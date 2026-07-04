import 'package:dartz/dartz.dart';
import '../error/app_error.dart';
import '../models/dynamic_form_model.dart';

abstract class DynamicFormRepository {
  /// Get forms for a company
  Future<Either<AppError, List<DynamicForm>>> getFormsByCompany(
    String companyId,
  );

  /// Get form by ID
  Future<Either<AppError, DynamicForm>> getFormById(String id);

  /// Get form for a specific department
  Future<Either<AppError, DynamicForm?>> getFormByDepartment(
    String companyId,
    String departmentId,
  );

  /// Get company-wide default form
  Future<Either<AppError, DynamicForm?>> getDefaultForm(String companyId);

  /// Create a form
  Future<Either<AppError, DynamicForm>> createForm(DynamicForm form);

  /// Update a form
  Future<Either<AppError, void>> updateForm(DynamicForm form);

  /// Delete a form
  Future<Either<AppError, void>> deleteForm(String id);

  /// Initialize default form for a company
  Future<Either<AppError, DynamicForm>> initializeDefaultForm(String companyId);

  /// Watch forms in real-time
  Stream<Either<AppError, List<DynamicForm>>> watchForms(String companyId);
}
