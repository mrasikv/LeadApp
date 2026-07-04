import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/models/company_model.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/auth/presentation/bloc/auth_event.dart';

class CompanySwitcherWidget extends StatelessWidget {
  final bool showAsDropdown;

  const CompanySwitcherWidget({
    super.key,
    this.showAsDropdown = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const SizedBox.shrink();
        }

        if (state.userCompanies.length <= 1) {
          // Show current company name only
          return _buildCurrentCompanyDisplay(
            context,
            state.currentCompany,
          );
        }

        if (showAsDropdown) {
          return _buildDropdown(context, state);
        } else {
          return _buildSwitcherButton(context, state);
        }
      },
    );
  }

  Widget _buildCurrentCompanyDisplay(
    BuildContext context,
    Company? company,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.business,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            company?.name ?? 'No Company',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, AuthAuthenticated state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.currentCompany?.id,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: state.userCompanies.map((company) {
            final isCurrentCompany = company.id == state.currentCompany?.id;
            return DropdownMenuItem<String>(
              value: company.id,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.business,
                    size: 20,
                    color: isCurrentCompany
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    company.name,
                    style: TextStyle(
                      fontWeight: isCurrentCompany
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (companyId) {
            if (companyId != null && companyId != state.currentCompany?.id) {
              context.read<AuthBloc>().add(
                    AuthSwitchCompanyEvent(companyId),
                  );
            }
          },
        ),
      ),
    );
  }

  Widget _buildSwitcherButton(BuildContext context, AuthAuthenticated state) {
    return InkWell(
      onTap: () => _showCompanySwitcherDialog(context, state),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.business,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              state.currentCompany?.name ?? 'Select Company',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.swap_horiz, size: 18),
          ],
        ),
      ),
    );
  }

  void _showCompanySwitcherDialog(
    BuildContext context,
    AuthAuthenticated state,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => CompanySwitcherSheet(
        companies: state.userCompanies,
        currentCompanyId: state.currentCompany?.id,
        onCompanySelected: (companyId) {
          Navigator.pop(ctx);
          context.read<AuthBloc>().add(
                AuthSwitchCompanyEvent(companyId),
              );
        },
      ),
    );
  }
}

class CompanySwitcherSheet extends StatelessWidget {
  final List<Company> companies;
  final String? currentCompanyId;
  final Function(String) onCompanySelected;

  const CompanySwitcherSheet({
    super.key,
    required this.companies,
    this.currentCompanyId,
    required this.onCompanySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(
                  Icons.swap_horiz,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Switch Company',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          ListView.builder(
            shrinkWrap: true,
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final company = companies[index];
              final isSelected = company.id == currentCompanyId;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.business,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                title: Text(
                  company.name,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  company.companyType,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () => onCompanySelected(company.id),
              );
            },
          ),
          const Divider(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '${companies.length} companies',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
