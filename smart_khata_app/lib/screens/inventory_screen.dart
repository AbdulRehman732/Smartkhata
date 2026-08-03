import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/product.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  bool _lowStockOnly = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final client = ApiClient();
      String endpoint = '/products?low_stock_only=$_lowStockOnly';
      if (_searchController.text.isNotEmpty) {
        endpoint += '&search=${Uri.encodeComponent(_searchController.text)}';
      }
      final data = await client.get(endpoint);
      if (data is List) {
        setState(() {
          _products = data.map((p) => Product.fromJson(p)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showStockAdjustmentDialog(Product product) {
    final qtyController = TextEditingController();
    String reason = 'manual_correction';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.cardDark,
        title: Text('Adjust Stock: ${product.name}', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Stock: ${product.currentStock} ${product.unit}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Change (+ for Add, - for Spoilage)',
                labelStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final change = double.tryParse(qtyController.text);
              if (change == null) return;
              try {
                final client = ApiClient();
                await client.post('/products/adjust-stock', {
                  'product_id': product.id,
                  'quantity_change': change,
                  'reason': reason,
                });
                Navigator.pop(ctx);
                _fetchProducts();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString()), backgroundColor: AppConstants.errorRed),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryGreen),
            child: const Text('SAVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      appBar: AppBar(
        title: const Text('Inventory & Stock'),
        backgroundColor: AppConstants.cardDark,
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _fetchProducts(),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search English / Urdu (چاول)...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: AppConstants.cardDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Low Stock', style: TextStyle(color: Colors.white)),
                  selected: _lowStockOnly,
                  selectedColor: AppConstants.errorRed,
                  backgroundColor: AppConstants.cardDark,
                  onSelected: (val) {
                    setState(() => _lowStockOnly = val);
                    _fetchProducts();
                  },
                ),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryGreen))
                : _products.isEmpty
                    ? const Center(child: Text('No products found', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (ctx, idx) {
                          final p = _products[idx];
                          final isLow = p.currentStock <= p.lowStockThreshold;
                          return Card(
                            color: AppConstants.cardDark,
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${p.urduName ?? ''} | Category: ${p.category} | Price: Rs. ${p.sellingPrice}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${p.currentStock} ${p.unit}',
                                    style: TextStyle(
                                      color: isLow ? AppConstants.errorRed : AppConstants.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (isLow)
                                    const Text('LOW STOCK', style: TextStyle(color: AppConstants.errorRed, fontSize: 10)),
                                ],
                              ),
                              onTap: () => _showStockAdjustmentDialog(p),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
