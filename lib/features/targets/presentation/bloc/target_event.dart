import 'package:equatable/equatable.dart';
import '../../../../core/models/target_model.dart';

abstract class TargetEvent extends Equatable {
  const TargetEvent();

  @override
  List<Object?> get props => [];
}

class LoadTargetsEvent extends TargetEvent {
  final String companyId;

  const LoadTargetsEvent(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class LoadTargetEvent extends TargetEvent {
  final String targetId;

  const LoadTargetEvent(this.targetId);

  @override
  List<Object> get props => [targetId];
}

class LoadUserTargetsEvent extends TargetEvent {
  final String companyId;
  final String userId;

  const LoadUserTargetsEvent(this.companyId, this.userId);

  @override
  List<Object> get props => [companyId, userId];
}

class LoadDepartmentTargetsEvent extends TargetEvent {
  final String companyId;
  final String departmentId;

  const LoadDepartmentTargetsEvent(this.companyId, this.departmentId);

  @override
  List<Object> get props => [companyId, departmentId];
}

class CreateTargetEvent extends TargetEvent {
  final Target target;

  const CreateTargetEvent(this.target);

  @override
  List<Object> get props => [target];
}

class UpdateTargetEvent extends TargetEvent {
  final Target target;

  const UpdateTargetEvent(this.target);

  @override
  List<Object> get props => [target];
}

class DeleteTargetEvent extends TargetEvent {
  final String targetId;

  const DeleteTargetEvent(this.targetId);

  @override
  List<Object> get props => [targetId];
}

class UpdateTargetProgressEvent extends TargetEvent {
  final String targetId;
  final double achievedPrice;
  final int achievedQuantity;

  const UpdateTargetProgressEvent({
    required this.targetId,
    required this.achievedPrice,
    required this.achievedQuantity,
  });

  @override
  List<Object> get props => [targetId, achievedPrice, achievedQuantity];
}

class WatchTargetsEvent extends TargetEvent {
  final String companyId;

  const WatchTargetsEvent(this.companyId);

  @override
  List<Object> get props => [companyId];
}
