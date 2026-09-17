import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/api_client.dart';
import '../models/job.dart';
import '../providers/jobs_provider.dart';
import 'case_detail_screen.dart';
import 'quotation_screen.dart';
import 'barcode_scanner_screen.dart';
import 'widgets/app_bottom_nav.dart';
import 'widgets/app_button.dart';
import 'widgets/cases_filter_sheet.dart';
import 'widgets/notify_customer_sheet.dart';
import 'widgets/offline_banner.dart';
import 'widgets/soft_surface.dart';
import 'widgets/update_status_sheet.dart';

class CasesListScreen extends ConsumerStatefulWidget {
  const CasesListScreen({
    super.key,
    this.initialClientReport,
    this.initialSearch,
  });

  final String? initialClientReport;
  final String? initialSearch;

  @override
  ConsumerState<CasesListScreen> createState() => _CasesListScreenState();
}

class _CasesListScreenState extends ConsumerState<CasesListScreen> {
  // كانت قوائم const بمستوى الكلاس. التسميات صارت مترجمة والترجمة
  // بتحتاج context، فصارت دوال بتنبنى وقت العرض. القيم التقنية
  // (clientReport / workStatus) ما تغيّرت — هي مفاتيح API مو نصوص.
  List<_FilterTab> _reportTabs(L l) => [
        _FilterTab(label: l.filterAll, color: const Color(0xFF33BEE9)),
        _FilterTab(label: l.clientAgree, color: const Color(0xFF22C55E), clientReport: 'agree'),
        _FilterTab(label: l.filterInspection, color: const Color(0xFF8B5CF6), workStatus: 'in_progress'),
        _FilterTab(label: l.clientWaitClient, color: const Color(0xFF6B7280), clientReport: 'wait_client'),
        _FilterTab(label: l.clientReady, color: const Color(0xFF22C55E), clientReport: 'finished'),
        _FilterTab(label: l.clientRejected, color: const Color(0xFFF04D4E), clientReport: 'rejected'),
      ];

  List<_FilterTab> _progressTabs(L l) => [
        _FilterTab(label: l.filterAll, color: const Color(0xFF4B5563)),
        _FilterTab(label: l.workPending, color: const Color(0xFFF5B942), workStatus: 'pending'),
        _FilterTab(label: l.workInProgress, color: const Color(0xFF33BEE9), workStatus: 'in_progress'),
        _FilterTab(label: l.workDone, color: const Color(0xFF22C55E), workStatus: 'finished'),
      ];

