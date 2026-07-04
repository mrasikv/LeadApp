import 'package:equatable/equatable.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/company_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  final Company? currentCompany;
  final List<Company> userCompanies;
  final bool isSuperAdmin;
  final bool isCompanyAdmin;

  const AuthAuthenticated({
    required this.user,
    this.currentCompany,
    this.userCompanies = const [],
    this.isSuperAdmin = false,
    this.isCompanyAdmin = false,
  });

  @override
  List<Object?> get props =>
      [user, currentCompany, userCompanies, isSuperAdmin, isCompanyAdmin];

  AuthAuthenticated copyWith({
    User? user,
    Company? currentCompany,
    List<Company>? userCompanies,
    bool? isSuperAdmin,
    bool? isCompanyAdmin,
  }) {
    return AuthAuthenticated(
      user: user ?? this.user,
      currentCompany: currentCompany ?? this.currentCompany,
      userCompanies: userCompanies ?? this.userCompanies,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      isCompanyAdmin: isCompanyAdmin ?? this.isCompanyAdmin,
    );
  }
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final AppError error;

  const AuthError(this.error);

  @override
  List<Object> get props => [error];
}

class AuthPasswordResetSent extends AuthState {
  final String email;

  const AuthPasswordResetSent(this.email);

  @override
  List<Object> get props => [email];
}
