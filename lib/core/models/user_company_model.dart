import 'package:freezed_annotation/freezed_annotation.dart';
import '../utils/timestamp_converter.dart';

part 'user_company_model.freezed.dart';
part 'user_company_model.g.dart';

/// Represents a user's membership in a company
/// Users can belong to multiple companies with different roles
@freezed
class UserCompany with _$UserCompany {
  const factory UserCompany({
    required String id,
    required String userId,
    required String companyId,
    required String roleId,
    String? departmentId,
    @Default([]) List<String> permissions,
    @Default(true) bool isActive,
    @Default(false) bool isPrimary, // Primary company for the user
    @TimestampConverter() required DateTime joinedAt,
    @TimestampConverter() required DateTime updatedAt,
    String? addedBy,
  }) = _UserCompany;

  factory UserCompany.fromJson(Map<String, dynamic> json) =>
      _$UserCompanyFromJson(json);
}
