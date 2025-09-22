import 'dart:io';
import 'services/ollama_service.dart';

void main() async {
  print('🤖 Testing Ollama Connection');
  print('============================');
  
  final ollamaService = OllamaService();
  
  // Test connection
  print('Checking if Ollama is running...');
  final isRunning = await ollamaService.isOllamaRunning();
  
  if (isRunning) {
    print('✅ Ollama is running!');
    
    // Get available models
    print('Getting available models...');
    final models = await ollamaService.getAvailableModels();
    
    if (models.isNotEmpty) {
      print('✅ Available models:');
      for (final model in models) {
        print('   - $model');
      }
      
      // Test a simple query
      print('\nTesting AI response...');
      final response = await ollamaService.generateResponse(
        'Hello! Can you tell me a short joke?',
        models.first,
      );
      
      print('✅ AI Response:');
      print('   $response');
    } else {
      print('❌ No models found. Please pull a model first:');
      print('   ollama pull llama3.2');
    }
  } else {
    print('❌ Ollama is not running. Please start it first:');
    print('   ollama serve');
  }
  
  print('\n🎉 Test complete!');
}
