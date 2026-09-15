import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import 'help_center_screen.dart';
import 'personal_information_screen.dart';
import 'widgets/app_bottom_nav.dart';
import 'widgets/app_button.dart';
import 'widgets/soft_surface.dart';
import 'login_screen.dart';

class SettingScreen extends ConsumerWidget {
  const SettingScreen({super.key});

  String _displayName(String? username, L l) {
    final raw = (username ?? '').trim();
    if (raw.isEmpty) return l.employee;
    return raw
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final l = L.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x66000000),
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.logOut),
        content: Text(l.logOutConfirm),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: AppTextButton(
                  label: l.cancel,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: l.logOut,
                  variant: AppButtonVariant.danger,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(authProvider.notifier).logout();
    if (!context.mounted) return;
    // لازم تنقّل صريح: شريط التنقل السفلي بيستعمل pushReplacement، فالبوابة
    // يلي بـ main.dart بتكون انشالت من الشجرة وما بتقدر ترجّعنا لشاشة الدخول.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final username = ref.watch(authProvider).username;
    final profile = ref.watch(authProvider).profile;
    final name = _displayName(username, l);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFEAF8FC), Color(0xFFF7F8FA)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.settings,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        const _LanguageChip(),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white,
                        backgroundImage: (profile?.photoUrl ?? '').isNotEmpty
                            ? NetworkImage(profile!.photoUrl)
                            : null,
                        child: (profile?.photoUrl ?? '').isEmpty
                            ? const Icon(Icons.person, size: 48, color: Color(0xFFD1D5DB))
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.role ?? l.itEmployee,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 28),
                    _SectionLabel(l.sectionAccount),
                    const SizedBox(height: 10),
                    _SettingsCard(
                      icon: Icons.person_outline,
                      label: l.personalInformation,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PersonalInformationScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    _SectionLabel(l.sectionSupport),
                    const SizedBox(height: 10),
                    _SettingsCard(
                      icon: Icons.help_outline,
                      label: l.helpCenter,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const HelpCenterScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    _LogoutButton(onTap: () => _logout(context, ref)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const AppFab(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }
}

/// شريحة تبديل اللغة. كانت نص ثابت «English» بدون وظيفة —
/// هلق بتعرض اللغة **التانية** (يعني الوجهة لو ضغطت) وبتبدّل فعلياً.
class _LanguageChip extends ConsumerWidget {
  const _LanguageChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isArabic = locale.languageCode == 'ar';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => ref.read(localeProvider.notifier).toggle(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language, size: 18, color: Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Text(
                isArabic ? 'English' : 'العربية',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
        color: Color(0xFF9CA3AF),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftSurface(
      radius: 16,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF4B5563), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return SoftSurface(
      radius: 16,
      color: const Color(0xFFFFE4E6),
      shadowColor: const Color(0x14EF4444),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: Color(0xFFEF4444), size: 20),
              SizedBox(width: 8),
              Text(
                l.logOut,
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
