import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/call_log_model.dart';
import '../bloc/call_log_bloc.dart';
import '../bloc/call_log_event.dart';
import '../bloc/call_log_state.dart';

class CallLogsPage extends StatefulWidget {
  const CallLogsPage({super.key});

  @override
  State<CallLogsPage> createState() => _CallLogsPageState();
}

class _CallLogsPageState extends State<CallLogsPage> {
  @override
  void initState() {
    super.initState();
    // TODO: Get companyId from auth context
    const companyId = 'current_company_id';
    context.read<CallLogBloc>().add(const LoadCallLogsEvent(companyId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncCallLogs,
            tooltip: 'Sync from Device',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              const companyId = 'current_company_id';
              context
                  .read<CallLogBloc>()
                  .add(const LoadCallLogsEvent(companyId));
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocConsumer<CallLogBloc, CallLogState>(
        listener: (context, state) {
          if (state is CallLogsSynced) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Synced ${state.syncedCount} call logs'),
                backgroundColor: AppColors.success,
              ),
            );
            // Reload call logs after sync
            const companyId = 'current_company_id';
            context.read<CallLogBloc>().add(const LoadCallLogsEvent(companyId));
          }
          if (state is CallLogError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CallLogLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CallLogSyncing) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Syncing call logs... ${state.progress}%'),
                ],
              ),
            );
          }

          if (state is CallLogsLoaded) {
            final callLogs = state.callLogs;

            if (callLogs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone_missed,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No call logs found'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _syncCallLogs,
                      icon: const Icon(Icons.sync),
                      label: const Text('Sync from Device'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                const companyId = 'current_company_id';
                context
                    .read<CallLogBloc>()
                    .add(const LoadCallLogsEvent(companyId));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: callLogs.length,
                itemBuilder: (context, index) {
                  final callLog = callLogs[index];
                  return _CallLogCard(
                    callLog: callLog,
                    onLinkToLead: () => _showLinkToLeadDialog(callLog),
                  );
                },
              ),
            );
          }

          return const Center(child: Text('No data'));
        },
      ),
    );
  }

  void _syncCallLogs() {
    // TODO: Get companyId and userId from auth context
    const companyId = 'current_company_id';
    const userId = 'current_user_id';

    context.read<CallLogBloc>().add(const SyncDeviceCallLogsEvent(
          companyId: companyId,
          userId: userId,
          daysBack: 7,
        ));
  }

  void _showLinkToLeadDialog(CallLog callLog) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Link to Lead'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Phone: ${callLog.phoneNumber}'),
            const SizedBox(height: 16),
            // TODO: Add lead search/selection
            const Text('Lead search coming soon...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _CallLogCard extends StatelessWidget {
  final CallLog callLog;
  final VoidCallback onLinkToLead;

  const _CallLogCard({
    required this.callLog,
    required this.onLinkToLead,
  });

  @override
  Widget build(BuildContext context) {
    final isIncoming = callLog.callType == 'incoming';
    final isMissed = callLog.callType == 'missed';
    final callIcon = isMissed
        ? Icons.phone_missed
        : isIncoming
            ? Icons.phone_callback
            : Icons.phone_forwarded;
    final callColor = isMissed
        ? AppColors.error
        : isIncoming
            ? AppColors.success
            : AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: callColor.withOpacity(0.1),
          child: Icon(callIcon, color: callColor),
        ),
        title: Text(
          callLog.phoneNumber,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _formatCallType(callLog.callType),
                  style: TextStyle(color: callColor),
                ),
                const SizedBox(width: 8),
                Text('${callLog.duration ?? 0}s'),
                const SizedBox(width: 8),
                Text(_formatDate(callLog.timestamp)),
              ],
            ),
          ],
        ),
        trailing: callLog.leadId == null
            ? IconButton(
                icon: const Icon(Icons.link),
                onPressed: onLinkToLead,
                tooltip: 'Link to Lead',
              )
            : const Icon(Icons.check_circle, color: AppColors.success),
        isThreeLine: false,
      ),
    );
  }

  String _formatCallType(String type) {
    switch (type) {
      case 'incoming':
        return 'Incoming';
      case 'outgoing':
        return 'Outgoing';
      case 'missed':
        return 'Missed';
      default:
        return type;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
