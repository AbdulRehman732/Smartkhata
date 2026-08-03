import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: AppConstants.creamBg,
      appBar: AppBar(
        title: Text('Reports & AI Insights', style: GoogleFonts.instrumentSerif(color: AppConstants.charcoal, fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.creamBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.charcoal),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.deepEmerald,
          indicatorWeight: 3,
          labelColor: AppConstants.deepEmerald,
          unselectedLabelColor: AppConstants.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'SUMMARY'),
            Tab(text: 'CASH BOOK'),
            Tab(text: 'AI FORECAST'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.deepEmerald))
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
    if (_summaryData == null) return const Center(child: Text('No summary data available', style: TextStyle(color: AppConstants.textMuted)));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryRow('Total Revenue:', 'Rs. ${_summaryData!['total_revenue']}', AppConstants.charcoal),
          _buildSummaryRow('Cost of Goods Sold (COGS):', 'Rs. ${_summaryData!['cost_of_goods_sold']}', AppConstants.textMuted),
          _buildSummaryRow('Gross Profit:', 'Rs. ${_summaryData!['gross_profit']}', AppConstants.deepEmerald),
          _buildSummaryRow('Total Expenses:', 'Rs. ${_summaryData!['total_expenses']}', AppConstants.alertRed),
          const SizedBox(height: 8),
          const Divider(color: AppConstants.softBorder, thickness: 1.5),
          const SizedBox(height: 8),
          _buildSummaryRow('NET PROFIT:', 'Rs. ${_summaryData!['net_profit']}', AppConstants.mutedTerracotta, isBold: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valColor, {bool isBold = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppConstants.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isBold ? AppConstants.mutedTerracotta : AppConstants.softBorder, width: isBold ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppConstants.charcoal, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, fontSize: isBold ? 16 : 14)),
          Text(value, style: TextStyle(color: valColor, fontWeight: FontWeight.bold, fontSize: isBold ? 20 : 15)),
        ],
      ),
    );
  }

  Widget _buildCashbookTab() {
    final entries = (_ledgerData?['entries'] as List?) ?? [];
    if (entries.isEmpty) {
      return const Center(child: Text('No cashbook entries found', style: TextStyle(color: AppConstants.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: entries.length,
      itemBuilder: (ctx, idx) {
        final e = entries[idx];
        final isInflow = e['type'] == 'inflow';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppConstants.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppConstants.softBorder),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isInflow ? AppConstants.softGreenChip : AppConstants.softRedChip,
              child: Icon(isInflow ? Icons.arrow_downward : Icons.arrow_upward, color: isInflow ? AppConstants.deepEmerald : AppConstants.alertRed),
            ),
            title: Text(e['description'] ?? 'Cash Entry', style: const TextStyle(color: AppConstants.charcoal, fontWeight: FontWeight.bold)),
            subtitle: Text(e['date'].toString().split('T')[0], style: const TextStyle(color: AppConstants.textMuted, fontSize: 12)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${isInflow ? "+" : "-"} Rs. ${e['amount']}', style: TextStyle(color: isInflow ? AppConstants.deepEmerald : AppConstants.alertRed, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Bal: Rs. ${e['running_balance']}', style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildForecastTab() {
    final forecasts = (_forecastData?['forecasts'] as List?) ?? [];
    if (forecasts.isEmpty) {
      return const Center(child: Text('No forecast data available', style: TextStyle(color: AppConstants.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: forecasts.length,
      itemBuilder: (ctx, idx) {
        final f = forecasts[idx];
        final needsRestock = f['needs_restock'] == true;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppConstants.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppConstants.softBorder),
          ),
          child: ListTile(
            title: Text(f['product_name'] ?? 'Product', style: const TextStyle(color: AppConstants.charcoal, fontWeight: FontWeight.bold)),
            subtitle: Text(
              'Stock: ${f['current_stock']} | 7-Day Demand: ${f['predicted_7day_demand']}',
              style: const TextStyle(color: AppConstants.textMuted, fontSize: 12),
            ),
            trailing: needsRestock
                ? Chip(
                    backgroundColor: AppConstants.softRedChip,
                    side: BorderSide.none,
                    label: Text('RESTOCK +${f['suggested_reorder_qty']}', style: const TextStyle(color: AppConstants.alertRed, fontWeight: FontWeight.bold, fontSize: 11)),
                  )
                : const Chip(
                    backgroundColor: AppConstants.softGreenChip,
                    side: BorderSide.none,
                    label: Text('STOCK OK', style: TextStyle(color: AppConstants.deepEmerald, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
          ),
        );
      },
    );
  }
}
