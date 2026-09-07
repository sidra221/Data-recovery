import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

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
      home: const LoginScreen(),
    );
  }
}
