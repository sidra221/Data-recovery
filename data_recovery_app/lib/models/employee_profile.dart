class EmployeeProfile {
  const EmployeeProfile({
    required this.username,
    required this.email,
    required this.phone,
    required this.role,
    required this.department,
    required this.photoUrl,
    this.userId,
    this.token,
  });

  final String username;
  final String email;
  final String phone;
  final String role;
  final String department;
  final String photoUrl;
  final int? userId;
  final String? token;

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    return EmployeeProfile(
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'IT Employee',
      department: json['department'] as String? ?? 'Data Recovery & Forensic Analysis',
      photoUrl: json['photo_url'] as String? ?? '',
      userId: json['user_id'] as int?,
      token: json['token'] as String?,
    );
  }
}
