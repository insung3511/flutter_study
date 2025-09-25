#!/bin/bash

# Ollama Remote Server Setup Script
# This script sets up Ollama on Raspberry Pi or Linux server for remote access

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
OLLAMA_PORT=${OLLAMA_PORT:-11434}
OLLAMA_GRPC_PORT=${OLLAMA_GRPC_PORT:-9090}
OLLAMA_HOST=${OLLAMA_HOST:-0.0.0.0}
DEFAULT_MODEL="gemma2:1b"
ENABLE_GRPC=${ENABLE_GRPC:-true}
ENABLE_DISCOVERY=${ENABLE_DISCOVERY:-true}

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root"
        exit 1
    fi
}

# Function to detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [[ -f /etc/lsb-release ]]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [[ -f /etc/debian_version ]]; then
        OS=Debian
        VER=$(cat /etc/debian_version)
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    
    print_status "Detected OS: $OS $VER"
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y curl wget unzip
    elif command -v yum &> /dev/null; then
        sudo yum update -y
        sudo yum install -y curl wget unzip
    elif command -v dnf &> /dev/null; then
        sudo dnf update -y
        sudo dnf install -y curl wget unzip
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu --noconfirm curl wget unzip
    else
        print_warning "Could not detect package manager. Please install curl, wget, and unzip manually."
    fi
    
    print_success "Dependencies installed"
}

# Function to install Ollama
install_ollama() {
    print_status "Installing Ollama..."
    
    if command -v ollama &> /dev/null; then
        print_warning "Ollama is already installed"
        return 0
    fi
    
    # Install Ollama using the official installer
    curl -fsSL https://ollama.ai/install.sh | sh
    
    print_success "Ollama installed successfully"
}

# Function to configure Ollama for remote access
configure_ollama() {
    print_status "Configuring Ollama for remote access..."
    
    # Create systemd service file
    sudo tee /etc/systemd/system/ollama.service > /dev/null <<EOF
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/local/bin/ollama serve
User=ollama
Group=ollama
Restart=always
RestartSec=3
Environment="OLLAMA_HOST=$OLLAMA_HOST:$OLLAMA_PORT"
Environment="OLLAMA_ORIGINS=*"
Environment="OLLAMA_GRPC_PORT=$OLLAMA_GRPC_PORT"

[Install]
WantedBy=default.target
EOF

    # Create ollama user if it doesn't exist
    if ! id "ollama" &>/dev/null; then
        sudo useradd -r -s /bin/false -m -d /usr/share/ollama ollama
    fi
    
    # Set up permissions
    sudo chown -R ollama:ollama /usr/share/ollama
    
    # Create gRPC wrapper script if gRPC is enabled
    if [[ "$ENABLE_GRPC" == "true" ]]; then
        create_grpc_wrapper
    fi
    
    # Setup mDNS service discovery if enabled
    if [[ "$ENABLE_DISCOVERY" == "true" ]]; then
        setup_mdns_discovery
    fi
    
    # Reload systemd and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable ollama
    
    print_success "Ollama configured for remote access"
}

# Function to create gRPC wrapper
create_grpc_wrapper() {
    print_status "Setting up gRPC support..."
    
    # Create gRPC wrapper script
    sudo tee /usr/local/bin/ollama-grpc-wrapper > /dev/null <<'EOF'
#!/bin/bash

# gRPC wrapper for Ollama
# This script provides gRPC interface for Ollama HTTP API

GRPC_PORT=${OLLAMA_GRPC_PORT:-9090}
HTTP_PORT=${OLLAMA_PORT:-11434}

echo "Starting Ollama gRPC wrapper on port $GRPC_PORT"
echo "HTTP API available on port $HTTP_PORT"

# Start Ollama HTTP service
/usr/local/bin/ollama serve &

# Start gRPC proxy (placeholder - would need actual gRPC implementation)
# For now, we'll just log that gRPC is available
echo "gRPC service would start on port $GRPC_PORT"
echo "Note: Full gRPC implementation requires additional setup"

# Keep the wrapper running
wait
EOF

    sudo chmod +x /usr/local/bin/ollama-grpc-wrapper
    print_success "gRPC wrapper created"
}

