import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/employee.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Employee> _employees = [];
  Map<String, String> _attendanceMap = {}; // emp_id -> status
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployeesAndAttendance();
  }

  String get _formattedDate => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Future<void> _loadEmployeesAndAttendance() async {
    setState(() => _isLoading = true);
    try {
      final client = ApiClient();
      final empData = await client.get('/employees');
      final attData = await client.get('/attendance?date=$_formattedDate');

      if (empData is List) {
        _employees = empData.map((e) => Employee.fromJson(e)).toList();
      }

      _attendanceMap.clear();
      if (attData is List) {
        for (var record in attData) {
          _attendanceMap[record['employee_id']] = record['status'];
        }
      }
    } catch (e) {
      // Handle error gracefully
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markStatus(String employeeId, String status) async {
    setState(() {
      _attendanceMap[employeeId] = status;
    });

    try {
      final client = ApiClient();
      await client.post('/attendance', {
        'employee_id': employeeId,
        'date': _formattedDate,
        'status': status,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e'), backgroundColor: AppConstants.errorRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      appBar: AppBar(
        title: const Text('Daily Attendance Roster'),
        backgroundColor: AppConstants.cardDark,
      ),
      body: Column(
        children: [
          // Date Selector Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: AppConstants.cardDark,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Date: $_formattedDate', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                      _loadEmployeesAndAttendance();
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 16, color: Colors.white),
                  label: const Text('CHANGE DATE', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryGreen),
                ),
              ],
            ),
          ),

          // Employee List Roster
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryGreen))
                : ListView.builder(
                    itemCount: _employees.length,
                    itemBuilder: (ctx, idx) {
                      final emp = _employees[idx];
                      final currentStatus = _attendanceMap[emp.id] ?? 'none';
                      return Card(
                        color: AppConstants.cardDark,
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(emp.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('Role: ${emp.roleTitle} | Type: ${emp.salaryType.toUpperCase()}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 8),

                              // Quick Toggle Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatusChip(emp.id, 'present', 'PRESENT', Colors.green, currentStatus),
                                  _buildStatusChip(emp.id, 'half_day', 'HALF DAY', Colors.orange, currentStatus),
                                  _buildStatusChip(emp.id, 'leave', 'LEAVE', Colors.blue, currentStatus),
                                  _buildStatusChip(emp.id, 'absent', 'ABSENT', Colors.red, currentStatus),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String empId, String statusKey, String label, Color color, String activeStatus) {
    final isSelected = activeStatus == statusKey;
    return GestureDetector(
      onTap: () => _markStatus(empId, statusKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
