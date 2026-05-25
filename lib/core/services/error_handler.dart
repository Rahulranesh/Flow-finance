import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// Custom exception for app-specific errors
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException[$code]: $message';
}

/// Error types for categorization
enum ErrorType {
  network,
  database,
  validation,
  authentication,
  permission,
  unknown,
}

/// Error information for UI display
class ErrorInfo {
  final String title;
  final String message;
  final ErrorType type;
  final String? actionLabel;
  final VoidCallback? onAction;

  ErrorInfo({
    required this.title,
    required this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
  });
}

/// Global error handler
class ErrorHandler {
  static final List<ErrorLog> _errorLogs = [];
  static final _errorController = StreamController<ErrorInfo>.broadcast();

  static Stream<ErrorInfo> get errorStream => _errorController.stream;

  /// Handle an error and return user-friendly info
  static ErrorInfo handleError(dynamic error, {StackTrace? stackTrace}) {
    final errorInfo = _mapToErrorInfo(error);
    _logError(error, stackTrace, errorInfo);
    _errorController.add(errorInfo);
    return errorInfo;
  }

  /// Handle error silently (log only)
  static void handleSilent(dynamic error, {StackTrace? stackTrace}) {
    final errorInfo = _mapToErrorInfo(error);
    _logError(error, stackTrace, errorInfo);
  }

  /// Map various error types to ErrorInfo
  static ErrorInfo _mapToErrorInfo(dynamic error) {
    if (error is AppException) {
      return ErrorInfo(
        title: 'Error'.tr(),
        message: error.message,
        type: _getErrorTypeFromCode(error.code),
      );
    }

    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socket') ||
        errorString.contains('connection') ||
        errorString.contains('network')) {
      return ErrorInfo(
        title: 'Network Error'.tr(),
        message: 'Please check your internet connection and try again.'.tr(),
        type: ErrorType.network,
        actionLabel: 'Retry'.tr(),
      );
    }

    // Database errors
    if (errorString.contains('database') ||
        errorString.contains('sql') ||
        errorString.contains('drift')) {
      return ErrorInfo(
        title: 'Database Error'.tr(),
        message: 'Failed to access local data. Please restart the app.'.tr(),
        type: ErrorType.database,
      );
    }

    // Validation errors
    if (errorString.contains('validation') ||
        errorString.contains('invalid') ||
        errorString.contains('required')) {
      return ErrorInfo(
        title: 'Validation Error'.tr(),
        message: 'Please check your input and try again.'.tr(),
        type: ErrorType.validation,
      );
    }

    // Permission errors
    if (errorString.contains('permission') ||
        errorString.contains('denied') ||
        errorString.contains('access')) {
      return ErrorInfo(
        title: 'Permission Required'.tr(),
        message: 'This feature requires additional permissions.'.tr(),
        type: ErrorType.permission,
        actionLabel: 'Open Settings'.tr(),
      );
    }

    // Default unknown error
    return ErrorInfo(
      title: 'Something Went Wrong'.tr(),
      message: 'An unexpected error occurred. Please try again.'.tr(),
      type: ErrorType.unknown,
    );
  }

  static ErrorType _getErrorTypeFromCode(String? code) {
    switch (code) {
      case 'network':
        return ErrorType.network;
      case 'database':
        return ErrorType.database;
      case 'validation':
        return ErrorType.validation;
      case 'auth':
        return ErrorType.authentication;
      case 'permission':
        return ErrorType.permission;
      default:
        return ErrorType.unknown;
    }
  }

  static void _logError(
    dynamic error,
    StackTrace? stackTrace,
    ErrorInfo errorInfo,
  ) {
    _errorLogs.add(ErrorLog(
      timestamp: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
      errorInfo: errorInfo,
    ));

    // Keep only last 100 errors
    if (_errorLogs.length > 100) {
      _errorLogs.removeAt(0);
    }

    // Print to console in debug mode
    assert(() {
      print('ERROR [${errorInfo.type}]: ${errorInfo.message}');
      if (stackTrace != null) {
        print(stackTrace);
      }
      return true;
    }());
  }

  /// Get recent error logs
  static List<ErrorLog> getRecentErrors({int count = 10}) {
    return _errorLogs.reversed.take(count).toList();
  }

  /// Clear error logs
  static void clearLogs() {
    _errorLogs.clear();
  }

  /// Wrap a future with error handling
  static Future<T?> runWithHandling<T>(
    Future<T> Function() operation, {
    void Function(ErrorInfo)? onError,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      final errorInfo = handleError(e, stackTrace: stackTrace);
      onError?.call(errorInfo);
      return null;
    }
  }

  /// Dispose resources
  static void dispose() {
    _errorController.close();
  }
}

/// Error log entry
class ErrorLog {
  final DateTime timestamp;
  final dynamic error;
  final StackTrace? stackTrace;
  final ErrorInfo errorInfo;

  ErrorLog({
    required this.timestamp,
    required this.error,
    this.stackTrace,
    required this.errorInfo,
  });
}

/// Widget to display error information
class ErrorDisplay extends StatelessWidget {
  final ErrorInfo error;
  final VoidCallback? onDismiss;

  const ErrorDisplay({
    super.key,
    required this.error,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIcon(),
                color: _getIconColor(context),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  error.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onDismiss,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            error.message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (error.actionLabel != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: error.onAction,
                child: Text(error.actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    switch (error.type) {
      case ErrorType.network:
        return Colors.orange.withValues(alpha: 0.1);
      case ErrorType.database:
      case ErrorType.unknown:
        return Colors.red.withValues(alpha: 0.1);
      case ErrorType.validation:
        return Colors.yellow.withValues(alpha: 0.1);
      case ErrorType.authentication:
      case ErrorType.permission:
        return Colors.blue.withValues(alpha: 0.1);
    }
  }

  Color _getBorderColor(BuildContext context) {
    switch (error.type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.database:
      case ErrorType.unknown:
        return Colors.red;
      case ErrorType.validation:
        return Colors.yellow.shade700;
      case ErrorType.authentication:
      case ErrorType.permission:
        return Colors.blue;
    }
  }

  Color _getIconColor(BuildContext context) {
    switch (error.type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.database:
      case ErrorType.unknown:
        return Colors.red;
      case ErrorType.validation:
        return Colors.yellow.shade700;
      case ErrorType.authentication:
      case ErrorType.permission:
        return Colors.blue;
    }
  }

  IconData _getIcon() {
    switch (error.type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.database:
        return Icons.storage;
      case ErrorType.validation:
        return Icons.warning_amber;
      case ErrorType.authentication:
        return Icons.lock;
      case ErrorType.permission:
        return Icons.security;
      case ErrorType.unknown:
        return Icons.error_outline;
    }
  }
}
