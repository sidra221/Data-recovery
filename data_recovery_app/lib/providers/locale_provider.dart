import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/secure_storage.dart';

const supportedLocales = [Locale('en'), Locale('ar')];

/// اللغة المختارة، محفوظة على الجهاز.
///
/// بتنقرا قبل `runApp` بـ [loadSavedLocale] حتى التطبيق يفتح بلغة المستخدم
/// مباشرة، بدون ما يرمش بالإنكليزي أول ثانية.
class LocaleNotifier extends Notifier<Locale> {
  Locale _initial = const Locale('en');

  /// بينقرا اللغة المحفوظة. مافي محفوظة أو غير مدعومة → إنكليزي.
  static Future<Locale> loadSavedLocale() async {
    try {
      final code = await SecureStorage().readLocale();
      return code == 'ar' ? const Locale('ar') : const Locale('en');
    } catch (_) {
      // التخزين مش متاح (متصفح بوضع خاص مثلاً) — منكمّل بالافتراضي.
      return const Locale('en');
    }
  }

  void seed(Locale locale) => _initial = locale;

  @override
  Locale build() => _initial;

  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.any((l) => l.languageCode == locale.languageCode)) {
      return;
    }
    state = locale;
    try {
      await SecureStorage().saveLocale(locale.languageCode);
    } catch (_) {
      // فشل الحفظ ما لازم يمنع تبديل اللغة بهالجلسة.
    }
  }

  Future<void> toggle() => setLocale(
        state.languageCode == 'ar' ? const Locale('en') : const Locale('ar'),
      );
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
