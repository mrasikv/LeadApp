import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../error/app_error.dart';
import '../../models/call_log_model.dart';
import '../call_log_repository.dart';

@LazySingleton(as: CallLogRepository)
class FirestoreCallLogRepository implements CallLogRepository {
  final FirebaseFirestore _firestore;

  FirestoreCallLogRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _callLogsRef =>
      _firestore.collection('call_logs');

  CollectionReference<Map<String, dynamic>> get _leadsRef =>
      _firestore.collection('leads');

  @override
  Future<Either<AppError, List<CallLog>>> getCallLogsByUser(
    String companyId,
    String userId, {
    int? limit,
    String? lastDocumentId,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _callLogsRef
          .where('companyId', isEqualTo: companyId)
          .where('userId', isEqualTo: userId)
          .orderBy('callTime', descending: true);

      if (lastDocumentId != null) {
        final lastDoc = await _callLogsRef.doc(lastDocumentId).get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final callLogs = snapshot.docs
          .map((doc) => CallLog.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      return Right(callLogs);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, List<CallLog>>> getCallLogsByLead(
      String leadId) async {
    try {
      final snapshot = await _callLogsRef
          .where('leadId', isEqualTo: leadId)
          .orderBy('callTime', descending: true)
          .get();

      final callLogs = snapshot.docs
          .map((doc) => CallLog.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      return Right(callLogs);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, List<CallLog>>> getCallLogsByPhone(
    String companyId,
    String phoneNumber,
  ) async {
    try {
      final normalizedPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');

      final snapshot = await _callLogsRef
          .where('companyId', isEqualTo: companyId)
          .where('phoneNumber', isEqualTo: normalizedPhone)
          .orderBy('callTime', descending: true)
          .get();

      final callLogs = snapshot.docs
          .map((doc) => CallLog.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      return Right(callLogs);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, CallLog>> createCallLog(CallLog callLog) async {
    try {
      final docRef = await _callLogsRef.add(callLog.toJson());
      return Right(callLog.copyWith(id: docRef.id));
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, List<CallLog>>> syncDeviceCallLogs(
    String companyId,
    String userId,
    List<Map<String, dynamic>> deviceLogs,
  ) async {
    try {
      final List<CallLog> createdLogs = [];

      for (final log in deviceLogs) {
        final phoneNumber =
            (log['phoneNumber'] as String?)?.replaceAll(RegExp(r'\D'), '') ??
                '';

        // Check if already synced
        final existingSnapshot = await _callLogsRef
            .where('companyId', isEqualTo: companyId)
            .where('userId', isEqualTo: userId)
            .where('deviceCallId', isEqualTo: log['id'])
            .limit(1)
            .get();

        if (existingSnapshot.docs.isNotEmpty) {
          continue; // Already synced
        }

        // Try to auto-link to lead
        String? leadId;
        if (phoneNumber.isNotEmpty) {
          final leadSnapshot = await _leadsRef
              .where('companyId', isEqualTo: companyId)
              .where('phone', isEqualTo: phoneNumber)
              .limit(1)
              .get();

          if (leadSnapshot.docs.isNotEmpty) {
            leadId = leadSnapshot.docs.first.id;
          }
        }

        // Determine call type from device log
        String callType = 'unknown';
        final deviceCallType = log['callType'] as int?;
        if (deviceCallType != null) {
          switch (deviceCallType) {
            case 1:
              callType = 'incoming';
              break;
            case 2:
              callType = 'outgoing';
              break;
            case 3:
              callType = 'missed';
              break;
          }
        }

        final callLog = CallLog(
          id: '', // Will be set after Firestore generates it
          companyId: companyId,
          userId: userId,
          leadId: leadId,
          phoneNumber: phoneNumber,
          callType: callType,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            log['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
          ),
          duration: log['duration'] as int? ?? 0,
          isAutoLinked: leadId != null,
          createdAt: DateTime.now(),
        );

        final docRef = await _callLogsRef.add(callLog.toJson());
        createdLogs.add(callLog.copyWith(id: docRef.id));
      }

      return Right(createdLogs);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, CallLog>> linkCallToLead(
    String callLogId,
    String leadId,
  ) async {
    try {
      await _callLogsRef.doc(callLogId).update({
        'leadId': leadId,
        'isAutoLinked': false, // Manual link
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final doc = await _callLogsRef.doc(callLogId).get();
      return Right(CallLog.fromJson({...doc.data()!, 'id': doc.id}));
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, Map<String, dynamic>>> getTodaysCallStats(
    String companyId,
    String userId,
  ) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final snapshot = await _callLogsRef
          .where('companyId', isEqualTo: companyId)
          .where('userId', isEqualTo: userId)
          .where('callTime', isGreaterThanOrEqualTo: startOfDay)
          .get();

      int totalCalls = snapshot.docs.length;
      int incomingCalls = 0;
      int outgoingCalls = 0;
      int missedCalls = 0;
      int totalDuration = 0;
      int linkedCalls = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final callType = data['callType'] as String?;
        final duration = data['duration'] as int? ?? 0;
        final leadId = data['leadId'] as String?;

        totalDuration += duration;

        if (leadId != null) linkedCalls++;

        switch (callType) {
          case 'incoming':
            incomingCalls++;
            break;
          case 'outgoing':
            outgoingCalls++;
            break;
          case 'missed':
            missedCalls++;
            break;
        }
      }

      return Right({
        'totalCalls': totalCalls,
        'incomingCalls': incomingCalls,
        'outgoingCalls': outgoingCalls,
        'missedCalls': missedCalls,
        'totalDuration': totalDuration,
        'linkedCalls': linkedCalls,
        'unlinkedCalls': totalCalls - linkedCalls,
      });
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Stream<Either<AppError, List<CallLog>>> watchCallLogs(
    String companyId,
    String userId,
  ) {
    return _callLogsRef
        .where('companyId', isEqualTo: companyId)
        .where('userId', isEqualTo: userId)
        .orderBy('callTime', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      try {
        final callLogs = snapshot.docs
            .map((doc) => CallLog.fromJson({...doc.data(), 'id': doc.id}))
            .toList();
        return Right(callLogs);
      } catch (e) {
        return Left(AppError.serverError(message: e.toString()));
      }
    });
  }
}
