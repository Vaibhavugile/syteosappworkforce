enum UserRole {
  admin,
  callingExecutive,
  salesExecutive,
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? profileImage;
  final bool isActive;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profileImage,
    this.isActive = true,
  });

  factory AppUser.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return AppUser(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: _roleFromString(data['role']),
      profileImage: data['profileImage'],
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'profileImage': profileImage,
      'isActive': isActive,
    };
  }

  static UserRole _roleFromString(String? value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;

      case 'callingExecutive':
        return UserRole.callingExecutive;

      case 'salesExecutive':
      default:
        return UserRole.salesExecutive;
    }
  }
}