import 'package:freezed_annotation/freezed_annotation.dart';
import '../utils/timestamp_converter.dart';

part 'company_invite_model.freezed.dart';
part 'company_invite_model.g.dart';

/// Represents an invitation to join a company
@freezed
class CompanyInvite with _$CompanyInvite {
  const factory CompanyInvite({
    required String id,
    required String companyId,
    required String email,
    required String roleId,
    String? departmentId,
    required String status, // pending, accepted, rejected, expired
    required String inviteCode,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime expiresAt,
    String? invitedBy,
    String? acceptedBy,
    @NullableTimestampConverter() DateTime? acceptedAt,
  }) = _CompanyInvite;

  factory CompanyInvite.fromJson(Map<String, dynamic> json) =>
      _$CompanyInviteFromJson(json);
}
