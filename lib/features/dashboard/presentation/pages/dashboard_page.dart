import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/status_utils.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/models/project_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../leads/presentation/bloc/lead_bloc.dart';
import '../../../leads/presentation/bloc/lead_event.dart';
import '../../../leads/presentation/bloc/lead_state.dart';
import '../../../projects/presentation/bloc/project_bloc.dart';
import '../../../projects/presentation/bloc/project_event.dart';
import '../../../projects/presentation/bloc/project_state.dart';
import '../../../companies/presentation/widgets/company_switcher.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated &&
        authState.user.currentCompanyId != null) {
      context
          .read<LeadBloc>()
          .add(LoadLeadsEvent(authState.user.currentCompanyId!));
      context
          .read<ProjectBloc>()
          .add(LoadProjectsEvent(authState.user.currentCompanyId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = sl<ProjectBloc>();
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated &&
            authState.user.currentCompanyId != null) {
          bloc.add(LoadProjectsEvent(authState.user.currentCompanyId!));
        }
        return bloc;
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: const [
            _HomePage(),
            _LeadsTab(),
            _CallsTab(),
            _FollowUpsTab(),
            _MoreTab(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Leads',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.phone_outlined),
              activeIcon: Icon(Icons.phone),
              label: 'Calls',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_outlined),
              activeIcon: Icon(Icons.event),
              label: 'Follow-ups',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu),
              activeIcon: Icon(Icons.menu),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'create_project') {
                    context.push('/projects/create');
                  } else if (value == 'all_projects') {
                    context.push('/projects');
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'create_project',
                    child: ListTile(
                      leading: Icon(Icons.add),
                      title: Text('Create Project'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'all_projects',
                    child: ListTile(
                      leading: Icon(Icons.folder),
                      title: Text('All Projects'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              CompanySwitcher(
                currentUser: authState.user,
                onCompanyChanged: (company) {},
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              if (authState.user.currentCompanyId != null) {
                context
                    .read<LeadBloc>()
                    .add(LoadLeadsEvent(authState.user.currentCompanyId!));
                context
                    .read<ProjectBloc>()
                    .add(LoadProjectsEvent(authState.user.currentCompanyId!));
              }
            },
            child: BlocBuilder<ProjectBloc, ProjectState>(
              builder: (context, projectState) {
                if (projectState is ProjectsLoaded &&
                    projectState.projects.isEmpty) {
                  return _EmptyDashboard(
                    userName: authState.user.name,
                    onCreateProject: () => context.push('/projects/create'),
                  );
                }

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _WelcomeCard(user: authState.user),
                      const SizedBox(height: 24),
                      Text("Today's Overview",
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      const _DynamicStatsSection(),
                      const SizedBox(height: 24),
                      Text('Quick Actions',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _ActionCard(
                                  icon: Icons.folder_open,
                                  label: 'Projects',
                                  onTap: () => context.push('/projects'))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _ActionCard(
                                  icon: Icons.sync,
                                  label: 'Sync Calls',
                                  onTap: () => context.push('/calls'))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _ActionCard(
                                  icon: Icons.track_changes,
                                  label: 'Targets',
                                  onTap: () => context.push('/targets'))),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Projects',
                              style: Theme.of(context).textTheme.titleLarge),
                          TextButton(
                              onPressed: () => context.push('/projects'),
                              child: const Text('View All')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _RecentProjectsSection(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Leads',
                              style: Theme.of(context).textTheme.titleLarge),
                          TextButton(
                              onPressed: () => context.push('/leads'),
                              child: const Text('View All')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _RecentLeadsSection(),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  final String userName;
  final VoidCallback onCreateProject;
  const _EmptyDashboard(
      {required this.userName, required this.onCreateProject});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primaryContainer,
              child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
            ),
            const SizedBox(height: 24),
            Text('Welcome, $userName!',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Get started by creating your first project',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            Icon(Icons.folder_open, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onCreateProject,
              icon: const Icon(Icons.add),
              label: const Text('Create Project'),
              style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final dynamic user;
  const _WelcomeCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primaryContainer,
              child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back!',
                      style: Theme.of(context).textTheme.bodySmall),
                  Text(user.name,
                      style: Theme.of(context).textTheme.headlineSmall),
                  if (user.currentRoleId != null)
                    Text(user.currentRoleId!,
                        style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DynamicStatsSection extends StatelessWidget {
  const _DynamicStatsSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeadBloc, LeadState>(
      builder: (context, leadState) {
        int newCount = 0, followUpCount = 0, contactedCount = 0, totalCount = 0;
        if (leadState is LeadsLoaded) {
          final leads = leadState.leads;
          totalCount = leads.length;
          final now = DateTime.now();
          final tomorrow = DateTime(now.year, now.month, now.day)
              .add(const Duration(days: 1));

          for (final lead in leads) {
            // Count as new if statusId is empty
            if (lead.statusId.isEmpty) {
              newCount++;
            }
            // Count contacted leads
            if (lead.lastContactedAt != null) {
              contactedCount++;
            }
            // Count follow-ups due today or overdue
            if (lead.nextFollowUpAt != null &&
                lead.nextFollowUpAt!.isBefore(tomorrow)) {
              followUpCount++;
            }
          }
        }
        return Column(
          children: [
            Row(children: [
              Expanded(
                  child: _StatCard(
                      title: 'New',
                      count: newCount,
                      color: Colors.blue,
                      icon: Icons.fiber_new)),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatCard(
                      title: 'Follow-up Due',
                      count: followUpCount,
                      color: Colors.orange,
                      icon: Icons.phone_callback)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _StatCard(
                      title: 'Contacted',
                      count: contactedCount,
                      color: Colors.green,
                      icon: Icons.check_circle)),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatCard(
                      title: 'Total',
                      count: totalCount,
                      color: AppColors.primary,
                      icon: Icons.people)),
            ]),
          ],
        );
      },
    );
  }
}

class _RecentProjectsSection extends StatelessWidget {
  const _RecentProjectsSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectBloc, ProjectState>(
      builder: (context, projectState) {
        if (projectState is ProjectLoading)
          return const SizedBox(
              height: 120, child: Center(child: CircularProgressIndicator()));
        if (projectState is ProjectsLoaded) {
          final projects = projectState.projects.take(5).toList();
          if (projects.isEmpty) return const SizedBox.shrink();
          return SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return _RecentProjectCard(
                    project: project,
                    onTap: () => context.push('/projects/${project.id}'));
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _RecentProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  const _RecentProjectCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(project.color ?? '#2196F3');
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 6, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        CircleAvatar(
                            backgroundColor: color.withOpacity(0.2),
                            radius: 14,
                            child: Icon(_getIconData(project.icon ?? 'folder'),
                                color: color, size: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(project.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                      ]),
                      const Spacer(),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${project.leadCount} leads',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600])),
                            Text('${project.activeLeadCount} active',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.blue[600])),
                          ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.blue;
    }
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'real_estate':
        return Icons.home_work;
      case 'car':
        return Icons.directions_car;
      case 'insurance':
        return Icons.security;
      case 'education':
        return Icons.school;
      case 'healthcare':
        return Icons.local_hospital;
      case 'finance':
        return Icons.account_balance;
      case 'retail':
        return Icons.storefront;
      case 'technology':
        return Icons.computer;
      default:
        return Icons.folder;
    }
  }
}

class _RecentLeadsSection extends StatelessWidget {
  const _RecentLeadsSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeadBloc, LeadState>(
      builder: (context, leadState) {
        return BlocBuilder<ProjectBloc, ProjectState>(
          builder: (context, projectState) {
            if (leadState is LeadLoading)
              return const Center(child: CircularProgressIndicator());
            if (leadState is LeadsLoaded) {
              final recentLeads = leadState.leads.take(5).toList();
              Map<String, String> projectNames = {};
              if (projectState is ProjectsLoaded) {
                for (final p in projectState.projects)
                  projectNames[p.id] = p.name;
              }
              if (recentLeads.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(children: [
                      Icon(Icons.people_outline,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text('No leads yet',
                          style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 12),
                      TextButton(
                          onPressed: () => context.push('/projects'),
                          child: const Text('Go to Projects to add leads')),
                    ]),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentLeads.length,
                itemBuilder: (context, index) {
                  final lead = recentLeads[index];
                  final projectName =
                      projectNames[lead.projectId] ?? 'Unknown Project';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                          backgroundColor: AppColors.primaryContainer,
                          child: Text(
                              lead.name.isNotEmpty
                                  ? lead.name[0].toUpperCase()
                                  : '?',
                              style:
                                  const TextStyle(color: AppColors.primary))),
                      title: Text(lead.name),
                      subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lead.phone),
                            const SizedBox(height: 2),
                            Row(children: [
                              Icon(Icons.folder_outlined,
                                  size: 12, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Expanded(
                                  child: Text(projectName,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500]),
                                      overflow: TextOverflow.ellipsis)),
                            ]),
                          ]),
                      trailing: _buildStatusChip(lead.statusId),
                      onTap: () => context.push('/leads/${lead.id}'),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildStatusChip(String statusId) {
    final color = StatusUtils.getColor(statusId);
    final displayName = StatusUtils.getDisplayName(statusId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Text(displayName,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;
  const _StatCard(
      {required this.title,
      required this.count,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
                child:
                    Text(title, style: Theme.of(context).textTheme.bodyMedium)),
          ]),
          const SizedBox(height: 8),
          Text(count.toString(),
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(color: color, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionCard(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}

class _LeadsTab extends StatefulWidget {
  const _LeadsTab();
  @override
  State<_LeadsTab> createState() => _LeadsTabState();
}

class _LeadsTabState extends State<_LeadsTab> {
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadLeads();
  }

  void _loadLeads() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated &&
        authState.user.currentCompanyId != null) {
      context
          .read<LeadBloc>()
          .add(LoadLeadsEvent(authState.user.currentCompanyId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leads'), actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadLeads),
      ]),
      body: Column(children: [
        _buildInsightCards(),
        _buildStatusFilters(),
        const Divider(height: 1),
        Expanded(
          child: BlocBuilder<LeadBloc, LeadState>(
            builder: (context, state) {
              if (state is LeadLoading)
                return const Center(child: CircularProgressIndicator());
              if (state is LeadsLoaded) {
                var leads = state.leads;
                if (_selectedStatus != null) {
                  leads = leads.where((l) {
                    if (_selectedStatus == 'new')
                      return l.statusId.isEmpty ||
                          l.statusId.toLowerCase() == 'new';
                    return l.statusId.toLowerCase() ==
                        _selectedStatus!.toLowerCase();
                  }).toList();
                }
                if (leads.isEmpty) {
                  return Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                            _selectedStatus != null
                                ? 'No leads with status "$_selectedStatus"'
                                : 'No leads yet',
                            style: TextStyle(color: Colors.grey[600])),
                      ]));
                }
                return RefreshIndicator(
                  onRefresh: () async => _loadLeads(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: leads.length,
                    itemBuilder: (context, index) =>
                        _LeadListItem(lead: leads[index]),
                  ),
                );
              }
              if (state is LeadError) {
                return Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(state.error.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _loadLeads, child: const Text('Retry')),
                    ]));
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildInsightCards() {
    return BlocBuilder<LeadBloc, LeadState>(
      builder: (context, state) {
        int total = 0, newLeads = 0, contacted = 0, followUps = 0;
        if (state is LeadsLoaded) {
          total = state.leads.length;
          final now = DateTime.now();
          final tomorrow = DateTime(now.year, now.month, now.day)
              .add(const Duration(days: 1));

          for (final lead in state.leads) {
            // Count as new if statusId is empty or has default new status
            if (lead.statusId.isEmpty) {
              newLeads++;
            }
            // Count contacted leads (those with lastContactedAt)
            if (lead.lastContactedAt != null) {
              contacted++;
            }
            // Count follow-ups due today or overdue
            if (lead.nextFollowUpAt != null &&
                lead.nextFollowUpAt!.isBefore(tomorrow)) {
              followUps++;
            }
          }
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            _InsightCard(label: 'Total', count: total, color: Colors.blue),
            const SizedBox(width: 8),
            _InsightCard(label: 'New', count: newLeads, color: Colors.green),
            const SizedBox(width: 8),
            _InsightCard(
                label: 'Contacted', count: contacted, color: Colors.orange),
            const SizedBox(width: 8),
            _InsightCard(
                label: 'Follow-ups', count: followUps, color: Colors.purple),
          ]),
        );
      },
    );
  }

  Widget _buildStatusFilters() {
    final statuses = ['All', 'New', 'Contacted', 'Qualified', 'Won', 'Lost'];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected = (status == 'All' && _selectedStatus == null) ||
              (_selectedStatus?.toLowerCase() == status.toLowerCase());
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
                label: Text(status),
                selected: isSelected,
                onSelected: (selected) => setState(
                    () => _selectedStatus = status == 'All' ? null : status)),
          );
        },
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _InsightCard(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(children: [
            Text(count.toString(),
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ]),
        ),
      ),
    );
  }
}

class _LeadListItem extends StatelessWidget {
  final Lead lead;
  const _LeadListItem({required this.lead});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
            backgroundColor: AppColors.primaryContainer,
            child: Text(lead.name.isNotEmpty ? lead.name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primary))),
        title: Text(lead.name),
        subtitle: Text(lead.phone),
        trailing: _buildStatusChip(lead.statusId),
        onTap: () => context.push('/leads/${lead.id}'),
      ),
    );
  }

  Widget _buildStatusChip(String statusId) {
    final color = StatusUtils.getColor(statusId);
    final displayName = StatusUtils.getDisplayName(statusId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Text(displayName, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}

class _CallsTab extends StatelessWidget {
  const _CallsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Call Logs'), actions: [
        IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Calls',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing call logs...')))),
      ]),
      body: BlocBuilder<LeadBloc, LeadState>(
        builder: (context, state) {
          if (state is LeadsLoaded) {
            final leadsWithCalls = state.leads
                .where(
                    (l) => l.totalCallsCount > 0 || l.lastContactedAt != null)
                .toList();
            if (leadsWithCalls.isEmpty) {
              return Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Icon(Icons.phone_outlined,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('No call history yet',
                        style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Text('Call logs will appear here after syncing',
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 12)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                        onPressed: () => context.push('/calls'),
                        icon: const Icon(Icons.sync),
                        label: const Text('Sync Call Logs')),
                  ]));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: leadsWithCalls.length,
              itemBuilder: (context, index) {
                final lead = leadsWithCalls[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                        backgroundColor: AppColors.primaryContainer,
                        child: Icon(Icons.phone, color: AppColors.primary)),
                    title: Text(lead.name),
                    subtitle: Text(lead.lastContactedAt != null
                        ? 'Last call: ${DateFormat('MMM d, h:mm a').format(lead.lastContactedAt!)}'
                        : '${lead.totalCallsCount} calls'),
                    trailing: Text('${lead.totalCallsCount}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                    onTap: () => context.push('/leads/${lead.id}'),
                  ),
                );
              },
            );
          }
          if (state is LeadLoading)
            return const Center(child: CircularProgressIndicator());
          return Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Icon(Icons.phone_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                    onPressed: () => context.push('/calls'),
                    icon: const Icon(Icons.sync),
                    label: const Text('Open Call Logs')),
              ]));
        },
      ),
    );
  }
}

