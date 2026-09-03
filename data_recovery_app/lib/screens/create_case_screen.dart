import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../providers/jobs_provider.dart';

class CreateCaseScreen extends ConsumerStatefulWidget {
  const CreateCaseScreen({super.key});

  @override
  ConsumerState<CreateCaseScreen> createState() => _CreateCaseScreenState();
}

class _CreateCaseScreenState extends ConsumerState<CreateCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _serialController = TextEditingController();
  final _problemController = TextEditingController();

  static const _accent = Color(0xFF33BEE9);
  static const _scanner = Color(0xFF2998BA);
  static const _gradientStart = Color(0xFF5CCBED);
  static const _gradientEnd = Color(0xFF2EABD2);

  static const _deviceTypes = <(String value, String label)>[
    ('hdd_35', 'HDD 3.5'),
    ('hdd_25', 'HDD 2.5'),
    ('ssd', 'SSD'),
    ('nvme', 'NVMe'),
    ('external', 'هارد خارجي'),
    ('usb', 'فلاش USB'),
    ('memory_card', 'كرت ذاكرة'),
    ('other', 'أخرى'),
  ];

  String? _deviceType;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _serialController.dispose();
    _problemController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final serial = _serialController.text.trim();
      final email = _emailController.text.trim();
      final problem = _problemController.text.trim();

      // TODO: revisit barcode/serial_number relationship once confirmed
      final payload = <String, dynamic>{
        'customer_name': _nameController.text.trim(),
        'customer_phone': _phoneController.text.trim(),
        'hard_disk_type': _deviceType,
        'serial_number': serial,
        'barcode': serial,
        if (email.isNotEmpty) 'customer_email': email,
        if (problem.isNotEmpty) 'problem': problem,
      };

      await ref.read(jobsProvider.notifier).createJob(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('تم إنشاء الفاتورة بنجاح')));
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error.message.isNotEmpty ? error.message : 'تعذّر إنشاء الفاتورة');
    } catch (_) {
      if (!mounted) return;
      _showError('تعذّر إنشاء الفاتورة');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'هذا الحقل مطلوب';
    return null;
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
          'Create New Case',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              const _SectionTitle('CUSTOMER INFORMATION'),
              const SizedBox(height: 16),
              _LabeledField(
                label: 'Full Name',
                child: TextFormField(
                  controller: _nameController,
                  enabled: !_isSubmitting,
                  textInputAction: TextInputAction.next,
                  validator: _required,
                  decoration: _inputDecoration(hint: 'Enter Full Name'),
                ),
              ),
              const SizedBox(height: 16),
              _LabeledField(
                label: 'phone Number',
                child: TextFormField(
                  controller: _phoneController,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: _required,
                  decoration: _inputDecoration(hint: '+96433416...'),
                ),
              ),
              const SizedBox(height: 16),
              _LabeledField(
                label: 'Email Address',
                child: TextFormField(
                  controller: _emailController,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(hint: '@example.com'),
                ),
              ),
              const SizedBox(height: 28),
              const _SectionTitle('DEVICE DETAILS'),
              const SizedBox(height: 16),
              _LabeledField(
                label: 'Device Type',
                child: DropdownButtonFormField<String>(
                  initialValue: _deviceType,
                  isExpanded: true,
                  decoration: _inputDecoration(hint: 'Select device type'),
                  items: [
                    for (final item in _deviceTypes)
                      DropdownMenuItem(value: item.$1, child: Text(item.$2)),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _deviceType = value),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'هذا الحقل مطلوب' : null,
                ),
              ),
              const SizedBox(height: 16),
              _LabeledField(
                label: 'Serial Number',
                child: TextFormField(
                  controller: _serialController,
                  enabled: !_isSubmitting,
                  textInputAction: TextInputAction.next,
                  validator: _required,
                  decoration: _inputDecoration(
                    hint: '#4232323..',
                    suffix: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.qr_code_scanner, color: _scanner),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // TODO: confirm actual meaning/options for Recovery Details
              _LabeledField(
                label: 'Recovery Details',
                child: TextFormField(
                  controller: _problemController,
                  enabled: !_isSubmitting,
                  textInputAction: TextInputAction.done,
                  decoration: _inputDecoration(hint: 'Describe the problem'),
                ),
              ),
              const SizedBox(height: 28),
              const _SectionTitle('MEDIA & DOCUMENT'),
              const SizedBox(height: 16),
              // TODO: no file upload support in backend yet
              const _UploadPlaceholder(),
              const SizedBox(height: 28),
              const _SectionTitle('STATUS'),
              const SizedBox(height: 16),
              // TODO: backend always sets status=received on creation, this field is display-only
              _LabeledField(
                label: 'Current Status',
                child: TextFormField(
                  enabled: false,
                  initialValue: 'Received',
                  decoration: _inputDecoration(hint: 'Received'),
                ),
              ),
              const SizedBox(height: 28),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    colors: [_gradientStart, _gradientEnd],
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isSubmitting ? null : _submit,
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: 52,
                      child: Center(
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Add Case',
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
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      suffixIcon: suffix,
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
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
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
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _UploadPlaceholder extends StatelessWidget {
  const _UploadPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1D5DB), width: 1.4),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          child: Column(
            children: [
              Icon(Icons.cloud_upload_outlined, size: 36, color: Color(0xFF33BEE9)),
              SizedBox(height: 8),
              Text(
                'Add Photos/Documents',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Upload JPG, PNG or PDF up to 10MB',
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
