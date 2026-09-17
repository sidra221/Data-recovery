import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import 'widgets/app_button.dart';
import 'widgets/soft_surface.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  // المقالات صارت تنبني من الترجمة، فما بقيت const — بتتبدّل مع اللغة.
  static List<_HelpArticle> _articlesFor(L l) => [
        _HelpArticle(
          title: l.helpPhotosTitle,
          steps: [l.helpPhotosStep1, l.helpPhotosStep2, l.helpPhotosStep3],
        ),
        _HelpArticle(
          title: l.helpSsdTitle,
          steps: [l.helpSsdStep1, l.helpSsdStep2, l.helpSsdStep3, l.helpSsdStep4],
        ),
        _HelpArticle(
          title: l.helpBillingTitle,
          steps: [l.helpBillingStep1, l.helpBillingStep2, l.helpBillingStep3],
        ),
      ];

  final Set<int> _expanded = {1};
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// بيفلتر بالعنوان وبالخطوات — الموظف غالباً بيتذكر كلمة من جوّا المقال
  /// مو عنوانه.
  List<_HelpArticle> _filter(List<_HelpArticle> articles) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return articles;
    return [
      for (final a in articles)
        if (a.title.toLowerCase().contains(q) ||
            a.steps.any((s) => s.toLowerCase().contains(q)))
          a,
    ];
  }

  Future<void> _emailSupport() async {
    final l = L.of(context);
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@datarecovery.io',
      queryParameters: {'subject': l.supportRequest},
    );
    final opened = await launchUrl(uri);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.couldNotOpenEmail)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final articles = _filter(_articlesFor(l));
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              children: [
                _CircleBackButton(onPressed: () => Navigator.of(context).pop()),
                Expanded(
                  child: Text(
                    l.helpCenter,
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
              child: Column(
                children: [
                  Text(
                    l.howCanWeHelp,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: l.searchHelpHint,
                      prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF9CA3AF)),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              color: const Color(0xFF9CA3AF),
                              onPressed: () => setState(() {
                                _searchController.clear();
                                _query = '';
                              }),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.popularArticles,
                    style: const TextStyle(
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
                      ..addAll(List.generate(articles.length, (index) => index));
                  }),
                  child: Text(
                    l.viewAll,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF33BEE9),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(articles.length, (index) {
              final article = articles[index];
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
            if (articles.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Text(
                  l.noArticlesMatch,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                ),
              ),
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
                  Text(
                    l.stillNeedHelp,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.supportAvailable247,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFFD1D5DB), height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: l.emailUs,
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
