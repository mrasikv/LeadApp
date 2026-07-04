import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/company_model.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_event.dart';
import '../../companies/presentation/bloc/company_bloc.dart';
import '../../companies/presentation/bloc/company_event.dart';
import '../../companies/presentation/bloc/company_state.dart';

class SuperAdminDashboardPage extends StatefulWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  State<SuperAdminDashboardPage> createState() =>
      _SuperAdminDashboardPageState();
}

class _SuperAdminDashboardPageState extends State<SuperAdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<CompanyBloc>().add(LoadCompaniesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CompanyBloc>().add(LoadCompaniesEvent());
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutEvent());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Overview
          BlocBuilder<CompanyBloc, CompanyState>(
            builder: (context, state) {
              if (state is! CompaniesLoaded) return const SizedBox.shrink();

              final activeCompanies =
                  state.companies.where((c) => c.isActive).toList();
              final inactiveCompanies =
                  state.companies.where((c) => !c.isActive).toList();

              return Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildStatCard(
                      context,
                      label: 'Total Companies',
                      value: state.companies.length.toString(),
                      icon: Icons.business,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      context,
                      label: 'Active',
                      value: activeCompanies.length.toString(),
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      context,
                      label: 'Inactive',
                      value: inactiveCompanies.length.toString(),
                      icon: Icons.cancel,
                      color: Colors.orange,
                    ),
                  ],
                ),
              );
            },
          ),

          // Company List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Companies',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showCreateCompanyDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Company'),
                ),
              ],
            ),
          ),

          // Companies List
          Expanded(
            child: BlocBuilder<CompanyBloc, CompanyState>(
              builder: (context, state) {
                if (state is CompanyLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is CompanyError) {
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
                        Text(state.error.message),
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          const Text('No companies yet'),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => _showCreateCompanyDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Company'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.companies.length,
                    itemBuilder: (context, index) {
                      final company = state.companies[index];
                      return CompanyCard(
                        company: company,
                        onTap: () => _openCompanyDetails(company),
                        onToggleStatus: () => _toggleCompanyStatus(company),
                        onEdit: () => _showEditCompanyDialog(company),
                        onDelete: () => _showDeleteConfirmation(company),
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
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
                    color: color,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCompanyDialog() {
    final nameController = TextEditingController();
    final companyTypeController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Company'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Company Name *',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: companyTypeController,
                decoration: const InputDecoration(
                  labelText: 'Company Type',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                ),
                keyboardType: TextInputType.phone,
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

              final now = DateTime.now();
              final company = Company(
                id: '', // Will be set by Firestore
                name: nameController.text.trim(),
                companyType: companyTypeController.text.trim().isNotEmpty
                    ? companyTypeController.text.trim()
                    : 'business',
                email: emailController.text.trim().isNotEmpty
                    ? emailController.text.trim()
                    : null,
                phone: phoneController.text.trim().isNotEmpty
                    ? phoneController.text.trim()
                    : null,
                isActive: true,
                enabledFeatures: {
                  'leads': true,
                  'call_logs': true,
                  'targets': true,
                  'tickets': true,
                  'dynamic_forms': true,
                },
                createdAt: now,
                updatedAt: now,
              );

              context.read<CompanyBloc>().add(CreateCompanyEvent(company));
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _openCompanyDetails(Company company) {
    context.push('/super-admin/companies/${company.id}');
  }

  void _toggleCompanyStatus(Company company) {
    final updated = company.copyWith(
      isActive: !company.isActive,
      updatedAt: DateTime.now(),
    );
    context.read<CompanyBloc>().add(UpdateCompanyEvent(updated));
  }

  void _showEditCompanyDialog(Company company) {
    final nameController = TextEditingController(text: company.name);
    final companyTypeController =
        TextEditingController(text: company.companyType);
    final emailController = TextEditingController(text: company.email);
    final phoneController = TextEditingController(text: company.phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Company'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Company Name *',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: companyTypeController,
                decoration: const InputDecoration(
                  labelText: 'Company Type',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                ),
                keyboardType: TextInputType.phone,
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

              final updated = company.copyWith(
                name: nameController.text.trim(),
                companyType: companyTypeController.text.trim().isNotEmpty
                    ? companyTypeController.text.trim()
                    : 'business',
                email: emailController.text.trim().isNotEmpty
                    ? emailController.text.trim()
                    : null,
                phone: phoneController.text.trim().isNotEmpty
                    ? phoneController.text.trim()
                    : null,
                updatedAt: DateTime.now(),
              );

              context.read<CompanyBloc>().add(UpdateCompanyEvent(updated));
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Company company) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Company'),
        content: Text(
          'Are you sure you want to delete "${company.name}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<CompanyBloc>().add(DeleteCompanyEvent(company.id));
              Navigator.pop(ctx);
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
}

class CompanyCard extends StatelessWidget {
  final Company company;
  final VoidCallback onTap;
  final VoidCallback onToggleStatus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CompanyCard({
    super.key,
    required this.company,
    required this.onTap,
    required this.onToggleStatus,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                  CircleAvatar(
                    backgroundColor: company.isActive
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.business,
                      color: company.isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          company.companyType,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: company.isActive
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      company.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: company.isActive ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (company.companyCode != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tag,
                            size: 14,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            company.companyCode!,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      company.isActive
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      size: 20,
                    ),
                    onPressed: onToggleStatus,
                    tooltip: company.isActive ? 'Deactivate' : 'Activate',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: onDelete,
                    tooltip: 'Delete',
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
