import 'package:dartz/dartz.dart';
import '../error/app_error.dart';
import '../models/company_invite_model.dart';

abstract class CompanyInviteRepository {
  /// Get pending invites for a company
  Future<Either<AppError, List<CompanyInvite>>> getPendingInvites(
    String companyId,
  );

  /// Get invite by code
  Future<Either<AppError, CompanyInvite?>> getInviteByCode(String inviteCode);

  /// Get invite by email
  Future<Either<AppError, CompanyInvite?>> getInviteByEmail(
    String companyId,
    String email,
  );

  /// Create an invite
  Future<Either<AppError, CompanyInvite>> createInvite(CompanyInvite invite);

  /// Accept an invite
  Future<Either<AppError, void>> acceptInvite(
    String inviteCode,
    String userId,
  );

  /// Decline an invite
  Future<Either<AppError, void>> declineInvite(String inviteCode);

  /// Cancel an invite (by admin)
  Future<Either<AppError, void>> cancelInvite(String id);

  /// Resend invite (regenerate code & extend expiry)
  Future<Either<AppError, CompanyInvite>> resendInvite(String id);

  /// Check if email has pending invite
  Future<Either<AppError, bool>> hasPendingInvite(
    String companyId,
    String email,
  );

  /// Get all pending invites for an email (across companies)
  Future<Either<AppError, List<CompanyInvite>>> getPendingInvitesByEmail(
    String email,
  );

  /// Generate unique invite code
  Future<Either<AppError, String>> generateUniqueInviteCode();
}
