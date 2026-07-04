part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  final Company? currentCompany;
  final UserCompany? currentUserCompany;
  final List<UserCompany> userCompanies;

  const AuthAuthenticated({
    required this.user,
    this.currentCompany,
    this.currentUserCompany,
    this.userCompanies = const [],
  });

  bool get isSuperAdmin => user.isSuperAdmin;

  bool get isCompanyAdmin {
    if (currentUserCompany == null) return false;
    return currentUserCompany!.roleId == 'company_admin' ||
        currentUserCompany!.permissions.contains('manage_company_settings');
  }

  bool get hasMultipleCompanies => userCompanies.length > 1;

  List<String> get currentPermissions => currentUserCompany?.permissions ?? [];

  bool hasPermission(String permission) {
    if (isSuperAdmin) return true;
    return currentPermissions.contains(permission);
  }

  @override
  List<Object?> get props => [
        user,
        currentCompany,
        currentUserCompany,
        userCompanies,
      ];
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
