import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/api_client.dart';
import '../models/customer.dart';
import '../providers/auth_provider.dart';
import '../providers/customers_provider.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final int customerId;

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  static const _accent = Color(0xFF33BEE9);
  static const _gradientStart = Color(0xFF5CCBED);
  static const _gradientEnd = Color(0xFF2EABD2);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  Customer? _customer;
  String? _error;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final customer = await ref.read(apiClientProvider).getCustomer(widget.customerId);
      if (!mounted) return;
      _applyCustomer(customer);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.message.isNotEmpty ? error.message : 'Failed to load customer';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load customer';
      });
    }
  }

  void _applyCustomer(Customer customer) {
    _nameController.text = customer.fullName;
    _phoneController.text = customer.phone;
    _emailController.text = customer.email;
    setState(() {
      _customer = customer;
      _isLoading = false;
      _error = null;
    });
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('d MMM yyyy').format(value.toLocal());
  }

  Future<void> _update() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final updated = await ref.read(customersProvider.notifier).updateCustomer(
            widget.customerId,
            {
              'full_name': _nameController.text.trim(),
              'phone': _phoneController.text.trim(),
              'email': _emailController.text.trim(),
            },
          );
      if (!mounted) return;
      _applyCustomer(updated);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Updated successfully')));
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error.message.isNotEmpty ? error.message : 'Failed to update');
    } catch (_) {
      if (!mounted) return;
      _showError('Failed to update');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text('Are you sure you want to delete this customer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(customersProvider.notifier).deleteCustomer(widget.customerId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } catch (_) {
      if (!mounted) return;
      _showError('Failed to delete customer');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Customer Details',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            enabled: !_isSaving && !_isDeleting && _customer != null,
            icon: const Icon(Icons.more_vert, color: Color(0xFF111827)),
            onSelected: (value) {
              if (value == 'delete') _confirmDelete();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _customer == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error ?? 'Failed to load customer',
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

    final customer = _customer!;
    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const Text(
              'Customer state',
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
                    label: 'Total Repairs',
                    value: '${customer.totalRepairs}',
                    icon: Icons.build_outlined,
                    iconBg: const Color(0xFFE5F9FD),
                    iconColor: const Color(0xFF33BEE9),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Total Spent',
                    value: '${customer.totalSpent} \$',
                    icon: Icons.payments_outlined,
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
                    label: 'First visit',
                    value: _formatDate(customer.firstVisit),
                    icon: Icons.event_available_outlined,
                    iconBg: const Color(0xFFE7FFED),
                    iconColor: const Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Last visit',
                    value: _formatDate(customer.lastVisit),
                    icon: Icons.event_outlined,
                    iconBg: const Color(0xFFFFF7ED),
                    iconColor: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const _SectionTitle('CUSTOMER INFORMATION'),
            const SizedBox(height: 16),
            _LabeledField(
              label: 'Full Name',
              child: TextFormField(
                controller: _nameController,
                enabled: !_isSaving,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'This field is required' : null,
                decoration: _inputDecoration(hint: 'Enter Full Name'),
              ),
            ),
            const SizedBox(height: 16),
            _LabeledField(
              label: 'phone Number',
              child: TextFormField(
                controller: _phoneController,
                enabled: !_isSaving,
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'This field is required' : null,
                decoration: _inputDecoration(hint: '+96433416...'),
              ),
            ),
            const SizedBox(height: 16),
            _LabeledField(
              label: 'Email Address',
              child: TextFormField(
                controller: _emailController,
                enabled: !_isSaving,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(hint: '@example.com'),
              ),
            ),
            const SizedBox(height: 28),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(colors: [_gradientStart, _gradientEnd]),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isSaving ? null : _update,
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 52,
                    child: Center(
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Update',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 1.2),
      ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF33BEE9),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
