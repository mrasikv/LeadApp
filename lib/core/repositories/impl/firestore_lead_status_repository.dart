import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../error/app_error.dart';
import '../../models/lead_status_model.dart';
import '../lead_status_repository.dart';

@LazySingleton(as: LeadStatusRepository)
class FirestoreLeadStatusRepository implements LeadStatusRepository {
  final FirebaseFirestore _firestore;

  FirestoreLeadStatusRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _statusesRef =>
      _firestore.collection('lead_statuses');

  static const List<Map<String, dynamic>> _defaultStatuses = [
    {
      'name': 'New',
      'color': '#3498db',
      'category': 'to_do',
      'order': 1,
      'canDelete': false,
      'isDefault': true,
    },
    {
      'name': 'Contacted',
      'color': '#f39c12',
      'category': 'in_progress',
      'order': 2,
      'canDelete': true,
      'isDefault': false,
    },
    {
      'name': 'Follow-up',
      'color': '#9b59b6',
      'category': 'in_progress',
      'order': 3,
      'canDelete': true,
      'isDefault': false,
    },
    {
      'name': 'Interested',
      'color': '#27ae60',
      'category': 'in_progress',
      'order': 4,
      'canDelete': true,
      'isDefault': false,
    },
    {
      'name': 'Converted',
      'color': '#2ecc71',
      'category': 'done',
      'order': 5,
      'canDelete': false,
      'isDefault': false,
    },
    {
      'name': 'Not Interested',
      'color': '#e74c3c',
      'category': 'done',
      'order': 6,
      'canDelete': false,
      'isDefault': false,
    },
  ];

  @override
  Future<Either<AppError, List<LeadStatus>>> getStatusesByCompany(
    String companyId,
  ) async {
    try {
      final snapshot = await _statusesRef
          .where('companyId', isEqualTo: companyId)
          .orderBy('order')
          .get();

      final statuses = snapshot.docs
          .map((doc) => LeadStatus.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      return Right(statuses);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, LeadStatus>> getStatusById(String id) async {
    try {
      final doc = await _statusesRef.doc(id).get();
      if (!doc.exists) {
        return Left(AppError.notFoundError(message: 'Status not found'));
      }
      return Right(LeadStatus.fromJson({...doc.data()!, 'id': doc.id}));
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, LeadStatus>> createStatus(LeadStatus status) async {
    try {
      final docRef = await _statusesRef.add(status.toJson());
      return Right(status.copyWith(id: docRef.id));
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> updateStatus(LeadStatus status) async {
    try {
      await _statusesRef.doc(status.id).update(status.toJson());
      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> deleteStatus(String id) async {
    try {
      // Check if can delete
      final doc = await _statusesRef.doc(id).get();
      if (doc.exists && doc.data()?['canDelete'] == false) {
        return Left(
          AppError.permissionError(message: 'This status cannot be deleted'),
        );
      }
      await _statusesRef.doc(id).delete();
      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> reorderStatuses(
    String companyId,
    List<String> statusIds,
  ) async {
    try {
      final batch = _firestore.batch();
      for (var i = 0; i < statusIds.length; i++) {
        batch.update(_statusesRef.doc(statusIds[i]), {'order': i + 1});
      }
      await batch.commit();
      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> initializeDefaultStatuses(
      String companyId) async {
    try {
      final batch = _firestore.batch();
      for (final statusData in _defaultStatuses) {
        final docRef = _statusesRef.doc();
        batch.set(docRef, {
          ...statusData,
          'companyId': companyId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, List<LeadStatus>>> getStatusesByCategory(
    String companyId,
    String category,
  ) async {
    try {
      final snapshot = await _statusesRef
          .where('companyId', isEqualTo: companyId)
          .where('category', isEqualTo: category)
          .orderBy('order')
          .get();

      final statuses = snapshot.docs
          .map((doc) => LeadStatus.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      return Right(statuses);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Stream<Either<AppError, List<LeadStatus>>> watchStatuses(String companyId) {
    return _statusesRef
        .where('companyId', isEqualTo: companyId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      try {
        final statuses = snapshot.docs
            .map((doc) => LeadStatus.fromJson({...doc.data(), 'id': doc.id}))
            .toList();
        return Right(statuses);
      } catch (e) {
        return Left(AppError.serverError(message: e.toString()));
      }
    });
  }
}
