import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../config/ollama_config.dart';

class ConnectionStatus extends StatefulWidget {
  final bool isConnected;
  final VoidCallback onRefresh;
  final String selectedModel;
  final List<String> availableModels;
  final Function(String) onModelChanged;

  const ConnectionStatus({
    super.key,
    required this.isConnected,
    required this.onRefresh,
    required this.selectedModel,
    required this.availableModels,
    required this.onModelChanged,
  });

  @override
  State<ConnectionStatus> createState() => _ConnectionStatusState();
}

class _ConnectionStatusState extends State<ConnectionStatus> {
  String _currentServerInfo = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadServerInfo();
  }

  Future<void> _loadServerInfo() async {
    try {
      final config = await OllamaConfig.getServerConfig();
      
      String serverInfo;
      switch (config['serverType']) {
        case OllamaConfig.localhost:
          serverInfo = 'Local';
          break;
        case OllamaConfig.raspberryPi:
          serverInfo = 'Raspberry Pi';
          break;
        case OllamaConfig.linuxServer:
          serverInfo = 'Linux Server';
          break;
        case OllamaConfig.custom:
          serverInfo = 'Custom Server';
          break;
        default:
          serverInfo = 'Unknown';
      }
      
      setState(() {
        _currentServerInfo = serverInfo;
      });
    } catch (e) {
      setState(() {
        _currentServerInfo = 'Unknown';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isConnected 
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: widget.isConnected 
                ? Colors.green.withOpacity(0.3)
                : Colors.red.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.isConnected ? MdiIcons.checkCircle : MdiIcons.alertCircle,
            color: widget.isConnected ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.isConnected 
                      ? 'Connected to Ollama (${widget.selectedModel})'
                      : 'Ollama not running - Start Ollama to begin chatting',
                  style: TextStyle(
                    color: widget.isConnected ? Colors.green[700] : Colors.red[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Server: $_currentServerInfo',
                  style: TextStyle(
                    color: widget.isConnected ? Colors.green[600] : Colors.red[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (widget.isConnected && widget.availableModels.length > 1)
            PopupMenuButton<String>(
              icon: Icon(
                MdiIcons.chevronDown,
                color: Theme.of(context).primaryColor,
              ),
              onSelected: widget.onModelChanged,
              itemBuilder: (context) => widget.availableModels.map((model) {
                return PopupMenuItem<String>(
                  value: model,
                  child: Row(
                    children: [
                      if (model == widget.selectedModel)
                        Icon(
                          MdiIcons.check,
                          color: Theme.of(context).primaryColor,
                          size: 16,
                        )
                      else
                        const SizedBox(width: 16),
                      const SizedBox(width: 8),
                      Text(model),
                    ],
                  ),
                );
              }).toList(),
            ),
          IconButton(
            onPressed: widget.onRefresh,
            icon: Icon(
              MdiIcons.refresh,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
