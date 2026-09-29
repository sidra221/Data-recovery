import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/src/pdf/options.dart' as pdf_options;

/// حزمة `pdf` بتشكّل الحروف العربية بس لما `use_bidi=false`.
///
/// الافتراضي (`useBidi=true`) بيمرّق النص على `bidi.logicalToVisual` يلي
/// بيرتّب بس ما بيوصل — فبتطلع المطبوعات «ﺍﺱﻡ ﺍﻝ ﻉﻡﻱﻝ» بأشكال منفصلة بدل
/// «اسم العميل». إطفاؤه بيشغّل `arabic.convert` يلي بيعمل التشكيل الصح.
///
/// الفلاغ بينمرّر وقت البناء، فما في شي بالكود بيضمنه — عشان هيك منثبّته
/// هون: أي بناء بينعمل بدونه بيخرّب كل مستند عربي.
void main() {
  test('سكربت البناء بيمرّر فلاغ التشكيل العربي', () {
    final script = File('../build_app.sh').readAsStringSync();
    expect(
      script,
      contains('use_bidi=false'),
      reason: 'بدونه كل المطبوعات بتطلع بعربي مقطّع',
    );
  });

  test('التشكيل مفعّل وقت تشغيل هذا الاختبار', () {
    expect(
      pdf_options.useArabic,
      isTrue,
      reason: 'شغّل الاختبارات بـ --dart-define=use_bidi=false',
    );
    expect(pdf_options.useBidi, isFalse);
  }, skip: 'بينشغّل يدوياً: flutter test --dart-define=use_bidi=false');
}
