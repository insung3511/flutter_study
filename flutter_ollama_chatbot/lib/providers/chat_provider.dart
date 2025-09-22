import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/ollama_service.dart';

class ChatProvider with ChangeNotifier {
  final List<Message> _messages = [];
  final OllamaService _ollamaService = OllamaService();
  
  bool _isLoading = false;
  bool _isOllamaConnected = false;
  String _selectedModel = 'llama3.2';
  List<String> _availableModels = [];

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isOllamaConnected => _isOllamaConnected;
  String get selectedModel => _selectedModel;
  List<String> get availableModels => _availableModels;

  ChatProvider() {
    _initializeOllama();
  }

  Future<void> _initializeOllama() async {
    _isOllamaConnected = await _ollamaService.isOllamaRunning();
    if (_isOllamaConnected) {
      _availableModels = await _ollamaService.getAvailableModels();
      if (_availableModels.isNotEmpty) {
        _selectedModel = _availableModels.first;
      }
    }
    notifyListeners();
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

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}
