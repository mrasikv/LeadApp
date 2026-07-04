import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/models/project_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/project_bloc.dart';
import '../bloc/project_event.dart';
import '../bloc/project_state.dart';

enum ProjectViewMode { grid, list, horizontal }

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

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
      child: const _ProjectsPageContent(),
    );
  }
}

class _ProjectsPageContent extends StatefulWidget {
  const _ProjectsPageContent();

  @override
  State<_ProjectsPageContent> createState() => _ProjectsPageContentState();
}

class _ProjectsPageContentState extends State<_ProjectsPageContent> {
  ProjectViewMode _viewMode = ProjectViewMode.grid;
  String _searchQuery = '';

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
            title: const Text('Projects'),
            actions: [
              // View mode toggle
              PopupMenuButton<ProjectViewMode>(
                icon: Icon(_getViewModeIcon()),
                tooltip: 'View Mode',
                onSelected: (mode) => setState(() => _viewMode = mode),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: ProjectViewMode.grid,
                    child: Row(
                      children: [
                        Icon(
                          Icons.grid_view,
                          color: _viewMode == ProjectViewMode.grid
                              ? AppColors.primary
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Text('Grid View'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: ProjectViewMode.list,
                    child: Row(
                      children: [
                        Icon(
                          Icons.view_list,
                          color: _viewMode == ProjectViewMode.list
                              ? AppColors.primary
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Text('List View'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: ProjectViewMode.horizontal,
                    child: Row(
                      children: [
                        Icon(
                          Icons.view_carousel,
                          color: _viewMode == ProjectViewMode.horizontal
                              ? AppColors.primary
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Text('Carousel View'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search projects...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),

              // Projects list
              Expanded(
                child: BlocBuilder<ProjectBloc, ProjectState>(
                  builder: (context, state) {
                    if (state is ProjectLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is ProjectsLoaded) {
                      final projects = state.projects.where((p) {
                        if (_searchQuery.isEmpty) return true;
                        return p.name
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase());
                      }).toList();

                      if (projects.isEmpty) {
                        return _EmptyProjectsWidget(
                          onCreatePressed: () =>
                              context.push('/projects/create'),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          if (authState.user.currentCompanyId != null) {
                            context.read<ProjectBloc>().add(
                                  LoadProjectsEvent(
                                      authState.user.currentCompanyId!),
                                );
                          }
                        },
                        child: _buildProjectsView(projects),
                      );
                    }

                    if (state is ProjectError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Error: ${state.error.message}'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                if (authState.user.currentCompanyId != null) {
                                  context.read<ProjectBloc>().add(
                                        LoadProjectsEvent(
                                            authState.user.currentCompanyId!),
                                      );
                                }
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    return const Center(child: Text('No projects found'));
                  },
                ),
              ),
            ],
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

  IconData _getViewModeIcon() {
    switch (_viewMode) {
      case ProjectViewMode.grid:
        return Icons.grid_view;
      case ProjectViewMode.list:
        return Icons.view_list;
      case ProjectViewMode.horizontal:
        return Icons.view_carousel;
    }
  }

  Widget _buildProjectsView(List<Project> projects) {
    switch (_viewMode) {
      case ProjectViewMode.grid:
        return _buildGridView(projects);
      case ProjectViewMode.list:
        return _buildListView(projects);
      case ProjectViewMode.horizontal:
        return _buildHorizontalView(projects);
    }
  }

  Widget _buildGridView(List<Project> projects) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        return _ProjectGridCard(
          project: projects[index],
          onTap: () => context.push('/projects/${projects[index].id}'),
        );
      },
    );
  }

  Widget _buildListView(List<Project> projects) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        return _ProjectListCard(
          project: projects[index],
          onTap: () => context.push('/projects/${projects[index].id}'),
        );
      },
    );
  }

  Widget _buildHorizontalView(List<Project> projects) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Projects
          _ProjectSection(
            title: 'Active Projects',
            projects: projects.where((p) => p.isActive).toList(),
          ),
          const SizedBox(height: 24),
          // Inactive Projects
          if (projects.any((p) => !p.isActive))
            _ProjectSection(
              title: 'Inactive Projects',
              projects: projects.where((p) => !p.isActive).toList(),
            ),
        ],
      ),
    );
  }
}

class _ProjectSection extends StatelessWidget {
  final String title;
  final List<Project> projects;

  const _ProjectSection({
    required this.title,
    required this.projects,
  });

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: projects.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 280,
                  child: _ProjectHorizontalCard(
                    project: projects[index],
                    onTap: () =>
                        context.push('/projects/${projects[index].id}'),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProjectGridCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const _ProjectGridCard({
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
            // Color header
            Container(
              height: 8,
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
                          radius: 18,
                          child: Icon(
                            _getIconData(project.icon ?? 'folder'),
                            color: color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            project.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
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
                        _StatChip(
                          label: 'Total',
                          value: project.leadCount.toString(),
                          color: Colors.grey,
                        ),
                        _StatChip(
                          label: 'Active',
                          value: project.activeLeadCount.toString(),
                          color: Colors.blue,
                        ),
                        _StatChip(
                          label: 'Won',
                          value: project.wonLeadCount.toString(),
                          color: Colors.green,
                        ),
                      ],
                    ),
                    if (!project.isActive)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Inactive',
                          style: TextStyle(fontSize: 10, color: Colors.red),
                        ),
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

class _ProjectListCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const _ProjectListCard({
    required this.project,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(project.color ?? '#2196F3');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                radius: 28,
                child: Icon(
                  _getIconData(project.icon ?? 'folder'),
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            project.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        if (!project.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Inactive',
                              style: TextStyle(fontSize: 10, color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.projectTypeName ?? 'General',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatBadge(
                          icon: Icons.people,
                          value: '${project.leadCount} leads',
                          color: color,
                        ),
                        const SizedBox(width: 16),
                        _StatBadge(
                          icon: Icons.check_circle,
                          value: '${project.wonLeadCount} won',
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
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

class _ProjectHorizontalCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const _ProjectHorizontalCard({
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
              height: 60,
              width: double.infinity,
              color: color.withOpacity(0.2),
              child: Center(
                child: Icon(
                  _getIconData(project.icon ?? 'folder'),
                  color: color,
                  size: 32,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.projectTypeName ?? 'General',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${project.leadCount} leads',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${project.wonLeadCount} won',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _EmptyProjectsWidget extends StatelessWidget {
  final VoidCallback onCreatePressed;

  const _EmptyProjectsWidget({required this.onCreatePressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No projects yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first project to start managing leads',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreatePressed,
              icon: const Icon(Icons.add),
              label: const Text('Create Project'),
            ),
          ],
        ),
      ),
    );
  }
}
