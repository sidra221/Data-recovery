import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// معرّف ثابت للجهاز، بينولّد أول مرة وبيضل محفوظ.
///
/// السيرفر بيربط فيه مدى أرقام الفواتير المحجوز، فلازم يضل هو هو بين
/// التشغيلات — وإلا كل إقلاع بياخد مدى جديد وبنستهلك المدايات ع الفاضي.
///
/// مو معرّف عتاد: لو انمسحت بيانات التطبيق بيتغيّر. هاد مقبول — أسوأ شي
/// بيصير إنه الجهاز بياخد مدى جديد، والمدى القديم بيضل محجوز وما حدا
/// بيستعمله.
class DeviceIdentity {
  DeviceIdentity({SharedPreferences? prefs}) : _injected = prefs;

  static const _key = 'device_id';

  final SharedPreferences? _injected;

  Future<String> get() async {
    final store = _injected ?? await SharedPreferences.getInstance();
    final existing = store.getString(_key);
    if (existing != null && existing.isNotEmpty) return existing;

    final generated = _generate();
    await store.setString(_key, generated);
    return generated;
  }

  static String _generate() {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    final suffix = List.generate(
      16,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
    return 'app-$suffix';
  }
}
