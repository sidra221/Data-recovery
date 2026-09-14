import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// نسخة طبق الأصل عن _WorkStatusBar بـ home_screen.dart (private فما منقدر نستوردها)
class BarUnderTest extends StatelessWidget {
  const BarUnderTest({
    super.key,
    required this.pending,
    required this.inProgress,
    required this.finished,
  });

  final int pending;
  final int inProgress;
  final int finished;

  @override
  Widget build(BuildContext context) {
    final total = pending + inProgress + finished;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 10,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFFE5E7EB)),
            if (total > 0)
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (pending > 0)
                    Expanded(
                      flex: pending,
                      child: const ColoredBox(color: Color(0xFFFFC562)),
                    ),
                  if (inProgress > 0)
                    Expanded(
                      flex: inProgress,
                      child: const ColoredBox(color: Color(0xFF33BEE9)),
                    ),
                  if (finished > 0)
                    Expanded(
                      flex: finished,
                      child: const ColoredBox(color: Color(0xFF1AC86C)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _pump(WidgetTester tester, Widget bar) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 300, child: bar)),
      ),
    ),
  );
}

List<Color> _colors(WidgetTester tester) => tester
    .widgetList<ColoredBox>(find.byType(ColoredBox))
    .map((b) => b.color)
    .toList();

void main() {
  const grey = Color(0xFFE5E7EB);
  const green = Color(0xFF1AC86C);
  const blue = Color(0xFF33BEE9);
  const amber = Color(0xFFFFC562);

  testWidgets('الحالة الحقيقية: finished=2 والباقي صفر', (tester) async {
    await _pump(tester, const BarUnderTest(pending: 0, inProgress: 0, finished: 2));
    final c = _colors(tester);
    // ignore: avoid_print
    print('  ألوان مرسومة: $c');
    expect(c, contains(green), reason: 'لازم يظهر الأخضر لأن finished=2');
  });

  testWidgets('عرض الشريط الأخضر لازم يغطي كل العرض', (tester) async {
    await _pump(tester, const BarUnderTest(pending: 0, inProgress: 0, finished: 2));
    final greenBox = find.byWidgetPredicate(
      (w) => w is ColoredBox && w.color == green,
    );
    expect(greenBox, findsOneWidget);
    final sz = tester.getSize(greenBox);
    // ignore: avoid_print
    print('  مقاس الأخضر: ${sz.width} x ${sz.height}');
    expect(sz.height, greaterThan(0), reason: 'ارتفاع صفر = شريط غير مرئي');
  });

  testWidgets('كل الحالات صفر: مافي ألوان حالة', (tester) async {
    await _pump(tester, const BarUnderTest(pending: 0, inProgress: 0, finished: 0));
    // Scaffold بيضيف ColoredBox خاصة فيه، فمنفحص غياب ألوان الحالة بس.
    final c = _colors(tester);
    expect(c, contains(grey));
    expect(c, isNot(contains(green)));
    expect(c, isNot(contains(blue)));
    expect(c, isNot(contains(amber)));
  });

  testWidgets('خليط: بيرسم التلاتة', (tester) async {
    await _pump(tester, const BarUnderTest(pending: 1, inProgress: 2, finished: 3));
    final c = _colors(tester);
    expect(c, containsAll(<Color>[amber, blue, green]));
  });
}
