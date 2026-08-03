import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/constants.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _summaryData;
  Map<String, dynamic>? _ledgerData;
  Map<String, dynamic>? _forecastData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReportsData();
  }

  Future<void> _loadReportsData() async {
    setState(() => _isLoading = true);
    try {
      final client = ApiClient();
      final summary = await client.get('/reports/summary?start_date=2026-01-01&end_date=2026-12-31');
      final ledger = await client.get('/cashbook/ledger');
      final forecast = await client.get('/forecast');

      setState(() {
        _summaryData = summary;
        _ledgerData = ledger;
        _forecastData = forecast;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      appBar: AppBar(
        title: const Text('Reports & AI Insights'),
        backgroundColor: AppConstants.cardDark,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.accentGold,
          tabs: const [
            Tab(text: 'SUMMARY'),
            Tab(text: 'CASH BOOK'),
            Tab(text: 'AI FORECAST'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryGreen))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildCashbookTab(),
                _buildForecastTab(),
              ],
            ),
    );
  }

  Widget _buildSummaryTab() {
    if (_summaryData == null) return const Center(child: Text('No summary data', style: TextStyle(color: Colors.grey)));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryRow('Total Revenue:', 'Rs. ${_summaryData!['total_revenue']}', Colors.white),
          _buildSummaryRow('Cost of Goods Sold (COGS):', 'Rs. ${_summaryData!['cost_of_goods_sold']}', Colors.grey),
          _buildSummaryRow('Gross Profit:', 'Rs. ${_summaryData!['gross_profit']}', AppConstants.primaryGreen),
          _buildSummaryRow('Total Expenses:', 'Rs. ${_summaryData!['total_expenses']}', AppConstants.errorRed),
          const Divider(color: Colors.grey),
          _buildSummaryRow('NET PROFIT:', 'Rs. ${_summaryData!['net_profit']}', AppConstants.accentGold, isBold: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valColor, {bool isBold = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppConstants.cardDark, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14)),
          Text(value, style: TextStyle(color: valColor, fontWeight: FontWeight.bold, fontSize: isBold ? 18 : 14)),
        ],
      ),
    );
  }

  Widget _buildCashbookTab() {
    final entries = (_ledgerData?['entries'] as List?) ?? [];
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (ctx, idx) {
        final e = entries[idx];
        final isInflow = e['type'] == 'inflow';
        return Card(
          color: AppConstants.cardDark,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: Icon(isInflow ? Icons.arrow_downward : Icons.arrow_upward, color: isInflow ? AppConstants.primaryGreen : AppConstants.errorRed),
            title: Text(e['description'], style: const TextStyle(color: Colors.white)),
            subtitle: Text(e['date'].toString().split('T')[0], style: const TextStyle(color: Colors.grey, fontSize: 12)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${isInflow ? "+" : "-"} Rs. ${e['amount']}', style: TextStyle(color: isInflow ? AppConstants.primaryGreen : AppConstants.errorRed, fontWeight: FontWeight.bold)),
                Text('Bal: Rs. ${e['running_balance']}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildForecastTab() {
    final forecasts = (_forecastData?['forecasts'] as List?) ?? [];
    return ListView.builder(
      itemCount: forecasts.length,
      itemBuilder: (ctx, idx) {
        final f = forecasts[idx];
        final needsRestock = f['needs_restock'] == true;
        return Card(
          color: AppConstants.cardDark,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            title: Text(f['product_name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              'Stock: ${f['current_stock']} | 7-Day Demand: ${f['predicted_7day_demand']} | Method: ${f['method_used']}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            trailing: needsRestock
                ? Chip(
                    backgroundColor: AppConstants.errorRed.withOpacity(0.2),
                    label: Text('RESTOCK +${f['suggested_reorder_qty']}', style: const TextStyle(color: AppConstants.errorRed, fontWeight: FontWeight.bold, fontSize: 10)),
                  )
                : const Chip(
                    backgroundColor: Colors.green,
                    label: Text('OK', style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
          ),
        );
      },
    );
  }
}
