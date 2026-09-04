DateTime? _parseDateTime(dynamic value) {
  if (value == null || value == '') return null;
  return DateTime.tryParse(value as String);
}

double _asDouble(dynamic value) {
  if (value == null || value == '') return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

class QuotationItem {
  QuotationItem({
    this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  final int? id;
  final String description;
  final double quantity;
  final double unitPrice;
  final double total;

  factory QuotationItem.fromJson(Map<String, dynamic> json) {
    return QuotationItem(
      id: json['id'] as int?,
      description: json['description'] as String? ?? '',
      quantity: _asDouble(json['quantity']),
      unitPrice: _asDouble(json['unit_price']),
      total: _asDouble(json['total']),
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'description': description,
      'quantity': quantity.toStringAsFixed(2),
      'unit_price': unitPrice.toStringAsFixed(2),
    };
  }
}

class Quotation {
  Quotation({
    required this.id,
    required this.jobId,
    required this.items,
    required this.discount,
    required this.taxRate,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    required this.terms,
    required this.createdByName,
    required this.createdAt,
    this.sentAt,
  });

  final int id;
  final int jobId;
  final List<QuotationItem> items;
  final double discount;
  final double taxRate;
  final double subtotal;
  final double taxAmount;
  final double total;
  final String terms;
  final String createdByName;
  final DateTime createdAt;
  final DateTime? sentAt;

  factory Quotation.fromJson(Map<String, dynamic> json) {
    return Quotation(
      id: json['id'] as int,
      jobId: json['job'] as int,
      items: [
        for (final item in json['items'] as List<dynamic>? ?? const [])
          QuotationItem.fromJson(item as Map<String, dynamic>),
      ],
      discount: _asDouble(json['discount']),
      taxRate: _asDouble(json['tax_rate']),
      subtotal: _asDouble(json['subtotal']),
      taxAmount: _asDouble(json['tax_amount']),
      total: _asDouble(json['total']),
      terms: json['terms'] as String? ?? '',
      createdByName: json['created_by_name'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      sentAt: _parseDateTime(json['sent_at']),
    );
  }

  Map<String, dynamic> toCreatePayload() {
    return {
      'job': jobId,
      'items': [for (final item in items) item.toPayload()],
      'discount': discount.toStringAsFixed(2),
      'tax_rate': taxRate.toStringAsFixed(2),
      'terms': terms,
    };
  }
}

class PaginatedQuotations {
  PaginatedQuotations({required this.count, required this.results});

  final int count;
  final List<Quotation> results;

  factory PaginatedQuotations.fromJson(Map<String, dynamic> json) {
    return PaginatedQuotations(
      count: json['count'] as int? ?? 0,
      results: [
        for (final item in json['results'] as List<dynamic>? ?? const [])
          Quotation.fromJson(item as Map<String, dynamic>),
      ],
    );
  }
}
