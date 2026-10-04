import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  ceo,
  cto,
  admin,
  callingExecutive,
  salesExecutive,
  teamMember,
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? profileImage;
  final bool isActive;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profileImage,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  // ============================================================
  // FROM FIRESTORE
  // ============================================================

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
      createdAt: _dateFromValue(
        data['createdAt'],
      ),
      updatedAt: _dateFromValue(
        data['updatedAt'],
      ),
    );
  }

  // ============================================================
  // TO FIRESTORE
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'profileImage': profileImage,
      'isActive': isActive,
      'createdAt': createdAt == null
          ? null
          : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null
          ? null
          : Timestamp.fromDate(updatedAt!),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? profileImage,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImage:
          profileImage ?? this.profileImage,
      isActive:
          isActive ?? this.isActive,
      createdAt:
          createdAt ?? this.createdAt,
      updatedAt:
          updatedAt ?? this.updatedAt,
    );
  }

  // ============================================================
  // ROLE CONVERSION
  // ============================================================

  static UserRole _roleFromString(
    String? value,
  ) {
    switch (value) {
      case 'ceo':
        return UserRole.ceo;

      case 'cto':
        return UserRole.cto;

      case 'admin':
        return UserRole.admin;

      case 'callingExecutive':
        return UserRole.callingExecutive;

      case 'salesExecutive':
        return UserRole.salesExecutive;

      case 'teamMember':
        return UserRole.teamMember;

      // Existing users created before
      // the new role system remain Sales
      // Executives by default.
      default:
        return UserRole.salesExecutive;
    }
  }

  // ============================================================
  // DATE PARSER
  // ============================================================

  static DateTime? _dateFromValue(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  // ============================================================
  // ROLE LABEL
  // ============================================================

  String get roleLabel {
    switch (role) {
      case UserRole.ceo:
        return 'CEO';

      case UserRole.cto:
        return 'CTO';

      case UserRole.admin:
        return 'Admin';

      case UserRole.callingExecutive:
        return 'Calling Executive';

      case UserRole.salesExecutive:
        return 'Sales Executive';

      case UserRole.teamMember:
        return 'Team Member';
    }
  }

  // ============================================================
  // PERMISSIONS
  // ============================================================

  bool get isCEO {
    return role == UserRole.ceo;
  }

  bool get isCTO {
    return role == UserRole.cto;
  }

  bool get isAdmin {
    return role == UserRole.admin;
  }

  bool get isManagement {
    return isCEO || isCTO || isAdmin;
  }

  bool get canManageEmployees {
    return isCEO || isCTO || isAdmin;
  }

  bool get canCreateProjects {
    return isCEO || isCTO || isAdmin;
  }

  bool get canEditProjects {
    return isCEO || isCTO || isAdmin;
  }

  bool get canDeleteProjects {
    return isCEO || isCTO;
  }

  bool get canCreateTasks {
    return isCEO ||
        isCTO ||
        isAdmin ||
        role == UserRole.teamMember;
  }

  bool get canAssignTasks {
    return isCEO || isCTO || isAdmin;
  }

  bool get canReviewTasks {
    return isCEO || isCTO || isAdmin;
  }

  bool get canViewAllProjects {
    return isCEO || isCTO || isAdmin;
  }

  bool get canViewAllEmployees {
    return isCEO || isCTO || isAdmin;
  }

  bool get canViewReports {
    return isCEO || isCTO || isAdmin;
  }

  bool get canManageTeam {
    return isCEO || isCTO || isAdmin;
  }

  bool get canChangeRoles {
    return isCEO || isAdmin;
  }
}