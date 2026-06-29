enum UserRole { parent, adviser, principal, ministrong_tagasubaybay, osd }

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? avatarUrl;
  
  // For advisers
  final String? assignedSection;
  
  // For verified parents
  final String? studentName;
  final String? studentGrade;
  final String? studentSection;
  final String? academicYear;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
    this.assignedSection,
    this.studentName,
    this.studentGrade,
    this.studentSection,
    this.academicYear,
  });

  String get roleString {
    switch (role) {
      case UserRole.parent:
        return 'Parent';
      case UserRole.adviser:
        return 'Adviser';
      case UserRole.principal:
        return 'Principal';
      case UserRole.ministrong_tagasubaybay:
        return 'Ministrong Tagasubaybay';
      case UserRole.osd:
        return 'OSD Officer';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'avatarUrl': avatarUrl,
      'assignedSection': assignedSection,
      'studentName': studentName,
      'studentGrade': studentGrade,
      'studentSection': studentSection,
      'academicYear': academicYear,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.parent,
      ),
      avatarUrl: json['avatarUrl'],
      assignedSection: json['assignedSection'],
      studentName: json['studentName'],
      studentGrade: json['studentGrade'],
      studentSection: json['studentSection'],
      academicYear: json['academicYear'],
    );
  }

  UserModel copyWith({
    String? name,
    String? avatarUrl,
    String? studentName,
    String? studentGrade,
    String? studentSection,
    String? academicYear,
  }) {
    return UserModel(
      id: id,
      email: email,
      name: name ?? this.name,
      role: role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      assignedSection: assignedSection,
      studentName: studentName ?? this.studentName,
      studentGrade: studentGrade ?? this.studentGrade,
      studentSection: studentSection ?? this.studentSection,
      academicYear: academicYear ?? this.academicYear,
    );
  }
}
