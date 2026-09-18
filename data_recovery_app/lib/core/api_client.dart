import 'package:dio/dio.dart';

import '../models/customer.dart';
import '../models/dashboard_stats.dart';
import '../models/employee_profile.dart';
import '../models/invoice_view.dart';
import '../models/job.dart';
import '../models/quotation.dart';
import 'constants.dart';
import 'invoice_number_minter.dart';
import 'offline_cache.dart';
import 'secure_storage.dart';

class ApiException implements Exception {
  ApiException(
    this.message, {
    this.statusCode,
    this.data,
    this.code,
    this.isNetworkError = false,
  });

  final String message;
  final int? statusCode;
  final dynamic data;

  /// رمز الخطأ من السيرفر، إذا بعت واحد.
  ///
  /// [message] بتجي بلغة السيرفر، فما بتتبع لغة التطبيق. الرمز بيخلّي
  /// التطبيق يعرض نصّه المترجم، والرسالة تضل احتياطي للأخطاء يلي ما إلها
  /// رمز معروف.
  final String? code;

  /// ما وصلنا للسيرفر أصلاً (مطفّى، مافي نت، انتهت المهلة).
  ///
  /// بيفرق عن خطأ جاي **من** السيرفر (400/403/500): هداك جوابه وصل ومعناه
  /// إن الطلب غلط، فما بينفع نرجع لكاش قديم بدالو.
  final bool isNetworkError;

  @override
  String toString() => message;
}

/// نتيجة إمّا طازة من الشبكة أو محفوظة من آخر مرة نجح فيها الطلب.
class Fresh<T> {
  const Fresh(this.value, this.cachedAt);

  final T value;

  /// وقت حفظ النسخة المعروضة. `null` يعني إنها جاية من الشبكة هلق.
  final DateTime? cachedAt;

  bool get isFromCache => cachedAt != null;
}

