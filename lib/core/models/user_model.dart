import 'package:freezed_annotation/freezed_annotation.dart';
import '../utils/timestamp_converter.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String name,
    String? phone,
    String? avatar,
    @Default(true) bool isActive,
    @Default(false) bool isSuperAdmin, // Global super admin flag
    @NullableTimestampConverter() DateTime? lastLoginAt,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    String? createdBy,

    // Additional metadata
    String? designation,
    String? employeeCode,
    Map<String, dynamic>? customFields,

    // Current active company context (set at runtime after company switch)
    String? currentCompanyId,
    String? currentRoleId,
    String? currentDepartmentId,
    @Default([]) List<String> currentPermissions,

    // List of company IDs user belongs to (for quick access)
    @Default([]) List<String> companyIds,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
