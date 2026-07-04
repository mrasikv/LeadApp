import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/models/project_type_model.dart';
import '../../../../core/services/logger_service.dart';

abstract class ProjectTypeRepository {
  Future<Either<AppError, List<ProjectType>>> getProjectTypes();
  Future<Either<AppError, ProjectType>> getProjectTypeById(String id);
  Future<Either<AppError, ProjectType>> createProjectType(
      ProjectType projectType);
  Future<Either<AppError, void>> updateProjectType(ProjectType projectType);
  Future<Either<AppError, void>> deleteProjectType(String id);
  Future<Either<AppError, void>> toggleProjectTypeActive(
      String id, bool isActive);
  Future<Either<AppError, void>> seedDefaultProjectTypes();
  Stream<List<ProjectType>> watchProjectTypes();
}

class ProjectTypeRepositoryImpl implements ProjectTypeRepository {
  final FirebaseFirestore _firestore;

  ProjectTypeRepositoryImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.projectTypesCollection);

  /// Converts ProjectType to a Firestore-compatible Map
  /// Firestore cannot serialize Freezed objects directly
  Map<String, dynamic> _toFirestoreData(ProjectType projectType) {
    final data = <String, dynamic>{
      'name': projectType.name,
      'description': projectType.description,
      'icon': projectType.icon,
      'color': projectType.color,
      'isActive': projectType.isActive,
      'createdAt': Timestamp.fromDate(projectType.createdAt),
      'updatedAt': Timestamp.fromDate(projectType.updatedAt),
      'createdBy': projectType.createdBy,
      // Convert StatusTemplate objects to plain Maps
      'defaultStatuses': projectType.defaultStatuses
          .map((status) => {
                'name': status.name,
                'category': status.category,
                'color': status.color,
                'order': status.order,
                'isDefault': status.isDefault,
                'mandatoryFields': status.mandatoryFields,
              })
          .toList(),
    };
    return data;
  }

  @override
  Future<Either<AppError, List<ProjectType>>> getProjectTypes() async {
    try {
      final snapshot =
          await _collection.orderBy('createdAt', descending: false).get();

      final projectTypes = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ProjectType.fromJson(data);
      }).toList();

      return Right(projectTypes);
    } catch (e, stackTrace) {
      LoggerService.error('Error getting project types', e, stackTrace);
      return Left(
          AppError.serverError(message: 'Failed to load project types'));
    }
  }

  @override
  Future<Either<AppError, ProjectType>> getProjectTypeById(String id) async {
    try {
      final doc = await _collection.doc(id).get();

      if (!doc.exists) {
        return const Left(
            AppError.notFoundError(message: 'Project type not found'));
      }

      final data = doc.data()!;
      data['id'] = doc.id;

      return Right(ProjectType.fromJson(data));
    } catch (e, stackTrace) {
      LoggerService.error('Error getting project type', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to load project type'));
    }
  }

  @override
  Future<Either<AppError, ProjectType>> createProjectType(
      ProjectType projectType) async {
    try {
      final now = DateTime.now();
      final updatedType = projectType.copyWith(
        createdAt: now,
        updatedAt: now,
      );

      // Use helper to convert to Firestore-compatible data
      final data = _toFirestoreData(updatedType);

      final docRef = await _collection.add(data);

      final created = updatedType.copyWith(id: docRef.id);

      return Right(created);
    } catch (e, stackTrace) {
      LoggerService.error('Error creating project type', e, stackTrace);
      return Left(
          AppError.serverError(message: 'Failed to create project type'));
    }
  }

  @override
  Future<Either<AppError, void>> updateProjectType(
      ProjectType projectType) async {
    try {
      final updatedType = projectType.copyWith(
        updatedAt: DateTime.now(),
      );

      // Use helper to convert to Firestore-compatible data
      final data = _toFirestoreData(updatedType);
      // Don't update createdAt
      data.remove('createdAt');

      await _collection.doc(projectType.id).update(data);

      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error updating project type', e, stackTrace);
      return Left(
          AppError.serverError(message: 'Failed to update project type'));
    }
  }

  @override
  Future<Either<AppError, void>> deleteProjectType(String id) async {
    try {
      await _collection.doc(id).delete();
      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error deleting project type', e, stackTrace);
      return Left(
          AppError.serverError(message: 'Failed to delete project type'));
    }
  }

  @override
  Future<Either<AppError, void>> toggleProjectTypeActive(
      String id, bool isActive) async {
    try {
      await _collection.doc(id).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error toggling project type active', e, stackTrace);
      return Left(
          AppError.serverError(message: 'Failed to update project type'));
    }
  }

  @override
  Stream<List<ProjectType>> watchProjectTypes() {
    return _collection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ProjectType.fromJson(data);
      }).toList();
    });
  }

  @override
  Future<Either<AppError, void>> seedDefaultProjectTypes() async {
    try {
      // Check if any project types exist
      final existing = await _collection.limit(1).get();
      if (existing.docs.isNotEmpty) {
        LoggerService.info('Project types already exist, skipping seed');
        return const Right(null);
      }

      final now = DateTime.now();
      final batch = _firestore.batch();

      final defaultTypes = _getDefaultProjectTypes(now);

      for (final type in defaultTypes) {
        final docRef = _collection.doc();
        // Use helper to convert to Firestore-compatible data
        final data = _toFirestoreData(type);
        batch.set(docRef, data);
      }

      await batch.commit();
      LoggerService.info('Seeded ${defaultTypes.length} default project types');
      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error seeding project types', e, stackTrace);
      return Left(
          AppError.serverError(message: 'Failed to seed project types'));
    }
  }

  List<ProjectType> _getDefaultProjectTypes(DateTime now) {
    return [
      ProjectType(
        id: '',
        name: 'Real Estate',
        description: 'For property sales and rental leads',
        icon: 'home',
        color: '#4CAF50',
        isActive: true,
        defaultStatuses: const [
          StatusTemplate(
              name: 'New Lead',
              category: 'to_do',
              color: '#2196F3',
              order: 1,
              isDefault: true),
          StatusTemplate(
              name: 'Contacted',
              category: 'in_progress',
              color: '#FF9800',
              order: 2),
          StatusTemplate(
              name: 'Site Visit Scheduled',
              category: 'in_progress',
              color: '#9C27B0',
              order: 3),
          StatusTemplate(
              name: 'Site Visit Done',
              category: 'in_progress',
              color: '#00BCD4',
              order: 4),
          StatusTemplate(
              name: 'Negotiation',
              category: 'in_progress',
              color: '#FFC107',
              order: 5),
          StatusTemplate(
              name: 'Won', category: 'done', color: '#4CAF50', order: 6),
          StatusTemplate(
              name: 'Lost', category: 'done', color: '#F44336', order: 7),
        ],
        createdAt: now,
        updatedAt: now,
      ),
      ProjectType(
        id: '',
        name: 'Education',
        description: 'For educational institution leads',
        icon: 'school',
        color: '#2196F3',
        isActive: true,
        defaultStatuses: const [
          StatusTemplate(
              name: 'Inquiry',
              category: 'to_do',
              color: '#2196F3',
              order: 1,
              isDefault: true),
          StatusTemplate(
              name: 'Follow Up',
              category: 'in_progress',
              color: '#FF9800',
              order: 2),
          StatusTemplate(
              name: 'Counseling Done',
              category: 'in_progress',
              color: '#9C27B0',
              order: 3),
          StatusTemplate(
              name: 'Application Submitted',
              category: 'in_progress',
              color: '#00BCD4',
              order: 4),
          StatusTemplate(
              name: 'Enrolled', category: 'done', color: '#4CAF50', order: 5),
          StatusTemplate(
              name: 'Not Interested',
              category: 'done',
              color: '#9E9E9E',
              order: 6),
        ],
        createdAt: now,
        updatedAt: now,
      ),
      ProjectType(
        id: '',
        name: 'Insurance',
        description: 'For insurance policy leads',
        icon: 'security',
        color: '#673AB7',
        isActive: true,
        defaultStatuses: const [
          StatusTemplate(
              name: 'New',
              category: 'to_do',
              color: '#2196F3',
              order: 1,
              isDefault: true),
          StatusTemplate(
              name: 'Called',
              category: 'in_progress',
              color: '#FF9800',
              order: 2),
          StatusTemplate(
              name: 'Meeting Scheduled',
              category: 'in_progress',
              color: '#9C27B0',
              order: 3),
          StatusTemplate(
              name: 'Proposal Sent',
              category: 'in_progress',
              color: '#00BCD4',
              order: 4),
          StatusTemplate(
              name: 'Policy Issued',
              category: 'done',
              color: '#4CAF50',
              order: 5),
          StatusTemplate(
              name: 'Rejected', category: 'done', color: '#F44336', order: 6),
        ],
        createdAt: now,
        updatedAt: now,
      ),
      ProjectType(
        id: '',
        name: 'Automobile',
        description: 'For vehicle sales leads',
        icon: 'directions_car',
        color: '#FF5722',
        isActive: true,
        defaultStatuses: const [
          StatusTemplate(
              name: 'Inquiry',
              category: 'to_do',
              color: '#2196F3',
              order: 1,
              isDefault: true),
          StatusTemplate(
              name: 'Test Drive Scheduled',
              category: 'in_progress',
              color: '#FF9800',
              order: 2),
          StatusTemplate(
              name: 'Test Drive Done',
              category: 'in_progress',
              color: '#9C27B0',
              order: 3),
          StatusTemplate(
              name: 'Quotation Sent',
              category: 'in_progress',
              color: '#00BCD4',
              order: 4),
          StatusTemplate(
              name: 'Booking Done',
              category: 'done',
              color: '#4CAF50',
              order: 5),
          StatusTemplate(
              name: 'Delivery Complete',
              category: 'done',
              color: '#8BC34A',
              order: 6),
          StatusTemplate(
              name: 'Lost', category: 'done', color: '#9E9E9E', order: 7),
        ],
        createdAt: now,
        updatedAt: now,
      ),
      ProjectType(
        id: '',
        name: 'General Sales',
        description: 'Generic sales pipeline',
        icon: 'trending_up',
        color: '#009688',
        isActive: true,
        defaultStatuses: const [
          StatusTemplate(
              name: 'New',
              category: 'to_do',
              color: '#2196F3',
              order: 1,
              isDefault: true),
          StatusTemplate(
              name: 'Contacted',
              category: 'in_progress',
              color: '#FF9800',
              order: 2),
          StatusTemplate(
              name: 'Qualified',
              category: 'in_progress',
              color: '#9C27B0',
              order: 3),
          StatusTemplate(
              name: 'Proposal',
              category: 'in_progress',
              color: '#00BCD4',
              order: 4),
          StatusTemplate(
              name: 'Negotiation',
              category: 'in_progress',
              color: '#FFC107',
              order: 5),
          StatusTemplate(
              name: 'Closed Won', category: 'done', color: '#4CAF50', order: 6),
          StatusTemplate(
              name: 'Closed Lost',
              category: 'done',
              color: '#F44336',
              order: 7),
        ],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
