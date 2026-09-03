import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/job.dart';
import 'auth_provider.dart';

class JobsState {
  const JobsState({
    this.jobs = const [],
    this.count = 0,
    this.isLoading = false,
    this.error,
  });

  final List<Job> jobs;
  final int count;
  final bool isLoading;
  final String? error;

  JobsState copyWith({
    List<Job>? jobs,
    int? count,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return JobsState(
      jobs: jobs ?? this.jobs,
      count: count ?? this.count,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final jobsProvider = NotifierProvider<JobsNotifier, JobsState>(JobsNotifier.new);

class JobsNotifier extends Notifier<JobsState> {
  @override
  JobsState build() => const JobsState();

  ApiClient get _client => ref.read(apiClientProvider);

  Future<void> fetchJobs({String? search, String? status}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await _client.listJobs(search: search, status: status);
      state = state.copyWith(
        jobs: page.results,
        count: page.count,
        isLoading: false,
      );
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, error: error.message);
      rethrow;
    }
  }

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
