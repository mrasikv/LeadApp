import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../companies/presentation/widgets/company_switcher.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = state.user;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile & Settings'),
            actions: [
              CompanySwitcher(
                currentUser: user,
                onCompanyChanged: (company) {
                  // Handle company change - typically would trigger an event
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      if (user.currentRoleId != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.currentRoleId!,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Menu Options
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        context,
                        icon: Icons.person,
                        title: 'Edit Profile',
                        onTap: () => _showEditProfileDialog(context, user),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.lock,
                        title: 'Change Password',
                        onTap: () => _showChangePasswordDialog(context),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.notifications,
                        title: 'Notifications',
                        onTap: () => _showNotificationsSettings(context),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Company',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        context,
                        icon: Icons.business,
                        title: 'My Companies',
                        subtitle: '${user.companyIds.length} companies',
                        onTap: () => _showCompaniesDialog(context, user),
                      ),
                      if (state.isCompanyAdmin) ...[
                        _buildMenuItem(
                          context,
                          icon: Icons.admin_panel_settings,
                          title: 'Company Admin',
                          onTap: () => context.push('/company-admin'),
                        ),
                      ],
                      if (state.isSuperAdmin) ...[
                        _buildMenuItem(
                          context,
                          icon: Icons.supervisor_account,
                          title: 'Super Admin Panel',
                          onTap: () => context.go('/super-admin'),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        'App',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        context,
                        icon: Icons.dark_mode,
                        title: 'Dark Mode',
                        trailing: Switch(
                          value: false,
                          onChanged: (value) {},
                        ),
                        onTap: () {},
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.help,
                        title: 'Help & Support',
                        onTap: () {},
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.info,
                        title: 'About',
                        onTap: () => _showAboutDialog(context),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmLogout(context),
                          icon:
                              const Icon(Icons.logout, color: AppColors.error),
                          label: const Text(
                            'Logout',
                            style: TextStyle(color: AppColors.error),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, dynamic user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Name'),
              controller: TextEditingController(text: user.name),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Phone'),
              controller: TextEditingController(text: user.phone ?? ''),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            TextField(
              decoration: InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Confirm New Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password changed')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showNotificationsSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Notification Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Push Notifications'),
              value: true,
              onChanged: (v) {},
            ),
            SwitchListTile(
              title: const Text('Email Notifications'),
              value: true,
              onChanged: (v) {},
            ),
            SwitchListTile(
              title: const Text('Follow-up Reminders'),
              value: true,
              onChanged: (v) {},
            ),
            SwitchListTile(
              title: const Text('Target Alerts'),
              value: false,
              onChanged: (v) {},
            ),
          ],
        ),
      ),
    );
  }

  void _showCompaniesDialog(BuildContext context, dynamic user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('My Companies'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: user.companyIds.length,
            itemBuilder: (context, index) {
              final companyId = user.companyIds[index];
              final isCurrent = companyId == user.currentCompanyId;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isCurrent
                      ? AppColors.primary
                      : AppColors.primaryContainer,
                  child: Icon(
                    Icons.business,
                    color: isCurrent ? Colors.white : AppColors.primary,
                  ),
                ),
                title: Text('Company $companyId'),
                trailing: isCurrent
                    ? const Chip(label: Text('Current'))
                    : TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          // Switch company
                        },
                        child: const Text('Switch'),
                      ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Lead Management App',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.business_center, size: 48),
      children: const [
        Text(
            'A multi-tenant lead management solution built with Flutter and Firebase.'),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
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
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
