import 'package:freezed_annotation/freezed_annotation.dart';
import '../utils/timestamp_converter.dart';

part 'target_model.freezed.dart';
part 'target_model.g.dart';

@freezed
class Target with _$Target {
  const factory Target({
    required String id,
    required String companyId,
    String? departmentId, // null = company-wide
    String? userId, // null = department/company target
    required String targetType, // price, quantity, hybrid
    required String month, // Format: YYYY-MM

    // Target values
    double? targetPrice,
    int? targetQuantity,

    // Achievement tracking (calculated)
    @Default(0.0) double achievedPrice,
    @Default(0) int achievedQuantity,
    @Default(0.0) double remainingPrice,
    @Default(0) int remainingQuantity,
    @Default(0.0) double percentageComplete,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    String? createdBy,
  }) = _Target;

  factory Target.fromJson(Map<String, dynamic> json) => _$TargetFromJson(json);
}
