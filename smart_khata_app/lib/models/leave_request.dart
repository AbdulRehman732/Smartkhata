class LeaveRequest {
  final String id;
  final String employeeId;
  final String employeeName;
  final String leaveType; // casual, sick
  final String startDate;
  final String endDate;
  final int daysRequested;
  final String status; // approved, pending, rejected
  final String reason;
  final String createdAt;

  LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.daysRequested,
    required this.status,
    required this.reason,
    required this.createdAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] ?? json['_id'] ?? '',
      employeeId: json['employee_id'] ?? '',
      employeeName: json['employee_name'] ?? '',
      leaveType: json['leave_type'] ?? 'casual',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      daysRequested: (json['days_requested'] as num?)?.toInt() ?? 1,
      status: json['status'] ?? 'approved',
      reason: json['reason'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'leave_type': leaveType,
      'start_date': startDate,
      'end_date': endDate,
      'days_requested': daysRequested,
      'status': status,
      'reason': reason,
      'created_at': createdAt,
    };
  }
}
