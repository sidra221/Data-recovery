import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/api_client.dart';
import '../models/job.dart';
import '../providers/auth_provider.dart';
import 'case_detail_screen.dart';

/// بحث عن فاتورة بالسيريال أو رقم الجوال أو الاسم أو نطاق تاريخ.
///
/// السيرفر بيبحث بحقل واحد عبر عدة أعمدة (اسم، هاتف، باركود، رقم فاتورة،
/// موديل، سيريال، وصف المشكلة)، فحقل بحث واحد بيغطي كل يلي طلبه العميل.
/// الضغط على نتيجة بيفتح تفاصيل القضية الكاملة مع حالتها.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final _searchController = TextEditingController();

  DateTime? _from;
  DateTime? _to;
  List<Job> _results = const [];
  int _total = 0;
  bool _loading = false;
  bool _searched = false;
  String? _error;

  static final _apiDate = DateFormat('yyyy-MM-dd');
  static final _uiDate = DateFormat('d MMM yyyy', 'en');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasCriteria =>
      _searchController.text.trim().isNotEmpty || _from != null || _to != null;

  Future<void> _search() async {
    final l = L.of(context);
    if (!_hasCriteria) {
      setState(() {
        _error = l.searchNeedsCriteria;
        _results = const [];
        _searched = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref.read(apiClientProvider).listJobs(
            search: _searchController.text.trim(),
            createdFrom: _from == null ? null : _apiDate.format(_from!),
            createdTo: _to == null ? null : _apiDate.format(_to!),
          );
      if (!mounted) return;
      setState(() {
        _results = page.results;
        _total = page.count;
        _loading = false;
        _searched = true;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _searched = true;
        _results = const [];
        _error = error.message.isNotEmpty ? error.message : l.searchFailed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _searched = true;
        _results = const [];
        _error = l.searchFailed;
      });
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _from : _to) ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
        // ما منخلّي "من" تتجاوز "إلى" — بينتج نطاق فاضي بلا معنى.
        if (_to != null && _to!.isBefore(picked)) _to = picked;
      } else {
        _to = picked;
        if (_from != null && _from!.isAfter(picked)) _from = picked;
      }
    });
  }

  void _clear() {
    setState(() {
      _searchController.clear();
      _from = null;
      _to = null;
      _results = const [];
      _total = 0;
      _searched = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          l.reports,
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        actions: [
          if (_hasCriteria || _searched)
            TextButton(onPressed: _clear, child: Text(l.clear)),
        ],
      ),
      body: Column(
        children: [
          _SearchPanel(
            controller: _searchController,
            from: _from,
            to: _to,
            loading: _loading,
            uiDate: _uiDate,
            onPickFrom: () => _pickDate(isFrom: true),
            onPickTo: () => _pickDate(isFrom: false),
            onSubmit: _search,
          ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final l = L.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return _Hint(icon: Icons.error_outline, text: _error!);
    }

    if (!_searched) {
      return _Hint(
        icon: Icons.search,
        text: l.searchReportsEmptyHint,
      );
    }

    if (_results.isEmpty) {
      return _Hint(
        icon: Icons.inbox_outlined,
        text: l.noCasesMatch,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _results.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          final shown = _results.length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              shown == _total
                  ? l.resultsCount(_total)
                  : l.showingOf(shown, _total),
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
            ),
          );
        }
        return _ResultTile(job: _results[index - 1]);
      },
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.controller,
    required this.from,
    required this.to,
    required this.loading,
    required this.uiDate,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final DateTime? from;
  final DateTime? to;
  final bool loading;
  final DateFormat uiDate;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          TextField(
            controller: controller,
            enabled: !loading,
            textInputAction: TextInputAction.search,
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              hintText: l.searchReportsHint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: l.dateFrom,
                  value: from == null ? l.dateAny : uiDate.format(from!),
                  onTap: loading ? null : onPickFrom,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateButton(
                  label: l.dateTo,
                  value: to == null ? l.dateAny : uiDate.format(to!),
                  onTap: loading ? null : onPickTo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: loading ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF33BEE9),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                l.search,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_outlined,
                size: 17, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// نتيجة واحدة: الفاتورة والسعر والحالة، وبيانات الجهاز اللي بتساعد
/// تميّز قضيتين لنفس العميل.
class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.job});

  final Job job;

  ({Color bg, Color fg}) get _statusColors {
    if (job.workStatus == 'finished' ||
        job.clientReport == 'finished' ||
        job.status == 'completed') {
      return (bg: const Color(0xFFDCFCE7), fg: const Color(0xFF16A34A));
    }
    if (job.status == 'has_problems' || job.clientReport == 'rejected') {
      return (bg: const Color(0xFFFFE4E6), fg: const Color(0xFFF04D4E));
    }
    return (bg: const Color(0xFFFFF4E5), fg: const Color(0xFFE08A1A));
  }

  String get _statusText {
    if (job.workStatusLabel.isNotEmpty) return job.workStatusLabel;
    if (job.clientReportLabel.isNotEmpty) return job.clientReportLabel;
    return job.statusLabel.isNotEmpty ? job.statusLabel : job.status;
  }

  @override
  Widget build(BuildContext context) {
    final c = _statusColors;
    final device = [
      job.hardDiskTypeLabel.isNotEmpty ? job.hardDiskTypeLabel : job.hardDiskType,
      if (job.deviceModel.isNotEmpty) job.deviceModel,
      if (job.serialNumber.isNotEmpty) job.serialNumber,
    ].join(' · ');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CaseDetailScreen(jobId: job.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${job.invoiceNumber}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  if (job.price != null) ...[
                    Text(
                      job.price! == job.price!.roundToDouble()
                          ? job.price!.toStringAsFixed(0)
                          : job.price!.toStringAsFixed(2),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.bg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: c.fg,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${job.customerName} · ${job.customerPhone}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
              ),
              if (device.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  device,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 3),
              Text(
                DateFormat('d MMM yyyy', 'en').format(job.createdAt.toLocal()),
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 38, color: const Color(0xFFD1D5DB)),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13.5),
            ),
          ],
        ),
      ),
    );
  }
}
