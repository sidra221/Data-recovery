import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:data_recovery_app/core/api_client.dart';
import 'package:data_recovery_app/core/device_identity.dart';
import 'package:data_recovery_app/core/invoice_number_minter.dart';
import 'package:data_recovery_app/core/pending_queue.dart';
import 'package:data_recovery_app/core/secure_storage.dart';
import 'package:data_recovery_app/core/sync_engine.dart';

const _block = NumberBlock(prefix: '01', blockStart: 9000, blockEnd: 9002);

final _jobJson = <String, dynamic>{
  'id': 1,
  'invoice_number': '01-20260917-9000',
  'barcode': '01-20260917-9000',
  'customer_name': 'سامر',
  'customer_phone': '0791234567',
  'hard_disk_type': 'hdd_25',
  'status': 'received',
  'created_at': '2026-09-17T09:00:00Z',
  'updated_at': '2026-09-17T09:00:00Z',
};

/// Dio بينجح دايماً وبيسجّل كل طلب مرق عليه.
Dio _dioOk(List<RequestOptions> seen, {Object? data}) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        seen.add(options);
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            data: data ?? _jobJson,
            statusCode: 201,
          ),
        );
      },
    ),
  );
  return dio;
}

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

/// Dio بيرجّع رفض من السيرفر بجسم محدّد.
Dio _dioRejecting(Object body, {int statusCode = 400}) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.reject(
        DioException(
          requestOptions: options,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: statusCode,
            data: body,
          ),
        ),
      ),
    ),
  );
  return dio;
}

