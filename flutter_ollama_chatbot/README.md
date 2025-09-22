# AI Chatbot with Ollama

A Flutter application that provides an AI chatbot interface using Ollama for local AI model inference on iOS.

## Features

- 🤖 **AI Chat Interface**: Clean, modern chat UI with message bubbles
- 🔗 **Ollama Integration**: Connects to local Ollama server for AI responses
- 📱 **iOS Optimized**: Designed specifically for iOS with native feel
- 🎨 **Modern UI**: Material Design 3 with dark/light theme support
- 📝 **Markdown Support**: Rich text rendering for AI responses
- 🔄 **Real-time Status**: Connection status indicator and model selection
- 💬 **Message History**: Persistent chat history during session

## Prerequisites

### 1. Install Ollama

First, you need to install and run Ollama on your machine:

```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama service
ollama serve

# Pull a model (e.g., Llama 3.2)
ollama pull llama3.2
```

### 2. Flutter Development Setup

Make sure you have Flutter installed and configured for iOS development:

```bash
# Check Flutter installation
flutter doctor

# Install iOS dependencies
flutter doctor --android-licenses
```

## Getting Started

### 1. Clone and Setup

```bash
cd flutter_ollama_chatbot
flutter pub get
```

### 2. Run on iOS

```bash
# Run on iOS simulator
flutter run -d ios

# Or run on physical iOS device
flutter run -d ios --device-id=<your-device-id>
```

### 3. Start Ollama

Make sure Ollama is running on your machine:

```bash
ollama serve
```

The app will automatically detect when Ollama is running and show the connection status.

## Usage

1. **Start Ollama**: Run `ollama serve` in your terminal
2. **Open the App**: Launch the Flutter app on your iOS device/simulator
3. **Check Connection**: The app will show "Connected to Ollama" when ready
4. **Start Chatting**: Type your message and tap the send button
5. **Switch Models**: Use the dropdown in the connection bar to switch between available models

## Configuration

### Ollama Server URL

The app connects to `http://localhost:11434` by default. To change this, modify the `_baseUrl` in `lib/services/ollama_service.dart`:

```dart
static const String _baseUrl = 'http://your-server:11434';
```

### Available Models

The app will automatically detect available models from your Ollama installation. Popular models include:

- `llama3.2` - Meta's Llama 3.2
- `llama3.1` - Meta's Llama 3.1
- `mistral` - Mistral AI models
- `codellama` - Code-focused Llama variant

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── message.dart         # Message data model
├── providers/
│   └── chat_provider.dart   # State management
├── services/
│   └── ollama_service.dart  # Ollama API integration
├── screens/
│   └── chat_screen.dart     # Main chat interface
└── widgets/
    ├── message_bubble.dart  # Message display widget
    ├── chat_input.dart      # Input field widget
    └── connection_status.dart # Status indicator
```

## Troubleshooting

### Connection Issues

- **"Ollama not running"**: Make sure Ollama is started with `ollama serve`
- **"Error connecting to Ollama"**: Check if Ollama is accessible at `http://localhost:11434`
- **No models available**: Pull a model with `ollama pull <model-name>`

### iOS Development Issues

- **Build errors**: Run `flutter clean && flutter pub get`
- **Simulator issues**: Reset iOS simulator or try a different device
- **Permission issues**: Check iOS development certificates

## Dependencies

- `http`: HTTP client for Ollama API communication
- `provider`: State management
- `flutter_markdown`: Markdown rendering for AI responses
- `material_design_icons_flutter`: Additional icons

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on iOS device/simulator
5. Submit a pull request

## License

This project is open source and available under the MIT License.