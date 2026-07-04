import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/utils/status_utils.dart';
import '../../../leads/presentation/bloc/lead_bloc.dart';
import '../../../leads/presentation/bloc/lead_event.dart';
import '../../../leads/presentation/bloc/lead_state.dart';
import '../bloc/project_bloc.dart';
import '../bloc/project_event.dart';
import '../bloc/project_state.dart';

enum LeadViewMode { card, list }

class ProjectDetailPage extends StatelessWidget {
  final String projectId;

  const ProjectDetailPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<ProjectBloc>()..add(LoadProjectEvent(projectId)),
        ),
        BlocProvider(
          create: (_) => sl<LeadBloc>(),
        ),
      ],
      child: _ProjectDetailView(projectId: projectId),
    );
  }
}

class _ProjectDetailView extends StatefulWidget {
  final String projectId;

  const _ProjectDetailView({required this.projectId});

  @override
  State<_ProjectDetailView> createState() => _ProjectDetailViewState();
}

class _ProjectDetailViewState extends State<_ProjectDetailView>
    with SingleTickerProviderStateMixin {
  LeadViewMode _viewMode = LeadViewMode.list;
  String? _selectedStatusId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectBloc, ProjectState>(
      builder: (context, projectState) {
        if (projectState is ProjectLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (projectState is ProjectLoaded) {
          final project = projectState.project;
          final projectColor = _parseColor(project.color ?? '#2196F3');

          return Scaffold(
            appBar: AppBar(
              title: Text(project.name),
              backgroundColor: projectColor.withOpacity(0.1),
              foregroundColor: projectColor,
              actions: [
                IconButton(
                  icon: Icon(
                    _viewMode == LeadViewMode.card
                        ? Icons.view_list
                        : Icons.grid_view,
                  ),
                  tooltip: _viewMode == LeadViewMode.card
                      ? 'Switch to List View'
                      : 'Switch to Card View',
                  onPressed: () {
                    setState(() {
                      _viewMode = _viewMode == LeadViewMode.card
                          ? LeadViewMode.list
                          : LeadViewMode.card;
                    });
                  },
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit Project'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: ListTile(
                        leading: Icon(Icons.settings),
                        title: Text('Project Settings'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      context.push('/projects/create', extra: project);
                    } else if (value == 'settings') {
                      _showProjectSettings(
                          context, project, context.read<ProjectBloc>());
                    }
                  },
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                labelColor: projectColor,
                indicatorColor: projectColor,
                tabs: const [
                  Tab(text: 'Leads'),
                  Tab(text: 'Analytics'),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _LeadsTabContent(
                  projectId: widget.projectId,
                  viewMode: _viewMode,
                  selectedStatusId: _selectedStatusId,
                  onStatusSelected: (statusId) {
                    setState(() {
                      _selectedStatusId = statusId;
                    });
                  },
                ),
                _AnalyticsTabContent(project: project),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () =>
                  context.push('/projects/${widget.projectId}/leads/create'),
              backgroundColor: projectColor,
              icon: const Icon(Icons.add),
              label: const Text('New Lead'),
            ),
          );
        }

        if (projectState is ProjectError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${projectState.error.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<ProjectBloc>()
                          .add(LoadProjectEvent(widget.projectId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('Project not found')),
        );
      },
    );
  }

  void _showProjectSettings(
      BuildContext context, Project project, ProjectBloc projectBloc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Project Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Lead Statuses (Project-specific)
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.flag),
                    ),
                    title: const Text('Lead Statuses'),
                    subtitle:
                        const Text('Manage status workflow for this project'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showProjectStatusesManager(
                          context, project, projectBloc);
                    },
                  ),
                  const Divider(),

                  // Custom Fields
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.text_fields),
                    ),
                    title: const Text('Custom Fields'),
                    subtitle: const Text('Add custom fields for leads'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showCustomFieldsManager(context, project, projectBloc);
                    },
                  ),
                  const Divider(),

                  // Project Info
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.edit),
                    ),
                    title: const Text('Edit Project'),
                    subtitle: const Text(
                        'Change project name, color, and description'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(ctx);
                      // Navigate to edit project (use create page with existing project)
                      context.push('/projects/create', extra: project);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomFieldsManager(
      BuildContext context, Project project, ProjectBloc projectBloc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: projectBloc,
        child: _CustomFieldsSheet(
          project: project,
          onSave: (fields) {
            // Save custom fields to project via Bloc
            final updatedProject = project.copyWith(
              customFields: fields,
              updatedAt: DateTime.now(),
            );
            projectBloc.add(UpdateProjectEvent(updatedProject));

            // Close the modal first
            if (Navigator.canPop(ctx)) {
              Navigator.pop(ctx);
            }

            // Show snackbar and reload
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final messenger = ScaffoldMessenger.maybeOf(context);
              if (messenger != null) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Custom fields saved'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              projectBloc.add(LoadProjectEvent(project.id));
            });
          },
        ),
      ),
    );
  }

  void _showProjectStatusesManager(
      BuildContext context, Project project, ProjectBloc projectBloc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: projectBloc,
        child: _ProjectStatusesSheet(
          project: project,
          onSave: (statuses) {
            // Save statuses to project via Bloc
            final updatedProject = project.copyWith(
              statuses: statuses,
              updatedAt: DateTime.now(),
            );
            projectBloc.add(UpdateProjectEvent(updatedProject));

            // Close the modal first
            if (Navigator.canPop(ctx)) {
              Navigator.pop(ctx);
            }

            // Show snackbar and reload
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final messenger = ScaffoldMessenger.maybeOf(context);
              if (messenger != null) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Statuses saved'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              projectBloc.add(LoadProjectEvent(project.id));
            });
          },
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
}

