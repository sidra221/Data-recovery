import 'package:flutter_test/flutter_test.dart';

import 'package:data_recovery_app/core/arabic_text.dart';

/// مدى أشكال العرض العربية (Arabic Presentation Forms-A/B).
bool _isPresentationForm(int c) =>
    (c >= 0xFB50 && c <= 0xFDFF) || (c >= 0xFE70 && c <= 0xFEFF);

void main() {
  group('كشف العربي', () {
    test('بيميّز العربي عن اللاتيني', () {
      expect(hasArabic('أحمد اليافعي'), isTrue);
      expect(hasArabic('hussam awad'), isFalse);
      expect(hasArabic('01-16720'), isFalse);
      expect(hasArabic(''), isFalse);
    });

    test('نص مختلط بينعدّ عربي', () {
      expect(hasArabic('Invoice: فاتورة'), isTrue);
    });
  });

  group('تحضير النص للـ PDF', () {
    test('النص غير العربي بيمرق متل ما هو', () {
      for (final s in ['01 Data Recovery', '01-16720', '', 'HDD 2.5']) {
        expect(shapeForPdf(s), s);
      }
    });

    test('بيحوّل الحروف لأشكال موصولة', () {
      // بدونها بتنرسم الحروف بشكلها المنفصل وبتطلع «ﺍﺱﻡ ﺍﻝ ﻉﻡﻱﻝ».
      final out = shapeForPdf('اسم العميل');
      expect(
        out.codeUnits.any(_isPresentationForm),
        isTrue,
        reason: 'لازم يحتوي أشكال عرض مو حروف أساسية',
      );
    });

    test('بيعكس ترتيب الكلمات — هون كان الخلل', () {
      // `arabic.convert` بتعكس النص كله فبتصير «العميل اسم». منعكس
      // ترتيب الكلمات حتى نرجّع المعنى.
      final shaped = shapeForPdf('اسم العميل').split(' ');
      final first = shapeForPdf('اسم');
      final second = shapeForPdf('العميل');

      expect(shaped.length, 2);
      expect(shaped.first, second, reason: 'الكلمة الأخيرة بتنرسم أول (يسار)');
      expect(shaped.last, first, reason: 'الكلمة الأولى بتنرسم آخر (يمين)');
    });

    test('عدد الكلمات ما بيتغيّر', () {
      for (final s in [
        'محمد صلاح',
        'لا يعمل ومفتوح من قبل المستخدم',
        'الملحقات المرافقة',
      ]) {
        expect(shapeForPdf(s).split(' ').length, s.split(' ').length);
      }
    });

    test('الكلمات اللاتينية جوّا نص عربي بتضل متل ما هي', () {
      final out = shapeForPdf('الرقم 16720 للعميل');
      expect(out.split(' '), contains('16720'));
    });

    test('كلمة وحدة ما بيتأثر ترتيبها', () {
      expect(shapeForPdf('محمد').split(' ').length, 1);
    });
  });
}
