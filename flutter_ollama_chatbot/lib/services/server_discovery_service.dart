import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:multicast_dns/multicast_dns.dart';

class DiscoveredServer {
  final String id;
  final String name;
  final String host;
  final int port;
  final String protocol;
  final bool supportsGrpc;
  final List<String> availableModels;
  final Map<String, dynamic> capabilities;
  final DateTime lastSeen;

  DiscoveredServer({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.protocol,
    required this.supportsGrpc,
    required this.availableModels,
    required this.capabilities,
    required this.lastSeen,
  });

  factory DiscoveredServer.fromJson(Map<String, dynamic> json) {
    return DiscoveredServer(
      id: json['server_id'] ?? '',
      name: json['server_name'] ?? 'Unknown Server',
      host: json['host'] ?? '',
      port: json['port'] ?? 11434,
      protocol: json['protocol'] ?? 'http',
      supportsGrpc: json['supports_grpc'] ?? false,
      availableModels: List<String>.from(json['available_models'] ?? []),
      capabilities: Map<String, dynamic>.from(json['capabilities'] ?? {}),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(json['last_seen'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'server_id': id,
      'server_name': name,
      'host': host,
      'port': port,
      'protocol': protocol,
      'supports_grpc': supportsGrpc,
      'available_models': availableModels,
      'capabilities': capabilities,
      'last_seen': lastSeen.millisecondsSinceEpoch,
    };
  }

  String get displayName => '$name ($host:$port)';
  String get fullUrl => '$protocol://$host:$port';
  
  @override
  String toString() => displayName;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredServer &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          host == other.host &&
          port == other.port;

  @override
  int get hashCode => id.hashCode ^ host.hashCode ^ port.hashCode;
}

class ServerDiscoveryService {
  static const String _serviceType = '_ollama._tcp.local';
  static const String _grpcServiceType = '_ollama-grpc._tcp.local';
  
  final Map<String, DiscoveredServer> _discoveredServers = {};
  final StreamController<List<DiscoveredServer>> _serversController = 
      StreamController<List<DiscoveredServer>>.broadcast();
  
  MDnsClient? _mDnsClient;
  Timer? _cleanupTimer;
  bool _isDiscovering = false;

  Stream<List<DiscoveredServer>> get discoveredServers => _serversController.stream;
  
  List<DiscoveredServer> get servers => _discoveredServers.values.toList();

  /// Start discovering servers on the network
  Future<void> startDiscovery() async {
    if (_isDiscovering) return;
    
    _isDiscovering = true;
    
    try {
      _mDnsClient = MDnsClient();
      await _mDnsClient!.start();
      
      // Discover HTTP servers
      await _discoverService(_serviceType);
      
      // Discover gRPC servers
      await _discoverService(_grpcServiceType);
      
      // Start cleanup timer to remove old servers
      _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (_) => _cleanupOldServers());
      
      print('Server discovery started');
    } catch (e) {
      print('Failed to start server discovery: $e');
      _isDiscovering = false;
    }
  }

  /// Stop discovering servers
  Future<void> stopDiscovery() async {
    if (!_isDiscovering) return;
    
    _isDiscovering = false;
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    
    _mDnsClient?.stop();
    _mDnsClient = null;
    
    print('Server discovery stopped');
  }

  /// Discover servers of a specific service type
  Future<void> _discoverService(String serviceType) async {
    try {
      final stream = _mDnsClient!.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(serviceType),
      );
      await for (final PtrResourceRecord ptr in stream) {
        await _resolveService(ptr.domainName, serviceType);
      }
    } catch (e) {
      print('Error discovering $serviceType: $e');
    }
  }

  /// Resolve service information
  Future<void> _resolveService(String name, String serviceType) async {
    try {
      // Get SRV record
      final srvRecord = await _mDnsClient!.lookup<SrvResourceRecord>(
        ResourceRecordQuery.service(name),
      ).first;
      
      // Get TXT record for additional info
      String? txtData;
      try {
        final txtRecord = await _mDnsClient!.lookup<TxtResourceRecord>(
          ResourceRecordQuery.text(name),
        ).first;
        txtData = txtRecord.text;
      } catch (e) {
        // TXT record is optional
      }
      
      // Get IP address by resolving hostname
      String? ipAddress;
      try {
        final addresses = await InternetAddress.lookup(srvRecord.target);
        if (addresses.isNotEmpty) {
          ipAddress = addresses.first.address;
        }
      } catch (e) {
        print('Could not resolve IP for ${srvRecord.target}: $e');
        return;
      }
      
      if (ipAddress != null) {
        await _processDiscoveredServer(
          name: name,
          host: ipAddress,
          port: srvRecord.port,
          serviceType: serviceType,
          txtData: txtData,
        );
      }
    } catch (e) {
      print('Error resolving service $name: $e');
    }
  }

