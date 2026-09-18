import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

import 'package:intl/date_symbol_data_local.dart';

import 'package:data_recovery_app/core/pdf_theme.dart';
import 'package:data_recovery_app/core/print_templates.dart';
import 'package:data_recovery_app/models/job.dart';

Job _job({
  String customerName = 'أحمد اليافعي',
  String problem = 'لا يعمل من قبل المستخدم',
  String model = 'Toshiba',
  String serial = 'PDAC2',
  String equipment = 'كيبل وعلبة',
}) {
  return Job.fromJson({
    'id': 1,
    'invoice_number': '01-20260917-0013',
    'barcode': '01-20260917-0013',
    'customer_name': customerName,
    'customer_phone': '0558447148',
    'customer_email': 'a@example.com',
    'hard_disk_type': 'external',
    'hard_disk_type_label': 'HDD External 2.5',
    'status': 'received',
    'status_label': 'Received',
    'device_model': model,
    'serial_number': serial,
    'problem': problem,
    'attached_equipment': equipment,
    'created_at': '2026-09-17T09:00:00Z',
    'updated_at': '2026-09-17T09:00:00Z',
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // التواريخ بالمطبوعات بتستعمل DateFormat، وهي بدها تهيئة
    // بتصير عادة بـ main.dart.
    await initializeDateFormatting('en');

    // القوالب بتقرا الخطوط من rootBundle، وبالاختبار ما في أصول محمّلة —
    // منوصلها للملفات مباشرة.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      final file = File(key);
      if (!file.existsSync()) return null;
      return file.readAsBytesSync().buffer.asByteData();
    });
  });

  group('اتجاه النص بالمستندات', () {
    // النص العربي كان بينطبع معكوس لأن اتجاه الصفحة إنكليزي. القرار
    // بينبنى على محتوى كل نص، فهاد الفحص هو نقطة القرار.
    test('بيميّز العربي عن اللاتيني', () {
      expect(hasArabic('أحمد اليافعي'), isTrue);
      expect(hasArabic('لا يعمل من قبل المستخدم'), isTrue);
      expect(hasArabic('hussam awad'), isFalse);
      expect(hasArabic('01-20260917-0013'), isFalse);
      expect(hasArabic('HDD External 2.5'), isFalse);
    });

    test('نص مختلط فيه عربي بيتعامل كعربي', () {
      expect(hasArabic('01 لاستعادة البيانات'), isTrue);
      expect(hasArabic('Invoice: فاتورة'), isTrue);
    });

    test('نص فاضي مو عربي', () {
      expect(hasArabic(''), isFalse);
    });
  });

  group('ستيكر القطعة', () {
    test('بيطلع PDF صالح بخط مدمج', () async {
      final bytes = await PrintTemplates.sticker(
        job: _job(),
        companyName: '01 Data Recovery',
      );

      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(8)), startsWith('%PDF'));
      // FontFile2 = في TrueType مدمج، يعني العربي رح يطلع مو مربعات.
      expect(String.fromCharCodes(bytes), contains('FontFile2'));
    });

    test('مقاس الصفحة بيطابق مقاس الملصق المضبوط', () async {
      final bytes = await PrintTemplates.sticker(
        job: _job(),
        companyName: '01',
      );

      final media = RegExp(r'/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)')
          .firstMatch(String.fromCharCodes(bytes));
      expect(media, isNotNull, reason: 'ما لقينا مقاس الصفحة بالملف');

      // 1 ملم = 2.8346 نقطة
      expect(
        double.parse(media!.group(1)!),
        closeTo(PrintTemplates.stickerWidthMm * 2.8346, 1),
      );
      expect(
        double.parse(media.group(2)!),
        closeTo(PrintTemplates.stickerHeightMm * 2.8346, 1),
      );
    });

    test('بيشتغل مع حقول فاضية بدون ما ينهار', () async {
      final bytes = await PrintTemplates.sticker(
        job: _job(problem: '', model: '', serial: ''),
        companyName: '01',
      );
      expect(bytes.length, greaterThan(1000));
    });
  });

  group('سند الاستلام', () {
    test('بيطلع PDF صالح بخط مدمج', () async {
      final bytes = await PrintTemplates.receivingReceipt(
        job: _job(),
        companyName: '01 Data Recovery',
      );

      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(8)), startsWith('%PDF'));
      expect(String.fromCharCodes(bytes), contains('FontFile2'));
    });

    test('مقاسه A4', () async {
      final bytes = await PrintTemplates.receivingReceipt(
        job: _job(),
        companyName: '01',
      );

      final media = RegExp(r'/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)')
          .firstMatch(String.fromCharCodes(bytes));
      expect(double.parse(media!.group(1)!), closeTo(595, 2));
      expect(double.parse(media.group(2)!), closeTo(842, 2));
    });

    test('بيشتغل بدون ملحقات ولا ملاحظات', () async {
      final bytes = await PrintTemplates.receivingReceipt(
        job: _job(problem: '', equipment: ''),
        companyName: '01',
      );
      expect(bytes.length, greaterThan(1000));
    });
  });
}
