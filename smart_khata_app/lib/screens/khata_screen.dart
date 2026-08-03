import 'package:flutter/material.dart';
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
        backgroundColor: AppConstants.cardDark,
        title: Text('Record Payment: ${customer.name}', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Balance Due: Rs. ${customer.balanceDue}', style: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Payment Amount (Rs.)',
                labelStyle: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Note',
                labelStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: Colors.grey))),
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
                Navigator.pop(ctx);
                _fetchCustomers();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppConstants.errorRed));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryGreen),
            child: const Text('RECORD PAYMENT', style: TextStyle(color: Colors.white)),
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
      backgroundColor: AppConstants.cardDark,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${customer.name} — Khata History', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Current Balance Due: Rs. ${customer.balanceDue}', style: const TextStyle(color: AppConstants.accentGold)),
            const SizedBox(height: 12),
            Expanded(
              child: history.isEmpty
                  ? const Center(child: Text('No transaction history found', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (c, i) {
                        final item = history[i];
                        final isCreditSale = item['type'] == 'sale_credit';
                        return ListTile(
                          leading: Icon(
                            isCreditSale ? Icons.add_circle : Icons.remove_circle,
                            color: isCreditSale ? AppConstants.errorRed : AppConstants.primaryGreen,
                          ),
                          title: Text(item['description'] ?? '', style: const TextStyle(color: Colors.white)),
                          subtitle: Text(item['date'].toString().split('T')[0], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          trailing: Text(
                            '${isCreditSale ? "+" : "-"} Rs. ${item['amount']}',
                            style: TextStyle(
                              color: isCreditSale ? AppConstants.errorRed : AppConstants.primaryGreen,
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

  @override
  Widget build(BuildContext context) {
    double totalDue = _customers.fold(0.0, (sum, c) => sum + c.balanceDue);

    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      appBar: AppBar(
        title: const Text('Customer Khata Ledger'),
        backgroundColor: AppConstants.cardDark,
      ),
      body: Column(
        children: [
          // Banner Total Balance Due
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.accentGold.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Pending Khata:', style: TextStyle(color: Colors.grey, fontSize: 14)),
                Text('Rs. $totalDue', style: const TextStyle(color: AppConstants.accentGold, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Customer List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryGreen))
                : ListView.builder(
                    itemCount: _customers.length,
                    itemBuilder: (ctx, idx) {
                      final c = _customers[idx];
                      return Card(
                        color: AppConstants.cardDark,
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          title: Text(c.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('Phone: ${c.phone} | Type: ${c.type.toUpperCase()}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Rs. ${c.balanceDue}', style: const TextStyle(color: AppConstants.accentGold, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const Text('DUE', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.payment, color: AppConstants.primaryGreen),
                                onPressed: () => _showRecordPaymentDialog(c),
                              ),
                            ],
                          ),
                          onTap: () => _showTransactionHistoryModal(c),
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