  /// Process discovered server information
  Future<void> _processDiscoveredServer({
    required String name,
    required String host,
    required int port,
    required String serviceType,
    String? txtData,
  }) async {
    try {
      // Parse TXT data if available
      Map<String, dynamic> capabilities = {};
      List<String> models = [];
      bool supportsGrpc = serviceType.contains('grpc');
      
      if (txtData != null) {
        try {
          final parsed = json.decode(txtData);
          capabilities = Map<String, dynamic>.from(parsed);
          models = List<String>.from(capabilities['models'] ?? []);
        } catch (e) {
          // TXT data might not be JSON, try simple parsing
          final pairs = txtData.split(',');
          for (final pair in pairs) {
            final parts = pair.split('=');
            if (parts.length == 2) {
              capabilities[parts[0].trim()] = parts[1].trim();
            }
          }
        }
      }
      
      // Create server ID from host and port
      final serverId = '${host}_$port';
      
      final server = DiscoveredServer(
        id: serverId,
        name: _extractServerName(name),
        host: host,
        port: port,
        protocol: supportsGrpc ? 'grpc' : 'http',
        supportsGrpc: supportsGrpc,
        availableModels: models,
        capabilities: capabilities,
        lastSeen: DateTime.now(),
      );
      
      _discoveredServers[serverId] = server;
      _notifyServersChanged();
      
      print('Discovered server: ${server.displayName} (${server.protocol})');
    } catch (e) {
      print('Error processing discovered server: $e');
    }
  }

  /// Extract server name from mDNS name
  String _extractServerName(String name) {
    // Remove service type and .local suffix
    String cleanName = name.replaceAll('._ollama._tcp.local', '');
    cleanName = cleanName.replaceAll('._ollama-grpc._tcp.local', '');
    
    // Convert to readable format
    return cleanName.replaceAll('-', ' ').replaceAll('_', ' ');
  }

  /// Clean up old servers that haven't been seen recently
  void _cleanupOldServers() {
    final now = DateTime.now();
    final toRemove = <String>[];
    
    for (final entry in _discoveredServers.entries) {
      final age = now.difference(entry.value.lastSeen);
      if (age.inMinutes > 5) { // Remove servers not seen for 5 minutes
        toRemove.add(entry.key);
      }
    }
    
    if (toRemove.isNotEmpty) {
      for (final key in toRemove) {
        _discoveredServers.remove(key);
      }
      _notifyServersChanged();
    }
  }

  /// Notify listeners of server list changes
  void _notifyServersChanged() {
    _serversController.add(_discoveredServers.values.toList());
  }

  /// Manually discover servers by scanning common ports
  Future<List<DiscoveredServer>> manualDiscovery() async {
    final discovered = <DiscoveredServer>[];
    
    try {
      final networkInfo = NetworkInfo();
      final wifiIP = await networkInfo.getWifiIP();
      
      if (wifiIP != null) {
        // Extract network prefix (e.g., 192.168.1 from 192.168.1.100)
        final parts = wifiIP.split('.');
        if (parts.length >= 3) {
          final networkPrefix = '${parts[0]}.${parts[1]}.${parts[2]}';
          
          // Scan common ports
          final ports = [11434, 8080, 9090];
          
          for (int i = 1; i <= 254; i++) {
            final ip = '$networkPrefix.$i';
            
            for (final port in ports) {
              if (await _testConnection(ip, port)) {
                final serverId = '${ip}_$port';
                if (!_discoveredServers.containsKey(serverId)) {
                  final server = DiscoveredServer(
                    id: serverId,
                    name: 'Discovered Server',
                    host: ip,
                    port: port,
                    protocol: port == 9090 ? 'grpc' : 'http',
                    supportsGrpc: port == 9090,
                    availableModels: [],
                    capabilities: {},
                    lastSeen: DateTime.now(),
                  );
                  
                  discovered.add(server);
                  _discoveredServers[serverId] = server;
                }
              }
            }
          }
        }
      }
      
      if (discovered.isNotEmpty) {
        _notifyServersChanged();
      }
    } catch (e) {
      print('Error in manual discovery: $e');
    }
    
    return discovered;
  }

  /// Test if a connection is possible to the given host and port
  Future<bool> _testConnection(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 2));
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get the best available server (prefer gRPC, then HTTP)
  DiscoveredServer? getBestServer() {
    if (_discoveredServers.isEmpty) return null;
    
    // First try to find a gRPC server
    for (final server in _discoveredServers.values) {
      if (server.supportsGrpc) {
        return server;
      }
    }
    
    // Fallback to HTTP server
    return _discoveredServers.values.first;
  }

  /// Clear all discovered servers
  void clearServers() {
    _discoveredServers.clear();
    _notifyServersChanged();
  }

  /// Dispose resources
  void dispose() {
    stopDiscovery();
    _serversController.close();
  }
}
