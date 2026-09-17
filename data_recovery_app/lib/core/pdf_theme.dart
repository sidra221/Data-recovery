import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// خطوط المستندات المطبوعة (فاتورة، ستيكر، سند استلام).
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
