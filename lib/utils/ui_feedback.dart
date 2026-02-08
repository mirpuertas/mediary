import 'package:flutter/material.dart';
import '../ui/app_theme_tokens.dart';
import '../services/error_logger.dart';
import 'app_error.dart';

/// Tipos de feedback visual para el usuario.
enum FeedbackType { success, error, warning, info }

/// Helper centralizado para mostrar SnackBars consistentes en toda la app.
class UIFeedback {
  UIFeedback._();

  /// Muestra un SnackBar con estilo consistente.
  static void show(
    BuildContext context, {
    required String message,
    FeedbackType type = FeedbackType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colors = context.statusColors;
    final config = _getConfig(colors, type);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(config.icon, color: config.foreground, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: config.foreground),
                ),
              ),
            ],
          ),
          backgroundColor: config.background,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          action: actionLabel != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: config.foreground,
                  onPressed: onAction ?? () {},
                )
              : null,
        ),
      );
  }

  /// Muestra un mensaje de error.
  static void showError(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: FeedbackType.error,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Muestra un mensaje de éxito.
  static void showSuccess(BuildContext context, String message) {
    show(
      context,
      message: message,
      type: FeedbackType.success,
      duration: const Duration(seconds: 2),
    );
  }

  /// Muestra una advertencia.
  static void showWarning(BuildContext context, String message) {
    show(context, message: message, type: FeedbackType.warning);
  }

  /// Muestra información.
  static void showInfo(BuildContext context, String message) {
    show(context, message: message, type: FeedbackType.info);
  }

  /// Error con logging y opción de reintentar.
  static void showErrorWithRetry(
    BuildContext context, {
    required String message,
    required Object error,
    StackTrace? stackTrace,
    AppErrorType errorType = AppErrorType.unknown,
    String? retryLabel,
    VoidCallback? onRetry,
  }) {
    // Log centralizado
    ErrorLogger.instance.logException(
      error,
      stackTrace: stackTrace,
      message: message,
      type: errorType,
    );

    show(
      context,
      message: message,
      type: FeedbackType.error,
      duration: const Duration(seconds: 5),
      actionLabel: retryLabel,
      onAction: onRetry,
    );
  }

  static _FeedbackConfig _getConfig(AppStatusColors colors, FeedbackType type) {
    return switch (type) {
      FeedbackType.success => _FeedbackConfig(
        background: colors.success,
        foreground: colors.onSuccess,
        icon: Icons.check_circle_outline,
      ),
      FeedbackType.error => _FeedbackConfig(
        background: colors.danger,
        foreground: colors.onDanger,
        icon: Icons.error_outline,
      ),
      FeedbackType.warning => _FeedbackConfig(
        background: colors.warning,
        foreground: colors.onWarning,
        icon: Icons.warning_amber_outlined,
      ),
      FeedbackType.info => _FeedbackConfig(
        background: colors.info,
        foreground: colors.onInfo,
        icon: Icons.info_outline,
      ),
    };
  }
}

class _FeedbackConfig {
  final Color background;
  final Color foreground;
  final IconData icon;

  const _FeedbackConfig({
    required this.background,
    required this.foreground,
    required this.icon,
  });
}
