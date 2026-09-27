import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// خلص المدى المحجوز لهاليوم، أو ما في مدى أصلاً.
///
/// نوع مستقل حتى الشاشة تعرض رسالة مترجمة ومفهومة بدل نص إنكليزي جاهز.
class OfflineNumbersExhausted implements Exception {
  const OfflineNumbersExhausted();
}

/// مدى أرقام محجوز لهالجهاز، جاي من السيرفر.
class NumberBlock {
  const NumberBlock({
    required this.prefix,
    required this.blockStart,
    required this.blockEnd,
  });

  final String prefix;
  final int blockStart;
  final int blockEnd;

  int get size => blockEnd - blockStart + 1;

  factory NumberBlock.fromJson(Map<String, dynamic> json) {
    return NumberBlock(
      prefix: json['prefix'] as String? ?? '01',
      blockStart: json['block_start'] as int,
      blockEnd: json['block_end'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'prefix': prefix,
        'block_start': blockStart,
        'block_end': blockEnd,
      };
}

/// بيولّد أرقام فواتير محلياً من المدى المحجوز للجهاز.
///
/// الرقم بيطلع بنفس شكل السيرفر: `PREFIX-NNNNN`. العدّاد مستمر مو يومي، متل
/// عدّاد السيرفر — الجهاز بياخد مدى ثابت (مثلاً 900000-900999) وبياكل منه
/// رقم لكل عملية أوفلاين، مهما كان اليوم.
class InvoiceNumberMinter {
  InvoiceNumberMinter({SharedPreferences? prefs}) : _injected = prefs;

  static const _blockKey = 'number_block';
  static const _cursorKey = 'number_cursor';

  final SharedPreferences? _injected;

  Future<SharedPreferences> get _store async =>
      _injected ?? await SharedPreferences.getInstance();

  Future<void> saveBlock(NumberBlock block) async {
    final store = await _store;
    await store.setString(_blockKey, jsonEncode(block.toJson()));
  }

  Future<NumberBlock?> readBlock() async {
    final store = await _store;
    final raw = store.getString(_blockKey);
    if (raw == null) return null;
    try {
      return NumberBlock.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// بيرجّع الرقم الجاي، أو `null` لو ما في مدى محجوز أو خلص المدى.
  ///
  /// خلوص المدى معناه إن الجهاز عمل [NumberBlock.size] عملية أوفلاين بدون
  /// ما يتصل بالسيرفر ولا مرة. منرجّع `null` بدل ما نعطي رقم برّا المدى،
  /// لأن رقم برّا المدى ممكن يتصادم مع رقم السيرفر وقت المزامنة.
  Future<String?> mint() async {
    final block = await readBlock();
    if (block == null) return null;

    final store = await _store;
    final next = store.getInt(_cursorKey) ?? block.blockStart;
    if (next > block.blockEnd) return null;

    await store.setInt(_cursorKey, next + 1);
    return '${block.prefix}-$next';
  }

  /// كم رقم باقي بالمدى. بينفع نحذّر الموظف قبل ما يخلص.
  Future<int> remaining() async {
    final block = await readBlock();
    if (block == null) return 0;

    final store = await _store;
    final next = store.getInt(_cursorKey) ?? block.blockStart;
    return (block.blockEnd - next + 1).clamp(0, block.size);
  }

  Future<void> clear() async {
    final store = await _store;
    await store.remove(_blockKey);
    await store.remove(_cursorKey);
  }
}
