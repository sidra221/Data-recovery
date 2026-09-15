import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:data_recovery_app/core/api_client.dart';
import 'package:data_recovery_app/core/secure_storage.dart';
import 'package:data_recovery_app/models/job.dart';
import 'package:data_recovery_app/providers/auth_provider.dart';
import 'package:data_recovery_app/screens/case_detail_screen.dart';

Map<String, dynamic> _json({
  dynamic price,
  String? serial,
  String? model,
  String? problem,
  String workStatus = '',
  List<Map<String, dynamic>> logs = const [],
}) =>
    <String, dynamic>{
      'id': 7,
      'invoice_number': '01-20260915-0007',
      'barcode': '01-20260915-0007',
      'customer_name': 'محمد الأحمد',
      'customer_phone': '0791234567',
      'hard_disk_type': 'hdd_35',
      'hard_disk_type_label': 'HDD 3.5',
      'status': 'received',
      'status_label': 'Received',
      'work_status': workStatus,
      'work_status_label': workStatus == 'finished' ? 'Done' : '',
      'device_model': ?model,
      'serial_number': ?serial,
      'problem': ?problem,
      'created_at': '2026-09-15T10:00:00+03:00',
      'updated_at': '2026-09-15T10:00:00+03:00',
      'price': ?price,
      'status_logs': logs,
    };

class _StubApi extends ApiClient {
  _StubApi(this._job) : super(storage: SecureStorage());

  final Map<String, dynamic> _job;

  @override
  Future<Job> getJob(int id) async => Job.fromJson(_job);
}

Future<void> _pump(WidgetTester tester, Map<String, dynamic> json) async {
  // سطح طويل: الشاشة ListView، ويلي تحت الحدود ما ينبني بالاختبار.
  tester.view.physicalSize = const Size(411 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWith((ref) => _StubApi(json))],
      child: const MaterialApp(home: CaseDetailScreen(jobId: 7)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('بيعرض رقم الفاتورة وبيانات العميل والجهاز', (tester) async {
    await _pump(
      tester,
      _json(serial: 'WD-123456', model: 'Seagate ST2000', problem: 'ما بيقلع'),
    );

    expect(find.text('#01-20260915-0007'), findsWidgets);
    expect(find.text('محمد الأحمد'), findsOneWidget);
    expect(find.text('0791234567'), findsOneWidget);
    expect(find.text('HDD 3.5'), findsOneWidget);
    expect(find.text('Seagate ST2000'), findsOneWidget);
    expect(find.text('WD-123456'), findsOneWidget);
    expect(find.text('ما بيقلع'), findsOneWidget);
  });

  testWidgets('الحقول الفاضية ما بتظهر كأسطر فاضية', (tester) async {
    await _pump(tester, _json());
    // مافي موديل ولا سيريال ولا مشكلة → التسميات لازم تكون غايبة
    expect(find.text('Model'), findsNothing);
    expect(find.text('Serial'), findsNothing);
    expect(find.text('Problem'), findsNothing);
  });

  testWidgets('السعر المحدّد بينعرض', (tester) async {
    await _pump(tester, _json(price: '150.00'));
    expect(find.text('150'), findsOneWidget);
  });

  testWidgets('بدون سعر بينعرض Not set', (tester) async {
    await _pump(tester, _json());
    expect(find.text('Not set'), findsOneWidget);
  });

  testWidgets('شارة حالة الشغل بتظهر لما تكون محدّدة', (tester) async {
    await _pump(tester, _json(workStatus: 'finished'));
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('WORK'), findsOneWidget);
  });

  testWidgets('سجل التغييرات: الأحدث فوق', (tester) async {
    await _pump(
      tester,
      _json(logs: [
        {
          'id': 1,
          'status': 'received',
          'status_label': 'Received',
          'note': 'أول سجل',
          'created_at': '2026-09-15T10:00:00+03:00',
          'created_by_name': 'mohammad',
        },
        {
          'id': 2,
          'status': 'completed',
          'status_label': 'Completed',
          'note': 'تاني سجل',
          'created_at': '2026-09-15T12:00:00+03:00',
          'created_by_name': 'mohammad',
        },
      ]),
    );

    // منستعمل نص الملاحظة مو الحالة: "Received" ظاهرة بشارة الحالة كمان.
    final newer = tester.getTopLeft(find.text('تاني سجل')).dy;
    final older = tester.getTopLeft(find.text('أول سجل')).dy;
    expect(newer, lessThan(older), reason: 'الأحدث لازم يكون فوق');
  });

  testWidgets('أزرار العمل التلاتة موجودة', (tester) async {
    await _pump(tester, _json());
    expect(find.text('Update Status'), findsOneWidget);
    expect(find.text('Notify Customer'), findsOneWidget);
    expect(find.text('Quotation / Invoice'), findsOneWidget);
  });
}
