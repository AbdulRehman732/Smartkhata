import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/employee.dart';
import '../models/leave_request.dart';

class AttendanceScreen extends StatefulWidget {
  final int initialTabIndex;
  const AttendanceScreen({super.key, this.initialTabIndex = 0});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Attendance state
  List<Employee> _employees = [];
  final Map<String, String> _attendanceMap = {};
  DateTime _selectedDate = DateTime.now();
  bool _isLoadingAttendance = true;

  // Leave Management state
  List<LeaveRequest> _allLeaves = [];
  bool _isLoadingLeaves = false;
  String? _selectedEmployeeFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadEmployeesAndAttendance();
    _loadAllLeaveRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _formattedDate => DateFormat('yyyy-MM-dd').format(_selectedDate);

  // ── Attendance Operations ──────────────────────────────────────────────────
  Future<void> _loadEmployeesAndAttendance() async {
    setState(() => _isLoadingAttendance = true);
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
    } catch (_) {
      // Handle silently
    } finally {
      if (mounted) setState(() => _isLoadingAttendance = false);
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update attendance: $e'), backgroundColor: AppConstants.alertRed),
      );
    }
  }

  // ── Leave Request Operations ───────────────────────────────────────────────
  Future<void> _loadAllLeaveRequests() async {
    setState(() => _isLoadingLeaves = true);
    try {
      final client = ApiClient();
      final empData = await client.get('/employees');
      if (empData is List) {
        _employees = empData.map((e) => Employee.fromJson(e)).toList();
      }

      List<LeaveRequest> collected = [];
      for (var emp in _employees) {
        try {
          final leavesData = await client.get('/employees/${emp.id}/leave-requests');
          if (leavesData is List) {
            collected.addAll(leavesData.map((l) => LeaveRequest.fromJson(l)));
          }
        } catch (_) {}
      }

      // Sort newest first
      collected.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _allLeaves = collected;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingLeaves = false);
    }
  }

  void _showApplyLeaveModal() {
    if (_employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No employees found to submit leave for.')),
      );
      return;
    }

    String selectedEmpId = _employees.first.id;
    String leaveType = 'casual';
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now();
    final reasonController = TextEditingController(text: 'Personal urgent work');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.creamBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final days = endDate.difference(startDate).inDays + 1;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppConstants.textMuted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Apply for Leave',
                          style: GoogleFonts.instrumentSerif(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.charcoal,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppConstants.softGreenChip,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$days ${days == 1 ? "Day" : "Days"}',
                            style: const TextStyle(
                              color: AppConstants.deepEmerald,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Employee Dropdown
                    const Text('Employee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConstants.charcoal)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppConstants.surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppConstants.softBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedEmpId,
                          isExpanded: true,
                          items: _employees.map((e) {
                            return DropdownMenuItem<String>(
                              value: e.id,
                              child: Text('${e.name} (${e.roleTitle.toUpperCase()})', style: const TextStyle(color: AppConstants.charcoal)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedEmpId = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Leave Type Segment
                    const Text('Leave Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConstants.charcoal)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Casual Leave (اتفاقی)')),
                            selected: leaveType == 'casual',
                            selectedColor: AppConstants.softGreenChip,
                            labelStyle: TextStyle(
                              color: leaveType == 'casual' ? AppConstants.deepEmerald : AppConstants.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) => setModalState(() => leaveType = 'casual'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Sick Leave (بیماری)')),
                            selected: leaveType == 'sick',
                            selectedColor: AppConstants.softGreenChip,
                            labelStyle: TextStyle(
                              color: leaveType == 'sick' ? AppConstants.deepEmerald : AppConstants.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) => setModalState(() => leaveType = 'sick'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Date Range Pickers
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConstants.charcoal)),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: AppConstants.surfaceWhite,
                                  side: const BorderSide(color: AppConstants.softBorder),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                ),
                                icon: const Icon(Icons.calendar_today, size: 16, color: AppConstants.deepEmerald),
                                label: Text(DateFormat('yyyy-MM-dd').format(startDate), style: const TextStyle(color: AppConstants.charcoal, fontSize: 12)),
                                onPressed: () async {
                                  final p = await showDatePicker(
                                    context: context,
                                    initialDate: startDate,
                                    firstDate: DateTime(2025),
                                    lastDate: DateTime(2030),
                                  );
                                  if (p != null) {
                                    setModalState(() {
                                      startDate = p;
                                      if (endDate.isBefore(startDate)) endDate = startDate;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('End Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConstants.charcoal)),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: AppConstants.surfaceWhite,
                                  side: const BorderSide(color: AppConstants.softBorder),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                ),
                                icon: const Icon(Icons.event, size: 16, color: AppConstants.deepEmerald),
                                label: Text(DateFormat('yyyy-MM-dd').format(endDate), style: const TextStyle(color: AppConstants.charcoal, fontSize: 12)),
                                onPressed: () async {
                                  final p = await showDatePicker(
                                    context: context,
                                    initialDate: endDate.isBefore(startDate) ? startDate : endDate,
                                    firstDate: startDate,
                                    lastDate: DateTime(2030),
                                  );
                                  if (p != null) {
                                    setModalState(() => endDate = p);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Reason Field
                    const Text('Reason / Note', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConstants.charcoal)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Family function, hospital visit...',
                        hintStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 13),
                        filled: true,
                        fillColor: AppConstants.surfaceWhite,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppConstants.softBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppConstants.softBorder),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.deepEmerald,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setModalState(() => isSubmitting = true);
                                try {
                                  final client = ApiClient();
                                  await client.post('/employees/$selectedEmpId/leave-requests', {
                                    'employee_id': selectedEmpId,
                                    'leave_type': leaveType,
                                    'start_date': DateFormat('yyyy-MM-dd').format(startDate),
                                    'end_date': DateFormat('yyyy-MM-dd').format(endDate),
                                    'reason': reasonController.text.trim(),
                                  });

                                  if (!mounted) return;
                                  Navigator.of(context, rootNavigator: false).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Leave request approved and recorded successfully!'),
                                      backgroundColor: AppConstants.deepEmerald,
                                    ),
                                  );
                                  _loadAllLeaveRequests();
                                } catch (e) {
                                  if (mounted) {
                                    setModalState(() => isSubmitting = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Submission failed: $e'), backgroundColor: AppConstants.alertRed),
                                    );
                                  }
                                }
                              },

                        child: isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : const Text(
                                'SUBMIT & APPROVE LEAVE',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.creamBg,
      appBar: AppBar(
        title: Text(
          'Staff & Leave Management',
          style: GoogleFonts.instrumentSerif(
            color: AppConstants.charcoal,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
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
            Tab(icon: Icon(Icons.how_to_reg_outlined, size: 20), text: 'DAILY ATTENDANCE'),
            Tab(icon: Icon(Icons.beach_access_outlined, size: 20), text: 'LEAVE REQUESTS'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: _showApplyLeaveModal,
              backgroundColor: AppConstants.deepEmerald,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('APPLY LEAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: Attendance Roster ───────────────────────────────────────
          _buildAttendanceTab(),

          // ── TAB 2: Leave Requests List ─────────────────────────────────────
          _buildLeaveRequestsTab(),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return Column(
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
          child: _isLoadingAttendance
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
    );
  }

  Widget _buildLeaveRequestsTab() {
    final filteredLeaves = _selectedEmployeeFilter == null
        ? _allLeaves
        : _allLeaves.where((l) => l.employeeId == _selectedEmployeeFilter).toList();

    return RefreshIndicator(
      color: AppConstants.deepEmerald,
      onRefresh: _loadAllLeaveRequests,
      child: Column(
        children: [
          // Filter & Summary Header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppConstants.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppConstants.softBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: AppConstants.deepEmerald, size: 20),
                const SizedBox(width: 8),
                const Text('Filter:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConstants.charcoal)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedEmployeeFilter,
                      isExpanded: true,
                      hint: const Text('All Staff Members', style: TextStyle(color: AppConstants.textMuted, fontSize: 13)),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Staff Members', style: TextStyle(color: AppConstants.charcoal, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        ..._employees.map((e) => DropdownMenuItem<String?>(
                              value: e.id,
                              child: Text(e.name, style: const TextStyle(color: AppConstants.charcoal, fontSize: 13)),
                            )),
                      ],
                      onChanged: (val) => setState(() => _selectedEmployeeFilter = val),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Leave Cards List
          Expanded(
            child: _isLoadingLeaves
                ? const Center(child: CircularProgressIndicator(color: AppConstants.deepEmerald))
                : filteredLeaves.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.beach_access_outlined, size: 48, color: AppConstants.textMuted.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            const Text('No leave records found', style: TextStyle(color: AppConstants.textMuted, fontSize: 14)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.deepEmerald,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _showApplyLeaveModal,
                              icon: const Icon(Icons.add, color: Colors.white, size: 18),
                              label: const Text('APPLY FIRST LEAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredLeaves.length,
                        itemBuilder: (ctx, idx) {
                          final leave = filteredLeaves[idx];
                          final isCasual = leave.leaveType.toLowerCase() == 'casual';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppConstants.surfaceWhite,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppConstants.softBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: isCasual ? AppConstants.softGreenChip : AppConstants.softRedChip,
                                          child: Icon(
                                            isCasual ? Icons.event_available : Icons.medical_services_outlined,
                                            size: 16,
                                            color: isCasual ? AppConstants.deepEmerald : AppConstants.alertRed,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          leave.employeeName,
                                          style: const TextStyle(
                                            color: AppConstants.charcoal,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppConstants.softGreenChip,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        leave.status.toUpperCase(),
                                        style: const TextStyle(
                                          color: AppConstants.deepEmerald,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isCasual
                                            ? AppConstants.deepEmerald.withValues(alpha: 0.08)
                                            : AppConstants.alertRed.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${isCasual ? "Casual" : "Sick"} Leave',
                                        style: TextStyle(
                                          color: isCasual ? AppConstants.deepEmerald : AppConstants.alertRed,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${leave.startDate} → ${leave.endDate} (${leave.daysRequested} ${leave.daysRequested == 1 ? "day" : "days"})',
                                      style: const TextStyle(
                                        color: AppConstants.charcoal,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (leave.reason.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Reason: "${leave.reason}"',
                                    style: const TextStyle(
                                      color: AppConstants.textMuted,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
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
