class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final String? department;
  final String? year;
  final bool isActive;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.department,
    this.year,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      role: json['role'],
      department: json['department'],
      year: json['year'],
      isActive: json['is_active'],
    );
  }

  String get roleDisplay {
    switch (role) {
      case 'super_admin': return 'Super Admin';
      case 'admin': return 'Admin';
      case 'hod': return 'HOD';
      case 'placement_cell': return 'Placement Cell';
      case 'club_coordinator': return 'Club Coordinator';
      case 'sports_coordinator': return 'Sports Coordinator';
      case 'student': return 'Student';
      default: return role;
    }
  }
}