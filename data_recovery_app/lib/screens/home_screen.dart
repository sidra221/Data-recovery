// TODO: align with final dashboard design once status naming confirmed
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/dashboard_stats.dart';
import '../providers/auth_provider.dart';
import 'widgets/app_bottom_nav.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DashboardStats? _stats;
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
      final stats = await ref.read(apiClientProvider).getDashboardStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _isLoading = false;
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.message.isNotEmpty ? error.message : 'Failed to load statistics';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load statistics';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                'Home',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildBody() {
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
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final stats = _stats!;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Received',
                  value: '${_count(stats.statusCounts, 'received')}',
                  icon: Icons.inventory_2_outlined,
                  iconBg: const Color(0xFFE5F9FD),
                  iconColor: const Color(0xFF33BEE9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Finished',
                  value: '${_count(stats.statusCounts, 'finished')}',
                  icon: Icons.check_circle_outline,
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
                child: _StatCard(
                  label: 'Completed',
                  value: '${_count(stats.statusCounts, 'completed')}',
                  icon: Icons.done_all,
                  iconBg: const Color(0xFFF5F5F5),
                  iconColor: const Color(0xFF878688),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Has Problems',
                  value: '${_count(stats.statusCounts, 'has_problems')}',
                  icon: Icons.error_outline,
                  iconBg: const Color(0xFFFFF5F3),
                  iconColor: const Color(0xFFF04D4E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Work Status',
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
                child: _WorkStat(
                  label: 'Pending',
                  value: _count(stats.workStatusCounts, 'pending'),
                ),
              ),
              Expanded(
                child: _WorkStat(
                  label: 'In Progress',
                  value: _count(stats.workStatusCounts, 'in_progress'),
                ),
              ),
              Expanded(
                child: _WorkStat(
                  label: 'Finished',
                  value: _count(stats.workStatusCounts, 'finished'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Today',
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
                child: _StatCard(
                  label: 'New Cases Today',
                  value: '${stats.jobsCreatedToday}',
                  icon: Icons.note_add_outlined,
                  iconBg: const Color(0xFFE5F9FD),
                  iconColor: const Color(0xFF33BEE9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Status Updates Today',
                  value: '${stats.statusChangesToday}',
                  icon: Icons.sync,
                  iconBg: const Color(0xFFFFF7ED),
                  iconColor: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Total customers: ${stats.totalCustomers}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _WorkStat extends StatelessWidget {
  const _WorkStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: iconBg,
            child: Icon(icon, size: 18, color: iconColor),
          ),
        ],
      ),
    );
  }
}
