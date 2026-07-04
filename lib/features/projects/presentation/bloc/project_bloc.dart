import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/project_repository.dart';
import 'project_event.dart';
import 'project_state.dart';
import '../../../../core/models/project_model.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final ProjectRepository _repository;
  StreamSubscription? _projectsSubscription;
  List<Project> _allProjects = [];
  Project? _selectedProject;

  ProjectBloc(this._repository) : super(ProjectInitial()) {
    on<LoadProjectsEvent>(_onLoadProjects);
    on<LoadProjectEvent>(_onLoadProject);
    on<WatchProjectsEvent>(_onWatchProjects);
    on<CreateProjectEvent>(_onCreateProject);
    on<UpdateProjectEvent>(_onUpdateProject);
    on<DeleteProjectEvent>(_onDeleteProject);
    on<ToggleProjectActiveEvent>(_onToggleProjectActive);
    on<UpdateProjectLeadCountsEvent>(_onUpdateLeadCounts);
    on<SelectProjectEvent>(_onSelectProject);
  }

  Future<void> _onLoadProjects(
    LoadProjectsEvent event,
    Emitter<ProjectState> emit,
  ) async {
    emit(ProjectLoading());

    final result = await _repository.getProjects(event.companyId);

    result.fold(
      (error) => emit(ProjectError(error)),
      (projects) {
        _allProjects = projects;
        emit(ProjectsLoaded(projects, selectedProject: _selectedProject));
      },
    );
  }

  Future<void> _onLoadProject(
    LoadProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    emit(ProjectLoading());

    final result = await _repository.getProjectById(event.projectId);

    result.fold(
      (error) => emit(ProjectError(error)),
      (project) => emit(ProjectLoaded(project)),
    );
  }

  Future<void> _onWatchProjects(
    WatchProjectsEvent event,
    Emitter<ProjectState> emit,
  ) async {
    emit(ProjectLoading());

    await _projectsSubscription?.cancel();

    _projectsSubscription = _repository.watchProjects(event.companyId).listen(
      (projects) {
        _allProjects = projects;
        add(LoadProjectsEvent(event.companyId));
      },
      onError: (error) {
        // Handle stream error
      },
    );

    // Load initial data
    final result = await _repository.getProjects(event.companyId);

    result.fold(
      (error) => emit(ProjectError(error)),
      (projects) {
        _allProjects = projects;
        emit(ProjectsLoaded(projects, selectedProject: _selectedProject));
      },
    );
  }

  Future<void> _onCreateProject(
    CreateProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    emit(ProjectLoading());

    final result = await _repository.createProject(
      event.project,
      event.projectType,
    );

    result.fold(
      (error) => emit(ProjectError(error)),
      (project) {
        _allProjects.insert(0, project);
        emit(ProjectCreated(project));
        emit(ProjectsLoaded(_allProjects, selectedProject: _selectedProject));
      },
    );
  }

  Future<void> _onUpdateProject(
    UpdateProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    final result = await _repository.updateProject(event.project);

    result.fold(
      (error) => emit(ProjectError(error)),
      (_) {
        final index = _allProjects.indexWhere((p) => p.id == event.project.id);
        if (index != -1) {
          _allProjects[index] = event.project;
        }
        emit(ProjectUpdated());
        emit(ProjectsLoaded(_allProjects, selectedProject: _selectedProject));
      },
    );
  }

  Future<void> _onDeleteProject(
    DeleteProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    final result = await _repository.deleteProject(event.projectId);

    result.fold(
      (error) => emit(ProjectError(error)),
      (_) {
        _allProjects.removeWhere((p) => p.id == event.projectId);
        if (_selectedProject?.id == event.projectId) {
          _selectedProject = null;
        }
        emit(ProjectDeleted());
        emit(ProjectsLoaded(_allProjects, selectedProject: _selectedProject));
      },
    );
  }

  Future<void> _onToggleProjectActive(
    ToggleProjectActiveEvent event,
    Emitter<ProjectState> emit,
  ) async {
    final result = await _repository.toggleProjectActive(
      event.projectId,
      event.isActive,
    );

    result.fold(
      (error) => emit(ProjectError(error)),
      (_) {
        final index = _allProjects.indexWhere((p) => p.id == event.projectId);
        if (index != -1) {
          _allProjects[index] = _allProjects[index].copyWith(
            isActive: event.isActive,
          );
        }
        emit(ProjectsLoaded(_allProjects, selectedProject: _selectedProject));
      },
    );
  }

  Future<void> _onUpdateLeadCounts(
    UpdateProjectLeadCountsEvent event,
    Emitter<ProjectState> emit,
  ) async {
    await _repository.updateLeadCounts(event.projectId);
    // Reload projects to get updated counts
    final companyId = _allProjects
        .firstWhere(
          (p) => p.id == event.projectId,
          orElse: () => _allProjects.first,
        )
        .companyId;
    add(LoadProjectsEvent(companyId));
  }

  void _onSelectProject(
    SelectProjectEvent event,
    Emitter<ProjectState> emit,
  ) {
    _selectedProject = event.project;
    emit(ProjectsLoaded(_allProjects, selectedProject: _selectedProject));
  }

  @override
  Future<void> close() {
    _projectsSubscription?.cancel();
    return super.close();
  }
}
