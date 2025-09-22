#!/bin/bash

echo "🤖 Setting up Ollama for AI Chatbot"
echo "=================================="

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama is not installed. Installing now..."
    curl -fsSL https://ollama.ai/install.sh | sh
    echo "✅ Ollama installed successfully!"
else
    echo "✅ Ollama is already installed"
fi

# Check if Ollama is running
if pgrep -x "ollama" > /dev/null; then
    echo "✅ Ollama is already running"
else
    echo "🚀 Starting Ollama service with network access..."
    OLLAMA_HOST=0.0.0.0:11434 ollama serve &
    sleep 3
    echo "✅ Ollama started successfully with network access!"
fi

# Pull a default model if not already present
echo "📥 Checking for Llama 3.2 model..."
if ollama list | grep -q "llama3.2"; then
    echo "✅ Llama 3.2 model is already available"
else
    echo "📥 Downloading Llama 3.2 model (this may take a while)..."
    ollama pull llama3.2
    echo "✅ Llama 3.2 model downloaded successfully!"
fi

echo ""
echo "🎉 Setup complete! You can now run the Flutter app:"
echo "   flutter run -d ios"
echo ""
echo "📱 The app will connect to Ollama at http://192.168.45.137:11434"
echo "🔗 Make sure to keep this terminal open to keep Ollama running"
echo "📡 Ollama is now accessible from other devices on your network"
