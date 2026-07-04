import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/lead_repository.dart';
import 'lead_event.dart';
import 'lead_state.dart';
import '../../../../core/models/lead_model.dart';

class LeadBloc extends Bloc<LeadEvent, LeadState> {
  final LeadRepository _repository;
  StreamSubscription? _leadsSubscription;
  List<Lead> _allLeads = [];

  LeadBloc(this._repository) : super(LeadInitial()) {
    on<LoadLeadsEvent>(_onLoadLeads);
    on<LoadLeadEvent>(_onLoadLead);
    on<LoadLeadsByStatusEvent>(_onLoadLeadsByStatus);
    on<LoadLeadsByProjectEvent>(_onLoadLeadsByProject);
    on<LoadLeadsByAssigneeEvent>(_onLoadLeadsByAssignee);
    on<CreateLeadEvent>(_onCreateLead);
    on<UpdateLeadEvent>(_onUpdateLead);
    on<DeleteLeadEvent>(_onDeleteLead);
    on<AssignLeadEvent>(_onAssignLead);
    on<ChangeLeadStatusEvent>(_onChangeLeadStatus);
    on<WatchLeadsEvent>(_onWatchLeads);
    on<SearchLeadsEvent>(_onSearchLeads);
    on<FilterLeadsEvent>(_onFilterLeads);
  }

  Future<void> _onLoadLeads(
    LoadLeadsEvent event,
    Emitter<LeadState> emit,
  ) async {
    emit(LeadLoading());

    final result = await _repository.getLeads(event.companyId);

    result.fold(
      (error) => emit(LeadError(error)),
      (leads) {
        _allLeads = leads;
        emit(LeadsLoaded(leads));
      },
    );
  }

  Future<void> _onLoadLead(
    LoadLeadEvent event,
    Emitter<LeadState> emit,
  ) async {
    emit(LeadLoading());

    final result = await _repository.getLeadById(event.leadId);

    result.fold(
      (error) => emit(LeadError(error)),
      (lead) => emit(LeadLoaded(lead)),
    );
  }

  Future<void> _onLoadLeadsByStatus(
    LoadLeadsByStatusEvent event,
    Emitter<LeadState> emit,
  ) async {
    emit(LeadLoading());

    final result = await _repository.getLeadsByStatus(
      event.companyId,
      event.statusId,
    );

    result.fold(
      (error) => emit(LeadError(error)),
      (leads) => emit(LeadsLoaded(leads)),
    );
  }

  Future<void> _onLoadLeadsByProject(
    LoadLeadsByProjectEvent event,
    Emitter<LeadState> emit,
  ) async {
    emit(LeadLoading());

    final result = await _repository.getLeadsByProject(event.projectId);

    result.fold(
      (error) => emit(LeadError(error)),
      (leads) {
        _allLeads = leads;
        emit(LeadsLoaded(leads));
      },
    );
  }

  Future<void> _onLoadLeadsByAssignee(
    LoadLeadsByAssigneeEvent event,
    Emitter<LeadState> emit,
  ) async {
    emit(LeadLoading());

    final result = await _repository.getLeadsByAssignee(
      event.companyId,
      event.userId,
    );

    result.fold(
      (error) => emit(LeadError(error)),
      (leads) => emit(LeadsLoaded(leads)),
    );
  }

  Future<void> _onCreateLead(
    CreateLeadEvent event,
    Emitter<LeadState> emit,
  ) async {
    emit(LeadLoading());

    final result = await _repository.createLead(event.lead);

    result.fold(
      (error) => emit(LeadError(error)),
      (lead) => emit(LeadCreated(lead)),
    );
  }

  Future<void> _onUpdateLead(
    UpdateLeadEvent event,
    Emitter<LeadState> emit,
  ) async {
    emit(LeadLoading());

    final result = await _repository.updateLead(event.lead);

    result.fold(
      (error) => emit(LeadError(error)),
      (_) => emit(LeadUpdated()),
    );
  }

  Future<void> _onDeleteLead(
    DeleteLeadEvent event,
    Emitter<LeadState> emit,
  ) async {
    emit(LeadLoading());

    final result = await _repository.deleteLead(event.leadId);

    result.fold(
      (error) => emit(LeadError(error)),
      (_) => emit(LeadDeleted()),
    );
  }

  Future<void> _onAssignLead(
    AssignLeadEvent event,
    Emitter<LeadState> emit,
  ) async {
    emit(LeadLoading());

    final result = await _repository.assignLead(event.leadId, event.userId);

    result.fold(
      (error) => emit(LeadError(error)),
      (_) => emit(LeadAssigned()),
    );
  }

  Future<void> _onChangeLeadStatus(
    ChangeLeadStatusEvent event,
    Emitter<LeadState> emit,
  ) async {
    emit(LeadLoading());

    final result = await _repository.changeStatus(event.leadId, event.statusId);

    result.fold(
      (error) => emit(LeadError(error)),
      (_) => emit(LeadStatusChanged()),
    );
  }

  Future<void> _onWatchLeads(
    WatchLeadsEvent event,
    Emitter<LeadState> emit,
  ) async {
    await _leadsSubscription?.cancel();

    _leadsSubscription = _repository.watchLeads(event.companyId).listen(
      (leads) {
        _allLeads = leads;
        add(LoadLeadsEvent(event.companyId));
      },
    );
  }

  void _onSearchLeads(
    SearchLeadsEvent event,
    Emitter<LeadState> emit,
  ) {
    if (event.query.isEmpty) {
      emit(LeadsLoaded(_allLeads));
      return;
    }

    final query = event.query.toLowerCase();
    final filteredLeads = _allLeads.where((lead) {
      return lead.name.toLowerCase().contains(query) ||
          (lead.email?.toLowerCase().contains(query) ?? false) ||
          lead.phone.toLowerCase().contains(query) ||
          (lead.city?.toLowerCase().contains(query) ?? false);
    }).toList();

    emit(LeadsLoaded(_allLeads, filteredLeads: filteredLeads));
  }

  void _onFilterLeads(
    FilterLeadsEvent event,
    Emitter<LeadState> emit,
  ) {
    var filteredLeads = List<Lead>.from(_allLeads);

    if (event.statusId != null) {
      filteredLeads = filteredLeads
          .where((lead) => lead.statusId == event.statusId)
          .toList();
    }

    if (event.assigneeId != null) {
      filteredLeads = filteredLeads
          .where((lead) => lead.assignedTo == event.assigneeId)
          .toList();
    }

    if (event.fromDate != null) {
      filteredLeads = filteredLeads
          .where((lead) => lead.createdAt.isAfter(event.fromDate!))
          .toList();
    }

    if (event.toDate != null) {
      filteredLeads = filteredLeads
          .where((lead) => lead.createdAt.isBefore(event.toDate!))
          .toList();
    }

    emit(LeadsLoaded(_allLeads, filteredLeads: filteredLeads));
  }

  @override
  Future<void> close() {
    _leadsSubscription?.cancel();
    return super.close();
  }
}
