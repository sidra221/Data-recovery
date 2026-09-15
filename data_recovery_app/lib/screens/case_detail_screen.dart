import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/api_client.dart';
import '../models/job.dart';
import '../providers/auth_provider.dart';
import 'quotation_screen.dart';
import 'widgets/app_button.dart';
import 'widgets/notify_customer_sheet.dart';
import 'widgets/update_status_sheet.dart';

/// تفاصيل قضية واحدة: بيانات العميل والجهاز، الحالات، السعر، المرفقات،
/// وسجل التغييرات — مع أزرار العمل.
///
/// بيعيد استخدام UpdateStatusSheet و NotifyCustomerSheet و QuotationScreen
/// بدل ما يكرّر منطقهن، حتى يضل السلوك واحد بكل التطبيق.
class CaseDetailScreen extends ConsumerStatefulWidget {
  const CaseDetailScreen({super.key, required this.jobId});

  final int jobId;

  @override
  ConsumerState<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends ConsumerState<CaseDetailScreen> {
  Job? _job;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final l = L.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final job = await ref.read(apiClientProvider).getJob(widget.jobId);
      if (!mounted) return;
      setState(() {
        _job = job;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message.isNotEmpty ? error.message : l.failedToLoadCase;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = l.failedToLoadCase;
      });
    }
  }

  void _openQuotation(Job job) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuotationScreen(
          jobId: job.id,
          jobCustomerName: job.customerName,
          jobCustomerPhone: job.customerPhone,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final job = _job;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          job == null ? l.caseTitle : '#${job.invoiceNumber}',
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: _buildBody(job),
    );
  }

  Widget _buildBody(Job? job) {
    final l = L.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 40, color: Color(0xFF9CA3AF)),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: Text(l.retry)),
            ],
          ),
        ),
      );
    }

    if (job == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _StatusStrip(job: job),
          const SizedBox(height: 16),
          _Section(
            title: l.sectionCustomer,
            rows: [
              (l.labelName, job.customerName),
              (l.labelPhone, job.customerPhone),
              if (job.customerEmail.isNotEmpty) (l.labelEmail, job.customerEmail),
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: l.sectionDevice,
            rows: [
              (
                l.labelType,
                job.hardDiskTypeLabel.isNotEmpty
                    ? job.hardDiskTypeLabel
                    : job.hardDiskType
              ),
              if (job.deviceModel.isNotEmpty) (l.labelModel, job.deviceModel),
              if (job.serialNumber.isNotEmpty) (l.labelSerial, job.serialNumber),
              if (job.attachedEquipment.isNotEmpty)
                (l.labelAttached, job.attachedEquipment),
              if (job.problem.isNotEmpty) (l.labelProblem, job.problem),
              if (job.inspectionNotes.isNotEmpty)
                (l.labelInspection, job.inspectionNotes),
              if (job.notes.isNotEmpty) (l.labelNotes, job.notes),
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: l.sectionBilling,
            rows: [
              (l.labelInvoice, '#${job.invoiceNumber}'),
              (l.labelBarcode, job.barcode),
              (l.labelPrice, job.price == null ? l.notSet : _money(job.price!)),
              (
                l.labelInvoiceSent,
                job.invoiceSentAt == null
                    ? l.no
                    : _dateTime(job.invoiceSentAt!)
              ),
              if (job.deliveredAt != null)
                (l.labelDelivered, _dateTime(job.deliveredAt!)),
            ],
          ),
          const SizedBox(height: 12),
          _AttachmentsSection(job: job),
          const SizedBox(height: 12),
          _TimelineSection(job: job),
          const SizedBox(height: 22),
          AppButton(
            label: l.updateStatus,
            onPressed: () => UpdateStatusSheet.show(
              context,
              job: job,
              onUpdated: _load,
            ),
          ),
          const SizedBox(height: 10),
          AppTextButton(
            label: l.notifyCustomer,
            onPressed: () => NotifyCustomerSheet.show(context, jobId: job.id),
          ),
          const SizedBox(height: 10),
          AppTextButton(
            label: l.quotationInvoice,
            onPressed: () => _openQuotation(job),
          ),
        ],
      ),
    );
  }
}

String _money(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);

String _dateTime(DateTime value) =>
    DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());

/// شارات الحالات التلاتة جنب بعض — الحالة العامة وحالة الشغل وقرار العميل.
class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final chips = <({String label, String value, Color bg, Color fg})>[
      (
        label: l.labelStatus,
        value: job.statusLabel.isNotEmpty ? job.statusLabel : job.status,
        bg: const Color(0xFFE5F9FD),
        fg: const Color(0xFF0E7490),
      ),
      if (job.workStatusLabel.isNotEmpty)
        (
          label: l.labelWork,
          value: job.workStatusLabel,
          bg: const Color(0xFFDCFCE7),
          fg: const Color(0xFF16A34A),
        ),
      if (job.clientReportLabel.isNotEmpty)
        (
          label: l.labelClient,
          value: job.clientReportLabel,
          bg: const Color(0xFFFFF4E5),
          fg: const Color(0xFFB45309),
        ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in chips)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: c.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: c.fg.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  c.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: c.fg,
                  ),
                ),
              ],
            ),
          ),
        if (job.waitClientOverdue)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE4E6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 16, color: Color(0xFFF04D4E)),
                SizedBox(width: 6),
                Text(
                  l.overdue,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFF04D4E),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: child,
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title, {this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// قسم بسيط: عنوان + أسطر «تسمية / قيمة». الأسطر الفاضية بتنشال قبل ما توصل.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final visible = rows.where((r) => r.$2.trim().isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(title),
          const SizedBox(height: 10),
          for (final row in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(
                      row.$1,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF374151),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AttachmentsSection extends StatelessWidget {
  const _AttachmentsSection({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            l.sectionAttachments,
            trailing: Text(
              '${job.attachments.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (job.attachments.isEmpty)
            Text(
              l.noAttachments,
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            )
          else
            for (final a in job.attachments)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file,
                        size: 16, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        a.originalName.isNotEmpty ? a.originalName : 'file',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF374151)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

/// سجل تغييرات الحالة، الأحدث فوق.
class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final logs = [...job.statusLogs]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(l.sectionHistory),
          const SizedBox(height: 10),
          if (logs.isEmpty)
            Text(
              l.noChangesYet,
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            )
          else
            for (final log in logs)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(top: 5, right: 9),
                      decoration: const BoxDecoration(
                        color: Color(0xFF33BEE9),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.statusLabel.isNotEmpty
                                ? log.statusLabel
                                : log.status,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          if (log.note.isNotEmpty)
                            Text(
                              log.note,
                              style: const TextStyle(
                                  fontSize: 12.5, color: Color(0xFF6B7280)),
                            ),
                          Text(
                            '${_dateTime(log.createdAt)}'
                            '${log.createdByName.isNotEmpty ? ' · ${log.createdByName}' : ''}',
                            style: const TextStyle(
                                fontSize: 11.5, color: Color(0xFF9CA3AF)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
