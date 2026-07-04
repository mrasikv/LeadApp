import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../error/app_error.dart';
import '../../models/lead_model.dart';
import '../lead_repository.dart';

@LazySingleton(as: LeadRepository)
class FirestoreLeadRepository implements LeadRepository {
  final FirebaseFirestore _firestore;

  FirestoreLeadRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _leadsRef =>
      _firestore.collection('leads');

  @override
  Future<Either<AppError, List<Lead>>> getLeads({
    required String companyId,
    String? departmentId,
    String? statusId,
    String? assignedTo,
    int? limit,
    String? lastDocumentId,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _leadsRef.where('companyId', isEqualTo: companyId);

      if (departmentId != null) {
        query = query.where('departmentId', isEqualTo: departmentId);
      }
      if (statusId != null) {
        query = query.where('statusId', isEqualTo: statusId);
      }
      if (assignedTo != null) {
        query = query.where('assignedTo', isEqualTo: assignedTo);
      }

      query = query.orderBy('createdAt', descending: true);

      if (lastDocumentId != null) {
        final lastDoc = await _leadsRef.doc(lastDocumentId).get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final leads = snapshot.docs
          .map((doc) => Lead.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      return Right(leads);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, Lead>> getLeadById(String id) async {
    try {
      final doc = await _leadsRef.doc(id).get();
      if (!doc.exists) {
        return Left(AppError.notFoundError(message: 'Lead not found'));
      }
      return Right(Lead.fromJson({...doc.data()!, 'id': doc.id}));
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, List<Lead>>> getLeadsByPhone(
    String companyId,
    String phone,
  ) async {
    try {
      // Normalize phone number
      final normalizedPhone = phone.replaceAll(RegExp(r'\D'), '');

      final snapshot = await _leadsRef
          .where('companyId', isEqualTo: companyId)
          .where('phone', isEqualTo: normalizedPhone)
          .get();

      final leads = snapshot.docs
          .map((doc) => Lead.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      return Right(leads);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, Lead>> createLead(Lead lead) async {
    try {
      final docRef = await _leadsRef.add(lead.toJson());
      return Right(lead.copyWith(id: docRef.id));
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> updateLead(Lead lead) async {
    try {
      await _leadsRef.doc(lead.id).update(lead.toJson());
      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> updateLeadStatus(
    String leadId,
    String newStatusId,
    String userId,
  ) async {
    try {
      await _leadsRef.doc(leadId).update({
        'statusId': newStatusId,
        'statusChangedAt': FieldValue.serverTimestamp(),
        'lastActivityAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> deleteLead(String id) async {
    try {
      await _leadsRef.doc(id).delete();
      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> assignLead(
    String leadId,
    String userId,
  ) async {
    try {
      await _leadsRef.doc(leadId).update({
        'assignedTo': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, List<Lead>>> searchLeads({
    required String companyId,
    required String query,
  }) async {
    try {
      // Search by name (prefix)
      final nameSnapshot = await _leadsRef
          .where('companyId', isEqualTo: companyId)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .limit(20)
          .get();

      // Search by phone
      final phoneSnapshot = await _leadsRef
          .where('companyId', isEqualTo: companyId)
          .where('phone', isEqualTo: query.replaceAll(RegExp(r'\D'), ''))
          .limit(20)
          .get();

      // Search by email
      final emailSnapshot = await _leadsRef
          .where('companyId', isEqualTo: companyId)
          .where('email', isEqualTo: query.toLowerCase())
          .limit(20)
          .get();

      // Combine and deduplicate
      final Map<String, Lead> leadsMap = {};
      for (final doc in [
        ...nameSnapshot.docs,
        ...phoneSnapshot.docs,
        ...emailSnapshot.docs
      ]) {
        if (!leadsMap.containsKey(doc.id)) {
          leadsMap[doc.id] = Lead.fromJson({...doc.data(), 'id': doc.id});
        }
      }

      return Right(leadsMap.values.toList());
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, Map<String, int>>> getLeadsCountByStatus(
    String companyId,
  ) async {
    try {
      final snapshot =
          await _leadsRef.where('companyId', isEqualTo: companyId).get();

      final Map<String, int> counts = {};
      for (final doc in snapshot.docs) {
        final statusId = doc.data()['statusId'] as String?;
        if (statusId != null) {
          counts[statusId] = (counts[statusId] ?? 0) + 1;
        }
      }

      return Right(counts);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, Map<String, List<Lead>>>> getTodaysLeadsByCategory(
    String companyId,
  ) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _leadsRef
          .where('companyId', isEqualTo: companyId)
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
          .where('createdAt', isLessThan: endOfDay)
          .get();

      final Map<String, List<Lead>> result = {
        'to_do': [],
        'in_progress': [],
        'done': [],
      };

      for (final doc in snapshot.docs) {
        final lead = Lead.fromJson({...doc.data(), 'id': doc.id});
        // Note: You'll need to fetch status category separately or store it on lead
        result['to_do']!.add(lead); // Default to to_do
      }

      return Right(result);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Stream<Either<AppError, List<Lead>>> watchLeads({
    required String companyId,
    String? statusId,
    String? assignedTo,
  }) {
    Query<Map<String, dynamic>> query =
        _leadsRef.where('companyId', isEqualTo: companyId);

    if (statusId != null) {
      query = query.where('statusId', isEqualTo: statusId);
    }
    if (assignedTo != null) {
      query = query.where('assignedTo', isEqualTo: assignedTo);
    }

    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      try {
        final leads = snapshot.docs
            .map((doc) => Lead.fromJson({...doc.data(), 'id': doc.id}))
            .toList();
        return Right(leads);
      } catch (e) {
        return Left(AppError.serverError(message: e.toString()));
      }
    });
  }

  @override
  Future<Either<AppError, List<Lead>>> getFollowUpLeads(
    String companyId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _leadsRef
          .where('companyId', isEqualTo: companyId)
          .where('followUpDate', isGreaterThanOrEqualTo: startOfDay)
          .where('followUpDate', isLessThan: endOfDay)
          .get();

      final leads = snapshot.docs
          .map((doc) => Lead.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      return Right(leads);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }
}
