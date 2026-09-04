import 'package:dio/dio.dart';

import '../models/customer.dart';
import '../models/dashboard_stats.dart';
import '../models/invoice_view.dart';
import '../models/job.dart';
import '../models/quotation.dart';
import 'constants.dart';
import 'secure_storage.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.data});

  final String message;
  final int? statusCode;
  final dynamic data;

  @override
  String toString() => message;
}

class LoginResult {
  LoginResult({
    required this.token,
    required this.userId,
    required this.username,
  });

  final String token;
  final int userId;
  final String username;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      token: json['token'] as String,
      userId: json['user_id'] as int,
      username: json['username'] as String,
    );
  }
}

class ApiClient {
  ApiClient({
    required this.storage,
    this.onUnauthorized,
    Dio? dio,
  }) : _dio = dio ??
           Dio(
             BaseOptions(
               baseUrl: AppConstants.apiBaseUrl,
               headers: const {'Content-Type': 'application/json'},
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
  final SecureStorage storage;
  final void Function()? onUnauthorized;

  bool _isLoginRequest(RequestOptions options) {
    return options.path.contains('auth/login');
  }

  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    final data = await _post(
      'auth/login/',
      {'username': username, 'password': password},
    );
    return LoginResult.fromJson(data as Map<String, dynamic>);
  }

  Future<PaginatedJobs> listJobs({String? search, String? status}) async {
    final data = await _get(
      'jobs/',
      query: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return PaginatedJobs.fromJson(data as Map<String, dynamic>);
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

  Future<Map<String, dynamic>> sendInvoice(int id) async {
    final data = await _post('jobs/$id/send/', {});
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> meta() async {
    final data = await _get('meta/');
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> health() async {
    final data = await _get('health/');
    return data as Map<String, dynamic>;
  }

  Future<DashboardStats> getDashboardStats() async {
    final data = await _get('dashboard/stats/');
    return DashboardStats.fromJson(data as Map<String, dynamic>);
  }

  Future<PaginatedCustomers> listCustomers({String? search}) async {
    final data = await _get(
      'customers/',
      query: {
        if (search != null && search.isNotEmpty) 'search': search,
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
      );
    }
  }

  String _messageFrom(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      if (data['detail'] is String) return data['detail'] as String;
      if (data['non_field_errors'] is List && (data['non_field_errors'] as List).isNotEmpty) {
        return (data['non_field_errors'] as List).first.toString();
      }
    }
    return error.message ?? 'A connection error occurred.';
  }
}
