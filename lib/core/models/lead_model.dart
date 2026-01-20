import 'package:freezed_annotation/freezed_annotation.dart';
import '../utils/timestamp_converter.dart';

part 'lead_model.freezed.dart';
part 'lead_model.g.dart';

@freezed
class Lead with _$Lead {
  const factory Lead({
    required String id,
    required String companyId,
    required String departmentId,
    required String name,
    required String phone,
    String? email,
    String? address,
    String? city,
    String? state,
    String? country,

    // Status & Assignment
    required String statusId, // References lead_statuses.id
    String? assignedTo, // User ID
    String? source, // Lead source

    // Tracking
    @NullableTimestampConverter() DateTime? lastContactedAt,
    @NullableTimestampConverter() DateTime? nextFollowUpAt,
    @Default(0) int totalCallsCount,
    @Default(0) int totalNotesCount,

    // Custom form data
    required Map<String, dynamic> customFields,

    // Time tracking in current status
    @NullableTimestampConverter() DateTime? statusChangedAt,
    int? timeInCurrentStatusMinutes,

    // Metadata
    @Default(false) bool isConverted,
    @NullableTimestampConverter() DateTime? convertedAt,
    String? ticketId, // If converted to deal/ticket

    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    required String createdBy,
  }) = _Lead;

  factory Lead.fromJson(Map<String, dynamic> json) => _$LeadFromJson(json);
}
