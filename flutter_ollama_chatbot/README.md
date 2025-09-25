# AI Chatbot with Ollama

A Flutter application that provides an AI chatbot interface using Ollama for AI model inference. Supports both local and remote Ollama servers, including Raspberry Pi and Linux servers.

## Features

- 🤖 **AI Chat Interface**: Clean, modern chat UI with message bubbles
- 🔗 **Ollama Integration**: Connects to local or remote Ollama servers for AI responses
- 📱 **Multi-Platform**: Works on iOS, Android, Web, and Desktop
- 🎨 **Modern UI**: Material Design 3 with dark/light theme support
- 📝 **Markdown Support**: Rich text rendering for AI responses
- 🔄 **Real-time Status**: Connection status indicator and model selection
- 💬 **Message History**: Persistent chat history during session
- ⚙️ **Server Configuration**: Easy setup for Raspberry Pi and Linux servers
- 🌐 **Remote Access**: Connect to Ollama servers on your local network
- ⚡ **gRPC Support**: Fast, efficient communication protocol for better performance
- 🔍 **Auto Discovery**: Automatically find Ollama servers on your network using mDNS
- 🔄 **Hybrid Protocol**: Automatic fallback between gRPC and HTTP for maximum compatibility
- 📊 **Connection Metrics**: Real-time performance monitoring and server health

## Prerequisites

### 1. Ollama Server Setup

You have several options for running Ollama:

#### Option A: Local Development (Recommended for testing)
```bash
# Install Ollama locally
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama service
ollama serve

# Pull a model (e.g., Gemma 2 1B - optimized for Raspberry Pi)
ollama pull gemma2:1b
```

#### Option B: Raspberry Pi Server (Recommended for production)
```bash
# On your Raspberry Pi, run our setup script with full features
curl -fsSL https://raw.githubusercontent.com/your-repo/flutter_ollama_chatbot/main/setup_remote_server.sh | bash

# Or download and run manually with custom options
wget https://raw.githubusercontent.com/your-repo/flutter_ollama_chatbot/main/setup_remote_server.sh
chmod +x setup_remote_server.sh

# Full setup with gRPC and auto-discovery (using Gemma 2 1B for Raspberry Pi)
./setup_remote_server.sh --port 11434 --grpc-port 9090 --model gemma2:1b

# HTTP-only setup (faster, less features)
./setup_remote_server.sh --port 11434 --no-grpc --no-discovery
```

#### Option C: Linux Server Setup
```bash
# On your Linux server, run our setup script
curl -fsSL https://raw.githubusercontent.com/your-repo/flutter_ollama_chatbot/main/setup_remote_server.sh | bash

# Or with custom configuration (using Gemma 2 2B for better performance)
./setup_remote_server.sh --port 8080 --grpc-port 9091 --model gemma2:2b
```

### 2. Flutter Development Setup

Make sure you have Flutter installed and configured:

```bash
# Check Flutter installation
flutter doctor

# Install dependencies
flutter pub get
```

## Getting Started

### 1. Clone and Setup

```bash
cd flutter_ollama_chatbot
flutter pub get
```

### 2. Configure Server Connection

The app supports multiple server configurations:

1. **Local Development**: Uses `localhost:11434` by default
2. **Raspberry Pi**: Configure with your Pi's IP address
3. **Linux Server**: Configure with your server's IP address
4. **Custom URL**: Use any custom Ollama server URL

### 3. Run the App

```bash
# Run on your preferred platform
flutter run -d ios          # iOS
flutter run -d android      # Android
flutter run -d web          # Web
flutter run -d macos        # macOS
flutter run -d linux        # Linux
flutter run -d windows      # Windows
```

### 4. Connect to Servers

#### Option A: Auto Discovery (Recommended)
1. **Find Servers**: Tap the radar icon (📡) in the app's top-right corner
2. **Auto Discovery**: The app will automatically find Ollama servers on your network
3. **Select Server**: Choose from discovered servers (gRPC servers are preferred)
4. **Connect**: Tap "Connect" on your preferred server

#### Option B: Manual Configuration
1. **Open Settings**: Tap the gear icon (⚙️) in the app's top-right corner
2. **Select Server Type**: Choose from Local, Raspberry Pi, Linux Server, or Custom
3. **Enter Details**: Provide IP address and port (for remote servers)
4. **Test Connection**: Use the "Test Connection" button to verify
5. **Save Configuration**: Tap "Save Configuration" to apply settings

## Usage

1. **Auto-Connect**: The app automatically discovers and connects to the best available server
2. **Check Connection**: The status bar shows connection type (gRPC/HTTP) and server info
3. **Start Chatting**: Type your message and tap the send button for fast AI responses
4. **Switch Models**: Use the dropdown in the connection bar to switch between available models
5. **Monitor Performance**: View connection metrics and server health in the discovery screen
6. **Clear Chat**: Use the trash icon to clear your conversation history

### Protocol Selection

The app automatically chooses the best protocol:
- **gRPC** (Preferred): Faster, more efficient communication
- **HTTP** (Fallback): Compatible with all Ollama servers
- **Auto**: Tries gRPC first, falls back to HTTP if needed

## Server Setup Guide

### Raspberry Pi Setup

1. **Install OS**: Flash Raspberry Pi OS to your SD card
2. **Enable SSH**: Create an empty `ssh` file in the boot partition
3. **Connect**: SSH into your Pi: `ssh pi@<pi-ip-address>`
4. **Run Setup Script**: 
   ```bash
   curl -fsSL https://raw.githubusercontent.com/your-repo/flutter_ollama_chatbot/main/setup_remote_server.sh | bash
   ```
