import 'package:equatable/equatable.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/models/call_log_model.dart';

abstract class CallLogState extends Equatable {
  const CallLogState();

  @override
  List<Object?> get props => [];
}

class CallLogInitial extends CallLogState {}

class CallLogLoading extends CallLogState {}

class CallLogsLoaded extends CallLogState {
  final List<CallLog> callLogs;

  const CallLogsLoaded(this.callLogs);

  @override
  List<Object> get props => [callLogs];
}

class CallLogSyncing extends CallLogState {
  final int progress;

  const CallLogSyncing(this.progress);

  @override
  List<Object> get props => [progress];
}

class CallLogsSynced extends CallLogState {
  final int syncedCount;

  const CallLogsSynced(this.syncedCount);

  @override
  List<Object> get props => [syncedCount];
}

class CallLogCreated extends CallLogState {
  final CallLog callLog;

  const CallLogCreated(this.callLog);

  @override
  List<Object> get props => [callLog];
}

class CallLogUpdated extends CallLogState {}

class CallLogLinked extends CallLogState {}

class CallLogError extends CallLogState {
  final AppError error;

  const CallLogError(this.error);

  @override
  List<Object> get props => [error];
}
