import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../error/app_error.dart';
import '../../models/user_model.dart';
import '../../models/user_company_model.dart';
import '../user_repository.dart';

@LazySingleton(as: UserRepository)
class FirestoreUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;

  FirestoreUserRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _userCompaniesRef =>
      _firestore.collection('user_companies');

  @override
  Future<Either<AppError, User>> getUserById(String id) async {
    try {
      final doc = await _usersRef.doc(id).get();
      if (!doc.exists) {
        return Left(AppError.notFoundError(message: 'User not found'));
      }
      return Right(User.fromJson({...doc.data()!, 'id': doc.id}));
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, User?>> getUserByEmail(String email) async {
    try {
      final snapshot = await _usersRef
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return const Right(null);
      }

      final doc = snapshot.docs.first;
      return Right(User.fromJson({...doc.data(), 'id': doc.id}));
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, List<User>>> getUsersByCompany(
      String companyId) async {
    try {
      // Get user IDs from user_companies collection
      final userCompaniesSnapshot = await _userCompaniesRef
          .where('companyId', isEqualTo: companyId)
          .get();

      if (userCompaniesSnapshot.docs.isEmpty) {
        return const Right([]);
      }

      final userIds = userCompaniesSnapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toSet()
          .toList();

      final users = <User>[];
      for (var i = 0; i < userIds.length; i += 10) {
        final batch = userIds.skip(i).take(10).toList();
        final snapshot =
            await _usersRef.where(FieldPath.documentId, whereIn: batch).get();
        users.addAll(
          snapshot.docs.map(
            (doc) => User.fromJson({...doc.data(), 'id': doc.id}),
          ),
        );
      }

      return Right(users);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, List<User>>> getUsersByDepartment(
    String companyId,
    String departmentId,
  ) async {
    try {
      final userCompaniesSnapshot = await _userCompaniesRef
          .where('companyId', isEqualTo: companyId)
          .where('departmentId', isEqualTo: departmentId)
          .get();

      if (userCompaniesSnapshot.docs.isEmpty) {
        return const Right([]);
      }

      final userIds = userCompaniesSnapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toSet()
          .toList();

      final users = <User>[];
      for (var i = 0; i < userIds.length; i += 10) {
        final batch = userIds.skip(i).take(10).toList();
        final snapshot =
            await _usersRef.where(FieldPath.documentId, whereIn: batch).get();
        users.addAll(
          snapshot.docs.map(
            (doc) => User.fromJson({...doc.data(), 'id': doc.id}),
          ),
        );
      }

      return Right(users);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, User>> createUser(User user) async {
    try {
      // Use the auth UID as document ID
      await _usersRef.doc(user.id).set(user.toJson());
      return Right(user);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> updateUser(User user) async {
    try {
      await _usersRef.doc(user.id).update(user.toJson());
      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> deleteUser(String id) async {
    try {
      // Delete user's company associations
      final userCompaniesSnapshot =
          await _userCompaniesRef.where('userId', isEqualTo: id).get();

      final batch = _firestore.batch();
      for (final doc in userCompaniesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_usersRef.doc(id));
      await batch.commit();

      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> toggleUserStatus(
      String id, bool isActive) async {
    try {
      await _usersRef.doc(id).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, List<UserCompany>>> getUserCompanies(
      String userId) async {
    try {
      final snapshot =
          await _userCompaniesRef.where('userId', isEqualTo: userId).get();

      final userCompanies = snapshot.docs
          .map((doc) => UserCompany.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      return Right(userCompanies);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, UserCompany>> addUserToCompany(
      UserCompany userCompany) async {
    try {
      final docRef = await _userCompaniesRef.add(userCompany.toJson());

      // Update user's companyIds array
      await _usersRef.doc(userCompany.userId).update({
        'companyIds': FieldValue.arrayUnion([userCompany.companyId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return Right(userCompany.copyWith(id: docRef.id));
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> updateUserCompany(
      UserCompany userCompany) async {
    try {
      await _userCompaniesRef.doc(userCompany.id).update(userCompany.toJson());
      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> removeUserFromCompany(
    String userId,
    String companyId,
  ) async {
    try {
      // Find and delete the user_company document
      final snapshot = await _userCompaniesRef
          .where('userId', isEqualTo: userId)
          .where('companyId', isEqualTo: companyId)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      // Update user's companyIds array
      await _usersRef.doc(userId).update({
        'companyIds': FieldValue.arrayRemove([companyId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> setPrimaryCompany(
    String userId,
    String companyId,
  ) async {
    try {
      // Unset previous primary
      final snapshot =
          await _userCompaniesRef.where('userId', isEqualTo: userId).get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        final isPrimary = doc.data()['companyId'] == companyId;
        batch.update(doc.reference, {'isPrimary': isPrimary});
      }
      await batch.commit();

      // Update current company on user
      await _usersRef.doc(userId).update({
        'currentCompanyId': companyId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Stream<Either<AppError, List<User>>> watchUsersByCompany(String companyId) {
    return _userCompaniesRef
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .asyncMap((snapshot) async {
      try {
        if (snapshot.docs.isEmpty) {
          return const Right(<User>[]);
        }

        final userIds = snapshot.docs
            .map((doc) => doc.data()['userId'] as String)
            .toSet()
            .toList();

        final users = <User>[];
        for (var i = 0; i < userIds.length; i += 10) {
          final batch = userIds.skip(i).take(10).toList();
          final usersSnapshot =
              await _usersRef.where(FieldPath.documentId, whereIn: batch).get();
          users.addAll(
            usersSnapshot.docs.map(
              (doc) => User.fromJson({...doc.data(), 'id': doc.id}),
            ),
          );
        }

        return Right(users);
      } catch (e) {
        return Left(AppError.serverError(message: e.toString()));
      }
    });
  }
}
