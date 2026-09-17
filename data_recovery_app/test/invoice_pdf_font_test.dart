import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// الفاتورة بتنطبع بخط مدمج بدل Helvetica. الاختبار بيتأكد إنه الخطوط
/// المرفقة فعلاً بتغطي العربي والإنجليزي مع بعض — لأنه Noto Naskh لحاله
/// ما بيغطي ASCII، و Noto Sans لحاله ما بيغطي العربي.
Map<int, int> _glyphs(String file) => TtfParser(
      File('assets/fonts/$file').readAsBytesSync().buffer.asByteData(),
    ).charToGlyphIndexMap;

const _asciiPrintable = 95; // U+0020..U+007E
List<int> get _ascii => [for (var c = 0x20; c < 0x7f; c++) c];
List<int> get _latinPunct =>
    const [0x2013, 0x2014, 0x2018, 0x2019, 0x201c, 0x201d, 0x2026, 0x2022];
List<int> get _arabic => [
      for (var c = 0x621; c <= 0x64a; c++) c,
      for (var c = 0x660; c < 0x66a; c++) c,
    ];

void main() {
  test('الخطوط المدمجة موجودة كلها', () {
    for (final f in const [
      'NotoSans-Regular.ttf',
      'NotoSans-Bold.ttf',
      'NotoNaskhArabic-Regular.ttf',
      'NotoNaskhArabic-Bold.ttf',
    ]) {
      expect(File('assets/fonts/$f').existsSync(), isTrue, reason: 'ناقص $f');
    }
  });

  test('الخط الأساسي بيغطي اللاتيني، والاحتياطي بيغطي العربي', () {
    final sans = _glyphs('NotoSans-Regular.ttf');
    final naskh = _glyphs('NotoNaskhArabic-Regular.ttf');

    bool covers(Map<int, int> m, int c) => (m[c] ?? 0) != 0;

    // الأساسي لازم يغطي ASCII كامل — هون كان بينكسر لو خلّينا Naskh أساسي.
    expect(_ascii.where((c) => covers(sans, c)).length, _asciiPrintable);
    expect(_latinPunct.every((c) => covers(sans, c)), isTrue);

    // الاحتياطي لازم يغطي العربي كامل.
    expect(_arabic.every((c) => covers(naskh, c)), isTrue);

    // مع بعض: ما في أي حرف بيطلع مربع فاضي.
    final combined = {...sans, ...naskh};
    final gaps = [..._ascii, ..._latinPunct, ..._arabic]
        .where((c) => !covers(combined, c))
        .toList();
    expect(gaps, isEmpty, reason: 'حروف بلا شكل: $gaps');
  });

  test('المستند بيطلع فيه خط مدمج ونص عربي', () async {
    pw.Font load(String f) => pw.Font.ttf(
        File('assets/fonts/$f').readAsBytesSync().buffer.asByteData());

    final theme = pw.ThemeData.withFont(
      base: load('NotoSans-Regular.ttf'),
      bold: load('NotoSans-Bold.ttf'),
      fontFallback: [
        load('NotoNaskhArabic-Regular.ttf'),
        load('NotoNaskhArabic-Bold.ttf'),
      ],
    );

    final doc = pw.Document(theme: theme);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        build: (_) => pw.Column(
          children: [
            pw.Text('شركة استرجاع البيانات — فاتورة ضريبية'),
            pw.Text('Invoice: INV-001  Total: 125.50'),
          ],
        ),
      ),
    );

    final bytes = await doc.save();
    // FontFile2 يعني إنه في TrueType مدمج جوّا الملف، مش Helvetica.
    expect(String.fromCharCodes(bytes), contains('FontFile2'));
    expect(bytes.length, greaterThan(1000));
  });
}
