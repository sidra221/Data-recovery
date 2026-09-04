import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/job.dart';
import '../providers/jobs_provider.dart';
import 'create_case_screen.dart';
import 'quotation_screen.dart';
import 'widgets/app_bottom_nav.dart';
import 'widgets/notify_customer_sheet.dart';
import 'widgets/update_status_sheet.dart';

class CasesListScreen extends ConsumerStatefulWidget {
  const CasesListScreen({super.key});

  @override
  ConsumerState<CasesListScreen> createState() => _CasesListScreenState();
}

class _CasesListScreenState extends ConsumerState<CasesListScreen> {
  static const _accent = Color(0xFF33BEE9);
  static const _gradientStart = Color(0xFF5CCBED);
  static const _gradientEnd = Color(0xFF2EABD2);

  // TODO: revisit tab-to-status mapping once naming decision confirmed
  static const _tabs = <_CaseTab>[
    _CaseTab(label: 'All', status: null, color: _accent),
    _CaseTab(label: 'Agree', status: 'finished', color: Color(0xFF22C55E)),
    _CaseTab(label: 'Inspection', status: 'received', color: Color(0xFF8B5CF6)),
    _CaseTab(label: 'Wait Client', status: 'completed', color: Color(0xFF878688)),
    _CaseTab(label: 'Rejected', status: 'has_problems', color: Color(0xFFF04D4E)),
  ];

  int _selectedTab = 0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  String? get _selectedStatus => _tabs[_selectedTab].status;

  Future<void> _load() async {
    try {
      await ref.read(jobsProvider.notifier).fetchJobs(status: _selectedStatus);
    } catch (_) {
      // الخطأ محفوظ بـ jobsProvider
    }
  }

  Future<void> _refresh() async {
    _isRefreshing = true;
    try {
      await _load();
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _selectTab(int index) async {
    if (_selectedTab == index) return;
    setState(() => _selectedTab = index);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(jobsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Cases',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  _RoundIconButton(icon: Icons.tune, onPressed: () {}),
                  const SizedBox(width: 8),
                  _RoundIconButton(icon: Icons.search, onPressed: () {}),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final tab = _tabs[index];
                  final selected = index == _selectedTab;
                  return _StatusTabChip(
                    tab: tab,
                    selected: selected,
                    onTap: () => _selectTab(index),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody(jobsState)),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [_gradientStart, _gradientEnd]),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CreateCaseScreen(),
              ),
            );
            await _load();
          },
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _buildBody(JobsState jobsState) {
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
              TextButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (jobsState.jobs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Center(child: Text('No cases found')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
        itemCount: jobsState.jobs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _CaseCard(
          job: jobsState.jobs[index],
          onStatusUpdated: _load,
        ),
      ),
    );
  }
}

class _CaseTab {
  const _CaseTab({
    required this.label,
    required this.status,
    required this.color,
  });

  final String label;
  final String? status;
  final Color color;
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F4F6),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFF374151)),
      ),
    );
  }
}

class _StatusTabChip extends StatelessWidget {
  const _StatusTabChip({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _CaseTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected ? const Color(0xFF33BEE9) : tab.color.withValues(alpha: 0.14);
    final foreground = selected ? Colors.white : tab.color;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            tab.label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _CaseColors {
  const _CaseColors({required this.stripe, required this.badgeBg, required this.badgeText});

  final Color stripe;
  final Color badgeBg;
  final Color badgeText;

  static _CaseColors forStatus(String status) {
    switch (status) {
      case 'finished':
        return const _CaseColors(
          stripe: Color(0xFF22C55E),
          badgeBg: Color(0xFFE7FFED),
          badgeText: Color(0xFF22C55E),
        );
      case 'has_problems':
        return const _CaseColors(
          stripe: Color(0xFFF04D4E),
          badgeBg: Color(0xFFFFF5F3),
          badgeText: Color(0xFFF04D4E),
        );
      case 'completed':
        return const _CaseColors(
          stripe: Color(0xFF878688),
          badgeBg: Color(0xFFF5F5F5),
          badgeText: Color(0xFF878688),
        );
      case 'received':
      default:
        return const _CaseColors(
          stripe: Color(0xFF33BEE9),
          badgeBg: Color(0xFFE5F9FD),
          badgeText: Color(0xFF33BEE9),
        );
    }
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.job, required this.onStatusUpdated});

  final Job job;
  final Future<void> Function() onStatusUpdated;

  @override
  Widget build(BuildContext context) {
    final colors = _CaseColors.forStatus(job.status);
    final dateText = DateFormat('d MMM yyyy').format(job.createdAt.toLocal());

    return Material(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: const Color(0x14000000),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        // TODO: navigate to case detail
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: colors.stripe),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                job.customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                            Text(
                              '#${job.invoiceNumber}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: colors.badgeBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.sd_storage_outlined, size: 16, color: colors.badgeText),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  job.hardDiskTypeLabel,
                                  style: TextStyle(
                                    color: colors.badgeText,
                                    fontWeight: FontWeight.w600,
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
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _InfoRow(icon: Icons.phone_outlined, text: job.customerPhone),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => QuotationScreen(
                                      jobId: job.id,
                                      jobCustomerName: job.customerName,
                                      jobCustomerPhone: job.customerPhone,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.request_quote),
                              color: const Color(0xFF6B7280),
                              visualDensity: VisualDensity.compact,
                            ),
                            // TODO: restrict bell icon visibility to appropriate status once naming decision confirmed
                            IconButton(
                              onPressed: () {
                                NotifyCustomerSheet.show(
                                  context,
                                  jobId: job.id,
                                );
                              },
                              icon: const Icon(Icons.notifications_none),
                              color: const Color(0xFF6B7280),
                              visualDensity: VisualDensity.compact,
                            ),
                            Material(
                              color: colors.badgeBg,
                              borderRadius: BorderRadius.circular(999),
                              child: InkWell(
                                onTap: () {
                                  UpdateStatusSheet.show(
                                    context,
                                    jobId: job.id,
                                    currentStatus: job.status,
                                    onUpdated: onStatusUpdated,
                                  );
                                },
                                borderRadius: BorderRadius.circular(999),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        job.statusLabel,
                                        style: TextStyle(
                                          color: colors.badgeText,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Icon(Icons.keyboard_arrow_down, size: 16, color: colors.badgeText),
                                    ],
                                  ),
                                ),
                              ),
                            ),
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
