/// Tipos de error de la aplicación.
enum AppErrorType {
  database,
  notification,
  permission,
  backup,
  export,
  validation,
  network,
  unknown,
}

/// Error con contexto para logging y debugging.
class AppError implements Exception {
  final AppErrorType type;
  final String message;
  final String? userMessage;
  final Object? originalError;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;
  final DateTime timestamp;

  AppError({
    required this.type,
    required this.message,
    this.userMessage,
    this.originalError,
    this.stackTrace,
    this.context,
  }) : timestamp = DateTime.now();

  /// Factory para errores de base de datos.
  factory AppError.database(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      type: AppErrorType.database,
      message: message,
      originalError: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Factory para errores de notificaciones.
  factory AppError.notification(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    return AppError(
      type: AppErrorType.notification,
      message: message,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Factory para errores de permisos.
  factory AppError.permission(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    return AppError(
      type: AppErrorType.permission,
      message: message,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Factory para errores de backup.
  factory AppError.backup(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    return AppError(
      type: AppErrorType.backup,
      message: message,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Factory para errores de export.
  factory AppError.export(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? exportType,
  }) {
    return AppError(
      type: AppErrorType.export,
      message: message,
      originalError: error,
      stackTrace: stackTrace,
      context: exportType != null ? {'exportType': exportType} : null,
    );
  }

  /// Factory para errores genéricos/desconocidos.
  factory AppError.unknown(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    return AppError(
      type: AppErrorType.unknown,
      message: message,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('AppError(${type.name}): $message');
    if (originalError != null) {
      buffer.write('\n  Caused by: $originalError');
    }
    if (context != null && context!.isNotEmpty) {
      buffer.write('\n  Context: $context');
    }
    return buffer.toString();
  }

  /// Formato compacto para logs.
  String toLogString() {
    return '[${timestamp.toIso8601String()}] ${type.name.toUpperCase()}: $message';
  }

  /// Convierte a Map para serialización (útil para export de logs).
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'message': message,
      'userMessage': userMessage,
      'originalError': originalError?.toString(),
      'context': context,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
