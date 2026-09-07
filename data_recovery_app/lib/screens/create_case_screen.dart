import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/customer.dart';
import '../providers/customers_provider.dart';
import '../providers/jobs_provider.dart';
import 'widgets/app_button.dart';
import 'widgets/soft_surface.dart';

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
  final _nameFocus = FocusNode();

  static const _accent = Color(0xFF33BEE9);

  static const _deviceTypes = <(String value, String label)>[
    ('hdd_35', 'HDD 3.5'),
    ('hdd_25', 'HDD 2.5'),
    ('ssd', 'SSD'),
    ('nvme', 'NVMe'),
    ('external', 'External HDD'),
    ('usb', 'USB Flash'),
    ('memory_card', 'Memory Card'),
    ('other', 'Other'),
  ];

  String? _deviceType;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        await ref.read(customersProvider.notifier).fetchCustomers();
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _serialController.dispose();
    _problemController.dispose();
    _nameFocus.dispose();
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
        ..showSnackBar(const SnackBar(content: Text('Case created successfully')));
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error.message.isNotEmpty ? error.message : 'Failed to create case');
    } catch (_) {
      if (!mounted) return;
      _showError('Failed to create case');
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
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }

  Iterable<Customer> _nameOptions(TextEditingValue value) {
    final customers = ref.read(customersProvider).customers;
    final query = value.text.trim().toLowerCase();
    if (query.isEmpty) return customers.take(8);
    return customers.where((customer) {
      return customer.fullName.toLowerCase().contains(query) ||
          customer.phone.contains(query);
    }).take(8);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    _CircleBackButton(
                      onPressed: _isSubmitting ? () {} : () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Create New Case',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    const _SectionTitle('CUSTOMER INFORMATION'),
                    const SizedBox(height: 16),
                    _LabeledField(
                      label: 'Full Name',
                      wrap: false,
                      child: RawAutocomplete<Customer>(
                        textEditingController: _nameController,
                        focusNode: _nameFocus,
                        displayStringForOption: (customer) => customer.fullName,
                        optionsBuilder: _nameOptions,
                        onSelected: (customer) {
                          _nameController.text = customer.fullName;
                          _phoneController.text = customer.phone;
                          _emailController.text = customer.email;
                          setState(() {});
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return SoftSurface(
                            radius: 14,
                            child: TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              enabled: !_isSubmitting,
                              textInputAction: TextInputAction.next,
                              validator: _required,
                              decoration: _inputDecoration(
                                hint: 'Enter Full Name',
                                suffix: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF)),
                              ),
                            ),
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 6,
                              borderRadius: BorderRadius.circular(12),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 200, maxWidth: 360),
                                child: ListView(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  children: [
                                    for (final customer in options)
                                      ListTile(
                                        dense: true,
                                        title: Text(customer.fullName),
                                        subtitle: Text(customer.phone),
                                        onTap: () => onSelected(customer),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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
                        hint: const Text(
                          'Device type',
                          style: TextStyle(color: Color(0xFF9CA3AF)),
                        ),
                        decoration: _inputDecoration(hint: 'Device type'),
                        items: [
                          for (final item in _deviceTypes)
                            DropdownMenuItem(value: item.$1, child: Text(item.$2)),
                        ],
                        onChanged: _isSubmitting
                            ? null
                            : (value) => setState(() => _deviceType = value),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'This field is required' : null,
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
                            icon: const Icon(Icons.qr_code_scanner, color: _accent),
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
                        decoration: _inputDecoration(
                          hint: 'select type',
                          suffix: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF)),
                        ),
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
                      child: DropdownButtonFormField<String>(
                        initialValue: 'received',
                        isExpanded: true,
                        decoration: _inputDecoration(hint: 'Select Status'),
                        items: const [
                          DropdownMenuItem(value: 'received', child: Text('Received')),
                        ],
                        onChanged: null,
                      ),
                    ),
                    const SizedBox(height: 28),
                    AppButton(
                      label: 'Add Case',
                      isLoading: _isSubmitting,
                      onPressed: _submit,
                    ),
                  ],
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
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accent, width: 1.2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F4F6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.chevron_left, color: Color(0xFF111827), size: 26),
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
          width: 4,
          height: 16,
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
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child, this.wrap = true});

  final String label;
  final Widget child;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        wrap ? SoftSurface(radius: 14, child: child) : child,
      ],
    );
  }
}

class _UploadPlaceholder extends StatelessWidget {
  const _UploadPlaceholder();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(color: const Color(0xFFD1D5DB), radius: 16),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          child: Column(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFF1E3A5F),
                child: Icon(Icons.cloud_upload, color: Colors.white, size: 22),
              ),
              SizedBox(height: 10),
              Text(
                'Add Photos/Documents',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
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

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