ApiClient _client(Dio dio) => ApiClient(storage: SecureStorage(), dio: dio);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late PendingQueue queue;
  late InvoiceNumberMinter minter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    queue = PendingQueue(prefs: prefs);
    minter = InvoiceNumberMinter(prefs: prefs);
  });

  group('معرّف الجهاز', () {
    test('بيضل هو هو بين القراءات', () async {
      final identity = DeviceIdentity(prefs: prefs);
      final first = await identity.get();
      final second = await identity.get();

      expect(first, isNotEmpty);
      expect(second, first);
    });
  });

  group('توليد رقم الفاتورة محلياً', () {
    test('بدون مدى محجوز ما بيولّد شي', () async {
      expect(await minter.mint(), isNull);
    });

    test('بيولّد بنفس شكل السيرفر وبيزيد التسلسل', () async {
      await minter.saveBlock(_block);
      final day = DateTime(2026, 9, 17);

      expect(await minter.mint(now: day), '01-20260917-9000');
      expect(await minter.mint(now: day), '01-20260917-9001');
      expect(await minter.mint(now: day), '01-20260917-9002');
    });

    test('بيوقف عند آخر المدى بدل ما يطلع برّا', () async {
      await minter.saveBlock(_block);
      final day = DateTime(2026, 9, 17);
      for (var i = 0; i < 3; i++) {
        await minter.mint(now: day);
      }

      expect(
        await minter.mint(now: day),
        isNull,
        reason: 'رقم برّا المدى ممكن يتصادم مع رقم السيرفر',
      );
    });

    test('التسلسل بيرجع لأول المدى بيوم جديد', () async {
      await minter.saveBlock(_block);
      await minter.mint(now: DateTime(2026, 9, 17));
      await minter.mint(now: DateTime(2026, 9, 17));

      expect(await minter.mint(now: DateTime(2026, 9, 18)), '01-20260918-9000');
    });

    test('بيعرف كم رقم باقي لهاليوم', () async {
      await minter.saveBlock(_block);
      final day = DateTime(2026, 9, 17);

      expect(await minter.remainingToday(now: day), 3);
      await minter.mint(now: day);
      expect(await minter.remainingToday(now: day), 2);
    });
  });

  group('طابور العمليات', () {
    test('بيحفظ الترتيب', () async {
      await queue.add(kind: PendingKind.createJob, payload: {'n': 1});
      await queue.add(kind: PendingKind.deliver, payload: {'n': 2});

      final ops = await queue.all();
      expect(ops.map((o) => o.payload['n']), [1, 2]);
    });

    test('بيضل محفوظ بعد إعادة التشغيل', () async {
      await queue.add(kind: PendingKind.createJob, payload: {'n': 1});

      final reopened = PendingQueue(prefs: await SharedPreferences.getInstance());
      expect((await reopened.all()).length, 1);
    });

    test('بيفرّق بين المنتظر والمرفوض', () async {
      final op = await queue.add(kind: PendingKind.createJob, payload: {});
      await queue.update(op.copyWith(lastError: 'phone is invalid'));

      expect(await queue.waiting(), isEmpty);
      expect((await queue.rejected()).single.lastError, 'phone is invalid');
    });
  });

  group('المزامنة', () {
    test('بترفع العمليات وبتفضّي الطابور', () async {
      await queue.add(
        kind: PendingKind.createJob,
        payload: {'customer_name': 'سامر', 'invoice_number': '01-20260917-9000'},
      );
      await queue.add(kind: PendingKind.deliver, payload: {'job_id': 1});

      final seen = <RequestOptions>[];
      final result = await SyncEngine(client: _client(_dioOk(seen)), queue: queue).flush();

      expect(result.synced, 2);
      expect(result.stillWaiting, 0);
      expect(await queue.all(), isEmpty);
      expect(seen.map((r) => r.path), ['jobs/', 'jobs/1/deliver/']);
    });

    test('السيرفر لسا مطفّى: بتوقف وبتخلّي الطابور متل ما هو', () async {
      await queue.add(kind: PendingKind.createJob, payload: {'a': 1});
      await queue.add(kind: PendingKind.createJob, payload: {'a': 2});

      final result =
          await SyncEngine(client: _client(_dioOffline()), queue: queue).flush();

      expect(result.stoppedOffline, isTrue);
      expect(result.synced, 0);
      expect(result.stillWaiting, 2, reason: 'ما بينضيع شي');
    });

    test('إعادة إرسال عملية وصلت قبل بتنعتبر نجاح مو تكرار', () async {
      await queue.add(
        kind: PendingKind.createJob,
        payload: {'invoice_number': '01-20260917-9000'},
      );

      // هاد الرد يلي بيرجّعه السيرفر لو الرقم أصلاً انسجّل.
      final dio = _dioRejecting({
        'invoice_number': ['invoice_number already exists'],
      });
      final result = await SyncEngine(client: _client(dio), queue: queue).flush();

      expect(result.synced, 1);
      expect(result.rejected, 0);
      expect(await queue.all(), isEmpty);
    });

    test('رفض حقيقي من السيرفر بينحفظ مع سببه وما بينعاد', () async {
      await queue.add(kind: PendingKind.createJob, payload: {'a': 1});

      final dio = _dioRejecting({
        'customer_phone': ['Enter a valid phone number'],
      });
      final result = await SyncEngine(client: _client(dio), queue: queue).flush();

      expect(result.rejected, 1);
      expect(result.synced, 0);

      final stuck = (await queue.rejected()).single;
      expect(stuck.lastError, contains('customer_phone'));
      expect(stuck.lastError, contains('valid phone'));
      expect(await queue.waiting(), isEmpty, reason: 'ما بينعاد تلقائياً');
    });

    test('العملية المرفوضة ما بتوقف يلي بعدها', () async {
      await queue.add(kind: PendingKind.createJob, payload: {'a': 1});
      await queue.add(kind: PendingKind.createJob, payload: {'a': 2});

      var call = 0;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            call++;
            if (call == 1) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response<dynamic>(
                    requestOptions: options,
                    statusCode: 400,
                    data: {'detail': 'bad'},
                  ),
                ),
              );
              return;
            }
            handler.resolve(
              Response<dynamic>(requestOptions: options, data: _jobJson, statusCode: 201),
            );
          },
        ),
      );

      final result = await SyncEngine(client: _client(dio), queue: queue).flush();
      expect(result.rejected, 1);
      expect(result.synced, 1);
    });
  });
}
