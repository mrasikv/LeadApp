import 'package:dartz/dartz.dart';
import '../error/app_error.dart';
import '../models/department_model.dart';

abstract class DepartmentRepository {
  /// Get all departments for a company
  Future<Either<AppError, List<Department>>> getDepartmentsByCompany(
    String companyId,
  );

  /// Get a single department by ID
  Future<Either<AppError, Department>> getDepartmentById(String id);

  /// Create a new department
  Future<Either<AppError, Department>> createDepartment(Department department);

  /// Update a department
  Future<Either<AppError, void>> updateDepartment(Department department);

  /// Delete a department
  Future<Either<AppError, void>> deleteDepartment(String id);

  /// Toggle department active status
  Future<Either<AppError, void>> toggleDepartmentStatus(
    String id,
    bool isActive,
  );

  /// Watch departments in real-time
  Stream<Either<AppError, List<Department>>> watchDepartments(String companyId);
}
