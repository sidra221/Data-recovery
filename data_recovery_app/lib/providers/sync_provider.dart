import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/device_identity.dart';
import '../core/invoice_number_minter.dart';
import '../core/pending_queue.dart';
import '../core/sync_engine.dart';
import 'auth_provider.dart';

final pendingQueueProvider = Provider<PendingQueue>((ref) => PendingQueue());
final invoiceMinterProvider =
    Provider<InvoiceNumberMinter>((ref) => InvoiceNumberMinter());
final deviceIdentityProvider = Provider<DeviceIdentity>((ref) => DeviceIdentity());

class SyncState {
  const SyncState({
    this.pending = 0,
    this.rejected = 0,
    this.isSyncing = false,
    this.numbersLeftToday = 0,
  });

  /// عمليات مستنية الشبكة.
  final int pending;

  /// عمليات السيرفر رفضها — بدها تدخّل من الموظف.
  final int rejected;

  final bool isSyncing;

  /// كم رقم فاتورة باقي بالمدى المحجوز لهاليوم.
  final int numbersLeftToday;

  bool get hasPending => pending > 0;
  bool get hasRejected => rejected > 0;

  SyncState copyWith({
    int? pending,
    int? rejected,
    bool? isSyncing,
    int? numbersLeftToday,
  }) {
    return SyncState(
      pending: pending ?? this.pending,
      rejected: rejected ?? this.rejected,
      isSyncing: isSyncing ?? this.isSyncing,
      numbersLeftToday: numbersLeftToday ?? this.numbersLeftToday,
    );
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);

class SyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() {
    Future.microtask(refresh);
    return const SyncState();
  }

  PendingQueue get _queue => ref.read(pendingQueueProvider);
  InvoiceNumberMinter get _minter => ref.read(invoiceMinterProvider);

  /// بيقرا حالة الطابور من التخزين بدون ما يلمس الشبكة.
  Future<void> refresh() async {
    state = state.copyWith(
      pending: (await _queue.waiting()).length,
      rejected: (await _queue.rejected()).length,
      numbersLeftToday: await _minter.remainingToday(),
    );
  }

  /// بيحجز مدى أرقام للجهاز إذا لسا ما عندو واحد.
  ///
  /// لازم ينعمل والسيرفر شغّال، حتى الجهاز يكون جاهز يشتغل أوفلاين بعدين.
  /// الفشل هون مو مشكلة — منعيد المحاولة أول ما ترجع الشبكة.
  Future<void> ensureNumberBlock() async {
    if (await _minter.readBlock() != null) return;
    try {
      final deviceId = await ref.read(deviceIdentityProvider).get();
      final block = await ref.read(apiClientProvider).reserveNumberBlock(deviceId);
      await _minter.saveBlock(block);
      await refresh();
    } on ApiException {
      // السيرفر مطفّى أو رفض — منحاول كمان مرة المرة الجاية.
    }
  }

  /// بيفرّغ الطابور. بينادى أول ما يبان إن السيرفر رجع.
  Future<SyncResult> flush() async {
    if (state.isSyncing) return const SyncResult();
    state = state.copyWith(isSyncing: true);
    try {
      final result = await SyncEngine(
        client: ref.read(apiClientProvider),
        queue: _queue,
      ).flush();
      await refresh();
      return result;
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  /// بينشال عمل مرفوض بعد ما الموظف يشوفه ويقرر يتخلّى عنه.
  Future<void> discard(String operationId) async {
    await _queue.remove(operationId);
    await refresh();
  }

  Future<List<PendingOperation>> rejectedOperations() => _queue.rejected();
}
