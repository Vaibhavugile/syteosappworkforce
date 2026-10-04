import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

class TeamService {
  TeamService._();

  static final TeamService instance = TeamService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>
      get _usersCollection =>
          _firestore.collection('users');

  String get currentUserUid {
    final uid = _auth.currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      throw StateError(
        'No authenticated user found.',
      );
    }

    return uid;
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  Future<AppUser?> getCurrentUser() async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return null;
    }

    return getEmployee(uid);
  }

  // ============================================================
  // GET ONE EMPLOYEE
  // ============================================================

  Future<AppUser?> getEmployee(
    String userId,
  ) async {
    final document =
        await _usersCollection.doc(userId).get();

    if (!document.exists) {
      return null;
    }

    final data = document.data();

    if (data == null) {
      return null;
    }

    return AppUser.fromMap(
      document.id,
      data,
    );
  }

  // ============================================================
  // WATCH ONE EMPLOYEE
  // ============================================================

  Stream<AppUser?> watchEmployee(
    String userId,
  ) {
    return _usersCollection
        .doc(userId)
        .snapshots()
        .map((document) {
      if (!document.exists) {
        return null;
      }

      final data = document.data();

      if (data == null) {
        return null;
      }

      return AppUser.fromMap(
        document.id,
        data,
      );
    });
  }

  // ============================================================
  // GET ALL EMPLOYEES
  // ============================================================

  Future<List<AppUser>> getAllEmployees() async {
    final snapshot =
        await _usersCollection.get();

    return snapshot.docs
        .map(
          (document) => AppUser.fromMap(
            document.id,
            document.data(),
          ),
        )
        .toList();
  }

  // ============================================================
  // WATCH ALL EMPLOYEES
  // ============================================================

  Stream<List<AppUser>> watchAllEmployees() {
    return _usersCollection
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) =>
                    AppUser.fromMap(
                  document.id,
                  document.data(),
                ),
              )
              .toList(),
        );
  }

  // ============================================================
  // ACTIVE EMPLOYEES
  // ============================================================

  Future<List<AppUser>>
      getActiveEmployees() async {
    final snapshot = await _usersCollection
        .where(
          'isActive',
          isEqualTo: true,
        )
        .get();

    final employees = snapshot.docs
        .map(
          (document) => AppUser.fromMap(
            document.id,
            document.data(),
          ),
        )
        .toList();

    employees.sort(
      (a, b) => a.name
          .toLowerCase()
          .compareTo(
            b.name.toLowerCase(),
          ),
    );

    return employees;
  }

  Stream<List<AppUser>>
      watchActiveEmployees() {
    return _usersCollection
        .where(
          'isActive',
          isEqualTo: true,
        )
        .snapshots()
        .map(
          (snapshot) {
            final employees = snapshot.docs
                .map(
                  (document) =>
                      AppUser.fromMap(
                    document.id,
                    document.data(),
                  ),
                )
                .toList();

            employees.sort(
              (a, b) => a.name
                  .toLowerCase()
                  .compareTo(
                    b.name.toLowerCase(),
                  ),
            );

            return employees;
          },
        );
  }

  // ============================================================
  // INACTIVE EMPLOYEES
  // ============================================================

  Future<List<AppUser>>
      getInactiveEmployees() async {
    final snapshot = await _usersCollection
        .where(
          'isActive',
          isEqualTo: false,
        )
        .get();

    final employees = snapshot.docs
        .map(
          (document) => AppUser.fromMap(
            document.id,
            document.data(),
          ),
        )
        .toList();

    employees.sort(
      (a, b) => a.name
          .toLowerCase()
          .compareTo(
            b.name.toLowerCase(),
          ),
    );

    return employees;
  }

  // ============================================================
  // BY ROLE
  // ============================================================

  Future<List<AppUser>>
      getEmployeesByRole(
    UserRole role,
  ) async {
    final snapshot = await _usersCollection
        .where(
          'role',
          isEqualTo: role.name,
        )
        .get();

    final employees = snapshot.docs
        .map(
          (document) => AppUser.fromMap(
            document.id,
            document.data(),
          ),
        )
        .toList();

    employees.sort(
      (a, b) => a.name
          .toLowerCase()
          .compareTo(
            b.name.toLowerCase(),
          ),
    );

    return employees;
  }

  Stream<List<AppUser>>
      watchEmployeesByRole(
    UserRole role,
  ) {
    return _usersCollection
        .where(
          'role',
          isEqualTo: role.name,
        )
        .snapshots()
        .map(
          (snapshot) {
            final employees = snapshot.docs
                .map(
                  (document) =>
                      AppUser.fromMap(
                    document.id,
                    document.data(),
                  ),
                )
                .toList();

            employees.sort(
              (a, b) => a.name
                  .toLowerCase()
                  .compareTo(
                    b.name.toLowerCase(),
                  ),
            );

            return employees;
          },
        );
  }

  // ============================================================
  // EMPLOYEE COUNTS
  // ============================================================

  Future<int> getTotalEmployeeCount() async {
    final snapshot =
        await _usersCollection.get();

    return snapshot.size;
  }

  Future<int> getActiveEmployeeCount() async {
    final snapshot = await _usersCollection
        .where(
          'isActive',
          isEqualTo: true,
        )
        .get();

    return snapshot.size;
  }

  Future<int> getInactiveEmployeeCount() async {
    final snapshot = await _usersCollection
        .where(
          'isActive',
          isEqualTo: false,
        )
        .get();

    return snapshot.size;
  }

  // ============================================================
  // ROLE COUNTS
  // ============================================================

  Future<int> getRoleCount(
    UserRole role,
  ) async {
    final snapshot = await _usersCollection
        .where(
          'role',
          isEqualTo: role.name,
        )
        .get();

    return snapshot.size;
  }

  // ============================================================
  // UPDATE EMPLOYEE PROFILE
  // ============================================================

  Future<void> updateEmployee({
    required String userId,
    String? name,
    String? phone,
    String? email,
    String? profileImage,
  }) async {
    final updates =
        <String, dynamic>{
      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    if (name != null) {
      updates['name'] = name.trim();
    }

    if (phone != null) {
      updates['phone'] = phone.trim();
    }

    if (email != null) {
      updates['email'] = email.trim();
    }

    if (profileImage != null) {
      updates['profileImage'] =
          profileImage;
    }

    await _usersCollection
        .doc(userId)
        .update(updates);
  }

  // ============================================================
  // CHANGE ROLE
  // ============================================================

  Future<void> updateEmployeeRole({
    required String userId,
    required UserRole role,
  }) async {
    await _usersCollection
        .doc(userId)
        .update({
      'role': role.name,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // ACTIVATE / DEACTIVATE
  // ============================================================

  Future<void> setEmployeeActive({
    required String userId,
    required bool isActive,
  }) async {
    await _usersCollection
        .doc(userId)
        .update({
      'isActive': isActive,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> activateEmployee(
    String userId,
  ) async {
    await setEmployeeActive(
      userId: userId,
      isActive: true,
    );
  }

  Future<void> deactivateEmployee(
    String userId,
  ) async {
    await setEmployeeActive(
      userId: userId,
      isActive: false,
    );
  }

  // ============================================================
  // SEARCH EMPLOYEES
  // ============================================================

  Future<List<AppUser>> searchEmployees(
    String query,
  ) async {
    final normalized =
        query.trim().toLowerCase();

    if (normalized.isEmpty) {
      return getAllEmployees();
    }

    final employees =
        await getAllEmployees();

    return employees.where((employee) {
      final name =
          employee.name.toLowerCase();

      final email =
          employee.email.toLowerCase();

      final phone =
          employee.phone.toLowerCase();

      final role =
          employee.role.name.toLowerCase();

      return name.contains(normalized) ||
          email.contains(normalized) ||
          phone.contains(normalized) ||
          role.contains(normalized);
    }).toList();
  }

  // ============================================================
  // ROLE LABEL
  // ============================================================

  String roleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';

      case UserRole.callingExecutive:
        return 'Calling Executive';

      case UserRole.salesExecutive:
        return 'Sales Executive';

      case UserRole.ceo:
        return 'CEO';

      case UserRole.cto:
        return 'CTO';

      case UserRole.teamMember:
        return 'Team Member';
    }
  }
}