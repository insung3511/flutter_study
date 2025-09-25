import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/hybrid_ollama_service.dart';
import '../services/server_discovery_service.dart';

class ChatProvider with ChangeNotifier {
  final List<Message> _messages = [];
  final HybridOllamaService _ollamaService = HybridOllamaService();
  
  bool _isLoading = false;
  bool _isOllamaConnected = false;
  String _selectedModel = 'gemma2:1b';
  List<String> _availableModels = [];
  List<DiscoveredServer> _discoveredServers = [];
  String _connectionStatus = 'Initializing...';

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isOllamaConnected => _isOllamaConnected;
  String get selectedModel => _selectedModel;
  List<String> get availableModels => _availableModels;
  List<DiscoveredServer> get discoveredServers => _discoveredServers;
  String get connectionStatus => _connectionStatus;

  ChatProvider() {
    _initializeOllama();
  }

  Future<void> _initializeOllama() async {
    try {
      _connectionStatus = 'Initializing services...';
      notifyListeners();
      
      // Initialize hybrid service and start discovery
      await _ollamaService.initialize();
      
      // Listen to discovered servers
      _ollamaService.discoveredServers.listen((servers) {
        _discoveredServers = servers;
        notifyListeners();
      });
      
      _connectionStatus = 'Searching for servers...';
      notifyListeners();
      
      // Try to connect automatically
      final connected = await _ollamaService.connect();
      _isOllamaConnected = connected;
      _connectionStatus = _ollamaService.connectionStatus;
      
      if (_isOllamaConnected) {
        _availableModels = await _ollamaService.getAvailableModels();
        if (_availableModels.isNotEmpty) {
          _selectedModel = _availableModels.first;
        }
      }
      
      notifyListeners();
    } catch (e) {
      _connectionStatus = 'Initialization error: $e';
      _isOllamaConnected = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || _isLoading) return;

    // Add user message
    final userMessage = Message(
      content: content.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    notifyListeners();

    if (!_isOllamaConnected) {
      _addBotMessage('Ollama is not running. Please start Ollama and try again.');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Add loading message
      final loadingMessage = Message(
        content: 'Thinking...',
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: true,
      );
      _messages.add(loadingMessage);
      notifyListeners();

      // Get response from Ollama
      final response = await _ollamaService.generateResponse(content, _selectedModel);
      
      // Remove loading message and add actual response
      _messages.removeLast();
      final botMessage = Message(
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(botMessage);
    } catch (e) {
      // Remove loading message and add error
      _messages.removeLast();
      _addBotMessage('Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _addBotMessage(String content) {
    final botMessage = Message(
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.add(botMessage);
    notifyListeners();
  }

  Future<void> changeModel(String model) async {
    if (_availableModels.contains(model)) {
      _selectedModel = model;
      notifyListeners();
    }
  }

  Future<void> refreshConnection() async {
    await _initializeOllama();
  }

  Future<void> connectToServer(DiscoveredServer server) async {
    try {
      _connectionStatus = 'Connecting to ${server.displayName}...';
      notifyListeners();
      
      final connected = await _ollamaService.connect(discoveredServer: server);
      _isOllamaConnected = connected;
      _connectionStatus = _ollamaService.connectionStatus;
      
      if (_isOllamaConnected) {
        _availableModels = await _ollamaService.getAvailableModels();
        if (_availableModels.isNotEmpty) {
          _selectedModel = _availableModels.first;
        }
      }
      
      notifyListeners();
    } catch (e) {
      _connectionStatus = 'Connection error: $e';
      _isOllamaConnected = false;
      notifyListeners();
    }
  }

  Future<void> manualDiscovery() async {
    try {
      _connectionStatus = 'Searching for servers...';
      notifyListeners();
      
      final servers = await _ollamaService.manualDiscovery();
      _discoveredServers = servers;
      
      if (servers.isNotEmpty) {
        _connectionStatus = 'Found ${servers.length} server(s)';
      } else {
        _connectionStatus = 'No servers found';
      }
      
      notifyListeners();
    } catch (e) {
      _connectionStatus = 'Discovery error: $e';
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getConnectionMetrics() async {
    return await _ollamaService.getConnectionMetrics();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _ollamaService.dispose();
    super.dispose();
  }
}
