import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/api_client.dart';
import '../l10n/app_localizations.dart';
import '../models/quotation.dart';
import '../providers/quotations_provider.dart';
import 'invoice_view_screen.dart';
import 'widgets/app_button.dart';
import 'widgets/soft_surface.dart';

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
  static const _companyName = '01 Data Recovery';

  final _formKey = GlobalKey<FormState>();
  final _discountController = TextEditingController(text: '0');
  final _taxRateController = TextEditingController(text: '0');
  final _termsController = TextEditingController();

  final List<_LineItem> _items = [];
  bool _isSubmitting = false;
  bool _seededTerms = false;

  @override
  void initState() {
    super.initState();
    _items.add(_LineItem(onChanged: _onItemChanged));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // الشروط الافتراضية بدها ترجمة، والترجمة ما بتكون جاهزة بـ initState.
    // منزرعها مرة وحدة بس، حتى ما ندعس على شي كتبه المستخدم.
    if (!_seededTerms) {
      _seededTerms = true;
      _termsController.text = L.of(context).paymentCash;
    }
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
      _showError(L.of(context).addAtLeastOneItem);
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
      _showError(error.message.isNotEmpty ? error.message : L.of(context).failedToSendQuotation);
    } catch (_) {
      if (!mounted) return;
      _showError(L.of(context).failedToSendQuotation);
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
    if (value == null || value.trim().isEmpty) return L.of(context).fieldRequired;
    return null;
  }

  String? _positivePrice(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) return L.of(context).enterPriceGreaterThanZero;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    _CircleBackButton(
                      onPressed: _isSubmitting ? () {} : () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        l.quotation,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    SoftSurface(
                      radius: 24,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildQuoteHeader(),
                            const SizedBox(height: 20),
                            _buildPartyGrid(),
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                const Icon(Icons.sell_outlined, color: _accent, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  l.financialOffer,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildItemsTable(),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _isSubmitting ? null : _addItem,
                                icon: const Icon(Icons.add, color: _accent, size: 20),
                                label: Text(
                                  l.addItem,
                                  style: const TextStyle(
                                    color: _accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _LabeledField(
                                    label: l.discount,
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
                                    label: l.taxRate,
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
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Color(0xFFD9F3FB),
                                  child: Icon(Icons.edit_note, size: 16, color: _accent),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l.termsAndConditions,
                                  style: const TextStyle(
                                    color: _accent,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _termsController,
                              enabled: !_isSubmitting,
                              minLines: 2,
                              maxLines: 5,
                              decoration: _inputDecoration(hint: l.paymentCash),
                            ),
                            const SizedBox(height: 10),
                            _NumberedTerm(
                              number: '2',
                              text: l.pricesInRiyals,
                            ),
                            const SizedBox(height: 6),
                            _NumberedTerm(
                              number: '3',
                              text: l.pricesForQuantity,
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildQuoteHeader() {
    final l = L.of(context);
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F7FC),
            shape: BoxShape.circle,
            border: Border.all(color: _accent, width: 1.4),
          ),
          child: const Center(
            child: Text(
              '01',
              style: TextStyle(
                color: _accent,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          _companyName,
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l.quotation,
          style: const TextStyle(
            color: _accent,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildPartyGrid() {
    final l = L.of(context);
    final dateText = DateFormat(
      'd MMM yyyy',
      Localizations.localeOf(context).languageCode,
    ).format(DateTime.now());
    // الخط الفاصل صار عمود ثالث بنفس الصف بدل ما يكون طبقة فوقه. هيك
    // بينمركز بين العمودين بالضبط، وعرضه بيضمن مسافة على الجهتين فما
    // بيلزق بالنص. و IntrinsicHeight بتخلّي طوله يطابق المحتوى تماماً.
    return IntrinsicHeight(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MetaLine(label: l.toColon, value: _customerName),
                    const SizedBox(height: 10),
                    _MetaLine(label: l.personName, value: _customerName),
                    const SizedBox(height: 10),
                    _MetaLine(label: l.tel, value: '—'),
                  ],
                ),
              ),
              SizedBox(
                width: 48,
                child: CustomPaint(painter: _DashedLinePainter()),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MetaLine(label: l.fromColon, value: _companyName),
                    const SizedBox(height: 10),
                    _MetaLine(label: l.mobile, value: _customerPhone),
                    const SizedBox(height: 10),
                    _MetaLine(label: l.labelDate, value: dateText),
                  ],
                ),
              ),
            ],
          ),
          const CircleAvatar(
            radius: 16,
            backgroundColor: _accent,
            child: Icon(Icons.description_outlined, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
    final l = L.of(context);
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
            child: Row(
              children: [
                const SizedBox(
                  width: 22,
                  child: Text('#', style: _headerStyle),
                ),
                Expanded(
                  flex: 3,
                  child: Text(l.description, style: _headerStyle),
                ),
                SizedBox(
                  width: 52,
                  child: Text(l.qty, style: _headerStyle),
                ),
                SizedBox(
                  width: 72,
                  child: Text(l.unitPrice, style: _headerStyle),
                ),
                SizedBox(
                  width: 58,
                  child: Text(l.total, style: _headerStyle, textAlign: TextAlign.end),
                ),
                const SizedBox(width: 28),
              ],
            ),
          ),
          for (var i = 0; i < _items.length; i++) _buildItemRow(i),
          Container(
            color: _accent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.total,
                    style: const TextStyle(
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
    final l = L.of(context);
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
              decoration: _compactDecoration(hint: l.item),
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
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: Text(
              l.cancel,
              style: const TextStyle(
                color: Color(0xFF33BEE9),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
          AppButton(
            label: l.send,
            width: 140,
            isLoading: _isSubmitting,
            onPressed: _send,
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

class _NumberedTerm extends StatelessWidget {
  const _NumberedTerm({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: const Color(0xFF33BEE9),
          child: Text(
            number,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF111827), height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F4F6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.chevron_left, color: Color(0xFF111827), size: 26),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF33BEE9), fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
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

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 1.2;
    const dash = 4.0;
    const gap = 3.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(size.width / 2, y), Offset(size.width / 2, y + dash), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

