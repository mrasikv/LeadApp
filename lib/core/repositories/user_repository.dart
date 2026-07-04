import 'package:dartz/dartz.dart';
import '../error/app_error.dart';
import '../models/user_model.dart';
import '../models/user_company_model.dart';

abstract class UserRepository {
  /// Get user by ID
  Future<Either<AppError, User>> getUserById(String id);

  /// Get user by email
  Future<Either<AppError, User?>> getUserByEmail(String email);

  /// Get all users for a company
  Future<Either<AppError, List<User>>> getUsersByCompany(String companyId);

  /// Get users by department
  Future<Either<AppError, List<User>>> getUsersByDepartment(
    String companyId,
    String departmentId,
  );

  /// Create a new user
  Future<Either<AppError, User>> createUser(User user);

  /// Update a user
  Future<Either<AppError, void>> updateUser(User user);

  /// Delete a user
  Future<Either<AppError, void>> deleteUser(String id);

  /// Toggle user active status
  Future<Either<AppError, void>> toggleUserStatus(String id, bool isActive);

  /// Get user's company memberships
  Future<Either<AppError, List<UserCompany>>> getUserCompanies(String userId);

  /// Add user to company
  Future<Either<AppError, UserCompany>> addUserToCompany(
      UserCompany userCompany);

  /// Update user's company membership
  Future<Either<AppError, void>> updateUserCompany(UserCompany userCompany);

  /// Remove user from company
  Future<Either<AppError, void>> removeUserFromCompany(
    String userId,
    String companyId,
  );

  /// Set primary company for user
  Future<Either<AppError, void>> setPrimaryCompany(
    String userId,
    String companyId,
  );

  /// Watch users by company (real-time)
  Stream<Either<AppError, List<User>>> watchUsersByCompany(String companyId);
}
