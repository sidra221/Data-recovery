import 'package:flutter/material.dart';

import '../../core/api_error_text.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/job.dart';
import '../../providers/jobs_provider.dart';
import '../quotation_screen.dart';
import 'app_button.dart';
import 'soft_surface.dart';

class UpdateStatusSheet extends ConsumerStatefulWidget {
  const UpdateStatusSheet({
    super.key,
    required this.job,
    this.onUpdated,
  });

  final Job job;
  final VoidCallback? onUpdated;

  static Future<void> show(
    BuildContext context, {
    required Job job,
    VoidCallback? onUpdated,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => UpdateStatusSheet(job: job, onUpdated: onUpdated),
    );
  }

  @override
  ConsumerState<UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends ConsumerState<UpdateStatusSheet> {
  String? _submitting;

  Future<void> _patch(Map<String, dynamic> payload, String key) async {
    final l = L.of(context);
    if (_submitting != null) return;
    setState(() => _submitting = key);
    try {
      if (payload.containsKey('deliver')) {
        await ref.read(jobsProvider.notifier).deliverJob(widget.job.id);
      } else {
        await ref.read(jobsProvider.notifier).updateJob(widget.job.id, payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onUpdated?.call();
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(apiErrorText(l, error, fallback: l.failedToUpdateStatus));
    } catch (_) {
      if (!mounted) return;
      _showError(l.failedToUpdateStatus);
    } finally {
      if (mounted) setState(() => _submitting = null);
    }
  }

  void _openQuotation() {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuotationScreen(
          jobId: widget.job.id,
          jobCustomerName: widget.job.customerName,
          jobCustomerPhone: widget.job.customerPhone,
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final busy = _submitting != null;
    final job = widget.job;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.sync, color: Color(0xFF1E3A5F)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.updateStatus,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: busy ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            const Divider(height: 20),
            _SectionLabel(l.workStatusSection),
            const SizedBox(height: 8),
            _ActionRow(
              icon: Icons.history,
              iconBg: const Color(0xFFFFF4E5),
              iconColor: const Color(0xFFE08A1A),
              title: l.workPending,
              subtitle: l.waitingToStart,
              selected: job.workStatus == 'pending' || job.workStatus.isEmpty,
              isLoading: _submitting == 'pending',
              onTap: busy ? null : () => _patch({'work_status': 'pending'}, 'pending'),
            ),
            const SizedBox(height: 8),
            _ActionRow(
              icon: Icons.sync,
              iconBg: const Color(0xFFDBEAFE),
              iconColor: const Color(0xFF2563EB),
              title: l.workInProgress,
              subtitle: l.technicianWorking,
              selected: job.workStatus == 'in_progress',
              isLoading: _submitting == 'in_progress',
              onTap: busy ? null : () => _patch({'work_status': 'in_progress'}, 'in_progress'),
            ),
            const SizedBox(height: 8),
            _ActionRow(
              icon: Icons.verified,
              iconBg: const Color(0xFFBBF7D0),
              iconColor: const Color(0xFF16A34A),
              title: l.workDone,
              subtitle: l.repairFinished,
              selected: job.workStatus == 'finished',
              isLoading: _submitting == 'finished',
              onTap: busy ? null : () => _patch({'work_status': 'finished'}, 'finished'),
            ),
            const SizedBox(height: 16),
            _SectionLabel(l.clientDecisionSection),
            const SizedBox(height: 8),
            _ActionRow(
              icon: Icons.thumb_up_outlined,
              iconBg: const Color(0xFFDCFCE7),
              iconColor: const Color(0xFF16A34A),
              title: l.clientAgree,
              subtitle: l.customerAcceptedPrice,
              selected: job.clientReport == 'agree',
              isLoading: _submitting == 'agree',
              onTap: busy ? null : () => _patch({'client_report': 'agree'}, 'agree'),
            ),
            const SizedBox(height: 8),
            _ActionRow(
              icon: Icons.schedule,
              iconBg: const Color(0xFFF3F4F6),
              iconColor: const Color(0xFF4B5563),
              title: l.clientWaitClient,
              subtitle: l.waitingCustomerReply,
              selected: job.clientReport == 'wait_client',
              isLoading: _submitting == 'wait_client',
              onTap: busy ? null : () => _patch({'client_report': 'wait_client'}, 'wait_client'),
            ),
            const SizedBox(height: 8),
            _ActionRow(
              icon: Icons.close,
              iconBg: const Color(0xFFFFE4E6),
              iconColor: const Color(0xFFF04D4E),
              title: l.clientRejected,
              subtitle: l.customerRejectedOffer,
              selected: job.clientReport == 'rejected',
              isLoading: _submitting == 'rejected',
              onTap: busy ? null : () => _patch({'client_report': 'rejected'}, 'rejected'),
            ),
            const SizedBox(height: 8),
            _ActionRow(
              icon: Icons.local_shipping_outlined,
              iconBg: const Color(0xFFE5F9FD),
              iconColor: const Color(0xFF0EA5E9),
              title: l.clientReady,
              subtitle: l.finishedAndReady,
              selected: job.clientReport == 'finished',
              isLoading: _submitting == 'ready',
              onTap: busy ? null : () => _patch({'client_report': 'finished'}, 'ready'),
            ),
            const SizedBox(height: 16),
            _SectionLabel(l.handoverSection),
            const SizedBox(height: 8),
            _ActionRow(
              icon: Icons.task_alt,
              iconBg: const Color(0xFFF5F3FF),
              iconColor: const Color(0xFFA855F7),
              title: job.deliveredAt == null ? l.markDelivered : l.labelDelivered,
              subtitle: job.deliveredAt == null
                  ? l.customerCollected
                  : l.alreadyDelivered,
              selected: job.deliveredAt != null,
              isLoading: _submitting == 'deliver',
              onTap: busy || job.deliveredAt != null
                  ? null
                  : () => _patch({'deliver': true}, 'deliver'),
            ),
            const SizedBox(height: 16),
            _ActionRow(
              icon: Icons.chat_bubble_outline,
              iconBg: const Color(0xFFDBF0FB),
              iconColor: const Color(0xFF0EA5E9),
              title: l.createReportAndInvoice,
              subtitle: l.sendReportToCustomer,
              bordered: true,
              onTap: busy ? null : _openQuotation,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w700,
        color: Color(0xFF9CA3AF),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.bordered = false,
    this.selected = false,
    this.isLoading = false,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool bordered;
  final bool selected;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SoftSurface(
      radius: AppButton.radius,
      color: selected ? iconBg : Colors.white,
      shadowColor: iconColor.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: bordered
              ? BoxDecoration(
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                  borderRadius: BorderRadius.circular(AppButton.radius),
                )
              : selected
                  ? BoxDecoration(
                      border: Border.all(color: iconColor.withValues(alpha: 0.35)),
                      borderRadius: BorderRadius.circular(AppButton.radius),
                    )
                  : null,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: iconColor),
                      )
                    : Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              if (bordered || selected)
                Icon(
                  selected ? Icons.check_circle : Icons.chevron_right,
                  color: selected ? iconColor : const Color(0xFF38BDF8),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
