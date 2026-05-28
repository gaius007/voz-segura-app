sealed class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;
}

class AuthException extends AppException {
  AuthException(super.message);
}

class DatabaseException extends AppException {
  DatabaseException(super.message);
}

class NetworkException extends AppException {
  NetworkException(super.message);
}

class UnknownException extends AppException {
  UnknownException([super.message = 'Ocorreu um erro inesperado']);
}
