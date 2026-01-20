class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, [this.code]);

  @override
  String toString() => message;
}

class ServerException extends AppException {
  ServerException([String message = 'Server error occurred', String? code])
      : super(message, code);
}

class NetworkException extends AppException {
  NetworkException([String message = 'No internet connection'])
      : super(message);
}

class AuthenticationException extends AppException {
  AuthenticationException([String message = 'Authentication failed', String? code])
      : super(message, code);
}

class PermissionException extends AppException {
  PermissionException([String message = 'Permission denied'])
      : super(message);
}

class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;
  
  ValidationException(String message, [this.fieldErrors]) : super(message);
}

class NotFoundException extends AppException {
  NotFoundException([String message = 'Resource not found'])
      : super(message);
}
