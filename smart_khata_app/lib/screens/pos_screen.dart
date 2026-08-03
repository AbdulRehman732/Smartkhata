import 'dart:io';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../core/database_helper.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({Key? key}) : super(key: key);

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  List<Product> _availableProducts = [];
  List<Customer> _customers = [];
  final Map<String, double> _cartQuantities = {};
  
  String _paymentMethod = 'cash'; // cash, credit, partial
  Customer? _selectedCustomer;
  double _discount = 0.0;
  double _amountPaidNow = 0.0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final client = ApiClient();
      final pData = await client.get('/products');
      final cData = await client.get('/customers');
      if (pData is List && cData is List) {
        setState(() {
          _availableProducts = pData.map((p) => Product.fromJson(p)).toList();
          _customers = cData.map((c) => Customer.fromJson(c)).toList();
        });
      }
    } catch (e) {
      // Fallback to local SQLite cache
      final cachedProducts = await DatabaseHelper.instance.getCachedProducts();
      final cachedCustomers = await DatabaseHelper.instance.getCachedCustomers();
      setState(() {
        _availableProducts = cachedProducts;
        _customers = cachedCustomers;
      });
    }
  }

  double get _subtotal {
    double sum = 0.0;
    _cartQuantities.forEach((prodId, qty) {
      final prod = _availableProducts.firstWhere((p) => p.id == prodId);
      sum += (prod.sellingPrice * qty);
    });
    return sum;
  }

  double get _total => (_subtotal - _discount).clamp(0.0, double.infinity);

  Future<void> _submitOrder() async {
    if (_cartQuantities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty! Select products first.')),
      );
      return;
    }

    if (_paymentMethod != 'cash' && _selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A Customer is required for Credit / Partial orders!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    List<Map<String, dynamic>> lineItems = [];
    _cartQuantities.forEach((prodId, qty) {
      lineItems.add({'product_id': prodId, 'quantity': qty});
    });

    final clientId = 'order_${DateTime.now().millisecondsSinceEpoch}';
    final payload = {
      'line_items': lineItems,
      'discount': _discount,
      'payment_method': _paymentMethod,
      'amount_paid_now': _paymentMethod == 'cash' ? _total : _amountPaidNow,
      'customer_id': _selectedCustomer?.id,
      'client_id': clientId,
    };

    try {
      final client = ApiClient();
      await client.post('/orders', payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order Created Successfully!'), backgroundColor: AppConstants.primaryGreen),
      );
      Navigator.pop(context);
    } on SocketException catch (_) {
      // Queue offline write
      await DatabaseHelper.instance.queueOfflineOrder(clientId, Uri.encodeComponent(payload.toString()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline mode: Order queued for sync!'), backgroundColor: AppConstants.accentGold),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppConstants.errorRed),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      appBar: AppBar(
        title: const Text('New Order (POS)'),
        backgroundColor: AppConstants.cardDark,
      ),
      body: Column(
        children: [
          // Product Selector List
          Expanded(
            flex: 3,
            child: ListView.builder(
              itemCount: _availableProducts.length,
              itemBuilder: (ctx, idx) {
                final prod = _availableProducts[idx];
                final qtyInCart = _cartQuantities[prod.id] ?? 0.0;
                return Card(
                  color: AppConstants.cardDark,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    title: Text(prod.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Price: Rs. ${prod.sellingPrice} | Stock: ${prod.currentStock} ${prod.unit}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (qtyInCart > 0)
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: AppConstants.errorRed),
                            onPressed: () {
                              setState(() {
                                if (qtyInCart > 1) {
                                  _cartQuantities[prod.id] = qtyInCart - 1;
                                } else {
                                  _cartQuantities.remove(prod.id);
                                }
                              });
                            },
                          ),
                        if (qtyInCart > 0)
                          Text('$qtyInCart', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: AppConstants.primaryGreen),
                          onPressed: () {
                            setState(() {
                              _cartQuantities[prod.id] = qtyInCart + 1;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Order Checkout Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppConstants.cardDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Payment Method Selector
                Row(
                  children: [
                    const Text('Payment Mode: ', style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Cash'),
                      selected: _paymentMethod == 'cash',
                      onSelected: (val) => setState(() => _paymentMethod = 'cash'),
                    ),
                    const SizedBox(width: 4),
                    ChoiceChip(
                      label: const Text('Credit'),
                      selected: _paymentMethod == 'credit',
                      onSelected: (val) => setState(() => _paymentMethod = 'credit'),
                    ),
                    const SizedBox(width: 4),
                    ChoiceChip(
                      label: const Text('Partial'),
                      selected: _paymentMethod == 'partial',
                      onSelected: (val) => setState(() => _paymentMethod = 'partial'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Customer Dropdown if Credit/Partial
                if (_paymentMethod != 'cash')
                  DropdownButton<Customer>(
                    dropdownColor: AppConstants.cardDark,
                    hint: const Text('Select Khata Customer', style: TextStyle(color: Colors.grey)),
                    value: _selectedCustomer,
                    isExpanded: true,
                    items: _customers.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text('${c.name} (${c.phone}) - Due: Rs. ${c.balanceDue}',
                            style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (c) => setState(() => _selectedCustomer = c),
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:', style: TextStyle(color: Colors.grey)),
                    Text('Rs. $_subtotal', style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Rs. $_total', style: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitOrder,
                    style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryGreen),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('COMPLETE SALE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
