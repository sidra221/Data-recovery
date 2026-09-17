import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../core/constants.dart';
import '../../core/print_templates.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job.dart';

/// مطبوعات الاستلام: الستيكر للقطعة، وسند الاستلام للعميل.
///
/// بياخد [Job] مو رقم عملية عن قصد — العمليات المسجّلة والسيرفر مطفّى ما
/// إلها id على السيرفر، ولازم تنطبع فوراً مع هيك.
class PrintDocumentsSheet extends StatelessWidget {
  const PrintDocumentsSheet._({required this.job});

  final Job job;

  static Future<void> show(BuildContext context, {required Job job}) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PrintDocumentsSheet._(job: job),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l.printDocuments,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              job.invoiceNumber,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 18),
            _PrintTile(
              icon: Icons.label_outline,
              title: l.printSticker,
              subtitle: l.printStickerHint,
              onTap: () => _print(
                context,
                () => PrintTemplates.sticker(
                  job: job,
                  companyName: AppConstants.companyName,
                  companyNameArabic: AppConstants.companyNameArabic,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _PrintTile(
              icon: Icons.receipt_long_outlined,
              title: l.printReceipt,
              subtitle: l.printReceiptHint,
              onTap: () => _print(
                context,
                () => PrintTemplates.receivingReceipt(
                  job: job,
                  companyName: AppConstants.companyName,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _print(BuildContext context, Future<Uint8List> Function() build) async {
    final l = L.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Printing.layoutPdf(onLayout: (_) => build());
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.printFailed)));
    }
  }
}

class _PrintTile extends StatelessWidget {
  const _PrintTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7FC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF33BEE9)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}
