import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/customer.dart';
import '../providers/customers_provider.dart';
import 'customer_detail_screen.dart';
import 'widgets/app_bottom_nav.dart';

class CustomersListScreen extends ConsumerStatefulWidget {
  const CustomersListScreen({super.key});

  @override
  ConsumerState<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends ConsumerState<CustomersListScreen> {
  static const _accent = Color(0xFF33BEE9);

  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await ref.read(customersProvider.notifier).fetchCustomers(
            search: _searchController.text.trim(),
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

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
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
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Text(
                      'Customers List',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search Name, Email, phone',
                        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFBFE9F6)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFBFE9F6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: _accent, width: 1.2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _buildBody(state)),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const AppFab(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  Widget _buildBody(CustomersState state) {
    if (state.isLoading && !_isRefreshing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.customers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.error!,
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

    if (state.customers.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Center(child: Text('No customers found')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
        itemCount: state.customers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _CustomerCard(
          customer: state.customers[index],
          onReturned: _load,
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer, required this.onReturned});

  final Customer customer;
  final Future<void> Function() onReturned;

  @override
  Widget build(BuildContext context) {
    final initial = customer.fullName.isNotEmpty ? customer.fullName[0].toUpperCase() : '?';
    final lastVisit = customer.lastVisit == null
        ? 'Last: -'
        : 'Last: ${DateFormat('d MMM yyyy', 'en').format(customer.lastVisit!.toLocal())}';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CustomerDetailScreen(customerId: customer.id),
                ),
              );
              await onReturned();
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFEDE9FE),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Color(0xFF3730A3),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Color(0xFF1E3A5F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${customer.totalRepairs} Repairs',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    lastVisit,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
