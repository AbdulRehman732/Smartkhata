class Supplier {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String notes;
  final double totalPurchased;
  final double totalPaid;
  final double balanceOwed;
  final String updatedAt;

  Supplier({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.notes,
    required this.totalPurchased,
    required this.totalPaid,
    required this.balanceOwed,
    required this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      notes: json['notes'] ?? '',
      totalPurchased: (json['total_purchased'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
      balanceOwed: (json['balance_owed'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
      'total_purchased': totalPurchased,
      'total_paid': totalPaid,
      'balance_owed': balanceOwed,
      'updated_at': updatedAt,
    };
  }
}
