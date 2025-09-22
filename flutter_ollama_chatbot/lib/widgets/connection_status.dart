import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ConnectionStatus extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isConnected 
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: isConnected 
                ? Colors.green.withOpacity(0.3)
                : Colors.red.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? MdiIcons.checkCircle : MdiIcons.alertCircle,
            color: isConnected ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isConnected 
                  ? 'Connected to Ollama ($selectedModel)'
                  : 'Ollama not running - Start Ollama to begin chatting',
              style: TextStyle(
                color: isConnected ? Colors.green[700] : Colors.red[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isConnected && availableModels.length > 1)
            PopupMenuButton<String>(
              icon: Icon(
                MdiIcons.chevronDown,
                color: Theme.of(context).primaryColor,
              ),
              onSelected: onModelChanged,
              itemBuilder: (context) => availableModels.map((model) {
                return PopupMenuItem<String>(
                  value: model,
                  child: Row(
                    children: [
                      if (model == selectedModel)
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
            onPressed: onRefresh,
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
