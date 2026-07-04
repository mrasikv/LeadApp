import 'package:dartz/dartz.dart';
import '../error/app_error.dart';
import '../models/target_model.dart';
import '../models/ticket_model.dart';

abstract class TargetRepository {
  /// Get targets for a company
  Future<Either<AppError, List<Target>>> getTargetsByCompany(
    String companyId,
    String month, // Format: YYYY-MM
  );

  /// Get target for a specific user
  Future<Either<AppError, Target?>> getTargetByUser(
    String companyId,
    String userId,
    String month,
  );

  /// Get department targets
  Future<Either<AppError, List<Target>>> getTargetsByDepartment(
    String companyId,
    String departmentId,
    String month,
  );

  /// Create a target
  Future<Either<AppError, Target>> createTarget(Target target);

  /// Update a target
  Future<Either<AppError, void>> updateTarget(Target target);

  /// Delete a target
  Future<Either<AppError, void>> deleteTarget(String id);

  /// Calculate and update achievements
  Future<Either<AppError, void>> recalculateAchievements(
    String companyId,
    String month,
  );

  /// Get target summary for dashboard
  Future<Either<AppError, Map<String, dynamic>>> getTargetSummary(
    String companyId,
    String month,
  );

  /// Watch target progress in real-time
  Stream<Either<AppError, Target?>> watchUserTarget(
    String companyId,
    String userId,
    String month,
  );
}

abstract class TicketRepository {
  /// Get tickets for a company
  Future<Either<AppError, List<Ticket>>> getTicketsByCompany(
    String companyId, {
    String? status,
    String? userId,
    int? limit,
  });

  /// Get ticket by ID
  Future<Either<AppError, Ticket>> getTicketById(String id);

  /// Get tickets by lead
  Future<Either<AppError, List<Ticket>>> getTicketsByLead(String leadId);

  /// Create a ticket (convert lead to deal)
  Future<Either<AppError, Ticket>> createTicket(Ticket ticket);

  /// Update a ticket
  Future<Either<AppError, void>> updateTicket(Ticket ticket);

  /// Close a ticket (won/lost)
  Future<Either<AppError, void>> closeTicket(
    String id,
    String status,
    String? notes,
  );

  /// Delete a ticket
  Future<Either<AppError, void>> deleteTicket(String id);

  /// Get tickets summary for month
  Future<Either<AppError, Map<String, dynamic>>> getTicketsSummary(
    String companyId,
    String month,
  );

  /// Watch tickets in real-time
  Stream<Either<AppError, List<Ticket>>> watchTickets(
    String companyId, {
    String? userId,
  });
}
