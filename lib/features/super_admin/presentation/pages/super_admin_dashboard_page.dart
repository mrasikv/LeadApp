import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/models/company_model.dart';
import '../../../../core/models/project_type_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../companies/presentation/bloc/company_bloc.dart';
import '../../../companies/presentation/bloc/company_event.dart';
import '../../../companies/presentation/bloc/company_state.dart';
import '../bloc/project_type_bloc.dart';
import '../bloc/project_type_event.dart';
import '../bloc/project_type_state.dart';

class SuperAdminDashboardPage extends StatelessWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              sl<ProjectTypeBloc>()..add(const LoadProjectTypesEvent()),
        ),
        BlocProvider(
          create: (_) => sl<CompanyBloc>()..add(const LoadCompaniesEvent()),
        ),
      ],
      child: const _SuperAdminDashboardView(),
    );
  }
}

class _SuperAdminDashboardView extends StatefulWidget {
  const _SuperAdminDashboardView();

  @override
  State<_SuperAdminDashboardView> createState() =>
      _SuperAdminDashboardViewState();
}

class _SuperAdminDashboardViewState extends State<_SuperAdminDashboardView>
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(AuthLogoutEvent());
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showCompanySwitchDialog() {
    // Reload companies before showing dialog
    context.read<CompanyBloc>().add(const LoadCompaniesEvent());

    showDialog(
      context: context,
      builder: (dialogContext) => BlocBuilder<CompanyBloc, CompanyState>(
        builder: (blocContext, state) {
          if (state is CompanyLoading || state is CompanyInitial) {
            return const AlertDialog(
              content: SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (state is CompaniesLoaded) {
            return AlertDialog(
              title: const Text('Switch to Company View'),
              content: SizedBox(
                width: double.maxFinite,
                child: state.companies.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child:
                            Text('No companies found. Create a company first.'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: state.companies.length,
                        itemBuilder: (listContext, index) {
                          final company = state.companies[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Text(company.name[0].toUpperCase()),
                            ),
                            title: Text(company.name),
                            subtitle: Text(company.companyCode ?? 'No code'),
                            trailing: company.isActive
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green)
                                : const Icon(Icons.cancel, color: Colors.red),
                            onTap: () {
                              Navigator.pop(dialogContext);
                              _switchToCompany(company);
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
              ],
            );
          }

          if (state is CompanyError) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to load companies: ${state.error.message}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: () {
                    context.read<CompanyBloc>().add(const LoadCompaniesEvent());
                  },
                  child: const Text('Retry'),
                ),
              ],
            );
          }

          // For any other states (CompanyCreated, CompanyUpdated, etc.), reload
          context.read<CompanyBloc>().add(const LoadCompaniesEvent());
          return const AlertDialog(
            content: SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        },
      ),
    );
  }

  void _switchToCompany(Company company) {
    // Store selected company context and navigate to dashboard
    context.read<AuthBloc>().add(AuthSwitchCompanyEvent(company.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switching to ${company.name}...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated && state.currentCompany != null) {
          // Super admin has switched to a company, navigate to dashboard
          context.go('/dashboard');
        } else if (state is AuthUnauthenticated) {
          context.go('/login');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Super Admin Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Switch to Company View',
              onPressed: _showCompanySwitchDialog,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'logout') {
                  _showLogoutDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Profile'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Settings'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text('Logout', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.category), text: 'Project Types'),
              Tab(icon: Icon(Icons.business), text: 'Companies'),
              Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _ProjectTypesTab(),
            _CompaniesTab(),
            _AnalyticsTab(),
          ],
        ),
      ),
    );
  }
}

// Project Types Management Tab
class _ProjectTypesTab extends StatelessWidget {
  const _ProjectTypesTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ProjectTypeBloc, ProjectTypeState>(
        builder: (context, state) {
          if (state is ProjectTypeLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProjectTypeError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.error.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<ProjectTypeBloc>()
                          .add(const LoadProjectTypesEvent());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ProjectTypesLoaded) {
            if (state.projectTypes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No project types yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text('Create your first project type to get started'),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _showCreateProjectTypeDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Project Type'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.projectTypes.length,
              itemBuilder: (context, index) {
                final type = state.projectTypes[index];
                return _ProjectTypeCard(projectType: type);
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProjectTypeDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Type'),
      ),
    );
  }

  void _showCreateProjectTypeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<ProjectTypeBloc>(),
        child: const _ProjectTypeFormDialog(),
      ),
    );
  }
}

