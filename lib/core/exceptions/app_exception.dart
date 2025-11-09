class AppException implements Exception {
  AppException(this.message, {this.cause, StackTrace? stackTrace})
      : stackTrace = stackTrace ?? StackTrace.current;

  final String message;
  final Object? cause;
  final StackTrace stackTrace;

  @override
  String toString() => 'AppException(message: $message, cause: $cause)';
}
