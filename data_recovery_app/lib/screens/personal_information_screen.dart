import 'package:flutter/material.dart';

import 'widgets/soft_surface.dart';

class PersonalInformationScreen extends StatelessWidget {
  const PersonalInformationScreen({
    super.key,
    this.username,
  });

  final String? username;

  String get _email {
    final handle = (username ?? '').trim().toLowerCase();
    if (handle.isEmpty) return 'a.wright@datarecovery.io';
    return '$handle@datarecovery.io';
  }

  @override
  Widget build(BuildContext context) {
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
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF3F4F6),
                      ),
                      child: const Icon(Icons.person, size: 64, color: Color(0xFFD1D5DB)),
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
                          onTap: () {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(content: Text('Photo upload coming soon')),
                              );
                          },
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
                      label: 'EMAIL ADDRESS',
                      value: _email,
                    ),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    const _InfoTile(
                      icon: Icons.smartphone_outlined,
                      label: 'PHONE NUMBER',
                      value: '+1 (555) 234-8901',
                    ),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    const _InfoTile(
                      icon: Icons.work_outline,
                      label: 'ROLE / DEPARTMENT',
                      value: 'Data Recovery & Forensic Analysis',
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF4B5563), size: 20),
          ),
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
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF),
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
