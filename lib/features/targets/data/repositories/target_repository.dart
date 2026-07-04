import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/models/target_model.dart';
import '../../../../core/services/logger_service.dart';

abstract class TargetRepository {
  Future<Either<AppError, List<Target>>> getTargets(String companyId);
  Future<Either<AppError, Target>> getTargetById(String id);
  Future<Either<AppError, List<Target>>> getUserTargets(
      String companyId, String userId);
  Future<Either<AppError, List<Target>>> getDepartmentTargets(
      String companyId, String departmentId);
  Future<Either<AppError, Target>> createTarget(Target target);
  Future<Either<AppError, void>> updateTarget(Target target);
  Future<Either<AppError, void>> deleteTarget(String id);
  Future<Either<AppError, void>> updateProgress(
      String targetId, double achievedPrice, int achievedQuantity);
  Stream<List<Target>> watchTargets(String companyId);
  Stream<Target> watchTarget(String id);
}

class TargetRepositoryImpl implements TargetRepository {
  final FirebaseFirestore _firestore;

  TargetRepositoryImpl(this._firestore);

  @override
  Future<Either<AppError, List<Target>>> getTargets(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.targetsCollection)
          .where('companyId', isEqualTo: companyId)
          .orderBy('startDate', descending: true)
          .get();

      final targets = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Target.fromJson(data);
      }).toList();

      return Right(targets);
    } catch (e, stackTrace) {
      LoggerService.error('Error getting targets', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to load targets'));
    }
  }

  @override
  Future<Either<AppError, Target>> getTargetById(String id) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.targetsCollection)
          .doc(id)
          .get();

      if (!doc.exists) {
        return const Left(AppError.notFoundError(message: 'Target not found'));
      }

      final data = doc.data()!;
      data['id'] = doc.id;

      return Right(Target.fromJson(data));
    } catch (e, stackTrace) {
      LoggerService.error('Error getting target', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to load target'));
    }
  }

  @override
  Future<Either<AppError, List<Target>>> getUserTargets(
    String companyId,
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.targetsCollection)
          .where('companyId', isEqualTo: companyId)
          .where('assignedTo', isEqualTo: userId)
          .orderBy('startDate', descending: true)
          .get();

      final targets = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Target.fromJson(data);
      }).toList();

      return Right(targets);
    } catch (e, stackTrace) {
      LoggerService.error('Error getting user targets', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to load targets'));
    }
  }

  @override
  Future<Either<AppError, List<Target>>> getDepartmentTargets(
    String companyId,
    String departmentId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.targetsCollection)
          .where('companyId', isEqualTo: companyId)
          .where('departmentId', isEqualTo: departmentId)
          .orderBy('startDate', descending: true)
          .get();

      final targets = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Target.fromJson(data);
      }).toList();

      return Right(targets);
    } catch (e, stackTrace) {
      LoggerService.error('Error getting department targets', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to load targets'));
    }
  }

  @override
  Future<Either<AppError, Target>> createTarget(Target target) async {
    try {
      final now = DateTime.now();
      final targetData = target
          .copyWith(
            createdAt: now,
            updatedAt: now,
          )
          .toJson();

      final docRef = await _firestore
          .collection(AppConstants.targetsCollection)
          .add(targetData);

      final createdTarget = target.copyWith(
        id: docRef.id,
        createdAt: now,
        updatedAt: now,
      );

      return Right(createdTarget);
    } catch (e, stackTrace) {
      LoggerService.error('Error creating target', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to create target'));
    }
  }

  @override
  Future<Either<AppError, void>> updateTarget(Target target) async {
    try {
      final targetData = target
          .copyWith(
            updatedAt: DateTime.now(),
          )
          .toJson();

      await _firestore
          .collection(AppConstants.targetsCollection)
          .doc(target.id)
          .update(targetData);

      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error updating target', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to update target'));
    }
  }

  @override
  Future<Either<AppError, void>> deleteTarget(String id) async {
    try {
      await _firestore
          .collection(AppConstants.targetsCollection)
          .doc(id)
          .delete();

      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error deleting target', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to delete target'));
    }
  }

  @override
  Future<Either<AppError, void>> updateProgress(
    String targetId,
    double achievedPrice,
    int achievedQuantity,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.targetsCollection)
          .doc(targetId)
          .update({
        'achievedPrice': achievedPrice,
        'achievedQuantity': achievedQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error updating target progress', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to update progress'));
    }
  }

  @override
  Stream<List<Target>> watchTargets(String companyId) {
    try {
      return _firestore
          .collection(AppConstants.targetsCollection)
          .where('companyId', isEqualTo: companyId)
          .orderBy('startDate', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Target.fromJson(data);
        }).toList();
      });
    } catch (e) {
      LoggerService.error('Error watching targets', e);
      return Stream.value([]);
    }
  }

  @override
  Stream<Target> watchTarget(String id) {
    try {
      return _firestore
          .collection(AppConstants.targetsCollection)
          .doc(id)
          .snapshots()
          .map((doc) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Target.fromJson(data);
      });
    } catch (e) {
      LoggerService.error('Error watching target', e);
      throw Exception('Failed to watch target');
    }
  }
}