class _ProjectTypeCard extends StatelessWidget {
  final ProjectType projectType;

  const _ProjectTypeCard({required this.projectType});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final typeColor = _parseColor(projectType.color ?? '#2196F3');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: typeColor.withOpacity(0.2),
          child: Icon(
            _getIconData(projectType.icon ?? 'category'),
            color: typeColor,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(projectType.name)),
            if (!projectType.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Inactive',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${projectType.defaultStatuses.length} default statuses',
          style: TextStyle(color: colorScheme.outline),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (projectType.description?.isNotEmpty == true) ...[
                  Text(
                    projectType.description!,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Default Statuses:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: projectType.defaultStatuses.map((status) {
                    final statusColor = _parseColor(status.color);
                    return Chip(
                      label: Text(status.name),
                      backgroundColor: statusColor.withOpacity(0.2),
                      side: BorderSide(color: statusColor),
                      avatar: status.isDefault
                          ? Icon(Icons.star, size: 16, color: statusColor)
                          : null,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showEditDialog(context),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _toggleActive(context),
                      icon: Icon(projectType.isActive
                          ? Icons.visibility_off
                          : Icons.visibility),
                      label: Text(
                          projectType.isActive ? 'Deactivate' : 'Activate'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<ProjectTypeBloc>(),
        child: _ProjectTypeFormDialog(projectType: projectType),
      ),
    );
  }

  void _toggleActive(BuildContext context) {
    context.read<ProjectTypeBloc>().add(
          ToggleProjectTypeActiveEvent(
            projectTypeId: projectType.id,
            isActive: !projectType.isActive,
          ),
        );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Project Type'),
        content: Text(
          'Are you sure you want to delete "${projectType.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<ProjectTypeBloc>().add(
                    DeleteProjectTypeEvent(projectType.id),
                  );
              Navigator.pop(dialogContext);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
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

class _ProjectTypeFormDialog extends StatefulWidget {
  final ProjectType? projectType;

  const _ProjectTypeFormDialog({this.projectType});

  @override
  State<_ProjectTypeFormDialog> createState() => _ProjectTypeFormDialogState();
}

class _ProjectTypeFormDialogState extends State<_ProjectTypeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String _selectedIcon = 'folder';
  String _selectedColor = '#2196F3';
  List<StatusTemplate> _statuses = [];

  final _iconOptions = [
    ('folder', Icons.folder),
    ('real_estate', Icons.home_work),
    ('car', Icons.directions_car),
    ('insurance', Icons.security),
    ('education', Icons.school),
    ('healthcare', Icons.local_hospital),
    ('finance', Icons.account_balance),
    ('retail', Icons.storefront),
    ('technology', Icons.computer),
  ];

  final _colorOptions = [
    '#2196F3', // Blue
    '#4CAF50', // Green
    '#FF9800', // Orange
    '#9C27B0', // Purple
    '#F44336', // Red
    '#00BCD4', // Cyan
    '#E91E63', // Pink
    '#795548', // Brown
  ];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.projectType?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.projectType?.description ?? '');
    _selectedIcon = widget.projectType?.icon ?? 'folder';
    _selectedColor = widget.projectType?.color ?? '#2196F3';
    _statuses =
        widget.projectType?.defaultStatuses.toList() ?? _getDefaultStatuses();
  }

  List<StatusTemplate> _getDefaultStatuses() {
    return const [
      StatusTemplate(
        name: 'New',
        category: 'to_do',
        color: '#2196F3',
        order: 1,
        isDefault: true,
        mandatoryFields: [],
      ),
      StatusTemplate(
        name: 'In Progress',
        category: 'in_progress',
        color: '#FF9800',
        order: 2,
        isDefault: false,
        mandatoryFields: [],
      ),
      StatusTemplate(
        name: 'Qualified',
        category: 'in_progress',
        color: '#4CAF50',
        order: 3,
        isDefault: false,
        mandatoryFields: [],
      ),
      StatusTemplate(
        name: 'Won',
        category: 'done',
        color: '#00C853',
        order: 4,
        isDefault: false,
        mandatoryFields: [],
      ),
      StatusTemplate(
        name: 'Lost',
        category: 'done',
        color: '#F44336',
        order: 5,
        isDefault: false,
        mandatoryFields: [],
      ),
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.projectType != null;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      isEditing ? Icons.edit : Icons.add_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEditing ? 'Edit Project Type' : 'Create Project Type',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name *',
                            hintText: 'e.g., Real Estate, Insurance',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Brief description of this project type',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Icon',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _iconOptions.map((option) {
                            final isSelected = _selectedIcon == option.$1;
                            return ChoiceChip(
                              label: Icon(option.$2),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedIcon = option.$1);
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Color',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _colorOptions.map((color) {
                            final isSelected = _selectedColor == color;
                            final parsedColor = Color(
                                int.parse(color.replaceFirst('#', '0xFF')));
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedColor = color),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: parsedColor,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: Colors.white, width: 3)
                                      : null,
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: parsedColor.withOpacity(0.5),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check,
                                        color: Colors.white, size: 20)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Default Statuses (${_statuses.length})',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            TextButton.icon(
                              onPressed: _addStatus,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Status'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _statuses.length,
                          itemBuilder: (context, index) {
                            final status = _statuses[index];
                            final statusColor = Color(
                              int.parse(status.color.replaceFirst('#', '0xFF')),
                            );
                            return ListTile(
                              key: ValueKey(index),
                              leading: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              title: Text(status.name),
                              subtitle: Text(status.category
                                  .replaceAll('_', ' ')
                                  .toUpperCase()),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (status.isDefault)
                                    const Chip(
                                      label: Text('Default',
                                          style: TextStyle(fontSize: 10)),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: () => _editStatus(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18),
                                    onPressed: () => _removeStatus(index),
                                  ),
                                  const Icon(Icons.drag_handle),
                                ],
                              ),
                            );
                          },
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) newIndex--;
                              final item = _statuses.removeAt(oldIndex);
                              _statuses.insert(newIndex, item);
                              // Update order values
                              for (int i = 0; i < _statuses.length; i++) {
                                _statuses[i] =
                                    _statuses[i].copyWith(order: i + 1);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _submit,
                      child: Text(isEditing ? 'Update' : 'Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addStatus() {
    _showStatusDialog();
  }

  void _editStatus(int index) {
    _showStatusDialog(index: index, status: _statuses[index]);
  }

  void _removeStatus(int index) {
    setState(() {
      _statuses.removeAt(index);
    });
  }

  void _showStatusDialog({int? index, StatusTemplate? status}) {
    final nameController = TextEditingController(text: status?.name ?? '');
    String category = status?.category ?? 'to_do';
    String color = status?.color ?? '#2196F3';
    bool isDefault = status?.isDefault ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(status == null ? 'Add Status' : 'Edit Status'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Status Name'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'to_do', child: Text('To Do')),
                    DropdownMenuItem(
                        value: 'in_progress', child: Text('In Progress')),
                    DropdownMenuItem(value: 'done', child: Text('Done')),
                  ],
                  onChanged: (v) => setDialogState(() => category = v!),
                ),
                const SizedBox(height: 16),
                const Text('Color'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _colorOptions.map((c) {
                    final parsedColor =
                        Color(int.parse(c.replaceFirst('#', '0xFF')));
                    return GestureDetector(
                      onTap: () => setDialogState(() => color = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: parsedColor,
                          shape: BoxShape.circle,
                          border: color == c
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                        ),
                        child: color == c
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 16)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Default Status'),
                  subtitle: const Text('New leads will start with this status'),
                  value: isDefault,
                  onChanged: (v) => setDialogState(() => isDefault = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.isEmpty) return;

                final newStatus = StatusTemplate(
                  name: nameController.text,
                  category: category,
                  color: color,
                  order: index != null
                      ? _statuses[index].order
                      : _statuses.length + 1,
                  isDefault: isDefault,
                  mandatoryFields: status?.mandatoryFields ?? [],
                );

                setState(() {
                  if (index != null) {
                    _statuses[index] = newStatus;
                  } else {
                    _statuses.add(newStatus);
                  }

                  // Ensure only one default
                  if (isDefault) {
                    for (int i = 0; i < _statuses.length; i++) {
                      if (i != (index ?? _statuses.length - 1) &&
                          _statuses[i].isDefault) {
                        _statuses[i] = _statuses[i].copyWith(isDefault: false);
                      }
                    }
                  }
                });

                Navigator.pop(ctx);
              },
              child: Text(index != null ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_statuses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one status')),
      );
      return;
    }

    final now = DateTime.now();
    final projectType = ProjectType(
      id: widget.projectType?.id ?? '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      icon: _selectedIcon,
      color: _selectedColor,
      isActive: widget.projectType?.isActive ?? true,
      defaultStatuses: _statuses,
      createdAt: widget.projectType?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.projectType != null) {
      context.read<ProjectTypeBloc>().add(UpdateProjectTypeEvent(projectType));
    } else {
      context.read<ProjectTypeBloc>().add(CreateProjectTypeEvent(projectType));
    }

    Navigator.pop(context);
  }
}

// Companies Tab - Full company management
class _CompaniesTab extends StatelessWidget {
  const _CompaniesTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompanyBloc, CompanyState>(
      builder: (context, state) {
        if (state is CompanyLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CompanyError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error: ${state.error.message}'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    context.read<CompanyBloc>().add(const LoadCompaniesEvent());
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is CompaniesLoaded) {
          if (state.companies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No companies yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text('Create your first company to get started'),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.go('/company-signup'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Company'),
                  ),
                ],
              ),
            );
          }

          return Scaffold(
            body: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.companies.length,
              itemBuilder: (context, index) {
                final company = state.companies[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: company.isActive
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.grey[300],
                      child: Text(
                        company.name.isNotEmpty
                            ? company.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: company.isActive
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                        ),
                      ),
                    ),
                    title: Text(company.name),
                    subtitle: Text(
                      'Code: ${company.companyCode ?? 'N/A'} • ${company.isActive ? 'Active' : 'Inactive'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!company.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Inactive',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                          onPressed: () {
                            context.go('/super-admin/companies/${company.id}');
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      context.go('/super-admin/companies/${company.id}');
                    },
                  ),
                );
              },
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => context.go('/company-signup'),
              icon: const Icon(Icons.add),
              label: const Text('Add Company'),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// Analytics Tab
class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompanyBloc, CompanyState>(
      builder: (context, state) {
        int totalCompanies = 0;
        int activeCompanies = 0;

        if (state is CompaniesLoaded) {
          totalCompanies = state.companies.length;
          activeCompanies = state.companies.where((c) => c.isActive).length;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Overview',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Companies',
                      value: totalCompanies.toString(),
                      icon: Icons.business,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Active Companies',
                      value: activeCompanies.toString(),
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              BlocBuilder<ProjectTypeBloc, ProjectTypeState>(
                builder: (context, ptState) {
                  int totalTypes = 0;
                  int activeTypes = 0;

                  if (ptState is ProjectTypesLoaded) {
                    totalTypes = ptState.projectTypes.length;
                    activeTypes =
                        ptState.projectTypes.where((t) => t.isActive).length;
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Project Types',
                          value: totalTypes.toString(),
                          icon: Icons.category,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Active Types',
                          value: activeTypes.toString(),
                          icon: Icons.toggle_on,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.add_business, size: 18),
                    label: const Text('Create Company'),
                    onPressed: () => context.go('/company-signup'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.category, size: 18),
                    label: const Text('Manage Project Types'),
                    onPressed: () {
                      // Switch to Project Types tab
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.backup, size: 18),
                    label: const Text('Backup Data'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Backup feature coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
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
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
