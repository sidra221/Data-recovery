import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'widgets/app_button.dart';
import 'widgets/soft_surface.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  static const _articles = [
    _HelpArticle(
      title: 'How to recover deleted photos',
      steps: [
        'Create a new case and choose the device that stored the photos.',
        'Keep the drive powered on and avoid writing new files to it.',
        'Wait until inspection finishes, then review recovered files with the customer.',
      ],
    ),
    _HelpArticle(
      title: 'Connecting an external SSD',
      steps: [
        'Power off the workstation before attaching the drive.',
        'Connect the SSD with a compatible cable or dock.',
        'Open a new case and select SSD as the disk type.',
        'Start inspection and follow the case status updates.',
      ],
    ),
    _HelpArticle(
      title: 'Subscription & Billing FAQs',
      steps: [
        'Add the agreed price on the case after the customer approves the quotation.',
        'Send the invoice to the customer from the case details screen.',
        'Mark the job as delivered after payment and handover are complete.',
      ],
    ),
  ];

  final Set<int> _expanded = {1};

  Future<void> _emailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@datarecovery.io',
      queryParameters: {'subject': 'Help Center support request'},
    );
    final opened = await launchUrl(uri);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Could not open email app')));
    }
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
                const Expanded(
                  child: Text(
                    'Help Center',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                children: [
                  Text(
                    'How can we help?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Search our knowledge base or browse categories below',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'POPULAR ARTICLES',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    _expanded
                      ..clear()
                      ..addAll(List.generate(_articles.length, (index) => index));
                  }),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF33BEE9),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(_articles.length, (index) {
              final article = _articles[index];
              final isOpen = _expanded.contains(index);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SoftSurface(
                  radius: 16,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isOpen) {
                          _expanded.remove(index);
                        } else {
                          _expanded.add(index);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.description_outlined,
                                  size: 18,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  article.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                              Icon(
                                isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ],
                          ),
                          if (isOpen) ...[
                            const SizedBox(height: 12),
                            ...List.generate(article.steps.length, (stepIndex) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '${stepIndex + 1}. ${article.steps[stepIndex]}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF4B5563),
                                    height: 1.4,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              decoration: BoxDecoration(
                color: const Color(0xFF2F3237),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  const Text(
                    'Still need help?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Our support team is available 24/7 to assist you with any questions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFFD1D5DB), height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Email Us',
                    icon: Icons.mail_outline,
                    onPressed: _emailSupport,
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

class _HelpArticle {
  const _HelpArticle({required this.title, required this.steps});

  final String title;
  final List<String> steps;
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
