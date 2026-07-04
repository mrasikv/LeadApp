import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../error/app_error.dart';
import '../../models/company_model.dart';
import '../company_repository.dart';

@LazySingleton(as: CompanyRepository)
class FirestoreCompanyRepository implements CompanyRepository {
  final FirebaseFirestore _firestore;

  FirestoreCompanyRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _companiesRef =>
      _firestore.collection('companies');

  @override
  Future<Either<AppError, List<Company>>> getAllCompanies() async {
    try {
      final snapshot = await _companiesRef.get();
      final companies = snapshot.docs
          .map((doc) => Company.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      return Right(companies);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, List<Company>>> getCompaniesByIds(
      List<String> ids) async {
    try {
      if (ids.isEmpty) return const Right([]);

      // Firestore 'in' query limited to 10 items
      final List<Company> companies = [];
      for (var i = 0; i < ids.length; i += 10) {
        final batch = ids.skip(i).take(10).toList();
        final snapshot = await _companiesRef
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        companies.addAll(
          snapshot.docs.map(
            (doc) => Company.fromJson({...doc.data(), 'id': doc.id}),
          ),
        );
      }
      return Right(companies);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, Company>> getCompanyById(String id) async {
    try {
      final doc = await _companiesRef.doc(id).get();
      if (!doc.exists) {
        return Left(AppError.notFoundError(message: 'Company not found'));
      }
      return Right(Company.fromJson({...doc.data()!, 'id': doc.id}));
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, Company>> getCompanyByCode(String code) async {
    try {
      final snapshot = await _companiesRef
          .where('companyCode', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return Left(AppError.notFoundError(message: 'Company not found'));
      }

      final doc = snapshot.docs.first;
      return Right(Company.fromJson({...doc.data(), 'id': doc.id}));
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, Company>> createCompany(Company company) async {
    try {
      final docRef = await _companiesRef.add(company.toJson());
      return Right(company.copyWith(id: docRef.id));
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> updateCompany(Company company) async {
    try {
      await _companiesRef.doc(company.id).update(company.toJson());
      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> deleteCompany(String id) async {
    try {
      await _companiesRef.doc(id).delete();
      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> toggleCompanyStatus(
      String id, bool isActive) async {
    try {
      await _companiesRef.doc(id).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> updateCompanyFeatures(
    String id,
    Map<String, bool> features,
  ) async {
    try {
      await _companiesRef.doc(id).update({
        'enabledFeatures': features,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, String>> generateUniqueCompanyCode() async {
    try {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final random = Random();

      String code;
      bool exists;

      do {
        code =
            List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
        final snapshot = await _companiesRef
            .where('companyCode', isEqualTo: code)
            .limit(1)
            .get();
        exists = snapshot.docs.isNotEmpty;
      } while (exists);

      return Right(code);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Stream<Either<AppError, List<Company>>> watchAllCompanies() {
    return _companiesRef.snapshots().map((snapshot) {
      try {
        final companies = snapshot.docs
            .map((doc) => Company.fromJson({...doc.data(), 'id': doc.id}))
            .toList();
        return Right(companies);
      } catch (e) {
        return Left(AppError.serverError(message: e.toString()));
      }
    });
  }
}
