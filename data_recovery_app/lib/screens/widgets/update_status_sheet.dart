import 'package:flutter/material.dart';
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

  Future<void> _setWorkStatus(String value) async {
    if (_submitting != null) return;
    setState(() => _submitting = value);
    try {
      await ref.read(jobsProvider.notifier).updateJob(widget.job.id, {
        'work_status': value,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onUpdated?.call();
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error.message.isNotEmpty ? error.message : 'Failed to update status');
    } catch (_) {
      if (!mounted) return;
      _showError('Failed to update status');
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
    final busy = _submitting != null;
    final current = widget.job.workStatus;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.sync, color: Color(0xFF1E3A5F)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Update Status',
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
            if (current == 'in_progress' || current == 'finished') ...[
              _ActionRow(
                icon: Icons.chat_bubble_outline,
                iconBg: const Color(0xFFDBF0FB),
                iconColor: const Color(0xFF0EA5E9),
                title: 'Create Report & Invoice',
                subtitle: 'Send Report to user',
                bordered: true,
                onTap: busy ? null : _openQuotation,
              ),
            ] else ...[
              _ActionRow(
                icon: Icons.sync,
                iconBg: const Color(0xFFDBEAFE),
                iconColor: const Color(0xFF2563EB),
                title: 'In Progress',
                subtitle: 'Technician working on repair',
                background: const Color(0xFFEFF6FF),
                isLoading: _submitting == 'in_progress',
                onTap: busy ? null : () => _setWorkStatus('in_progress'),
              ),
              const SizedBox(height: 10),
              _ActionRow(
                icon: Icons.verified,
                iconBg: const Color(0xFFBBF7D0),
                iconColor: const Color(0xFF16A34A),
                title: 'Done',
                subtitle: 'Cancelled or unrepairable',
                background: const Color(0xFFECFDF5),
                isLoading: _submitting == 'finished',
                onTap: busy ? null : () => _setWorkStatus('finished'),
              ),
            ],
          ],
        ),
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
    this.background = Colors.white,
    this.bordered = false,
    this.isLoading = false,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color background;
  final bool bordered;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SoftSurface(
      radius: AppButton.radius,
      color: background,
      shadowColor: iconColor.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: bordered
              ? BoxDecoration(
                  border: Border.all(color: const Color(0xFFBAE6FD)),
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
              if (bordered) const Icon(Icons.chevron_right, color: Color(0xFF38BDF8)),
            ],
          ),
        ),
      ),
    );
  }
}
