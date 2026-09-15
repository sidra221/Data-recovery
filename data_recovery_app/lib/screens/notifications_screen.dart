import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/api_client.dart';
import '../models/job.dart';
import '../providers/auth_provider.dart';
import 'cases_list_screen.dart';
import 'widgets/soft_surface.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<Job> _jobs = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final l = L.of(context);
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final page = await ref.read(apiClientProvider).listJobs(overdue: true);
      if (!mounted) return;
      setState(() {
        _jobs = page.results;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.message.isNotEmpty ? error.message : l.failedToLoadAlerts;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = l.failedToLoadAlerts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          l.notifications,
          style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w700),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l = L.of(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Color(0xFF6B7280))),
            TextButton(onPressed: _load, child: Text(l.retry)),
          ],
        ),
      );
    }
    if (_jobs.isEmpty) {
      return Center(
        child: Text(
          l.noOverdueCases,
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: _jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final job = _jobs[index];
        return SoftSurface(
          radius: 16,
          child: ListTile(
            title: Text(
              job.customerName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '#${job.invoiceNumber}  •  ${DateFormat('d MMM yyyy', 'en').format(job.createdAt.toLocal())}',
            ),
            trailing: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => CasesListScreen(
                    initialClientReport: 'wait_client',
                    initialSearch: job.invoiceNumber,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