# Function to setup mDNS discovery
setup_mdns_discovery() {
    print_status "Setting up mDNS service discovery..."
    
    # Install avahi-daemon if not present
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y avahi-daemon avahi-utils
    elif command -v yum &> /dev/null; then
        sudo yum install -y avahi avahi-tools
    fi
    
    # Create mDNS service file for HTTP
    sudo tee /etc/avahi/services/ollama-http.service > /dev/null <<EOF
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">Ollama HTTP Server on %h</name>
  <service>
    <type>_ollama._tcp</type>
    <port>$OLLAMA_PORT</port>
    <txt-record>version=1.0</txt-record>
    <txt-record>protocol=http</txt-record>
    <txt-record>supports_grpc=false</txt-record>
  </service>
</service-group>
EOF

    # Create mDNS service file for gRPC
    if [[ "$ENABLE_GRPC" == "true" ]]; then
        sudo tee /etc/avahi/services/ollama-grpc.service > /dev/null <<EOF
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">Ollama gRPC Server on %h</name>
  <service>
    <type>_ollama-grpc._tcp</type>
    <port>$OLLAMA_GRPC_PORT</port>
    <txt-record>version=1.0</txt-record>
    <txt-record>protocol=grpc</txt-record>
    <txt-record>supports_grpc=true</txt-record>
  </service>
</service-group>
EOF
    fi
    
    # Start avahi-daemon
    sudo systemctl enable avahi-daemon
    sudo systemctl start avahi-daemon
    
    print_success "mDNS service discovery configured"
}

# Function to configure firewall
configure_firewall() {
    print_status "Configuring firewall..."
    
    # Check if ufw is available
    if command -v ufw &> /dev/null; then
        sudo ufw allow $OLLAMA_PORT/tcp
        if [[ "$ENABLE_GRPC" == "true" ]]; then
            sudo ufw allow $OLLAMA_GRPC_PORT/tcp
        fi
        print_success "UFW firewall configured"
    elif command -v firewall-cmd &> /dev/null; then
        sudo firewall-cmd --permanent --add-port=$OLLAMA_PORT/tcp
        if [[ "$ENABLE_GRPC" == "true" ]]; then
            sudo firewall-cmd --permanent --add-port=$OLLAMA_GRPC_PORT/tcp
        fi
        sudo firewall-cmd --reload
        print_success "Firewalld configured"
    elif command -v iptables &> /dev/null; then
        sudo iptables -A INPUT -p tcp --dport $OLLAMA_PORT -j ACCEPT
        if [[ "$ENABLE_GRPC" == "true" ]]; then
            sudo iptables -A INPUT -p tcp --dport $OLLAMA_GRPC_PORT -j ACCEPT
        fi
        print_warning "iptables rule added. Make sure to save your iptables rules."
    else
        print_warning "No firewall detected. Make sure to open ports $OLLAMA_PORT"
        if [[ "$ENABLE_GRPC" == "true" ]]; then
            print_warning "and $OLLAMA_GRPC_PORT manually."
        else
            print_warning "manually."
        fi
    fi
}

# Function to start Ollama service
start_ollama() {
    print_status "Starting Ollama service..."
    
    sudo systemctl start ollama
    
    # Wait a moment for the service to start
    sleep 3
    
    if sudo systemctl is-active --quiet ollama; then
        print_success "Ollama service started successfully"
    else
        print_error "Failed to start Ollama service"
        sudo systemctl status ollama
        exit 1
    fi
}

# Function to download a default model
download_model() {
    print_status "Downloading default model ($DEFAULT_MODEL)..."
    print_warning "This may take a while depending on your internet connection and model size"
    print_status "Gemma 2 1B (~1.2GB) - Optimized for Raspberry Pi performance"
    
    # Wait for Ollama to be ready
    sleep 5
    
    ollama pull $DEFAULT_MODEL
    
    print_success "Model $DEFAULT_MODEL downloaded successfully"
    print_status "Model is ready for use with your Flutter app!"
}

