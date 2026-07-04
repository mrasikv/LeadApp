import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/models/call_log_model.dart';
import '../../../core/repositories/call_log_repository.dart';

part 'call_logs_event.dart';
part 'call_logs_state.dart';

@injectable
class CallLogsBloc extends Bloc<CallLogsEvent, CallLogsState> {
  final CallLogRepository _callLogRepository;

  StreamSubscription? _callLogsSubscription;

  CallLogsBloc(this._callLogRepository) : super(CallLogsInitial()) {
    on<CallLogsLoadRequested>(_onLoadRequested);
    on<CallLogsRefreshRequested>(_onRefreshRequested);
    on<CallLogsSyncDeviceRequested>(_onSyncDeviceRequested);
    on<CallLogLinkToLeadRequested>(_onLinkToLeadRequested);
    on<CallLogsUpdated>(_onCallLogsUpdated);
  }

  Future<void> _onLoadRequested(
    CallLogsLoadRequested event,
    Emitter<CallLogsState> emit,
  ) async {
    emit(CallLogsLoading());

    try {
      // Load today's stats
      final statsResult = await _callLogRepository.getTodaysCallStats(
        event.companyId,
        event.userId,
      );

      final stats = statsResult.isRight()
          ? statsResult.getOrElse(() => {})
          : <String, dynamic>{};

      // Start watching call logs
      _callLogsSubscription?.cancel();
      _callLogsSubscription = _callLogRepository
          .watchCallLogs(event.companyId, event.userId)
          .listen(
        (result) {
          result.fold(
            (error) => add(CallLogsUpdated(callLogs: [], stats: stats)),
            (logs) => add(CallLogsUpdated(callLogs: logs, stats: stats)),
          );
        },
        onError: (e) => add(CallLogsUpdated(callLogs: [], stats: stats)),
      );
    } catch (e) {
      emit(CallLogsError(message: e.toString()));
    }
  }

  Future<void> _onRefreshRequested(
    CallLogsRefreshRequested event,
    Emitter<CallLogsState> emit,
  ) async {
    add(CallLogsLoadRequested(
      companyId: event.companyId,
      userId: event.userId,
    ));
  }

  Future<void> _onSyncDeviceRequested(
    CallLogsSyncDeviceRequested event,
    Emitter<CallLogsState> emit,
  ) async {
    if (state is! CallLogsLoaded) return;

    final currentState = state as CallLogsLoaded;
    emit(currentState.copyWith(isSyncing: true));

    try {
      final result = await _callLogRepository.syncDeviceCallLogs(
        event.companyId,
        event.userId,
        event.deviceLogs,
      );

      result.fold(
        (error) => emit(currentState.copyWith(
          isSyncing: false,
          syncError: 'Failed to sync call logs',
        )),
        (synced) {
          emit(currentState.copyWith(
            isSyncing: false,
            lastSyncedCount: synced.length,
          ));
          // Refresh to get updated list
          add(CallLogsRefreshRequested(
            companyId: event.companyId,
            userId: event.userId,
          ));
        },
      );
    } catch (e) {
      emit(currentState.copyWith(
        isSyncing: false,
        syncError: e.toString(),
      ));
    }
  }

  Future<void> _onLinkToLeadRequested(
    CallLogLinkToLeadRequested event,
    Emitter<CallLogsState> emit,
  ) async {
    if (state is! CallLogsLoaded) return;

    final currentState = state as CallLogsLoaded;

    try {
      final result = await _callLogRepository.linkCallToLead(
        event.callLogId,
        event.leadId,
      );

      result.fold(
        (error) => emit(CallLogsError(message: 'Failed to link call to lead')),
        (updatedLog) {
          final updatedLogs = currentState.callLogs.map((log) {
            return log.id == event.callLogId ? updatedLog : log;
          }).toList();
          emit(currentState.copyWith(callLogs: updatedLogs));
        },
      );
    } catch (e) {
      emit(CallLogsError(message: e.toString()));
      emit(currentState);
    }
  }

  void _onCallLogsUpdated(
    CallLogsUpdated event,
    Emitter<CallLogsState> emit,
  ) {
    final currentState = state;
    if (currentState is CallLogsLoaded) {
      emit(currentState.copyWith(
        callLogs: event.callLogs,
        stats: event.stats,
      ));
    } else {
      emit(CallLogsLoaded(
        callLogs: event.callLogs,
        stats: event.stats,
      ));
    }
  }

  @override
  Future<void> close() {
    _callLogsSubscription?.cancel();
    return super.close();
  }
}
