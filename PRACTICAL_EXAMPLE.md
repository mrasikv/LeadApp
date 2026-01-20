# 🔨 PRACTICAL EXAMPLE: Implementing Lead Repository

## Step-by-Step Guide for Your First Implementation

This guide shows exactly how to implement the Lead CRUD operations, serving as a template for all other features.

---

## Step 1: Create Repository Interface

Create `lib/features/leads/domain/repositories/lead_repository.dart`:

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/models/lead_model.dart';

abstract class LeadRepository {
  /// Get all leads for a company with optional filters
  Future<Either<AppError, List<Lead>>> getLeads({
    required String companyId,
    String? departmentId,
    String? statusId,
    String? assignedTo,
    int? limit,
    String? lastDocumentId,
  });

  /// Get a single lead by ID
  Future<Either<AppError, Lead>> getLeadById(String id);

  /// Create a new lead
  Future<Either<AppError, Lead>> createLead(Lead lead);

  /// Update an existing lead
  Future<Either<AppError, void>> updateLead(Lead lead);

  /// Delete a lead
  Future<Either<AppError, void>> deleteLead(String id);

  /// Watch leads in real-time
  Stream<Either<AppError, List<Lead>>> watchLeads({
    required String companyId,
    String? statusId,
  });

  /// Search leads by name or phone
  Future<Either<AppError, List<Lead>>> searchLeads({
    required String companyId,
    required String query,
  });

  /// Get leads count by status
  Future<Either<AppError, Map<String, int>>> getLeadsCountByStatus(
    String companyId,
  );
}
```

---

## Step 2: Implement Repository

Create `lib/features/leads/data/repositories/lead_repository_impl.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/services/logger_service.dart';
import '../../domain/repositories/lead_repository.dart';

class LeadRepositoryImpl implements LeadRepository {
  final FirebaseFirestore _firestore;

  LeadRepositoryImpl(this._firestore);

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
      Query query = _firestore
          .collection(AppConstants.leadsCollection)
          .where('companyId', isEqualTo: companyId);

      // Apply filters
      if (departmentId != null) {
        query = query.where('departmentId', isEqualTo: departmentId);
      }
      if (statusId != null) {
        query = query.where('statusId', isEqualTo: statusId);
      }
      if (assignedTo != null) {
        query = query.where('assignedTo', isEqualTo: assignedTo);
      }

      // Order and limit
      query = query.orderBy('createdAt', descending: true);
      if (limit != null) {
        query = query.limit(limit);
      }

      // Pagination
      if (lastDocumentId != null) {
        final lastDoc = await _firestore
            .collection(AppConstants.leadsCollection)
            .doc(lastDocumentId)
            .get();
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();

      final leads = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
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
  Future<Either<AppError, Lead>> createLead(Lead lead) async {
    try {
      final now = DateTime.now();
      final leadData = lead.copyWith(
        createdAt: now,
        updatedAt: now,
        statusChangedAt: now,
      ).toJson();

      final docRef = await _firestore
          .collection(AppConstants.leadsCollection)
          .add(leadData);

      final createdLead = lead.copyWith(
        id: docRef.id,
        createdAt: now,
        updatedAt: now,
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
      final leadData = lead.copyWith(
        updatedAt: DateTime.now(),
      ).toJson();

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
      await _firestore
          .collection(AppConstants.leadsCollection)
          .doc(id)
          .delete();

      return const Right(null);
    } catch (e, stackTrace) {
      LoggerService.error('Error deleting lead', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to delete lead'));
    }
  }

  @override
  Stream<Either<AppError, List<Lead>>> watchLeads({
    required String companyId,
    String? statusId,
  }) {
    try {
      Query query = _firestore
          .collection(AppConstants.leadsCollection)
          .where('companyId', isEqualTo: companyId);

      if (statusId != null) {
        query = query.where('statusId', isEqualTo: statusId);
      }

      query = query.orderBy('updatedAt', descending: true).limit(20);

      return query.snapshots().map((snapshot) {
        final leads = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return Lead.fromJson(data);
        }).toList();

        return Right(leads);
      });
    } catch (e) {
      LoggerService.error('Error watching leads', e);
      return Stream.value(
        Left(AppError.serverError(message: 'Failed to watch leads')),
      );
    }
  }

  @override
  Future<Either<AppError, List<Lead>>> searchLeads({
    required String companyId,
    required String query,
  }) async {
    try {
      // Note: This is a basic search. For production, consider:
      // 1. Algolia/ElasticSearch for full-text search
      // 2. Cloud Function for advanced search

      final lowerQuery = query.toLowerCase();

      final snapshot = await _firestore
          .collection(AppConstants.leadsCollection)
          .where('companyId', isEqualTo: companyId)
          .get();

      final leads = snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Lead.fromJson(data);
          })
          .where((lead) =>
              lead.name.toLowerCase().contains(lowerQuery) ||
              lead.phone.contains(query) ||
              (lead.email?.toLowerCase().contains(lowerQuery) ?? false))
          .toList();

      return Right(leads);
    } catch (e, stackTrace) {
      LoggerService.error('Error searching leads', e, stackTrace);
      return Left(AppError.serverError(message: 'Failed to search leads'));
    }
  }

  @override
  Future<Either<AppError, Map<String, int>>> getLeadsCountByStatus(
    String companyId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.leadsCollection)
          .where('companyId', isEqualTo: companyId)
          .get();

      final Map<String, int> countByStatus = {};

      for (final doc in snapshot.docs) {
        final statusId = doc.data()['statusId'] as String;
        countByStatus[statusId] = (countByStatus[statusId] ?? 0) + 1;
      }

      return Right(countByStatus);
    } catch (e, stackTrace) {
      LoggerService.error('Error getting leads count', e, stackTrace);
      return Left(
        AppError.serverError(message: 'Failed to get leads count'),
      );
    }
  }
}
```

---

## Step 3: Create BLoC Events

Create `lib/features/leads/presentation/bloc/leads_event.dart`:

```dart
import 'package:equatable/equatable.dart';
import '../../../../core/models/lead_model.dart';

