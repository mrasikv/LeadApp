part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthCompanyLoginRequested extends AuthEvent {
  final String companyCode;
  final String email;
  final String password;

  const AuthCompanyLoginRequested({
    required this.companyCode,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [companyCode, email, password];
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String? phone;

  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.name,
    this.phone,
  });

  @override
  List<Object?> get props => [email, password, name, phone];
}

class AuthCompanySignUpRequested extends AuthEvent {
  final String companyName;
  final String? industry;
  final String adminName;
  final String adminEmail;
  final String password;
  final String? phone;

  const AuthCompanySignUpRequested({
    required this.companyName,
    this.industry,
    required this.adminName,
    required this.adminEmail,
    required this.password,
    this.phone,
  });

  @override
  List<Object?> get props => [
        companyName,
        industry,
        adminName,
        adminEmail,
        password,
        phone,
      ];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthSwitchCompanyRequested extends AuthEvent {
  final String companyId;

  const AuthSwitchCompanyRequested({required this.companyId});

  @override
  List<Object?> get props => [companyId];
}

class AuthRefreshUserRequested extends AuthEvent {}
