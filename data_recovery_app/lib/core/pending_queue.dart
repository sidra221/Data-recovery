import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

enum PendingKind { createJob, updateStatus, deliver }

/// عملية كتابة انعملت والسيرفر مطفّى، مخزّنة لحد ما ترجع الشبكة.
class PendingOperation {
  const PendingOperation({
    required this.id,
    required this.kind,
    required this.payload,
    required this.queuedAt,
    this.attempts = 0,
    this.lastError,
  });

  final String id;
  final PendingKind kind;
  final Map<String, dynamic> payload;
  final DateTime queuedAt;
  final int attempts;

  /// آخر خطأ **من السيرفر** (مو انقطاع شبكة). وجوده معناه إن العملية
  /// مرفوضة وبدها تدخّل من الموظف، مو إنها بانتظار الشبكة.
  final String? lastError;

  bool get isRejected => lastError != null;

  PendingOperation copyWith({int? attempts, String? lastError}) {
    return PendingOperation(
      id: id,
      kind: kind,
      payload: payload,
      queuedAt: queuedAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'payload': payload,
        'queuedAt': queuedAt.toIso8601String(),
        'attempts': attempts,
        'lastError': lastError,
      };

  static PendingOperation? fromJson(Map<String, dynamic> json) {
    final kind = PendingKind.values
        .where((k) => k.name == json['kind'])
        .firstOrNull;
    final queuedAt = DateTime.tryParse(json['queuedAt'] as String? ?? '');
    if (kind == null || queuedAt == null) return null;
    return PendingOperation(
      id: json['id'] as String,
      kind: kind,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      queuedAt: queuedAt,
      attempts: json['attempts'] as int? ?? 0,
      lastError: json['lastError'] as String?,
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// طابور دائم للعمليات المؤجّلة.
///
/// الترتيب مهم: العمليات بتتنفّذ بنفس ترتيب ما انعملت، حتى تحديث حالة
/// انعمل بعد إنشاء عملية ما يسبق الإنشاء نفسه.
class PendingQueue {
  PendingQueue({SharedPreferences? prefs}) : _injected = prefs;

  static const _key = 'pending_ops';

  final SharedPreferences? _injected;

  Future<SharedPreferences> get _store async =>
      _injected ?? await SharedPreferences.getInstance();

  Future<List<PendingOperation>> all() async {
    try {
      final store = await _store;
      final raw = store.getString(_key);
      if (raw == null) return const [];
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          ?PendingOperation.fromJson(Map<String, dynamic>.from(item as Map)),
      ];
    } catch (_) {
      // محفوظ خربان — أحسن نرجّع طابور فاضي من نكسر التطبيق.
      return const [];
    }
  }

  Future<void> _write(List<PendingOperation> ops) async {
    final store = await _store;
    await store.setString(
      _key,
      jsonEncode([for (final op in ops) op.toJson()]),
    );
  }

  Future<PendingOperation> add({
    required PendingKind kind,
    required Map<String, dynamic> payload,
  }) async {
    final op = PendingOperation(
      id: _newId(),
      kind: kind,
      payload: payload,
      queuedAt: DateTime.now(),
    );
    await _write([...await all(), op]);
    return op;
  }

  Future<void> remove(String id) async {
    final ops = await all();
    await _write([
      for (final op in ops)
        if (op.id != id) op,
    ]);
  }

  Future<void> update(PendingOperation replacement) async {
    final ops = await all();
    await _write([
      for (final op in ops)
        if (op.id == replacement.id) replacement else op,
    ]);
  }

  /// العمليات يلي لسا بانتظار الشبكة (مو المرفوضة من السيرفر).
  Future<List<PendingOperation>> waiting() async {
    return [
      for (final op in await all())
        if (!op.isRejected) op,
    ];
  }

  Future<List<PendingOperation>> rejected() async {
    return [
      for (final op in await all())
        if (op.isRejected) op,
    ];
  }

  Future<void> clear() async {
    final store = await _store;
    await store.remove(_key);
  }

  static String _newId() {
    final random = Random();
    return '${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(1 << 32)}';
  }
}
