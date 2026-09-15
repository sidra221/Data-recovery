import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

import 'app_button.dart';
import 'soft_surface.dart';

enum CasesDateRange { allTime, custom, thisWeek, today, thisMonth }

class CasesFilterResult {
  const CasesFilterResult({
    required this.range,
    this.customStart,
    this.customEnd,
  });

  final CasesDateRange range;
  final DateTime? customStart;
  final DateTime? customEnd;
}

class CasesFilterSheet extends StatefulWidget {
  const CasesFilterSheet({super.key, required this.initialRange});

  final CasesDateRange initialRange;

  static Future<CasesFilterResult?> show(
    BuildContext context, {
    required CasesDateRange initialRange,
  }) {
    return showModalBottomSheet<CasesFilterResult>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => CasesFilterSheet(initialRange: initialRange),
    );
  }

  @override
  State<CasesFilterSheet> createState() => _CasesFilterSheetState();
}

class _CasesFilterSheetState extends State<CasesFilterSheet> {
  late CasesDateRange _range;
  DateTime? _customStart;
  DateTime? _customEnd;

  /// كانت قائمة const بمستوى الكلاس — والترجمة بتحتاج context،
  /// فصارت دالة بتنبنى وقت العرض.
  List<(CasesDateRange, String)> _options(L l) => [
        (CasesDateRange.allTime, l.allTime),
        (CasesDateRange.custom, l.custom),
        (CasesDateRange.thisWeek, l.thisWeek),
        (CasesDateRange.today, l.today),
        (CasesDateRange.thisMonth, l.thisMonth),
      ];

  @override
  void initState() {
    super.initState();
    _range = widget.initialRange;
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.tune, color: Color(0xFF111827)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.filter,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l.dateRange,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final option in _options(l))
                  _FilterPill(
                    label: option.$2,
                    selected: _range == option.$1,
                    onTap: () async {
                      if (option.$1 == CasesDateRange.custom) {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                          initialDateRange: _customStart != null && _customEnd != null
                              ? DateTimeRange(start: _customStart!, end: _customEnd!)
                              : null,
                        );
                        if (picked == null) return;
                        setState(() {
                          _range = CasesDateRange.custom;
                          _customStart = DateTime(
                            picked.start.year,
                            picked.start.month,
                            picked.start.day,
                          );
                          _customEnd = DateTime(
                            picked.end.year,
                            picked.end.month,
                            picked.end.day,
                            23,
                            59,
                            59,
                          );
                        });
                        return;
                      }
                      setState(() => _range = option.$1);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _range = CasesDateRange.allTime;
                    _customStart = null;
                    _customEnd = null;
                  }),
                  child: Text(
                    l.clearAll,
                    style: TextStyle(
                      color: Color(0xFF33BEE9),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                AppButton(
                  label: l.applyFilter,
                  width: 160,
                  onPressed: () => Navigator.of(context).pop(
                    CasesFilterResult(
                      range: _range,
                      customStart: _customStart,
                      customEnd: _customEnd,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftSurface(
      radius: 999,
      color: selected ? const Color(0xFF33BEE9) : Colors.white,
      shadowColor: selected ? const Color(0x4033BEE9) : const Color(0x14000000),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: selected
              ? const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF5CCBED), Color(0xFF2EABD2)],
                  ),
                )
              : null,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF374151),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
