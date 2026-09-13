import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/job.dart';
import 'auth_provider.dart';

class JobsState {
  const JobsState({
    this.jobs = const [],
    this.count = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<Job> jobs;
  final int count;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  bool get hasMore => jobs.length < count;

  JobsState copyWith({
    List<Job>? jobs,
    int? count,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return JobsState(
      jobs: jobs ?? this.jobs,
      count: count ?? this.count,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final jobsProvider = NotifierProvider<JobsNotifier, JobsState>(JobsNotifier.new);

class JobsNotifier extends Notifier<JobsState> {
  @override
  JobsState build() => const JobsState();

  ApiClient get _client => ref.read(apiClientProvider);

  String? _search;
  String? _status;
  String? _clientReport;
  String? _workStatus;

  Future<void> fetchJobs({
    String? search,
    String? status,
    String? clientReport,
    String? workStatus,
    bool append = false,
  }) async {
    if (!append) {
      _search = search;
      _status = status;
      _clientReport = clientReport;
      _workStatus = workStatus;
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      if (!state.hasMore || state.isLoadingMore) return;
      state = state.copyWith(isLoadingMore: true, clearError: true);
    }
    try {
      final page = await _client.listJobs(
        search: _search,
        status: _status,
        clientReport: _clientReport,
        workStatus: _workStatus,
        page: append ? (state.jobs.length ~/ 20) + 1 : 1,
      );
      state = state.copyWith(
        jobs: append ? [...state.jobs, ...page.results] : page.results,
        count: page.count,
        isLoading: false,
        isLoadingMore: false,
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

  Future<void> loadMore() => fetchJobs(append: true);

  Future<Job> createJob(Map<String, dynamic> payload) async {
    final job = await _client.createJob(payload);
    state = state.copyWith(jobs: [job, ...state.jobs], count: state.count + 1);
    return job;
  }

  Future<Job> getJob(int id) {
    return _client.getJob(id);
  }

  Future<Job> updateJob(int id, Map<String, dynamic> payload) async {
    final job = await _client.updateJob(id, payload);
    _replace(job);
    return job;
  }

  Future<Job> deliverJob(int id) async {
    final job = await _client.deliverJob(id);
    _replace(job);
    return job;
  }

  Future<Job> scanBarcode(String barcode) {
    return _client.scanBarcode(barcode);
  }

  Future<Job> updateStatus(int id, {required String status, String note = ''}) async {
    final job = await _client.updateStatus(id, status: status, note: note);
    _replace(job);
    return job;
  }

  void _replace(Job job) {
    state = state.copyWith(
      jobs: [
        for (final item in state.jobs)
          if (item.id == job.id) job else item,
      ],
    );
  }
}
