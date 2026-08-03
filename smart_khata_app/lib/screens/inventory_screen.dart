import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  int _activeFilterIndex = 0; // 0: All, 1: Low Stock, 2: Out of Stock
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
      bool lowStockOnly = _activeFilterIndex == 1;
      String endpoint = '/products?low_stock_only=$lowStockOnly';
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Adjust Stock: ${product.name}',
          style: GoogleFonts.instrumentSerif(color: AppConstants.charcoal, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Stock: ${product.currentStock} ${product.unit}',
              style: GoogleFonts.inter(color: AppConstants.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              style: GoogleFonts.inter(color: AppConstants.charcoal),
              decoration: const InputDecoration(
                labelText: 'Change (+ for Add, - for Spoilage)',
                hintText: 'e.g. +10 or -2',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: GoogleFonts.inter(color: AppConstants.textMuted, fontWeight: FontWeight.w600)),
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
                  'reason': 'manual_correction',
                });
                if (!mounted) return;
                Navigator.pop(ctx);
                _fetchProducts();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString()), backgroundColor: AppConstants.alertRed),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.deepEmerald,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('SAVE', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int lowStockCount = _products.where((p) => p.currentStock <= p.lowStockThreshold).length;

    return Scaffold(
      backgroundColor: AppConstants.creamBg,
      appBar: AppBar(
        backgroundColor: AppConstants.creamBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppConstants.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Inventory',
          style: GoogleFonts.instrumentSerif(
            color: AppConstants.charcoal,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppConstants.charcoal),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _fetchProducts(),
              style: GoogleFonts.inter(color: AppConstants.charcoal, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search products in Urdu or English',
                hintStyle: GoogleFonts.inter(color: AppConstants.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: AppConstants.textMuted),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune_outlined, color: AppConstants.textMuted, size: 20),
                  onPressed: () {},
                ),
              ),
            ),
          ),

          // 2. Filter Chips Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                _buildFilterChip('All', 0),
                const SizedBox(width: 8),
                _buildFilterChip('Low stock ($lowStockCount)', 1),
                const SizedBox(width: 8),
                _buildFilterChip('Out of stock (0)', 2),
              ],
            ),
          ),

          // 3. Stock Summary Metric Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppConstants.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppConstants.softBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat('${_products.length}', 'Products'),
                Container(height: 30, width: 1, color: AppConstants.softBorder),
                _buildSummaryStat('$lowStockCount', 'Low stock', isAlert: lowStockCount > 0),
                Container(height: 30, width: 1, color: AppConstants.softBorder),
                _buildSummaryStat('2.8L', 'Stock value'),
              ],
            ),
          ),

          // 4. Products List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConstants.deepEmerald))
                : _products.isEmpty
                    ? Center(
                        child: Text(
                          'No products found',
                          style: GoogleFonts.inter(color: AppConstants.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _products.length,
                        itemBuilder: (ctx, idx) {
                          final p = _products[idx];
                          final isLow = p.currentStock <= p.lowStockThreshold;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppConstants.surfaceWhite,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppConstants.softBorder),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppConstants.creamBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  color: AppConstants.deepEmerald,
                                  size: 26,
                                ),
                              ),
                              title: Text(
                                p.name,
                                style: GoogleFonts.inter(
                                  color: AppConstants.charcoal,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                'PKR ${p.sellingPrice.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  color: AppConstants.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${p.currentStock} ${p.unit}',
                                        style: GoogleFonts.inter(
                                          color: isLow ? AppConstants.alertRed : AppConstants.charcoal,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isLow ? 'Low stock' : 'In stock',
                                        style: GoogleFonts.inter(
                                          color: isLow ? AppConstants.alertRed : AppConstants.textMuted,
                                          fontSize: 11,
                                          fontWeight: isLow ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right, color: AppConstants.textMuted, size: 20),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppConstants.deepEmerald,
        elevation: 2,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _activeFilterIndex == index;
    Color bg = isSelected
        ? (index == 1 ? AppConstants.softRedChip : AppConstants.deepEmerald)
        : AppConstants.surfaceWhite;
    Color textColor = isSelected
        ? (index == 1 ? AppConstants.alertRed : Colors.white)
        : AppConstants.charcoal;

    return GestureDetector(
      onTap: () {
        setState(() => _activeFilterIndex = index);
        _fetchProducts();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? (index == 1 ? AppConstants.alertRed : AppConstants.deepEmerald) : AppConstants.softBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String value, String label, {bool isAlert = false}) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.instrumentSerif(
            color: isAlert ? AppConstants.alertRed : AppConstants.charcoal,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppConstants.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
