import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../providers/jobs_provider.dart';

class UpdateStatusSheet extends ConsumerStatefulWidget {
  const UpdateStatusSheet({
    super.key,
    required this.jobId,
    required this.currentStatus,
    this.onUpdated,
  });

  final int jobId;
  final String currentStatus;
  final VoidCallback? onUpdated;

  static Future<void> show(
    BuildContext context, {
    required int jobId,
    required String currentStatus,
    VoidCallback? onUpdated,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => UpdateStatusSheet(
        jobId: jobId,
        currentStatus: currentStatus,
        onUpdated: onUpdated,
      ),
    );
  }

  @override
  ConsumerState<UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends ConsumerState<UpdateStatusSheet> {
  String? _submittingStatus;

  // TODO: replace with context-aware status transitions once naming decision confirmed
  static const _options = <_StatusOption>[
    _StatusOption(
      value: 'received',
      label: 'تم الاستلام',
      icon: Icons.inventory_2_outlined,
      badgeBg: Color(0xFFE5F9FD),
      badgeText: Color(0xFF33BEE9),
    ),
    _StatusOption(
      value: 'finished',
      label: 'فنش',
      icon: Icons.check_circle_outline,
      badgeBg: Color(0xFFE7FFED),
      badgeText: Color(0xFF22C55E),
    ),
    _StatusOption(
      value: 'completed',
      label: 'خلص',
      icon: Icons.done_all,
      badgeBg: Color(0xFFF5F5F5),
      badgeText: Color(0xFF878688),
    ),
    _StatusOption(
      value: 'has_problems',
      label: 'في مشاكل',
      icon: Icons.error_outline,
      badgeBg: Color(0xFFFFF5F3),
      badgeText: Color(0xFFF04D4E),
    ),
  ];

  Future<void> _select(_StatusOption option) async {
    if (_submittingStatus != null) return;

    setState(() => _submittingStatus = option.value);
    try {
      await ref.read(jobsProvider.notifier).updateStatus(
            widget.jobId,
            status: option.value,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onUpdated?.call();
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error.message.isNotEmpty ? error.message : 'تعذّر تحديث الحالة');
    } catch (_) {
      if (!mounted) return;
      _showError('تعذّر تحديث الحالة');
    } finally {
      if (mounted) setState(() => _submittingStatus = null);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      for (final option in _options)
        if (option.value != widget.currentStatus) option,
    ];
    final busy = _submittingStatus != null;

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
                const Icon(Icons.sync, color: Color(0xFF111827)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Update Status',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: busy ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            const Divider(height: 24),
            for (final option in options) ...[
              _StatusChoiceCard(
                option: option,
                enabled: !busy,
                isLoading: _submittingStatus == option.value,
                onTap: () => _select(option),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusOption {
  const _StatusOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.badgeBg,
    required this.badgeText,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color badgeBg;
  final Color badgeText;
}

class _StatusChoiceCard extends StatelessWidget {
  const _StatusChoiceCard({
    required this.option,
    required this.enabled,
    required this.isLoading,
    required this.onTap,
  });

  final _StatusOption option;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: option.badgeBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withValues(alpha: 0.7),
                child: isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: option.badgeText,
                        ),
                      )
                    : Icon(option.icon, color: option.badgeText, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: option.badgeText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mark this case as ${option.label}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