class _FollowUpsTab extends StatefulWidget {
  const _FollowUpsTab();
  @override
  State<_FollowUpsTab> createState() => _FollowUpsTabState();
}

class _FollowUpsTabState extends State<_FollowUpsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Lead> _getOverdueLeads(List<Lead> leads) {
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return leads
        .where((l) =>
            l.nextFollowUpAt != null && l.nextFollowUpAt!.isBefore(today))
        .toList();
  }

  List<Lead> _getTodayLeads(List<Lead> leads) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return leads
        .where((l) =>
            l.nextFollowUpAt != null &&
            l.nextFollowUpAt!
                .isAfter(today.subtract(const Duration(seconds: 1))) &&
            l.nextFollowUpAt!.isBefore(tomorrow))
        .toList();
  }

  List<Lead> _getUpcomingLeads(List<Lead> leads) {
    final tomorrow =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
            .add(const Duration(days: 1));
    return leads
        .where((l) =>
            l.nextFollowUpAt != null &&
            l.nextFollowUpAt!
                .isAfter(tomorrow.subtract(const Duration(seconds: 1))))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Follow-ups'),
          bottom: TabBar(controller: _tabController, tabs: const [
            Tab(text: 'Overdue'),
            Tab(text: 'Today'),
            Tab(text: 'Upcoming')
          ])),
      body: BlocBuilder<LeadBloc, LeadState>(
        builder: (context, state) {
          if (state is LeadLoading)
            return const Center(child: CircularProgressIndicator());
          if (state is LeadsLoaded) {
            return TabBarView(controller: _tabController, children: [
              _buildFollowUpList(_getOverdueLeads(state.leads), 'overdue'),
              _buildFollowUpList(_getTodayLeads(state.leads), 'today'),
              _buildFollowUpList(_getUpcomingLeads(state.leads), 'upcoming'),
            ]);
          }
          return const Center(child: Text('No follow-ups'));
        },
      ),
    );
  }

  Widget _buildFollowUpList(List<Lead> leads, String type) {
    if (leads.isEmpty) {
      String message;
      IconData icon;
      Color color;
      switch (type) {
        case 'overdue':
          message = 'No overdue follow-ups';
          icon = Icons.check_circle;
          color = Colors.green;
          break;
        case 'today':
          message = 'No follow-ups for today';
          icon = Icons.event_available;
          color = Colors.blue;
          break;
        default:
          message = 'No upcoming follow-ups';
          icon = Icons.event_note;
          color = Colors.grey;
      }
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 64, color: color.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text(message, style: TextStyle(color: Colors.grey[600])),
      ]));
    }
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: leads.length,
        itemBuilder: (context, index) =>
            _FollowUpCard(lead: leads[index], type: type));
  }
}

