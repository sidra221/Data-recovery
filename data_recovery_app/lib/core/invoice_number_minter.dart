import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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
/// الرقم بيطلع بنفس شكل السيرفر: `PREFIX-YYYYMMDD-NNNN`. التسلسل بيبلّش من
/// `blockStart` كل يوم جديد — المدى محجوز للجهاز بكل الأيام، مو ليوم واحد،
/// فلو ضل أوفلاين لبكرا بيضل يقدر يولّد.
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

  /// بيرجّع الرقم الجاي، أو `null` لو ما في مدى محجوز أو خلص المدى لهاليوم.
  ///
  /// خلوص المدى معناه إن الجهاز عمل أكتر من [NumberBlock.size] عملية بيوم
  /// واحد وهو أوفلاين. منرجّع `null` بدل ما نعطي رقم برّا المدى، لأن رقم
  /// برّا المدى ممكن يتصادم مع رقم تاني وقت المزامنة.
  Future<String?> mint({DateTime? now}) async {
    final block = await readBlock();
    if (block == null) return null;

    final today = now ?? DateTime.now();
    final day =
        '${today.year.toString().padLeft(4, '0')}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

    final store = await _store;
    final cursor = jsonDecode(store.getString(_cursorKey) ?? '{}') as Map<String, dynamic>;
    // التسلسل بينعاد من بداية المدى كل يوم، لأن الرقم فيه التاريخ.
    final next = cursor['day'] == day ? (cursor['next'] as int) : block.blockStart;
    if (next > block.blockEnd) return null;

    await store.setString(
      _cursorKey,
      jsonEncode({'day': day, 'next': next + 1}),
    );
    return '${block.prefix}-$day-${next.toString().padLeft(4, '0')}';
  }

  /// كم رقم باقي لهاليوم. بينفع نحذّر الموظف قبل ما يخلص المدى.
  Future<int> remainingToday({DateTime? now}) async {
    final block = await readBlock();
    if (block == null) return 0;

    final today = now ?? DateTime.now();
    final day =
        '${today.year.toString().padLeft(4, '0')}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

    final store = await _store;
    final cursor = jsonDecode(store.getString(_cursorKey) ?? '{}') as Map<String, dynamic>;
    final next = cursor['day'] == day ? (cursor['next'] as int) : block.blockStart;
    return (block.blockEnd - next + 1).clamp(0, block.size);
  }

  Future<void> clear() async {
    final store = await _store;
    await store.remove(_blockKey);
    await store.remove(_cursorKey);
  }
}
