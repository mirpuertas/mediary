import 'package:flutter/foundation.dart';
import '../utils/app_error.dart';

/// Servicio centralizado de logging de errores.
class ErrorLogger {
  static final ErrorLogger instance = ErrorLogger._();
  ErrorLogger._();

  final List<AppError> _errors = [];
  static const int _maxStoredErrors = 100;

  void log(AppError error) {
    if (kDebugMode) {
      _printError(error);
    }

    _errors.add(error);
    if (_errors.length > _maxStoredErrors) {
      _errors.removeAt(0);
    }
  }

  void logException(
    Object error, {
    StackTrace? stackTrace,
    String? message,
    AppErrorType type = AppErrorType.unknown,
    Map<String, dynamic>? context,
  }) {
    log(
      AppError(
        type: type,
        message: message ?? error.toString(),
        originalError: error,
        stackTrace: stackTrace,
        context: context,
      ),
    );
  }

  void logDatabaseError(
    Object error, {
    StackTrace? stackTrace,
    String? operation,
  }) {
    log(
      AppError.database(
        operation ?? 'Database operation failed',
        error: error,
        stackTrace: stackTrace,
        context: operation != null ? {'operation': operation} : null,
      ),
    );
  }

  void logNotificationError(
    Object error, {
    StackTrace? stackTrace,
    String? action,
  }) {
    log(
      AppError.notification(
        action ?? 'Notification operation failed',
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  void logBackupError(
    Object error, {
    StackTrace? stackTrace,
    String? operation,
  }) {
    log(
      AppError.backup(
        operation ?? 'Backup operation failed',
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  void logExportError(
    Object error, {
    StackTrace? stackTrace,
    String? exportType,
  }) {
    log(
      AppError.export(
        'Export failed',
        error: error,
        stackTrace: stackTrace,
        exportType: exportType,
      ),
    );
  }

  List<AppError> get recentErrors => List.unmodifiable(_errors);

  int get errorCount => _errors.length;

  List<AppError> errorsByType(AppErrorType type) {
    return _errors.where((e) => e.type == type).toList();
  }

  List<AppError> errorsInLastHours(int hours) {
    final cutoff = DateTime.now().subtract(Duration(hours: hours));
    return _errors.where((e) => e.timestamp.isAfter(cutoff)).toList();
  }

  void clear() => _errors.clear();

  List<Map<String, dynamic>> exportErrors() {
    return _errors.map((e) => e.toMap()).toList();
  }

  Map<AppErrorType, int> get errorSummary {
    final summary = <AppErrorType, int>{};
    for (final error in _errors) {
      summary[error.type] = (summary[error.type] ?? 0) + 1;
    }
    return summary;
  }

  void _printError(AppError error) {
    final icon = switch (error.type) {
      AppErrorType.database => '🗄️',
      AppErrorType.notification => '🔔',
      AppErrorType.permission => '🔒',
      AppErrorType.backup => '💾',
      AppErrorType.export => '📤',
      AppErrorType.validation => '⚠️',
      AppErrorType.network => '🌐',
      AppErrorType.unknown => '❌',
    };

    debugPrint('$icon ${error.toLogString()}');
    if (error.originalError != null) {
      debugPrint('   Caused by: ${error.originalError}');
    }
    if (error.stackTrace != null && kDebugMode) {
      debugPrint(
        '   Stack: ${error.stackTrace.toString().split('\n').take(3).join('\n   ')}',
      );
    }
  }
}
