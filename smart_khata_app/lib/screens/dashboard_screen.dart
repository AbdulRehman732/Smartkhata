import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import 'inventory_screen.dart';
import 'pos_screen.dart';
import 'khata_screen.dart';
import 'attendance_screen.dart';
import 'payroll_screen.dart';
import 'reports_screen.dart';
import 'voice_command_screen.dart';
import 'sync_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _metrics;
  bool _isLoading = true;
  String _userRole = 'owner';
  String _userName = 'Owner Store';

  @override
  void initState() {
    super.initState();
    _loadUserAndMetrics();
  }

  Future<void> _loadUserAndMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString(AppConstants.userRoleKey) ?? 'owner';
      _userName = prefs.getString(AppConstants.userNameKey) ?? 'Owner Store';
    });

    try {
      final client = ApiClient();
      final data = await client.get('/reports/dashboard');
      setState(() {
        _metrics = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallets = (_metrics?['wallet_balances'] as Map<String, dynamic>?) ?? {};

    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      appBar: AppBar(
        title: const Text('Smart Khata Dashboard'),
        backgroundColor: AppConstants.cardDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: AppConstants.accentGold),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SyncScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.mic_rounded, color: AppConstants.primaryGreen),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VoiceCommandScreen()),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppConstants.cardDark,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppConstants.primaryGreen),
              accountName: Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text('Role: ${_userRole.toUpperCase()}'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: AppConstants.accentGold,
                child: Icon(Icons.store, color: Colors.white),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2, color: Colors.white),
              title: const Text('Inventory', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.point_of_sale, color: Colors.white),
              title: const Text('New Order (POS)', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PosScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book, color: Colors.white),
              title: const Text('Customer Khata', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KhataScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.how_to_reg, color: Colors.white),
              title: const Text('Daily Attendance', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen())),
            ),
            if (_userRole == 'owner') ...[
              ListTile(
                leading: const Icon(Icons.payments, color: Colors.white),
                title: const Text('Payroll HR', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PayrollScreen())),
              ),
              ListTile(
                leading: const Icon(Icons.analytics, color: Colors.white),
                title: const Text('Reports & Forecast', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
              ),
            ],
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.logout, color: AppConstants.errorRed),
              title: const Text('Log Out', style: TextStyle(color: AppConstants.errorRed)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryGreen))
          : RefreshIndicator(
              onRefresh: _loadUserAndMetrics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppConstants.primaryGreen, Color(0xFF064E3B)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Assalam-o-Alaikum, $_userName!',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Here is your store summary for today',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.storefront, size: 40, color: AppConstants.accentGold),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Metrics Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _buildMetricCard('Today Revenue', 'Rs. ${_metrics?['today_revenue'] ?? 0}', Icons.attach_money, AppConstants.primaryGreen),
                        _buildMetricCard('Gross Profit', 'Rs. ${_metrics?['today_profit'] ?? 0}', Icons.trending_up, Colors.blue),
                        _buildMetricCard('Cash Collected', 'Rs. ${_metrics?['cash_collected'] ?? 0}', Icons.account_balance_wallet, AppConstants.accentGold),
                        _buildMetricCard('Low Stock Alert', '${_metrics?['low_stock_count'] ?? 0} items', Icons.warning_amber, AppConstants.errorRed),
                        _buildMetricCard('Pending Khata', 'Rs. ${_metrics?['pending_khata_total'] ?? 0}', Icons.book, Colors.purple),
                        _buildMetricCard('Staff Present', '${_metrics?['employees_present_today'] ?? 0} active', Icons.people, Colors.teal),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Multi-Wallet Account Balances Header
                    const Text(
                      'Multi-Wallet Balances',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildWalletChip('Cash Box', 'Rs. ${wallets['cash'] ?? 0}', Colors.green),
                          _buildWalletChip('JazzCash', 'Rs. ${wallets['jazzcash'] ?? 0}', Colors.redAccent),
                          _buildWalletChip('Easypaisa', 'Rs. ${wallets['easypaisa'] ?? 0}', Colors.lightGreen),
                          _buildWalletChip('NayaPay', 'Rs. ${wallets['nayapay'] ?? 0}', Colors.orangeAccent),
                          _buildWalletChip('Bank Account', 'Rs. ${wallets['bank'] ?? 0}', Colors.blueAccent),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions Header
                    const Text(
                      'Quick Actions',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PosScreen())),
                            icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                            label: const Text('POS SALE', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KhataScreen())),
                            icon: const Icon(Icons.payment, color: Colors.white),
                            label: const Text('KHATA', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.accentGold,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletChip(String name, String balance, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(name, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(balance, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
