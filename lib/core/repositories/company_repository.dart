import 'package:dartz/dartz.dart';
import '../error/app_error.dart';
import '../models/company_model.dart';

abstract class CompanyRepository {
  /// Get all companies (Super Admin only)
  Future<Either<AppError, List<Company>>> getAllCompanies();

  /// Get companies by IDs (for user's companies)
  Future<Either<AppError, List<Company>>> getCompaniesByIds(List<String> ids);

  /// Get a single company by ID
  Future<Either<AppError, Company>> getCompanyById(String id);

  /// Get company by company code
  Future<Either<AppError, Company>> getCompanyByCode(String code);

  /// Create a new company
  Future<Either<AppError, Company>> createCompany(Company company);

  /// Update a company
  Future<Either<AppError, void>> updateCompany(Company company);

  /// Delete a company (Super Admin only)
  Future<Either<AppError, void>> deleteCompany(String id);

  /// Toggle company active status
  Future<Either<AppError, void>> toggleCompanyStatus(String id, bool isActive);

  /// Update company features
  Future<Either<AppError, void>> updateCompanyFeatures(
    String id,
    Map<String, bool> features,
  );

  /// Generate unique company code
  Future<Either<AppError, String>> generateUniqueCompanyCode();

  /// Watch all companies (real-time)
  Stream<Either<AppError, List<Company>>> watchAllCompanies();
}
