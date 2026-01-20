import 'package:freezed_annotation/freezed_annotation.dart';
import '../utils/timestamp_converter.dart';

part 'activity_model.freezed.dart';
part 'activity_model.g.dart';

@freezed
class Activity with _$Activity {
  const factory Activity({
    required String id,
    required String companyId,
    required String leadId,
    required String userId,
    required String activityType, // status_change, call, note, etc.
    required String description,

    // Additional metadata
    Map<String, dynamic>? metadata, // Extra data like old/new status

    @TimestampConverter() required DateTime createdAt,
  }) = _Activity;

  factory Activity.fromJson(Map<String, dynamic> json) =>
      _$ActivityFromJson(json);
}
