import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
  Future<DashboardStats> getDashboardStats() async =>
      DashboardStats.fromJson(_realServerJson);
}

const green = Color(0xFF1AC86C);

void main() {
  testWidgets('الشاشة الحقيقية ببيانات السيرفر الحقيقية: الشريط لازم يخضرّ',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWith((ref) => _StubApi())],
        child: const MaterialApp(home: HomeScreen()),
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
    // ملاحظة: الأزرق والبرتقالي موجودين بالشاشة كشرائط جانبية للكروت
    // الأربعة (_HeroCard)، فما منقدر نمنعهن عالمستوى العام.
  });
}