  int _selectedReport = 0;
  int _selectedProgress = 0;
  CasesDateRange _dateRange = CasesDateRange.allTime;
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _isRefreshing = false;
  bool _showSearch = false;
  bool _isScanning = false;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final initialReport = widget.initialClientReport;
    if (initialReport != null) {
      final index = _reportTabs(L.of(context)).indexWhere((tab) => tab.clientReport == initialReport);
      if (index >= 0) _selectedReport = index;
    }
    final initialSearch = widget.initialSearch?.trim() ?? '';
    if (initialSearch.isNotEmpty) {
      _searchController.text = initialSearch;
      _showSearch = true;
    }
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final report = _reportTabs(L.of(context))[_selectedReport];
    final progress = _progressTabs(L.of(context))[_selectedProgress];
    try {
      await ref.read(jobsProvider.notifier).fetchJobs(
            search: _searchController.text.trim(),
            clientReport: report.clientReport,
            workStatus: report.workStatus ?? progress.workStatus,
          );
    } catch (_) {}
  }

  Future<void> _refresh() async {
    _isRefreshing = true;
    try {
      await _load();
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _selectReport(int index) async {
    if (_selectedReport == index) return;
    setState(() {
      _selectedReport = index;
      if (_reportTabs(L.of(context))[index].workStatus == 'in_progress') {
        _selectedProgress = 2;
      }
    });
    await _load();
  }

  Future<void> _selectProgress(int index) async {
    if (_selectedProgress == index) return;
    setState(() {
      _selectedProgress = index;
      final reportWork = _reportTabs(L.of(context))[_selectedReport].workStatus;
      final progressWork = _progressTabs(L.of(context))[index].workStatus;
      if (reportWork != null && reportWork != progressWork) {
        _selectedReport = 0;
      }
    });
    await _load();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Future<void> _openFilter() async {
    final result = await CasesFilterSheet.show(context, initialRange: _dateRange);
    if (result == null || !mounted) return;
    setState(() {
      _dateRange = result.range;
      _customStart = result.customStart;
      _customEnd = result.customEnd;
    });
  }

  void _openSearch() {
    setState(() => _showSearch = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    _searchFocus.unfocus();
    _searchController.clear();
    setState(() => _showSearch = false);
    _load();
  }

  Future<void> _scanBarcode() async {
    final l = L.of(context);
    final barcode = await BarcodeScannerScreen.scan(context);
    if (barcode == null || barcode.isEmpty || !mounted) return;

    setState(() => _isScanning = true);
    try {
      final job = await ref.read(jobsProvider.notifier).scanBarcode(barcode);
      if (!mounted) return;
      _searchController.text = job.invoiceNumber;
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(error.message.isNotEmpty ? error.message : l.barcodeNotFound)),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.barcodeNotFound)));
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  List<Job> _visibleJobs(List<Job> jobs) {
    return jobs.where((job) => _matchesDate(job.createdAt)).toList();
  }

  bool _matchesDate(DateTime createdAt) {
    final created = createdAt.toLocal();
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    switch (_dateRange) {
      case CasesDateRange.allTime:
      case CasesDateRange.custom:
        if (_customStart == null || _customEnd == null) return true;
        return !created.isBefore(_customStart!) && !created.isAfter(_customEnd!);
      case CasesDateRange.today:
        return !created.isBefore(startOfToday);
      case CasesDateRange.thisWeek:
        final weekStart = startOfToday.subtract(Duration(days: now.weekday - 1));
        return !created.isBefore(weekStart);
      case CasesDateRange.thisMonth:
        return created.year == now.year && created.month == now.month;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final jobsState = ref.watch(jobsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: _showSearch
                  ? const BoxDecoration(color: Colors.white)
                  : const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFEAF8FC), Color(0xFFF7F8FA)],
                      ),
                    ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showSearch)
                      _CasesSearchBar(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        isScanning: _isScanning,
                        onChanged: _onSearchChanged,
                        onClose: _closeSearch,
                        onScan: _scanBarcode,
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l.navCases,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            _RoundIconButton(icon: Icons.tune, onPressed: _openFilter),
                            const SizedBox(width: 8),
                            _RoundIconButton(
                              icon: Icons.search,
                              onPressed: _openSearch,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SoftSurface(
                          radius: 22,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: _FilterRow(
                              tabs: _reportTabs(l),
                              selectedIndex: _selectedReport,
                              onSelected: _selectReport,
                              allCount: jobsState.count,
                              padded: false,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _FilterRow(
                        tabs: _progressTabs(l),
                        selectedIndex: _selectedProgress,
                        onSelected: _selectProgress,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (jobsState.cachedAt != null)
                      OfflineBanner(cachedAt: jobsState.cachedAt!),
                    Expanded(child: _buildBody(jobsState)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _showSearch ? null : AppFab(onCreated: _load),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _buildBody(JobsState jobsState) {
    final l = L.of(context);
    if (jobsState.isLoading && !_isRefreshing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (jobsState.error != null && jobsState.jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                jobsState.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              AppTextButton(label: l.retry, onPressed: _load),
            ],
          ),
        ),
      );
    }

    final jobs = _visibleJobs(jobsState.jobs);

    if (jobs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            _EmptyRepairs(),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
        itemCount: jobs.length + (jobsState.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          if (index >= jobs.length) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Center(
                child: jobsState.isLoadingMore
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      )
                    : AppTextButton(
                        label: l.loadMore,
                        onPressed: () => ref.read(jobsProvider.notifier).loadMore(),
                      ),
              ),
            );
          }
          return _CaseCard(
            job: jobs[index],
            inspectionStyle: _selectedReport == 2,
            onStatusUpdated: _load,
          );
        },
      ),
    );
  }
}

