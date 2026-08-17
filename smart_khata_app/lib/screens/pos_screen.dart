import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../core/database_helper.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

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
        if (!mounted) return;
        setState(() {
          _availableProducts = pData.map((p) => Product.fromJson(p)).toList();
          _customers = cData.map((c) => Customer.fromJson(c)).toList();
        });
      }
    } catch (e) {
      // Handle offline or fallback
    }
  }

  double get _subtotal {
    double sum = 0.0;
    for (var prod in _availableProducts) {
      final qty = _cartQuantities[prod.id] ?? 0.0;
      if (qty > 0) {
        sum += (prod.sellingPrice * qty);
      }
    }
    return sum;
  }

  double get _total => (_subtotal - _discount).clamp(0.0, double.infinity);
  double get _totalAmount => _total;

  Future<void> _submitOrder() async {
    if (_cartQuantities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Select products first.'), backgroundColor: AppConstants.alertRed),
      );
      return;
    }

    if ((_paymentMethod == 'credit' || _paymentMethod == 'partial') && _selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer for Khata credit ledger.'), backgroundColor: AppConstants.alertRed),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final lineItems = <Map<String, dynamic>>[];
    for (var prod in _availableProducts) {
      final qty = _cartQuantities[prod.id] ?? 0.0;
      if (qty > 0) {
        lineItems.add({
          'product_id': prod.id,
          'product_name': prod.name,
          'unit_price': prod.sellingPrice,
          'quantity': qty,
          'line_total': prod.sellingPrice * qty,
        });
      }
    }

    final clientId = 'order_${DateTime.now().millisecondsSinceEpoch}';
    final payload = {
      'line_items': lineItems,
      'subtotal': _subtotal,
      'discount': _discount,
      'total_amount': _totalAmount,
      'payment_method': _paymentMethod,
      'customer_id': _selectedCustomer?.id,
      'client_id': clientId,
      'amount_paid_now': _paymentMethod == 'cash' ? _totalAmount : (_paymentMethod == 'partial' ? _amountPaidNow : 0.0),
    };

    try {
      final client = ApiClient();
      await client.post('/orders', payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order & Khata Invoice recorded successfully!'), backgroundColor: AppConstants.deepEmerald),
      );

      setState(() {
        _cartQuantities.clear();
        _discount = 0.0;
        _amountPaidNow = 0.0;
        _isSubmitting = false;
      });
      _loadData();
    } catch (e) {
      // OFFLINE QUEUING: Store in SQLite pending queue
      await DatabaseHelper.instance.queueOfflineOrder(clientId, jsonEncode(payload));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network offline: Order saved locally to SQLite queue for background sync.'),
          backgroundColor: AppConstants.mutedTerracotta,
        ),
      );

      setState(() {
        _cartQuantities.clear();
        _isSubmitting = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.creamBg,
      appBar: AppBar(
        title: Text('New Sale & POS', style: GoogleFonts.instrumentSerif(color: AppConstants.charcoal, fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.creamBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.charcoal),
      ),
      body: Column(
        children: [
          // Product Selector List
          Expanded(
            child: _availableProducts.isEmpty
                ? const Center(
                    child: Text('No products found', style: TextStyle(color: AppConstants.textMuted, fontSize: 16)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _availableProducts.length,
                    itemBuilder: (ctx, idx) {
                      final prod = _availableProducts[idx];
                      final qtyInCart = _cartQuantities[prod.id] ?? 0.0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppConstants.surfaceWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppConstants.softBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(prod.name, style: const TextStyle(color: AppConstants.charcoal, fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Rs. ${prod.sellingPrice} | Stock: ${prod.currentStock} ${prod.unit}',
                              style: const TextStyle(color: AppConstants.textMuted, fontSize: 13),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (qtyInCart > 0)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: AppConstants.alertRed, size: 24),
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
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text('${qtyInCart.toInt()}', style: const TextStyle(color: AppConstants.charcoal, fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: AppConstants.deepEmerald, size: 28),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppConstants.surfaceWhite,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppConstants.softBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Method Selector with Horizontal Scroll to prevent overflow
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text('Payment Mode: ', style: TextStyle(color: AppConstants.charcoal, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Cash'),
                          selected: _paymentMethod == 'cash',
                          selectedColor: AppConstants.softGreenChip,
                          labelStyle: TextStyle(
                            color: _paymentMethod == 'cash' ? AppConstants.deepEmerald : AppConstants.textMuted,
                            fontWeight: _paymentMethod == 'cash' ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) => setState(() => _paymentMethod = 'cash'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Credit (Khata)'),
                          selected: _paymentMethod == 'credit',
                          selectedColor: AppConstants.softGreenChip,
                          labelStyle: TextStyle(
                            color: _paymentMethod == 'credit' ? AppConstants.deepEmerald : AppConstants.textMuted,
                            fontWeight: _paymentMethod == 'credit' ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) => setState(() => _paymentMethod = 'credit'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Partial'),
                          selected: _paymentMethod == 'partial',
                          selectedColor: AppConstants.softGreenChip,
                          labelStyle: TextStyle(
                            color: _paymentMethod == 'partial' ? AppConstants.deepEmerald : AppConstants.textMuted,
                            fontWeight: _paymentMethod == 'partial' ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) => setState(() => _paymentMethod = 'partial'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Customer Dropdown if Credit/Partial
                  if (_paymentMethod != 'cash')
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppConstants.creamBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppConstants.softBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Customer>(
                          dropdownColor: AppConstants.surfaceWhite,
                          hint: const Text('Select Khata Customer', style: TextStyle(color: AppConstants.textMuted)),
                          value: _selectedCustomer,
                          isExpanded: true,
                          items: _customers.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text('${c.name} (${c.phone}) - Due: Rs. ${c.balanceDue}',
                                  style: const TextStyle(color: AppConstants.charcoal, fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (c) => setState(() => _selectedCustomer = c),
                        ),
                      ),
                    ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:', style: TextStyle(color: AppConstants.textMuted, fontSize: 14)),
                      Text('Rs. $_subtotal', style: const TextStyle(color: AppConstants.charcoal, fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:', style: TextStyle(color: AppConstants.charcoal, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Rs. $_total', style: GoogleFonts.instrumentSerif(color: AppConstants.mutedTerracotta, fontWeight: FontWeight.bold, fontSize: 24)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.deepEmerald,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('COMPLETE SALE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
