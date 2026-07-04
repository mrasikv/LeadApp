import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/project_type_repository.dart';
import 'project_type_event.dart';
import 'project_type_state.dart';
import '../../../../core/models/project_type_model.dart';

class ProjectTypeBloc extends Bloc<ProjectTypeEvent, ProjectTypeState> {
  final ProjectTypeRepository _repository;
  StreamSubscription? _typesSubscription;
  List<ProjectType> _allTypes = [];

  ProjectTypeBloc(this._repository) : super(ProjectTypeInitial()) {
    on<LoadProjectTypesEvent>(_onLoadProjectTypes);
    on<LoadProjectTypeEvent>(_onLoadProjectType);
    on<WatchProjectTypesEvent>(_onWatchProjectTypes);
    on<CreateProjectTypeEvent>(_onCreateProjectType);
    on<UpdateProjectTypeEvent>(_onUpdateProjectType);
    on<DeleteProjectTypeEvent>(_onDeleteProjectType);
    on<ToggleProjectTypeActiveEvent>(_onToggleProjectTypeActive);
  }

  Future<void> _onLoadProjectTypes(
    LoadProjectTypesEvent event,
    Emitter<ProjectTypeState> emit,
  ) async {
    emit(ProjectTypeLoading());

    // First, try to seed default types if none exist
    await _repository.seedDefaultProjectTypes();

    final result = await _repository.getProjectTypes();

    result.fold(
      (error) => emit(ProjectTypeError(error)),
      (types) {
        _allTypes = types;
        emit(ProjectTypesLoaded(types));
      },
    );
  }

  Future<void> _onLoadProjectType(
    LoadProjectTypeEvent event,
    Emitter<ProjectTypeState> emit,
  ) async {
    emit(ProjectTypeLoading());

    final result = await _repository.getProjectTypeById(event.projectTypeId);

    result.fold(
      (error) => emit(ProjectTypeError(error)),
      (type) => emit(ProjectTypeLoaded(type)),
    );
  }

  Future<void> _onWatchProjectTypes(
    WatchProjectTypesEvent event,
    Emitter<ProjectTypeState> emit,
  ) async {
    emit(ProjectTypeLoading());

    await _typesSubscription?.cancel();

    _typesSubscription = _repository.watchProjectTypes().listen(
      (types) {
        _allTypes = types;
        add(const LoadProjectTypesEvent());
      },
      onError: (error) {
        // Handle stream error
      },
    );

    // Load initial data
    final result = await _repository.getProjectTypes();

    result.fold(
      (error) => emit(ProjectTypeError(error)),
      (types) {
        _allTypes = types;
        emit(ProjectTypesLoaded(types));
      },
    );
  }

  Future<void> _onCreateProjectType(
    CreateProjectTypeEvent event,
    Emitter<ProjectTypeState> emit,
  ) async {
    emit(ProjectTypeLoading());

    final result = await _repository.createProjectType(event.projectType);

    result.fold(
      (error) => emit(ProjectTypeError(error)),
      (type) {
        _allTypes.add(type);
        emit(ProjectTypeCreated(type));
        emit(ProjectTypesLoaded(_allTypes));
      },
    );
  }

  Future<void> _onUpdateProjectType(
    UpdateProjectTypeEvent event,
    Emitter<ProjectTypeState> emit,
  ) async {
    final result = await _repository.updateProjectType(event.projectType);

    result.fold(
      (error) => emit(ProjectTypeError(error)),
      (_) {
        final index = _allTypes.indexWhere((t) => t.id == event.projectType.id);
        if (index != -1) {
          _allTypes[index] = event.projectType;
        }
        emit(ProjectTypeUpdated());
        emit(ProjectTypesLoaded(_allTypes));
      },
    );
  }

  Future<void> _onDeleteProjectType(
    DeleteProjectTypeEvent event,
    Emitter<ProjectTypeState> emit,
  ) async {
    final result = await _repository.deleteProjectType(event.projectTypeId);

    result.fold(
      (error) => emit(ProjectTypeError(error)),
      (_) {
        _allTypes.removeWhere((t) => t.id == event.projectTypeId);
        emit(ProjectTypeDeleted());
        emit(ProjectTypesLoaded(_allTypes));
      },
    );
  }

  Future<void> _onToggleProjectTypeActive(
    ToggleProjectTypeActiveEvent event,
    Emitter<ProjectTypeState> emit,
  ) async {
    final result = await _repository.toggleProjectTypeActive(
      event.projectTypeId,
      event.isActive,
    );

    result.fold(
      (error) => emit(ProjectTypeError(error)),
      (_) {
        final index = _allTypes.indexWhere((t) => t.id == event.projectTypeId);
        if (index != -1) {
          _allTypes[index] =
              _allTypes[index].copyWith(isActive: event.isActive);
        }
        emit(ProjectTypesLoaded(_allTypes));
      },
    );
  }

  @override
  Future<void> close() {
    _typesSubscription?.cancel();
    return super.close();
  }
}
