import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? component;
  final Map<String, dynamic>? metadata;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.component,
    this.metadata,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      'component': component,
      'metadata': metadata,
      'stackTrace': stackTrace?.toString(),
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.parse(json['timestamp']),
      level: LogLevel.values.firstWhere(
        (level) => level.name == json['level'],
        orElse: () => LogLevel.info,
      ),
      message: json['message'],
      component: json['component'],
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      stackTrace: json['stackTrace'] != null 
          ? StackTrace.fromString(json['stackTrace'])
          : null,
    );
  }

  String get formattedMessage {
    final time = timestamp.toLocal().toString().substring(11, 19);
    final levelStr = level.name.toUpperCase().padRight(8);
    final componentStr = component != null ? '[$component] ' : '';
    return '$time $levelStr $componentStr$message';
  }
}

class ErrorLoggingService {
  static const String _logsKey = 'error_logs';
  static const int _maxLogs = 1000; // Keep last 1000 log entries
  static const int _maxLogAge = 7; // Keep logs for 7 days
  
  final List<LogEntry> _logs = [];
  final StreamController<LogEntry> _logController = 
      StreamController<LogEntry>.broadcast();
  
  static final ErrorLoggingService _instance = ErrorLoggingService._internal();
  factory ErrorLoggingService() => _instance;
  ErrorLoggingService._internal();

  Stream<LogEntry> get logStream => _logController.stream;
  List<LogEntry> get logs => List.unmodifiable(_logs);

  /// Initialize the logging service
  Future<void> initialize() async {
    await _loadLogs();
    _startCleanupTimer();
  }

  /// Log a message with specified level
  Future<void> log(
    LogLevel level,
    String message, {
    String? component,
    Map<String, dynamic>? metadata,
    StackTrace? stackTrace,
  }) async {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      component: component,
      metadata: metadata,
      stackTrace: stackTrace,
    );

    _logs.add(entry);
    _logController.add(entry);

    // Keep only the most recent logs
    if (_logs.length > _maxLogs) {
      _logs.removeRange(0, _logs.length - _maxLogs);
    }

    // Save logs periodically
    if (_logs.length % 10 == 0) {
      await _saveLogs();
    }

    // Print to console for debugging
    print(entry.formattedMessage);
  }

  /// Log debug message
  Future<void> debug(String message, {String? component, Map<String, dynamic>? metadata}) {
    return log(LogLevel.debug, message, component: component, metadata: metadata);
  }

  /// Log info message
  Future<void> info(String message, {String? component, Map<String, dynamic>? metadata}) {
    return log(LogLevel.info, message, component: component, metadata: metadata);
  }

  /// Log warning message
  Future<void> warning(String message, {String? component, Map<String, dynamic>? metadata}) {
    return log(LogLevel.warning, message, component: component, metadata: metadata);
  }

  /// Log error message
  Future<void> error(
    String message, {
    String? component,
    Map<String, dynamic>? metadata,
    StackTrace? stackTrace,
  }) {
    return log(LogLevel.error, message, 
        component: component, metadata: metadata, stackTrace: stackTrace);
  }

  /// Log critical error
  Future<void> critical(
    String message, {
    String? component,
    Map<String, dynamic>? metadata,
    StackTrace? stackTrace,
  }) {
    return log(LogLevel.critical, message,
        component: component, metadata: metadata, stackTrace: stackTrace);
  }

  /// Log HTTP request/response
  Future<void> logHttpRequest({
    required String method,
    required String url,
    int? statusCode,
    String? responseBody,
    Duration? duration,
    String? error,
  }) {
    final metadata = <String, dynamic>{
      'method': method,
      'url': url,
      if (statusCode != null) 'statusCode': statusCode,
      if (duration != null) 'duration': duration.inMilliseconds,
      if (error != null) 'error': error,
    };

    final level = error != null || (statusCode != null && statusCode >= 400)
        ? LogLevel.error
        : LogLevel.info;

    final message = error != null
        ? 'HTTP Request failed: $method $url - $error'
        : 'HTTP Request: $method $url - ${statusCode ?? 'pending'}';

    return log(level, message, component: 'HTTP', metadata: metadata);
  }

  /// Log gRPC request/response
  Future<void> logGrpcRequest({
    required String method,
    required String host,
    required int port,
    Duration? duration,
    String? error,
  }) {
    final metadata = <String, dynamic>{
      'method': method,
      'host': host,
      'port': port,
      if (duration != null) 'duration': duration.inMilliseconds,
      if (error != null) 'error': error,
    };

    final level = error != null ? LogLevel.error : LogLevel.info;
    final message = error != null
        ? 'gRPC Request failed: $method $host:$port - $error'
        : 'gRPC Request: $method $host:$port';

    return log(level, message, component: 'gRPC', metadata: metadata);
  }

  /// Log server discovery events
  Future<void> logDiscovery({
    required String event,
    String? serverId,
    String? serverHost,
    int? serverPort,
    Map<String, dynamic>? metadata,
  }) {
    final discoveryMetadata = <String, dynamic>{
      'event': event,
      if (serverId != null) 'serverId': serverId,
      if (serverHost != null) 'serverHost': serverHost,
      if (serverPort != null) 'serverPort': serverPort,
      ...?metadata,
    };

    return log(LogLevel.info, 'Discovery: $event', 
        component: 'Discovery', metadata: discoveryMetadata);
  }

  /// Get logs filtered by level
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }

  /// Get logs filtered by component
  List<LogEntry> getLogsByComponent(String component) {
    return _logs.where((log) => log.component == component).toList();
  }

  /// Get recent logs (last N entries)
  List<LogEntry> getRecentLogs(int count) {
    final start = _logs.length > count ? _logs.length - count : 0;
    return _logs.sublist(start);
  }

  /// Export logs as JSON
  String exportLogsAsJson() {
    final logsJson = _logs.map((log) => log.toJson()).toList();
    return json.encode(logsJson);
  }

  /// Export logs as text
  String exportLogsAsText() {
    return _logs.map((log) => log.formattedMessage).join('\n');
  }

  /// Clear all logs
  Future<void> clearLogs() async {
    _logs.clear();
    await _saveLogs();
  }

  /// Load logs from storage
  Future<void> _loadLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getString(_logsKey);
      
      if (logsJson != null) {
        final List<dynamic> logsList = json.decode(logsJson);
        _logs.clear();
        _logs.addAll(logsList.map((json) => LogEntry.fromJson(json)));
        
        // Clean up old logs
        await _cleanupOldLogs();
      }
    } catch (e) {
      print('Error loading logs: $e');
    }
  }

  /// Save logs to storage
  Future<void> _saveLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = json.encode(_logs.map((log) => log.toJson()).toList());
      await prefs.setString(_logsKey, logsJson);
    } catch (e) {
      print('Error saving logs: $e');
    }
  }

  /// Clean up old logs
  Future<void> _cleanupOldLogs() async {
    final cutoffDate = DateTime.now().subtract(Duration(days: _maxLogAge));
    _logs.removeWhere((log) => log.timestamp.isBefore(cutoffDate));
    await _saveLogs();
  }

  /// Start cleanup timer
  void _startCleanupTimer() {
    Timer.periodic(Duration(hours: 1), (_) => _cleanupOldLogs());
  }

  /// Dispose resources
  void dispose() {
    _saveLogs();
    _logController.close();
  }
}
