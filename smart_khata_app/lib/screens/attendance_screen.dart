import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  Map<String, String> _attendanceMap = {};
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
      // Handle gracefully
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
        SnackBar(content: Text('Failed to update: $e'), backgroundColor: AppConstants.alertRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.creamBg,
      appBar: AppBar(
        title: Text('Daily Attendance', style: GoogleFonts.instrumentSerif(color: AppConstants.charcoal, fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.creamBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.charcoal),
      ),
      body: Column(
        children: [
          // Date Selector Bar
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
                Text('Date: $_formattedDate', style: const TextStyle(color: AppConstants.charcoal, fontSize: 16, fontWeight: FontWeight.bold)),
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
                  label: const Text('SELECT DATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.deepEmerald,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),

          // Employee List Roster
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConstants.deepEmerald))
                : _employees.isEmpty
                    ? const Center(child: Text('No employees found', style: TextStyle(color: AppConstants.textMuted)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _employees.length,
                        itemBuilder: (ctx, idx) {
                          final emp = _employees[idx];
                          final currentStatus = _attendanceMap[emp.id] ?? 'none';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppConstants.surfaceWhite,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppConstants.softBorder),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              title: Text(emp.name, style: const TextStyle(color: AppConstants.charcoal, fontWeight: FontWeight.bold)),
                              subtitle: Text('Role: ${emp.roleTitle.toUpperCase()} | Phone: ${emp.phone}',
                                  style: const TextStyle(color: AppConstants.textMuted, fontSize: 12)),
                              trailing: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ChoiceChip(
                                      label: const Text('Present'),
                                      selected: currentStatus == 'present',
                                      selectedColor: AppConstants.softGreenChip,
                                      labelStyle: TextStyle(
                                        color: currentStatus == 'present' ? AppConstants.deepEmerald : AppConstants.textMuted,
                                        fontWeight: currentStatus == 'present' ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                      onSelected: (_) => _markStatus(emp.id, 'present'),
                                    ),
                                    const SizedBox(width: 4),
                                    ChoiceChip(
                                      label: const Text('Absent'),
                                      selected: currentStatus == 'absent',
                                      selectedColor: AppConstants.softRedChip,
                                      labelStyle: TextStyle(
                                        color: currentStatus == 'absent' ? AppConstants.alertRed : AppConstants.textMuted,
                                        fontWeight: currentStatus == 'absent' ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                      onSelected: (_) => _markStatus(emp.id, 'absent'),
                                    ),
                                  ],
                                ),
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
}
