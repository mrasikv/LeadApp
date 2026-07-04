import 'package:equatable/equatable.dart';
import '../../../../core/models/call_log_model.dart';

abstract class CallLogEvent extends Equatable {
  const CallLogEvent();

  @override
  List<Object?> get props => [];
}

class LoadCallLogsEvent extends CallLogEvent {
  final String companyId;

  const LoadCallLogsEvent(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class LoadCallLogsByLeadEvent extends CallLogEvent {
  final String leadId;

  const LoadCallLogsByLeadEvent(this.leadId);

  @override
  List<Object> get props => [leadId];
}

class LoadCallLogsByUserEvent extends CallLogEvent {
  final String companyId;
  final String userId;

  const LoadCallLogsByUserEvent(this.companyId, this.userId);

  @override
  List<Object> get props => [companyId, userId];
}

class SyncDeviceCallLogsEvent extends CallLogEvent {
  final String companyId;
  final String userId;
  final int daysBack;

  const SyncDeviceCallLogsEvent({
    required this.companyId,
    required this.userId,
    this.daysBack = 7,
  });

  @override
  List<Object> get props => [companyId, userId, daysBack];
}

class CreateCallLogEvent extends CallLogEvent {
  final CallLog callLog;

  const CreateCallLogEvent(this.callLog);

  @override
  List<Object> get props => [callLog];
}

class UpdateCallLogEvent extends CallLogEvent {
  final CallLog callLog;

  const UpdateCallLogEvent(this.callLog);

  @override
  List<Object> get props => [callLog];
}

class LinkCallLogToLeadEvent extends CallLogEvent {
  final String callLogId;
  final String leadId;

  const LinkCallLogToLeadEvent(this.callLogId, this.leadId);

  @override
  List<Object> get props => [callLogId, leadId];
}

class WatchCallLogsEvent extends CallLogEvent {
  final String companyId;

  const WatchCallLogsEvent(this.companyId);

  @override
  List<Object> get props => [companyId];
}