class ApiClient {
  ApiClient({
    required this.storage,
    this.onUnauthorized,
    this.cache,
    Dio? dio,
  }) : _dio = dio ??
           Dio(
             BaseOptions(
               baseUrl: AppConstants.apiBaseUrl,
               connectTimeout: const Duration(seconds: 20),
               receiveTimeout: const Duration(seconds: 20),
             ),
           ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Token $token';
          }
          if (AppConstants.apiBaseUrl.contains('ngrok')) {
            options.headers['ngrok-skip-browser-warning'] = 'true';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              !_isLoginRequest(error.requestOptions)) {
            await storage.clearToken();
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final OfflineCache? cache;
  final SecureStorage storage;
  final void Function()? onUnauthorized;

  /// بيجيب من الشبكة وبيحفظ نسخة. إذا السيرفر ما ردّ، بيرجع آخر نسخة محفوظة.
  ///
  /// بيرجع للكاش **بس** لما يكون الفشل شبكة. خطأ جاي من السيرفر (403 مثلاً)
  /// معناه الطلب نفسه غلط، وعرض بيانات قديمة بداله بيخبّي المشكلة.
  Future<Fresh<T>> _cachedGet<T>({
    required String cacheKey,
    required Future<dynamic> Function() fetch,
    required T Function(dynamic json) parse,
  }) async {
    try {
      final data = await fetch();
      await cache?.write(cacheKey, data);
      return Fresh(parse(data), null);
    } on ApiException catch (error) {
      final store = cache;
      if (!error.isNetworkError || store == null) rethrow;
      final cached = await store.read(cacheKey);
      if (cached == null) rethrow;
      try {
        return Fresh(parse(cached.data), cached.savedAt);
      } catch (_) {
        // المحفوظ ما عاد ينفكّ (تغيّر شكل الـ API) — منرجع خطأ الشبكة الأصلي.
        throw error;
      }
    }
  }

  Future<Fresh<DashboardStats>> getDashboardStatsCached() {
    return _cachedGet(
      cacheKey: OfflineCache.keyDashboardStats,
      fetch: () => _get('dashboard/stats/'),
      parse: (json) => DashboardStats.fromJson(json as Map<String, dynamic>),
    );
  }

  /// الصفحة الأولى بدون بحث ولا فلاتر — هي الوحيدة يلي منكاشها، لأن كاش
  /// نتيجة مفلترة ما بينفع نعرضه لفلتر تاني.
  Future<Fresh<PaginatedJobs>> listJobsCached() {
    return _cachedGet(
      cacheKey: OfflineCache.keyJobs,
      fetch: () => _get('jobs/'),
      parse: (json) => PaginatedJobs.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Fresh<PaginatedCustomers>> listCustomersCached() {
    return _cachedGet(
      cacheKey: OfflineCache.keyCustomers,
      fetch: () => _get('customers/'),
      parse: (json) => PaginatedCustomers.fromJson(json as Map<String, dynamic>),
    );
  }

  bool _isLoginRequest(RequestOptions options) {
    return options.path.contains('auth/login');
  }

  Future<EmployeeProfile> login({
    required String username,
    required String password,
  }) async {
    final data = await _post(
      'auth/login/',
      {'username': username, 'password': password},
    );
    return EmployeeProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<EmployeeProfile> getMe() async {
    final data = await _get('auth/me/');
    return EmployeeProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<EmployeeProfile> updateMe({
    Map<String, dynamic>? fields,
    String? photoPath,
    String? photoFilename,
  }) async {
    if (photoPath != null) {
      final form = FormData.fromMap({
        ...?fields,
        'photo': await MultipartFile.fromFile(photoPath, filename: photoFilename),
      });
      final data = await _send(() => _dio.patch<dynamic>('auth/me/', data: form));
      return EmployeeProfile.fromJson(data as Map<String, dynamic>);
    }
    final data = await _patch('auth/me/', fields ?? const {});
    return EmployeeProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<PaginatedJobs> listJobs({
    String? search,
    String? status,
    String? clientReport,
    String? workStatus,
    int? customerId,
    String? createdFrom,
    String? createdTo,
    bool overdue = false,
    int page = 1,
  }) async {
    final data = await _get(
      'jobs/',
      query: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
        if (clientReport != null && clientReport.isNotEmpty) 'client_report': clientReport,
        if (workStatus != null && workStatus.isNotEmpty) 'work_status': workStatus,
        'customer': ?customerId,
        if (createdFrom != null && createdFrom.isNotEmpty) 'created_from': createdFrom,
        if (createdTo != null && createdTo.isNotEmpty) 'created_to': createdTo,
        if (overdue) 'overdue': 'true',
        if (page > 1) 'page': page,
      },
    );
    return PaginatedJobs.fromJson(data as Map<String, dynamic>);
  }

  /// بيحجز مدى أرقام لهالجهاز حتى يقدر يولّد أرقام فواتير وهو أوفلاين.
  /// idempotent — نفس الجهاز بياخد نفس المدى كل مرة.
  Future<NumberBlock> reserveNumberBlock(String deviceId) async {
    final data = await _post('jobs/device-block/', {'device_id': deviceId});
    return NumberBlock.fromJson(data as Map<String, dynamic>);
  }

  Future<Job> createJob(Map<String, dynamic> payload) async {
    final data = await _post('jobs/', payload);
    return Job.fromJson(data as Map<String, dynamic>);
  }

  Future<Job> getJob(int id) async {
    final data = await _get('jobs/$id/');
    return Job.fromJson(data as Map<String, dynamic>);
  }

  Future<Job> updateJob(int id, Map<String, dynamic> payload) async {
    final data = await _patch('jobs/$id/', payload);
    return Job.fromJson(data as Map<String, dynamic>);
  }

  Future<Job> scanBarcode(String barcode) async {
    final data = await _get('jobs/scan/$barcode/');
    return Job.fromJson(data as Map<String, dynamic>);
  }

  Future<Job> updateStatus(int id, {required String status, String note = ''}) async {
    final data = await _post('jobs/$id/status/', {'status': status, 'note': note});
    return Job.fromJson(data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getInvoice(int id) async {
    final data = await _get('jobs/$id/invoice/');
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendInvoice(int id, {String? message}) async {
    final data = await _post(
      'jobs/$id/send/',
      {if (message != null && message.trim().isNotEmpty) 'message': message.trim()},
    );
    return data as Map<String, dynamic>;
  }

  Future<Job> deliverJob(int id) async {
    final data = await _post('jobs/$id/deliver/', {});
    return Job.fromJson(data as Map<String, dynamic>);
  }

  Future<List<JobAttachment>> uploadJobAttachments({
    required int jobId,
    required List<({String path, String name})> files,
  }) async {
    final form = FormData();
    for (final file in files) {
      form.files.add(
        MapEntry(
          'files',
          await MultipartFile.fromFile(file.path, filename: file.name),
        ),
      );
    }
    final data = await _send(() => _dio.post<dynamic>('jobs/$jobId/attachments/', data: form));
    final list = data as List<dynamic>;
    return [
      for (final item in list) JobAttachment.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<Map<String, dynamic>> meta() async {
    final data = await _get('meta/');
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> health() async {
    final data = await _get('health/');
    return data as Map<String, dynamic>;
  }

  Future<PaginatedCustomers> listCustomers({String? search, int page = 1}) async {
    final data = await _get(
      'customers/',
      query: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (page > 1) 'page': page,
      },
    );
    return PaginatedCustomers.fromJson(data as Map<String, dynamic>);
  }

  Future<Customer> getCustomer(int id) async {
    final data = await _get('customers/$id/');
    return Customer.fromJson(data as Map<String, dynamic>);
  }

  Future<Customer> updateCustomer(int id, Map<String, dynamic> payload) async {
    final data = await _patch('customers/$id/', payload);
    return Customer.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteCustomer(int id) async {
    await _delete('customers/$id/');
  }

  Future<PaginatedQuotations> listQuotations({required int jobId}) async {
    final data = await _get('quotations/', query: {'job': jobId});
    return PaginatedQuotations.fromJson(data as Map<String, dynamic>);
  }

  Future<Quotation> createQuotation(Map<String, dynamic> payload) async {
    final data = await _post('quotations/', payload);
    return Quotation.fromJson(data as Map<String, dynamic>);
  }

  Future<Quotation> sendQuotation(int id) async {
    final data = await _post('quotations/$id/send/', {});
    return Quotation.fromJson(data as Map<String, dynamic>);
  }

  Future<InvoiceView> getQuotationInvoice(int quotationId) async {
    final data = await _get('quotations/$quotationId/invoice/');
    return InvoiceView.fromJson(data as Map<String, dynamic>);
  }

  Future<dynamic> _get(String path, {Map<String, dynamic>? query}) {
    return _send(() => _dio.get<dynamic>(path, queryParameters: query));
  }

  Future<dynamic> _post(String path, Map<String, dynamic> data) {
    return _send(() => _dio.post<dynamic>(path, data: data));
  }

  Future<dynamic> _patch(String path, Map<String, dynamic> data) {
    return _send(() => _dio.patch<dynamic>(path, data: data));
  }

  Future<dynamic> _delete(String path) {
    return _send(() => _dio.delete<dynamic>(path));
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (error) {
      throw ApiException(
        _messageFrom(error),
        statusCode: error.response?.statusCode,
        data: error.response?.data,
        code: _codeFrom(error),
        // مافي response = ما وصل جواب من السيرفر بالمرة.
        isNetworkError: error.response == null && error.type != DioExceptionType.cancel,
      );
    }
  }

  String? _codeFrom(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['code'] is String) return data['code'] as String;
    return null;
  }

  String _messageFrom(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      if (data['detail'] is String) return data['detail'] as String;
      if (data['non_field_errors'] is List && (data['non_field_errors'] as List).isNotEmpty) {
        return (data['non_field_errors'] as List).first.toString();
      }
      // أخطاء الحقول من DRF بتجي `{"customer_phone": ["..."]}`. بدون
      // هالجزء كانت بتطلع للموظف «خطأ اتصال» وهو السيرفر رادّ فعلاً —
      // تضليل بيخلّيه يجرّب كمان مرة بدل ما يصلّح الحقل.
      for (final entry in data.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          return '${entry.key}: ${value.first}';
        }
        if (value is String && value.isNotEmpty) {
          return '${entry.key}: $value';
        }
      }
    }
    // وصلنا لهون يعني ما في رد مفهوم — غالباً السيرفر ما ردّ أصلاً.
    return error.message ?? 'A connection error occurred.';
  }
}
