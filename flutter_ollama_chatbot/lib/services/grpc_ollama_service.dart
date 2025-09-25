import 'dart:async';
import 'dart:io';
import 'package:grpc/grpc.dart';

// Note: These will be generated from the proto file
// For now, we'll create placeholder classes
class GenerateRequest {
  final String model;
  final String prompt;
  final String? system;
  final String? context;
  final bool stream;
  final String? format;
  final Map<String, String> options;

  GenerateRequest({
    required this.model,
    required this.prompt,
    this.system,
    this.context,
    this.stream = false,
    this.format,
    this.options = const {},
  });

  Map<String, dynamic> toJson() => {
    'model': model,
    'prompt': prompt,
    if (system != null) 'system': system,
    if (context != null) 'context': context,
    'stream': stream,
    if (format != null) 'format': format,
    'options': options,
  };
}

class GenerateResponse {
  final String model;
  final String response;
  final bool done;
  final String? context;
  final int totalDuration;
  final int loadDuration;
  final int promptEvalCount;
  final int promptEvalDuration;
  final int evalCount;
  final int evalDuration;
  final Map<String, String> metadata;

  GenerateResponse({
    required this.model,
    required this.response,
    required this.done,
    this.context,
    required this.totalDuration,
    required this.loadDuration,
    required this.promptEvalCount,
    required this.promptEvalDuration,
    required this.evalCount,
    required this.evalDuration,
    required this.metadata,
  });

  factory GenerateResponse.fromJson(Map<String, dynamic> json) {
    return GenerateResponse(
      model: json['model'] ?? '',
      response: json['response'] ?? '',
      done: json['done'] ?? false,
      context: json['context'],
      totalDuration: json['total_duration'] ?? 0,
      loadDuration: json['load_duration'] ?? 0,
      promptEvalCount: json['prompt_eval_count'] ?? 0,
      promptEvalDuration: json['prompt_eval_duration'] ?? 0,
      evalCount: json['eval_count'] ?? 0,
      evalDuration: json['eval_duration'] ?? 0,
      metadata: Map<String, String>.from(json['metadata'] ?? {}),
    );
  }
}

class ServerInfo {
  final String serverId;
  final String serverName;
  final String version;
  final String host;
  final int port;
  final String protocol;
  final bool supportsGrpc;
  final List<String> availableModels;
  final DateTime lastSeen;
  final String capabilities;

  ServerInfo({
    required this.serverId,
    required this.serverName,
    required this.version,
    required this.host,
    required this.port,
    required this.protocol,
    required this.supportsGrpc,
    required this.availableModels,
    required this.lastSeen,
    required this.capabilities,
  });

  factory ServerInfo.fromJson(Map<String, dynamic> json) {
    return ServerInfo(
      serverId: json['server_id'] ?? '',
      serverName: json['server_name'] ?? 'Unknown Server',
      version: json['version'] ?? '1.0.0',
      host: json['host'] ?? '',
      port: json['port'] ?? 11434,
      protocol: json['protocol'] ?? 'grpc',
      supportsGrpc: json['supports_grpc'] ?? true,
      availableModels: List<String>.from(json['available_models'] ?? []),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(json['last_seen'] ?? 0),
      capabilities: json['capabilities'] ?? '{}',
    );
  }
}

class GrpcOllamaService {
  ClientChannel? _channel;
  bool _isConnected = false;
  String _currentHost = '';
  int _currentPort = 9090;
  
  // Note: This will be replaced with the generated gRPC client
  // OllamaServiceClient? _client;

  /// Connect to gRPC server
  Future<bool> connect(String host, int port) async {
    try {
      await disconnect();
      
      _currentHost = host;
      _currentPort = port;
      
      _channel = ClientChannel(
        host,
        port: port,
        options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
        ),
      );
      
      // Test connection
      await _channel!.shutdown();
      _channel = ClientChannel(
        host,
        port: port,
        options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
        ),
      );
      
      _isConnected = true;
      return true;
    } catch (e) {
      print('Failed to connect to gRPC server: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Disconnect from gRPC server
  Future<void> disconnect() async {
    if (_channel != null) {
      await _channel!.shutdown();
      _channel = null;
    }
    _isConnected = false;
  }

  /// Check if connected
  bool get isConnected => _isConnected;

  /// Get server information
  Future<ServerInfo?> getServerInfo() async {
    if (!_isConnected || _channel == null) return null;
    
    try {
      // This would use the generated gRPC client
      // For now, we'll simulate with placeholder data
      
      // Simulate gRPC call - in real implementation, this would be:
      // final response = await _client.getServerInfo(Empty());
      
      return ServerInfo(
        serverId: 'grpc-server',
        serverName: 'gRPC Ollama Server',
        version: '1.0.0',
        host: _currentHost,
        port: _currentPort,
        protocol: 'grpc',
        supportsGrpc: true,
        availableModels: ['gemma2:1b', 'gemma2:2b', 'gemma2:4b'],
        lastSeen: DateTime.now(),
        capabilities: '{"streaming": true, "batch_processing": true}',
      );
    } catch (e) {
      print('Error getting server info: $e');
      return null;
    }
  }

  /// Get available models
  Future<List<String>> getAvailableModels() async {
    if (!_isConnected || _channel == null) return [];
    
    try {
      // This would use the generated gRPC client
      // For now, simulate with Gemma models optimized for Raspberry Pi
      return ['gemma2:1b', 'gemma2:2b', 'gemma2:4b', 'gemma2:9b'];
    } catch (e) {
      print('Error getting available models: $e');
      return [];
    }
  }

  /// Generate response (streaming)
  Stream<String> generateStreamResponse(String message, String model) async* {
    if (!_isConnected || _channel == null) {
      yield 'Error: Not connected to gRPC server';
      return;
    }
    
    try {
      // This would use the generated gRPC client
      // For now, simulate streaming response
      final words = message.split(' ');
      for (int i = 0; i < words.length; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        yield '${words[i]} ';
      }
    } catch (e) {
      yield 'Error generating response: $e';
    }
  }

  /// Generate single response (non-streaming)
  Future<String> generateResponse(String message, String model) async {
    if (!_isConnected || _channel == null) {
      return 'Error: Not connected to gRPC server';
    }
    
    try {
      // This would use the generated gRPC client
      // For now, simulate response
      await Future.delayed(const Duration(milliseconds: 500));
      return 'This is a simulated gRPC response for: $message';
    } catch (e) {
      return 'Error generating response: $e';
    }
  }

  /// Check if gRPC server is running
  Future<bool> isGrpcServerRunning(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Test gRPC connection
  Future<bool> testConnection(String host, int port) async {
    return await connect(host, port);
  }
}
