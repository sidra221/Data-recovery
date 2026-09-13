import 'package:flutter/material.dart';

import '../cases_list_screen.dart';
import '../create_case_screen.dart';
import '../customers_list_screen.dart';
import '../home_screen.dart';
import '../setting_screen.dart';

class AppFab extends StatelessWidget {
  const AppFab({super.key, this.onCreated});

  final Future<void> Function()? onCreated;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF33BEE9).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CreateCaseScreen(),
            ),
          );
          await onCreated?.call();
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
        child: Ink(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5CCBED), Color(0xFF2EABD2)],
            ),
          ),
          child: const Center(
            child: Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

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
    return BottomAppBar(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 12,
      shadowColor: const Color(0x1A000000),
      padding: EdgeInsets.zero,
      notchMargin: 8,
      shape: const AutomaticNotchedShape(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        CircleBorder(),
      ),
      child: SizedBox(
        height: 68,
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                selected: currentIndex == 0,
                onTap: () => _onTap(context, 0),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.build_outlined,
                label: 'Cases',
                selected: currentIndex == 1,
                circled: true,
                onTap: () => _onTap(context, 1),
              ),
            ),
            const SizedBox(width: 64),
            Expanded(
              child: _NavItem(
                icon: Icons.groups_outlined,
                label: 'Customer',
                selected: currentIndex == 2,
                onTap: () => _onTap(context, 2),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.settings_outlined,
                label: 'Setting',
                selected: currentIndex == 3,
                onTap: () => _onTap(context, 3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.circled = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool circled;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppBottomNav._accent : const Color(0xFF4B5563);
    final iconWidget = circled
        ? SizedBox(
            width: 26,
            height: 26,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.circle_outlined, size: 26, color: color),
                Icon(icon, size: 12, color: color),
              ],
            ),
          )
        : Icon(icon, size: 24, color: color);

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE5F9FD) : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: iconWidget,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}