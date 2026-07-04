import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/models/call_log_model.dart';
import '../../../../core/services/logger_service.dart';

abstract class CallLogRepository {
  Future<Either<AppError, List<CallLog>>> getCallLogs(String companyId);
  Future<Either<AppError, CallLog>> getCallLogById(String id);
  Future<Either<AppError, List<CallLog>>> getCallLogsByLead(String leadId);
  Future<Either<AppError, List<CallLog>>> getCallLogsByUser(
      String companyId, String userId);
  Future<Either<AppError, CallLog>> createCallLog(CallLog callLog);
  Future<Either<AppError, void>> updateCallLog(CallLog callLog);
  Future<Either<AppError, void>> deleteCallLog(String id);
  Future<Either<AppError, void>> linkCallLogToLead(
      String callLogId, String leadId);
  Stream<List<CallLog>> watchCallLogs(String companyId);
}

class CallLogRepositoryImpl implements CallLogRepository {
  final FirebaseFirestore _firestore;

  CallLogRepositoryImpl(this._firestore);

  @override
  Future<Either<AppError, List<CallLog>>> getCallLogs(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.callLogsCollection)
          .where('companyId', isEqualTo: companyId)
          .orderBy('callTime', descending: true)
          .limit(100)
          .get();

      final callLogs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CallLog.fromJson(data);
      }).toList();

      return Right(callLogs);
    } catch (e, stackTrace) {
      LoggerService.error('Error getting call logs', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to load call logs'));
    }
  }

  @override
  Future<Either<AppError, CallLog>> getCallLogById(String id) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.callLogsCollection)
          .doc(id)
          .get();

      if (!doc.exists) {
        return const Left(
            AppError.notFoundError(message: 'Call log not found'));
      }

      final data = doc.data()!;
      data['id'] = doc.id;

      return Right(CallLog.fromJson(data));
    } catch (e, stackTrace) {
      LoggerService.error('Error getting call log', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to load call log'));
    }
  }

  @override
  Future<Either<AppError, List<CallLog>>> getCallLogsByLead(
      String leadId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.callLogsCollection)
          .where('leadId', isEqualTo: leadId)
          .orderBy('callTime', descending: true)
          .get();

      final callLogs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CallLog.fromJson(data);
      }).toList();

      return Right(callLogs);
    } catch (e, stackTrace) {
      LoggerService.error('Error getting call logs by lead', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to load call logs'));
    }
  }

  @override
  Future<Either<AppError, List<CallLog>>> getCallLogsByUser(
    String companyId,
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.callLogsCollection)
          .where('companyId', isEqualTo: companyId)
          .where('userId', isEqualTo: userId)
          .orderBy('callTime', descending: true)
          .limit(100)
          .get();

      final callLogs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CallLog.fromJson(data);
      }).toList();

      return Right(callLogs);
    } catch (e, stackTrace) {
      LoggerService.error('Error getting call logs by user', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to load call logs'));
    }
  }

  @override
  Future<Either<AppError, CallLog>> createCallLog(CallLog callLog) async {
    try {
      final callLogData = callLog.toJson();

      final docRef = await _firestore
          .collection(AppConstants.callLogsCollection)
          .add(callLogData);

      final createdCallLog = callLog.copyWith(id: docRef.id);

      return Right(createdCallLog);
    } catch (e, stackTrace) {
      LoggerService.error('Error creating call log', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to create call log'));
    }
  }

  @override
  Future<Either<AppError, void>> updateCallLog(CallLog callLog) async {
    try {
      final callLogData = callLog.toJson();

      await _firestore
          .collection(AppConstants.callLogsCollection)
          .doc(callLog.id)
          .update(callLogData);

      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error updating call log', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to update call log'));
    }
  }

  @override
  Future<Either<AppError, void>> deleteCallLog(String id) async {
    try {
      await _firestore
          .collection(AppConstants.callLogsCollection)
          .doc(id)
          .delete();

      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error deleting call log', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to delete call log'));
    }
  }

  @override
  Future<Either<AppError, void>> linkCallLogToLead(
    String callLogId,
    String leadId,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.callLogsCollection)
          .doc(callLogId)
          .update({
        'leadId': leadId,
      });

      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error linking call log to lead', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to link call log'));
    }
  }

  @override
  Stream<List<CallLog>> watchCallLogs(String companyId) {
    try {
      return _firestore
          .collection(AppConstants.callLogsCollection)
          .where('companyId', isEqualTo: companyId)
          .orderBy('callTime', descending: true)
          .limit(100)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return CallLog.fromJson(data);
        }).toList();
      });
    } catch (e) {
      LoggerService.error('Error watching call logs', e);
      return Stream.value([]);
    }
  }
}
