import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/customer.dart';
import 'auth_provider.dart';

class CustomersState {
  const CustomersState({
    this.customers = const [],
    this.count = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.cachedAt,
  });

  final List<Customer> customers;
  final int count;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  /// وقت حفظ النسخة المعروضة. مو `null` يعني بيانات محفوظة، مو من الشبكة.
  final DateTime? cachedAt;

  bool get isFromCache => cachedAt != null;

  bool get hasMore => customers.length < count;

  CustomersState copyWith({
    List<Customer>? customers,
    int? count,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    DateTime? cachedAt,
    bool clearCachedAt = false,
  }) {
    return CustomersState(
      customers: customers ?? this.customers,
      count: count ?? this.count,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      cachedAt: clearCachedAt ? null : cachedAt ?? this.cachedAt,
    );
  }
}

final customersProvider =
    NotifierProvider<CustomersNotifier, CustomersState>(CustomersNotifier.new);

class CustomersNotifier extends Notifier<CustomersState> {
  @override
  CustomersState build() => const CustomersState();

  ApiClient get _client => ref.read(apiClientProvider);
  String? _search;

  Future<void> fetchCustomers({String? search, bool append = false}) async {
    if (!append) {
      _search = search;
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      if (!state.hasMore || state.isLoadingMore) return;
      state = state.copyWith(isLoadingMore: true, clearError: true);
    }
    try {
      if (!append && (_search == null || _search!.isEmpty)) {
        final fresh = await _client.listCustomersCached();
        state = state.copyWith(
          customers: fresh.value.results,
          count: fresh.value.count,
          isLoading: false,
          isLoadingMore: false,
          cachedAt: fresh.cachedAt,
          clearCachedAt: !fresh.isFromCache,
        );
        return;
      }
      final page = await _client.listCustomers(
        search: _search,
        page: append ? (state.customers.length ~/ 20) + 1 : 1,
      );
      state = state.copyWith(
        customers: append ? [...state.customers, ...page.results] : page.results,
        count: page.count,
        isLoading: false,
        isLoadingMore: false,
        clearCachedAt: true,
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: error.message,
      );
      rethrow;
    }
  }

  Future<void> loadMore() => fetchCustomers(append: true);

  Future<Customer> updateCustomer(int id, Map<String, dynamic> payload) {
    return _client.updateCustomer(id, payload);
  }

  Future<void> deleteCustomer(int id) {
    return _client.deleteCustomer(id);
  }
}
