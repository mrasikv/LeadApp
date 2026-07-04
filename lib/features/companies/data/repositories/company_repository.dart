import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/models/company_model.dart';
import '../../../../core/services/logger_service.dart';

abstract class CompanyRepository {
  Future<Either<AppError, List<Company>>> getAllCompanies();
  Future<Either<AppError, Company>> getCompanyById(String id);
  Future<Either<AppError, Company>> getCompanyByCode(String code);
  Future<Either<AppError, Company>> createCompany(Company company);
  Future<Either<AppError, void>> updateCompany(Company company);
  Future<Either<AppError, void>> deleteCompany(String id);
  Future<Either<AppError, List<Company>>> getUserCompanies(
      List<String> companyIds);
  Stream<List<Company>> watchCompanies();
}

class CompanyRepositoryImpl implements CompanyRepository {
  final FirebaseFirestore _firestore;

  CompanyRepositoryImpl(this._firestore);

  @override
  Future<Either<AppError, List<Company>>> getAllCompanies() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.companiesCollection)
          .orderBy('name')
          .get();

      final companies = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Company.fromJson(data);
      }).toList();

      return Right(companies);
    } catch (e, stackTrace) {
      LoggerService.error('Error getting companies', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to load companies'));
    }
  }

  @override
  Future<Either<AppError, Company>> getCompanyById(String id) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.companiesCollection)
          .doc(id)
          .get();

      if (!doc.exists) {
        return const Left(AppError.notFoundError(message: 'Company not found'));
      }

      final data = doc.data()!;
      data['id'] = doc.id;

      return Right(Company.fromJson(data));
    } catch (e, stackTrace) {
      LoggerService.error('Error getting company', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to load company'));
    }
  }

  @override
  Future<Either<AppError, Company>> getCompanyByCode(String code) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.companiesCollection)
          .where('companyCode', isEqualTo: code.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return const Left(
          AppError.notFoundError(message: 'Invalid company code'),
        );
      }

      final doc = snapshot.docs.first;
      final data = doc.data();
      data['id'] = doc.id;

      return Right(Company.fromJson(data));
    } catch (e, stackTrace) {
      LoggerService.error('Error getting company by code', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to load company'));
    }
  }

  @override
  Future<Either<AppError, Company>> createCompany(Company company) async {
    try {
      // Check if company code already exists
      final existingCompany = await getCompanyByCode(company.companyCode!);
      if (existingCompany.isRight()) {
        return const Left(
          AppError.validationError(message: 'Company code already exists'),
        );
      }

      final now = DateTime.now();
      final companyData = company
          .copyWith(
            createdAt: now,
            updatedAt: now,
          )
          .toJson();

      final docRef = await _firestore
          .collection(AppConstants.companiesCollection)
          .add(companyData);

      final createdCompany = company.copyWith(
        id: docRef.id,
        createdAt: now,
        updatedAt: now,
      );

      return Right(createdCompany);
    } catch (e, stackTrace) {
      LoggerService.error('Error creating company', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to create company'));
    }
  }

  @override
  Future<Either<AppError, void>> updateCompany(Company company) async {
    try {
      final companyData = company
          .copyWith(
            updatedAt: DateTime.now(),
          )
          .toJson();

      await _firestore
          .collection(AppConstants.companiesCollection)
          .doc(company.id)
          .update(companyData);

      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error updating company', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to update company'));
    }
  }

  @override
  Future<Either<AppError, void>> deleteCompany(String id) async {
    try {
      await _firestore
          .collection(AppConstants.companiesCollection)
          .doc(id)
          .delete();

      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error deleting company', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to delete company'));
    }
  }

  @override
  Future<Either<AppError, List<Company>>> getUserCompanies(
    List<String> companyIds,
  ) async {
    try {
      // Filter out empty strings to prevent Firestore invalid-argument error
      final validIds = companyIds.where((id) => id.isNotEmpty).toList();

      if (validIds.isEmpty) {
        return const Right([]);
      }

      final snapshot = await _firestore
          .collection(AppConstants.companiesCollection)
          .where(FieldPath.documentId, whereIn: validIds)
          .get();

      final companies = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Company.fromJson(data);
      }).toList();

      return Right(companies);
    } catch (e, stackTrace) {
      LoggerService.error('Error getting user companies', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to load companies'));
    }
  }

  @override
  Stream<List<Company>> watchCompanies() {
    try {
      return _firestore
          .collection(AppConstants.companiesCollection)
          .orderBy('name')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Company.fromJson(data);
        }).toList();
      });
    } catch (e) {
      LoggerService.error('Error watching companies', e);
      return Stream.value([]);
    }
  }
}
