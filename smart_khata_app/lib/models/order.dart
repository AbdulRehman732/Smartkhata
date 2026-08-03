class OrderLineItem {
  final String productId;
  final String productName;
  final double unitPrice;
  final double quantity;
  final double lineTotal;

  OrderLineItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  factory OrderLineItem.fromJson(Map<String, dynamic> json) {
    return OrderLineItem(
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? 'Product',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (json['line_total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'line_total': lineTotal,
    };
  }
}

class OrderModel {
  final String id;
  final List<OrderLineItem> lineItems;
  final double subtotal;
  final double discount;
  final double totalAmount;
  final String paymentMethod; // cash, credit, partial
  final double amountPaidNow;
  final double amountAddedToKhata;
  final String? customerId;
  final String? customerName;
  final String createdAt;
  final String? clientId;

  OrderModel({
    required this.id,
    required this.lineItems,
    required this.subtotal,
    required this.discount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.amountPaidNow,
    required this.amountAddedToKhata,
    this.customerId,
    this.customerName,
    required this.createdAt,
    this.clientId,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawLines = json['line_items'] as List? ?? [];
    List<OrderLineItem> items = rawLines.map((i) => OrderLineItem.fromJson(i)).toList();

    return OrderModel(
      id: json['id'] ?? json['_id'] ?? '',
      lineItems: items,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] ?? 'cash',
      amountPaidNow: (json['amount_paid_now'] as num?)?.toDouble() ?? 0.0,
      amountAddedToKhata: (json['amount_added_to_khata'] as num?)?.toDouble() ?? 0.0,
      customerId: json['customer_id'],
      customerName: json['customer_name'],
      createdAt: json['created_at'] ?? '',
      clientId: json['client_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'line_items': lineItems.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'amount_paid_now': amountPaidNow,
      'amount_added_to_khata': amountAddedToKhata,
      'customer_id': customerId,
      'customer_name': customerName,
      'created_at': createdAt,
      'client_id': clientId,
    };
  }
}
