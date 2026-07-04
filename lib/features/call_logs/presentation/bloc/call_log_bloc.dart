import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/app_error.dart';
import '../../data/repositories/call_log_repository.dart';
import '../../data/services/call_log_service.dart';
import 'call_log_event.dart';
import 'call_log_state.dart';

class CallLogBloc extends Bloc<CallLogEvent, CallLogState> {
  final CallLogRepository _repository;
  final CallLogService _callLogService;
  StreamSubscription? _callLogsSubscription;

  CallLogBloc(this._repository, this._callLogService)
      : super(CallLogInitial()) {
    on<LoadCallLogsEvent>(_onLoadCallLogs);
    on<LoadCallLogsByLeadEvent>(_onLoadCallLogsByLead);
    on<LoadCallLogsByUserEvent>(_onLoadCallLogsByUser);
    on<SyncDeviceCallLogsEvent>(_onSyncDeviceCallLogs);
    on<CreateCallLogEvent>(_onCreateCallLog);
    on<UpdateCallLogEvent>(_onUpdateCallLog);
    on<LinkCallLogToLeadEvent>(_onLinkCallLogToLead);
    on<WatchCallLogsEvent>(_onWatchCallLogs);
  }

  Future<void> _onLoadCallLogs(
    LoadCallLogsEvent event,
    Emitter<CallLogState> emit,
  ) async {
    emit(CallLogLoading());

    final result = await _repository.getCallLogs(event.companyId);

    result.fold(
      (error) => emit(CallLogError(error)),
      (callLogs) => emit(CallLogsLoaded(callLogs)),
    );
  }

  Future<void> _onLoadCallLogsByLead(
    LoadCallLogsByLeadEvent event,
    Emitter<CallLogState> emit,
  ) async {
    emit(CallLogLoading());

    final result = await _repository.getCallLogsByLead(event.leadId);

    result.fold(
      (error) => emit(CallLogError(error)),
      (callLogs) => emit(CallLogsLoaded(callLogs)),
    );
  }

  Future<void> _onLoadCallLogsByUser(
    LoadCallLogsByUserEvent event,
    Emitter<CallLogState> emit,
  ) async {
    emit(CallLogLoading());

    final result = await _repository.getCallLogsByUser(
      event.companyId,
      event.userId,
    );

    result.fold(
      (error) => emit(CallLogError(error)),
      (callLogs) => emit(CallLogsLoaded(callLogs)),
    );
  }

  Future<void> _onSyncDeviceCallLogs(
    SyncDeviceCallLogsEvent event,
    Emitter<CallLogState> emit,
  ) async {
    try {
      emit(const CallLogSyncing(0));

      // Request permissions
      final hasPermission = await _callLogService.requestPermissions();
      if (!hasPermission) {
        emit(
          const CallLogError(
            AppError.validationError(
              message: 'Call log permissions are required',
            ),
          ),
        );
        return;
      }

      emit(const CallLogSyncing(30));

      // Sync call logs from device
      final deviceCallLogs = await _callLogService.syncCallLogs(
        companyId: event.companyId,
        userId: event.userId,
        daysBack: event.daysBack,
      );

      emit(const CallLogSyncing(60));

      // Save to Firestore
      int syncedCount = 0;
      for (final callLog in deviceCallLogs) {
        final result = await _repository.createCallLog(callLog);
        result.fold(
          (error) => null,
          (_) => syncedCount++,
        );
      }

      emit(const CallLogSyncing(100));
      emit(CallLogsSynced(syncedCount));
    } catch (e) {
      emit(
        CallLogError(
          AppError.serverError(message: 'Failed to sync call logs: $e'),
        ),
      );
    }
  }

  Future<void> _onCreateCallLog(
    CreateCallLogEvent event,
    Emitter<CallLogState> emit,
  ) async {
    emit(CallLogLoading());

    final result = await _repository.createCallLog(event.callLog);

    result.fold(
      (error) => emit(CallLogError(error)),
      (callLog) => emit(CallLogCreated(callLog)),
    );
  }

  Future<void> _onUpdateCallLog(
    UpdateCallLogEvent event,
    Emitter<CallLogState> emit,
  ) async {
    emit(CallLogLoading());

    final result = await _repository.updateCallLog(event.callLog);

    result.fold(
      (error) => emit(CallLogError(error)),
      (_) => emit(CallLogUpdated()),
    );
  }

  Future<void> _onLinkCallLogToLead(
    LinkCallLogToLeadEvent event,
    Emitter<CallLogState> emit,
  ) async {
    emit(CallLogLoading());

    final result = await _repository.linkCallLogToLead(
      event.callLogId,
      event.leadId,
    );

    result.fold(
      (error) => emit(CallLogError(error)),
      (_) => emit(CallLogLinked()),
    );
  }

  Future<void> _onWatchCallLogs(
    WatchCallLogsEvent event,
    Emitter<CallLogState> emit,
  ) async {
    await _callLogsSubscription?.cancel();

    _callLogsSubscription = _repository.watchCallLogs(event.companyId).listen(
          (callLogs) => add(LoadCallLogsEvent(event.companyId)),
        );
  }

  @override
  Future<void> close() {
    _callLogsSubscription?.cancel();
    return super.close();
  }
}
