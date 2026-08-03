import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/customer.dart';

class KhataScreen extends StatefulWidget {
  const KhataScreen({Key? key}) : super(key: key);

  @override
  State<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends State<KhataScreen> {
  List<Customer> _customers = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    setState(() => _isLoading = true);
    try {
      final client = ApiClient();
      final data = await client.get('/customers');
      if (data is List) {
        setState(() {
          _customers = data.map((c) => Customer.fromJson(c)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showRecordPaymentDialog(Customer customer) {
    final amountController = TextEditingController();
    final noteController = TextEditingController(text: 'Khata payment received');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Record Payment: ${customer.name}',
          style: GoogleFonts.instrumentSerif(color: AppConstants.charcoal, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Balance Due: PKR ${customer.balanceDue}',
              style: GoogleFonts.inter(color: AppConstants.mutedTerracotta, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(color: AppConstants.charcoal),
              decoration: const InputDecoration(
                labelText: 'Payment Amount (PKR)',
                hintText: 'e.g. 500',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              style: GoogleFonts.inter(color: AppConstants.charcoal),
              decoration: const InputDecoration(
                labelText: 'Note',
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
              final amt = double.tryParse(amountController.text);
              if (amt == null || amt <= 0) return;
              try {
                final client = ApiClient();
                await client.post('/customers/payments', {
                  'customer_id': customer.id,
                  'amount': amt,
                  'note': noteController.text,
                });
                if (!mounted) return;
                Navigator.pop(ctx);
                _fetchCustomers();
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
            child: Text('RECORD PAYMENT', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showTransactionHistoryModal(Customer customer) async {
    List<dynamic> history = [];
    try {
      final client = ApiClient();
      final data = await client.get('/customers/${customer.id}/history');
      if (data is List) history = data;
    } catch (_) {}

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${customer.name} — Khata History',
              style: GoogleFonts.instrumentSerif(color: AppConstants.charcoal, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Balance Due: PKR ${customer.balanceDue}',
              style: GoogleFonts.inter(color: AppConstants.mutedTerracotta, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: history.isEmpty
                  ? Center(child: Text('No transaction history found', style: GoogleFonts.inter(color: AppConstants.textMuted)))
                  : ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (c, i) {
                        final item = history[i];
                        final isCreditSale = item['type'] == 'sale_credit';
                        return ListTile(
                          leading: Icon(
                            isCreditSale ? Icons.add_circle_outline : Icons.remove_circle_outline,
                            color: isCreditSale ? AppConstants.alertRed : AppConstants.deepEmerald,
                          ),
                          title: Text(item['description'] ?? '', style: GoogleFonts.inter(color: AppConstants.charcoal, fontWeight: FontWeight.w600)),
                          subtitle: Text(item['date'].toString().split('T')[0], style: GoogleFonts.inter(color: AppConstants.textMuted, fontSize: 12)),
                          trailing: Text(
                            '${isCreditSale ? "+" : "-"} PKR ${item['amount']}',
                            style: GoogleFonts.inter(
                              color: isCreditSale ? AppConstants.alertRed : AppConstants.deepEmerald,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    List<String> parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'C';
  }

  @override
  Widget build(BuildContext context) {
    final filteredCustomers = _searchController.text.isEmpty
        ? _customers
        : _customers.where((c) => c.name.toLowerCase().contains(_searchController.text.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: AppConstants.creamBg,
      appBar: AppBar(
        backgroundColor: AppConstants.creamBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppConstants.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customers',
              style: GoogleFonts.instrumentSerif(
                color: AppConstants.charcoal,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'You have ${filteredCustomers.length} customers',
              style: GoogleFonts.inter(
                color: AppConstants.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined, color: AppConstants.charcoal),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppConstants.deepEmerald),
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
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.inter(color: AppConstants.charcoal, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search customers',
                hintStyle: GoogleFonts.inter(color: AppConstants.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppConstants.textMuted),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 2. Customer List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConstants.deepEmerald))
                : filteredCustomers.isEmpty
                    ? Center(child: Text('No customers found', style: GoogleFonts.inter(color: AppConstants.textMuted)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: filteredCustomers.length,
                        itemBuilder: (ctx, idx) {
                          final c = filteredCustomers[idx];
                          final hasDue = c.balanceDue > 0;

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
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppConstants.softBorder.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    _getInitials(c.name),
                                    style: GoogleFonts.inter(
                                      color: AppConstants.charcoal,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                c.name,
                                style: GoogleFonts.inter(
                                  color: AppConstants.charcoal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                c.phone.isNotEmpty ? '+92 ${c.phone}' : 'Customer',
                                style: GoogleFonts.inter(
                                  color: AppConstants.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                              trailing: InkWell(
                                onTap: () => _showRecordPaymentDialog(c),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      hasDue ? 'Due' : 'Paid',
                                      style: GoogleFonts.inter(
                                        color: hasDue ? AppConstants.alertRed : AppConstants.deepEmerald,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'PKR ${c.balanceDue.toStringAsFixed(0)}',
                                      style: GoogleFonts.inter(
                                        color: hasDue ? AppConstants.alertRed : AppConstants.deepEmerald,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () => _showTransactionHistoryModal(c),
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
}
