import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

final _arabicRange =
    RegExp(r'[؀-ۿݐ-ݿﭐ-﷿ﹰ-﻿]');

bool hasArabic(String text) => _arabicRange.hasMatch(text);

/// نص بالـ PDF باتجاه مشتقّ من محتواه.
///
/// حزمة `pdf` بترتّب الحروف حسب اتجاه الصفحة، وصفحاتنا إنكليزية (LTR). فأي
/// نص عربي — اسم عميل، وصف عطل، شروط، اسم شركة — كان بينطبع **معكوس**:
/// الحروف مشكّلة صح بس مرتّبة من اليسار لليمين.
///
/// المستندات مختلطة بطبيعتها (رقم فاتورة لاتيني واسم عربي بنفس الصفحة)،
/// فاتجاه الصفحة لحاله ما بيكفي — كل نص لازم ياخد اتجاهه من محتواه هو.
pw.Widget rtlAware(
  String text, {
  pw.TextStyle? style,
  int? maxLines,
  pw.TextAlign? align,
}) {
  return pw.Directionality(
    textDirection: hasArabic(text) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
    child: pw.Text(text, style: style, maxLines: maxLines, textAlign: align),
  );
}

/// خطوط المستندات المطبوعة (فاتورة، ملصق، سند استلام).
///
/// حزمة `pdf` بتستعمل Helvetica افتراضياً، وهي Type1 بلا دعم يونيكود أصلاً —
/// فكل حرف عربي بيطلع مربّع فاضي. وأسماء العملاء والأجهزة والمشاكل كلها
/// بتنكتب عربي.
///
/// Noto Naskh ما بينفع يحلّ محل Helvetica: هو قصّة عربية بس، بتغطي ١٥ حرف من
/// الـ ٩٥ ASCII المطبوعة ولا شي من ترقيم اللاتيني — فلو خلّيناه الأساسي
/// بتنكسر العناوين الإنكليزية والأرقام. Noto Sans بيحمل اللاتيني، و Noto
/// Naskh احتياطي للعربي؛ مع بعض ما بيضل فجوة.
/// `test/invoice_pdf_font_test.dart` بيثبّت هالشي.
class PdfTheme {
  /// بينتحفظ بين الطباعات — تحليل ٤ خطوط (١.٤ ميغا) لازم يصير مرة وحدة بس.
  static Future<pw.ThemeData>? _future;

  static Future<pw.ThemeData> load() {
    return _future ??= () async {
      Future<pw.Font> font(String name) async =>
          pw.Font.ttf(await rootBundle.load('assets/fonts/$name.ttf'));

      return pw.ThemeData.withFont(
        base: await font('NotoSans-Regular'),
        bold: await font('NotoSans-Bold'),
        fontFallback: [
          await font('NotoNaskhArabic-Regular'),
          await font('NotoNaskhArabic-Bold'),
        ],
      );
    }();
  }
}
