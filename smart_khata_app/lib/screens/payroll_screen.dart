import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../core/constants.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({Key? key}) : super(key: key);

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  Map<String, dynamic>? _payrollRun;
  bool _isLoading = false;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  Future<void> _generatePayroll() async {
    setState(() => _isLoading = true);
    try {
      final client = ApiClient();
      final data = await client.post('/payroll/generate', {'month': _selectedMonth});
      setState(() {
        _payrollRun = data;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payroll error: $e'), backgroundColor: AppConstants.alertRed),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _payPayroll() async {
    if (_payrollRun == null) return;
    try {
      final client = ApiClient();
      final updated = await client.post('/payroll/${_payrollRun!['id']}/pay', {});
      setState(() {
        _payrollRun = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payroll marked as Paid & Salary Expense Logged!'), backgroundColor: AppConstants.deepEmerald),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppConstants.alertRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.creamBg,
      appBar: AppBar(
        title: Text('Payroll HR & Salaries', style: GoogleFonts.instrumentSerif(color: AppConstants.charcoal, fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.creamBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.charcoal),
      ),
      body: Column(
        children: [
          // Month Selector Bar
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppConstants.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppConstants.softBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Month: $_selectedMonth', style: const TextStyle(color: AppConstants.charcoal, fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _generatePayroll,
                  icon: const Icon(Icons.calculate, color: Colors.white, size: 18),
                  label: const Text('GENERATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.deepEmerald,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),

          // Breakdown View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConstants.deepEmerald))
                : _payrollRun == null
                    ? const Center(child: Text('Click GENERATE to calculate salaries for the selected month.', style: TextStyle(color: AppConstants.textMuted)))
                    : Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppConstants.surfaceWhite,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppConstants.mutedTerracotta, width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total Payout Amount:', style: TextStyle(color: AppConstants.textMuted, fontSize: 13)),
                                    Text('Rs. ${_payrollRun!['total_payout']}', style: GoogleFonts.instrumentSerif(color: AppConstants.mutedTerracotta, fontSize: 26, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: _payrollRun!['paid'] == true ? null : _payPayroll,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _payrollRun!['paid'] == true ? AppConstants.textMuted : AppConstants.deepEmerald,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                  child: Text(_payrollRun!['paid'] == true ? 'PAID' : 'MARK AS PAID', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: (_payrollRun!['lines'] as List).length,
                              itemBuilder: (ctx, idx) {
                                final line = _payrollRun!['lines'][idx];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: AppConstants.surfaceWhite,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppConstants.softBorder),
                                  ),
                                  child: ListTile(
                                    title: Text(line['employee_name'], style: const TextStyle(color: AppConstants.charcoal, fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                      'Type: ${line['salary_type'].toString().toUpperCase()} | Worked: ${line['days_worked']}d | Leave: ${line['leave_days']}d | Absent: ${line['absence_days']}d',
                                      style: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                                    ),
                                    trailing: Text(
                                      'Rs. ${line['calculated_salary']}',
                                      style: const TextStyle(color: AppConstants.deepEmerald, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                );
                              },
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
