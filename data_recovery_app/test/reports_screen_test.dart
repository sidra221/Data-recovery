import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:data_recovery_app/core/api_client.dart';
import 'package:data_recovery_app/core/secure_storage.dart';
import 'package:data_recovery_app/models/job.dart';
import 'package:data_recovery_app/providers/auth_provider.dart';
import 'package:data_recovery_app/screens/reports_screen.dart';

Map<String, dynamic> _job(int id, {String? serial, dynamic price}) =>
    <String, dynamic>{
      'id': id,
      'invoice_number': '01-20260915-000$id',
      'barcode': '01-20260915-000$id',
      'customer_name': 'محمد الأحمد',
      'customer_phone': '079123456$id',
      'hard_disk_type': 'hdd_35',
      'hard_disk_type_label': 'HDD 3.5',
      'status': 'received',
      'status_label': 'Received',
      'serial_number': ?serial,
      'created_at': '2026-09-15T10:00:00+03:00',
      'updated_at': '2026-09-15T10:00:00+03:00',
      'price': ?price,
    };

/// بيسجّل البارامترات اللي وصلته حتى نتأكد إن الشاشة بتبعتها صح.
class _SpyApi extends ApiClient {
  _SpyApi({this.jobs = const [], this.total, this.fail = false})
      : super(storage: SecureStorage());

  final List<Map<String, dynamic>> jobs;
  final int? total;
  final bool fail;

  String? lastSearch;
  String? lastFrom;
  String? lastTo;
  int calls = 0;

  @override
  Future<PaginatedJobs> listJobs({
    String? search,
    String? status,
    String? clientReport,
    String? workStatus,
    int? customerId,
    String? createdFrom,
    String? createdTo,
    bool overdue = false,
    int page = 1,
  }) async {
    calls++;
    lastSearch = search;
    lastFrom = createdFrom;
    lastTo = createdTo;
    if (fail) throw ApiException('server exploded');
    return PaginatedJobs(
      count: total ?? jobs.length,
      results: [for (final j in jobs) Job.fromJson(j)],
    );
  }
}

Future<void> _pump(WidgetTester tester, _SpyApi api) async {
  tester.view.physicalSize = const Size(411 * 3, 1400 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWith((ref) => api)],
      child: wrapApp(const ReportsScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  // main() بالإنتاج بينادي هاد؛ الاختبارات لازم تعمله بنفسها
  // وإلا DateFormat بلغة محددة بترفع LocaleDataException.
  setUpAll(() => initializeDateFormatting('en'));

  testWidgets('بيفتح على تلميح، وما بينادي السيرفر قبل البحث', (tester) async {
    final api = _SpyApi();
    await _pump(tester, api);

    expect(find.textContaining('Search by serial'), findsOneWidget);
    expect(api.calls, 0);
  });

  testWidgets('بحث فاضي بدون تاريخ: بيحذّر وما بينادي السيرفر', (tester) async {
    final api = _SpyApi();
    await _pump(tester, api);

    await tester.tap(find.widgetWithText(FilledButton, 'Search'));
    await tester.pump();

    expect(api.calls, 0, reason: 'ما في معيار بحث — ما لازم ينادي السيرفر');
    expect(find.textContaining('Enter a serial'), findsOneWidget);
  });

  testWidgets('البحث بالسيريال بيمرّر النص للسيرفر وبيعرض النتيجة',
      (tester) async {
    final api = _SpyApi(jobs: [_job(1, serial: 'WD-123456', price: '150.00')]);
    await _pump(tester, api);

    await tester.enterText(find.byType(TextField), 'WD-123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Search'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(api.calls, 1);
    expect(api.lastSearch, 'WD-123456');
    expect(find.text('#01-20260915-0001'), findsOneWidget);
    expect(find.text('150'), findsOneWidget);
    expect(find.text('Received'), findsOneWidget);
    expect(find.text('1 result'), findsOneWidget);
  });

  testWidgets('مافي نتائج: بيعرض رسالة واضحة', (tester) async {
    final api = _SpyApi();
    await _pump(tester, api);

    await tester.enterText(find.byType(TextField), 'ما موجود');
    await tester.tap(find.widgetWithText(FilledButton, 'Search'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No cases match this search'), findsOneWidget);
  });

  testWidgets('فشل السيرفر بينعرض كرسالة مو انهيار', (tester) async {
    final api = _SpyApi(fail: true);
    await _pump(tester, api);

    await tester.enterText(find.byType(TextField), 'أي شي');
    await tester.tap(find.widgetWithText(FilledButton, 'Search'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('server exploded'), findsOneWidget);
  });

  testWidgets('لما النتائج أكثر من صفحة: بيوضّح إنه في كمان', (tester) async {
    final api = _SpyApi(jobs: [_job(1), _job(2)], total: 47);
    await _pump(tester, api);

    await tester.enterText(find.byType(TextField), 'محمد');
    await tester.tap(find.widgetWithText(FilledButton, 'Search'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Showing 2 of 47'), findsOneWidget);
  });

  testWidgets('زر Clear بيصفّي البحث والنتائج', (tester) async {
    final api = _SpyApi(jobs: [_job(1)]);
    await _pump(tester, api);

    await tester.enterText(find.byType(TextField), 'محمد');
    await tester.tap(find.widgetWithText(FilledButton, 'Search'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('#01-20260915-0001'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Clear'));
    await tester.pump();

    expect(find.text('#01-20260915-0001'), findsNothing);
    expect(find.textContaining('Search by serial'), findsOneWidget);
  });
}
