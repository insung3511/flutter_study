import 'package:shared_preferences/shared_preferences.dart';

class OllamaConfig {
  // Default configurations for different server types
  static const String _defaultLocalhost = 'http://localhost:11434';
  static const String _defaultRaspberryPi = 'http://192.168.1.100:11434';
  static const String _defaultLinuxServer = 'http://192.168.1.200:11434';
  
  // Timeout settings
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration requestTimeout = Duration(seconds: 60);
  
  // Server configuration keys
  static const String _serverTypeKey = 'ollama_server_type';
  static const String _customUrlKey = 'ollama_custom_url';
  static const String _serverHostKey = 'ollama_server_host';
  static const String _serverPortKey = 'ollama_server_port';
  
  // Server types
  static const String localhost = 'localhost';
  static const String raspberryPi = 'raspberry_pi';
  static const String linuxServer = 'linux_server';
  static const String custom = 'custom';
  
  // Get base URL based on current configuration
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final serverType = prefs.getString(_serverTypeKey) ?? localhost;
    
    switch (serverType) {
      case raspberryPi:
        return prefs.getString(_customUrlKey) ?? _defaultRaspberryPi;
      case linuxServer:
        return prefs.getString(_customUrlKey) ?? _defaultLinuxServer;
      case custom:
        return prefs.getString(_customUrlKey) ?? _defaultLocalhost;
      case localhost:
      default:
        return _defaultLocalhost;
    }
  }
  
  // Set server configuration
  static Future<void> setServerConfig({
    required String serverType,
    String? customUrl,
    String? host,
    int? port,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_serverTypeKey, serverType);
    
    if (customUrl != null) {
      await prefs.setString(_customUrlKey, customUrl);
    }
    
    if (host != null) {
      await prefs.setString(_serverHostKey, host);
    }
    
    if (port != null) {
      await prefs.setInt(_serverPortKey, port);
    }
  }
  
  // Get current server configuration
  static Future<Map<String, dynamic>> getServerConfig() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'serverType': prefs.getString(_serverTypeKey) ?? localhost,
      'customUrl': prefs.getString(_customUrlKey),
      'host': prefs.getString(_serverHostKey),
      'port': prefs.getInt(_serverPortKey) ?? 11434,
    };
  }
  
  // Validate server URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (e) {
      return false;
    }
  }
  
  // Build URL from host and port
  static String buildUrl(String host, int port, {bool useHttps = false}) {
    final scheme = useHttps ? 'https' : 'http';
    return '$scheme://$host:$port';
  }
}
