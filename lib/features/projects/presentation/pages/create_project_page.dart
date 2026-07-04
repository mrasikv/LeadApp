import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/models/project_type_model.dart';
import '../../../../core/utils/status_utils.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../super_admin/presentation/bloc/project_type_bloc.dart';
import '../../../super_admin/presentation/bloc/project_type_event.dart';
import '../../../super_admin/presentation/bloc/project_type_state.dart';
import '../bloc/project_bloc.dart';
import '../bloc/project_event.dart';
import '../bloc/project_state.dart';

class CreateProjectPage extends StatelessWidget {
  const CreateProjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              sl<ProjectTypeBloc>()..add(const LoadProjectTypesEvent()),
        ),
        BlocProvider(
          create: (_) => sl<ProjectBloc>(),
        ),
      ],
      child: const _CreateProjectView(),
    );
  }
}

class _CreateProjectView extends StatefulWidget {
  const _CreateProjectView();

  @override
  State<_CreateProjectView> createState() => _CreateProjectViewState();
}

class _CreateProjectViewState extends State<_CreateProjectView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  ProjectType? _selectedProjectType;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Project'),
      ),
      body: BlocListener<ProjectBloc, ProjectState>(
        listener: (context, state) {
          if (state is ProjectCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Project "${state.project.name}" created!')),
            );
            context.pop();
          } else if (state is ProjectError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.error.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Project Type Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Project Type',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Project type determines the default statuses for your leads',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      BlocBuilder<ProjectTypeBloc, ProjectTypeState>(
                        builder: (context, state) {
                          if (state is ProjectTypeLoading) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (state is ProjectTypesLoaded) {
                            final activeTypes = state.projectTypes
                                .where((t) => t.isActive)
                                .toList();

                            if (activeTypes.isEmpty) {
                              return const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'No project types available. Please contact super admin.',
                                  ),
                                ),
                              );
                            }

                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: activeTypes.map((type) {
                                final isSelected =
                                    _selectedProjectType?.id == type.id;
                                final color =
                                    _parseColor(type.color ?? '#2196F3');

                                return ChoiceChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getIconData(type.icon ?? 'category'),
                                        size: 18,
                                        color:
                                            isSelected ? Colors.white : color,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(type.name),
                                    ],
                                  ),
                                  selected: isSelected,
                                  selectedColor: color,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedProjectType =
                                          selected ? type : null;
                                    });
                                  },
                                );
                              }).toList(),
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Project Details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Project Details',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Project Name *',
                          hintText: 'e.g., Mumbai Residential Q4',
                          prefixIcon: Icon(Icons.folder),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a project name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Brief description of the project',
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Selected type preview
              if (_selectedProjectType != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Default Statuses',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'These statuses will be created for your project:',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedProjectType!.defaultStatuses
                              .map((status) {
                            final color = _parseColor(status.color);
                            return Chip(
                              label: Text(
                                status.name,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: color.withOpacity(0.2),
                              side: BorderSide(color: color),
                              avatar: status.isDefault
                                  ? Icon(Icons.star, size: 14, color: color)
                                  : null,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Create Button
              BlocBuilder<ProjectBloc, ProjectState>(
                builder: (context, state) {
                  final isLoading = state is ProjectLoading;

                  return FilledButton.icon(
                    onPressed: isLoading ? null : _createProject,
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: Text(isLoading ? 'Creating...' : 'Create Project'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createProject() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProjectType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project type')),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated ||
        authState.user.currentCompanyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No company selected')),
      );
      return;
    }

    final now = DateTime.now();
    // Initialize with default statuses
    final defaultStatuses = StatusUtils.getDefaultStatuses();
    final project = Project(
      id: '', // Will be set by Firestore
      companyId: authState.user.currentCompanyId!,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      projectTypeId: _selectedProjectType!.id,
      projectTypeName: _selectedProjectType!.name,
      icon: _selectedProjectType!.icon,
      color: _selectedProjectType!.color,
      isActive: true,
      leadCount: 0,
      activeLeadCount: 0,
      wonLeadCount: 0,
      customFields: [],
      statuses: defaultStatuses,
      createdAt: now,
      updatedAt: now,
    );

    context.read<ProjectBloc>().add(CreateProjectEvent(
          project: project,
          projectType: _selectedProjectType!,
        ));
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
