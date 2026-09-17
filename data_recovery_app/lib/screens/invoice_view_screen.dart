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
import '../l10n/app_localizations.dart';
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
        _error = error.message.isNotEmpty
            ? error.message
            : L.of(context).failedToLoadInvoice;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = L.of(context).failedToLoadInvoice;
      });
    }
  }

  String _formatDateTime(DateTime value) {
    return DateFormat(
      'yyyy-MM-dd hh:mm:ss a',
      Localizations.localeOf(context).languageCode,
    ).format(value.toLocal());
  }

  String _shareText(InvoiceView invoice) {
    final l = L.of(context);
    return '${invoice.company.name}\n'
        '${l.labelInvoice}: ${invoice.invoiceNumber}\n'
        '${l.customer}: ${invoice.customerName}\n'
        '${l.labelPhone}: ${invoice.customerPhone}\n'
        '${l.colTotal}: ${invoice.total.toStringAsFixed(2)}';
  }

  Future<void> _share() async {
    final invoice = _invoice;
    if (invoice == null) return;
    await SharePlus.instance.share(ShareParams(text: _shareText(invoice)));
  }

  // ملاحظة: نصوص الـ PDF بتضل إنكليزي. خط الـ pdf الافتراضي (Helvetica) ما
  // فيه محارف عربية، فأي نص عربي بيطلع مربّعات فاضية. لتعريبه لازم ننزّل خط
  // عربي (مثلاً Noto Naskh Arabic) ونضيفه كـ asset ونعرّفه بـ pw.ThemeData.
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
              pw.Spacer(),
              _signatureRow(),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  /// خانتَي التوقيع بأسفل الـ PDF. لو التوقيع مو مرسوم بعد، بينطبع سطر
  /// فاضي حتى ينوقّع باليد على الورقة.
  pw.Widget _signatureRow() {
    pw.Widget box(String label, Uint8List? bytes) {
      return pw.Expanded(
        child: pw.Column(
          children: [
            pw.SizedBox(
              height: 50,
              child: bytes == null
                  ? pw.SizedBox()
                  : pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
            ),
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 4),
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(width: 0.7)),
              ),
            ),
            pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      );
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        box('Seller Signature', _sellerSignature),
        pw.SizedBox(width: 40),
        box('Receiver Signature', _receiverSignature),
      ],
    );
  }

  Future<void> _captureSignature({required bool seller}) async {
    final controller = SignatureController(
      penStrokeWidth: 2.4,
      penColor: const Color(0xFF111827),
    );
    final l = L.of(context);
    final saved = await showDialog<Uint8List>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(seller ? l.sellerSignature : l.receiverSignature),
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
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
            TextButton(onPressed: controller.clear, child: Text(l.clear)),
            TextButton(
              onPressed: () async {
                if (controller.isEmpty) {
                  Navigator.pop(context);
                  return;
                }
                final bytes = await controller.toPngBytes();
                if (context.mounted) Navigator.pop(context, bytes);
              },
              child: Text(l.save),
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
                      _error ?? L.of(context).failedToLoadInvoice,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 12),
                    TextButton(onPressed: _load, child: Text(L.of(context).retry)),
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
    final l = L.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          const _CircleBackButton(),
          Expanded(
            child: Text(
              l.electronicInvoice,
              textAlign: TextAlign.center,
              style: const TextStyle(
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
    final l = L.of(context);
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
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            l.electronicInvoice,
            style: const TextStyle(
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
              Text(
                l.invoiceIdLabel,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
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
    final l = L.of(context);
    final payment = invoice.terms.toLowerCase().contains('cash') ? l.cash : '—';
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _MetaCell(label: l.paymentMethod, value: payment)),
            Expanded(child: _MetaCell(label: l.invoiceType, value: l.taxInvoice)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _MetaCell(label: l.invoiceTime, value: _formatDateTime(invoice.createdAt)),
            ),
            Expanded(child: _MetaCell(label: l.customerOrCompany, value: invoice.customerName)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _MetaCell(label: l.mainEmployee, value: '—')),
            Expanded(
              child: _MetaCell(
                label: l.nationalAddress,
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
                label: l.branchName,
                value: invoice.company.name.isEmpty ? '—' : invoice.company.name,
              ),
            ),
            Expanded(child: _MetaCell(label: l.labelPhone, value: invoice.customerPhone)),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsTable(InvoiceView invoice) {
    final l = L.of(context);
    final items = invoice.items;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          Container(
            color: _accent,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                _HeadCell(l.colNo, width: 28),
                _HeadCell(l.colItem, width: 48),
                _HeadCell(l.colDescription, width: 140),
                _HeadCell(l.colQty, width: 36),
                _HeadCell(l.colPrice, width: 64),
                _HeadCell(l.colDisc, width: 48),
                _HeadCell(l.colTax, width: 52),
                _HeadCell(l.colTotal, width: 64, alignEnd: true),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(l.noItems, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
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
    final l = L.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _PaidBox(label: l.paidOnMainFund, value: invoice.total.toStringAsFixed(2)),
            ),
            const SizedBox(width: 8),
            Expanded(child: _PaidBox(label: l.paidOnTwo, value: '0')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _PaidBox(label: l.paidOnThree, value: '0')),
            const SizedBox(width: 8),
            Expanded(
              child: _PaidBox(
                label: l.labelNotes,
                value: invoice.terms.trim().isEmpty ? '' : invoice.terms.trim(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummary(InvoiceView invoice) {
    final l = L.of(context);
    final exclTax = invoice.subtotal - invoice.discount;
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 220,
        child: Column(
          children: [
            _SummaryRow(label: l.subtotal, value: invoice.subtotal.toStringAsFixed(2)),
            const SizedBox(height: 6),
            _SummaryRow(label: l.discount, value: invoice.discount.toStringAsFixed(2)),
            const SizedBox(height: 6),
            _SummaryRow(label: l.totalExclTax, value: exclTax.toStringAsFixed(2)),
            const SizedBox(height: 6),
            _SummaryRow(label: l.colTax, value: invoice.taxAmount.toStringAsFixed(2)),
            const SizedBox(height: 6),
            _SummaryRow(
              label: l.totalWithTax,
              value: invoice.total.toStringAsFixed(2),
              emphasize: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatures() {
    final l = L.of(context);
    final invoice = _invoice;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _SignatureBlock(
            label: l.sellerSignature,
            imageBytes: _sellerSignature,
            onTap: () => _captureSignature(seller: true),
          ),
        ),
        Expanded(
          child: _SignatureBlock(
            label: l.receiverSignature,
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
                invoice?.invoiceNumber ?? l.verificationCode,
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
    final l = L.of(context);
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
            child: Text(
              l.share,
              style: const TextStyle(
                color: Color(0xFF33BEE9),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const Spacer(),
          AppButton(
            label: l.saveAndPrint,
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
                : Text(
                    L.of(context).tapToSign,
                    style: const TextStyle(color: Color(0xFF33BEE9), fontSize: 13, fontWeight: FontWeight.w600),
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
