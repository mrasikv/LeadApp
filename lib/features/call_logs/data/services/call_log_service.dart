import 'dart:io';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/models/call_log_model.dart' as app_model;
import '../../../../core/services/logger_service.dart';

class CallLogService {
  static final CallLogService _instance = CallLogService._internal();
  factory CallLogService() => _instance;
  CallLogService._internal();

  /// Request phone and call log permissions
  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) {
      LoggerService.warning('Call log access is only available on Android');
      return false;
    }

    try {
      final phonePermission = await Permission.phone.request();
      final callLogPermission = await Permission.phone.request();

      return phonePermission.isGranted && callLogPermission.isGranted;
    } catch (e) {
      LoggerService.error('Error requesting permissions', e);
      return false;
    }
  }

  /// Check if permissions are granted
  Future<bool> hasPermissions() async {
    if (!Platform.isAndroid) {
      return false;
    }

    final phonePermission = await Permission.phone.status;
    return phonePermission.isGranted;
  }

  /// Fetch recent call logs from device
  Future<List<app_model.CallLog>> getRecentCallLogs({
    int daysBack = 7,
  }) async {
    if (!Platform.isAndroid) {
      LoggerService.warning('Call log access is only available on Android');
      return [];
    }

    try {
      final hasPermission = await hasPermissions();
      if (!hasPermission) {
        LoggerService.warning('Call log permissions not granted');
        return [];
      }

      final fromDate = DateTime.now().subtract(Duration(days: daysBack));
      final entries = await CallLog.query(
        dateFrom: fromDate.millisecondsSinceEpoch,
      );

      return entries.map((entry) => _convertToAppCallLog(entry)).toList();
    } catch (e, stackTrace) {
      LoggerService.error('Error fetching call logs', e, stackTrace);
      return [];
    }
  }

  /// Convert device CallLogEntry to app CallLog model
  app_model.CallLog _convertToAppCallLog(CallLogEntry entry) {
    final now = DateTime.now();
    final timestamp = DateTime.fromMillisecondsSinceEpoch(entry.timestamp ?? 0);
    return app_model.CallLog(
      id: '', // Will be set when syncing
      companyId: '', // Will be set when syncing
      userId: '', // Will be set when syncing
      phoneNumber: entry.number ?? '',
      callType: _convertCallType(entry.callType),
      timestamp: timestamp,
      duration: entry.duration,
      leadId: null, // Will be linked during sync
      notes: null,
      createdAt: now,
    );
  }

  /// Convert CallLog plugin call type to app call type
  String _convertCallType(CallType? callType) {
    switch (callType) {
      case CallType.incoming:
        return 'incoming';
      case CallType.outgoing:
        return 'outgoing';
      case CallType.missed:
        return 'missed';
      case CallType.rejected:
        return 'missed';
      default:
        return 'outgoing';
    }
  }

  /// Link call log to lead by matching phone number
  Future<String?> findMatchingLeadId(
    String phoneNumber,
    List<String> leadPhoneNumbers,
  ) async {
    try {
      // Remove all non-numeric characters for comparison
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');

      for (var i = 0; i < leadPhoneNumbers.length; i++) {
        final leadNumber = leadPhoneNumbers[i].replaceAll(RegExp(r'\D'), '');

        // Match if last 10 digits are the same (handles country codes)
        if (cleanNumber.length >= 10 && leadNumber.length >= 10) {
          final cleanLast10 = cleanNumber.substring(cleanNumber.length - 10);
          final leadLast10 = leadNumber.substring(leadNumber.length - 10);

          if (cleanLast10 == leadLast10) {
            return leadPhoneNumbers[i];
          }
        }
      }

      return null;
    } catch (e) {
      LoggerService.error('Error matching phone number', e);
      return null;
    }
  }

  /// Sync device call logs with Firestore
  Future<List<app_model.CallLog>> syncCallLogs({
    required String companyId,
    required String userId,
    int daysBack = 7,
  }) async {
    try {
      final deviceCallLogs = await getRecentCallLogs(daysBack: daysBack);

      // Add company and user IDs
      final syncedCallLogs = deviceCallLogs.map((callLog) {
        return callLog.copyWith(
          companyId: companyId,
          userId: userId,
        );
      }).toList();

      return syncedCallLogs;
    } catch (e, stackTrace) {
      LoggerService.error('Error syncing call logs', e, stackTrace);
      return [];
    }
  }
}
