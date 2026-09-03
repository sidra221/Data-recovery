import 'status_log.dart';

DateTime? _parseDateTime(dynamic value) {
  if (value == null || value == '') return null;
  return DateTime.tryParse(value as String);
}

class Job {
  Job({
    required this.id,
    required this.invoiceNumber,
    required this.barcode,
    required this.customerName,
    required this.customerPhone,
    required this.hardDiskType,
    required this.hardDiskTypeLabel,
    required this.status,
    required this.statusLabel,
    required this.clientReport,
    required this.clientReportLabel,
    required this.workStatus,
    required this.workStatusLabel,
    required this.notes,
    required this.problem,
    required this.deviceModel,
    required this.serialNumber,
    required this.customerEmail,
    required this.attachedEquipment,
    required this.inspectionNotes,
    required this.createdByName,
    required this.invoiceSent,
    required this.invoiceSentAt,
    required this.readyNotifiedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.statusLogs,
  });

  final int id;
  final String invoiceNumber;
  final String barcode;
  final String customerName;
  final String customerPhone;
  final String hardDiskType;
  final String hardDiskTypeLabel;
  final String status;
  final String statusLabel;
  final String clientReport;
  final String clientReportLabel;
  final String workStatus;
  final String workStatusLabel;
  final String notes;
  final String problem;
  final String deviceModel;
  final String serialNumber;
  final String customerEmail;
  final String attachedEquipment;
  final String inspectionNotes;
  final String createdByName;
  final bool invoiceSent;
  final DateTime? invoiceSentAt;
  final DateTime? readyNotifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<StatusLog> statusLogs;

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as int,
      invoiceNumber: json['invoice_number'] as String,
      barcode: json['barcode'] as String,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String,
      hardDiskType: json['hard_disk_type'] as String,
      hardDiskTypeLabel: json['hard_disk_type_label'] as String? ?? '',
      status: json['status'] as String,
      statusLabel: json['status_label'] as String? ?? '',
      clientReport: json['client_report'] as String? ?? '',
      clientReportLabel: json['client_report_label'] as String? ?? '',
      workStatus: json['work_status'] as String? ?? '',
      workStatusLabel: json['work_status_label'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      problem: json['problem'] as String? ?? '',
      deviceModel: json['device_model'] as String? ?? '',
      serialNumber: json['serial_number'] as String? ?? '',
      customerEmail: json['customer_email'] as String? ?? '',
      attachedEquipment: json['attached_equipment'] as String? ?? '',
      inspectionNotes: json['inspection_notes'] as String? ?? '',
      createdByName: json['created_by_name'] as String? ?? '',
      invoiceSent: json['invoice_sent'] as bool? ?? false,
      invoiceSentAt: _parseDateTime(json['invoice_sent_at']),
      readyNotifiedAt: _parseDateTime(json['ready_notified_at']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      statusLogs: [
        for (final item in json['status_logs'] as List<dynamic>? ?? const [])
          StatusLog.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'barcode': barcode,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'hard_disk_type': hardDiskType,
      'hard_disk_type_label': hardDiskTypeLabel,
      'status': status,
      'status_label': statusLabel,
      'client_report': clientReport,
      'client_report_label': clientReportLabel,
      'work_status': workStatus,
      'work_status_label': workStatusLabel,
      'notes': notes,
      'problem': problem,
      'device_model': deviceModel,
      'serial_number': serialNumber,
      'customer_email': customerEmail,
      'attached_equipment': attachedEquipment,
      'inspection_notes': inspectionNotes,
      'created_by_name': createdByName,
      'invoice_sent': invoiceSent,
      'invoice_sent_at': invoiceSentAt?.toIso8601String(),
      'ready_notified_at': readyNotifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status_logs': [for (final log in statusLogs) log.toJson()],
    };
  }
}

class PaginatedJobs {
  PaginatedJobs({required this.count, required this.results});

  final int count;
  final List<Job> results;

  factory PaginatedJobs.fromJson(Map<String, dynamic> json) {
    return PaginatedJobs(
      count: json['count'] as int? ?? 0,
      results: [
        for (final item in json['results'] as List<dynamic>? ?? const [])
          Job.fromJson(item as Map<String, dynamic>),
      ],
    );
  }
}
