import 'package:flutter_test/flutter_test.dart';

import 'package:data_recovery_app/models/job.dart';

Map<String, dynamic> _jobJson({dynamic price}) => <String, dynamic>{
      'id': 1,
      'invoice_number': '01-20260915-0001',
      'barcode': '01-20260915-0001',
      'customer_name': 'محمد',
      'customer_phone': '0791234567',
      'hard_disk_type': 'hdd_35',
      'status': 'received',
      'created_at': '2026-09-15T10:00:00+03:00',
      'updated_at': '2026-09-15T10:00:00+03:00',
      'price': ?price,
    };

void main() {
  group('قراءة السعر من الـ API', () {
    test('نص عشري (شكل DRF الافتراضي)', () {
      expect(Job.fromJson(_jobJson(price: '150.00')).price, 150.0);
    });

    test('نص فيه كسور', () {
      expect(Job.fromJson(_jobJson(price: '99.50')).price, 99.5);
    });

    test('رقم (لو COERCE_DECIMAL_TO_STRING = False)', () {
      expect(Job.fromJson(_jobJson(price: 250)).price, 250.0);
    });

    test('null — قضية بدون سعر محدّد', () {
      expect(Job.fromJson(_jobJson()).price, isNull);
    });

    test('قيمة خربوطة ما بتكسر التطبيق', () {
      expect(Job.fromJson(_jobJson(price: 'abc')).price, isNull);
    });
  });
}
