import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:signature/signature.dart';

import '../core/api_client.dart';
import '../models/invoice_view.dart';
import '../providers/auth_provider.dart';
import 'widgets/app_button.dart';
import 'widgets/soft_surface.dart';

class InvoiceViewScreen extends ConsumerStatefulWidget {
  const InvoiceViewScreen({super.key, required this.quotationId});

  final int quotationId;

  @override
  ConsumerState<InvoiceViewScreen> createState() => _InvoiceViewScreenState();
}

class _InvoiceViewScreenState extends ConsumerState<InvoiceViewScreen> {
  static const _accent = Color(0xFF33BEE9);

  InvoiceView? _invoice;
  String? _error;
  bool _isLoading = true;
  Uint8List? _sellerSignature;
  Uint8List? _receiverSignature;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final invoice = await ref.read(apiClientProvider).getQuotationInvoice(widget.quotationId);
      if (!mounted) return;
      setState(() {
        _invoice = invoice;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.message.isNotEmpty ? error.message : 'Failed to load invoice';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load invoice';
      });
    }
  }

  String _formatDateTime(DateTime value) {
    return DateFormat('yyyy-MM-dd hh:mm:ss a', 'en').format(value.toLocal());
  }

  String _shareText(InvoiceView invoice) {
    return '${invoice.company.name}\n'
        'Invoice: ${invoice.invoiceNumber}\n'
        'Customer: ${invoice.customerName}\n'
        'Phone: ${invoice.customerPhone}\n'
        'Total: ${invoice.total.toStringAsFixed(2)}';
  }

  Future<void> _share() async {
    final invoice = _invoice;
    if (invoice == null) return;
    await SharePlus.instance.share(ShareParams(text: _shareText(invoice)));
  }

  Future<void> _saveAndPrint() async {
    final invoice = _invoice;
    if (invoice == null) return;
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(invoice.company.name, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Invoice: ${invoice.invoiceNumber}'),
              pw.Text('Customer: ${invoice.customerName}'),
              pw.Text('Phone: ${invoice.customerPhone}'),
              pw.SizedBox(height: 16),
              ...[
                for (final item in invoice.items)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(child: pw.Text(item.description)),
                      pw.Text(item.total.toStringAsFixed(2)),
                    ],
                  ),
              ],
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Total: ${invoice.total.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Text('Verification: ${invoice.invoiceNumber}'),
              if (invoice.terms.isNotEmpty) pw.Text(invoice.terms),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  Future<void> _captureSignature({required bool seller}) async {
    final controller = SignatureController(
      penStrokeWidth: 2.4,
      penColor: const Color(0xFF111827),
    );
    final saved = await showDialog<Uint8List>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(seller ? 'Seller Signature' : 'Receiver Signature'),
          content: SizedBox(
            width: 320,
            height: 180,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Signature(controller: controller, backgroundColor: Colors.white),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: controller.clear, child: const Text('Clear')),
            TextButton(
              onPressed: () async {
                if (controller.isEmpty) {
                  Navigator.pop(context);
                  return;
                }
                final bytes = await controller.toPngBytes();
                if (context.mounted) Navigator.pop(context, bytes);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (saved == null || !mounted) return;
    setState(() {
      if (seller) {
        _sellerSignature = saved;
      } else {
        _receiverSignature = saved;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _invoice == null) {
      return Column(
        children: [
          _buildAppHeader(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error ?? 'Failed to load invoice',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 12),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final invoice = _invoice!;
    return Column(
      children: [
        _buildAppHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              SoftSurface(
                radius: 24,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  child: Column(
                    children: [
                      _buildDocHeader(invoice),
                      const SizedBox(height: 16),
                      _buildInfoGrid(invoice),
                      const SizedBox(height: 16),
                      _buildItemsTable(invoice),
                      const SizedBox(height: 14),
                      _buildPaidBoxes(invoice),
                      const SizedBox(height: 16),
                      _buildSummary(invoice),
                      const SizedBox(height: 20),
                      _buildSignatures(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildAppHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          const _CircleBackButton(),
          const Expanded(
            child: Text(
              'Electronic Invoice',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildDocHeader(InvoiceView invoice) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7FC),
                  shape: BoxShape.circle,
                  border: Border.all(color: _accent),
                ),
                child: const Center(
                  child: Text(
                    '01',
                    style: TextStyle(color: _accent, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                invoice.company.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Electronic Invoice',
            style: TextStyle(
              color: _accent,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'invoice ID',
                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
              Text(
                invoice.invoiceNumber,
                style: const TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGrid(InvoiceView invoice) {
    final payment = invoice.terms.toLowerCase().contains('cash') ? 'Cash' : '—';
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _MetaCell(label: 'Payment Method', value: payment)),
            Expanded(child: _MetaCell(label: 'Invoice Type', value: 'Tax Invoice')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _MetaCell(label: 'Invoice Time', value: _formatDateTime(invoice.createdAt)),
            ),
            Expanded(child: _MetaCell(label: 'Customer / Company', value: invoice.customerName)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _MetaCell(label: 'Main Employee', value: '—')),
            Expanded(
              child: _MetaCell(
                label: 'National Address',
                value: invoice.company.address.isEmpty ? '—' : invoice.company.address,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _MetaCell(
                label: 'Branch Name',
                value: invoice.company.name.isEmpty ? '—' : invoice.company.name,
              ),
            ),
            Expanded(child: _MetaCell(label: 'Phone', value: invoice.customerPhone)),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsTable(InvoiceView invoice) {
    final items = invoice.items;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          Container(
            color: _accent,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: const Row(
              children: [
                _HeadCell('No.', width: 28),
                _HeadCell('Item', width: 48),
                _HeadCell('Description', width: 140),
                _HeadCell('Qty', width: 36),
                _HeadCell('Price', width: 64),
                _HeadCell('Disc.', width: 48),
                _HeadCell('Tax', width: 52),
                _HeadCell('Total', width: 64, alignEnd: true),
              ],
            ),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No items', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
            )
          else
            for (var i = 0; i < items.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: [
                    _BodyCell('${i + 1}', width: 28),
                    _BodyCell('${i + 1}', width: 48),
                    SizedBox(
                      width: 140,
                      child: Text(
                        items[i].description,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF111827)),
                      ),
                    ),
                    _BodyCell(items[i].quantity.toStringAsFixed(0), width: 36),
                    _BodyCell(items[i].unitPrice.toStringAsFixed(2), width: 64),
                    const _BodyCell('0', width: 48),
                    _BodyCell(
                      (items[i].quantity * items[i].unitPrice * invoice.taxRate / 100)
                          .toStringAsFixed(2),
                      width: 52,
                    ),
                    _BodyCell(items[i].total.toStringAsFixed(2), width: 64, alignEnd: true, bold: true),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildPaidBoxes(InvoiceView invoice) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _PaidBox(label: 'Paid on (1) Main Fund', value: invoice.total.toStringAsFixed(2)),
            ),
            const SizedBox(width: 8),
            const Expanded(child: _PaidBox(label: 'Paid on (2)', value: '0')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(child: _PaidBox(label: 'Paid on (3)', value: '0')),
            const SizedBox(width: 8),
            Expanded(
              child: _PaidBox(
                label: 'Notes',
                value: invoice.terms.trim().isEmpty ? '' : invoice.terms.trim(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummary(InvoiceView invoice) {
    final exclTax = invoice.subtotal - invoice.discount;
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 220,
        child: Column(
          children: [
            _SummaryRow(label: 'Subtotal', value: invoice.subtotal.toStringAsFixed(2)),
            const SizedBox(height: 6),
            _SummaryRow(label: 'Discount', value: invoice.discount.toStringAsFixed(2)),
            const SizedBox(height: 6),
            _SummaryRow(label: 'Total Excl. Tax', value: exclTax.toStringAsFixed(2)),
            const SizedBox(height: 6),
            _SummaryRow(label: 'Tax', value: invoice.taxAmount.toStringAsFixed(2)),
            const SizedBox(height: 6),
            _SummaryRow(
              label: 'Total With Tax',
              value: invoice.total.toStringAsFixed(2),
              emphasize: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatures() {
    final invoice = _invoice;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _SignatureBlock(
            label: 'Seller Signature',
            imageBytes: _sellerSignature,
            onTap: () => _captureSignature(seller: true),
          ),
        ),
        Expanded(
          child: _SignatureBlock(
            label: 'Receiver Signature',
            imageBytes: _receiverSignature,
            onTap: () => _captureSignature(seller: false),
          ),
        ),
        SizedBox(
          width: 72,
          child: Column(
            children: [
              if (invoice != null)
                QrImageView(
                  data: invoice.invoiceNumber,
                  size: 64,
                  backgroundColor: Colors.white,
                )
              else
                const Icon(Icons.qr_code_2, size: 44, color: Color(0xFF33BEE9)),
              const SizedBox(height: 4),
              Text(
                invoice?.invoiceNumber ?? 'Verification Code',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 8, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: _share,
            child: const Text(
              'Share',
              style: TextStyle(
                color: Color(0xFF33BEE9),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const Spacer(),
          AppButton(
            label: 'Save & Print',
            width: 160,
            onPressed: _saveAndPrint,
          ),
        ],
      ),
    );
  }

}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F4F6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).pop(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.chevron_left, color: Color(0xFF111827), size: 26),
        ),
      ),
    );
  }
}

class _MetaCell extends StatelessWidget {
  const _MetaCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '—' : value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}

class _HeadCell extends StatelessWidget {
  const _HeadCell(this.label, {required this.width, this.alignEnd = false});

  final String label;
  final double width;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell(this.text, {required this.width, this.alignEnd = false, this.bold = false});

  final String text;
  final double width;
  final bool alignEnd;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        style: TextStyle(
          fontSize: 11,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: const Color(0xFF111827),
        ),
      ),
    );
  }
}

class _PaidBox extends StatelessWidget {
  const _PaidBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
        ],
      ),
    );
  }
}

class _SignatureBlock extends StatelessWidget {
  const _SignatureBlock({
    required this.label,
    required this.onTap,
    this.imageBytes,
  });

  final String label;
  final VoidCallback onTap;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: imageBytes != null
                ? Image.memory(imageBytes!, fit: BoxFit.contain)
                : const Text(
                    'Tap to sign',
                    style: TextStyle(color: Color(0xFF33BEE9), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: emphasize ? 16 : 13,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
              color: emphasize ? const Color(0xFF33BEE9) : const Color(0xFF6B7280),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasize ? 16 : 13,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            color: emphasize ? const Color(0xFF33BEE9) : const Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}
