import 'package:dartz/dartz.dart';
import '../error/app_error.dart';
import '../models/lead_model.dart';

abstract class LeadRepository {
  /// Get all leads for a company with optional filters
  Future<Either<AppError, List<Lead>>> getLeads({
    required String companyId,
    String? departmentId,
    String? statusId,
    String? assignedTo,
    int? limit,
    String? lastDocumentId,
  });

  /// Get a single lead by ID
  Future<Either<AppError, Lead>> getLeadById(String id);

  /// Get leads by phone number (for call linking)
  Future<Either<AppError, List<Lead>>> getLeadsByPhone(
    String companyId,
    String phone,
  );

  /// Create a new lead
  Future<Either<AppError, Lead>> createLead(Lead lead);

  /// Update an existing lead
  Future<Either<AppError, void>> updateLead(Lead lead);

  /// Update lead status with tracking
  Future<Either<AppError, void>> updateLeadStatus(
    String leadId,
    String newStatusId,
    String userId,
  );

  /// Delete a lead
  Future<Either<AppError, void>> deleteLead(String id);

  /// Assign lead to user
  Future<Either<AppError, void>> assignLead(
    String leadId,
    String userId,
  );

  /// Search leads by name, phone, or email
  Future<Either<AppError, List<Lead>>> searchLeads({
    required String companyId,
    required String query,
  });

  /// Get leads count by status
  Future<Either<AppError, Map<String, int>>> getLeadsCountByStatus(
    String companyId,
  );

  /// Get today's leads by status category
  Future<Either<AppError, Map<String, List<Lead>>>> getTodaysLeadsByCategory(
    String companyId,
  );

  /// Watch leads in real-time
  Stream<Either<AppError, List<Lead>>> watchLeads({
    required String companyId,
    String? statusId,
    String? assignedTo,
  });

  /// Get leads for follow-up today
  Future<Either<AppError, List<Lead>>> getFollowUpLeads(
    String companyId,
    DateTime date,
  );
}
