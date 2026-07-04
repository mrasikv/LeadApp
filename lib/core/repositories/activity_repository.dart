import 'package:dartz/dartz.dart';
import '../error/app_error.dart';
import '../models/activity_model.dart';
import '../models/note_model.dart';

abstract class ActivityRepository {
  /// Get activities for a lead
  Future<Either<AppError, List<Activity>>> getActivitiesByLead(
    String leadId, {
    int? limit,
  });

  /// Get activities for a user
  Future<Either<AppError, List<Activity>>> getActivitiesByUser(
    String companyId,
    String userId, {
    int? limit,
  });

  /// Create an activity (immutable - no update/delete)
  Future<Either<AppError, Activity>> createActivity(Activity activity);

  /// Get recent activities for dashboard
  Future<Either<AppError, List<Activity>>> getRecentActivities(
    String companyId, {
    int limit = 20,
  });

  /// Watch activities for a lead in real-time
  Stream<Either<AppError, List<Activity>>> watchLeadActivities(String leadId);
}

abstract class NoteRepository {
  /// Get notes for a lead
  Future<Either<AppError, List<Note>>> getNotesByLead(String leadId);

  /// Create a note
  Future<Either<AppError, Note>> createNote(Note note);

  /// Update a note (only by creator)
  Future<Either<AppError, void>> updateNote(Note note);

  /// Delete a note
  Future<Either<AppError, void>> deleteNote(String id);

  /// Watch notes for a lead in real-time
  Stream<Either<AppError, List<Note>>> watchLeadNotes(String leadId);
}
