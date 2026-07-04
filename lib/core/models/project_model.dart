import 'package:freezed_annotation/freezed_annotation.dart';
import '../utils/timestamp_converter.dart';

part 'project_model.freezed.dart';
part 'project_model.g.dart';

/// Project - Belongs to a Company
/// Each project has its own lead statuses based on project type
@freezed
class Project with _$Project {
  const factory Project({
    required String id,
    required String companyId,
    required String name,
    String? description,
    required String projectTypeId,
    String? projectTypeName, // Denormalized for display
    String? icon,
    String? color,
    @Default(true) bool isActive,
    @Default(0) int leadCount,
    @Default(0) int activeLeadCount,
    @Default(0) int wonLeadCount,
    // Custom fields configuration for leads in this project
    @Default([]) List<Map<String, dynamic>> customFields,
    // Custom statuses for this project (copied from global defaults on creation)
    @Default([]) List<Map<String, dynamic>> statuses,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    String? createdBy,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);
}
