import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/company_login_page.dart';
import '../../features/companies/presentation/pages/company_signup_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/leads/presentation/pages/leads_page.dart';
import '../../features/leads/presentation/pages/create_lead_page.dart';
import '../../features/leads/presentation/pages/create_lead_page_new.dart';
import '../../features/leads/presentation/pages/lead_detail_page.dart';
import '../../features/leads/presentation/pages/import_leads_page.dart';
import '../../features/leads/presentation/pages/status_management_page.dart';
import '../../features/call_logs/presentation/pages/call_logs_page.dart';
import '../../features/companies/presentation/pages/super_admin_company_management_page.dart';
import '../../features/user_management/presentation/pages/company_admin_dashboard_page.dart';
import '../../features/user_management/presentation/pages/user_management_page.dart';
import '../../features/targets/presentation/pages/targets_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/follow_ups/presentation/pages/follow_ups_page.dart';
import '../../features/projects/presentation/pages/create_project_page.dart';
import '../../features/projects/presentation/pages/project_detail_page.dart';
import '../../features/projects/presentation/pages/projects_page.dart';
import '../../features/super_admin/presentation/pages/super_admin_dashboard_page.dart';
import '../di/injection_container.dart';
import '../../features/leads/presentation/bloc/lead_bloc.dart';
import '../../features/call_logs/presentation/bloc/call_log_bloc.dart';
import '../../features/companies/presentation/bloc/company_bloc.dart';
import '../../features/targets/presentation/bloc/target_bloc.dart';
import '../../features/projects/presentation/bloc/project_bloc.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isAuthenticated = authState is AuthAuthenticated;
      final isLoading = authState is AuthLoading;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/company-login' ||
          state.matchedLocation == '/company-signup';

      // Don't redirect while loading
      if (isLoading) return null;

      // Redirect to login if not authenticated
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      // Redirect to appropriate dashboard if authenticated and on auth route
      if (isAuthenticated && isAuthRoute) {
        final authenticated = authState as AuthAuthenticated;
        if (authenticated.isSuperAdmin) {
          return '/super-admin';
        }
        return '/dashboard';
      }

      return null;
    },
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
      GoRoute(
        path: '/company-signup',
        name: 'company-signup',
        builder: (context, state) => const CompanySignupPage(),
      ),

      // Main Dashboard
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<LeadBloc>()),
            BlocProvider(create: (_) => sl<CallLogBloc>()),
            BlocProvider(create: (_) => sl<TargetBloc>()),
            BlocProvider(create: (_) => sl<ProjectBloc>()),
          ],
          child: const DashboardPage(),
        ),
      ),

      // Leads Routes
      GoRoute(
        path: '/leads',
        name: 'leads',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<LeadBloc>(),
          child: const LeadsPage(),
        ),
      ),
      GoRoute(
        path: '/leads/import',
        name: 'import-leads',
        builder: (context, state) {
          final projectId = state.uri.queryParameters['projectId'];
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => sl<LeadBloc>()),
              BlocProvider(create: (_) => sl<ProjectBloc>()),
            ],
            child: ImportLeadsPage(projectId: projectId),
          );
        },
      ),
      GoRoute(
        path: '/leads/create',
        name: 'create-lead',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<LeadBloc>()),
            BlocProvider(create: (_) => sl<ProjectBloc>()),
          ],
          child: const CreateLeadPageNew(),
        ),
      ),
      GoRoute(
        path: '/leads/:id',
        name: 'lead-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => sl<LeadBloc>()),
              BlocProvider(create: (_) => sl<ProjectBloc>()),
            ],
            child: LeadDetailPage(leadId: id),
          );
        },
      ),

      // Call Logs Routes
      GoRoute(
        path: '/calls',
        name: 'calls',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<CallLogBloc>(),
          child: const CallLogsPage(),
        ),
      ),

      // Follow-ups
      GoRoute(
        path: '/follow-ups',
        name: 'follow-ups',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<LeadBloc>(),
          child: const FollowUpsPage(),
        ),
      ),

      // Targets
      GoRoute(
        path: '/targets',
        name: 'targets',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<TargetBloc>(),
          child: const TargetsPage(),
        ),
      ),

      // Profile
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),

      // Super Admin Routes
      GoRoute(
        path: '/super-admin',
        name: 'super-admin',
        builder: (context, state) => const SuperAdminDashboardPage(),
      ),
      GoRoute(
        path: '/super-admin/companies',
        name: 'super-admin-companies',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<CompanyBloc>(),
          child: const SuperAdminCompanyManagementPage(),
        ),
      ),
      GoRoute(
        path: '/super-admin/companies/:id',
        name: 'company-details',
        builder: (context, state) {
          final companyId = state.pathParameters['id']!;
          return BlocProvider(
            create: (_) => sl<CompanyBloc>(),
            child: Scaffold(
              appBar: AppBar(title: const Text('Company Details')),
              body: Center(child: Text('Company ID: $companyId')),
            ),
          );
        },
      ),

      // Company Admin Routes
      GoRoute(
        path: '/company-admin',
        name: 'company-admin',
        builder: (context, state) => const CompanyAdminDashboardPage(),
      ),
      GoRoute(
        path: '/company-admin/users',
        name: 'manage-users',
        builder: (context, state) => const UserManagementPage(),
      ),
      GoRoute(
        path: '/company-admin/statuses',
        name: 'manage-statuses',
        builder: (context, state) => const StatusManagementPage(),
      ),
      GoRoute(
        path: '/company-admin/targets',
        name: 'manage-targets',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<TargetBloc>(),
          child: const TargetsPage(),
        ),
      ),

      // Project Routes
      GoRoute(
        path: '/projects',
        name: 'projects',
        builder: (context, state) => const ProjectsPage(),
      ),
      GoRoute(
        path: '/projects/create',
        name: 'create-project',
        builder: (context, state) => const CreateProjectPage(),
      ),
      GoRoute(
        path: '/projects/:id',
        name: 'project-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProjectDetailPage(projectId: id);
        },
      ),
      // Create lead under specific project
      GoRoute(
        path: '/projects/:projectId/leads/create',
        name: 'create-project-lead',
        builder: (context, state) {
          final projectId = state.pathParameters['projectId']!;
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => sl<LeadBloc>()),
              BlocProvider(create: (_) => sl<ProjectBloc>()),
            ],
            child: CreateLeadPageNew(projectId: projectId),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Page not found: ${state.matchedLocation}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Stream that converts Bloc stream to Listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    stream.listen((_) => notifyListeners());
  }
}
