import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../services/error_logging_service.dart';

class ErrorLogsScreen extends StatefulWidget {
  const ErrorLogsScreen({super.key});

  @override
  State<ErrorLogsScreen> createState() => _ErrorLogsScreenState();
}

class _ErrorLogsScreenState extends State<ErrorLogsScreen> {
  final ErrorLoggingService _loggingService = ErrorLoggingService();
  LogLevel _selectedLevel = LogLevel.info;
  String? _selectedComponent;
  bool _autoScroll = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Logs'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: _onFilterChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Levels'),
              ),
              const PopupMenuItem(
                value: 'critical',
                child: Text('Critical Only'),
              ),
              const PopupMenuItem(
                value: 'error',
                child: Text('Errors & Critical'),
              ),
              const PopupMenuItem(
                value: 'warning',
                child: Text('Warnings & Above'),
              ),
              const PopupMenuItem(
                value: 'info',
                child: Text('Info & Above'),
              ),
            ],
          ),
          IconButton(
            onPressed: _exportLogs,
            icon: const Icon(MdiIcons.download),
            tooltip: 'Export Logs',
          ),
          IconButton(
            onPressed: _clearLogs,
            icon: const Icon(MdiIcons.delete),
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<LogLevel>(
                    value: _selectedLevel,
                    decoration: const InputDecoration(
                      labelText: 'Log Level',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: LogLevel.values.map((level) {
                      return DropdownMenuItem(
                        value: level,
                        child: Row(
                          children: [
                            _getLevelIcon(level),
                            const SizedBox(width: 8),
                            Text(level.name.toUpperCase()),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (level) {
                      setState(() {
                        _selectedLevel = level!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedComponent,
                    decoration: const InputDecoration(
                      labelText: 'Component',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Components'),
                      ),
                      ..._getUniqueComponents().map((component) {
                        return DropdownMenuItem(
                          value: component,
                          child: Text(component),
                        );
                      }),
                    ],
                    onChanged: (component) {
                      setState(() {
                        _selectedComponent = component;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _autoScroll = !_autoScroll;
                    });
                  },
                  icon: Icon(
                    _autoScroll ? MdiIcons.autoFix : MdiIcons.autoFixOff,
                    color: _autoScroll ? Colors.green : Colors.grey,
                  ),
                  tooltip: _autoScroll ? 'Auto-scroll enabled' : 'Auto-scroll disabled',
                ),
              ],
            ),
          ),
          
          // Logs list
          Expanded(
            child: StreamBuilder<List<LogEntry>>(
              stream: _loggingService.logStream.map((_) => _getFilteredLogs()),
              initialData: _getFilteredLogs(),
              builder: (context, snapshot) {
                final logs = snapshot.data ?? [];
                
                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          MdiIcons.fileDocumentOutline,
                          size: 80,
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No logs found',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Logs will appear here as the app runs',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _buildLogCard(log);
                  },
                );
              },
            ),
          ),
          
          // Log stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', _loggingService.logs.length.toString()),
                _buildStatItem('Errors', _loggingService.getLogsByLevel(LogLevel.error).length.toString()),
                _buildStatItem('Warnings', _loggingService.getLogsByLevel(LogLevel.warning).length.toString()),
                _buildStatItem('Critical', _loggingService.getLogsByLevel(LogLevel.critical).length.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(LogEntry log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: _getLevelIcon(log.level),
        title: Text(
          log.message,
          style: TextStyle(
            fontWeight: log.level == LogLevel.error || log.level == LogLevel.critical
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${log.timestamp.toLocal().toString().substring(11, 19)} '
              '${log.component != null ? '[${log.component}] ' : ''}'
              '${log.level.name.toUpperCase()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (log.metadata != null && log.metadata!.isNotEmpty)
              Text(
                'Metadata: ${log.metadata!.toString()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
          ],
        ),
        children: [
          if (log.stackTrace != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stack Trace:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SelectableText(
                      log.stackTrace.toString(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (log.metadata != null && log.metadata!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Metadata:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SelectableText(
                      log.metadata.toString(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Icon _getLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return const Icon(MdiIcons.bug, color: Colors.grey, size: 16);
      case LogLevel.info:
        return const Icon(MdiIcons.information, color: Colors.blue, size: 16);
      case LogLevel.warning:
        return const Icon(MdiIcons.alert, color: Colors.orange, size: 16);
      case LogLevel.error:
        return const Icon(MdiIcons.alertCircle, color: Colors.red, size: 16);
      case LogLevel.critical:
        return const Icon(MdiIcons.alertOctagon, color: Colors.red, size: 16);
    }
  }

  List<LogEntry> _getFilteredLogs() {
    var logs = _loggingService.logs;

    // Filter by level
    if (_selectedLevel != LogLevel.debug) {
      final levelIndex = LogLevel.values.indexOf(_selectedLevel);
      logs = logs.where((log) {
        final logLevelIndex = LogLevel.values.indexOf(log.level);
        return logLevelIndex >= levelIndex;
      }).toList();
    }

    // Filter by component
    if (_selectedComponent != null) {
      logs = logs.where((log) => log.component == _selectedComponent).toList();
    }

    return logs.reversed.toList(); // Show newest first
  }

  Set<String> _getUniqueComponents() {
    return _loggingService.logs
        .where((log) => log.component != null)
        .map((log) => log.component!)
        .toSet()
        .toList()
        ..sort();
  }

  void _onFilterChanged(String value) {
    setState(() {
      switch (value) {
        case 'all':
          _selectedLevel = LogLevel.debug;
          break;
        case 'critical':
          _selectedLevel = LogLevel.critical;
          break;
        case 'error':
          _selectedLevel = LogLevel.error;
          break;
        case 'warning':
          _selectedLevel = LogLevel.warning;
          break;
        case 'info':
          _selectedLevel = LogLevel.info;
          break;
      }
    });
  }

  void _exportLogs() {
    final logsText = _loggingService.exportLogsAsText();
    Clipboard.setData(ClipboardData(text: logsText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logs copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs'),
        content: const Text('Are you sure you want to clear all logs? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _loggingService.clearLogs();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
