import 'package:flutter_test/flutter_test.dart';
import 'package:smart_khata_app/models/product.dart';
import 'package:smart_khata_app/models/customer.dart';
import 'package:smart_khata_app/models/order.dart';

void main() {
  group('Smart Khata Model Serialization Tests', () {
    test('Product JSON parsing and stock status', () {
      final json = {
        'id': 'prod_123',
        'name': 'Basmati Rice 5kg',
        'urdu_name': 'چاول 5 کلو',
        'category': 'Grains',
        'unit': 'kg',
        'buying_price': 1000.0,
        'selling_price': 1250.0,
        'current_stock': 3.0,
        'low_stock_threshold': 5.0,
        'updated_at': '2026-07-27T00:00:00Z',
      };

      final p = Product.fromJson(json);
      expect(p.id, equals('prod_123'));
      expect(p.name, equals('Basmati Rice 5kg'));
      expect(p.urduName, equals('چاول 5 کلو'));
      expect(p.currentStock <= p.lowStockThreshold, isTrue);
    });

    test('Customer Khata JSON serialization', () {
      final customer = Customer(
        id: 'cust_001',
        name: 'Chaudhry Ahmad',
        phone: '03001234567',
        address: 'Main Bazaar',
        type: 'regular',
        balanceDue: 2500.0,
        updatedAt: '2026-07-27T00:00:00Z',
      );

      final map = customer.toJson();
      expect(map['name'], equals('Chaudhry Ahmad'));
      expect(map['balance_due'], equals(2500.0));
    });

    test('Order Line Item calculation', () {
      final orderJson = {
        'id': 'ord_999',
        'line_items': [
          {
            'product_id': 'prod_1',
            'product_name': 'Sugar 1kg',
            'unit_price': 150.0,
            'quantity': 2.0,
            'line_total': 300.0,
          }
        ],
        'subtotal': 300.0,
        'discount': 20.0,
        'total_amount': 280.0,
        'payment_method': 'partial',
        'amount_paid_now': 100.0,
        'amount_added_to_khata': 180.0,
        'created_at': '2026-07-27T00:00:00Z',
        'client_id': 'client_uuid_111',
      };

      final order = OrderModel.fromJson(orderJson);
      expect(order.totalAmount, equals(280.0));
      expect(order.amountAddedToKhata, equals(180.0));
      expect(order.lineItems.length, equals(1));
    });
    test('Sync response per-order status filtering logic', () {
      final syncResponse = {
        'results': [
          {'client_id': 'ord_1', 'entity_type': 'order', 'status': 'success'},
          {'client_id': 'ord_2', 'entity_type': 'order', 'status': 'failed', 'message': 'Stock out'},
        ]
      };

      final results = syncResponse['results'] as List;
      final successfulClientIds = <String>{};
      for (var r in results) {
        if (r is Map && r['entity_type'] == 'order' && r['status'] == 'success') {
          if (r['client_id'] != null) {
            successfulClientIds.add(r['client_id'].toString());
          }
        }
      }

      expect(successfulClientIds.contains('ord_1'), isTrue);
      expect(successfulClientIds.contains('ord_2'), isFalse);
    });
  });
}