abstract class LeadsEvent extends Equatable {
  const LeadsEvent();

  @override
  List<Object?> get props => [];
}

class LoadLeads extends LeadsEvent {
  final String? statusId;
  final String? departmentId;
  final bool refresh;

  const LoadLeads({
    this.statusId,
    this.departmentId,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [statusId, departmentId, refresh];
}

class LoadMoreLeads extends LeadsEvent {
  const LoadMoreLeads();
}

class SearchLeads extends LeadsEvent {
  final String query;

  const SearchLeads(this.query);

  @override
  List<Object> get props => [query];
}

class CreateLead extends LeadsEvent {
  final Lead lead;

  const CreateLead(this.lead);

  @override
  List<Object> get props => [lead];
}

class UpdateLead extends LeadsEvent {
  final Lead lead;

  const UpdateLead(this.lead);

  @override
  List<Object> get props => [lead];
}

class DeleteLead extends LeadsEvent {
  final String leadId;

  const DeleteLead(this.leadId);

  @override
  List<Object> get props => [leadId];
}

class WatchLeadsRealtime extends LeadsEvent {
  final String? statusId;

  const WatchLeadsRealtime({this.statusId});

  @override
  List<Object?> get props => [statusId];
}
```

---

## Step 4: Create BLoC States

Create `lib/features/leads/presentation/bloc/leads_state.dart`:

```dart
import 'package:equatable/equatable.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/models/lead_model.dart';

abstract class LeadsState extends Equatable {
  const LeadsState();

  @override
  List<Object?> get props => [];
}

class LeadsInitial extends LeadsState {}

class LeadsLoading extends LeadsState {}

class LeadsLoaded extends LeadsState {
  final List<Lead> leads;
  final bool hasMore;
  final Map<String, int> countByStatus;

  const LeadsLoaded({
    required this.leads,
    this.hasMore = false,
    this.countByStatus = const {},
  });

  @override
  List<Object> get props => [leads, hasMore, countByStatus];

  LeadsLoaded copyWith({
    List<Lead>? leads,
    bool? hasMore,
    Map<String, int>? countByStatus,
  }) {
    return LeadsLoaded(
      leads: leads ?? this.leads,
      hasMore: hasMore ?? this.hasMore,
      countByStatus: countByStatus ?? this.countByStatus,
    );
  }
}

class LeadsError extends LeadsState {
  final AppError error;

  const LeadsError(this.error);

  @override
  List<Object> get props => [error];
}

class LeadCreated extends LeadsState {
  final Lead lead;

  const LeadCreated(this.lead);

  @override
  List<Object> get props => [lead];
}

class LeadUpdated extends LeadsState {
  final Lead lead;

  const LeadUpdated(this.lead);

  @override
  List<Object> get props => [lead];
}

class LeadDeleted extends LeadsState {
  final String leadId;

  const LeadDeleted(this.leadId);

  @override
  List<Object> get props => [leadId];
}

class LeadsSearching extends LeadsState {}

class LeadsSearchResult extends LeadsState {
  final List<Lead> results;
  final String query;

  const LeadsSearchResult({
    required this.results,
    required this.query,
  });

  @override
  List<Object> get props => [results, query];
}
```

---

## Step 5: Implement BLoC

Create `lib/features/leads/presentation/bloc/leads_bloc.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/services/logger_service.dart';
import '../../domain/repositories/lead_repository.dart';
import 'leads_event.dart';
import 'leads_state.dart';

class LeadsBloc extends Bloc<LeadsEvent, LeadsState> {
  final LeadRepository _leadRepository;
  final PermissionService _permissionService;

  LeadsBloc(
    this._leadRepository,
    this._permissionService,
  ) : super(LeadsInitial()) {
    on<LoadLeads>(_onLoadLeads);
    on<LoadMoreLeads>(_onLoadMoreLeads);
    on<SearchLeads>(_onSearchLeads);
    on<CreateLead>(_onCreateLead);
    on<UpdateLead>(_onUpdateLead);
    on<DeleteLead>(_onDeleteLead);
    on<WatchLeadsRealtime>(_onWatchLeadsRealtime);
  }

  Future<void> _onLoadLeads(
    LoadLeads event,
    Emitter<LeadsState> emit,
  ) async {
    emit(LeadsLoading());

    final companyId = _permissionService.currentUser?.companyId;
    if (companyId == null) {
      emit(const LeadsError(
        AppError.authenticationError(message: 'User not authenticated'),
      ));
      return;
    }

    final result = await _leadRepository.getLeads(
      companyId: companyId,
      statusId: event.statusId,
      departmentId: event.departmentId,
      limit: 20,
    );

    result.fold(
      (error) => emit(LeadsError(error)),
      (leads) async {
        // Get count by status
        final countResult = await _leadRepository.getLeadsCountByStatus(
          companyId,
        );

        final countByStatus = countResult.fold(
          (error) => <String, int>{},
          (count) => count,
        );

        emit(LeadsLoaded(
          leads: leads,
          hasMore: leads.length >= 20,
          countByStatus: countByStatus,
        ));
      },
    );
  }

  Future<void> _onLoadMoreLeads(
    LoadMoreLeads event,
    Emitter<LeadsState> emit,
  ) async {
    if (state is! LeadsLoaded) return;

    final currentState = state as LeadsLoaded;
    if (!currentState.hasMore) return;

    final companyId = _permissionService.currentUser?.companyId;
    if (companyId == null) return;

    final lastLeadId = currentState.leads.lastOrNull?.id;
    if (lastLeadId == null) return;

    final result = await _leadRepository.getLeads(
      companyId: companyId,
      limit: 20,
      lastDocumentId: lastLeadId,
    );

    result.fold(
      (error) => LoggerService.error('Error loading more leads', error),
      (newLeads) {
        emit(currentState.copyWith(
          leads: [...currentState.leads, ...newLeads],
          hasMore: newLeads.length >= 20,
        ));
      },
    );
  }

  Future<void> _onSearchLeads(
    SearchLeads event,
    Emitter<LeadsState> emit,
  ) async {
    if (event.query.isEmpty) {
      add(const LoadLeads());
      return;
    }

    emit(LeadsSearching());

    final companyId = _permissionService.currentUser?.companyId;
    if (companyId == null) {
      emit(const LeadsError(
        AppError.authenticationError(message: 'User not authenticated'),
      ));
      return;
    }

    final result = await _leadRepository.searchLeads(
      companyId: companyId,
      query: event.query,
    );

    result.fold(
      (error) => emit(LeadsError(error)),
      (results) => emit(LeadsSearchResult(
        results: results,
        query: event.query,
      )),
    );
  }

  Future<void> _onCreateLead(
    CreateLead event,
    Emitter<LeadsState> emit,
  ) async {
    if (!_permissionService.hasPermission('create_leads')) {
      emit(const LeadsError(
        AppError.permissionError(message: 'No permission to create leads'),
      ));
      return;
    }

    final result = await _leadRepository.createLead(event.lead);

    result.fold(
      (error) => emit(LeadsError(error)),
      (lead) {
        emit(LeadCreated(lead));
        add(const LoadLeads(refresh: true));
      },
    );
  }

  Future<void> _onUpdateLead(
    UpdateLead event,
    Emitter<LeadsState> emit,
  ) async {
    if (!_permissionService.hasPermission('edit_leads')) {
      emit(const LeadsError(
        AppError.permissionError(message: 'No permission to edit leads'),
      ));
      return;
    }

    final result = await _leadRepository.updateLead(event.lead);

    result.fold(
      (error) => emit(LeadsError(error)),
      (_) {
        emit(LeadUpdated(event.lead));
        add(const LoadLeads(refresh: true));
      },
    );
  }

  Future<void> _onDeleteLead(
    DeleteLead event,
    Emitter<LeadsState> emit,
  ) async {
    if (!_permissionService.hasPermission('delete_leads')) {
      emit(const LeadsError(
        AppError.permissionError(message: 'No permission to delete leads'),
      ));
      return;
    }

    final result = await _leadRepository.deleteLead(event.leadId);

    result.fold(
      (error) => emit(LeadsError(error)),
      (_) {
        emit(LeadDeleted(event.leadId));
        add(const LoadLeads(refresh: true));
      },
    );
  }

  Future<void> _onWatchLeadsRealtime(
    WatchLeadsRealtime event,
    Emitter<LeadsState> emit,
  ) async {
    final companyId = _permissionService.currentUser?.companyId;
    if (companyId == null) {
      emit(const LeadsError(
        AppError.authenticationError(message: 'User not authenticated'),
      ));
      return;
    }

    await emit.forEach(
      _leadRepository.watchLeads(
        companyId: companyId,
        statusId: event.statusId,
      ),
      onData: (result) {
        return result.fold(
          (error) => LeadsError(error),
          (leads) => LeadsLoaded(leads: leads),
        );
      },
    );
  }
}
```

---

## Step 6: Register in Dependency Injection

Update `lib/core/di/injection_container.dart`:

```dart
// Add this after configureDependencies

Future<void> setupLeadsDependencies() async {
  // Repository
  sl.registerLazySingleton<LeadRepository>(
    () => LeadRepositoryImpl(sl<FirebaseFirestore>()),
  );

  // BLoC
  sl.registerFactory<LeadsBloc>(
    () => LeadsBloc(
      sl<LeadRepository>(),
      sl<PermissionService>(),
    ),
  );
}
```

---

## Step 7: Usage in UI

Update `lib/features/leads/presentation/pages/leads_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/leads_bloc.dart';
import '../bloc/leads_event.dart';
import '../bloc/leads_state.dart';

class LeadsPage extends StatelessWidget {
  const LeadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<LeadsBloc>()..add(const LoadLeads()),
      child: const _LeadsView(),
    );
  }
}

