import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../providers/chat_provider.dart';
import '../services/server_discovery_service.dart';

class ServerDiscoveryScreen extends StatefulWidget {
  const ServerDiscoveryScreen({super.key});

  @override
  State<ServerDiscoveryScreen> createState() => _ServerDiscoveryScreenState();
}

class _ServerDiscoveryScreenState extends State<ServerDiscoveryScreen> {
  bool _isDiscovering = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Discovery'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _isDiscovering ? null : _startDiscovery,
            icon: Icon(_isDiscovering ? MdiIcons.stop : MdiIcons.play),
            tooltip: _isDiscovering ? 'Stop Discovery' : 'Start Discovery',
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          return Column(
            children: [
              // Discovery Status Card
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isDiscovering ? MdiIcons.radar : MdiIcons.radar,
                            color: _isDiscovering ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Discovery Status',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        chatProvider.connectionStatus,
                        style: TextStyle(
                          color: _isDiscovering ? Colors.green[700] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _isDiscovering ? null : 0,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isDiscovering ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Discovery Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isDiscovering ? null : _startDiscovery,
                        icon: Icon(_isDiscovering ? MdiIcons.loading : MdiIcons.radar),
                        label: Text(_isDiscovering ? 'Discovering...' : 'Auto Discovery'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isDiscovering ? null : _manualDiscovery,
                        icon: Icon(MdiIcons.magnify),
                        label: const Text('Manual Scan'),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Discovered Servers
              Expanded(
                child: chatProvider.discoveredServers.isEmpty
                    ? _buildEmptyState()
                    : _buildServerList(chatProvider),
              ),
              
              // Connection Metrics
              if (chatProvider.isOllamaConnected) ...[
                const Divider(),
                _buildConnectionMetrics(chatProvider),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            MdiIcons.serverOff,
            size: 80,
            color: Theme.of(context).primaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No servers discovered yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Auto Discovery" to search for Ollama servers on your network',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isDiscovering ? null : _startDiscovery,
            icon: Icon(MdiIcons.radar),
            label: const Text('Start Discovery'),
          ),
        ],
      ),
    );
  }

  Widget _buildServerList(ChatProvider chatProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: chatProvider.discoveredServers.length,
      itemBuilder: (context, index) {
        final server = chatProvider.discoveredServers[index];
        return _buildServerCard(server, chatProvider);
      },
    );
  }

  Widget _buildServerCard(DiscoveredServer server, ChatProvider chatProvider) {
    final isConnected = chatProvider.isOllamaConnected && 
        chatProvider.connectionStatus.contains(server.host);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: server.supportsGrpc ? Colors.blue : Colors.green,
          child: Icon(
            server.supportsGrpc ? MdiIcons.lightningBolt : MdiIcons.server,
            color: Colors.white,
          ),
        ),
        title: Text(
          server.displayName,
          style: TextStyle(
            fontWeight: isConnected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${server.protocol.toUpperCase()} • ${server.host}:${server.port}'),
            if (server.availableModels.isNotEmpty)
              Text(
                'Models: ${server.availableModels.length}',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
            Text(
              'Last seen: ${_formatLastSeen(server.lastSeen)}',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (server.supportsGrpc)
              Icon(
                MdiIcons.lightningBolt,
                color: Colors.blue,
                size: 16,
              ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: isConnected ? null : () => _connectToServer(server, chatProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: isConnected ? Colors.green : Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(isConnected ? 'Connected' : 'Connect'),
            ),
          ],
        ),
        onTap: isConnected ? null : () => _connectToServer(server, chatProvider),
      ),
    );
  }

  Widget _buildConnectionMetrics(ChatProvider chatProvider) {
    return FutureBuilder<Map<String, dynamic>>(
      future: chatProvider.getConnectionMetrics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        final metrics = snapshot.data!;
        
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connection Metrics',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricItem(
                      'Protocol',
                      metrics['protocol']?.toString().toUpperCase() ?? 'Unknown',
                      MdiIcons.lan,
                    ),
                    _buildMetricItem(
                      'Server',
                      '${metrics['host']}:${metrics['port']}',
                      MdiIcons.server,
                    ),
                    _buildMetricItem(
                      'Discovered',
                      '${metrics['discovered_servers']} servers',
                      MdiIcons.radar,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricItem(
                      'gRPC',
                      metrics['grpc_available'] ? 'Available' : 'Not Available',
                      MdiIcons.lightningBolt,
                      color: metrics['grpc_available'] ? Colors.blue : Colors.grey,
                    ),
                    _buildMetricItem(
                      'HTTP',
                      metrics['http_available'] ? 'Available' : 'Not Available',
                      MdiIcons.web,
                      color: metrics['http_available'] ? Colors.green : Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(
          icon,
          color: color ?? Theme.of(context).primaryColor,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _isDiscovering = true;
    });
    
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.refreshConnection();
      
      // Discovery is active
    } catch (e) {
      setState(() {
        _isDiscovering = false;
      });
    }
  }

  Future<void> _manualDiscovery() async {
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.manualDiscovery();
    } catch (e) {
      // Handle error silently or show a snackbar
    }
  }

  Future<void> _connectToServer(DiscoveredServer server, ChatProvider chatProvider) async {
    await chatProvider.connectToServer(server);
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
