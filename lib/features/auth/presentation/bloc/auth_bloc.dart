import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../../core/error/app_error.dart';
import '../../../../core/models/company_model.dart';
import '../../../companies/data/repositories/company_repository.dart';
import '../../../user_management/data/repositories/user_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final UserRepository _userRepository;
  final CompanyRepository _companyRepository;

  AuthBloc(
    this._firebaseAuth,
    this._userRepository,
    this._companyRepository,
  ) : super(AuthInitial()) {
    on<AuthCheckStatusEvent>(_onCheckStatus);
    on<AuthLoginWithEmailEvent>(_onLoginWithEmail);
    on<AuthLoginWithCompanyCodeEvent>(_onLoginWithCompanyCode);
    on<AuthLogoutEvent>(_onLogout);
    on<AuthSwitchCompanyEvent>(_onSwitchCompany);
    on<AuthUpdateUserEvent>(_onUpdateUser);
    on<AuthResetPasswordEvent>(_onResetPassword);
  }

  Future<void> _onCheckStatus(
    AuthCheckStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser == null) {
        emit(AuthUnauthenticated());
        return;
      }

      final userResult = await _userRepository.getUserById(firebaseUser.uid);

      if (userResult.isLeft()) {
        emit(AuthUnauthenticated());
        return;
      }

      final user =
          userResult.getOrElse(() => throw Exception('User not found'));

      // Load user's companies
      final companiesResult = await _companyRepository.getUserCompanies(
        user.companyIds,
      );

      final companies = companiesResult.getOrElse(() => <Company>[]);

      // Super admins may have no companies
      if (companies.isEmpty) {
        emit(AuthAuthenticated(
          user: user,
          isSuperAdmin: user.isSuperAdmin,
        ));
        return;
      }

      final currentCompany = companies.firstWhere(
        (c) => c.id == user.currentCompanyId,
        orElse: () => companies.first,
      );

      emit(AuthAuthenticated(
        user: user,
        currentCompany: currentCompany,
        userCompanies: companies,
        isSuperAdmin: user.isSuperAdmin,
      ));
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginWithEmail(
    AuthLoginWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        emit(const AuthError(
            AppError.authenticationError(message: 'Login failed')));
        return;
      }

      final userResult = await _userRepository.getUserById(firebaseUser.uid);

      if (userResult.isLeft()) {
        final error = userResult.fold((l) => l, (r) => null);
        emit(AuthError(
            error ?? AppError.serverError(message: 'User not found')));
        return;
      }

      final user =
          userResult.getOrElse(() => throw Exception('User not found'));

      // Load user's companies
      final companiesResult = await _companyRepository.getUserCompanies(
        user.companyIds,
      );

      final companies = companiesResult.getOrElse(() => <Company>[]);

      final currentCompany = companies.isNotEmpty
          ? companies.firstWhere(
              (c) => c.id == user.currentCompanyId,
              orElse: () => companies.first,
            )
          : null;

      emit(AuthAuthenticated(
        user: user,
        currentCompany: currentCompany,
        userCompanies: companies,
        isSuperAdmin: user.isSuperAdmin,
      ));
    } on firebase_auth.FirebaseAuthException catch (e) {
      emit(AuthError(
          AppError.authenticationError(message: e.message ?? 'Login failed')));
    } catch (e) {
      emit(AuthError(AppError.serverError(message: e.toString())));
    }
  }

  Future<void> _onLoginWithCompanyCode(
    AuthLoginWithCompanyCodeEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // Validate company code first
      final companyResult = await _companyRepository.getCompanyByCode(
        event.companyCode,
      );

      if (companyResult.isLeft()) {
        final error = companyResult.fold((l) => l, (r) => null);
        emit(AuthError(
            error ?? AppError.notFoundError(message: 'Invalid company code')));
        return;
      }

      final company =
          companyResult.getOrElse(() => throw Exception('Company not found'));

      // Login with Firebase
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        emit(const AuthError(
            AppError.authenticationError(message: 'Login failed')));
        return;
      }

      final userResult = await _userRepository.getUserById(firebaseUser.uid);

      if (userResult.isLeft()) {
        final error = userResult.fold((l) => l, (r) => null);
        emit(AuthError(
            error ?? AppError.serverError(message: 'User not found')));
        return;
      }

      final user =
          userResult.getOrElse(() => throw Exception('User not found'));

      // Verify user belongs to this company
      if (!user.companyIds.contains(company.id)) {
        await _firebaseAuth.signOut();
        emit(const AuthError(
          AppError.authenticationError(
              message: 'You do not belong to this company'),
        ));
        return;
      }

      // Update current company if different
      if (user.currentCompanyId != company.id) {
        await _userRepository.switchCompany(
          user.id,
          company.id,
          user.currentRoleId ?? '',
          user.currentDepartmentId ?? '',
        );
      }

      // Load all user companies
      final companiesResult = await _companyRepository.getUserCompanies(
        user.companyIds,
      );

      final companies = companiesResult.getOrElse(() => <Company>[]);

      emit(AuthAuthenticated(
        user: user.copyWith(currentCompanyId: company.id),
        currentCompany: company,
        userCompanies: companies,
        isSuperAdmin: user.isSuperAdmin,
      ));
    } on firebase_auth.FirebaseAuthException catch (e) {
      emit(AuthError(
          AppError.authenticationError(message: e.message ?? 'Login failed')));
    } catch (e) {
      emit(AuthError(AppError.serverError(message: e.toString())));
    }
  }

  Future<void> _onLogout(
    AuthLogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await _firebaseAuth.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(AppError.serverError(message: 'Logout failed')));
    }
  }

  Future<void> _onSwitchCompany(
    AuthSwitchCompanyEvent event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;

    emit(AuthLoading());

    try {
      // Check if switching back to super admin view (empty company)
      if (event.companyId.isEmpty) {
        final updatedUser = currentState.user.copyWith(
          currentCompanyId: '',
          currentRoleId: 'super_admin',
          currentDepartmentId: '',
        );
        emit(AuthAuthenticated(
          user: updatedUser,
          currentCompany: null,
          userCompanies: currentState.userCompanies,
          isSuperAdmin: true,
          isCompanyAdmin: false,
        ));
        return;
      }

      // Try to find company in user's companies list first
      Company? targetCompany;
      try {
        targetCompany = currentState.userCompanies.firstWhere(
          (c) => c.id == event.companyId,
        );
      } catch (_) {
        // Company not in user's list - fetch from repository (for super admin)
        final companyResult =
            await _companyRepository.getCompanyById(event.companyId);
        companyResult.fold(
          (error) => throw Exception('Company not found'),
          (company) => targetCompany = company,
        );
      }

      if (targetCompany == null) {
        emit(AuthError(AppError.notFoundError(message: 'Company not found')));
        emit(currentState);
        return;
      }

      String roleId = '';
      String departmentId = '';

      // Get the UserCompany info for this company if user is not super admin
      if (!currentState.isSuperAdmin) {
        final userCompanyResult = await _userRepository.getUserCompany(
          currentState.user.id,
          event.companyId,
        );

        userCompanyResult.fold(
          (error) {
            // Use default values if we can't find the UserCompany
          },
          (userCompany) {
            roleId = userCompany.roleId;
            departmentId = userCompany.departmentId ?? '';
          },
        );

        await _userRepository.switchCompany(
          currentState.user.id,
          event.companyId,
          roleId,
          departmentId,
        );
      } else {
        // Super admin switching - use admin role for this company
        roleId = 'company_admin';
      }

      final updatedUser = currentState.user.copyWith(
        currentCompanyId: event.companyId,
        currentRoleId: roleId,
        currentDepartmentId: departmentId,
      );

      emit(AuthAuthenticated(
        user: updatedUser,
        currentCompany: targetCompany,
        userCompanies: currentState.userCompanies,
        isSuperAdmin: currentState.isSuperAdmin,
        isCompanyAdmin: roleId == 'company_admin',
      ));
    } catch (e) {
      emit(
          AuthError(AppError.serverError(message: 'Failed to switch company')));
      // Restore previous state
      emit(currentState);
    }
  }

  Future<void> _onUpdateUser(
    AuthUpdateUserEvent event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;

    try {
      await _userRepository.updateUser(event.user);
      emit(currentState.copyWith(user: event.user));
    } catch (e) {
      emit(AuthError(AppError.serverError(message: 'Failed to update user')));
      emit(currentState);
    }
  }

  Future<void> _onResetPassword(
    AuthResetPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: event.email);
      emit(AuthPasswordResetSent(event.email));
    } on firebase_auth.FirebaseAuthException catch (e) {
      emit(AuthError(AppError.authenticationError(
          message: e.message ?? 'Failed to send reset email')));
    } catch (e) {
      emit(AuthError(AppError.serverError(message: e.toString())));
    }
  }
}