class _LeadsView extends StatelessWidget {
  const _LeadsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Open search
            },
          ),
        ],
      ),
      body: BlocBuilder<LeadsBloc, LeadsState>(
        builder: (context, state) {
          if (state is LeadsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is LeadsError) {
            return Center(
              child: Text('Error: ${state.error}'),
            );
          }

          if (state is LeadsLoaded) {
            if (state.leads.isEmpty) {
              return const Center(
                child: Text('No leads found'),
              );
            }

            return ListView.builder(
              itemCount: state.leads.length,
              itemBuilder: (context, index) {
                final lead = state.leads[index];
                return ListTile(
                  title: Text(lead.name),
                  subtitle: Text(lead.phone),
                  trailing: Chip(label: Text(lead.statusId)),
                  onTap: () {
                    // Navigate to detail
                  },
                );
              },
            );
          }

          return const Center(child: Text('Unknown state'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create lead
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

---

## Testing

Create `test/features/leads/data/repositories/lead_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
// ... add your tests

void main() {
  group('LeadRepository', () {
    test('should get leads from Firestore', () async {
      // Arrange
      // Act
      // Assert
    });
  });
}
```

---

## Summary

This example demonstrates the complete flow:

1. ✅ Define repository interface
2. ✅ Implement with Firestore
3. ✅ Create BLoC events & states
4. ✅ Implement BLoC logic
5. ✅ Register dependencies
6. ✅ Use in UI
7. ✅ Test

**Use this pattern for all other features:**

- User management
- Department management
- Status builder
- Form builder
- Analytics

---

**Next**: Implement UserRepository following the same pattern!
