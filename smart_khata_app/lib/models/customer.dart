class Customer {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String type; // regular, farmer, business
  final double balanceDue;
  final String updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.type,
    required this.balanceDue,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      type: json['type'] ?? 'regular',
      balanceDue: (json['balance_due'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'type': type,
      'balance_due': balanceDue,
      'updated_at': updatedAt,
    };
  }
}
