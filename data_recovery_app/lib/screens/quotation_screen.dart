import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/quotation.dart';
import '../providers/quotations_provider.dart';
import 'invoice_view_screen.dart';

class QuotationScreen extends ConsumerStatefulWidget {
  const QuotationScreen({
    super.key,
    required this.jobId,
    this.jobCustomerName,
    this.jobCustomerPhone,
  });

  final int jobId;
  final String? jobCustomerName;
  final String? jobCustomerPhone;

  @override
  ConsumerState<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends ConsumerState<QuotationScreen> {
  static const _accent = Color(0xFF33BEE9);
  static const _gradientStart = Color(0xFF5CCBED);
  static const _gradientEnd = Color(0xFF2EABD2);
  static const _companyName = '01 Data Recovery';

  final _formKey = GlobalKey<FormState>();
  final _discountController = TextEditingController(text: '0');
  final _taxRateController = TextEditingController(text: '0');
  final _termsController = TextEditingController(text: 'Payment: 100% CASH');

  final List<_LineItem> _items = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _items.add(_LineItem(onChanged: _onItemChanged));
  }

  @override
  void dispose() {
    _discountController.dispose();
    _taxRateController.dispose();
    _termsController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  String get _customerName {
    final value = widget.jobCustomerName?.trim() ?? '';
    return value.isEmpty ? '—' : value;
  }

  String get _customerPhone {
    final value = widget.jobCustomerPhone?.trim() ?? '';
    return value.isEmpty ? '—' : value;
  }

  double get _localTotal {
    return _items.fold<double>(0, (sum, item) => sum + item.lineTotal);
  }

  void _onItemChanged() {
    if (mounted) setState(() {});
  }

  void _addItem() {
    setState(() {
      _items.add(_LineItem(onChanged: _onItemChanged));
    });
  }

  void _removeItem(int index) {
    setState(() {
      final item = _items.removeAt(index);
      item.dispose();
    });
  }

  Future<void> _send() async {
    if (_isSubmitting) return;

    if (_items.isEmpty) {
      _showError('Add at least one item');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final quotation = Quotation(
        id: 0,
        jobId: widget.jobId,
        items: [
          for (final item in _items)
            QuotationItem(
              description: item.description.text.trim(),
              quantity: item.qty,
              unitPrice: item.price,
              total: item.lineTotal,
            ),
        ],
        discount: double.tryParse(_discountController.text.trim()) ?? 0,
        taxRate: double.tryParse(_taxRateController.text.trim()) ?? 0,
        subtotal: 0,
        taxAmount: 0,
        total: 0,
        terms: _termsController.text.trim(),
        createdByName: '',
        createdAt: DateTime.now(),
      );

      final sent = await ref.read(quotationsProvider.notifier).createAndSend(quotation.toCreatePayload());
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => InvoiceViewScreen(quotationId: sent.id),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error.message.isNotEmpty ? error.message : 'Failed to send quotation');
    } catch (_) {
      if (!mounted) return;
      _showError('Failed to send quotation');
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
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }

  String? _positivePrice(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) return 'Enter a price greater than zero';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'QUOTATION',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    _buildQuoteCard(),
                    const SizedBox(height: 20),
                    const _SectionTitle('Financial Offer'),
                    const SizedBox(height: 12),
                    _buildItemsTable(),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _isSubmitting ? null : _addItem,
                        icon: const Icon(Icons.add, color: _accent, size: 20),
                        label: const Text(
                          'Add Item',
                          style: TextStyle(
                            color: _accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _LabeledField(
                            label: 'Discount',
                            child: TextFormField(
                              controller: _discountController,
                              enabled: !_isSubmitting,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                              ],
                              decoration: _inputDecoration(hint: '0.00'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LabeledField(
                            label: 'Tax Rate %',
                            child: TextFormField(
                              controller: _taxRateController,
                              enabled: !_isSubmitting,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                              ],
                              decoration: _inputDecoration(hint: '0'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle('Terms and Conditions'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _termsController,
                      enabled: !_isSubmitting,
                      minLines: 3,
                      maxLines: 6,
                      decoration: _inputDecoration(hint: 'Payment: 100% CASH'),
                    ),
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteCard() {
    return Container(
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7FC),
              shape: BoxShape.circle,
              border: Border.all(color: _accent, width: 1.4),
            ),
            child: const Icon(Icons.business, color: _accent, size: 32),
          ),
          const SizedBox(height: 10),
          const Text(
            'QUOTATION',
            style: TextStyle(
              color: _accent,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _InfoBlock(
                  title: 'To',
                  value: _customerName,
                ),
              ),
              Expanded(
                child: _InfoBlock(
                  title: 'From',
                  value: _companyName,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoBlock(
                  title: 'Person name',
                  value: _customerName,
                ),
              ),
              Expanded(
                child: _InfoBlock(
                  title: 'Mobile',
                  value: _customerPhone,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: _accent,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: const Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text('#', style: _headerStyle),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Description', style: _headerStyle),
                ),
                SizedBox(
                  width: 52,
                  child: Text('Qty', style: _headerStyle),
                ),
                SizedBox(
                  width: 72,
                  child: Text('Unit Price', style: _headerStyle),
                ),
                SizedBox(
                  width: 58,
                  child: Text('Total', style: _headerStyle, textAlign: TextAlign.end),
                ),
                SizedBox(width: 28),
              ],
            ),
          ),
          for (var i = 0; i < _items.length; i++) _buildItemRow(i),
          Container(
            color: _accent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'TOTAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  _localTotal.toStringAsFixed(2),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(int index) {
    final item = _items[index];
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '${index + 1}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: item.description,
              enabled: !_isSubmitting,
              validator: _required,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 12),
              decoration: _compactDecoration(hint: 'Item'),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 52,
            child: TextFormField(
              controller: item.quantity,
              enabled: !_isSubmitting,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: const TextStyle(fontSize: 12),
              decoration: _compactDecoration(hint: '1'),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 72,
            child: TextFormField(
              controller: item.unitPrice,
              enabled: !_isSubmitting,
              validator: _positivePrice,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: const TextStyle(fontSize: 12),
              decoration: _compactDecoration(hint: '0.00'),
            ),
          ),
          SizedBox(
            width: 58,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                item.lineTotal.toStringAsFixed(2),
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 36),
              onPressed: _isSubmitting ? null : () => _removeItem(index),
              icon: const Icon(Icons.close, size: 16, color: Color(0xFF9CA3AF)),
            ),
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
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          const Spacer(),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                colors: [_gradientStart, _gradientEnd],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSubmitting ? null : _send,
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 48,
                  width: 132,
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Send',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
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

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 1.2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }

  InputDecoration _compactDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _accent, width: 1.2),
      ),
      errorStyle: const TextStyle(fontSize: 9),
    );
  }
}

class _LineItem {
  _LineItem({required this.onChanged})
      : description = TextEditingController(),
        quantity = TextEditingController(text: '1'),
        unitPrice = TextEditingController() {
    quantity.addListener(onChanged);
    unitPrice.addListener(onChanged);
  }

  final VoidCallback onChanged;
  final TextEditingController description;
  final TextEditingController quantity;
  final TextEditingController unitPrice;

  double get qty => double.tryParse(quantity.text.trim()) ?? 0;
  double get price => double.tryParse(unitPrice.text.trim()) ?? 0;
  double get lineTotal => qty * price;

  void dispose() {
    quantity.removeListener(onChanged);
    unitPrice.removeListener(onChanged);
    description.dispose();
    quantity.dispose();
    unitPrice.dispose();
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
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF33BEE9),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}
