part of 'company_bloc.dart';

abstract class CompanyState extends Equatable {
  const CompanyState();

  @override
  List<Object?> get props => [];
}

class CompanyInitial extends CompanyState {}

class CompanyLoading extends CompanyState {}

class CompanyLoaded extends CompanyState {
  final List<Company> companies;

  const CompanyLoaded({required this.companies});

  List<Company> get activeCompanies =>
      companies.where((c) => c.isActive).toList();

  List<Company> get inactiveCompanies =>
      companies.where((c) => !c.isActive).toList();

  CompanyLoaded copyWith({List<Company>? companies}) {
    return CompanyLoaded(companies: companies ?? this.companies);
  }

  @override
  List<Object?> get props => [companies];
}

class CompanyError extends CompanyState {
  final String message;

  const CompanyError({required this.message});

  @override
  List<Object?> get props => [message];
}
