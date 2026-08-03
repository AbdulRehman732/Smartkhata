import 'package:flutter/material.dart';
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
        SnackBar(content: Text('Payroll error: $e'), backgroundColor: AppConstants.errorRed),
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
        const SnackBar(content: Text('Payroll marked as Paid & Salary Expense Logged!'), backgroundColor: AppConstants.primaryGreen),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppConstants.errorRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      appBar: AppBar(
        title: const Text('Payroll HR & Salaries'),
        backgroundColor: AppConstants.cardDark,
      ),
      body: Column(
        children: [
          // Month Selector Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: AppConstants.cardDark,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Month: $_selectedMonth', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _generatePayroll,
                  icon: const Icon(Icons.calculate, color: Colors.white),
                  label: const Text('GENERATE PAYROLL', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryGreen),
                ),
              ],
            ),
          ),

          // Breakdown View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryGreen))
                : _payrollRun == null
                    ? const Center(child: Text('Click GENERATE PAYROLL for the selected month.', style: TextStyle(color: Colors.grey)))
                    : Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppConstants.cardDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppConstants.accentGold),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total Payout Amount:', style: TextStyle(color: Colors.grey)),
                                    Text('Rs. ${_payrollRun!['total_payout']}', style: const TextStyle(color: AppConstants.accentGold, fontSize: 22, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: _payrollRun!['paid'] ? null : _payPayroll,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _payrollRun!['paid'] ? Colors.grey : AppConstants.primaryGreen,
                                  ),
                                  child: Text(_payrollRun!['paid'] ? 'PAID' : 'MARK AS PAID', style: const TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            child: ListView.builder(
                              itemCount: (_payrollRun!['lines'] as List).length,
                              itemBuilder: (ctx, idx) {
                                final line = _payrollRun!['lines'][idx];
                                return Card(
                                  color: AppConstants.cardDark,
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  child: ListTile(
                                    title: Text(line['employee_name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                      'Type: ${line['salary_type'].toString().toUpperCase()} | Worked: ${line['days_worked']}d | Leave: ${line['leave_days']}d | Absent: ${line['absence_days']}d',
                                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                                    ),
                                    trailing: Text(
                                      'Rs. ${line['calculated_salary']}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
