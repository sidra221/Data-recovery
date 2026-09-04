import 'package:flutter/material.dart';

import '../cases_list_screen.dart';
import '../customers_list_screen.dart';
import '../home_screen.dart';
import '../setting_screen.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  static const _accent = Color(0xFF33BEE9);

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    final Widget screen = switch (index) {
      0 => const HomeScreen(),
      1 => const CasesListScreen(),
      2 => const CustomersListScreen(),
      3 => const SettingScreen(),
      _ => const CasesListScreen(),
    };
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: _accent,
      unselectedItemColor: const Color(0xFF9CA3AF),
      onTap: (index) => _onTap(context, index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), label: 'Cases'),
        BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Customer'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Setting'),
      ],
    );
  }
}
