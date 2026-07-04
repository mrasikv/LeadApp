import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/company_repository.dart';
import 'company_event.dart';
import 'company_state.dart';

class CompanyBloc extends Bloc<CompanyEvent, CompanyState> {
  final CompanyRepository _repository;
  StreamSubscription? _companiesSubscription;

  CompanyBloc(this._repository) : super(CompanyInitial()) {
    on<LoadCompaniesEvent>(_onLoadCompanies);
    on<LoadCompanyEvent>(_onLoadCompany);
    on<LoadUserCompaniesEvent>(_onLoadUserCompanies);
    on<CreateCompanyEvent>(_onCreateCompany);
    on<UpdateCompanyEvent>(_onUpdateCompany);
    on<DeleteCompanyEvent>(_onDeleteCompany);
    on<WatchCompaniesEvent>(_onWatchCompanies);
  }

  Future<void> _onLoadCompanies(
    LoadCompaniesEvent event,
    Emitter<CompanyState> emit,
  ) async {
    emit(CompanyLoading());

    final result = await _repository.getAllCompanies();

    result.fold(
      (error) => emit(CompanyError(error)),
      (companies) => emit(CompaniesLoaded(companies)),
    );
  }

  Future<void> _onLoadCompany(
    LoadCompanyEvent event,
    Emitter<CompanyState> emit,
  ) async {
    emit(CompanyLoading());

    final result = await _repository.getCompanyById(event.companyId);

    result.fold(
      (error) => emit(CompanyError(error)),
      (company) => emit(CompanyLoaded(company)),
    );
  }

  Future<void> _onLoadUserCompanies(
    LoadUserCompaniesEvent event,
    Emitter<CompanyState> emit,
  ) async {
    emit(CompanyLoading());

    final result = await _repository.getUserCompanies(event.companyIds);

    result.fold(
      (error) => emit(CompanyError(error)),
      (companies) => emit(CompaniesLoaded(companies)),
    );
  }

  Future<void> _onCreateCompany(
    CreateCompanyEvent event,
    Emitter<CompanyState> emit,
  ) async {
    emit(CompanyLoading());

    final result = await _repository.createCompany(event.company);

    result.fold(
      (error) => emit(CompanyError(error)),
      (company) => emit(CompanyCreated(company)),
    );
  }

  Future<void> _onUpdateCompany(
    UpdateCompanyEvent event,
    Emitter<CompanyState> emit,
  ) async {
    emit(CompanyLoading());

    final result = await _repository.updateCompany(event.company);

    result.fold(
      (error) => emit(CompanyError(error)),
      (_) => emit(CompanyUpdated()),
    );
  }

  Future<void> _onDeleteCompany(
    DeleteCompanyEvent event,
    Emitter<CompanyState> emit,
  ) async {
    emit(CompanyLoading());

    final result = await _repository.deleteCompany(event.companyId);

    result.fold(
      (error) => emit(CompanyError(error)),
      (_) => emit(CompanyDeleted()),
    );
  }

  Future<void> _onWatchCompanies(
    WatchCompaniesEvent event,
    Emitter<CompanyState> emit,
  ) async {
    await _companiesSubscription?.cancel();

    _companiesSubscription = _repository.watchCompanies().listen(
          (companies) => add(LoadCompaniesEvent()),
        );
  }

  @override
  Future<void> close() {
    _companiesSubscription?.cancel();
    return super.close();
  }
}
