import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en');
  runApp(const ProviderScope(child: DataRecoveryApp()));
}

class DataRecoveryApp extends StatelessWidget {
  const DataRecoveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '01 Data Recovery',
      debugShowCheckedModeBanner: false,
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      theme: AppTheme.light,
      home: const _AuthGate(),
    );
  }
}

/// بيقرر **شاشة البداية فقط**، مرة وحدة عند الإقلاع.
///
/// قبل هيك كان `home: LoginScreen()` ثابت، فحتى لو التوكن محفوظ وشغّال
/// كان الموظف يضطر يسجّل دخول كل مرة. هلق منستنّى `_restoreSession()`
/// تخلص وبنقرر على أساسها.
///
/// مهم: بعد القرار الأول منوقف نتفاعل مع تغيّر الحالة. السبب إن شريط
/// التنقل السفلي بيستعمل `pushReplacement`، فبيشيل هالمسار من الشجرة
/// أول ما تنتقلي لأي تبويب. فالاعتماد عليه بتسجيل الخروج بيفشل —
/// الخروج بينقّل يدوياً من `setting_screen.dart`.
class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate();

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  AuthStatus? _decided;

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(authProvider.select((state) => state.status));
    _decided ??= status == AuthStatus.unknown ? null : status;

    if (_decided == null) return const _SessionSplash();
    return _decided == AuthStatus.authenticated
        ? const HomeScreen()
        : const LoginScreen();
  }
}

class _SessionSplash extends StatelessWidget {
  const _SessionSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
