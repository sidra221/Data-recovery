import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../providers/auth_provider.dart';
import 'widgets/soft_surface.dart';

class PersonalInformationScreen extends ConsumerStatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  ConsumerState<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends ConsumerState<PersonalInformationScreen> {
  bool _uploading = false;

  /// بيخيّر بين الاستديو والكاميرا بدل ما يفتح الكاميرا مباشرة.
  Future<ImageSource?> _askSource() {
    final l = L.of(context);
    return showModalBottomSheet<ImageSource>(
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
              leading: const Icon(Icons.photo_library_outlined,
                  color: Color(0xFF1E3A5F)),
              title: Text(l.chooseFromGallery),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: Color(0xFF1E3A5F)),
              title: Text(l.takePhoto),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final l = L.of(context);
    if (_uploading) return;
    final source = await _askSource();
    if (source == null) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      await ref.read(apiClientProvider).updateMe(
            photoPath: picked.path,
            photoFilename: picked.name,
          );
      await ref.read(authProvider.notifier).refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.photoUpdated)));
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.failedToUploadPhoto)));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final profile = ref.watch(authProvider).profile;
    final email = profile?.email ?? '';
    final phone = profile?.phone ?? '';
    final role = [
      if ((profile?.role ?? '').isNotEmpty) profile!.role,
      if ((profile?.department ?? '').isNotEmpty) profile!.department,
    ].join(' • ');
    final photoUrl = profile?.photoUrl ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              children: [
                _CircleBackButton(onPressed: () => Navigator.of(context).pop()),
                const SizedBox(width: 8),
                const Text(
                  'personal information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Center(
              child: SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFFF3F4F6),
                      backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                      child: photoUrl.isEmpty
                          ? const Icon(Icons.person, size: 64, color: Color(0xFFD1D5DB))
                          : _uploading
                              ? const CircularProgressIndicator()
                              : null,
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 2,
                        shadowColor: const Color(0x33000000),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _uploading ? null : _pickPhoto,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.photo_camera_outlined, size: 18, color: Color(0xFF111827)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            SoftSurface(
              radius: 22,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  children: [
                    _InfoTile(
                      icon: Icons.mail_outline,
                      label: l.emailAddressCaps,
                      value: email.isEmpty ? '—' : email,
                    ),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    _InfoTile(
                      icon: Icons.smartphone_outlined,
                      label: l.phoneNumberCaps,
                      value: phone.isEmpty ? '—' : phone,
                    ),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    _InfoTile(
                      icon: Icons.work_outline,
                      label: l.roleDepartment,
                      value: role.isEmpty ? '—' : role,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Icon(Icons.chevron_left, color: Color(0xFF111827), size: 26),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
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
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.6,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