5. **Configure App**: Use your Pi's IP address in the Flutter app

### Linux Server Setup

1. **Access Server**: SSH into your Linux server
2. **Run Setup Script**:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/your-repo/flutter_ollama_chatbot/main/setup_remote_server.sh | bash
   ```
3. **Custom Configuration**:
   ```bash
   # Custom port and model
   ./setup_remote_server.sh --port 8080 --model llama3.1
   
   # Skip model download
   ./setup_remote_server.sh --skip-model
   
   # Test existing installation
   ./setup_remote_server.sh --test-only
   ```

### Manual Server Configuration

If you prefer manual setup:

1. **Install Ollama**:
   ```bash
   curl -fsSL https://ollama.ai/install.sh | sh
   ```

2. **Configure for Remote Access**:
   ```bash
   # Set environment variables
   export OLLAMA_HOST=0.0.0.0:11434
   export OLLAMA_ORIGINS=*
   
   # Start Ollama
   ollama serve
   ```

3. **Configure Firewall**:
   ```bash
   # Ubuntu/Debian
   sudo ufw allow 11434/tcp
   
   # CentOS/RHEL
   sudo firewall-cmd --permanent --add-port=11434/tcp
   sudo firewall-cmd --reload
   ```

4. **Download Models** (choose based on your Pi's RAM):
   ```bash
   # For Raspberry Pi 4 (4GB) - Ultra-fast
   ollama pull gemma2:1b
   
   # For Raspberry Pi 4 (8GB) - Good balance
   ollama pull gemma2:2b
   
   # For Raspberry Pi 5 (8GB) - High quality
   ollama pull gemma2:4b
   ```

### Available Models

The app will automatically detect available models from your Ollama installation. **Recommended models for Raspberry Pi:**

#### **Gemma 2 Models (Recommended for Raspberry Pi):**
- `gemma2:1b` - **Best for Raspberry Pi** - Ultra-fast, 1 billion parameters, ~1.2GB RAM
- `gemma2:2b` - **Good balance** - Fast with better quality, 2 billion parameters, ~2.4GB RAM  
- `gemma2:4b` - **High quality** - Excellent performance, 4 billion parameters, ~4.8GB RAM
- `gemma2:9b` - **Premium quality** - Best results, 9 billion parameters, ~10GB RAM (Pi 5 only)

#### **Other Compatible Models:**
- `phi3:mini` - Microsoft's Phi-3 Mini (efficient for Pi)
- `qwen2.5:0.5b` - Very lightweight option
- `tinyllama` - Ultra-minimal model for testing

#### **Model Selection Guide:**
- **Raspberry Pi 4 (4GB)**: Use `gemma2:1b` or `gemma2:2b`
- **Raspberry Pi 4 (8GB)**: Use `gemma2:2b` or `gemma2:4b`
- **Raspberry Pi 5 (8GB)**: Use `gemma2:4b` or `gemma2:9b`

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── config/
│   └── ollama_config.dart   # Server configuration management
├── models/
│   └── message.dart         # Message data model
├── providers/
│   └── chat_provider.dart   # State management
├── services/
│   └── ollama_service.dart  # Ollama API integration
├── screens/
│   ├── chat_screen.dart     # Main chat interface
│   └── server_config_screen.dart # Server configuration UI
└── widgets/
    ├── message_bubble.dart  # Message display widget
    ├── chat_input.dart      # Input field widget
    └── connection_status.dart # Status indicator

setup_remote_server.sh      # Automated server setup script
```

## Troubleshooting

### Connection Issues

- **"Ollama not running"**: Make sure Ollama is started on your server
- **"Error connecting to Ollama"**: Check if the server IP and port are correct
- **"Connection timeout"**: Verify network connectivity and firewall settings
- **No models available**: Pull a model with `ollama pull <model-name>` on your server

### Server Issues

- **Can't access remote server**: Check firewall settings and ensure port 11434 is open
- **Permission denied**: Make sure Ollama service is running with proper permissions
- **Model download fails**: Check internet connection and available disk space on server

### App Issues

- **Build errors**: Run `flutter clean && flutter pub get`
- **Platform-specific issues**: Check Flutter doctor output for platform-specific problems
- **Settings not saving**: Ensure the app has proper storage permissions

### Network Troubleshooting

1. **Test server connectivity**:
   ```bash
   # From your device, test if server is reachable
   ping <server-ip>
   
   # Test if Ollama port is open
   telnet <server-ip> 11434
   ```

2. **Check Ollama service status**:
   ```bash
   # On the server
   sudo systemctl status ollama
   sudo journalctl -u ollama -f
   ```

3. **Verify Ollama is accessible**:
   ```bash
   # Test from server itself
   curl http://localhost:11434/api/tags
   
   # Test from another device on network
   curl http://<server-ip>:11434/api/tags
   ```

## Dependencies

- `http`: HTTP client for Ollama API communication
- `provider`: State management
- `flutter_markdown`: Markdown rendering for AI responses
- `material_design_icons_flutter`: Additional icons
- `shared_preferences`: Local storage for server configuration
- `grpc`: gRPC client for fast communication
- `protobuf`: Protocol buffer support
- `network_info_plus`: Network information for discovery
- `multicast_dns`: mDNS service discovery
- `json_annotation`: JSON serialization support

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on iOS device/simulator
5. Submit a pull request

## License

This project is open source and available under the MIT License.