import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/target_repository.dart';
import 'target_event.dart';
import 'target_state.dart';

class TargetBloc extends Bloc<TargetEvent, TargetState> {
  final TargetRepository _repository;
  StreamSubscription? _targetsSubscription;

  TargetBloc(this._repository) : super(TargetInitial()) {
    on<LoadTargetsEvent>(_onLoadTargets);
    on<LoadTargetEvent>(_onLoadTarget);
    on<LoadUserTargetsEvent>(_onLoadUserTargets);
    on<LoadDepartmentTargetsEvent>(_onLoadDepartmentTargets);
    on<CreateTargetEvent>(_onCreateTarget);
    on<UpdateTargetEvent>(_onUpdateTarget);
    on<DeleteTargetEvent>(_onDeleteTarget);
    on<UpdateTargetProgressEvent>(_onUpdateTargetProgress);
    on<WatchTargetsEvent>(_onWatchTargets);
  }

  Future<void> _onLoadTargets(
    LoadTargetsEvent event,
    Emitter<TargetState> emit,
  ) async {
    emit(TargetLoading());

    final result = await _repository.getTargets(event.companyId);

    result.fold(
      (error) => emit(TargetError(error)),
      (targets) => emit(TargetsLoaded(targets)),
    );
  }

  Future<void> _onLoadTarget(
    LoadTargetEvent event,
    Emitter<TargetState> emit,
  ) async {
    emit(TargetLoading());

    final result = await _repository.getTargetById(event.targetId);

    result.fold(
      (error) => emit(TargetError(error)),
      (target) => emit(TargetLoaded(target)),
    );
  }

  Future<void> _onLoadUserTargets(
    LoadUserTargetsEvent event,
    Emitter<TargetState> emit,
  ) async {
    emit(TargetLoading());

    final result = await _repository.getUserTargets(
      event.companyId,
      event.userId,
    );

    result.fold(
      (error) => emit(TargetError(error)),
      (targets) => emit(TargetsLoaded(targets)),
    );
  }

  Future<void> _onLoadDepartmentTargets(
    LoadDepartmentTargetsEvent event,
    Emitter<TargetState> emit,
  ) async {
    emit(TargetLoading());

    final result = await _repository.getDepartmentTargets(
      event.companyId,
      event.departmentId,
    );

    result.fold(
      (error) => emit(TargetError(error)),
      (targets) => emit(TargetsLoaded(targets)),
    );
  }

  Future<void> _onCreateTarget(
    CreateTargetEvent event,
    Emitter<TargetState> emit,
  ) async {
    emit(TargetLoading());

    final result = await _repository.createTarget(event.target);

    result.fold(
      (error) => emit(TargetError(error)),
      (target) => emit(TargetCreated(target)),
    );
  }

  Future<void> _onUpdateTarget(
    UpdateTargetEvent event,
    Emitter<TargetState> emit,
  ) async {
    emit(TargetLoading());

    final result = await _repository.updateTarget(event.target);

    result.fold(
      (error) => emit(TargetError(error)),
      (_) => emit(TargetUpdated()),
    );
  }

  Future<void> _onDeleteTarget(
    DeleteTargetEvent event,
    Emitter<TargetState> emit,
  ) async {
    emit(TargetLoading());

    final result = await _repository.deleteTarget(event.targetId);

    result.fold(
      (error) => emit(TargetError(error)),
      (_) => emit(TargetDeleted()),
    );
  }

  Future<void> _onUpdateTargetProgress(
    UpdateTargetProgressEvent event,
    Emitter<TargetState> emit,
  ) async {
    emit(TargetLoading());

    final result = await _repository.updateProgress(
      event.targetId,
      event.achievedPrice,
      event.achievedQuantity,
    );

    result.fold(
      (error) => emit(TargetError(error)),
      (_) => emit(TargetProgressUpdated()),
    );
  }

  Future<void> _onWatchTargets(
    WatchTargetsEvent event,
    Emitter<TargetState> emit,
  ) async {
    await _targetsSubscription?.cancel();

    _targetsSubscription = _repository.watchTargets(event.companyId).listen(
          (targets) => add(LoadTargetsEvent(event.companyId)),
        );
  }

  @override
  Future<void> close() {
    _targetsSubscription?.cancel();
    return super.close();
  }
}
