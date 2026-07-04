import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/lead_model.dart';
import '../../leads/presentation/bloc/lead_bloc.dart';
import '../../leads/presentation/bloc/lead_event.dart';
import '../../leads/presentation/bloc/lead_state.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';

class FollowUpsPage extends StatefulWidget {
  const FollowUpsPage({super.key});

  @override
  State<FollowUpsPage> createState() => _FollowUpsPageState();
}

class _FollowUpsPageState extends State<FollowUpsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _companyId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Get current user info from AuthBloc
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _companyId = authState.user.currentCompanyId;
      _loadLeads();
    }
  }

  void _loadLeads() {
    if (_companyId != null) {
      context.read<LeadBloc>().add(LoadLeadsEvent(_companyId!));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Lead> _getOverdueLeads(List<Lead> leads) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return leads.where((lead) {
      if (lead.nextFollowUpAt == null) return false;
      return lead.nextFollowUpAt!.isBefore(today);
    }).toList();
  }

  List<Lead> _getTodayLeads(List<Lead> leads) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return leads.where((lead) {
      if (lead.nextFollowUpAt == null) return false;
      return lead.nextFollowUpAt!
              .isAfter(today.subtract(const Duration(seconds: 1))) &&
          lead.nextFollowUpAt!.isBefore(tomorrow);
    }).toList();
  }

  List<Lead> _getUpcomingLeads(List<Lead> leads) {
    final now = DateTime.now();
    final tomorrow =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    return leads.where((lead) {
      if (lead.nextFollowUpAt == null) return false;
      return lead.nextFollowUpAt!
          .isAfter(tomorrow.subtract(const Duration(seconds: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow-ups'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overdue'),
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeads,
          ),
        ],
      ),
      body: BlocBuilder<LeadBloc, LeadState>(
        builder: (context, state) {
          if (state is LeadLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is LeadsLoaded) {
            final overdue = _getOverdueLeads(state.leads);
            final today = _getTodayLeads(state.leads);
            final upcoming = _getUpcomingLeads(state.leads);

            return TabBarView(
              controller: _tabController,
              children: [
                _buildFollowUpList(overdue, 'overdue'),
                _buildFollowUpList(today, 'today'),
                _buildFollowUpList(upcoming, 'upcoming'),
              ],
            );
          }

          if (state is LeadError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.error.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadLeads,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('No follow-ups'));
        },
      ),
    );
  }

  Widget _buildFollowUpList(List<Lead> leads, String type) {
    if (leads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'overdue'
                  ? Icons.check_circle
                  : type == 'today'
                      ? Icons.today
                      : Icons.event,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              type == 'overdue'
                  ? 'No overdue follow-ups!'
                  : type == 'today'
                      ? 'No follow-ups for today'
                      : 'No upcoming follow-ups',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadLeads(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: leads.length,
        itemBuilder: (context, index) {
          final lead = leads[index];
          return _FollowUpCard(
            lead: lead,
            type: type,
            onTap: () => context.push('/leads/${lead.id}'),
            onMarkComplete: () => _markFollowUpComplete(lead),
            onReschedule: () => _rescheduleFollowUp(lead),
          );
        },
      ),
    );
  }

  void _markFollowUpComplete(Lead lead) {
    context.read<LeadBloc>().add(
          UpdateLeadEvent(lead.copyWith(nextFollowUpAt: null)),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Follow-up marked as complete')),
    );
  }

  void _rescheduleFollowUp(Lead lead) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 10, minute: 0),
      );

      if (time != null && mounted) {
        final newFollowUpDate = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        context.read<LeadBloc>().add(
              UpdateLeadEvent(lead.copyWith(nextFollowUpAt: newFollowUpDate)),
            );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Follow-up rescheduled to ${DateFormat('MMM dd, yyyy - hh:mm a').format(newFollowUpDate)}',
            ),
          ),
        );
      }
    }
  }
}

class _FollowUpCard extends StatelessWidget {
  final Lead lead;
  final String type;
  final VoidCallback onTap;
  final VoidCallback onMarkComplete;
  final VoidCallback onReschedule;

  const _FollowUpCard({
    required this.lead,
    required this.type,
    required this.onTap,
    required this.onMarkComplete,
    required this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = type == 'overdue';
    final cardColor = isOverdue ? Colors.red.shade50 : null;
    final timeColor = isOverdue ? Colors.red : Colors.blue;

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lead.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      lead.statusId.isEmpty ? 'New' : lead.statusId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    lead.phone,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.event, size: 16, color: timeColor),
                  const SizedBox(width: 4),
                  Text(
                    lead.nextFollowUpAt != null
                        ? DateFormat('MMM dd, yyyy - hh:mm a')
                            .format(lead.nextFollowUpAt!)
                        : 'No date set',
                    style: TextStyle(
                      color: timeColor,
                      fontWeight: isOverdue ? FontWeight.bold : null,
                    ),
                  ),
                  if (isOverdue) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getOverdueDuration(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onReschedule,
                    icon: const Icon(Icons.schedule, size: 18),
                    label: const Text('Reschedule'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onMarkComplete,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Complete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getOverdueDuration() {
    if (lead.nextFollowUpAt == null) return '';
    final difference = DateTime.now().difference(lead.nextFollowUpAt!);
    if (difference.inDays > 0) {
      return '${difference.inDays}d overdue';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h overdue';
    } else {
      return '${difference.inMinutes}m overdue';
    }
  }
}
