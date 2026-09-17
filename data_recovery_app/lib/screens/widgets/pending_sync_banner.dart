import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/sync_provider.dart';

/// بيبيّن إنه في شغل انعمل على الجهاز ولسا ما وصل السيرفر.
///
/// المهم إنه الموظف يعرف إن العملية **محفوظة مو ضايعة**، وبنفس الوقت يعرف
/// إنها لسا ما وصلت — حتى ما يفترض إن زميله على جهاز تاني عم يشوفها.
class PendingSyncBanner extends ConsumerWidget {
  const PendingSyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final sync = ref.watch(syncProvider);
    if (!sync.hasPending && !sync.hasRejected) return const SizedBox.shrink();

    // الرفض أهم من الانتظار: الانتظار بينحل لحاله، الرفض لأ.
    final isRejected = sync.hasRejected;
    final background = isRejected ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF);
    final foreground = isRejected ? const Color(0xFF991B1B) : const Color(0xFF1E40AF);

    return Container(
      width: double.infinity,
      color: background,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Icon(
            isRejected ? Icons.error_outline : Icons.cloud_upload_outlined,
            size: 18,
            color: foreground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isRejected
                  ? l.rejectedSyncCount(sync.rejected)
                  : l.pendingSyncCount(sync.pending),
              style: TextStyle(
                fontSize: 12.5,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
          if (sync.isSyncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (sync.hasPending)
            TextButton(
              onPressed: () => _sync(context, ref),
              style: TextButton.styleFrom(
                foregroundColor: foreground,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l.syncNow,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    final l = L.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(syncProvider.notifier).flush();
    if (!context.mounted) return;

    final message = result.stoppedOffline && result.synced == 0
        ? l.serverUnreachable
        : l.syncedCount(result.synced);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
