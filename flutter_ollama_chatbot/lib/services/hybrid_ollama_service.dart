import 'dart:async';
import 'grpc_ollama_service.dart';
import 'ollama_service.dart';
import '../config/ollama_config.dart';
import 'server_discovery_service.dart';

enum ConnectionProtocol {
  http,
  grpc,
  auto, // Try gRPC first, fallback to HTTP
}

class HybridOllamaService {
  final OllamaService _httpService = OllamaService();
  final GrpcOllamaService _grpcService = GrpcOllamaService();
  final ServerDiscoveryService _discoveryService = ServerDiscoveryService();
  
  ConnectionProtocol _currentProtocol = ConnectionProtocol.auto;
  String _currentHost = '';
  int _currentPort = 11434;
  bool _isConnected = false;
  String _connectionStatus = 'Disconnected';
  
  // Getters
  bool get isConnected => _isConnected;
  String get connectionStatus => _connectionStatus;
  ConnectionProtocol get currentProtocol => _currentProtocol;
  String get currentHost => _currentHost;
  int get currentPort => _currentPort;
  
  Stream<List<DiscoveredServer>> get discoveredServers => _discoveryService.discoveredServers;

  /// Initialize the service and start server discovery
  Future<void> initialize() async {
    await _discoveryService.startDiscovery();
  }

  /// Connect using the best available protocol and server
  Future<bool> connect({
    ConnectionProtocol protocol = ConnectionProtocol.auto,
    String? host,
    int? port,
    DiscoveredServer? discoveredServer,
  }) async {
    try {
      // Determine connection parameters
      if (discoveredServer != null) {
        _currentHost = discoveredServer.host;
        _currentPort = discoveredServer.port;
        _currentProtocol = discoveredServer.supportsGrpc 
            ? ConnectionProtocol.grpc 
            : ConnectionProtocol.http;
      } else if (host != null) {
        _currentHost = host;
        _currentPort = port ?? 11434;
        _currentProtocol = protocol;
      } else {
        // Try to find the best server automatically
        final bestServer = _discoveryService.getBestServer();
        if (bestServer != null) {
          return await connect(discoveredServer: bestServer);
        } else {
          // Fallback to configured server
          final baseUrl = await OllamaConfig.getBaseUrl();
          final uri = Uri.parse(baseUrl);
          _currentHost = uri.host;
          _currentPort = uri.port;
          _currentProtocol = protocol;
        }
      }

      // Attempt connection based on protocol
      switch (_currentProtocol) {
        case ConnectionProtocol.grpc:
          return await _connectGrpc();
        case ConnectionProtocol.http:
          return await _connectHttp();
        case ConnectionProtocol.auto:
          return await _connectAuto();
      }
    } catch (e) {
      _connectionStatus = 'Connection error: $e';
      _isConnected = false;
      return false;
    }
  }

  /// Connect using gRPC
  Future<bool> _connectGrpc() async {
    try {
      _connectionStatus = 'Connecting via gRPC...';
      
      final success = await _grpcService.connect(_currentHost, _currentPort);
      if (success) {
        _connectionStatus = 'Connected via gRPC';
        _isConnected = true;
        return true;
      } else {
        _connectionStatus = 'gRPC connection failed';
        _isConnected = false;
        return false;
      }
    } catch (e) {
      _connectionStatus = 'gRPC error: $e';
      _isConnected = false;
      return false;
    }
  }

  /// Connect using HTTP
  Future<bool> _connectHttp() async {
    try {
      _connectionStatus = 'Connecting via HTTP...';
      
      final success = await _httpService.isOllamaRunning();
      if (success) {
        _connectionStatus = 'Connected via HTTP';
        _isConnected = true;
        return true;
      } else {
        _connectionStatus = 'HTTP connection failed';
        _isConnected = false;
        return false;
      }
    } catch (e) {
      _connectionStatus = 'HTTP error: $e';
      _isConnected = false;
      return false;
    }
  }

