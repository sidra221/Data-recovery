import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:data_recovery_app/main.dart';

void main() {
  testWidgets('app starts on login stub', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DataRecoveryApp()));
    expect(find.text('Login — UI لاحقاً'), findsOneWidget);
  });
}
