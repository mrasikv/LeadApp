import 'package:freezed_annotation/freezed_annotation.dart';
import '../utils/timestamp_converter.dart';

part 'department_model.freezed.dart';
part 'department_model.g.dart';

@freezed
class Department with _$Department {
  const factory Department({
    required String id,
    required String companyId,
    required String name,
    String? description,
    String? managerId,
    @Default(true) bool isActive,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    String? createdBy,

    // Additional fields
    Map<String, dynamic>? customFormFields, // Department-specific lead fields
  }) = _Department;

  factory Department.fromJson(Map<String, dynamic> json) =>
      _$DepartmentFromJson(json);
}
