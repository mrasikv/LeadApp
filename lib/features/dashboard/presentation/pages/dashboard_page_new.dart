import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
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
            _ProjectsTab(),
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
              icon: Icon(Icons.folder_outlined),
              activeIcon: Icon(Icons.folder),
              label: 'Projects',
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
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User greeting card
                  _WelcomeCard(user: authState.user),
                  const SizedBox(height: 24),

                  // Company Performance Insights
                  Text(
                    'Company Performance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _CompanyPerformanceCard(),
                  const SizedBox(height: 24),

                  // Quick Stats Grid
                  _QuickStatsSection(),
                  const SizedBox(height: 24),

                  // Recent Projects Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Projects',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.push('/projects'),
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _RecentProjectsSection(),
                  const SizedBox(height: 24),

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _QuickActionsSection(),
                  const SizedBox(height: 80), // Bottom padding for FAB
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/projects/create'),
            icon: const Icon(Icons.add),
            label: const Text('New Project'),
          ),
        );
      },
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
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (user.currentRoleId != null)
                    Text(
                      user.currentRoleId!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    return 'Good evening!';
  }
}

class _CompanyPerformanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeadBloc, LeadState>(
      builder: (context, leadState) {
        return BlocBuilder<ProjectBloc, ProjectState>(
          builder: (context, projectState) {
            int totalLeads = 0;
            int totalProjects = 0;
            int activeProjects = 0;
            int wonLeads = 0;
            int activeLeads = 0;
            double conversionRate = 0.0;

            if (leadState is LeadsLoaded) {
              totalLeads = leadState.leads.length;
            }

            if (projectState is ProjectsLoaded) {
              totalProjects = projectState.projects.length;
              activeProjects =
                  projectState.projects.where((p) => p.isActive).length;
              wonLeads = projectState.projects
                  .fold(0, (sum, p) => sum + p.wonLeadCount);
              activeLeads = projectState.projects
                  .fold(0, (sum, p) => sum + p.activeLeadCount);

              if (totalLeads > 0) {
                conversionRate = (wonLeads / totalLeads) * 100;
              }
            }

            return Card(
              color: AppColors.primary.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _PerformanceMetric(
                            icon: Icons.folder,
                            value: totalProjects.toString(),
                            label: 'Total Projects',
                            color: AppColors.primary,
                          ),
                        ),
                        Container(
                          height: 50,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        Expanded(
                          child: _PerformanceMetric(
                            icon: Icons.people,
                            value: totalLeads.toString(),
                            label: 'Total Leads',
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: _PerformanceMetric(
                            icon: Icons.trending_up,
                            value: activeLeads.toString(),
                            label: 'Active Leads',
                            color: Colors.orange,
                          ),
                        ),
                        Container(
                          height: 50,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        Expanded(
                          child: _PerformanceMetric(
                            icon: Icons.emoji_events,
                            value: '${conversionRate.toStringAsFixed(1)}%',
                            label: 'Conversion Rate',
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PerformanceMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _PerformanceMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}

class _QuickStatsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeadBloc, LeadState>(
      builder: (context, leadState) {
        int todayLeads = 0;
        int weekLeads = 0;
        int monthLeads = 0;
        int pendingFollowUps = 0;

        if (leadState is LeadsLoaded) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final weekAgo = today.subtract(const Duration(days: 7));
          final monthAgo = DateTime(now.year, now.month - 1, now.day);

          todayLeads =
              leadState.leads.where((l) => l.createdAt.isAfter(today)).length;
          weekLeads =
              leadState.leads.where((l) => l.createdAt.isAfter(weekAgo)).length;
          monthLeads = leadState.leads
              .where((l) => l.createdAt.isAfter(monthAgo))
              .length;

          // Simulate pending follow-ups
          pendingFollowUps = (leadState.leads.length * 0.2).round();
        }

        return Row(
          children: [
            Expanded(
              child: _QuickStatCard(
                title: 'Today',
                count: todayLeads,
                icon: Icons.today,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickStatCard(
                title: 'This Week',
                count: weekLeads,
                icon: Icons.date_range,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickStatCard(
                title: 'This Month',
                count: monthLeads,
                icon: Icons.calendar_month,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickStatCard(
                title: 'Follow-ups',
                count: pendingFollowUps,
                icon: Icons.schedule,
                color: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _QuickStatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentProjectsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectBloc, ProjectState>(
      builder: (context, state) {
        if (state is ProjectLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is ProjectsLoaded) {
          if (state.projects.isEmpty) {
            return _EmptyProjectsCard();
          }

          // Show only 3 most recent projects
          final recentProjects = state.projects.take(3).toList();

          return SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recentProjects.length + 1, // +1 for "View All" card
              itemBuilder: (context, index) {
                if (index == recentProjects.length) {
                  return _ViewAllProjectsCard();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 200,
                    child: _RecentProjectCard(
                      project: recentProjects[index],
                      onTap: () =>
                          context.push('/projects/${recentProjects[index].id}'),
                    ),
                  ),
                );
              },
            ),
          );
        }

        if (state is ProjectError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 32),
                  const SizedBox(height: 8),
                  Text('Error loading projects: ${state.error.message}'),
                ],
              ),
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

  const _RecentProjectCard({
    required this.project,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(project.color ?? '#2196F3');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 6,
              color: color,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: color.withOpacity(0.2),
                          radius: 16,
                          child: Icon(
                            _getIconData(project.icon ?? 'folder'),
                            color: color,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            project.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${project.leadCount}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            Text(
                              'Leads',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${project.wonLeadCount}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'Won',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.blue;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
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

class _ViewAllProjectsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Card(
        child: InkWell(
          onTap: () => context.push('/projects'),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyProjectsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.folder_open, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text('No projects yet'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.push('/projects/create'),
              icon: const Icon(Icons.add),
              label: const Text('Create Project'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.folder_copy,
            label: 'Projects',
            color: AppColors.primary,
            onTap: () => context.push('/projects'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.sync,
            label: 'Sync Calls',
            color: Colors.orange,
            onTap: () => context.push('/calls'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.track_changes,
            label: 'Targets',
            color: Colors.purple,
            onTap: () => context.push('/targets'),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tab: Projects (now links to full projects page)
class _ProjectsTab extends StatelessWidget {
  const _ProjectsTab();

  @override
  Widget build(BuildContext context) {
    // Redirect to full projects page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/projects');
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _CallsTab extends StatelessWidget {
  const _CallsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Call Logs')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Sync and view your call logs'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/calls'),
              child: const Text('Open Call Logs'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowUpsTab extends StatelessWidget {
  const _FollowUpsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Follow-ups')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Manage your follow-up schedule'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/follow-ups'),
              child: const Text('Open Follow-ups'),
            ),
          ],
        ),
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
          body: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/profile'),
              ),
              ListTile(
                leading: const Icon(Icons.track_changes),
                title: const Text('Targets'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/targets'),
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('All Leads'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/leads'),
              ),
              if (state is AuthAuthenticated && state.isCompanyAdmin) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('Company Admin'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/company-admin'),
                ),
              ],
              if (state is AuthAuthenticated && state.isSuperAdmin) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.supervisor_account),
                  title: const Text('Super Admin'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/super-admin'),
                ),
              ],
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('Logout',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.read<AuthBloc>().add(AuthLogoutEvent());
                          },
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
