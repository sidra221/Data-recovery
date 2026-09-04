import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/api_client.dart';
import '../models/invoice_view.dart';
import '../providers/auth_provider.dart';

class InvoiceViewScreen extends ConsumerStatefulWidget {
  const InvoiceViewScreen({super.key, required this.quotationId});

  final int quotationId;

  @override
  ConsumerState<InvoiceViewScreen> createState() => _InvoiceViewScreenState();
}

class _InvoiceViewScreenState extends ConsumerState<InvoiceViewScreen> {
  static const _accent = Color(0xFF33BEE9);
  static const _gradientStart = Color(0xFF5CCBED);
  static const _gradientEnd = Color(0xFF2EABD2);

  InvoiceView? _invoice;
  String? _error;
  bool _isLoading = true;

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
        _error = error.message.isNotEmpty ? error.message : 'تعذّر جلب الفاتورة';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'تعذّر جلب الفاتورة';
      });
    }
  }

  String _formatDate(DateTime value) {
    return DateFormat('d MMM yyyy').format(value.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Electronic Invoice',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _invoice == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error ?? 'تعذّر جلب الفاتورة',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
    }

    final invoice = _invoice!;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              _buildHeaderCard(invoice),
              const SizedBox(height: 16),
              _buildItemsTable(invoice.items),
              const SizedBox(height: 12),
              _buildSummary(invoice),
              if (invoice.terms.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildTerms(invoice.terms),
              ],
            ],
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildHeaderCard(InvoiceView invoice) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            invoice.company,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _accent,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Invoice No: ${invoice.invoiceNumber}',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: _SectionLabel('Customer'),
          ),
          const SizedBox(height: 8),
          _InfoRow(label: 'Name', value: invoice.customerName),
          _InfoRow(label: 'Phone', value: invoice.customerPhone),
          if (invoice.customerEmail.trim().isNotEmpty)
            _InfoRow(label: 'Email', value: invoice.customerEmail),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: _SectionLabel('Device'),
          ),
          const SizedBox(height: 8),
          _InfoRow(label: 'Type', value: invoice.deviceType),
          if (invoice.deviceModel.trim().isNotEmpty)
            _InfoRow(label: 'Model', value: invoice.deviceModel),
          if (invoice.deviceSerialNumber.trim().isNotEmpty)
            _InfoRow(label: 'Serial', value: invoice.deviceSerialNumber),
          const SizedBox(height: 16),
          _InfoRow(label: 'Issue date', value: _formatDate(invoice.createdAt)),
        ],
      ),
    );
  }

  Widget _buildItemsTable(List<InvoiceViewItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: _accent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('Description', style: _headerStyle),
                ),
                SizedBox(
                  width: 44,
                  child: Text('Qty', style: _headerStyle),
                ),
                SizedBox(
                  width: 80,
                  child: Text('Unit Price', style: _headerStyle),
                ),
                SizedBox(
                  width: 64,
                  child: Text('Total', style: _headerStyle, textAlign: TextAlign.end),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No items',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              ),
            )
          else
            for (var i = 0; i < items.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: i == items.length - 1
                          ? Colors.transparent
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        items[i].description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text(
                        items[i].quantity.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        items[i].unitPrice.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      child: Text(
                        items[i].total.toStringAsFixed(2),
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildSummary(InvoiceView invoice) {
    final taxLabel = 'Tax (${invoice.taxRate.toStringAsFixed(invoice.taxRate == invoice.taxRate.roundToDouble() ? 0 : 2)}%)';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Subtotal', value: invoice.subtotal.toStringAsFixed(2)),
          const SizedBox(height: 8),
          _SummaryRow(label: 'Discount', value: invoice.discount.toStringAsFixed(2)),
          const SizedBox(height: 8),
          _SummaryRow(label: taxLabel, value: invoice.taxAmount.toStringAsFixed(2)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFE5E7EB)),
          ),
          _SummaryRow(
            label: 'Total',
            value: invoice.total.toStringAsFixed(2),
            emphasize: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTerms(String terms) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Terms and Conditions'),
          const SizedBox(height: 8),
          Text(
            terms,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.4),
          ),
        ],
      ),
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
          // TODO: no PDF/share implementation yet
          TextButton(
            onPressed: null,
            child: Text(
              'Share',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          const Spacer(),
          // TODO: no PDF generation in backend yet
          Opacity(
            opacity: 0.45,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    colors: [_gradientStart, _gradientEnd],
                  ),
                ),
                child: const SizedBox(
                  height: 48,
                  width: 148,
                  child: Center(
                    child: Text(
                      'Save & Print',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    color: Colors.white,
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF111827),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
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
