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
            _DocumentTile(
              icon: Icons.label_outline,
              title: l.printSticker,
              subtitle: l.printStickerHint,
              onPrint: () => _print(context, _sticker),
              onShare: () => _share(context, _sticker, 'sticker'),
            ),
            const SizedBox(height: 10),
            _DocumentTile(
              icon: Icons.receipt_long_outlined,
              title: l.printReceipt,
              subtitle: l.printReceiptHint,
              onPrint: () => _print(context, _receipt),
              onShare: () => _share(context, _receipt, 'receipt'),
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _sticker() =>
      PrintTemplates.sticker(job: job, companyName: AppConstants.companyName);

  Future<Uint8List> _receipt() => PrintTemplates.receivingReceipt(
        job: job,
        companyName: AppConstants.companyName,
      );

  /// بيشارك المستند كملف PDF — الموظف بيقدر يبعته واتساب أو يحفظه.
  Future<void> _share(
    BuildContext context,
    Future<Uint8List> Function() build,
    String kind,
  ) async {
    final l = L.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Printing.sharePdf(
        bytes: await build(),
        filename: '$kind-${job.invoiceNumber}.pdf',
      );
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.printFailed)));
    }
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

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPrint,
    required this.onShare,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPrint;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(
            children: [
          Row(
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
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Action(
                  icon: Icons.print_outlined,
                  label: l.printPdf,
                  onTap: onPrint,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Action(
                  icon: Icons.ios_share,
                  label: l.sharePdf,
                  onTap: onShare,
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

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: const Color(0xFF33BEE9)),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
