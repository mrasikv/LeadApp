import 'package:freezed_annotation/freezed_annotation.dart';
import '../utils/timestamp_converter.dart';

part 'ticket_model.freezed.dart';
part 'ticket_model.g.dart';

@freezed
class Ticket with _$Ticket {
  const factory Ticket({
    required String id,
    required String companyId,
    required String leadId,
    required String name,
    required String userId, // Owner

    // Deal value
    double? price,
    int? quantity,
    String? currency,

    // Status
    required String status, // won, lost, pending
    @NullableTimestampConverter() DateTime? closedAt,
    String? notes,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    required String createdBy,
  }) = _Ticket;

  factory Ticket.fromJson(Map<String, dynamic> json) => _$TicketFromJson(json);
}
