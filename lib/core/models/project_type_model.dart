import 'package:freezed_annotation/freezed_annotation.dart';
import '../utils/timestamp_converter.dart';

part 'project_type_model.freezed.dart';
part 'project_type_model.g.dart';

/// Default status template for a project type
@freezed
class StatusTemplate with _$StatusTemplate {
  const factory StatusTemplate({
    required String name,
    required String category, // to_do, in_progress, done
    required String color,
    required int order,
    @Default(false) bool isDefault, // Default status for new leads
    @Default([]) List<String> mandatoryFields,
  }) = _StatusTemplate;

  factory StatusTemplate.fromJson(Map<String, dynamic> json) =>
      _$StatusTemplateFromJson(json);
}

/// Project Type - Managed by Super Admin
/// Defines templates for projects with default statuses
@freezed
class ProjectType with _$ProjectType {
  const factory ProjectType({
    required String id,
    required String name,
    String? description,
    String? icon, // Material icon name
    String? color, // Hex color
    @Default(true) bool isActive,
    @Default([]) List<StatusTemplate> defaultStatuses,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    String? createdBy,
  }) = _ProjectType;

  factory ProjectType.fromJson(Map<String, dynamic> json) =>
      _$ProjectTypeFromJson(json);
}
