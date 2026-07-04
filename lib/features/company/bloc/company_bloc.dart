import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/models/company_model.dart';
import '../../../core/repositories/company_repository.dart';
import '../../../core/repositories/lead_status_repository.dart';

part 'company_event.dart';
part 'company_state.dart';

@injectable
class CompanyBloc extends Bloc<CompanyEvent, CompanyState> {
  final CompanyRepository _companyRepository;
  final LeadStatusRepository _statusRepository;

  StreamSubscription? _companiesSubscription;

  CompanyBloc(
    this._companyRepository,
    this._statusRepository,
  ) : super(CompanyInitial()) {
    on<CompaniesLoadRequested>(_onLoadRequested);
    on<CompanyCreateRequested>(_onCreateRequested);
    on<CompanyUpdateRequested>(_onUpdateRequested);
    on<CompanyDeleteRequested>(_onDeleteRequested);
    on<CompanyToggleStatusRequested>(_onToggleStatusRequested);
    on<CompanyUpdateFeaturesRequested>(_onUpdateFeaturesRequested);
    on<CompaniesUpdated>(_onCompaniesUpdated);
  }

  Future<void> _onLoadRequested(
    CompaniesLoadRequested event,
    Emitter<CompanyState> emit,
  ) async {
    emit(CompanyLoading());

    try {
      _companiesSubscription?.cancel();
      _companiesSubscription =
          _companyRepository.watchAllCompanies().listen((result) {
        result.fold(
          (error) => add(const CompaniesUpdated(companies: [])),
          (companies) => add(CompaniesUpdated(companies: companies)),
        );
      });
    } catch (e) {
      emit(CompanyError(message: e.toString()));
    }
  }

  Future<void> _onCreateRequested(
    CompanyCreateRequested event,
    Emitter<CompanyState> emit,
  ) async {
    if (state is! CompanyLoaded) return;

    final currentState = state as CompanyLoaded;

    try {
      // Generate unique company code
      final codeResult = await _companyRepository.generateUniqueCompanyCode();
      if (codeResult.isLeft()) {
        emit(const CompanyError(message: 'Failed to generate company code'));
        emit(currentState);
        return;
      }

      final companyWithCode = event.company.copyWith(
        companyCode: codeResult.getOrElse(() => ''),
      );

      final result = await _companyRepository.createCompany(companyWithCode);

      await result.fold(
        (error) async {
          emit(const CompanyError(message: 'Failed to create company'));
          emit(currentState);
        },
        (company) async {
          // Initialize default statuses for the new company
          await _statusRepository.initializeDefaultStatuses(company.id!);

          emit(currentState.copyWith(
            companies: [...currentState.companies, company],
          ));
        },
      );
    } catch (e) {
      emit(CompanyError(message: e.toString()));
      emit(currentState);
    }
  }

  Future<void> _onUpdateRequested(
    CompanyUpdateRequested event,
    Emitter<CompanyState> emit,
  ) async {
    if (state is! CompanyLoaded) return;

    final currentState = state as CompanyLoaded;

    try {
      final result = await _companyRepository.updateCompany(event.company);

      result.fold(
        (error) {
          emit(const CompanyError(message: 'Failed to update company'));
          emit(currentState);
        },
        (_) {
          final updated = currentState.companies.map((c) {
            return c.id == event.company.id ? event.company : c;
          }).toList();
          emit(currentState.copyWith(companies: updated));
        },
      );
    } catch (e) {
      emit(CompanyError(message: e.toString()));
      emit(currentState);
    }
  }

  Future<void> _onDeleteRequested(
    CompanyDeleteRequested event,
    Emitter<CompanyState> emit,
  ) async {
    if (state is! CompanyLoaded) return;

    final currentState = state as CompanyLoaded;

    try {
      final result = await _companyRepository.deleteCompany(event.companyId);

      result.fold(
        (error) {
          emit(const CompanyError(message: 'Failed to delete company'));
          emit(currentState);
        },
        (_) {
          final updated = currentState.companies
              .where((c) => c.id != event.companyId)
              .toList();
          emit(currentState.copyWith(companies: updated));
        },
      );
    } catch (e) {
      emit(CompanyError(message: e.toString()));
      emit(currentState);
    }
  }

  Future<void> _onToggleStatusRequested(
    CompanyToggleStatusRequested event,
    Emitter<CompanyState> emit,
  ) async {
    if (state is! CompanyLoaded) return;

    final currentState = state as CompanyLoaded;

    try {
      await _companyRepository.toggleCompanyStatus(
        event.companyId,
        event.isActive,
      );
    } catch (e) {
      emit(CompanyError(message: e.toString()));
      emit(currentState);
    }
  }

  Future<void> _onUpdateFeaturesRequested(
    CompanyUpdateFeaturesRequested event,
    Emitter<CompanyState> emit,
  ) async {
    if (state is! CompanyLoaded) return;

    final currentState = state as CompanyLoaded;

    try {
      await _companyRepository.updateCompanyFeatures(
        event.companyId,
        event.features,
      );
    } catch (e) {
      emit(CompanyError(message: e.toString()));
      emit(currentState);
    }
  }

  void _onCompaniesUpdated(
    CompaniesUpdated event,
    Emitter<CompanyState> emit,
  ) {
    emit(CompanyLoaded(companies: event.companies));
  }

  @override
  Future<void> close() {
    _companiesSubscription?.cancel();
    return super.close();
  }
}
