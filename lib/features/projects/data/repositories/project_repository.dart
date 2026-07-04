import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/models/project_type_model.dart';
import '../../../../core/models/lead_status_model.dart';
import '../../../../core/services/logger_service.dart';

abstract class ProjectRepository {
  Future<Either<AppError, List<Project>>> getProjects(String companyId);
  Future<Either<AppError, Project>> getProjectById(String id);
  Future<Either<AppError, Project>> createProject(
      Project project, ProjectType projectType);
  Future<Either<AppError, void>> updateProject(Project project);
  Future<Either<AppError, void>> deleteProject(String id);
  Future<Either<AppError, void>> toggleProjectActive(String id, bool isActive);
  Future<Either<AppError, void>> updateLeadCounts(String projectId);
  Stream<List<Project>> watchProjects(String companyId);
  Stream<Project> watchProject(String id);
}

class ProjectRepositoryImpl implements ProjectRepository {
  final FirebaseFirestore _firestore;

  ProjectRepositoryImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _projectsCollection =>
      _firestore.collection(AppConstants.projectsCollection);

  CollectionReference<Map<String, dynamic>> get _statusesCollection =>
      _firestore.collection(AppConstants.leadStatusesCollection);

  @override
  Future<Either<AppError, List<Project>>> getProjects(String companyId) async {
    try {
      final snapshot = await _projectsCollection
          .where('companyId', isEqualTo: companyId)
          .orderBy('createdAt', descending: true)
          .get();

      final projects = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Project.fromJson(data);
      }).toList();

      return Right(projects);
    } catch (e, stackTrace) {
      LoggerService.error('Error getting projects', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to load projects'));
    }
  }

  @override
  Future<Either<AppError, Project>> getProjectById(String id) async {
    try {
      final doc = await _projectsCollection.doc(id).get();

      if (!doc.exists) {
        return const Left(AppError.notFoundError(message: 'Project not found'));
      }

      final data = doc.data()!;
      data['id'] = doc.id;

      return Right(Project.fromJson(data));
    } catch (e, stackTrace) {
      LoggerService.error('Error getting project', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to load project'));
    }
  }

  @override
  Future<Either<AppError, Project>> createProject(
    Project project,
    ProjectType projectType,
  ) async {
    try {
      final now = DateTime.now();

      // Use Firestore batch to create project and its default statuses
      final batch = _firestore.batch();

      // Create project document
      final projectRef = _projectsCollection.doc();
      final projectData = project
          .copyWith(
            id: projectRef.id,
            projectTypeId: projectType.id,
            projectTypeName: projectType.name,
            createdAt: now,
            updatedAt: now,
          )
          .toJson();

      projectData.remove('id'); // Firestore auto-generates ID
      batch.set(projectRef, projectData);

      // Create default statuses from project type template
      for (int i = 0; i < projectType.defaultStatuses.length; i++) {
        final template = projectType.defaultStatuses[i];
        final statusRef = _statusesCollection.doc();

        final status = LeadStatus(
          id: statusRef.id,
          companyId: project.companyId,
          projectId: projectRef.id,
          name: template.name,
          category: template.category,
          color: template.color,
          order: template.order,
          isDefault: template.isDefault,
          mandatoryFields: template.mandatoryFields,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        final statusData = status.toJson();
        statusData.remove('id');
        batch.set(statusRef, statusData);
      }

      await batch.commit();

      final createdProject = project.copyWith(
        id: projectRef.id,
        projectTypeId: projectType.id,
        projectTypeName: projectType.name,
        createdAt: now,
        updatedAt: now,
      );

      return Right(createdProject);
    } catch (e, stackTrace) {
      LoggerService.error('Error creating project', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to create project'));
    }
  }

  @override
  Future<Either<AppError, void>> updateProject(Project project) async {
    try {
      final data = project
          .copyWith(
            updatedAt: DateTime.now(),
          )
          .toJson();

      data.remove('id');
      data.remove('createdAt');

      await _projectsCollection.doc(project.id).update(data);

      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error updating project', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to update project'));
    }
  }

  @override
  Future<Either<AppError, void>> deleteProject(String id) async {
    try {
      // Delete project and all its statuses
      final batch = _firestore.batch();

      // Delete project
      batch.delete(_projectsCollection.doc(id));

      // Delete associated statuses
      final statusSnapshot =
          await _statusesCollection.where('projectId', isEqualTo: id).get();

      for (final doc in statusSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error deleting project', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to delete project'));
    }
  }

  @override
  Future<Either<AppError, void>> toggleProjectActive(
      String id, bool isActive) async {
    try {
      await _projectsCollection.doc(id).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error toggling project active', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to update project'));
    }
  }

  @override
  Future<Either<AppError, void>> updateLeadCounts(String projectId) async {
    try {
      // Get lead counts
      final leadsSnapshot = await _firestore
          .collection(AppConstants.leadsCollection)
          .where('projectId', isEqualTo: projectId)
          .get();

      final totalLeads = leadsSnapshot.docs.length;

      // Get active leads (not converted)
      final activeLeads = leadsSnapshot.docs
          .where((doc) => doc.data()['isConverted'] != true)
          .length;

      // Get won leads (converted)
      final wonLeads = leadsSnapshot.docs
          .where((doc) => doc.data()['isConverted'] == true)
          .length;

      await _projectsCollection.doc(projectId).update({
        'leadCount': totalLeads,
        'activeLeadCount': activeLeads,
        'wonLeadCount': wonLeads,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error updating lead counts', e, stackTrace);
      return Left(
          AppError.serverError(message: 'Failed to update lead counts'));
    }
  }

  @override
  Stream<List<Project>> watchProjects(String companyId) {
    return _projectsCollection
        .where('companyId', isEqualTo: companyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Project.fromJson(data);
      }).toList();
    });
  }

  @override
  Stream<Project> watchProject(String id) {
    return _projectsCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists) {
        throw Exception('Project not found');
      }
      final data = doc.data()!;
      data['id'] = doc.id;
      return Project.fromJson(data);
    });
  }
}
