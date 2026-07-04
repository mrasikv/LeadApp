import 'package:dartz/dartz.dart';
import '../error/app_error.dart';
import '../models/lead_status_model.dart';

abstract class LeadStatusRepository {
  /// Get all statuses for a company
  Future<Either<AppError, List<LeadStatus>>> getStatusesByCompany(
    String companyId,
  );

  /// Get a single status by ID
  Future<Either<AppError, LeadStatus>> getStatusById(String id);

  /// Create a new status
  Future<Either<AppError, LeadStatus>> createStatus(LeadStatus status);

  /// Update a status (name, color, order, etc.)
  Future<Either<AppError, void>> updateStatus(LeadStatus status);

  /// Delete a status (only if canDelete = true)
  Future<Either<AppError, void>> deleteStatus(String id);

  /// Reorder statuses
  Future<Either<AppError, void>> reorderStatuses(
    String companyId,
    List<String> statusIds,
  );

  /// Initialize default statuses for a new company
  Future<Either<AppError, void>> initializeDefaultStatuses(String companyId);

  /// Get statuses by category
  Future<Either<AppError, List<LeadStatus>>> getStatusesByCategory(
    String companyId,
    String category,
  );

  /// Watch statuses in real-time
  Stream<Either<AppError, List<LeadStatus>>> watchStatuses(String companyId);
}
