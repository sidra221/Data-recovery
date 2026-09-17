import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:data_recovery_app/core/api_client.dart';
import 'package:data_recovery_app/core/offline_cache.dart';
import 'package:data_recovery_app/core/secure_storage.dart';

final _statsJson = <String, dynamic>{
  'status_counts': {'received': 3},
  'client_report_counts': {'finished': 1},
  'work_status_counts': {'finished': 2},
  'total_customers': 4,
  'total_jobs': 3,
  'jobs_created_today': 0,
  'status_changes_today': 0,
  'total_delivered': 0,
};

/// Dio بيرجّع الرد المطلوب بدون ما يلمس الشبكة.
Dio _dioReturning(Object data) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(
        Response<dynamic>(requestOptions: options, data: data, statusCode: 200),
      ),
    ),
  );
  return dio;
}

/// Dio بيفشل بدون ما يوصل للسيرفر — زي ما بيصير لما السيرفر يكون مطفّى.
Dio _dioOffline() {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'connection refused',
        ),
      ),
    ),
  );
  return dio;
}

/// Dio بيرجّع خطأ **من** السيرفر — الطلب وصل وانرفض.
Dio _dioRejecting(int statusCode) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.reject(
        DioException(
          requestOptions: options,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: statusCode,
            data: {'detail': 'rejected'},
          ),
        ),
      ),
    ),
  );
  return dio;
}

ApiClient _client(Dio dio, OfflineCache cache) {
  return ApiClient(storage: SecureStorage(), cache: cache, dio: dio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OfflineCache cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cache = OfflineCache(prefs: await SharedPreferences.getInstance());
  });

  group('OfflineCache', () {
    test('بيحفظ وبيرجّع نفس البيانات مع وقت الحفظ', () async {
      await cache.write('k', {'a': 1});
      final got = await cache.read('k');

      expect(got, isNotNull);
      expect(got!.data, {'a': 1});
      expect(
        DateTime.now().difference(got.savedAt).inSeconds,
        lessThan(5),
        reason: 'وقت الحفظ لازم يكون هلق تقريباً',
      );
    });

    test('مفتاح ما انحفظ بيرجّع null', () async {
      expect(await cache.read('ما_موجود'), isNull);
    });

    test('clear بتمسح كل شي', () async {
      await cache.write('a', 1);
      await cache.write('b', 2);
      await cache.clear();

      expect(await cache.read('a'), isNull);
      expect(await cache.read('b'), isNull);
    });
  });

  group('الرجوع للكاش لما السيرفر يطفى', () {
    test('نجاح الشبكة: بيرجّع طازة وبيحفظ نسخة', () async {
      final fresh =
          await _client(_dioReturning(_statsJson), cache).getDashboardStatsCached();

      expect(fresh.isFromCache, isFalse);
      expect(fresh.cachedAt, isNull);
      expect(fresh.value.totalJobs, 3);
      expect(
        await cache.read(OfflineCache.keyDashboardStats),
        isNotNull,
        reason: 'لازم يكون حفظ نسخة للمرة الجاية',
      );
    });

    test('السيرفر مطفّى + في كاش: بيرجّع المحفوظ مو خطأ', () async {
      await _client(_dioReturning(_statsJson), cache).getDashboardStatsCached();

      final fresh = await _client(_dioOffline(), cache).getDashboardStatsCached();

      expect(fresh.isFromCache, isTrue);
      expect(fresh.cachedAt, isNotNull);
      expect(fresh.value.totalJobs, 3);
    });

    test('السيرفر مطفّى وما في كاش: بيرمي خطأ شبكة', () async {
      await expectLater(
        _client(_dioOffline(), cache).getDashboardStatsCached(),
        throwsA(
          isA<ApiException>().having((e) => e.isNetworkError, 'isNetworkError', isTrue),
        ),
      );
    });

    test('خطأ من السيرفر (403) ما بيرجّع كاش قديم', () async {
      await _client(_dioReturning(_statsJson), cache).getDashboardStatsCached();

      // الطلب وصل والسيرفر رفضه. عرض بيانات قديمة بداله بيخبّي المشكلة.
      await expectLater(
        _client(_dioRejecting(403), cache).getDashboardStatsCached(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isNetworkError, 'isNetworkError', isFalse)
              .having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });

    test('بدون كاش مربوط: الفشل بيضل فشل', () async {
      final client = ApiClient(storage: SecureStorage(), dio: _dioOffline());

      await expectLater(
        client.getDashboardStatsCached(),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
