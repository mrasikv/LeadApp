import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/company_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/company_bloc.dart';
import '../bloc/company_event.dart';
import '../bloc/company_state.dart';

class SuperAdminCompanyManagementPage extends StatefulWidget {
  const SuperAdminCompanyManagementPage({super.key});

  @override
  State<SuperAdminCompanyManagementPage> createState() =>
      _SuperAdminCompanyManagementPageState();
}

class _SuperAdminCompanyManagementPageState
    extends State<SuperAdminCompanyManagementPage> {
  @override
  void initState() {
    super.initState();
    context.read<CompanyBloc>().add(LoadCompaniesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated || !authState.isSuperAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Access Denied')),
            body: const Center(
              child: Text('You do not have permission to access this page'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Company Management'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showCreateCompanyDialog(context),
                tooltip: 'Create Company',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  context.read<CompanyBloc>().add(LoadCompaniesEvent());
                },
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: BlocBuilder<CompanyBloc, CompanyState>(
            builder: (context, state) {
              if (state is CompanyLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is CompanyError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        state.error.message,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<CompanyBloc>().add(LoadCompaniesEvent());
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state is CompaniesLoaded) {
                if (state.companies.isEmpty) {
                  return const Center(
                    child: Text('No companies found'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.companies.length,
                  itemBuilder: (context, index) {
                    final company = state.companies[index];
                    return _CompanyCard(
                      company: company,
                      onEdit: () => _showEditCompanyDialog(context, company),
                      onDelete: () => _confirmDeleteCompany(context, company),
                      onToggleActive: () =>
                          _toggleCompanyActive(context, company),
                    );
                  },
                );
              }

              return const Center(child: Text('No data'));
            },
          ),
        );
      },
    );
  }

  void _showCreateCompanyDialog(BuildContext context) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    String companyType = 'other';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Company'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Company Name',
                    hintText: 'Enter company name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Company Code',
                    hintText: 'Enter company code (6 chars)',
                  ),
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: companyType,
                  decoration: const InputDecoration(
                    labelText: 'Company Type',
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'real_estate', child: Text('Real Estate')),
                    DropdownMenuItem(
                        value: 'insurance', child: Text('Insurance')),
                    DropdownMenuItem(value: 'finance', child: Text('Finance')),
                    DropdownMenuItem(
                        value: 'education', child: Text('Education')),
                    DropdownMenuItem(
                        value: 'healthcare', child: Text('Healthcare')),
                    DropdownMenuItem(
                        value: 'technology', child: Text('Technology')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => companyType = value);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  codeController.text.isNotEmpty) {
                final company = Company(
                  id: '', // Will be generated by Firestore
                  name: nameController.text,
                  companyType: companyType,
                  companyCode: codeController.text.toUpperCase(),
                  isActive: true,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                context.read<CompanyBloc>().add(CreateCompanyEvent(company));
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditCompanyDialog(BuildContext context, Company company) {
    final nameController = TextEditingController(text: company.name);
    final codeController = TextEditingController(text: company.companyCode);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Company'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Company Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Company Code'),
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedCompany = company.copyWith(
                name: nameController.text,
                companyCode: codeController.text.toUpperCase(),
              );

              context
                  .read<CompanyBloc>()
                  .add(UpdateCompanyEvent(updatedCompany));
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCompany(BuildContext context, Company company) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Company'),
        content: Text('Are you sure you want to delete ${company.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CompanyBloc>().add(DeleteCompanyEvent(company.id));
              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleCompanyActive(BuildContext context, Company company) {
    final updatedCompany = company.copyWith(isActive: !company.isActive);
    context.read<CompanyBloc>().add(UpdateCompanyEvent(updatedCompany));
  }
}

class _CompanyCard extends StatelessWidget {
  final Company company;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _CompanyCard({
    required this.company,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: company.isActive ? AppColors.primary : Colors.grey,
          child: Text(
            company.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          company.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Code: ${company.companyCode ?? 'N/A'}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                company.isActive ? Icons.toggle_on : Icons.toggle_off,
                color: company.isActive ? AppColors.success : Colors.grey,
              ),
              onPressed: onToggleActive,
              tooltip: company.isActive ? 'Deactivate' : 'Activate',
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: onDelete,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}