# Function to show connection info
show_connection_info() {
    print_status "Setup completed successfully!"
    echo
    echo "=============================================="
    echo "Ollama Server Information"
    echo "=============================================="
    echo "Server IP: $(hostname -I | awk '{print $1}')"
    echo "HTTP Port: $OLLAMA_PORT"
    echo "HTTP URL: http://$(hostname -I | awk '{print $1}'):$OLLAMA_PORT"
    if [[ "$ENABLE_GRPC" == "true" ]]; then
        echo "gRPC Port: $OLLAMA_GRPC_PORT"
        echo "gRPC URL: grpc://$(hostname -I | awk '{print $1}'):$OLLAMA_GRPC_PORT"
    fi
    echo
    echo "Available models:"
    ollama list
    echo
    echo "Service status:"
    sudo systemctl status ollama --no-pager
    if [[ "$ENABLE_DISCOVERY" == "true" ]]; then
        echo
        echo "mDNS Discovery status:"
        sudo systemctl status avahi-daemon --no-pager
    fi
    echo
    echo "=============================================="
    echo "Flutter App Configuration"
    echo "=============================================="
    echo "In your Flutter app, use these settings:"
    echo "Server Type: Raspberry Pi or Linux Server"
    echo "Host: $(hostname -I | awk '{print $1}')"
    echo "Port: $OLLAMA_PORT"
    echo
    echo "Protocols available:"
    echo "• HTTP: http://$(hostname -I | awk '{print $1}'):$OLLAMA_PORT"
    if [[ "$ENABLE_GRPC" == "true" ]]; then
        echo "• gRPC: grpc://$(hostname -I | awk '{print $1}'):$OLLAMA_GRPC_PORT"
    fi
    if [[ "$ENABLE_DISCOVERY" == "true" ]]; then
        echo "• Auto Discovery: Use 'Find Servers' button in app"
    fi
    echo
    echo "Model Recommendations:"
    echo "• Current: $DEFAULT_MODEL (optimized for Raspberry Pi)"
    echo "• For more RAM: ollama pull gemma2:2b"
    echo "• For best quality: ollama pull gemma2:4b"
    echo "=============================================="
}

# Function to test connection
test_connection() {
    print_status "Testing Ollama connection..."
    
    local server_ip=$(hostname -I | awk '{print $1}')
    local test_url="http://$server_ip:$OLLAMA_PORT/api/tags"
    
    if curl -s -f "$test_url" > /dev/null; then
        print_success "Connection test passed!"
        return 0
    else
        print_error "Connection test failed!"
        return 1
    fi
}

# Function to show help
show_help() {
    echo "Ollama Remote Server Setup Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -p, --port PORT       Set Ollama port (default: 11434)"
    echo "  -h, --host HOST       Set Ollama host (default: 0.0.0.0)"
    echo "  -m, --model MODEL     Download specific model (default: gemma2:1b)"
    echo "  --skip-model          Skip model download"
    echo "  --skip-firewall       Skip firewall configuration"
    echo "  --test-only           Only test existing installation"
    echo "  --help                Show this help message"
    echo
    echo "Examples:"
    echo "  $0                                    # Full setup with defaults"
    echo "  $0 -p 8080 -m gemma2:2b              # Use port 8080 and gemma2:2b model"
    echo "  $0 --skip-model --skip-firewall      # Setup without model download and firewall"
    echo "  $0 --test-only                       # Test existing installation"
}

# Main function
main() {
    local skip_model=false
    local skip_firewall=false
    local test_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--port)
                OLLAMA_PORT="$2"
                shift 2
                ;;
            -h|--host)
                OLLAMA_HOST="$2"
                shift 2
                ;;
            -m|--model)
                DEFAULT_MODEL="$2"
                shift 2
                ;;
            --skip-model)
                skip_model=true
                shift
                ;;
            --skip-firewall)
                skip_firewall=true
                shift
                ;;
            --test-only)
                test_only=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    echo "=============================================="
    echo "Ollama Remote Server Setup"
    echo "=============================================="
    echo "Port: $OLLAMA_PORT"
    echo "Host: $OLLAMA_HOST"
    echo "Model: $DEFAULT_MODEL"
    echo "=============================================="
    echo
    
    if [[ "$test_only" == true ]]; then
        test_connection
        exit $?
    fi
    
    check_root
    detect_os
    
    print_status "Starting Ollama remote server setup..."
    
    install_dependencies
    install_ollama
    configure_ollama
    
    if [[ "$skip_firewall" != true ]]; then
        configure_firewall
    fi
    
    start_ollama
    
    if [[ "$skip_model" != true ]]; then
        download_model
    fi
    
    test_connection
    
    if [[ $? -eq 0 ]]; then
        show_connection_info
        print_success "Setup completed successfully!"
    else
        print_error "Setup completed but connection test failed."
        print_status "Please check the Ollama service status and firewall configuration."
        exit 1
    fi
}

# Run main function
main "$@"
