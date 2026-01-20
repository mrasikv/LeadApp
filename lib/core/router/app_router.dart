import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/company_login_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/leads/presentation/pages/leads_page.dart';
import '../../features/leads/presentation/pages/lead_detail_page.dart';
import '../../features/leads/presentation/pages/create_lead_page.dart';
import '../../features/super_admin/presentation/pages/super_admin_dashboard_page.dart';
import '../../features/company_admin/presentation/pages/company_admin_dashboard_page.dart';
import '../../features/company_admin/presentation/pages/status_builder_page.dart';
import '../../features/company_admin/presentation/pages/form_builder_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/company-login',
        name: 'company-login',
        builder: (context, state) => const CompanyLoginPage(),
      ),

      // Main App Routes (after authentication)
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
      ),

      // Leads Routes
      GoRoute(
        path: '/leads',
        name: 'leads',
        builder: (context, state) => const LeadsPage(),
      ),
      GoRoute(
        path: '/leads/create',
        name: 'create-lead',
        builder: (context, state) => const CreateLeadPage(),
      ),
      GoRoute(
        path: '/leads/:id',
        name: 'lead-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return LeadDetailPage(leadId: id);
        },
      ),

      // Super Admin Routes
      GoRoute(
        path: '/super-admin',
        name: 'super-admin',
        builder: (context, state) => const SuperAdminDashboardPage(),
      ),

      // Company Admin Routes
      GoRoute(
        path: '/company-admin',
        name: 'company-admin',
        builder: (context, state) => const CompanyAdminDashboardPage(),
      ),
      GoRoute(
        path: '/company-admin/status-builder',
        name: 'status-builder',
        builder: (context, state) => const StatusBuilderPage(),
      ),
      GoRoute(
        path: '/company-admin/form-builder',
        name: 'form-builder',
        builder: (context, state) => const FormBuilderPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}
