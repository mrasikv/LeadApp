import 'package:equatable/equatable.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/models/lead_model.dart';

abstract class LeadState extends Equatable {
  const LeadState();

  @override
  List<Object?> get props => [];
}

class LeadInitial extends LeadState {}

class LeadLoading extends LeadState {}

class LeadLoaded extends LeadState {
  final Lead lead;

  const LeadLoaded(this.lead);

  @override
  List<Object> get props => [lead];
}

class LeadsLoaded extends LeadState {
  final List<Lead> leads;
  final List<Lead>? filteredLeads;

  const LeadsLoaded(this.leads, {this.filteredLeads});

  List<Lead> get displayLeads => filteredLeads ?? leads;

  @override
  List<Object?> get props => [leads, filteredLeads];
}

class LeadCreated extends LeadState {
  final Lead lead;

  const LeadCreated(this.lead);

  @override
  List<Object> get props => [lead];
}

class LeadUpdated extends LeadState {}

class LeadDeleted extends LeadState {}

class LeadAssigned extends LeadState {}

class LeadStatusChanged extends LeadState {}

class LeadError extends LeadState {
  final AppError error;

  const LeadError(this.error);

  @override
  List<Object> get props => [error];
}
