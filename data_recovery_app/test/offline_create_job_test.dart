import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:data_recovery_app/core/api_client.dart';
import 'package:data_recovery_app/core/invoice_number_minter.dart';
import 'package:data_recovery_app/core/pending_queue.dart';
import 'package:data_recovery_app/core/secure_storage.dart';
import 'package:data_recovery_app/providers/auth_provider.dart';
import 'package:data_recovery_app/providers/jobs_provider.dart';
import 'package:data_recovery_app/providers/sync_provider.dart';

final _payload = <String, dynamic>{
  'customer_name': 'سامر',
  'customer_phone': '0791234567',
  'hard_disk_type': 'hdd_25',
};

final _serverJob = <String, dynamic>{
  'id': 7,
  'invoice_number': '01-20260917-0001',
  'barcode': '01-20260917-0001',
  'customer_name': 'سامر',
  'customer_phone': '0791234567',
  'hard_disk_type': 'hdd_25',
  'status': 'received',
  'created_at': '2026-09-17T09:00:00Z',
  'updated_at': '2026-09-17T09:00:00Z',
};

Dio _dioOffline() {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      ),
    ),
  );
  return dio;
}

Dio _dioOnline() {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(
        Response<dynamic>(
          requestOptions: options,
          data: _serverJob,
          statusCode: 201,
        ),
      ),
    ),
  );
  return dio;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late PendingQueue queue;
  late InvoiceNumberMinter minter;

  Future<ProviderContainer> containerWith(Dio dio) async {
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWith(
          (ref) => ApiClient(storage: SecureStorage(), dio: dio),
        ),
        pendingQueueProvider.overrideWithValue(queue),
        invoiceMinterProvider.overrideWithValue(minter),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    queue = PendingQueue(prefs: prefs);
    minter = InvoiceNumberMinter(prefs: prefs);
  });

  test('السيرفر شغّال: بتنعمل عادي وما بينضاف شي للطابور', () async {
    await minter.saveBlock(
      const NumberBlock(prefix: '01', blockStart: 9000, blockEnd: 9009),
    );
    final container = await containerWith(_dioOnline());

    final job = await container.read(jobsProvider.notifier).createJob(_payload);

    expect(job.id, 7);
    expect(job.invoiceNumber, '01-20260917-0001');
    expect(await queue.all(), isEmpty);
    expect(
      await minter.remainingToday(),
      10,
      reason: 'ما لازم نستهلك رقم محجوز والسيرفر شغّال',
    );
  });

  test('السيرفر مطفّى: بتنحفظ بالطابور برقم من المدى المحجوز', () async {
    await minter.saveBlock(
      const NumberBlock(prefix: '01', blockStart: 9000, blockEnd: 9009),
    );
    final container = await containerWith(_dioOffline());

    final job = await container.read(jobsProvider.notifier).createJob(_payload);

    expect(job.id, lessThan(0), reason: 'id سالب = لسا ما انرفعت');
    expect(job.invoiceNumber, '01-20260917-9000');
    expect(job.barcode, job.invoiceNumber, reason: 'الباركود = رقم الفاتورة');
    expect(job.customerName, 'سامر');

    final queued = (await queue.all()).single;
    expect(queued.kind, PendingKind.createJob);
    expect(queued.payload['invoice_number'], '01-20260917-9000');
    expect(queued.payload['customer_name'], 'سامر');
  });

  test('العملية المحفوظة بتظهر بالقائمة فوراً', () async {
    await minter.saveBlock(
      const NumberBlock(prefix: '01', blockStart: 9000, blockEnd: 9009),
    );
    final container = await containerWith(_dioOffline());

    await container.read(jobsProvider.notifier).createJob(_payload);

    final jobs = container.read(jobsProvider).jobs;
    expect(jobs.single.invoiceNumber, '01-20260917-9000');
  });

  test('بدون مدى محجوز: بترمي خطأ واضح مو بتحفظ رقم عشوائي', () async {
    final container = await containerWith(_dioOffline());

    await expectLater(
      container.read(jobsProvider.notifier).createJob(_payload),
      throwsA(isA<OfflineNumbersExhausted>()),
    );
    expect(await queue.all(), isEmpty, reason: 'ما بينحفظ شي ناقص');
  });

  test('خلص المدى لهاليوم: بترمي خطأ بدل ما تعطي رقم بيتصادم', () async {
    await minter.saveBlock(
      const NumberBlock(prefix: '01', blockStart: 9000, blockEnd: 9000),
    );
    final container = await containerWith(_dioOffline());

    await container.read(jobsProvider.notifier).createJob(_payload);

    await expectLater(
      container.read(jobsProvider.notifier).createJob(_payload),
      throwsA(isA<OfflineNumbersExhausted>()),
    );
    expect((await queue.all()).length, 1);
  });

  test('خطأ من السيرفر مو انقطاع: بينرمي متل ما هو وما بينحفظ', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            response: Response<dynamic>(
              requestOptions: options,
              statusCode: 400,
              data: {'customer_phone': ['Enter a valid phone number']},
            ),
          ),
        ),
      ),
    );
    await minter.saveBlock(
      const NumberBlock(prefix: '01', blockStart: 9000, blockEnd: 9009),
    );
    final container = await containerWith(dio);

    await expectLater(
      container.read(jobsProvider.notifier).createJob(_payload),
      throwsA(
        isA<ApiException>().having((e) => e.message, 'message', contains('valid phone')),
      ),
    );
    expect(
      await queue.all(),
      isEmpty,
      reason: 'السيرفر رفضها — حفظها بالطابور بيعيد نفس الرفض بلا فايدة',
    );
  });
}
