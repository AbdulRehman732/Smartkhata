class Employee {
  final String id;
  final String name;
  final String roleTitle;
  final String salaryType; // monthly, daily
  final double salaryRate;
  final String phone;
  final bool active;
  final String? userAccountId;
  final String updatedAt;

  Employee({
    required this.id,
    required this.name,
    required this.roleTitle,
    required this.salaryType,
    required this.salaryRate,
    required this.phone,
    this.active = true,
    this.userAccountId,
    required this.updatedAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      roleTitle: json['role_title'] ?? 'Helper',
      salaryType: json['salary_type'] ?? 'monthly',
      salaryRate: (json['salary_rate'] as num?)?.toDouble() ?? 0.0,
      phone: json['phone'] ?? '',
      active: json['active'] ?? true,
      userAccountId: json['user_account_id'],
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role_title': roleTitle,
      'salary_type': salaryType,
      'salary_rate': salaryRate,
      'phone': phone,
      'active': active,
      'user_account_id': userAccountId,
      'updated_at': updatedAt,
    };
  }
}
