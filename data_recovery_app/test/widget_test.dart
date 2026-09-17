import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:data_recovery_app/core/api_client.dart';
import 'package:data_recovery_app/core/secure_storage.dart';
import 'package:data_recovery_app/main.dart';
import 'package:data_recovery_app/models/dashboard_stats.dart';
import 'package:data_recovery_app/providers/auth_provider.dart';
import 'package:data_recovery_app/screens/login_screen.dart';

/// بيتخطّى _restoreSession() حتى الاختبار ما يلمس تخزين ولا شبكة.
class _FixedAuth extends AuthNotifier {
  _FixedAuth(this._state);

  final AuthState _state;

  @override
  AuthState build() => _state;
}

/// HomeScreen بيجيب إحصائيات عند البناء. بالاختبار منرمي خطأ فوراً بدل
/// ما نفتح اتصال حقيقي — وإلا بيضل مؤقّت Dio معلّق وبيفشل الاختبار.
class _OfflineApi extends ApiClient {
  _OfflineApi() : super(storage: SecureStorage());

  @override
  Future<Fresh<DashboardStats>> getDashboardStatsCached() async =>
      throw ApiException('offline in tests');
}

Widget _appWith(AuthStatus status) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(() => _FixedAuth(AuthState(status: status))),
      apiClientProvider.overrideWith((ref) => _OfflineApi()),
    ],
    child: const DataRecoveryApp(),
  );
}

void main() {
  testWidgets('استعادة الجلسة قيد التنفيذ: بيعرض انتظار مش شاشة دخول',
      (WidgetTester tester) async {
    await tester.pumpWidget(_appWith(AuthStatus.unknown));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('بدون جلسة محفوظة: بيفتح على شاشة الدخول',
      (WidgetTester tester) async {
    await tester.pumpWidget(_appWith(AuthStatus.unauthenticated));
    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('مع جلسة صالحة: ما بيرجّع المستخدم لشاشة الدخول',
      (WidgetTester tester) async {
    await tester.pumpWidget(_appWith(AuthStatus.authenticated));
    await tester.pump();

    // الانحدار اللي صار: التوكن كان شغّال (getMe رجّع 200) والتطبيق
    // ظل يفتح على شاشة الدخول لأن main.dart كان `home: LoginScreen()` ثابت.
    // HomeScreen بيعرض مؤشر تحميل وهو بيجيب البيانات، فما منتحقق منه هون —
    // المهم إن شاشة الدخول مو ظاهرة.
    expect(find.byType(LoginScreen), findsNothing);
  });
}
