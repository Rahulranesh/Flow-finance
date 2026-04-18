import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Log levels
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  fatal,
}

/// Log entry
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final dynamic data;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.data,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'level': level.name.toUpperCase(),
        'tag': tag,
        'message': message,
        'data': data?.toString(),
      };

  @override
  String toString() {
    final time = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    return '[$time] ${level.name.toUpperCase()}/$tag: $message';
  }
}

/// Logger service for app-wide logging
class Logger {
  static final List<LogEntry> _logs = [];
  static bool _isFileLoggingEnabled = true;
  static LogLevel _minLevel = LogLevel.debug;
  static const int _maxLogCount = 1000;

  /// Initialize logger
  static void initialize({
    bool fileLogging = true,
    LogLevel minLevel = LogLevel.debug,
  }) {
    _isFileLoggingEnabled = fileLogging;
    _minLevel = minLevel;
    info('Logger', 'Logger initialized');
  }

  /// Log verbose message
  static void verbose(String tag, String message, {dynamic data}) {
    _log(LogLevel.verbose, tag, message, data: data);
  }

  /// Log debug message
  static void debug(String tag, String message, {dynamic data}) {
    _log(LogLevel.debug, tag, message, data: data);
  }

  /// Log info message
  static void info(String tag, String message, {dynamic data}) {
    _log(LogLevel.info, tag, message, data: data);
  }

  /// Log warning message
  static void warning(String tag, String message, {dynamic data}) {
    _log(LogLevel.warning, tag, message, data: data);
  }

  /// Log error message
  static void error(
    String tag,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    dynamic data,
  }) {
    _log(
      LogLevel.error,
      tag,
      message,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log fatal message
  static void fatal(
    String tag,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    dynamic data,
  }) {
    _log(
      LogLevel.fatal,
      tag,
      message,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void _log(
    LogLevel level,
    String tag,
    String message, {
    dynamic data,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    // Check minimum level
    if (level.index < _minLevel.index) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      data: data ?? error,
      stackTrace: stackTrace,
    );

    // Add to in-memory logs
    _logs.add(entry);
    if (_logs.length > _maxLogCount) {
      _logs.removeAt(0);
    }

    // Console output
    _outputToConsole(entry);

    // File output
    if (_isFileLoggingEnabled) {
      _outputToFile(entry);
    }
  }

  static void _outputToConsole(LogEntry entry) {
    final emoji = _getEmoji(entry.level);
    developer.log(
      '$emoji [${entry.tag}] ${entry.message}',
      name: entry.tag,
      error: entry.data,
      stackTrace: entry.stackTrace,
      level: _getLogLevelValue(entry.level),
    );
  }

  static void _outputToFile(LogEntry entry) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/app_logs.txt');

      final line = '${entry.toString()}\n';
      await file.writeAsString(line, mode: FileMode.append);
    } catch (e) {
      // Silently fail for file logging
    }
  }

  static String _getEmoji(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return '💬';
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.fatal:
        return '💥';
    }
  }

  static int _getLogLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return 500;
      case LogLevel.debug:
        return 700;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.fatal:
        return 1200;
    }
  }

  /// Get all logs
  static List<LogEntry> getLogs() => List.unmodifiable(_logs);

  /// Get logs by level
  static List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }

  /// Get logs by tag
  static List<LogEntry> getLogsByTag(String tag) {
    return _logs.where((log) => log.tag == tag).toList();
  }

  /// Get recent logs
  static List<LogEntry> getRecentLogs({int count = 50}) {
    return _logs.reversed.take(count).toList();
  }

  /// Clear all logs
  static void clearLogs() {
    _logs.clear();
    info('Logger', 'Logs cleared');
  }

  /// Export logs to JSON
  static String exportToJson() {
    final data = _logs.map((e) => e.toJson()).toList();
    return jsonEncode({'logs': data, 'exportedAt': DateTime.now().toIso8601String()});
  }

  /// Export logs to text
  static String exportToText() {
    return _logs.map((e) => e.toString()).join('\n');
  }

  /// Save logs to file
  static Future<String> saveLogsToFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/logs_$timestamp.txt');

    final content = exportToText();
    await file.writeAsString(content);

    return file.path;
  }

  /// Get log file path
  static Future<String?> getLogFilePath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/app_logs.txt');
      if (await file.exists()) {
        return file.path;
      }
    } catch (e) {
      error('Logger', 'Failed to get log file path', error: e);
    }
    return null;
  }

  /// Log performance metric
  static void logPerformance(String operation, Duration duration, {Map<String, dynamic>? metadata}) {
    info(
      'Performance',
      '$operation completed in ${duration.inMilliseconds}ms',
      data: metadata,
    );
  }

  /// Log navigation event
  static void logNavigation(String from, String to, {Map<String, dynamic>? params}) {
    info(
      'Navigation',
      '$from → $to',
      data: params,
    );
  }

  /// Log user action
  static void logUserAction(String action, {Map<String, dynamic>? params}) {
    info(
      'UserAction',
      action,
      data: params,
    );
  }

  /// Log database operation
  static void logDatabase(String operation, String table, {dynamic data, Duration? duration}) {
    final message = duration != null
        ? '$operation on $table (${duration.inMilliseconds}ms)'
        : '$operation on $table';
    debug('Database', message, data: data);
  }
}

/// Mixin for adding logging to classes
mixin LoggerMixin {
  String get logTag => runtimeType.toString();

  void logVerbose(String message, {dynamic data}) =>
      Logger.verbose(logTag, message, data: data);

  void logDebug(String message, {dynamic data}) =>
      Logger.debug(logTag, message, data: data);

  void logInfo(String message, {dynamic data}) =>
      Logger.info(logTag, message, data: data);

  void logWarning(String message, {dynamic data}) =>
      Logger.warning(logTag, message, data: data);

  void logError(String message, {dynamic error, StackTrace? stackTrace, dynamic data}) =>
      Logger.error(logTag, message, error: error, stackTrace: stackTrace, data: data);
}
