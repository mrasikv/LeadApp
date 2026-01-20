import 'package:freezed_annotation/freezed_annotation.dart';
import '../utils/timestamp_converter.dart';

part 'role_model.freezed.dart';
part 'role_model.g.dart';

@freezed
class Role with _$Role {
  const factory Role({
    required String id,
    required String name,
    required String companyId, // empty string for system-wide roles
    String? description,
    @Default([]) List<String> permissions,
    @Default(false) bool isSystemRole,
    @Default(true) bool isActive,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    String? createdBy,
  }) = _Role;

  factory Role.fromJson(Map<String, dynamic> json) => _$RoleFromJson(json);
}
