import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/services/logger_service.dart';

abstract class LeadRepository {
  Future<Either<AppError, List<Lead>>> getLeads(String companyId);
  Future<Either<AppError, Lead>> getLeadById(String id);
  Future<Either<AppError, List<Lead>>> getLeadsByProject(String projectId);
  Future<Either<AppError, List<Lead>>> getLeadsByStatus(
      String companyId, String statusId);
  Future<Either<AppError, List<Lead>>> getLeadsByAssignee(
      String companyId, String userId);
  Future<Either<AppError, Lead>> createLead(Lead lead);
  Future<Either<AppError, void>> updateLead(Lead lead);
  Future<Either<AppError, void>> deleteLead(String id);
  Future<Either<AppError, void>> assignLead(String leadId, String userId);
  Future<Either<AppError, void>> changeStatus(String leadId, String statusId);
  Stream<List<Lead>> watchLeads(String companyId);
  Stream<List<Lead>> watchLeadsByProject(String projectId);
  Stream<Lead> watchLead(String id);
}

class LeadRepositoryImpl implements LeadRepository {
  final FirebaseFirestore _firestore;

  LeadRepositoryImpl(this._firestore);

  @override
  Future<Either<AppError, List<Lead>>> getLeads(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.leadsCollection)
          .where('companyId', isEqualTo: companyId)
          .orderBy('createdAt', descending: true)
          .get();

      final leads = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Lead.fromJson(data);
      }).toList();

      return Right(leads);
    } catch (e, stackTrace) {
      LoggerService.error('Error getting leads', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to load leads'));
    }
  }

  @override
  Future<Either<AppError, Lead>> getLeadById(String id) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.leadsCollection)
          .doc(id)
          .get();

      if (!doc.exists) {
        return const Left(AppError.notFoundError(message: 'Lead not found'));
      }

      final data = doc.data()!;
      data['id'] = doc.id;

      return Right(Lead.fromJson(data));
    } catch (e, stackTrace) {
      LoggerService.error('Error getting lead', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to load lead'));
    }
  }

  @override
  Future<Either<AppError, List<Lead>>> getLeadsByProject(
      String projectId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.leadsCollection)
          .where('projectId', isEqualTo: projectId)
          .orderBy('createdAt', descending: true)
          .get();

      final leads = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Lead.fromJson(data);
      }).toList();

      return Right(leads);
    } catch (e, stackTrace) {
      LoggerService.error('Error getting leads by project', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to load leads'));
    }
  }

  @override
  Future<Either<AppError, List<Lead>>> getLeadsByStatus(
    String companyId,
    String statusId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.leadsCollection)
          .where('companyId', isEqualTo: companyId)
          .where('statusId', isEqualTo: statusId)
          .orderBy('statusChangedAt', descending: true)
          .get();

      final leads = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Lead.fromJson(data);
      }).toList();

      return Right(leads);
    } catch (e, stackTrace) {
      LoggerService.error('Error getting leads by status', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to load leads'));
    }
  }

  @override
  Future<Either<AppError, List<Lead>>> getLeadsByAssignee(
    String companyId,
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.leadsCollection)
          .where('companyId', isEqualTo: companyId)
          .where('assignedTo', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final leads = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Lead.fromJson(data);
      }).toList();

      return Right(leads);
    } catch (e, stackTrace) {
      LoggerService.error('Error getting leads by assignee', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to load leads'));
    }
  }

  @override
  Future<Either<AppError, Lead>> createLead(Lead lead) async {
    try {
      final now = DateTime.now();
      final leadData = lead
          .copyWith(
            createdAt: now,
            updatedAt: now,
            statusChangedAt: now,
          )
          .toJson();

      final docRef = await _firestore
          .collection(AppConstants.leadsCollection)
          .add(leadData);

      final createdLead = lead.copyWith(
        id: docRef.id,
        createdAt: now,
        updatedAt: now,
        statusChangedAt: now,
      );

      return Right(createdLead);
    } catch (e, stackTrace) {
      LoggerService.error('Error creating lead', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to create lead'));
    }
  }

  @override
  Future<Either<AppError, void>> updateLead(Lead lead) async {
    try {
      final leadData = lead
          .copyWith(
            updatedAt: DateTime.now(),
          )
          .toJson();

      await _firestore
          .collection(AppConstants.leadsCollection)
          .doc(lead.id)
          .update(leadData);

      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error updating lead', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to update lead'));
    }
  }

  @override
  Future<Either<AppError, void>> deleteLead(String id) async {
    try {
      await _firestore.collection(AppConstants.leadsCollection).doc(id).update({
        'deletedAt': FieldValue.serverTimestamp(),
      });

      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error deleting lead', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to delete lead'));
    }
  }

  @override
  Future<Either<AppError, void>> assignLead(
      String leadId, String userId) async {
    try {
      await _firestore
          .collection(AppConstants.leadsCollection)
          .doc(leadId)
          .update({
        'assignedTo': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error assigning lead', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to assign lead'));
    }
  }

  @override
  Future<Either<AppError, void>> changeStatus(
      String leadId, String statusId) async {
    try {
      await _firestore
          .collection(AppConstants.leadsCollection)
          .doc(leadId)
          .update({
        'statusId': statusId,
        'statusChangedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error changing lead status', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to change status'));
    }
  }

  @override
  Stream<List<Lead>> watchLeads(String companyId) {
    try {
      return _firestore
          .collection(AppConstants.leadsCollection)
          .where('companyId', isEqualTo: companyId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Lead.fromJson(data);
        }).toList();
      });
    } catch (e) {
      LoggerService.error('Error watching leads', e);
      return Stream.value([]);
    }
  }

  @override
  Stream<List<Lead>> watchLeadsByProject(String projectId) {
    try {
      return _firestore
          .collection(AppConstants.leadsCollection)
          .where('projectId', isEqualTo: projectId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Lead.fromJson(data);
        }).toList();
      });
    } catch (e) {
      LoggerService.error('Error watching leads by project', e);
      return Stream.value([]);
    }
  }

  @override
  Stream<Lead> watchLead(String id) {
    try {
      return _firestore
          .collection(AppConstants.leadsCollection)
          .doc(id)
          .snapshots()
          .map((doc) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Lead.fromJson(data);
      });
    } catch (e) {
      LoggerService.error('Error watching lead', e);
      throw Exception('Failed to watch lead');
    }
  }
}
