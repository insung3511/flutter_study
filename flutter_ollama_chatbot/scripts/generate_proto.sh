#!/bin/bash

# Generate Dart gRPC code from protobuf definitions

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Generating gRPC Dart code...${NC}"

# Create directories if they don't exist
mkdir -p lib/generated/grpc
mkdir -p lib/generated/protobuf

# Check if protoc is installed
if ! command -v protoc &> /dev/null; then
    echo "protoc is not installed. Installing..."
    
    # Detect OS and install protoc
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install protobuf
        else
            echo "Please install Homebrew and run: brew install protobuf"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y protobuf-compiler
        elif command -v yum &> /dev/null; then
            sudo yum install -y protobuf-compiler
        else
            echo "Please install protobuf-compiler manually"
            exit 1
        fi
    else
        echo "Unsupported OS. Please install protoc manually."
        exit 1
    fi
fi

# Install protoc_plugin if not installed
if ! pub global list | grep -q protoc_plugin; then
    echo "Installing protoc_plugin..."
    pub global activate protoc_plugin
fi

# Add pub global bin to PATH
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Generate Dart code from proto files
echo "Generating Dart code from proto files..."

protoc --dart_out=grpc:lib/generated/grpc \
    --proto_path=proto \
    proto/ollama.proto

echo -e "${GREEN}✅ gRPC Dart code generated successfully!${NC}"
echo "Generated files:"
echo "  - lib/generated/grpc/ollama.pb.dart"
echo "  - lib/generated/grpc/ollama.pbgrpc.dart"

echo ""
echo "You can now use the generated gRPC client in your Flutter app."
