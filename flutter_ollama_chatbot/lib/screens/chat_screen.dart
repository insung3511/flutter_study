import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/connection_status.dart';
import 'server_config_screen.dart';
import 'server_discovery_screen.dart';
import 'error_logs_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chatbot'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ServerDiscoveryScreen(),
                ),
              ).then((_) {
                // Refresh connection after returning from discovery screen
                Provider.of<ChatProvider>(context, listen: false).refreshConnection();
              });
            },
            icon: Icon(MdiIcons.radar),
            tooltip: 'Find Servers',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ServerConfigScreen(),
                ),
              ).then((_) {
                // Refresh connection after returning from config screen
                Provider.of<ChatProvider>(context, listen: false).refreshConnection();
              });
            },
            icon: Icon(MdiIcons.cog),
            tooltip: 'Server Settings',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ErrorLogsScreen(),
                ),
              );
            },
            icon: Icon(MdiIcons.fileDocumentOutline),
            tooltip: 'Error Logs',
          ),
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return IconButton(
                onPressed: chatProvider.messages.isNotEmpty
                    ? () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear Chat'),
                            content: const Text('Are you sure you want to clear all messages?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  chatProvider.clearMessages();
                                  Navigator.pop(context);
                                },
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                        );
                      }
                    : null,
                icon: Icon(MdiIcons.deleteOutline),
                tooltip: 'Clear Chat',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return ConnectionStatus(
                isConnected: chatProvider.isOllamaConnected,
                onRefresh: chatProvider.refreshConnection,
                selectedModel: chatProvider.selectedModel,
                availableModels: chatProvider.availableModels,
                onModelChanged: chatProvider.changeModel,
              );
            },
          ),
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                // Scroll to bottom when new messages are added
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                if (chatProvider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          MdiIcons.robot,
                          size: 80,
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start a conversation with AI',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Make sure Ollama is running to begin chatting',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    return MessageBubble(message: message);
                  },
                );
              },
            ),
          ),
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return ChatInput(
                onSendMessage: chatProvider.sendMessage,
                isLoading: chatProvider.isLoading,
              );
            },
          ),
        ],
      ),
    );
  }
}
