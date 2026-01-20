import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_error.freezed.dart';

@freezed
class AppError with _$AppError {
  const factory AppError.serverError({
    required String message,
    String? code,
  }) = ServerError;

  const factory AppError.networkError({
    @Default('No internet connection') String message,
  }) = NetworkError;

  const factory AppError.authenticationError({
    required String message,
    String? code,
  }) = AuthenticationError;

  const factory AppError.permissionError({
    @Default('You do not have permission to perform this action') String message,
  }) = PermissionError;

  const factory AppError.validationError({
    required String message,
    Map<String, String>? fieldErrors,
  }) = ValidationError;

  const factory AppError.notFoundError({
    @Default('Resource not found') String message,
  }) = NotFoundError;

  const factory AppError.unknownError({
    @Default('An unknown error occurred') String message,
  }) = UnknownError;
}
