import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:injectable/injectable.dart';

import '../../../core/models/user_model.dart';
import '../../../core/models/user_company_model.dart';
import '../../../core/models/company_model.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/repositories/company_repository.dart';
import '../../../core/services/local_storage_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final UserRepository _userRepository;
  final CompanyRepository _companyRepository;
  final LocalStorageService _localStorage;

  AuthBloc(
    this._firebaseAuth,
    this._userRepository,
    this._companyRepository,
    this._localStorage,
  ) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthCompanyLoginRequested>(_onCompanyLoginRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthCompanySignUpRequested>(_onCompanySignUpRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSwitchCompanyRequested>(_onSwitchCompanyRequested);
    on<AuthRefreshUserRequested>(_onRefreshUserRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser == null) {
        emit(AuthUnauthenticated());
        return;
      }

      // Get user data from Firestore
      final userResult = await _userRepository.getUserById(firebaseUser.uid);

      if (userResult.isLeft()) {
        emit(AuthUnauthenticated());
        return;
      }

      final user =
          userResult.getOrElse(() => throw Exception('User not found'));

      // Get user's companies
      final companiesResult = await _userRepository.getUserCompanies(user.id);

      final userCompanies = companiesResult.isRight()
          ? companiesResult.getOrElse(() => [])
          : <UserCompany>[];

      // Get current company
      Company? currentCompany;
      UserCompany? currentUserCompany;

      if (user.currentCompanyId != null) {
        final companyResult =
            await _companyRepository.getCompanyById(user.currentCompanyId!);
        if (companyResult.isRight()) {
          currentCompany = companyResult.getOrElse(() => throw Exception());
        }

        currentUserCompany = userCompanies.firstWhere(
          (uc) => uc.companyId == user.currentCompanyId,
          orElse: () => userCompanies.isNotEmpty
              ? userCompanies.first
              : throw Exception(),
        );
      } else if (userCompanies.isNotEmpty) {
        // Set first company as current
        final primaryCompany = userCompanies.firstWhere(
          (uc) => uc.isPrimary,
          orElse: () => userCompanies.first,
        );

        currentUserCompany = primaryCompany;
        final companyResult =
            await _companyRepository.getCompanyById(primaryCompany.companyId);
        if (companyResult.isRight()) {
          currentCompany = companyResult.getOrElse(() => throw Exception());
        }
      }

      emit(AuthAuthenticated(
        user: user,
        currentCompany: currentCompany,
        currentUserCompany: currentUserCompany,
        userCompanies: userCompanies,
      ));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      if (credential.user == null) {
        emit(const AuthError(message: 'Login failed'));
        return;
      }

      add(AuthCheckRequested());
    } on firebase_auth.FirebaseAuthException catch (e) {
      emit(AuthError(message: _getAuthErrorMessage(e.code)));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onCompanyLoginRequested(
    AuthCompanyLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // First validate company code
      final companyResult =
          await _companyRepository.getCompanyByCode(event.companyCode);

      if (companyResult.isLeft()) {
        emit(const AuthError(message: 'Invalid company code'));
        return;
      }

      final company = companyResult.getOrElse(() => throw Exception());

      if (!company.isActive) {
        emit(const AuthError(message: 'This company is currently inactive'));
        return;
      }

      // Now login
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      if (credential.user == null) {
        emit(const AuthError(message: 'Login failed'));
        return;
      }

      // Verify user belongs to this company
      final userCompaniesResult =
          await _userRepository.getUserCompanies(credential.user!.uid);

      if (userCompaniesResult.isLeft()) {
        await _firebaseAuth.signOut();
        emit(const AuthError(message: 'Failed to verify company membership'));
        return;
      }

      final userCompanies = userCompaniesResult.getOrElse(() => []);
      final userCompany = userCompanies.firstWhere(
        (uc) => uc.companyId == company.id,
        orElse: () => throw Exception('Not a member'),
      );

      // Update user's current company
      await _userRepository.setPrimaryCompany(
          credential.user!.uid, company.id!);

      add(AuthCheckRequested());
    } on firebase_auth.FirebaseAuthException catch (e) {
      emit(AuthError(message: _getAuthErrorMessage(e.code)));
    } catch (e) {
      if (e.toString().contains('Not a member')) {
        emit(const AuthError(message: 'You are not a member of this company'));
      } else {
        emit(AuthError(message: e.toString()));
      }
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      if (credential.user == null) {
        emit(const AuthError(message: 'Registration failed'));
        return;
      }

      // Create user profile
      final now = DateTime.now();
      final user = User(
        id: credential.user!.uid,
        email: event.email.toLowerCase(),
        name: event.name,
        phone: event.phone,
        isActive: true,
        isSuperAdmin: false,
        createdAt: now,
        updatedAt: now,
      );

      await _userRepository.createUser(user);

      add(AuthCheckRequested());
    } on firebase_auth.FirebaseAuthException catch (e) {
      emit(AuthError(message: _getAuthErrorMessage(e.code)));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onCompanySignUpRequested(
    AuthCompanySignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // Create Firebase user
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: event.adminEmail,
        password: event.password,
      );

      if (credential.user == null) {
        emit(const AuthError(message: 'Registration failed'));
        return;
      }

      // Generate unique company code
      final codeResult = await _companyRepository.generateUniqueCompanyCode();
      if (codeResult.isLeft()) {
        throw Exception('Failed to generate company code');
      }
      final companyCode = codeResult.getOrElse(() => '');

      // Create company
      final now = DateTime.now();
      final company = Company(
        id: '', // Will be set by Firestore
        name: event.companyName,
        companyCode: companyCode,
        companyType: 'business',
        email: event.adminEmail,
        phone: event.phone,
        isActive: true,
        enabledFeatures: {
          'leads': true,
          'call_logs': true,
          'targets': true,
          'tickets': true,
          'dynamic_forms': true,
        },
        createdAt: now,
        updatedAt: now,
      );

      final companyResult = await _companyRepository.createCompany(company);
      if (companyResult.isLeft()) {
        throw Exception('Failed to create company');
      }
      final createdCompany = companyResult.getOrElse(() => throw Exception());

      // Create admin user
      final user = User(
        id: credential.user!.uid,
        email: event.adminEmail.toLowerCase(),
        name: event.adminName,
        phone: event.phone,
        isActive: true,
        isSuperAdmin: false,
        currentCompanyId: createdCompany.id,
        companyIds: [createdCompany.id],
        createdAt: now,
        updatedAt: now,
      );

      await _userRepository.createUser(user);

      // Create user-company association with admin role
      final userCompany = UserCompany(
        id: '', // Will be set by Firestore
        userId: credential.user!.uid,
        companyId: createdCompany.id,
        roleId: 'company_admin', // Predefined role
        permissions: [
          'manage_users',
          'manage_leads',
          'manage_statuses',
          'manage_departments',
          'manage_forms',
          'manage_targets',
          'view_reports',
          'manage_company_settings',
        ],
        isPrimary: true,
        isActive: true,
        joinedAt: now,
        updatedAt: now,
      );

      await _userRepository.addUserToCompany(userCompany);

      add(AuthCheckRequested());
    } on firebase_auth.FirebaseAuthException catch (e) {
      emit(AuthError(message: _getAuthErrorMessage(e.code)));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _firebaseAuth.signOut();
      await _localStorage.clearAll();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onSwitchCompanyRequested(
    AuthSwitchCompanyRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;

    emit(AuthLoading());

    try {
      // Update user's current company
      await _userRepository.setPrimaryCompany(
        currentState.user.id,
        event.companyId,
      );

      add(AuthCheckRequested());
    } catch (e) {
      emit(AuthError(message: e.toString()));
      emit(currentState);
    }
  }

  Future<void> _onRefreshUserRequested(
    AuthRefreshUserRequested event,
    Emitter<AuthState> emit,
  ) async {
    add(AuthCheckRequested());
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      default:
        return 'Authentication failed. Please try again';
    }
  }
}
