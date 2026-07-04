import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/call_log_model.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/call_logs_bloc.dart';

class CallLogsPage extends StatefulWidget {
  const CallLogsPage({super.key});

  @override
  State<CallLogsPage> createState() => _CallLogsPageState();
}

class _CallLogsPageState extends State<CallLogsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCallLogs();
  }

  void _loadCallLogs() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.currentCompany != null) {
      context.read<CallLogsBloc>().add(
            CallLogsLoadRequested(
              companyId: authState.currentCompany!.id!,
              userId: authState.user.id,
            ),
          );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync from device',
            onPressed: _syncFromDevice,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCallLogs,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Linked'),
            Tab(text: 'Unlinked'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats Section
          BlocBuilder<CallLogsBloc, CallLogsState>(
            builder: (context, state) {
              if (state is! CallLogsLoaded) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildStatCard(
                      context,
                      icon: Icons.call_made,
                      label: 'Outgoing',
                      value: state.outgoingCalls.toString(),
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      context,
                      icon: Icons.call_received,
                      label: 'Incoming',
                      value: state.incomingCalls.toString(),
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      context,
                      icon: Icons.call_missed,
                      label: 'Missed',
                      value: state.missedCalls.toString(),
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      context,
                      icon: Icons.timer,
                      label: 'Duration',
                      value: _formatDuration(state.totalDuration),
                      color: Colors.orange,
                    ),
                  ],
                ),
              );
            },
          ),

          // Sync Status
          BlocBuilder<CallLogsBloc, CallLogsState>(
            builder: (context, state) {
              if (state is CallLogsLoaded && state.isSyncing) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Syncing call logs from device...'),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Call Logs List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCallLogsList(filter: null),
                _buildCallLogsList(filter: 'linked'),
                _buildCallLogsList(filter: 'unlinked'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallLogsList({String? filter}) {
    return BlocBuilder<CallLogsBloc, CallLogsState>(
      builder: (context, state) {
        if (state is CallLogsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CallLogsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadCallLogs,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is CallLogsLoaded) {
          List<CallLog> logs;
          switch (filter) {
            case 'linked':
              logs = state.linkedCallLogs;
              break;
            case 'unlinked':
              logs = state.unlinkedCallLogs;
              break;
            default:
              logs = state.callLogs;
          }

          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.call_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No call logs',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _syncFromDevice,
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync from device'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadCallLogs(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return CallLogCard(
                  callLog: log,
                  onLinkToLead: log.leadId == null
                      ? () => _showLinkToLeadDialog(log)
                      : null,
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _syncFromDevice() async {
    // This would use platform channels to get device call logs
    // For now, show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Call log sync requires native implementation. '
          'Please implement CallLogService for your platform.',
        ),
      ),
    );
  }

  void _showLinkToLeadDialog(CallLog callLog) {
    // TODO: Show dialog to search and select a lead
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Link to Lead',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text('Phone: ${callLog.phoneNumber}'),
            const SizedBox(height: 16),
            const Text('Search for a lead to link this call to...'),
            const SizedBox(height: 24),
            // Add lead search here
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }
}

class CallLogCard extends StatelessWidget {
  final CallLog callLog;
  final VoidCallback? onLinkToLead;

  const CallLogCard({
    super.key,
    required this.callLog,
    this.onLinkToLead,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCallTypeColor(callLog.callType).withOpacity(0.2),
          child: Icon(
            _getCallTypeIcon(callLog.callType),
            color: _getCallTypeColor(callLog.callType),
          ),
        ),
        title: Text(
          callLog.phoneNumber,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Row(
          children: [
            Text(
              _formatCallType(callLog.callType),
              style: TextStyle(
                color: _getCallTypeColor(callLog.callType),
              ),
            ),
            const Text(' • '),
            Text(_formatDuration(callLog.duration ?? 0)),
            const Text(' • '),
            Text(_formatTime(callLog.timestamp)),
          ],
        ),
        trailing: callLog.leadId != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.link,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Linked',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              )
            : IconButton(
                icon: const Icon(Icons.add_link),
                onPressed: onLinkToLead,
                tooltip: 'Link to lead',
              ),
      ),
    );
  }

  IconData _getCallTypeIcon(String callType) {
    switch (callType) {
      case 'incoming':
        return Icons.call_received;
      case 'outgoing':
        return Icons.call_made;
      case 'missed':
        return Icons.call_missed;
      default:
        return Icons.call;
    }
  }

  Color _getCallTypeColor(String callType) {
    switch (callType) {
      case 'incoming':
        return Colors.blue;
      case 'outgoing':
        return Colors.green;
      case 'missed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatCallType(String callType) {
    return callType[0].toUpperCase() + callType.substring(1);
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return '0s';
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'N/A';
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
