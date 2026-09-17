import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/invoice_number_minter.dart';
import '../core/pending_queue.dart';
import '../models/job.dart';
import 'auth_provider.dart';
import 'sync_provider.dart';

class JobsState {
  const JobsState({
    this.jobs = const [],
    this.count = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.cachedAt,
  });

  final List<Job> jobs;
  final int count;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  /// وقت حفظ النسخة المعروضة. مو `null` يعني السيرفر ما ردّ وهاي بيانات محفوظة.
  final DateTime? cachedAt;

  bool get isFromCache => cachedAt != null;

  bool get hasMore => jobs.length < count;

  JobsState copyWith({
    List<Job>? jobs,
    int? count,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    DateTime? cachedAt,
    bool clearCachedAt = false,
  }) {
    return JobsState(
      jobs: jobs ?? this.jobs,
      count: count ?? this.count,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      cachedAt: clearCachedAt ? null : cachedAt ?? this.cachedAt,
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

  /// الكاش بيخدم الصفحة الأولى بدون بحث ولا فلتر بس. أي فلتر مختار معناه
  /// إن المحفوظ (وهو قائمة كاملة غير مفلترة) ما بيمثّل يلي المستخدم طالبه.
  bool get _isPlainFirstPage =>
      (_search == null || _search!.isEmpty) &&
      (_status == null || _status!.isEmpty) &&
      (_clientReport == null || _clientReport!.isEmpty) &&
      (_workStatus == null || _workStatus!.isEmpty);

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
      if (!append && _isPlainFirstPage) {
        final fresh = await _client.listJobsCached();
        state = state.copyWith(
          jobs: fresh.value.results,
          count: fresh.value.count,
          isLoading: false,
          isLoadingMore: false,
          cachedAt: fresh.cachedAt,
          clearCachedAt: !fresh.isFromCache,
        );
        return;
      }
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

  Future<void> loadMore() => fetchJobs(append: true);

  Future<Job> createJob(Map<String, dynamic> payload) async {
    try {
      final job = await _client.createJob(payload);
      state = state.copyWith(jobs: [job, ...state.jobs], count: state.count + 1);
      return job;
    } on ApiException catch (error) {
      if (!error.isNetworkError) rethrow;
      // السيرفر مطفّى والعميل واقف عالكاونتر — منسجّل محلياً برقم من المدى
      // المحجوز، حتى يقدر يطبع الستيكر والسند فوراً.
      return _createOffline(payload);
    }
  }

  Future<Job> _createOffline(Map<String, dynamic> payload) async {
    final number = await ref.read(invoiceMinterProvider).mint();
    if (number == null) throw const OfflineNumbersExhausted();

    final queued = {...payload, 'invoice_number': number};
    await ref.read(pendingQueueProvider).add(
          kind: PendingKind.createJob,
          payload: queued,
        );
    await ref.read(syncProvider.notifier).refresh();

    final job = _localJob(queued);
    state = state.copyWith(jobs: [job, ...state.jobs], count: state.count + 1);
    return job;
  }

  /// عملية موجودة على الجهاز بس وما وصلت السيرفر بعد.
  ///
  /// الـ id سالب عن قصد: السيرفر ما بيعطي أرقام سالبة، فأي شي سالب معناه
  /// «لسا ما انرفع». الشاشات بتعتمد على هالشي حتى ما تحاول ترفع مرفقات
  /// لعملية ما إلها id حقيقي.
  Job _localJob(Map<String, dynamic> payload) {
    final now = DateTime.now();
    return Job.fromJson({
      ...payload,
      'id': -now.millisecondsSinceEpoch,
      'barcode': payload['invoice_number'],
      'status': payload['status'] ?? 'received',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
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
