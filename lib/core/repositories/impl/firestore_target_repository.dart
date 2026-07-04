import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../error/app_error.dart';
import '../../models/target_model.dart';
import '../../models/ticket_model.dart';
import '../target_repository.dart';

@LazySingleton(as: TargetRepository)
class FirestoreTargetRepository implements TargetRepository {
  final FirebaseFirestore _firestore;

  FirestoreTargetRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _targetsRef =>
      _firestore.collection('targets');

  CollectionReference<Map<String, dynamic>> get _ticketsRef =>
      _firestore.collection('tickets');

  @override
  Future<Either<AppError, List<Target>>> getTargetsByCompany(
    String companyId,
    String month,
  ) async {
    try {
      final snapshot = await _targetsRef
          .where('companyId', isEqualTo: companyId)
          .where('month', isEqualTo: month)
          .get();

      final targets = snapshot.docs
          .map((doc) => Target.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      return Right(targets);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, Target?>> getTargetByUser(
    String companyId,
    String userId,
    String month,
  ) async {
    try {
      final snapshot = await _targetsRef
          .where('companyId', isEqualTo: companyId)
          .where('userId', isEqualTo: userId)
          .where('month', isEqualTo: month)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return const Right(null);
      }

      final doc = snapshot.docs.first;
      return Right(Target.fromJson({...doc.data(), 'id': doc.id}));
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, List<Target>>> getTargetsByDepartment(
    String companyId,
    String departmentId,
    String month,
  ) async {
    try {
      final snapshot = await _targetsRef
          .where('companyId', isEqualTo: companyId)
          .where('departmentId', isEqualTo: departmentId)
          .where('month', isEqualTo: month)
          .get();

      final targets = snapshot.docs
          .map((doc) => Target.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      return Right(targets);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, Target>> createTarget(Target target) async {
    try {
      final docRef = await _targetsRef.add(target.toJson());
      return Right(target.copyWith(id: docRef.id));
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> updateTarget(Target target) async {
    try {
      await _targetsRef.doc(target.id).update(target.toJson());
      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> deleteTarget(String id) async {
    try {
      await _targetsRef.doc(id).delete();
      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> recalculateAchievements(
    String companyId,
    String month,
  ) async {
    try {
      // Get all targets for the month
      final targetsSnapshot = await _targetsRef
          .where('companyId', isEqualTo: companyId)
          .where('month', isEqualTo: month)
          .get();

      // Get all closed tickets for the month
      final monthParts = month.split('-');
      final year = int.parse(monthParts[0]);
      final monthNum = int.parse(monthParts[1]);
      final startOfMonth = DateTime(year, monthNum, 1);
      final endOfMonth = DateTime(year, monthNum + 1, 1);

      for (final targetDoc in targetsSnapshot.docs) {
        final userId = targetDoc.data()['userId'] as String?;
        if (userId == null) continue;

        // Get won tickets for this user
        final ticketsSnapshot = await _ticketsRef
            .where('companyId', isEqualTo: companyId)
            .where('closedBy', isEqualTo: userId)
            .where('status', isEqualTo: 'won')
            .where('closedAt', isGreaterThanOrEqualTo: startOfMonth)
            .where('closedAt', isLessThan: endOfMonth)
            .get();

        double achievedValue = 0;
        int achievedCount = 0;
        for (final ticket in ticketsSnapshot.docs) {
          achievedValue += (ticket.data()['amount'] as num?)?.toDouble() ?? 0;
          achievedCount++;
        }

        await targetDoc.reference.update({
          'achievedValue': achievedValue,
          'achievedCount': achievedCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, Map<String, dynamic>>> getTargetSummary(
    String companyId,
    String month,
  ) async {
    try {
      final snapshot = await _targetsRef
          .where('companyId', isEqualTo: companyId)
          .where('month', isEqualTo: month)
          .get();

      double totalTargetValue = 0;
      double totalAchievedValue = 0;
      int totalTargetCount = 0;
      int totalAchievedCount = 0;
      int usersWithTargets = 0;
      int usersAchievedTarget = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final targetValue = (data['targetValue'] as num?)?.toDouble() ?? 0;
        final achievedValue = (data['achievedValue'] as num?)?.toDouble() ?? 0;
        final targetCount = data['targetCount'] as int? ?? 0;
        final achievedCount = data['achievedCount'] as int? ?? 0;

        totalTargetValue += targetValue;
        totalAchievedValue += achievedValue;
        totalTargetCount += targetCount;
        totalAchievedCount += achievedCount;
        usersWithTargets++;

        if (achievedValue >= targetValue && targetValue > 0) {
          usersAchievedTarget++;
        }
      }

      return Right({
        'totalTargetValue': totalTargetValue,
        'totalAchievedValue': totalAchievedValue,
        'totalTargetCount': totalTargetCount,
        'totalAchievedCount': totalAchievedCount,
        'usersWithTargets': usersWithTargets,
        'usersAchievedTarget': usersAchievedTarget,
        'overallPercentage': totalTargetValue > 0
            ? (totalAchievedValue / totalTargetValue * 100).round()
            : 0,
      });
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Stream<Either<AppError, Target?>> watchUserTarget(
    String companyId,
    String userId,
    String month,
  ) {
    return _targetsRef
        .where('companyId', isEqualTo: companyId)
        .where('userId', isEqualTo: userId)
        .where('month', isEqualTo: month)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      try {
        if (snapshot.docs.isEmpty) {
          return const Right(null);
        }
        final doc = snapshot.docs.first;
        return Right(Target.fromJson({...doc.data(), 'id': doc.id}));
      } catch (e) {
        return Left(AppError.serverError(message: e.toString()));
      }
    });
  }
}

@LazySingleton(as: TicketRepository)
class FirestoreTicketRepository implements TicketRepository {
  final FirebaseFirestore _firestore;

  FirestoreTicketRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _ticketsRef =>
      _firestore.collection('tickets');

  @override
  Future<Either<AppError, List<Ticket>>> getTicketsByCompany(
    String companyId, {
    String? status,
    String? userId,
    int? limit,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _ticketsRef.where('companyId', isEqualTo: companyId);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      if (userId != null) {
        query = query.where('createdBy', isEqualTo: userId);
      }

      query = query.orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final tickets = snapshot.docs
          .map((doc) => Ticket.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      return Right(tickets);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, Ticket>> getTicketById(String id) async {
    try {
      final doc = await _ticketsRef.doc(id).get();
      if (!doc.exists) {
        return Left(AppError.notFoundError(message: 'Ticket not found'));
      }
      return Right(Ticket.fromJson({...doc.data()!, 'id': doc.id}));
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, List<Ticket>>> getTicketsByLead(String leadId) async {
    try {
      final snapshot = await _ticketsRef
          .where('leadId', isEqualTo: leadId)
          .orderBy('createdAt', descending: true)
          .get();

      final tickets = snapshot.docs
          .map((doc) => Ticket.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      return Right(tickets);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, Ticket>> createTicket(Ticket ticket) async {
    try {
      final docRef = await _ticketsRef.add(ticket.toJson());
      return Right(ticket.copyWith(id: docRef.id));
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> updateTicket(Ticket ticket) async {
    try {
      await _ticketsRef.doc(ticket.id).update(ticket.toJson());
      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> closeTicket(
    String id,
    String status,
    String? notes,
  ) async {
    try {
      await _ticketsRef.doc(id).update({
        'status': status,
        'closedAt': FieldValue.serverTimestamp(),
        if (notes != null) 'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> deleteTicket(String id) async {
    try {
      await _ticketsRef.doc(id).delete();
      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, Map<String, dynamic>>> getTicketsSummary(
    String companyId,
    String month,
  ) async {
    try {
      final monthParts = month.split('-');
      final year = int.parse(monthParts[0]);
      final monthNum = int.parse(monthParts[1]);
      final startOfMonth = DateTime(year, monthNum, 1);
      final endOfMonth = DateTime(year, monthNum + 1, 1);

      final snapshot = await _ticketsRef
          .where('companyId', isEqualTo: companyId)
          .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
          .where('createdAt', isLessThan: endOfMonth)
          .get();

      int totalTickets = 0;
      int openTickets = 0;
      int wonTickets = 0;
      int lostTickets = 0;
      double totalValue = 0;
      double wonValue = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;

        totalTickets++;
        totalValue += amount;

        switch (status) {
          case 'open':
            openTickets++;
            break;
          case 'won':
            wonTickets++;
            wonValue += amount;
            break;
          case 'lost':
            lostTickets++;
            break;
        }
      }

      return Right({
        'totalTickets': totalTickets,
        'openTickets': openTickets,
        'wonTickets': wonTickets,
        'lostTickets': lostTickets,
        'totalValue': totalValue,
        'wonValue': wonValue,
        'conversionRate':
            totalTickets > 0 ? (wonTickets / totalTickets * 100).round() : 0,
      });
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Stream<Either<AppError, List<Ticket>>> watchTickets(
    String companyId, {
    String? userId,
  }) {
    Query<Map<String, dynamic>> query =
        _ticketsRef.where('companyId', isEqualTo: companyId);

    if (userId != null) {
      query = query.where('createdBy', isEqualTo: userId);
    }

    query = query.orderBy('createdAt', descending: true).limit(50);

    return query.snapshots().map((snapshot) {
      try {
        final tickets = snapshot.docs
            .map((doc) => Ticket.fromJson({...doc.data(), 'id': doc.id}))
            .toList();
        return Right(tickets);
      } catch (e) {
        return Left(AppError.serverError(message: e.toString()));
      }
    });
  }
}
