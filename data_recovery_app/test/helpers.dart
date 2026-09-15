import 'package:flutter/material.dart';

import 'package:data_recovery_app/l10n/app_localizations.dart';
import 'package:data_recovery_app/providers/locale_provider.dart';

/// بيلفّ الشاشة بـ MaterialApp فيه مزوّدي الترجمة.
///
/// أي شاشة تستعمل `L.of(context)` بترفع استثناء لو انلفّت بـ MaterialApp
/// عادي، فكل اختبارات الشاشات لازم تمرق من هون.
Widget wrapApp(Widget home, {String locale = 'en'}) {
  return MaterialApp(
    locale: Locale(locale),
    supportedLocales: supportedLocales,
    localizationsDelegates: L.localizationsDelegates,
    home: home,
  );
}
