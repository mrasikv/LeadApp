import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/company_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../user_management/data/repositories/user_repository.dart';
import '../bloc/company_bloc.dart';
import '../bloc/company_state.dart';

class CompanySwitcher extends StatelessWidget {
  final User currentUser;
  final Function(Company) onCompanyChanged;

  const CompanySwitcher({
    super.key,
    required this.currentUser,
    required this.onCompanyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompanyBloc, CompanyState>(
      builder: (context, state) {
        if (state is CompaniesLoaded) {
          final userCompanies = state.companies
              .where((c) => currentUser.companyIds.contains(c.id))
              .toList();

          if (userCompanies.isEmpty) {
            return const SizedBox.shrink();
          }

          final currentCompany = userCompanies.firstWhere(
            (c) => c.id == currentUser.currentCompanyId,
            orElse: () => userCompanies.first,
          );

          return PopupMenuButton<Company>(
            initialValue: currentCompany,
            tooltip: 'Switch Company',
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.business, size: 20),
                const SizedBox(width: 8),
                Text(
                  currentCompany.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
            onSelected: (Company company) async {
              if (company.id != currentUser.currentCompanyId) {
                await _switchCompany(context, company);
              }
            },
            itemBuilder: (BuildContext context) {
              return userCompanies.map((Company company) {
                final isSelected = company.id == currentUser.currentCompanyId;

                return PopupMenuItem<Company>(
                  value: company,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor:
                          isSelected ? AppColors.primary : AppColors.surface,
                      child: Text(
                        company.name[0].toUpperCase(),
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      company.name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(company.companyCode ?? ''),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                );
              }).toList();
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Future<void> _switchCompany(BuildContext context, Company company) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // TODO: Get role and department for this company
      // For now, using placeholder values
      final roleId = 'default_role_id';
      final departmentId = 'default_department_id';

      // Switch company in repository
      final userRepository = context.read<UserRepository>();
      final result = await userRepository.switchCompany(
        currentUser.id,
        company.id,
        roleId,
        departmentId,
      );

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      result.fold(
        (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to switch company: ${error.message}'),
              backgroundColor: AppColors.error,
            ),
          );
        },
        (_) {
          onCompanyChanged(company);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Switched to ${company.name}'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;

      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
