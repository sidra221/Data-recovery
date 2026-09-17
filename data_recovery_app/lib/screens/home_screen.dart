import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/dashboard_stats.dart';
import '../providers/auth_provider.dart';
import 'cases_list_screen.dart';
import 'notifications_screen.dart';
import 'reports_screen.dart';
import 'widgets/app_bottom_nav.dart';
import 'widgets/offline_banner.dart';
import 'widgets/pending_sync_banner.dart';
import '../providers/sync_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _accent = Color(0xFF33BEE9);

  DashboardStats? _stats;
  DateTime? _cachedAt;
  String? _error;
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    if (!_isRefreshing) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final fresh = await ref.read(apiClientProvider).getDashboardStatsCached();
      if (!mounted) return;
      setState(() {
        _stats = fresh.value;
        _cachedAt = fresh.cachedAt;
        _isLoading = false;
        _error = null;
      });
      // نجاح الطلب من الشبكة (مو من الكاش) هو أوضح إشارة إنه السيرفر رجع.
      // منستغلها حتى نرفع يلي انعمل أوفلاين ومنحجز مدى أرقام لو ما عندنا.
      if (!fresh.isFromCache) {
        await ref.read(syncProvider.notifier).ensureNumberBlock();
        if (ref.read(syncProvider).hasPending) {
          await ref.read(syncProvider.notifier).flush();
        }
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.isNetworkError
            ? L.of(context).serverUnreachable
            : (error.message.isNotEmpty
                ? error.message
                : L.of(context).failedToLoadStats);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = L.of(context).failedToLoadStats;
      });
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

  int _count(Map<String, int> source, String key) => source[key] ?? 0;

  void _openCases() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const CasesListScreen(initialClientReport: 'finished'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 28,
                    height: 28,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.storage,
                      size: 28,
                      color: _accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Data Recovery',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _accent,
                      ),
                    ),
                  ),
                  // البحث عن فاتورة بيصير على الكاونتر باستمرار، فمحلّه
                  // بالرأس جنب الجرس مو مدفون جوّا الإعدادات.
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: l.reports,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ReportsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.receipt_long_outlined,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: l.notifications,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_cachedAt != null) OfflineBanner(cachedAt: _cachedAt!),
            const PendingSyncBanner(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: AppFab(onCreated: _load),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildBody() {
    final l = L.of(context);
    if (_isLoading && !_isRefreshing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _stats == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 6),
              Text(
                l.noSavedData,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: Text(l.retry)),
            ],
          ),
        ),
      );
    }

    final stats = _stats!;
    final pending = _count(stats.workStatusCounts, 'pending');
    final inProgress = _count(stats.workStatusCounts, 'in_progress');
    final finishedWork = _count(stats.workStatusCounts, 'finished');
    final agree = _count(stats.clientReportCounts, 'agree');
    final readyForReturn = _count(stats.clientReportCounts, 'finished');

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
        children: [
          Row(
            children: [
              Expanded(
                child: _HeroCard(
                  label: l.clientWaitClient,
                  value: '${_count(stats.clientReportCounts, 'wait_client')}',
                  icon: Icons.schedule,
                  iconBg: const Color(0xFFFFF7ED),
                  accent: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroCard(
                  label: l.clientRejected,
                  value: '${_count(stats.clientReportCounts, 'rejected')}',
                  icon: Icons.cancel_outlined,
                  iconBg: const Color(0xFFFFF5F3),
                  accent: const Color(0xFFF04D4E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HeroCard(
                  label: l.filterInspection,
                  value: '$inProgress',
                  icon: Icons.science_outlined,
                  iconBg: const Color(0xFFE5F9FD),
                  accent: const Color(0xFF33BEE9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroCard(
                  label: l.labelDelivered,
                  value: '${stats.totalDelivered}',
                  icon: Icons.local_shipping_outlined,
                  iconBg: const Color(0xFFF5F3FF),
                  accent: const Color(0xFFA855F7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.recoveryProgress,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7FFED),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l.agreeChip(agree),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF22C55E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _WorkStat(
                  label: l.workPending,
                  value: pending,
                  color: const Color(0xFFFFC562),
                ),
              ),
              Expanded(
                child: _WorkStat(
                  label: l.workInProgress,
                  value: inProgress,
                  color: const Color(0xFF33BEE9),
                ),
              ),
              Expanded(
                child: _WorkStat(
                  label: l.workDone,
                  value: finishedWork,
                  color: const Color(0xFF1AC86C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _WorkStatusBar(
            pending: pending,
            inProgress: inProgress,
            finished: finishedWork,
          ),
          const SizedBox(height: 20),
          _ReadyBanner(
            count: readyForReturn,
            onViewCases: _openCases,
          ),
          const SizedBox(height: 28),
          Text(
            l.todaysActivity,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActivityCard(
                  label: l.newCases,
                  value: '${stats.jobsCreatedToday}',
                  icon: Icons.description_outlined,
                  iconBg: const Color(0xFFE5F9FD),
                  iconColor: const Color(0xFF33BEE9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActivityCard(
                  label: l.updates,
                  value: '${stats.statusChangesToday}',
                  icon: Icons.my_location,
                  iconBg: const Color(0xFFE7FFED),
                  iconColor: const Color(0xFF22C55E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActivityCard(
                  label: l.clientAgree,
                  value: '$agree',
                  icon: Icons.thumb_up_outlined,
                  iconBg: const Color(0xFFE7FFED),
                  iconColor: const Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActivityCard(
                  label: l.labelDelivered,
                  value: '${stats.totalDelivered}',
                  icon: Icons.send_outlined,
                  iconBg: const Color(0xFFFFF7ED),
                  iconColor: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: const Color(0x14000000),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: iconBg,
                          child: Icon(icon, size: 16, color: accent),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          value,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                            height: 1,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: Color(0xFF9CA3AF),
                          ),
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

class _WorkStatusBar extends StatelessWidget {
  const _WorkStatusBar({
    required this.pending,
    required this.inProgress,
    required this.finished,
  });

  final int pending;
  final int inProgress;
  final int finished;

  @override
  Widget build(BuildContext context) {
    final total = pending + inProgress + finished;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 10,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFFE5E7EB)),
            if (total > 0)
              Row(
                // لازم stretch: ColoredBox بدون طفل بينهار لارتفاع صفر مع
                // المحاذاة الافتراضية (center)، فالشريط بيصير غير مرئي.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (pending > 0)
                    Expanded(
                      flex: pending,
                      child: const ColoredBox(color: Color(0xFFFFC562)),
                    ),
                  if (inProgress > 0)
                    Expanded(
                      flex: inProgress,
                      child: const ColoredBox(color: Color(0xFF33BEE9)),
                    ),
                  if (finished > 0)
                    Expanded(
                      flex: finished,
                      child: const ColoredBox(color: Color(0xFF1AC86C)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _WorkStat extends StatelessWidget {
  const _WorkStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}

class _ReadyBanner extends StatelessWidget {
  const _ReadyBanner({required this.count, required this.onViewCases});

  final int count;
  final VoidCallback onViewCases;

  static const _gradientStart = Color(0xFF5CCBED);
  static const _gradientEnd = Color(0xFF2EABD2);

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [_gradientStart, _gradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF33BEE9).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                l.readyForReturn,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.casesCount(count),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.finishedReadyToCollect,
                      style: TextStyle(
                        color: Color(0xE6FFFFFF),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: onViewCases,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Text(
                      l.viewCases,
                      style: TextStyle(
                        color: Color(0xFF2EABD2),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: iconBg,
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
