import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../error/app_error.dart';
import '../../models/company_invite_model.dart';
import '../company_invite_repository.dart';

@LazySingleton(as: CompanyInviteRepository)
class FirestoreCompanyInviteRepository implements CompanyInviteRepository {
  final FirebaseFirestore _firestore;

  FirestoreCompanyInviteRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _invitesRef =>
      _firestore.collection('company_invites');

  @override
  Future<Either<AppError, List<CompanyInvite>>> getPendingInvites(
    String companyId,
  ) async {
    try {
      final snapshot = await _invitesRef
          .where('companyId', isEqualTo: companyId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      final invites = snapshot.docs
          .map((doc) => CompanyInvite.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      return Right(invites);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, CompanyInvite?>> getInviteByCode(
      String inviteCode) async {
    try {
      final snapshot = await _invitesRef
          .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return const Right(null);
      }

      final doc = snapshot.docs.first;
      return Right(CompanyInvite.fromJson({...doc.data(), 'id': doc.id}));
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, CompanyInvite?>> getInviteByEmail(
    String companyId,
    String email,
  ) async {
    try {
      final snapshot = await _invitesRef
          .where('companyId', isEqualTo: companyId)
          .where('email', isEqualTo: email.toLowerCase())
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return const Right(null);
      }

      final doc = snapshot.docs.first;
      return Right(CompanyInvite.fromJson({...doc.data(), 'id': doc.id}));
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, CompanyInvite>> createInvite(
      CompanyInvite invite) async {
    try {
      // Check if invite already exists
      final existingResult =
          await getInviteByEmail(invite.companyId, invite.email);

      if (existingResult.isRight()) {
        final existing = existingResult.getOrElse(() => null);
        if (existing != null) {
          return Left(
            AppError.validationError(
              message: 'An invite already exists for this email',
            ),
          );
        }
      }

      final docRef = await _invitesRef.add(invite.toJson());
      return Right(invite.copyWith(id: docRef.id));
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> acceptInvite(
    String inviteCode,
    String userId,
  ) async {
    try {
      final inviteResult = await getInviteByCode(inviteCode);
      if (inviteResult.isLeft()) {
        return Left(
          AppError.notFoundError(message: 'Invite not found'),
        );
      }

      final invite = inviteResult.getOrElse(() => null);
      if (invite == null) {
        return Left(AppError.notFoundError(message: 'Invite not found'));
      }

      if (invite.status != 'pending') {
        return Left(
          AppError.validationError(message: 'This invite is no longer valid'),
        );
      }

      if (invite.expiresAt?.isBefore(DateTime.now()) == true) {
        await _invitesRef.doc(invite.id).update({'status': 'expired'});
        return Left(
          AppError.validationError(message: 'This invite has expired'),
        );
      }

      await _invitesRef.doc(invite.id).update({
        'status': 'accepted',
        'acceptedBy': userId,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> declineInvite(String inviteCode) async {
    try {
      final inviteResult = await getInviteByCode(inviteCode);
      if (inviteResult.isLeft()) {
        return Left(AppError.notFoundError(message: 'Invite not found'));
      }

      final invite = inviteResult.getOrElse(() => null);
      if (invite == null) {
        return Left(AppError.notFoundError(message: 'Invite not found'));
      }

      await _invitesRef.doc(invite.id).update({
        'status': 'declined',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, void>> cancelInvite(String id) async {
    try {
      await _invitesRef.doc(id).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, CompanyInvite>> resendInvite(String id) async {
    try {
      final newCodeResult = await generateUniqueInviteCode();
      if (newCodeResult.isLeft()) {
        return Left(
          AppError.serverError(message: 'Failed to generate invite code'),
        );
      }

      final newCode = newCodeResult.getOrElse(() => '');
      final newExpiry = DateTime.now().add(const Duration(days: 7));

      await _invitesRef.doc(id).update({
        'inviteCode': newCode,
        'expiresAt': newExpiry,
        'status': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final doc = await _invitesRef.doc(id).get();
      return Right(CompanyInvite.fromJson({...doc.data()!, 'id': doc.id}));
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, bool>> hasPendingInvite(
    String companyId,
    String email,
  ) async {
    try {
      final result = await getInviteByEmail(companyId, email);
      return Right(
        result.isRight() && result.getOrElse(() => null) != null,
      );
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, List<CompanyInvite>>> getPendingInvitesByEmail(
    String email,
  ) async {
    try {
      final snapshot = await _invitesRef
          .where('email', isEqualTo: email.toLowerCase())
          .where('status', isEqualTo: 'pending')
          .get();

      final invites = snapshot.docs
          .map((doc) => CompanyInvite.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      // Filter out expired invites
      final now = DateTime.now();
      final validInvites = invites
          .where(
            (invite) =>
                invite.expiresAt == null || invite.expiresAt!.isAfter(now),
          )
          .toList();

      return Right(validInvites);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }

  @override
  Future<Either<AppError, String>> generateUniqueInviteCode() async {
    try {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final random = Random();

      String code;
      bool exists;

      do {
        code =
            List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
        final snapshot = await _invitesRef
            .where('inviteCode', isEqualTo: code)
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();
        exists = snapshot.docs.isNotEmpty;
      } while (exists);

      return Right(code);
    } catch (e) {
      return Left(AppError.serverError(message: e.toString()));
    }
  }
}
