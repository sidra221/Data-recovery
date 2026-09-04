double _asDouble(dynamic value) {
  if (value == null || value == '') return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

class InvoiceViewItem {
  InvoiceViewItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  final String description;
  final double quantity;
  final double unitPrice;
  final double total;

  factory InvoiceViewItem.fromJson(Map<String, dynamic> json) {
    return InvoiceViewItem(
      description: json['description'] as String? ?? '',
      quantity: _asDouble(json['quantity']),
      unitPrice: _asDouble(json['unit_price']),
      total: _asDouble(json['total']),
    );
  }
}

class InvoiceView {
  InvoiceView({
    required this.company,
    required this.invoiceNumber,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.deviceType,
    required this.deviceModel,
    required this.deviceSerialNumber,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
    required this.terms,
    required this.createdAt,
  });

  final String company;
  final String invoiceNumber;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String deviceType;
  final String deviceModel;
  final String deviceSerialNumber;
  final List<InvoiceViewItem> items;
  final double subtotal;
  final double discount;
  final double taxRate;
  final double taxAmount;
  final double total;
  final String terms;
  final DateTime createdAt;

  factory InvoiceView.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>? ?? const {};
    final device = json['device'] as Map<String, dynamic>? ?? const {};
    return InvoiceView(
      company: json['company'] as String? ?? '',
      invoiceNumber: json['invoice_number'] as String? ?? '',
      customerName: customer['name'] as String? ?? '',
      customerPhone: customer['phone'] as String? ?? '',
      customerEmail: customer['email'] as String? ?? '',
      deviceType: device['type'] as String? ?? '',
      deviceModel: device['model'] as String? ?? '',
      deviceSerialNumber: device['serial_number'] as String? ?? '',
      items: [
        for (final item in json['items'] as List<dynamic>? ?? const [])
          InvoiceViewItem.fromJson(item as Map<String, dynamic>),
      ],
      subtotal: _asDouble(json['subtotal']),
      discount: _asDouble(json['discount']),
      taxRate: _asDouble(json['tax_rate']),
      taxAmount: _asDouble(json['tax_amount']),
      total: _asDouble(json['total']),
      terms: json['terms'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