class _FilterTab {
  const _FilterTab({
    required this.label,
    required this.color,
    this.clientReport,
    this.workStatus,
  });

  final String label;
  final Color color;
  final String? clientReport;
  final String? workStatus;
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    this.allCount,
    this.padded = true,
  });

  final List<_FilterTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final int? allCount;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: padded ? 20 : 10),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final label = index == 0 && allCount != null ? '$allCount All' : tab.label;
          return _StatusTabChip(
            label: label,
            color: tab.color,
            selected: index == selectedIndex,
            onTap: () => onSelected(index),
          );
        },
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F4F6),
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: const Color(0x14000000),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFF374151)),
      ),
    );
  }
}

class _CasesSearchBar extends StatelessWidget {
  const _CasesSearchBar({
    required this.controller,
    required this.focusNode,
    required this.isScanning,
    required this.onChanged,
    required this.onClose,
    required this.onScan,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isScanning;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF374151)),
          ),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFA5E1EF)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search, color: Color(0xFF111827), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: onChanged,
                      cursorColor: const Color(0xFF33BEE9),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: '',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF33BEE9).withValues(alpha: 0.28),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: isScanning ? null : onScan,
                        icon: isScanning
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.qr_code_scanner, color: Color(0xFF33BEE9)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifyBellButton extends StatelessWidget {
  const _NotifyBellButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.notifications, size: 22, color: Color(0xFF22C55E)),
        ),
      ),
    );
  }
}

