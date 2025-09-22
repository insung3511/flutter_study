class OllamaConfig {
  // Change this to your Mac's IP address if it changes
  // You can find your IP with: ifconfig | grep "inet " | grep -v 127.0.0.1
  static const String baseUrl = 'http://192.168.45.137:11434';
  
  // Alternative: Use localhost for simulator testing
  // static const String baseUrl = 'http://localhost:11434';
  
  // Timeout settings
  static const Duration connectionTimeout = Duration(seconds: 5);
  static const Duration requestTimeout = Duration(seconds: 30);
}
