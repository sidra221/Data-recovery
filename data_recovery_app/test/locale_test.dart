
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:data_recovery_app/l10n/app_localizations.dart';
import 'package:data_recovery_app/providers/locale_provider.dart';

void main() {
  test('اللغات المدعومة: إنكليزي وعربي', () {
    expect(supportedLocales.map((l) => l.languageCode), ['en', 'ar']);
  });

  test('اللغة الافتراضية إنكليزي', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(localeProvider).languageCode, 'en');
  });

  test('seed بتحدّد لغة البداية', () {
    final c = ProviderContainer(
      overrides: [
        localeProvider
            .overrideWith(() => LocaleNotifier()..seed(const Locale('ar'))),
      ],
    );
    addTearDown(c.dispose);
    expect(c.read(localeProvider).languageCode, 'ar');
  });

  test('toggle بيبدّل بين الاتنين', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    await c.read(localeProvider.notifier).toggle();
    expect(c.read(localeProvider).languageCode, 'ar');

    await c.read(localeProvider.notifier).toggle();
    expect(c.read(localeProvider).languageCode, 'en');
  });

  test('لغة غير مدعومة بتنرفض بدون ما تكسر الحالة', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    await c.read(localeProvider.notifier).setLocale(const Locale('fr'));
    expect(c.read(localeProvider).languageCode, 'en',
        reason: 'الفرنسي مش مدعوم — لازم يضل إنكليزي');
  });

  testWidgets('الترجمة بترجّع النص الصح لكل لغة', (tester) async {
    for (final (code, expected) in [
      ('en', 'Welcome Back'),
      ('ar', 'أهلاً بعودتك'),
    ]) {
      late L l;
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(code),
          supportedLocales: supportedLocales,
          localizationsDelegates: L.localizationsDelegates,
          home: Builder(
            builder: (context) {
              l = L.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(l.welcomeBack, expected, reason: 'اللغة $code');
    }
  });

  testWidgets('العربي بيطبّق اتجاه RTL تلقائياً', (tester) async {
    late TextDirection dir;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: supportedLocales,
        localizationsDelegates: L.localizationsDelegates,
        home: Builder(
          builder: (context) {
            dir = Directionality.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(dir, TextDirection.rtl);
  });

  group('ملفات الترجمة', () {
    Map<String, dynamic> arb(String code) => jsonDecode(
          File('lib/l10n/app_$code.arb').readAsStringSync(),
        ) as Map<String, dynamic>;

    Set<String> keysOf(Map<String, dynamic> m) =>
        m.keys.where((k) => !k.startsWith('@')).toSet();

    test('العربي والإنكليزي عندهم نفس المفاتيح', () {
      final en = keysOf(arb('en'));
      final ar = keysOf(arb('ar'));
      expect(en.difference(ar), isEmpty, reason: 'مفاتيح ناقصة بالعربي');
      expect(ar.difference(en), isEmpty, reason: 'مفاتيح زايدة بالعربي');
    });

    test('مافي ترجمة فاضية', () {
      for (final code in ['en', 'ar']) {
        final m = arb(code);
        for (final k in keysOf(m)) {
          expect((m[k] as String).trim(), isNotEmpty, reason: '$code → $k فاضي');
        }
      }
    });

    test('الترجمة العربية مو منسوخة عن الإنكليزي', () {
      final en = arb('en');
      final ar = arb('ar');
      // المصطلحات التقنية بتضل لاتينية عن قصد، فمنستثنيها.
      const latinByDesign = {
        'typeSsd', 'typeNvme', 'typeHdd35', 'typeHdd25', 'appTitle',
      };
      final copied = [
        for (final k in keysOf(en))
          if (!latinByDesign.contains(k) && en[k] == ar[k]) k,
      ];
      expect(copied, isEmpty, reason: 'مفاتيح لسا بالإنكليزي: $copied');
    });
  });
}
