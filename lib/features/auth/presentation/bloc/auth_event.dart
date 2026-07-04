import 'package:equatable/equatable.dart';
import '../../../../core/models/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckStatusEvent extends AuthEvent {}

class AuthLoginWithEmailEvent extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginWithEmailEvent(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

class AuthLoginWithCompanyCodeEvent extends AuthEvent {
  final String companyCode;
  final String email;
  final String password;

  const AuthLoginWithCompanyCodeEvent(
      this.companyCode, this.email, this.password);

  @override
  List<Object> get props => [companyCode, email, password];
}

class AuthLogoutEvent extends AuthEvent {}

class AuthSwitchCompanyEvent extends AuthEvent {
  final String companyId;

  const AuthSwitchCompanyEvent(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class AuthUpdateUserEvent extends AuthEvent {
  final User user;

  const AuthUpdateUserEvent(this.user);

  @override
  List<Object> get props => [user];
}

class AuthResetPasswordEvent extends AuthEvent {
  final String email;

  const AuthResetPasswordEvent(this.email);

  @override
  List<Object> get props => [email];
}