class _FollowUpCard extends StatelessWidget {
  final Lead lead;
  final String type;
  const _FollowUpCard({required this.lead, required this.type});

  @override
  Widget build(BuildContext context) {
    Color bgColor, textColor;
    switch (type) {
      case 'overdue':
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        break;
      case 'today':
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        break;
      default:
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
            backgroundColor: bgColor,
            child: Icon(Icons.event, color: textColor)),
        title: Text(lead.name),
        subtitle: Text(lead.nextFollowUpAt != null
            ? DateFormat('MMM d, yyyy - h:mm a').format(lead.nextFollowUpAt!)
            : 'No date set'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: bgColor, borderRadius: BorderRadius.circular(12)),
          child: Text(
              type == 'overdue'
                  ? 'Overdue'
                  : type == 'today'
                      ? 'Today'
                      : 'Upcoming',
              style: TextStyle(fontSize: 11, color: textColor)),
        ),
        onTap: () => context.push('/leads/${lead.id}'),
      ),
    );
  }
}

class _MoreTab extends StatelessWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('More')),
          body: ListView(children: [
            ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/profile')),
            ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('All Projects'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/projects')),
            ListTile(
                leading: const Icon(Icons.track_changes),
                title: const Text('Targets'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/targets')),
            if (state is AuthAuthenticated && state.isCompanyAdmin) ...[
              const Divider(),
              ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('Company Admin'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/company-admin')),
            ],
            if (state is AuthAuthenticated && state.isSuperAdmin) ...[
              const Divider(),
              ListTile(
                  leading: const Icon(Icons.supervisor_account),
                  title: const Text('Super Admin'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/super-admin')),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Logout',
                  style: TextStyle(color: AppColors.error)),
              onTap: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.read<AuthBloc>().add(AuthLogoutEvent());
                        },
                        child: const Text('Logout')),
                  ],
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}
