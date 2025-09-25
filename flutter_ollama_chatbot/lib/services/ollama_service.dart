import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/ollama_config.dart';

class OllamaService {
  
  // Check if Ollama is running
  Future<bool> isOllamaRunning() async {
    try {
      final baseUrl = await OllamaConfig.getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/api/tags'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(OllamaConfig.connectionTimeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get available models
  Future<List<String>> getAvailableModels() async {
    try {
      final baseUrl = await OllamaConfig.getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/api/tags'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = data['models'] as List;
        return models.map((model) => model['name'] as String).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Generate response from Ollama
  Future<String> generateResponse(String message, String model) async {
    try {
      final baseUrl = await OllamaConfig.getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'model': model,
          'prompt': message,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'] ?? 'Sorry, I could not generate a response.';
      } else {
        return 'Error: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      return 'Error connecting to Ollama: $e';
    }
  }

  // Stream response from Ollama (for real-time typing effect)
  Stream<String> generateStreamResponse(String message, String model) async* {
    try {
      final baseUrl = await OllamaConfig.getBaseUrl();
      final request = http.Request('POST', Uri.parse('$baseUrl/api/generate'));
      request.headers['Content-Type'] = 'application/json';
      request.body = json.encode({
        'model': model,
        'prompt': message,
        'stream': true,
      });

      final streamedResponse = await http.Client().send(request);
      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.isNotEmpty) {
          try {
            final data = json.decode(line);
            if (data['response'] != null) {
              yield data['response'];
            }
          } catch (e) {
            // Skip invalid JSON lines
          }
        }
      }
    } catch (e) {
      yield 'Error connecting to Ollama: $e';
    }
  }
}
