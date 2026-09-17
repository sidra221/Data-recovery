import 'api_client.dart';
import 'pending_queue.dart';

class SyncResult {
  const SyncResult({
    this.synced = 0,
    this.rejected = 0,
    this.stillWaiting = 0,
    this.stoppedOffline = false,
  });

  /// عمليات وصلت للسيرفر ونجحت.
  final int synced;

  /// عمليات السيرفر رفضها — بدها تدخّل من الموظف، إعادة المحاولة ما بتفيد.
  final int rejected;

  /// عمليات لسا بالطابور.
  final int stillWaiting;

  /// وقفنا لأن السيرفر لسا مطفّى، مو لأن في غلط بالعمليات.
  final bool stoppedOffline;

  bool get didWork => synced > 0 || rejected > 0;
}

/// بيفرّغ طابور العمليات المؤجّلة على السيرفر.
///
/// مبدأ التسليم «مرة على الأقل»: ممكن عملية توصل للسيرفر وينقطع الرد قبل
/// ما نشيلها من الطابور، فتنبعت مرة تانية. عشان هيك الإنشاء بيعتمد على رقم
/// فاتورة مولّد بالجهاز — إعادة الإرسال بترجع «الرقم موجود» ومنعتبرها نجاح
/// بدل ما ننشئ نسخة مكررة.
class SyncEngine {
  SyncEngine({required this.client, required this.queue});

  final ApiClient client;
  final PendingQueue queue;

  bool _running = false;

  Future<SyncResult> flush() async {
    // منع تشغيلين متوازيين — بينتجوا إرسال مكرر بلا فايدة.
    if (_running) return const SyncResult();
    _running = true;
    try {
      return await _flush();
    } finally {
      _running = false;
    }
  }

  Future<SyncResult> _flush() async {
    var synced = 0;
    var rejected = 0;

    for (final op in await queue.waiting()) {
      try {
        await _apply(op);
        await queue.remove(op.id);
        synced++;
      } on ApiException catch (error) {
        if (error.isNetworkError) {
          // السيرفر لسا مطفّى. منوقف كل الطابور — العمليات مرتبة، وتخطّي
          // وحدة ممكن يقلب الترتيب.
          await queue.update(op.copyWith(attempts: op.attempts + 1));
          return SyncResult(
            synced: synced,
            rejected: rejected,
            stillWaiting: (await queue.waiting()).length,
            stoppedOffline: true,
          );
        }
        if (_isAlreadyApplied(op, error)) {
          // وصلت قبل وانقطع الرد. منعتبرها خلصت.
          await queue.remove(op.id);
          synced++;
          continue;
        }
        await queue.update(
          op.copyWith(attempts: op.attempts + 1, lastError: error.message),
        );
        rejected++;
      }
    }

    return SyncResult(
      synced: synced,
      rejected: rejected,
      stillWaiting: (await queue.waiting()).length,
    );
  }

  Future<void> _apply(PendingOperation op) async {
    switch (op.kind) {
      case PendingKind.createJob:
        await client.createJob(Map<String, dynamic>.from(op.payload));
      case PendingKind.updateStatus:
        await client.updateJob(
          op.payload['job_id'] as int,
          Map<String, dynamic>.from(op.payload['patch'] as Map),
        );
      case PendingKind.deliver:
        await client.deliverJob(op.payload['job_id'] as int);
    }
  }

  /// هل رفض السيرفر معناه إن العملية أصلاً انطبّقت قبل؟
  bool _isAlreadyApplied(PendingOperation op, ApiException error) {
    if (op.kind != PendingKind.createJob) return false;
    final body = error.data;
    if (body is! Map) return false;
    final messages = body['invoice_number'];
    if (messages is! List) return false;
    return messages.any(
      (m) => m.toString().toLowerCase().contains('already exists'),
    );
  }
}
