class Product {
  final String id;
  final String name;
  final String? urduName;
  final String category;
  final String unit;
  final double buyingPrice;
  final double sellingPrice;
  final double currentStock;
  final double lowStockThreshold;
  final String? supplierId;
  final String updatedAt;

  Product({
    required this.id,
    required this.name,
    this.urduName,
    required this.category,
    required this.unit,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.currentStock,
    required this.lowStockThreshold,
    this.supplierId,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      urduName: json['urdu_name'],
      category: json['category'] ?? 'General',
      unit: json['unit'] ?? 'pc',
      buyingPrice: (json['buying_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? 0.0,
      currentStock: (json['current_stock'] as num?)?.toDouble() ?? 0.0,
      lowStockThreshold: (json['low_stock_threshold'] as num?)?.toDouble() ?? 5.0,
      supplierId: json['supplier_id'],
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'urdu_name': urduName,
      'category': category,
      'unit': unit,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'current_stock': currentStock,
      'low_stock_threshold': lowStockThreshold,
      'supplier_id': supplierId,
      'updated_at': updatedAt,
    };
  }
}
