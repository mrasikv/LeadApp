import 'package:equatable/equatable.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/models/company_model.dart';

abstract class CompanyState extends Equatable {
  const CompanyState();

  @override
  List<Object?> get props => [];
}

class CompanyInitial extends CompanyState {}

class CompanyLoading extends CompanyState {}

class CompanyLoaded extends CompanyState {
  final Company company;

  const CompanyLoaded(this.company);

  @override
  List<Object> get props => [company];
}

class CompaniesLoaded extends CompanyState {
  final List<Company> companies;

  const CompaniesLoaded(this.companies);

  @override
  List<Object> get props => [companies];
}

class CompanyCreated extends CompanyState {
  final Company company;

  const CompanyCreated(this.company);

  @override
  List<Object> get props => [company];
}

class CompanyUpdated extends CompanyState {}

class CompanyDeleted extends CompanyState {}

class CompanyError extends CompanyState {
  final AppError error;

  const CompanyError(this.error);

  @override
  List<Object> get props => [error];
}
