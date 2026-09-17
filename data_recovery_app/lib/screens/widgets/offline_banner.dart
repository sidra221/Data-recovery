import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// شريط بيقول للموظف إن يلي شايفه بيانات محفوظة، مو طازة من السيرفر.
///
/// مهم يكون واضح: بشغل ورشة، حدا يتصرّف على حالة قضية قديمة وهو فاكرها
/// الحالية أسوأ من إنه ما يشوف شي.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.cachedAt});

  final DateTime cachedAt;

  /// «هلق» / «من ٥ دقائق» / «من ساعتين» / «من ٣ أيام».
  static String relativeTime(L l, DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.isNegative || diff.inMinutes < 1) return l.justNow;
    if (diff.inMinutes < 60) return l.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l.hoursAgo(diff.inHours);
    return l.daysAgo(diff.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF7ED),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 18, color: Color(0xFFB45309)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${l.offline} · ${l.showingSavedData(relativeTime(l, cachedAt))}',
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
