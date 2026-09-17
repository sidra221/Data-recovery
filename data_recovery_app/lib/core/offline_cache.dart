import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// نسخة محفوظة من ردّ سيرفر، مع وقت ما انحفظت.
class CachedResponse {
  const CachedResponse({required this.data, required this.savedAt});

  final dynamic data;
  final DateTime savedAt;
}

/// كاش للقراءة فقط، حتى التطبيق يضل يعرض شي لما السيرفر يطفى.
///
/// بنخزّن الرد الخام (JSON) مو الموديلات، حتى أي تغيير بالموديل ما يكسر
/// المحفوظ — بيتفكّ بنفس `fromJson` تبع الشبكة.
///
/// **مو مكان للأسرار.** التوكن بيضل بـ [SecureStorage]. هون بس بيانات
/// بيشوفها الموظف أصلاً على الشاشة.
class OfflineCache {
  OfflineCache({SharedPreferences? prefs}) : _injected = prefs;

  static const _prefix = 'cache:';
  static const keyDashboardStats = 'dashboard_stats';
  static const keyJobs = 'jobs';
  static const keyCustomers = 'customers';
  static const keyProfile = 'profile';

  final SharedPreferences? _injected;
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _store async {
    return _injected ?? (_prefs ??= await SharedPreferences.getInstance());
  }

  Future<void> write(String key, Object? json) async {
    try {
      final store = await _store;
      await store.setString(
        '$_prefix$key',
        jsonEncode({
          'savedAt': DateTime.now().toIso8601String(),
          'data': json,
        }),
      );
    } catch (_) {
      // الكاش تحسين مو ضرورة — فشل الحفظ ما لازم يكسر طلب ناجح.
    }
  }

  Future<CachedResponse?> read(String key) async {
    try {
      final store = await _store;
      final raw = store.getString('$_prefix$key');
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.tryParse(decoded['savedAt'] as String? ?? '');
      if (savedAt == null) return null;
      return CachedResponse(data: decoded['data'], savedAt: savedAt);
    } catch (_) {
      // محفوظ خربان أو من نسخة قديمة — منتجاهله ومنعتبر ما في كاش.
      return null;
    }
  }

  /// بتنمسح عند تسجيل الخروج — الكاش بيخص الموظف يلي كان مسجّل دخول.
  Future<void> clear() async {
    try {
      final store = await _store;
      for (final key in store.getKeys().where((k) => k.startsWith(_prefix))) {
        await store.remove(key);
      }
    } catch (_) {
      // ما منقدر نمسح — مو سبب يمنع تسجيل الخروج.
    }
  }
}
