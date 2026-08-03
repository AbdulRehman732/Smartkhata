class AttendanceRecord {
  final String id;
  final String employeeId;
  final String date;
  final String status; // present, absent, half_day, leave

  AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.status,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? json['_id'] ?? '',
      employeeId: json['employee_id'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? 'present',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'date': date,
      'status': status,
    };
  }
}
