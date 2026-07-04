import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/di/injection_container.dart';
import 'core/theme/signal_theme.dart';
import 'core/services/logger_service.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/companies/presentation/bloc/company_bloc.dart';
import 'features/leads/presentation/bloc/lead_bloc.dart';
import 'features/call_logs/presentation/bloc/call_log_bloc.dart';
import 'features/targets/presentation/bloc/target_bloc.dart';

// Import firebase_options.dart after running: flutterfire configure
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Configure dependencies
    await configureDependencies();

    LoggerService.info('App initialized successfully');

    runApp(const MyApp());
  } catch (e, stackTrace) {
    LoggerService.error('App initialization failed', e, stackTrace);
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<AuthBloc>()..add(AuthCheckStatusEvent()),
        ),
        BlocProvider(create: (_) => sl<CompanyBloc>()),
        BlocProvider(create: (_) => sl<LeadBloc>()),
        BlocProvider(create: (_) => sl<CallLogBloc>()),
        BlocProvider(create: (_) => sl<TargetBloc>()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          final authBloc = context.read<AuthBloc>();
          return MaterialApp.router(
            title: 'LeadFlow Pro',
            debugShowCheckedModeBanner: false,
            theme: SignalTheme.lightTheme,
            darkTheme: SignalTheme.darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: AppRouter(authBloc).router,
          );
        },
      ),
    );
  }
}
