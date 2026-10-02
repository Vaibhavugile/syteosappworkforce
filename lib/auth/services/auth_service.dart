import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/app_user.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges =>
      _auth.authStateChanges();

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final credential =
        await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw Exception(
        'Unable to create account.',
      );
    }

    final appUser = AppUser(
      id: firebaseUser.uid,
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: UserRole.salesExecutive,
      isActive: true,
    );

    await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .set({
      ...appUser.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return appUser;
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential =
        await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw Exception(
        'Unable to sign in.',
      );
    }

    final appUser =
        await getUserProfile(firebaseUser.uid);

    if (appUser == null) {
      await _auth.signOut();

      throw Exception(
        'User profile was not found.',
      );
    }

    if (!appUser.isActive) {
      await _auth.signOut();

      throw Exception(
        'Your account has been deactivated.',
      );
    }

    return appUser;
  }

  Future<AppUser?> getUserProfile(
    String uid,
  ) async {
    final document = await _firestore
        .collection('users')
        .doc(uid)
        .get();

    if (!document.exists ||
        document.data() == null) {
      return null;
    }

    return AppUser.fromMap(
      document.id,
      document.data()!,
    );
  }

  Future<AppUser?> getCurrentUserProfile() async {
    final firebaseUser = _auth.currentUser;

    if (firebaseUser == null) {
      return null;
    }

    return getUserProfile(firebaseUser.uid);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}