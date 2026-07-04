import 'package:dartz/dartz.dart';
import '../error/app_error.dart';
import '../models/call_log_model.dart';

abstract class CallLogRepository {
  /// Get call logs for a user
  Future<Either<AppError, List<CallLog>>> getCallLogsByUser(
    String companyId,
    String userId, {
    int? limit,
    String? lastDocumentId,
  });

  /// Get call logs for a lead
  Future<Either<AppError, List<CallLog>>> getCallLogsByLead(String leadId);

  /// Get call logs by phone number
  Future<Either<AppError, List<CallLog>>> getCallLogsByPhone(
    String companyId,
    String phoneNumber,
  );

  /// Create a call log entry
  Future<Either<AppError, CallLog>> createCallLog(CallLog callLog);

  /// Sync device call logs
  Future<Either<AppError, List<CallLog>>> syncDeviceCallLogs(
    String companyId,
    String userId,
    List<Map<String, dynamic>> deviceLogs,
  );

  /// Auto-link call to lead by phone number
  Future<Either<AppError, CallLog>> linkCallToLead(
    String callLogId,
    String leadId,
  );

  /// Get today's call statistics
  Future<Either<AppError, Map<String, dynamic>>> getTodaysCallStats(
    String companyId,
    String userId,
  );

  /// Watch call logs in real-time
  Stream<Either<AppError, List<CallLog>>> watchCallLogs(
    String companyId,
    String userId,
  );
}
