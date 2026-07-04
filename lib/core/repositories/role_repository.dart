import 'package:dartz/dartz.dart';
import '../error/app_error.dart';
import '../models/role_model.dart';

abstract class RoleRepository {
  /// Get all system roles
  Future<Either<AppError, List<Role>>> getSystemRoles();

  /// Get roles for a company (includes system + custom roles)
  Future<Either<AppError, List<Role>>> getRolesByCompany(String companyId);

  /// Get role by ID
  Future<Either<AppError, Role>> getRoleById(String id);

  /// Create a custom role
  Future<Either<AppError, Role>> createRole(Role role);

  /// Update a role
  Future<Either<AppError, void>> updateRole(Role role);

  /// Delete a custom role
  Future<Either<AppError, void>> deleteRole(String id);

  /// Initialize system roles
  Future<Either<AppError, void>> initializeSystemRoles();

  /// Watch roles in real-time
  Stream<Either<AppError, List<Role>>> watchRoles(String companyId);
}
