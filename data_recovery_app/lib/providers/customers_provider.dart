import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/customer.dart';
import 'auth_provider.dart';

class CustomersState {
  const CustomersState({
    this.customers = const [],
    this.count = 0,
    this.isLoading = false,
    this.error,
  });

  final List<Customer> customers;
  final int count;
  final bool isLoading;
  final String? error;

  CustomersState copyWith({
    List<Customer>? customers,
    int? count,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CustomersState(
      customers: customers ?? this.customers,
      count: count ?? this.count,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final customersProvider =
    NotifierProvider<CustomersNotifier, CustomersState>(CustomersNotifier.new);

class CustomersNotifier extends Notifier<CustomersState> {
  @override
  CustomersState build() => const CustomersState();

  ApiClient get _client => ref.read(apiClientProvider);

  Future<void> fetchCustomers({String? search}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await _client.listCustomers(search: search);
      state = state.copyWith(
        customers: page.results,
        count: page.count,
        isLoading: false,
      );
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, error: error.message);
      rethrow;
    }
  }

  Future<Customer> updateCustomer(int id, Map<String, dynamic> payload) {
    return _client.updateCustomer(id, payload);
  }

  Future<void> deleteCustomer(int id) {
    return _client.deleteCustomer(id);
  }
}
