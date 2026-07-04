import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/user_company_model.dart';
import '../../../../core/services/logger_service.dart';

abstract class UserRepository {
  Future<Either<AppError, User>> getUserById(String id);
  Future<Either<AppError, User>> getUserByEmail(String email);
  Future<Either<AppError, List<User>>> getCompanyUsers(String companyId);
  Future<Either<AppError, User>> createUser(User user);
  Future<Either<AppError, void>> updateUser(User user);
  Future<Either<AppError, void>> deleteUser(String id);
  Future<Either<AppError, void>> addUserToCompany(
      String userId, String companyId);
  Future<Either<AppError, void>> removeUserFromCompany(
      String userId, String companyId);
  Future<Either<AppError, void>> switchCompany(
      String userId, String companyId, String roleId, String departmentId);
  Future<Either<AppError, UserCompany>> getUserCompany(
      String userId, String companyId);
  Stream<User> watchUser(String id);
}

class UserRepositoryImpl implements UserRepository {
  final FirebaseFirestore _firestore;

  UserRepositoryImpl(this._firestore);

  @override
  Future<Either<AppError, User>> getUserById(String id) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(id)
          .get();

      if (!doc.exists) {
        return const Left(AppError.notFoundError(message: 'User not found'));
      }

      final data = doc.data()!;
      data['id'] = doc.id;

      return Right(User.fromJson(data));
    } catch (e, stackTrace) {
      LoggerService.error('Error getting user', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to load user'));
    }
  }

  @override
  Future<Either<AppError, User>> getUserByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return const Left(AppError.notFoundError(message: 'User not found'));
      }

      final doc = snapshot.docs.first;
      final data = doc.data();
      data['id'] = doc.id;

      return Right(User.fromJson(data));
    } catch (e, stackTrace) {
      LoggerService.error('Error getting user by email', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to load user'));
    }
  }

  @override
  Future<Either<AppError, List<User>>> getCompanyUsers(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('companyIds', arrayContains: companyId)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return User.fromJson(data);
      }).toList();

      return Right(users);
    } catch (e, stackTrace) {
      LoggerService.error('Error getting company users', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to load users'));
    }
  }

  @override
  Future<Either<AppError, User>> createUser(User user) async {
    try {
      final now = DateTime.now();
      final userData = user
          .copyWith(
            createdAt: now,
            updatedAt: now,
          )
          .toJson();

      final docRef = await _firestore
          .collection(AppConstants.usersCollection)
          .add(userData);

      final createdUser = user.copyWith(
        id: docRef.id,
        createdAt: now,
        updatedAt: now,
      );

      return Right(createdUser);
    } catch (e, stackTrace) {
      LoggerService.error('Error creating user', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to create user'));
    }
  }

  @override
  Future<Either<AppError, void>> updateUser(User user) async {
    try {
      final userData = user
          .copyWith(
            updatedAt: DateTime.now(),
          )
          .toJson();

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .update(userData);

      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error updating user', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to update user'));
    }
  }

  @override
  Future<Either<AppError, void>> deleteUser(String id) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(id).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });

      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error deleting user', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to delete user'));
    }
  }

  @override
  Future<Either<AppError, void>> addUserToCompany(
    String userId,
    String companyId,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'companyIds': FieldValue.arrayUnion([companyId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error adding user to company', e, stackTrace);
      return Left(
          AppError.serverError(message: 'Failed to add user to company'));
    }
  }

  @override
  Future<Either<AppError, void>> removeUserFromCompany(
    String userId,
    String companyId,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'companyIds': FieldValue.arrayRemove([companyId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error removing user from company', e, stackTrace);
      return Left(
          AppError.serverError(message: 'Failed to remove user from company'));
    }
  }

  @override
  Future<Either<AppError, void>> switchCompany(
    String userId,
    String companyId,
    String roleId,
    String departmentId,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'currentCompanyId': companyId,
        'currentRoleId': roleId,
        'currentDepartmentId': departmentId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error switching company', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to switch company'));
    }
  }

  @override
  Stream<User> watchUser(String id) {
    try {
      return _firestore
          .collection(AppConstants.usersCollection)
          .doc(id)
          .snapshots()
          .map((doc) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return User.fromJson(data);
      });
    } catch (e) {
      LoggerService.error('Error watching user', e);
      throw ServerException('Failed to watch user');
    }
  }

  @override
  Future<Either<AppError, UserCompany>> getUserCompany(
    String userId,
    String companyId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.userCompaniesCollection)
          .where('userId', isEqualTo: userId)
          .where('companyId', isEqualTo: companyId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return const Left(
            AppError.notFoundError(message: 'User company not found'));
      }

      final doc = snapshot.docs.first;
      final data = doc.data();
      data['id'] = doc.id;

      return Right(UserCompany.fromJson(data));
    } catch (e, stackTrace) {
      LoggerService.error('Error getting user company', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to load user company'));
    }
  }
}
