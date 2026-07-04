part of 'company_bloc.dart';

abstract class CompanyEvent extends Equatable {
  const CompanyEvent();

  @override
  List<Object?> get props => [];
}

class CompaniesLoadRequested extends CompanyEvent {}

class CompanyCreateRequested extends CompanyEvent {
  final Company company;

  const CompanyCreateRequested({required this.company});

  @override
  List<Object?> get props => [company];
}

class CompanyUpdateRequested extends CompanyEvent {
  final Company company;

  const CompanyUpdateRequested({required this.company});

  @override
  List<Object?> get props => [company];
}

class CompanyDeleteRequested extends CompanyEvent {
  final String companyId;

  const CompanyDeleteRequested({required this.companyId});

  @override
  List<Object?> get props => [companyId];
}

class CompanyToggleStatusRequested extends CompanyEvent {
  final String companyId;
  final bool isActive;

  const CompanyToggleStatusRequested({
    required this.companyId,
    required this.isActive,
  });

  @override
  List<Object?> get props => [companyId, isActive];
}

class CompanyUpdateFeaturesRequested extends CompanyEvent {
  final String companyId;
  final Map<String, bool> features;

  const CompanyUpdateFeaturesRequested({
    required this.companyId,
    required this.features,
  });

  @override
  List<Object?> get props => [companyId, features];
}

class CompaniesUpdated extends CompanyEvent {
  final List<Company> companies;

  const CompaniesUpdated({required this.companies});

  @override
  List<Object?> get props => [companies];
}
