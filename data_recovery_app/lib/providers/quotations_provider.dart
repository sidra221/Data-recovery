import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/quotation.dart';
import 'auth_provider.dart';

class QuotationsState {
  const QuotationsState({
    this.quotations = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Quotation> quotations;
  final bool isLoading;
  final String? error;

  QuotationsState copyWith({
    List<Quotation>? quotations,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return QuotationsState(
      quotations: quotations ?? this.quotations,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final quotationsProvider =
    NotifierProvider<QuotationsNotifier, QuotationsState>(QuotationsNotifier.new);

class QuotationsNotifier extends Notifier<QuotationsState> {
  @override
  QuotationsState build() => const QuotationsState();

  ApiClient get _client => ref.read(apiClientProvider);

  Future<void> fetchQuotations(int jobId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await _client.listQuotations(jobId: jobId);
      state = state.copyWith(quotations: page.results, isLoading: false);
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, error: error.message);
      rethrow;
    }
  }

  Future<Quotation> createAndSend(Map<String, dynamic> payload) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final created = await _client.createQuotation(payload);
      final sent = await _client.sendQuotation(created.id);
      state = state.copyWith(
        quotations: [sent, ...state.quotations],
        isLoading: false,
      );
      return sent;
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, error: error.message);
      rethrow;
    }
  }
}
