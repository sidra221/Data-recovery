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

/// مصدر الحقيقة الوحيد لشاشة البداية.
///
/// قبل هيك كان `home: LoginScreen()` ثابت، فحتى لو التوكن محفوظ وشغّال
/// كان الموظف يضطر يسجّل دخول كل مرة يفتح فيها التطبيق. هلق منستنّى
/// `_restoreSession()` تخلص، وبننتقل حسب نتيجتها.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(authProvider.select((state) => state.status));
    switch (status) {
      case AuthStatus.unknown:
        return const _SessionSplash();
      case AuthStatus.authenticated:
        return const HomeScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
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
