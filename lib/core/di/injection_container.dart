import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/call_logs/data/repositories/call_log_repository.dart';
import '../../features/call_logs/data/services/call_log_service.dart';
import '../../features/call_logs/presentation/bloc/call_log_bloc.dart';
import '../../features/companies/data/repositories/company_repository.dart';
import '../../features/companies/presentation/bloc/company_bloc.dart';
import '../../features/leads/data/repositories/lead_repository.dart';
import '../../features/leads/presentation/bloc/lead_bloc.dart';
import '../../features/projects/data/repositories/project_repository.dart';
import '../../features/projects/presentation/bloc/project_bloc.dart';
import '../../features/super_admin/data/repositories/project_type_repository.dart';
import '../../features/super_admin/presentation/bloc/project_type_bloc.dart';
import '../../features/targets/data/repositories/target_repository.dart';
import '../../features/targets/presentation/bloc/target_bloc.dart';
import '../../features/user_management/data/repositories/user_repository.dart';
import '../services/auth_service.dart';
import '../services/permission_service.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // Firebase
  final firestore = FirebaseFirestore.instance;
  final firebaseAuth = FirebaseAuth.instance;
  sl.registerSingleton<FirebaseFirestore>(firestore);
  sl.registerSingleton<FirebaseAuth>(firebaseAuth);

  // Core Services
  sl.registerLazySingleton<AuthService>(
      () => AuthService(sl<FirebaseAuth>(), sl<FirebaseFirestore>()));
  sl.registerLazySingleton<PermissionService>(
      () => PermissionService(sl<FirebaseAuth>()));
  sl.registerLazySingleton<CallLogService>(() => CallLogService());

  // Repositories
  sl.registerLazySingleton<CompanyRepository>(
    () => CompanyRepositoryImpl(sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<LeadRepository>(
    () => LeadRepositoryImpl(sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<CallLogRepository>(
    () => CallLogRepositoryImpl(sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<TargetRepository>(
    () => TargetRepositoryImpl(sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<ProjectRepository>(
    () => ProjectRepositoryImpl(sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<ProjectTypeRepository>(
    () => ProjectTypeRepositoryImpl(sl<FirebaseFirestore>()),
  );

  // BLoCs
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      sl<FirebaseAuth>(),
      sl<UserRepository>(),
      sl<CompanyRepository>(),
    ),
  );
  sl.registerFactory<CompanyBloc>(
    () => CompanyBloc(sl<CompanyRepository>()),
  );
  sl.registerFactory<LeadBloc>(
    () => LeadBloc(sl<LeadRepository>()),
  );
  sl.registerFactory<CallLogBloc>(
    () => CallLogBloc(sl<CallLogRepository>(), sl<CallLogService>()),
  );
  sl.registerFactory<TargetBloc>(
    () => TargetBloc(sl<TargetRepository>()),
  );
  sl.registerFactory<ProjectBloc>(
    () => ProjectBloc(sl<ProjectRepository>()),
  );
  sl.registerFactory<ProjectTypeBloc>(
    () => ProjectTypeBloc(sl<ProjectTypeRepository>()),
  );
}