class _LeadsTabContent extends StatefulWidget {
  final String projectId;
  final LeadViewMode viewMode;
  final String? selectedStatusId;
  final Function(String?) onStatusSelected;

  const _LeadsTabContent({
    required this.projectId,
    required this.viewMode,
    required this.selectedStatusId,
    required this.onStatusSelected,
  });

  @override
  State<_LeadsTabContent> createState() => _LeadsTabContentState();
}

class _LeadsTabContentState extends State<_LeadsTabContent> {
  bool _statusGridView = false;

  @override
  void initState() {
    super.initState();
    // Load leads for this project
    context.read<LeadBloc>().add(LoadLeadsByProjectEvent(widget.projectId));
  }

  Map<String, int> _countLeadsByStatus(List<Lead> leads) {
    final counts = <String, int>{};
    for (final lead in leads) {
      final status =
          lead.statusId.isEmpty ? 'new' : lead.statusId.toLowerCase();
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  Widget _buildStatusScroll(
    List<Map<String, dynamic>> statusList,
    Map<String, int> statusCounts,
    int totalCount,
  ) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _StatusChip(
            label: 'All',
            count: totalCount,
            color: Colors.grey,
            isSelected: widget.selectedStatusId == null,
            onTap: () => widget.onStatusSelected(null),
          ),
          const SizedBox(width: 8),
          ...statusList.map((status) {
            final statusId = status['id'] as String;
            final count = statusCounts[statusId] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _StatusChip(
                label: status['name'] as String,
                count: count,
                color: status['color'] as Color,
                isSelected: widget.selectedStatusId == statusId,
                onTap: () => widget.onStatusSelected(statusId),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusGrid(
    List<Map<String, dynamic>> statusList,
    Map<String, int> statusCounts,
    int totalCount,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatusChip(
          label: 'All',
          count: totalCount,
          color: Colors.grey,
          isSelected: widget.selectedStatusId == null,
          onTap: () => widget.onStatusSelected(null),
        ),
        ...statusList.map((status) {
          final statusId = status['id'] as String;
          final count = statusCounts[statusId] ?? 0;
          return _StatusChip(
            label: status['name'] as String,
            count: count,
            color: status['color'] as Color,
            isSelected: widget.selectedStatusId == statusId,
            onTap: () => widget.onStatusSelected(statusId),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeadBloc, LeadState>(
      builder: (context, leadState) {
        final allLeads = leadState is LeadsLoaded ? leadState.leads : <Lead>[];
        final statusCounts = _countLeadsByStatus(allLeads);

        // Filter leads by selected status
        final filteredLeads = widget.selectedStatusId == null
            ? allLeads
            : allLeads.where((lead) {
                final status =
                    lead.statusId.isEmpty ? 'new' : lead.statusId.toLowerCase();
                return status == widget.selectedStatusId;
              }).toList();

        final statusList = [
          {'id': 'new', 'name': 'New', 'color': Colors.blue},
          {'id': 'contacted', 'name': 'Contacted', 'color': Colors.orange},
          {'id': 'qualified', 'name': 'Qualified', 'color': Colors.purple},
          {'id': 'proposal', 'name': 'Proposal', 'color': Colors.teal},
          {'id': 'negotiation', 'name': 'Negotiation', 'color': Colors.amber},
          {'id': 'won', 'name': 'Won', 'color': Colors.green},
          {'id': 'lost', 'name': 'Lost', 'color': Colors.red},
        ];

        return Column(
          children: [
            // Status filter chips (horizontal scroll or grid)
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter by Status',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      IconButton(
                        icon: Icon(
                          _statusGridView ? Icons.view_list : Icons.grid_view,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _statusGridView = !_statusGridView);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _statusGridView
                      ? _buildStatusGrid(
                          statusList, statusCounts, allLeads.length)
                      : _buildStatusScroll(
                          statusList, statusCounts, allLeads.length),
                ],
              ),
            ),
            const Divider(height: 1),

            // Leads list/grid
            Expanded(
              child: Builder(
                builder: (context) {
                  if (leadState is LeadLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (filteredLeads.isNotEmpty) {
                    if (widget.viewMode == LeadViewMode.card) {
                      return _LeadCardView(leads: filteredLeads);
                    } else {
                      return _LeadListView(leads: filteredLeads);
                    }
                  }

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.selectedStatusId != null
                              ? 'No leads with this status'
                              : 'No leads yet',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first lead to get started',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.count,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadCardView extends StatelessWidget {
  final List<Lead> leads;

  const _LeadCardView({required this.leads});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: leads.length,
      itemBuilder: (context, index) {
        final lead = leads[index];
        return _LeadCard(lead: lead);
      },
    );
  }
}

class _LeadCard extends StatelessWidget {
  final Lead lead;

  const _LeadCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/leads/${lead.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      lead.name.isNotEmpty ? lead.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      lead.statusId.isEmpty ? 'New' : lead.statusId,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                lead.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                lead.phone,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              if (lead.email != null && lead.email!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  lead.email!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.call, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    '${lead.totalCallsCount}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.note, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    '${lead.totalNotesCount}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadListView extends StatelessWidget {
  final List<Lead> leads;

  const _LeadListView({required this.leads});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leads.length,
      itemBuilder: (context, index) {
        final lead = leads[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryContainer,
              child: Text(
                lead.name.isNotEmpty ? lead.name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
            title: Text(lead.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lead.phone),
                if (lead.email != null && lead.email!.isNotEmpty)
                  Text(
                    lead.email!,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      lead.statusId.isEmpty ? 'New' : lead.statusId,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${lead.totalCallsCount} calls',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            onTap: () => context.push('/leads/${lead.id}'),
          ),
        );
      },
    );
  }
}

class _AnalyticsTabContent extends StatelessWidget {
  final dynamic project;

  const _AnalyticsTabContent({required this.project});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeadBloc, LeadState>(
      builder: (context, leadState) {
        // Calculate analytics from actual leads
        int totalLeads = 0;
        int activeLeads = 0;
        int wonLeads = 0;
        int lostLeads = 0;
        int newLeads = 0;
        int contactedLeads = 0;
        int qualifiedLeads = 0;
        int proposalLeads = 0;
        int negotiationLeads = 0;

        if (leadState is LeadsLoaded) {
          totalLeads = leadState.leads.length;
          for (final lead in leadState.leads) {
            final status =
                lead.statusId.isEmpty ? 'new' : lead.statusId.toLowerCase();
            switch (status) {
              case 'new':
                newLeads++;
                activeLeads++;
                break;
              case 'contacted':
                contactedLeads++;
                activeLeads++;
                break;
              case 'qualified':
                qualifiedLeads++;
                activeLeads++;
                break;
              case 'proposal':
                proposalLeads++;
                activeLeads++;
                break;
              case 'negotiation':
                negotiationLeads++;
                activeLeads++;
                break;
              case 'won':
                wonLeads++;
                break;
              case 'lost':
                lostLeads++;
                break;
              default:
                activeLeads++;
            }
          }
        }

        final conversionRate =
            totalLeads > 0 ? (wonLeads / totalLeads) * 100 : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: _AnalyticCard(
                      title: 'Total Leads',
                      value: totalLeads.toString(),
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AnalyticCard(
                      title: 'Active',
                      value: activeLeads.toString(),
                      icon: Icons.trending_up,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AnalyticCard(
                      title: 'Won',
                      value: wonLeads.toString(),
                      icon: Icons.emoji_events,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AnalyticCard(
                      title: 'Lost',
                      value: lostLeads.toString(),
                      icon: Icons.cancel,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AnalyticCard(
                      title: 'Conversion',
                      value: '${conversionRate.toStringAsFixed(1)}%',
                      icon: Icons.percent,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Status Distribution',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatusRow('New', newLeads, totalLeads, Colors.blue),
                      _buildStatusRow('Contacted', contactedLeads, totalLeads,
                          Colors.orange),
                      _buildStatusRow('Qualified', qualifiedLeads, totalLeads,
                          Colors.purple),
                      _buildStatusRow(
                          'Proposal', proposalLeads, totalLeads, Colors.teal),
                      _buildStatusRow('Negotiation', negotiationLeads,
                          totalLeads, Colors.amber),
                      _buildStatusRow(
                          'Won', wonLeads, totalLeads, Colors.green),
                      _buildStatusRow(
                          'Lost', lostLeads, totalLeads, Colors.red),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusRow(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              '${percentage.toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AnalyticCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Fields Manager Sheet
class _CustomFieldsSheet extends StatefulWidget {
  final Project project;
  final Function(List<Map<String, dynamic>>) onSave;

  const _CustomFieldsSheet({required this.project, required this.onSave});

  @override
  State<_CustomFieldsSheet> createState() => _CustomFieldsSheetState();
}

class _CustomFieldsSheetState extends State<_CustomFieldsSheet> {
  late List<Map<String, dynamic>> _fields;
  final _fieldNameController = TextEditingController();
  String _selectedType = 'text';
  bool _isRequired = false;

  final _fieldTypes = [
    {'id': 'text', 'name': 'Text', 'icon': Icons.text_fields},
    {'id': 'number', 'name': 'Number', 'icon': Icons.numbers},
    {'id': 'date', 'name': 'Date', 'icon': Icons.calendar_today},
    {
      'id': 'dropdown',
      'name': 'Dropdown',
      'icon': Icons.arrow_drop_down_circle
    },
    {'id': 'checkbox', 'name': 'Checkbox', 'icon': Icons.check_box},
  ];

  @override
  void initState() {
    super.initState();
    // Load existing custom fields from project
    _fields = List<Map<String, dynamic>>.from(
      widget.project.customFields.map((f) => Map<String, dynamic>.from(f)),
    );
  }

  @override
  void dispose() {
    _fieldNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Custom Fields',
                    style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Add new field section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add New Field',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _fieldNameController,
                            decoration: const InputDecoration(
                              labelText: 'Field Name',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedType,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: _fieldTypes
                                .map((type) => DropdownMenuItem(
                                      value: type['id'] as String,
                                      child: Text(type['name'] as String),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedType = value!);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text('Required Field'),
                      subtitle: const Text('User must fill this field'),
                      value: _isRequired,
                      onChanged: (value) {
                        setState(() => _isRequired = value ?? false);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (_fieldNameController.text.trim().isNotEmpty) {
                            setState(() {
                              _fields.add({
                                'name': _fieldNameController.text.trim(),
                                'type': _selectedType,
                                'required': _isRequired,
                              });
                              _fieldNameController.clear();
                              _isRequired = false;
                            });
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Field'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Existing fields list
            if (_fields.isNotEmpty) ...[
              Text('Fields (${_fields.length})',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _fields.length,
                  itemBuilder: (context, index) {
                    final field = _fields[index];
                    final typeInfo = _fieldTypes.firstWhere(
                      (t) => t['id'] == field['type'],
                      orElse: () => _fieldTypes.first,
                    );
                    final isRequired = field['required'] as bool? ?? false;
                    return Card(
                      child: ListTile(
                        leading: Icon(typeInfo['icon'] as IconData, size: 20),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              field['name'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isRequired)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  border:
                                      Border.all(color: Colors.red, width: 1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Required',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(typeInfo['name'] as String),
                        trailing: SizedBox(
                          width: 80,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isRequired ? Icons.star : Icons.star_border,
                                  color:
                                      isRequired ? Colors.amber : Colors.grey,
                                  size: 20,
                                ),
                                tooltip: isRequired
                                    ? 'Mark as optional'
                                    : 'Mark as required',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _fields[index]['required'] = !isRequired;
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                onPressed: () {
                                  setState(() => _fields.removeAt(index));
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No custom fields yet.\nAdd fields above to customize lead data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => widget.onSave(_fields),
                child: const Text('Save Custom Fields'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Project Statuses Manager Sheet
class _ProjectStatusesSheet extends StatefulWidget {
  final Project project;
  final Function(List<Map<String, dynamic>>) onSave;

  const _ProjectStatusesSheet({required this.project, required this.onSave});

  @override
  State<_ProjectStatusesSheet> createState() => _ProjectStatusesSheetState();
}

class _ProjectStatusesSheetState extends State<_ProjectStatusesSheet> {
  late List<Map<String, dynamic>> _statuses;
  final _statusNameController = TextEditingController();
  Color _selectedColor = Colors.blue;

  final List<Color> _availableColors = [
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.green,
    Colors.red,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    // Load existing statuses from project or use defaults
    if (widget.project.statuses.isEmpty) {
      _statuses = StatusUtils.getDefaultStatuses();
    } else {
      _statuses = List<Map<String, dynamic>>.from(
        widget.project.statuses.map((s) => Map<String, dynamic>.from(s)),
      );
    }
  }

  @override
  void dispose() {
    _statusNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Project Statuses',
                    style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Define custom statuses for leads in this project',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Add new status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _statusNameController,
                            decoration: const InputDecoration(
                              hintText: 'New status name',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.all(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<Color>(
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _selectedColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                          ),
                          itemBuilder: (context) => _availableColors
                              .map((color) => PopupMenuItem(
                                    value: color,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ))
                              .toList(),
                          onSelected: (color) {
                            setState(() => _selectedColor = color);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          onPressed: () {
                            if (_statusNameController.text.trim().isNotEmpty) {
                              setState(() {
                                _statuses.add({
                                  'id': _statusNameController.text
                                      .trim()
                                      .toLowerCase()
                                      .replaceAll(' ', '_'),
                                  'name': _statusNameController.text.trim(),
                                  'color':
                                      StatusUtils.colorToHex(_selectedColor),
                                  'order': _statuses.length + 1,
                                });
                                _statusNameController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Statuses list
            Expanded(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                itemCount: _statuses.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) newIndex--;
                    final item = _statuses.removeAt(oldIndex);
                    _statuses.insert(newIndex, item);
                    // Update order
                    for (int i = 0; i < _statuses.length; i++) {
                      _statuses[i]['order'] = i + 1;
                    }
                  });
                },
                itemBuilder: (context, index) {
                  final status = _statuses[index];
                  // Handle both Color objects and hex strings
                  final color = status['color'] is Color
                      ? status['color'] as Color
                      : status['color'] is String
                          ? StatusUtils.hexToColor(status['color'] as String)
                          : StatusUtils.getColor(status['id'] as String);

                  return Card(
                    key: ValueKey(status['id']),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      leading: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      title: Text(
                        status['name'] as String,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: SizedBox(
                        width: 80,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (index > 0 || _statuses.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                color: Colors.grey[400],
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                onPressed: () {
                                  setState(() => _statuses.removeAt(index));
                                },
                              ),
                            const Icon(Icons.drag_handle, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => widget.onSave(_statuses),
                child: const Text('Save Statuses'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
