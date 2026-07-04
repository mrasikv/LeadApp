part of 'call_logs_bloc.dart';

abstract class CallLogsState extends Equatable {
  const CallLogsState();

  @override
  List<Object?> get props => [];
}

class CallLogsInitial extends CallLogsState {}

class CallLogsLoading extends CallLogsState {}

class CallLogsLoaded extends CallLogsState {
  final List<CallLog> callLogs;
  final Map<String, dynamic> stats;
  final bool isSyncing;
  final String? syncError;
  final int? lastSyncedCount;

  const CallLogsLoaded({
    required this.callLogs,
    required this.stats,
    this.isSyncing = false,
    this.syncError,
    this.lastSyncedCount,
  });

  int get totalCalls => stats['totalCalls'] as int? ?? 0;
  int get incomingCalls => stats['incomingCalls'] as int? ?? 0;
  int get outgoingCalls => stats['outgoingCalls'] as int? ?? 0;
  int get missedCalls => stats['missedCalls'] as int? ?? 0;
  int get totalDuration => stats['totalDuration'] as int? ?? 0;
  int get linkedCalls => stats['linkedCalls'] as int? ?? 0;
  int get unlinkedCalls => stats['unlinkedCalls'] as int? ?? 0;

  List<CallLog> get linkedCallLogs =>
      callLogs.where((log) => log.leadId != null).toList();

  List<CallLog> get unlinkedCallLogs =>
      callLogs.where((log) => log.leadId == null).toList();

  CallLogsLoaded copyWith({
    List<CallLog>? callLogs,
    Map<String, dynamic>? stats,
    bool? isSyncing,
    String? syncError,
    int? lastSyncedCount,
  }) {
    return CallLogsLoaded(
      callLogs: callLogs ?? this.callLogs,
      stats: stats ?? this.stats,
      isSyncing: isSyncing ?? this.isSyncing,
      syncError: syncError,
      lastSyncedCount: lastSyncedCount,
    );
  }

  @override
  List<Object?> get props => [
        callLogs,
        stats,
        isSyncing,
        syncError,
        lastSyncedCount,
      ];
}

class CallLogsError extends CallLogsState {
  final String message;

  const CallLogsError({required this.message});

  @override
  List<Object?> get props => [message];
}
