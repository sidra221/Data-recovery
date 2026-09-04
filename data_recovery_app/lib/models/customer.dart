DateTime? _parseDateTime(dynamic value) {
  if (value == null || value == '') return null;
  return DateTime.tryParse(value as String);
}

class Customer {
  Customer({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.createdAt,
    required this.totalRepairs,
    required this.totalSpent,
    required this.firstVisit,
    required this.lastVisit,
  });

  final int id;
  final String fullName;
  final String phone;
  final String email;
  final DateTime createdAt;
  final int totalRepairs;
  final String totalSpent;
  final DateTime? firstVisit;
  final DateTime? lastVisit;

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      totalRepairs: json['total_repairs'] as int? ?? 0,
      totalSpent: json['total_spent']?.toString() ?? '0.00',
      firstVisit: _parseDateTime(json['first_visit']),
      lastVisit: _parseDateTime(json['last_visit']),
    );
  }
}

class PaginatedCustomers {
  PaginatedCustomers({required this.count, required this.results});

  final int count;
  final List<Customer> results;

  factory PaginatedCustomers.fromJson(Map<String, dynamic> json) {
    return PaginatedCustomers(
      count: json['count'] as int? ?? 0,
      results: [
        for (final item in json['results'] as List<dynamic>? ?? const [])
          Customer.fromJson(item as Map<String, dynamic>),
      ],
    );
  }
}
