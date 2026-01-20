import 'package:freezed_annotation/freezed_annotation.dart';
import '../utils/timestamp_converter.dart';

part 'call_log_model.freezed.dart';
part 'call_log_model.g.dart';

@freezed
class CallLog with _$CallLog {
  const factory CallLog({
    required String id,
    required String companyId,
    required String userId,
    required String phoneNumber,
    required String callType, // outgoing, incoming, missed
    int? duration, // in seconds
    @TimestampConverter() required DateTime timestamp,

    // Auto-linked lead
    String? leadId,
    bool? isAutoLinked,

    // Metadata
    String? notes,
    @TimestampConverter() required DateTime createdAt,
  }) = _CallLog;

  factory CallLog.fromJson(Map<String, dynamic> json) =>
      _$CallLogFromJson(json);
}
