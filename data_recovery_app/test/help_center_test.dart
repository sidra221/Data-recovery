import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

import 'package:data_recovery_app/screens/help_center_screen.dart';

void main() {
  Future<void> open(WidgetTester tester, {String locale = 'en'}) async {
    await tester.pumpWidget(wrapApp(const HelpCenterScreen(), locale: locale));
    await tester.pumpAndSettle();
  }

  testWidgets('بيعرض كل المقالات لما البحث فاضي', (tester) async {
    await open(tester);

    expect(find.text('How to recover deleted photos'), findsOneWidget);
    expect(find.text('Connecting an external SSD'), findsOneWidget);
    expect(find.text('Subscription & Billing FAQs'), findsOneWidget);
  });

  testWidgets('البحث بيفلتر بالعنوان', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), 'SSD');
    await tester.pumpAndSettle();

    expect(find.text('Connecting an external SSD'), findsOneWidget);
    expect(find.text('How to recover deleted photos'), findsNothing);
  });

  testWidgets('البحث بيلاقي كلمة جوّا خطوات المقال مو بالعنوان فقط',
      (tester) async {
    await open(tester);

    // «invoice» مذكورة بخطوات مقال الفوترة بس مو بعنوانه.
    await tester.enterText(find.byType(TextField), 'invoice');
    await tester.pumpAndSettle();

    expect(find.text('Subscription & Billing FAQs'), findsOneWidget);
    expect(find.text('Connecting an external SSD'), findsNothing);
  });

  testWidgets('بحث ما بيطابق شي بيعطي رسالة مو شاشة فاضية', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), 'zzzzz');
    await tester.pumpAndSettle();

    expect(find.text('No articles match this search'), findsOneWidget);
  });

  testWidgets('زر المسح بيرجّع كل المقالات', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), 'SSD');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('How to recover deleted photos'), findsOneWidget);
  });

  testWidgets('البحث بالعربي بيشتغل كمان', (tester) async {
    await open(tester, locale: 'ar');

    await tester.enterText(find.byType(TextField), 'SSD');
    await tester.pumpAndSettle();

    expect(find.text('توصيل قرص SSD خارجي'), findsOneWidget);
    expect(find.text('كيفية استعادة الصور المحذوفة'), findsNothing);
  });
}
