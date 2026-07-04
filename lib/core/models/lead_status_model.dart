import 'package:freezed_annotation/freezed_annotation.dart';
import '../utils/timestamp_converter.dart';

part 'lead_status_model.freezed.dart';
part 'lead_status_model.g.dart';

@freezed
class LeadStatus with _$LeadStatus {
  const factory LeadStatus({
    required String id, // Immutable UUID
    required String companyId,
    String? projectId, // NEW: Link to specific project (null = company-wide)
    required String name, // Can be renamed
    required String category, // 'to_do', 'in_progress', 'done'
    required String color, // Hex color code
    required int order, // Display order
    @Default(false) bool isSystemDefault,
    @Default(true) bool isActive,
    @Default(false)
    bool isDefault, // Default status for new leads in this project
    @Default(false) bool canDelete, // False for system defaults

    // Auto-transition rules
    String? autoTransitionToStatusId, // Auto-move to this status after time
    int? autoTransitionAfterHours,

    // Mandatory fields for this status
    @Default([]) List<String> mandatoryFields,

    // Time tracking
    int? maxTimeInStatusHours, // Alert if lead stays too long

    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    String? createdBy,
  }) = _LeadStatus;

  factory LeadStatus.fromJson(Map<String, dynamic> json) =>
      _$LeadStatusFromJson(json);
}
