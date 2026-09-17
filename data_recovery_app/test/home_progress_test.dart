import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

import 'package:data_recovery_app/core/api_client.dart';
import 'package:data_recovery_app/core/secure_storage.dart';
import 'package:data_recovery_app/models/dashboard_stats.dart';
import 'package:data_recovery_app/providers/auth_provider.dart';
import 'package:data_recovery_app/screens/home_screen.dart';

/// نفس JSON اللي بيرجّعه السيرفر فعلياً (تم نسخه من /api/dashboard/stats/).
final _realServerJson = <String, dynamic>{
  'status_counts': {'received': 3, 'completed': 0, 'has_problems': 0},
  'client_report_counts': {
    'agree': 0,
    'wait_client': 0,
    'finished': 1,
    'rejected': 0,
    'unset': 2,
  },
  'work_status_counts': {
    'pending': 0,
    'in_progress': 0,
    'finished': 2,
    'unset': 1,
  },
  'total_customers': 4,
  'total_jobs': 3,
  'jobs_created_today': 0,
  'status_changes_today': 0,
  'total_delivered': 0,
};

class _StubApi extends ApiClient {
  _StubApi() : super(storage: SecureStorage());

  @override
  Future<Fresh<DashboardStats>> getDashboardStatsCached() async =>
      Fresh(DashboardStats.fromJson(_realServerJson), null);
}

const green = Color(0xFF1AC86C);

void main() {
  testWidgets('الشاشة الحقيقية ببيانات السيرفر الحقيقية: الشريط لازم يخضرّ',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWith((ref) => _StubApi())],
        child: wrapApp(const HomeScreen()),
      ),
    );
    await tester.pump(); // يشغّل _load
    await tester.pump(const Duration(milliseconds: 100));

    final colors = tester
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .map((b) => b.color)
        .toList();
    // ignore: avoid_print
    print('  ألوان ColoredBox بالشاشة: $colors');

    final greenBox = find.byWidgetPredicate(
      (w) => w is ColoredBox && w.color == green,
    );
    if (greenBox.evaluate().isNotEmpty) {
      // ignore: avoid_print
      print('  عرض الشريط الأخضر: ${tester.getSize(greenBox.first).width}');
    }

    expect(greenBox, findsOneWidget,
        reason: 'finished=2 فالشريط لازم يكون أخضر بالكامل');
    // الارتفاع أهم من العرض: الباگ اللي صار كان شريط بعرض كامل وارتفاع صفر.
    expect(tester.getSize(greenBox.first).height, greaterThan(0),
        reason: 'شريط بارتفاع صفر = غير مرئي');
    // ملاحظة: الأزرق والبرتقالي موجودين بالشاشة كشرائط جانبية للكروت
    // الأربعة (_HeroCard)، فما منقدر نمنعهن عالمستوى العام.
  });

  testWidgets('قياس ارتفاع الكروت الأربعة', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWith((ref) => _StubApi())],
        child: wrapApp(const HomeScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    for (final label in ['WAIT CLIENT', 'REJECTED', 'INSPECTION', 'DELIVERY']) {
      final f = find.text(label);
      if (f.evaluate().isEmpty) continue;
      final card = find.ancestor(of: f, matching: find.byType(Material)).first;
      // ignore: avoid_print
      print('  كرت $label: ارتفاع ${tester.getSize(card).height.toStringAsFixed(1)}');
    }
  });

  testWidgets('بعرض موبايل حقيقي 411x915: الشريط لازم يخضرّ كمان',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(411 * 3, 915 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWith((ref) => _StubApi())],
        child: wrapApp(const HomeScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final greenBox = find.byWidgetPredicate(
      (w) => w is ColoredBox && w.color == green,
    );
    // ignore: avoid_print
    print('  بعرض موبايل — لقي أخضر؟ ${greenBox.evaluate().length}');
    if (greenBox.evaluate().isNotEmpty) {
      final sz = tester.getSize(greenBox.first);
      // ignore: avoid_print
      print('  مقاس الأخضر: ${sz.width} x ${sz.height}');
    }
    for (final label in ['WAIT CLIENT', 'DELIVERY']) {
      final f = find.text(label);
      if (f.evaluate().isEmpty) continue;
      final card = find.ancestor(of: f, matching: find.byType(Material)).first;
      // ignore: avoid_print
      print('  كرت $label: ${tester.getSize(card).height.toStringAsFixed(1)}');
    }
    expect(greenBox, findsOneWidget);
    expect(tester.getSize(greenBox.first).height, greaterThan(0),
        reason: 'بعرض الموبايل كان بينهار لارتفاع صفر — هون انكشف الباگ');
  });
}
