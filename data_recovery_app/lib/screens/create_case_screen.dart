import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/invoice_number_minter.dart';
import '../models/customer.dart';
import '../providers/auth_provider.dart';
import '../providers/customers_provider.dart';
import '../providers/jobs_provider.dart';
import 'barcode_scanner_screen.dart';
import 'widgets/app_button.dart';
import 'widgets/print_documents_sheet.dart';
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

  // القيم مفاتيح API فما تغيّرت؛ التسميات مترجمة فبتنبنى وقت العرض.
  List<(String value, String label)> _deviceTypes(L l) => [
        ('hdd_35', l.typeHdd35),
        ('hdd_25', l.typeHdd25),
        ('ssd', l.typeSsd),
        ('nvme', l.typeNvme),
        ('external', l.typeExternal),
        ('usb', l.typeUsb),
        ('memory_card', l.typeMemoryCard),
        ('other', l.typeOther),
      ];

  String? _deviceType;
  bool _isSubmitting = false;
  final List<({String path, String name})> _files = [];

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
    final l = L.of(context);
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
        if (email.isNotEmpty) 'customer_email': email,
        if (problem.isNotEmpty) 'problem': problem,
      };

      final job = await ref.read(jobsProvider.notifier).createJob(payload);

      // id سالب = انحفظت على الجهاز وما وصلت السيرفر بعد، فما في id حقيقي
      // نرفع عليه مرفقات.
      final savedOffline = job.id < 0;
      if (_files.isNotEmpty && !savedOffline) {
        await ref.read(apiClientProvider).uploadJobAttachments(
              jobId: job.id,
              files: _files,
            );
      }
      if (!mounted) return;

      final message = savedOffline
          ? (_files.isEmpty
              ? l.savedOfflineWillSync
              : '${l.savedOfflineWillSync} ${l.attachmentsNeedServer}')
          : l.caseCreated;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            duration: savedOffline
                ? const Duration(seconds: 6)
                : const Duration(seconds: 4),
          ),
        );
      // المسار المعتمد: بعد الحفظ بتطلع المطبوعتين فوراً — ستيكر بينلزق على
      // القطعة، وسند بياخده العميل. بتشتغل حتى لو السيرفر مطفّى.
      await PrintDocumentsSheet.show(context, job: job);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on OfflineNumbersExhausted {
      if (!mounted) return;
      _showError(l.noOfflineNumbersLeft);
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error.message.isNotEmpty ? error.message : l.failedToCreateCase);
    } catch (_) {
      if (!mounted) return;
      _showError(l.failedToCreateCase);
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
    final l = L.of(context);
    if (value == null || value.trim().isEmpty) return l.fieldRequired;
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

  /// بيخيّر بين الكاميرا والاستديو والملفات.
  ///
  /// الصور بتنخزّن محلياً بـ _files وبتنرفع بعد ما تنحفظ القضية —
  /// المرفقات بدها id القضية، وهي لسا ما انعملت بهالمرحلة.
  Future<void> _addAttachment() async {
    final l = L.of(context);
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: Color(0xFF1E3A5F)),
              title: Text(l.takePhoto),
              onTap: () => Navigator.of(sheetContext).pop('camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: Color(0xFF1E3A5F)),
              title: Text(l.chooseFromGallery),
              onTap: () => Navigator.of(sheetContext).pop('gallery'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.attach_file, color: Color(0xFF1E3A5F)),
              title: Text(l.chooseFile),
              onTap: () => Navigator.of(sheetContext).pop('file'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    if (source == 'file') {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf', 'webp'],
      );
      if (!mounted) return;
      setState(() {
        for (final file in picked) {
          final path = file.path;
          if (path == null || path.isEmpty) continue;
          _files.add((path: path, name: file.name));
        }
      });
      return;
    }

    final shot = await ImagePicker().pickImage(
      source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (shot == null || !mounted) return;
    setState(() => _files.add((path: shot.path, name: shot.name)));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
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
                    Expanded(
                      child: Text(
                        l.createNewCase,
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
                    _SectionTitle(l.customerInformation),
                    const SizedBox(height: 16),
                    _LabeledField(
                      label: l.fullName,
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
                                hint: l.enterFullName,
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
                      label: l.phoneNumber,
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
                      label: l.emailAddress,
                      child: TextFormField(
                        controller: _emailController,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(hint: '@example.com'),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _SectionTitle(l.deviceDetails),
                    const SizedBox(height: 16),
                    _LabeledField(
                      label: l.deviceType,
                      child: DropdownButtonFormField<String>(
                        initialValue: _deviceType,
                        isExpanded: true,
                        hint: Text(
                          l.deviceType,
                          style: TextStyle(color: Color(0xFF9CA3AF)),
                        ),
                        decoration: _inputDecoration(hint: l.deviceType),
                        items: [
                          for (final item in _deviceTypes(l))
                            DropdownMenuItem(value: item.$1, child: Text(item.$2)),
                        ],
                        onChanged: _isSubmitting
                            ? null
                            : (value) => setState(() => _deviceType = value),
                        validator: (value) =>
                            value == null || value.isEmpty ? l.fieldRequired : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LabeledField(
                      label: l.serialNumber,
                      child: TextFormField(
                        controller: _serialController,
                        enabled: !_isSubmitting,
                        textInputAction: TextInputAction.next,
                        validator: _required,
                        decoration: _inputDecoration(
                          hint: '#4232323..',
                          suffix: IconButton(
                            onPressed: _isSubmitting
                                ? null
                                : () async {
                                    final code = await BarcodeScannerScreen.scan(
                                      context,
                                      title: l.scanSerial,
                                    );
                                    if (code == null || !mounted) return;
                                    _serialController.text = code;
                                  },
                            icon: const Icon(Icons.qr_code_scanner, color: _accent),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LabeledField(
                      label: l.recoveryDetails,
                      child: TextFormField(
                        controller: _problemController,
                        enabled: !_isSubmitting,
                        maxLines: 3,
                        textInputAction: TextInputAction.done,
                        decoration: _inputDecoration(
                          hint: l.whatCustomerReported,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _SectionTitle(l.mediaAndDocument),
                    const SizedBox(height: 16),
                    _UploadPlaceholder(
                      files: _files,
                      enabled: !_isSubmitting,
                      onAdd: _addAttachment,
                      onRemove: (index) => setState(() => _files.removeAt(index)),
                    ),
                    const SizedBox(height: 28),
                    _SectionTitle(l.statusSection),
                    const SizedBox(height: 16),
                    _LabeledField(
                      label: l.currentStatus,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Text(
                          l.statusReceived,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    AppButton(
                      label: l.addCase,
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
  const _UploadPlaceholder({
    required this.files,
    required this.onAdd,
    required this.onRemove,
    required this.enabled,
  });

  final List<({String path, String name})> files;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Column(
      children: [
        CustomPaint(
          painter: const _DashedRRectPainter(color: Color(0xFFD1D5DB), radius: 16),
          child: InkWell(
            onTap: enabled ? onAdd : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
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
                    l.addPhotosDocuments,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    l.uploadHint,
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
          ),
        ),
        for (var i = 0; i < files.length; i++)
          ListTile(
            dense: true,
            leading: const Icon(Icons.attach_file),
            title: Text(files[i].name, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              onPressed: enabled ? () => onRemove(i) : null,
              icon: const Icon(Icons.close),
            ),
          ),
      ],
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