class _StatusTabChip extends StatelessWidget {
  const _StatusTabChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyRepairs extends StatelessWidget {
  const _EmptyRepairs();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: Color(0xFFD9F3FB),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.build, size: 52, color: Colors.white),
        ),
        const SizedBox(height: 18),
        Text(
          l.noRepairs,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l.noRepairsHint,
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _CaseLook {
  const _CaseLook({
    required this.label,
    required this.icon,
    required this.stripe,
    required this.badgeBg,
    required this.accent,
  });

  final String label;
  final IconData icon;
  final Color stripe;
  final Color badgeBg;
  final Color accent;

  static _CaseLook _rejected(L l) => _CaseLook(
    label: l.clientRejected,
    icon: Icons.close,
    stripe: Color(0xFFF04D4E),
    badgeBg: Color(0xFFFFE4E6),
    accent: Color(0xFFF04D4E),
  );

  static _CaseLook _done(L l) => _CaseLook(
    label: l.workDone,
    icon: Icons.check_circle,
    stripe: Color(0xFF22C55E),
    badgeBg: Color(0xFFDCFCE7),
    accent: Color(0xFF16A34A),
  );

  static _CaseLook _pending(L l) => _CaseLook(
    label: l.workPending,
    icon: Icons.history,
    stripe: Color(0xFFF5B942),
    badgeBg: Color(0xFFFFF4E5),
    accent: Color(0xFFE08A1A),
  );

  static _CaseLook of(Job job, L l, {bool inspectionStyle = false}) {
    if (job.clientReport == 'rejected') return _rejected(l);
    if (job.clientReport == 'wait_client') {
      return _CaseLook(
        label: l.clientWaitClient,
        icon: Icons.timelapse,
        stripe: Color(0xFF6B7280),
        badgeBg: Color(0xFFF3F4F6),
        accent: Color(0xFF4B5563),
      );
    }
    if (job.workStatus == 'in_progress') {
      if (inspectionStyle) {
        return _CaseLook(
          label: l.filterInspection,
          icon: Icons.sync,
          stripe: Color(0xFF8B5CF6),
          badgeBg: Color(0xFFF3E8FF),
          accent: Color(0xFF7C3AED),
        );
      }
      return _CaseLook(
        label: l.workInProgress,
        icon: Icons.sync,
        stripe: Color(0xFF33BEE9),
        badgeBg: Color(0xFFE5F9FD),
        accent: Color(0xFF0EA5E9),
      );
    }
    if (job.workStatus == 'finished' || job.clientReport == 'finished') {
      return _done(l);
    }
    if (job.workStatus == 'pending') return _pending(l);
    switch (job.status) {
      case 'has_problems':
        return _rejected(l);
      case 'completed':
        return _done(l);
      default:
        return _pending(l);
    }
  }
}

/// تنسيق السعر بنفس عُرف باقي التطبيق: رقمين عشريين بدون رمز عملة.
/// الأرقام الصحيحة بتنعرض بدون كسور (150 مو 150.00).
String _formatPrice(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({
    required this.job,
    required this.onStatusUpdated,
    this.inspectionStyle = false,
  });

  final Job job;
  final Future<void> Function() onStatusUpdated;
  final bool inspectionStyle;

  String _diskLabel(L l) {
    switch (job.hardDiskType) {
      case 'hdd_35':
        return l.typeHdd35;
      case 'hdd_25':
        return l.typeHdd25;
      case 'ssd':
        return l.typeSsd;
      case 'nvme':
        return l.typeNvme;
      case 'external':
        return l.typeExternal;
      case 'usb':
        return l.typeUsb;
      case 'memory_card':
        return l.typeMemoryCard;
      default:
        return l.typeOther;
    }
  }

  Future<void> _openDetails(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CaseDetailScreen(jobId: job.id),
      ),
    );
    await onStatusUpdated();
  }

  Future<void> _openQuotation(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuotationScreen(
          jobId: job.id,
          jobCustomerName: job.customerName,
          jobCustomerPhone: job.customerPhone,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final look = _CaseLook.of(job, l, inspectionStyle: inspectionStyle);
    final dateText = DateFormat('d MMM yyyy', 'en').format(job.createdAt.toLocal());

    return SoftSurface(
      radius: 24,
      child: GestureDetector(
        // الضغط بيفتح التفاصيل (كان ما بيعمل شي)، والضغط الطويل بيضل
        // اختصار للعرض المالي. بعد الرجوع منحدّث القائمة لأن شاشة
        // التفاصيل تقدر تغيّر الحالة.
        onTap: () => _openDetails(context),
        onLongPress: () => _openQuotation(context),
        child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: look.stripe),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 4, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              job.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                        ),
                        if (job.waitClientOverdue)
                          const Padding(
                            padding: EdgeInsets.only(top: 6, left: 6),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8, right: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '#${job.invoiceNumber}',
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF6B7280)),
                              ),
                              // السعر بيظهر بس لما ينحدّد — القضايا الجديدة بدون سعر
                              if (job.price != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  _formatPrice(job.price!),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 14, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 4),
                        Text(
                          dateText,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: look.badgeBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.build_outlined, size: 16, color: look.accent),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _diskLabel(l),
                              style: TextStyle(
                                color: look.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (job.customerEmail.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _InfoRow(icon: Icons.mail_outline, text: job.customerEmail),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoRow(icon: Icons.phone_outlined, text: job.customerPhone),
                        ),
                        if (look.label == l.workDone) ...[
                          _NotifyBellButton(
                            onTap: () => NotifyCustomerSheet.show(context, jobId: job.id),
                          ),
                          const SizedBox(width: 6),
                        ],
                        _StatusChipButton(
                          label: look.label,
                          icon: look.icon,
                          background: look.badgeBg,
                          foreground: look.accent,
                          onTap: () {
                            UpdateStatusSheet.show(
                              context,
                              job: job,
                              onUpdated: onStatusUpdated,
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _StatusChipButton extends StatelessWidget {
  const _StatusChipButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Icon(Icons.keyboard_arrow_down, size: 16, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
          ),
        ),
      ],
    );
  }
}
