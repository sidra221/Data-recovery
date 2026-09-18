import 'package:flutter/material.dart';

import '../core/api_error_text.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/api_client.dart';
import '../models/customer.dart';
import '../models/job.dart';
import '../providers/auth_provider.dart';
import '../providers/customers_provider.dart';
import 'widgets/app_button.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final int customerId;

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameFocus = FocusNode();

  Customer? _customer;
  List<Job> _jobs = const [];
  bool _jobsLoading = true;
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
    _nameFocus.dispose();
    super.dispose();
  }

  /// أجهزة العميل. فشل هالنداء ما بيكسر الشاشة — بيعرض القسم فاضي مع
  /// إمكانية إعادة المحاولة، لأن معلومات العميل نفسها أهم.
  Future<void> _loadJobs() async {
    setState(() => _jobsLoading = true);
    try {
      final page = await ref
          .read(apiClientProvider)
          .listJobs(customerId: widget.customerId);
      if (!mounted) return;
      setState(() {
        _jobs = page.results;
        _jobsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _jobs = const [];
        _jobsLoading = false;
      });
    }
  }

  Future<void> _load() async {
    final l = L.of(context);
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final customer = await ref.read(apiClientProvider).getCustomer(widget.customerId);
      if (!mounted) return;
      _applyCustomer(customer);
      _loadJobs();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = apiErrorText(l, error, fallback: l.failedToLoadCustomer);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = l.failedToLoadCustomer;
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
    return DateFormat('d MMM yyyy', 'en').format(value.toLocal());
  }

  Future<void> _update() async {
    final l = L.of(context);
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
        ..showSnackBar(SnackBar(content: Text(l.updatedSuccessfully)));
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(apiErrorText(l, error, fallback: l.failedToUpdate));
    } catch (_) {
      if (!mounted) return;
      _showError(l.failedToUpdate);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final l = L.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x66000000),
      builder: (context) => const _DeleteCustomerDialog(),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(customersProvider.notifier).deleteCustomer(widget.customerId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(apiErrorText(l, error, fallback: l.failedToDeleteCustomer));
    } catch (_) {
      if (!mounted) return;
      _showError(l.failedToDeleteCustomer);
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
    final l = L.of(context);
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
        title: Text(
          l.customerDetails,
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
            color: Colors.white,
            elevation: 4,
            shadowColor: const Color(0x33000000),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            position: PopupMenuPosition.under,
            onSelected: (value) {
              if (value == 'edit') {
                _nameFocus.requestFocus();
              } else if (value == 'delete') {
                _confirmDelete();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, color: Color(0xFF111827), size: 20),
                    SizedBox(width: 10),
                    Text(l.edit),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                    SizedBox(width: 10),
                    Text(l.delete, style: TextStyle(color: Color(0xFFEF4444))),
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
    final l = L.of(context);
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
                _error ?? l.failedToLoadCustomer,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: Text(l.retry)),
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
            Text(
              l.customerState,
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
                    label: l.totalRepairs,
                    value: '${customer.totalRepairs}',
                    icon: Icons.build_outlined,
                    iconBg: const Color(0xFFE5F9FD),
                    iconColor: const Color(0xFF33BEE9),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: l.totalSpent,
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
                    label: l.firstVisit,
                    value: _formatDate(customer.firstVisit),
                    icon: Icons.event_available_outlined,
                    iconBg: const Color(0xFFE7FFED),
                    iconColor: const Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: l.lastVisit,
                    value: _formatDate(customer.lastVisit),
                    icon: Icons.event_outlined,
                    iconBg: const Color(0xFFFFF7ED),
                    iconColor: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(child: _SectionTitle(l.devices)),
                if (!_jobsLoading)
                  Text(
                    '${_jobs.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_jobsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_jobs.isEmpty)
              _SoftSurface(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.inbox_outlined,
                          color: Color(0xFF9CA3AF), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l.noDevicesYet,
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ),
                      TextButton(onPressed: _loadJobs, child: Text(l.retry)),
                    ],
                  ),
                ),
              )
            else
              for (final job in _jobs) ...[
                _DeviceCard(job: job),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 28),
            _SectionTitle(l.customerInformation),
            const SizedBox(height: 16),
            _LabeledField(
              label: l.fullName,
              child: _SoftSurface(
                child: TextFormField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  enabled: !_isSaving,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? l.fieldRequired : null,
                  decoration: _inputDecoration(hint: l.enterFullName),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _LabeledField(
              label: l.phoneNumber,
              child: _SoftSurface(
                child: TextFormField(
                  controller: _phoneController,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? l.fieldRequired : null,
                  decoration: _inputDecoration(hint: '+96433416...'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _LabeledField(
              label: l.emailAddress,
              child: _SoftSurface(
                child: TextFormField(
                  controller: _emailController,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(hint: '@example.com'),
                ),
              ),
            ),
            const SizedBox(height: 28),
            AppButton(
              label: l.update,
              isLoading: _isSaving,
              onPressed: _update,
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
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
    );
  }
}

/// كرت جهاز واحد للعميل: رقم الفاتورة والحالة، ونوع الهاردسك والموديل
/// والسيريال ووصف المشكلة — الحقول اللي طلبها العميل.
class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.job});

  final Job job;

  /// لون الحالة بيطابق شارات شاشة القضايا حتى يكون العُرف واحد.
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
    return job.statusLabel;
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final c = _statusColors;
    return _SoftSurface(
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
                    _formatDevicePrice(job.price!),
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
            const SizedBox(height: 10),
            _DeviceRow(
              icon: Icons.storage_outlined,
              label: l.labelType,
              value: job.hardDiskTypeLabel.isNotEmpty
                  ? job.hardDiskTypeLabel
                  : job.hardDiskType,
            ),
            if (job.deviceModel.isNotEmpty)
              _DeviceRow(
                icon: Icons.memory_outlined,
                label: l.labelModel,
                value: job.deviceModel,
              ),
            if (job.serialNumber.isNotEmpty)
              _DeviceRow(
                icon: Icons.qr_code_2_outlined,
                label: l.labelSerial,
                value: job.serialNumber,
              ),
            if (job.problem.isNotEmpty)
              _DeviceRow(
                icon: Icons.report_problem_outlined,
                label: l.labelProblem,
                value: job.problem,
              ),
          ],
        ),
      ),
    );
  }
}

String _formatDevicePrice(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);

/// سطر «تسمية: قيمة». القيمة بتلتف على أكتر من سطر بدل ما تنقص —
/// وصف المشكلة بيكون طويل عادةً.
class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 8),
          SizedBox(
            width: 58,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
          ),
        ],
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
    return _SoftSurface(
      radius: 16,
      child: Padding(
        padding: const EdgeInsets.all(14),
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
          ],
        ),
      ),
    );
  }
}

class _SoftSurface extends StatelessWidget {
  const _SoftSurface({required this.child, this.radius = 12});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Material(
          color: Colors.white,
          child: child,
        ),
      ),
    );
  }
}

class _DeleteCustomerDialog extends StatelessWidget {
  const _DeleteCustomerDialog();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Dialog(
      backgroundColor: Colors.white,
      elevation: 8,
      shadowColor: const Color(0x33000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              l.deleteCustomer,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.deleteCustomerConfirm,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.4),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppTextButton(
                    label: l.cancel,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: l.delete,
                    variant: AppButtonVariant.danger,
                    onPressed: () => Navigator.of(context).pop(true),
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