  /// Connect automatically (try gRPC first, fallback to HTTP)
  Future<bool> _connectAuto() async {
    try {
      _connectionStatus = 'Auto-connecting (trying gRPC first)...';
      
      // First try gRPC
      final grpcPort = _currentPort == 11434 ? 9090 : _currentPort;
      final grpcSuccess = await _grpcService.connect(_currentHost, grpcPort);
      
      if (grpcSuccess) {
        _currentPort = grpcPort;
        _currentProtocol = ConnectionProtocol.grpc;
        _connectionStatus = 'Connected via gRPC (auto)';
        _isConnected = true;
        return true;
      }
      
      // Fallback to HTTP
      _connectionStatus = 'gRPC failed, trying HTTP...';
      final httpSuccess = await _httpService.isOllamaRunning();
      
      if (httpSuccess) {
        _currentPort = 11434;
        _currentProtocol = ConnectionProtocol.http;
        _connectionStatus = 'Connected via HTTP (auto fallback)';
        _isConnected = true;
        return true;
      }
      
      _connectionStatus = 'Both gRPC and HTTP failed';
      _isConnected = false;
      return false;
    } catch (e) {
      _connectionStatus = 'Auto-connection error: $e';
      _isConnected = false;
      return false;
    }
  }

  /// Disconnect from current service
  Future<void> disconnect() async {
    await _grpcService.disconnect();
    _isConnected = false;
    _connectionStatus = 'Disconnected';
  }

  /// Get available models
  Future<List<String>> getAvailableModels() async {
    if (!_isConnected) return [];
    
    try {
      switch (_currentProtocol) {
        case ConnectionProtocol.grpc:
          return await _grpcService.getAvailableModels();
        case ConnectionProtocol.http:
          return await _httpService.getAvailableModels();
        case ConnectionProtocol.auto:
          // This shouldn't happen after connection, but handle it
          return await _httpService.getAvailableModels();
      }
    } catch (e) {
      print('Error getting available models: $e');
      return [];
    }
  }

  /// Generate response (streaming)
  Stream<String> generateStreamResponse(String message, String model) async* {
    if (!_isConnected) {
      yield 'Error: Not connected to server';
      return;
    }
    
    try {
      switch (_currentProtocol) {
        case ConnectionProtocol.grpc:
          yield* _grpcService.generateStreamResponse(message, model);
          break;
        case ConnectionProtocol.http:
          yield* _httpService.generateStreamResponse(message, model);
          break;
        case ConnectionProtocol.auto:
          // This shouldn't happen after connection
          yield* _httpService.generateStreamResponse(message, model);
          break;
      }
    } catch (e) {
      yield 'Error generating response: $e';
    }
  }

  /// Generate single response (non-streaming)
  Future<String> generateResponse(String message, String model) async {
    if (!_isConnected) {
      return 'Error: Not connected to server';
    }
    
    try {
      switch (_currentProtocol) {
        case ConnectionProtocol.grpc:
          return await _grpcService.generateResponse(message, model);
        case ConnectionProtocol.http:
          return await _httpService.generateResponse(message, model);
        case ConnectionProtocol.auto:
          // This shouldn't happen after connection
          return await _httpService.generateResponse(message, model);
      }
    } catch (e) {
      return 'Error generating response: $e';
    }
  }

  /// Start server discovery
  Future<void> startDiscovery() async {
    await _discoveryService.startDiscovery();
  }

  /// Stop server discovery
  Future<void> stopDiscovery() async {
    await _discoveryService.stopDiscovery();
  }

  /// Get discovered servers
  List<DiscoveredServer> getDiscoveredServers() {
    return _discoveryService.servers;
  }

  /// Manual server discovery
  Future<List<DiscoveredServer>> manualDiscovery() async {
    return await _discoveryService.manualDiscovery();
  }

  /// Test connection to a specific server
  Future<bool> testConnection(String host, int port, {bool preferGrpc = true}) async {
    try {
      if (preferGrpc) {
        final grpcPort = port == 11434 ? 9090 : port;
        final grpcSuccess = await _grpcService.testConnection(host, grpcPort);
        if (grpcSuccess) return true;
      }
      
      // Test HTTP connection
      final httpSuccess = await _httpService.isOllamaRunning();
      return httpSuccess;
    } catch (e) {
      return false;
    }
  }

  /// Get connection performance metrics
  Future<Map<String, dynamic>> getConnectionMetrics() async {
    final metrics = <String, dynamic>{
      'protocol': _currentProtocol.toString().split('.').last,
      'host': _currentHost,
      'port': _currentPort,
      'is_connected': _isConnected,
      'status': _connectionStatus,
      'discovered_servers': _discoveryService.servers.length,
      'grpc_available': false,
      'http_available': false,
    };
    
    // Test both protocols
    try {
      metrics['grpc_available'] = await _grpcService.isGrpcServerRunning(_currentHost, 9090);
      metrics['http_available'] = await _httpService.isOllamaRunning();
    } catch (e) {
      // Ignore errors in metrics collection
    }
    
    return metrics;
  }

  /// Dispose resources
  void dispose() {
    _discoveryService.dispose();
    _grpcService.disconnect();
  }
}
