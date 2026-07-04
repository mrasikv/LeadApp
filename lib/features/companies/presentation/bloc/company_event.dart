import 'package:equatable/equatable.dart';
import '../../../../core/models/company_model.dart';

abstract class CompanyEvent extends Equatable {
  const CompanyEvent();

  @override
  List<Object?> get props => [];
}

class LoadCompaniesEvent extends CompanyEvent {
  const LoadCompaniesEvent();
}

class LoadCompanyEvent extends CompanyEvent {
  final String companyId;

  const LoadCompanyEvent(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class LoadUserCompaniesEvent extends CompanyEvent {
  final List<String> companyIds;

  const LoadUserCompaniesEvent(this.companyIds);

  @override
  List<Object> get props => [companyIds];
}

class CreateCompanyEvent extends CompanyEvent {
  final Company company;

  const CreateCompanyEvent(this.company);

  @override
  List<Object> get props => [company];
}

class UpdateCompanyEvent extends CompanyEvent {
  final Company company;

  const UpdateCompanyEvent(this.company);

  @override
  List<Object> get props => [company];
}

class DeleteCompanyEvent extends CompanyEvent {
  final String companyId;

  const DeleteCompanyEvent(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class WatchCompaniesEvent extends CompanyEvent {}
