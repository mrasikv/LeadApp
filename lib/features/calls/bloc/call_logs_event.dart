part of 'call_logs_bloc.dart';

abstract class CallLogsEvent extends Equatable {
  const CallLogsEvent();

  @override
  List<Object?> get props => [];
}

class CallLogsLoadRequested extends CallLogsEvent {
  final String companyId;
  final String userId;

  const CallLogsLoadRequested({
    required this.companyId,
    required this.userId,
  });

  @override
  List<Object?> get props => [companyId, userId];
}

class CallLogsRefreshRequested extends CallLogsEvent {
  final String companyId;
  final String userId;

  const CallLogsRefreshRequested({
    required this.companyId,
    required this.userId,
  });

  @override
  List<Object?> get props => [companyId, userId];
}

class CallLogsSyncDeviceRequested extends CallLogsEvent {
  final String companyId;
  final String userId;
  final List<Map<String, dynamic>> deviceLogs;

  const CallLogsSyncDeviceRequested({
    required this.companyId,
    required this.userId,
    required this.deviceLogs,
  });

  @override
  List<Object?> get props => [companyId, userId, deviceLogs];
}

class CallLogLinkToLeadRequested extends CallLogsEvent {
  final String callLogId;
  final String leadId;

  const CallLogLinkToLeadRequested({
    required this.callLogId,
    required this.leadId,
  });

  @override
  List<Object?> get props => [callLogId, leadId];
}

class CallLogsUpdated extends CallLogsEvent {
  final List<CallLog> callLogs;
  final Map<String, dynamic> stats;

  const CallLogsUpdated({
    required this.callLogs,
    required this.stats,
  });

  @override
  List<Object?> get props => [callLogs, stats];
}
