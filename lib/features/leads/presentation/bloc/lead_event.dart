import 'package:equatable/equatable.dart';
import '../../../../core/models/lead_model.dart';

abstract class LeadEvent extends Equatable {
  const LeadEvent();

  @override
  List<Object?> get props => [];
}

class LoadLeadsEvent extends LeadEvent {
  final String companyId;

  const LoadLeadsEvent(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class LoadLeadEvent extends LeadEvent {
  final String leadId;

  const LoadLeadEvent(this.leadId);

  @override
  List<Object> get props => [leadId];
}

class LoadLeadsByStatusEvent extends LeadEvent {
  final String companyId;
  final String statusId;

  const LoadLeadsByStatusEvent(this.companyId, this.statusId);

  @override
  List<Object> get props => [companyId, statusId];
}

class LoadLeadsByProjectEvent extends LeadEvent {
  final String projectId;

  const LoadLeadsByProjectEvent(this.projectId);

  @override
  List<Object> get props => [projectId];
}

class LoadLeadsByAssigneeEvent extends LeadEvent {
  final String companyId;
  final String userId;

  const LoadLeadsByAssigneeEvent(this.companyId, this.userId);

  @override
  List<Object> get props => [companyId, userId];
}

class CreateLeadEvent extends LeadEvent {
  final Lead lead;

  const CreateLeadEvent(this.lead);

  @override
  List<Object> get props => [lead];
}

class UpdateLeadEvent extends LeadEvent {
  final Lead lead;

  const UpdateLeadEvent(this.lead);

  @override
  List<Object> get props => [lead];
}

class DeleteLeadEvent extends LeadEvent {
  final String leadId;

  const DeleteLeadEvent(this.leadId);

  @override
  List<Object> get props => [leadId];
}

class AssignLeadEvent extends LeadEvent {
  final String leadId;
  final String userId;

  const AssignLeadEvent(this.leadId, this.userId);

  @override
  List<Object> get props => [leadId, userId];
}

class ChangeLeadStatusEvent extends LeadEvent {
  final String leadId;
  final String statusId;

  const ChangeLeadStatusEvent(this.leadId, this.statusId);

  @override
  List<Object> get props => [leadId, statusId];
}

class WatchLeadsEvent extends LeadEvent {
  final String companyId;

  const WatchLeadsEvent(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class SearchLeadsEvent extends LeadEvent {
  final String query;

  const SearchLeadsEvent(this.query);

  @override
  List<Object> get props => [query];
}

class FilterLeadsEvent extends LeadEvent {
  final String? statusId;
  final String? assigneeId;
  final DateTime? fromDate;
  final DateTime? toDate;

  const FilterLeadsEvent({
    this.statusId,
    this.assigneeId,
    this.fromDate,
    this.toDate,
  });

  @override
  List<Object?> get props => [statusId, assigneeId, fromDate, toDate];
}
