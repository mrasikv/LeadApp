import 'package:freezed_annotation/freezed_annotation.dart';
import '../utils/timestamp_converter.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String companyId,
    required String email,
    required String name,
    String? phone,
    String? avatar,
    required String roleId,
    String? departmentId,
    @Default([]) List<String> permissions,
    @Default(true) bool isActive,
    @NullableTimestampConverter() DateTime? lastLoginAt,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    String? createdBy,

    // Additional metadata
    String? designation,
    String? employeeCode,
    Map<String, dynamic>? customFields,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
