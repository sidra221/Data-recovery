class DashboardStats {
  DashboardStats({
    required this.statusCounts,
    required this.clientReportCounts,
    required this.workStatusCounts,
    required this.totalCustomers,
    required this.totalJobs,
    required this.jobsCreatedToday,
    required this.statusChangesToday,
  });

  final Map<String, int> statusCounts;
  final Map<String, int> clientReportCounts;
  final Map<String, int> workStatusCounts;
  final int totalCustomers;
  final int totalJobs;
  final int jobsCreatedToday;
  final int statusChangesToday;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      statusCounts: _intMap(json['status_counts']),
      clientReportCounts: _intMap(json['client_report_counts']),
      workStatusCounts: _intMap(json['work_status_counts']),
      totalCustomers: json['total_customers'] as int? ?? 0,
      totalJobs: json['total_jobs'] as int? ?? 0,
      jobsCreatedToday: json['jobs_created_today'] as int? ?? 0,
      statusChangesToday: json['status_changes_today'] as int? ?? 0,
    );
  }

  static Map<String, int> _intMap(dynamic value) {
    if (value is! Map) return {};
    return {
      for (final entry in value.entries)
        entry.key.toString(): (entry.value as num?)?.toInt() ?? 0,
    };
  }
}
