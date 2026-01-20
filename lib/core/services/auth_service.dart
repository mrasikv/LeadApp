import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../error/exceptions.dart';
import 'logger_service.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthService(this._firebaseAuth, this._firestore);

  // Get current Firebase user
  firebase_auth.User? get currentFirebaseUser => _firebaseAuth.currentUser;

  // Stream of auth state changes
  Stream<firebase_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  // Sign in with email & password
  Future<User> signInWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw AuthenticationException('Sign in failed');
      }

      // Fetch user data from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw AuthenticationException('User data not found');
      }

      final userData = userDoc.data()!;
      userData['id'] = userDoc.id;

      return User.fromJson(userData);
    } on firebase_auth.FirebaseAuthException catch (e) {
      LoggerService.error('Sign in error', e);
      throw AuthenticationException(
        _getAuthErrorMessage(e.code),
        e.code,
      );
    } catch (e) {
      LoggerService.error('Unexpected sign in error', e);
      throw AuthenticationException('An unexpected error occurred');
    }
  }

  // Sign in with company code + email + password
  Future<User> signInWithCompanyCode({
    required String companyCode,
    required String email,
    required String password,
  }) async {
    try {
      // First, verify company code exists
      final companyQuery = await _firestore
          .collection('companies')
          .where('companyCode', isEqualTo: companyCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (companyQuery.docs.isEmpty) {
        throw AuthenticationException('Invalid company code');
      }

      final companyId = companyQuery.docs.first.id;

      // Sign in with email/password
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw AuthenticationException('Sign in failed');
      }

      // Fetch user and verify they belong to the company
      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw AuthenticationException('User data not found');
      }

      final userData = userDoc.data()!;
      
      if (userData['companyId'] != companyId) {
        await _firebaseAuth.signOut();
        throw AuthenticationException(
          'User does not belong to this company',
        );
      }

      if (userData['isActive'] != true) {
        await _firebaseAuth.signOut();
        throw AuthenticationException('User account is inactive');
      }

      userData['id'] = userDoc.id;

      // Update last login
      await _firestore.collection('users').doc(userDoc.id).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      return User.fromJson(userData);
    } on firebase_auth.FirebaseAuthException catch (e) {
      LoggerService.error('Sign in error', e);
      throw AuthenticationException(
        _getAuthErrorMessage(e.code),
        e.code,
      );
    } catch (e) {
      if (e is AuthenticationException) rethrow;
      LoggerService.error('Unexpected sign in error', e);
      throw AuthenticationException('An unexpected error occurred');
    }
  }

  // Create user with email & password (for Super Admin creating company admins)
  Future<User> createUser({
    required String email,
    required String password,
    required User userData,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw AuthenticationException('User creation failed');
      }

      // Create user document in Firestore
      final userDataMap = userData.copyWith(id: credential.user!.uid).toJson();
      
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userDataMap);

      return userData.copyWith(id: credential.user!.uid);
    } on firebase_auth.FirebaseAuthException catch (e) {
      LoggerService.error('Create user error', e);
      throw AuthenticationException(
        _getAuthErrorMessage(e.code),
        e.code,
      );
    } catch (e) {
      LoggerService.error('Unexpected create user error', e);
      throw AuthenticationException('An unexpected error occurred');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      LoggerService.error('Sign out error', e);
      throw AuthenticationException('Sign out failed');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      LoggerService.error('Reset password error', e);
      throw AuthenticationException(
        _getAuthErrorMessage(e.code),
        e.code,
      );
    }
  }

  // Get current user data from Firestore
  Future<User?> getCurrentUser() async {
    try {
      final firebaseUser = currentFirebaseUser;
      if (firebaseUser == null) return null;

      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;
      userData['id'] = userDoc.id;

      return User.fromJson(userData);
    } catch (e) {
      LoggerService.error('Get current user error', e);
      return null;
    }
  }

  // Set custom claims (called from backend)
  Future<void> refreshToken() async {
    try {
      await currentFirebaseUser?.getIdToken(true);
    } catch (e) {
      LoggerService.error('Refresh token error', e);
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      default:
        return 'Authentication failed';
    }
  }
}
