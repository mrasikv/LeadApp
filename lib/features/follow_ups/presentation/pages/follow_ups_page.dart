import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../leads/presentation/bloc/lead_bloc.dart';
import '../../../leads/presentation/bloc/lead_event.dart';
import '../../../leads/presentation/bloc/lead_state.dart';

class FollowUpsPage extends StatefulWidget {
  const FollowUpsPage({super.key});

  @override
  State<FollowUpsPage> createState() => _FollowUpsPageState();
}

class _FollowUpsPageState extends State<FollowUpsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFollowUps();
  }

  void _loadFollowUps() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated &&
        authState.user.currentCompanyId != null) {
      context.read<LeadBloc>().add(
            LoadLeadsEvent(authState.user.currentCompanyId!),
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
        title: const Text('Follow-ups'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Overdue'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFollowUpDialog(),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<LeadBloc, LeadState>(
        builder: (context, state) {
          if (state is LeadLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildFollowUpList('today'),
              _buildFollowUpList('upcoming'),
              _buildFollowUpList('overdue'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFollowUpList(String type) {
    // Placeholder follow-ups
    final followUps = _getPlaceholderFollowUps(type);

    if (followUps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'overdue' ? Icons.check_circle : Icons.event_available,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              type == 'overdue'
                  ? 'No overdue follow-ups!'
                  : 'No follow-ups scheduled',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: followUps.length,
      itemBuilder: (context, index) {
        final followUp = followUps[index];
        return _buildFollowUpCard(followUp, type);
      },
    );
  }

  Widget _buildFollowUpCard(Map<String, dynamic> followUp, String type) {
    Color statusColor;
    switch (type) {
      case 'overdue':
        statusColor = AppColors.error;
        break;
      case 'today':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = AppColors.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/leads/${followUp['leadId']}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      followUp['leadName'][0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          followUp['leadName'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          followUp['phone'] as String,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          followUp['time'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notes, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        followUp['notes'] as String,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _markAsComplete(followUp),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Complete'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _rescheduleFollowUp(followUp),
                    icon: const Icon(Icons.schedule, size: 18),
                    label: const Text('Reschedule'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getPlaceholderFollowUps(String type) {
    final now = DateTime.now();
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    switch (type) {
      case 'today':
        return [
          {
            'leadId': '1',
            'leadName': 'John Smith',
            'phone': '+1 234 567 890',
            'time': timeFormat.format(now.add(const Duration(hours: 2))),
            'notes': 'Discuss pricing options and send proposal',
          },
          {
            'leadId': '2',
            'leadName': 'Sarah Johnson',
            'phone': '+1 345 678 901',
            'time': timeFormat.format(now.add(const Duration(hours: 4))),
            'notes': 'Follow up on demo request',
          },
        ];
      case 'upcoming':
        return [
          {
            'leadId': '3',
            'leadName': 'Michael Brown',
            'phone': '+1 456 789 012',
            'time': dateFormat.format(now.add(const Duration(days: 1))),
            'notes': 'Check if they reviewed the contract',
          },
          {
            'leadId': '4',
            'leadName': 'Emily Davis',
            'phone': '+1 567 890 123',
            'time': dateFormat.format(now.add(const Duration(days: 3))),
            'notes': 'Quarterly check-in call',
          },
        ];
      case 'overdue':
        return [
          {
            'leadId': '5',
            'leadName': 'Robert Wilson',
            'phone': '+1 678 901 234',
            'time': dateFormat.format(now.subtract(const Duration(days: 2))),
            'notes': 'Was supposed to send requirements document',
          },
        ];
      default:
        return [];
    }
  }

  void _markAsComplete(Map<String, dynamic> followUp) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Follow-up for ${followUp['leadName']} marked as complete'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {},
        ),
      ),
    );
    setState(() {});
  }

  void _rescheduleFollowUp(Map<String, dynamic> followUp) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((date) {
      if (date != null) {
        showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        ).then((time) {
          if (time != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Follow-up rescheduled to ${DateFormat('MMM dd').format(date)} at ${time.format(context)}',
                ),
              ),
            );
          }
        });
      }
    });
  }

  void _showAddFollowUpDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule Follow-up',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Search Lead',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Select Date & Time'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null && mounted) {
                  await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Notes',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Follow-up scheduled!')),
                      );
                    },
                    child: const Text('Schedule'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
