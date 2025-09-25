#!/bin/bash

# Ollama Troubleshooting Script for Raspberry Pi
# This script helps diagnose and fix common Ollama issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
OLLAMA_PORT=${OLLAMA_PORT:-11434}
OLLAMA_USER="ollama"

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

print_header() {
    echo "=============================================="
    echo -e "${BLUE}$1${NC}"
    echo "=============================================="
}

# Function to check system resources
check_system_resources() {
    print_header "System Resources Check"
    
    # Check RAM
    local total_ram=$(free -h | awk '/^Mem:/ {print $2}')
    local available_ram=$(free -h | awk '/^Mem:/ {print $7}')
    local used_ram=$(free -h | awk '/^Mem:/ {print $3}')
    
    print_status "Total RAM: $total_ram"
    print_status "Available RAM: $available_ram"
    print_status "Used RAM: $used_ram"
    
    # Check disk space
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    local disk_free=$(df -h / | awk 'NR==2 {print $4}')
    
    print_status "Disk usage: $disk_usage%"
    print_status "Free disk space: $disk_free"
    
    if [ "$disk_usage" -gt 90 ]; then
        print_warning "Disk usage is high ($disk_usage%). Consider freeing up space."
    fi
    
    # Check CPU temperature (if available)
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        local temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        local temp_c=$((temp / 1000))
        print_status "CPU Temperature: ${temp_c}°C"
        
        if [ "$temp_c" -gt 80 ]; then
            print_warning "CPU temperature is high (${temp_c}°C). Consider cooling."
        fi
    fi
}

# Function to check Ollama installation
check_ollama_installation() {
    print_header "Ollama Installation Check"
    
    # Check if Ollama is installed
    if command -v ollama &> /dev/null; then
        local ollama_version=$(ollama --version 2>/dev/null || echo "Unknown")
        print_success "Ollama is installed: $ollama_version"
    else
        print_error "Ollama is not installed!"
        return 1
    fi
    
    # Check Ollama binary location
    local ollama_path=$(which ollama)
    print_status "Ollama binary: $ollama_path"
    
    # Check Ollama user
    if id "$OLLAMA_USER" &>/dev/null; then
        print_success "Ollama user exists: $OLLAMA_USER"
    else
        print_warning "Ollama user does not exist"
    fi
    
    # Check Ollama directory
    if [ -d "/usr/share/ollama" ]; then
        print_success "Ollama directory exists: /usr/share/ollama"
        local dir_size=$(du -sh /usr/share/ollama 2>/dev/null | cut -f1 || echo "Unknown")
        print_status "Directory size: $dir_size"
    else
        print_warning "Ollama directory does not exist"
    fi
}

# Function to check Ollama service
check_ollama_service() {
    print_header "Ollama Service Check"
    
    # Check if service exists
    if systemctl list-unit-files | grep -q "ollama.service"; then
        print_success "Ollama systemd service exists"
    else
        print_error "Ollama systemd service does not exist!"
        return 1
    fi
    
    # Check service status
    local service_status=$(systemctl is-active ollama 2>/dev/null || echo "inactive")
    print_status "Service status: $service_status"
    
    if [ "$service_status" = "active" ]; then
        print_success "Ollama service is running"
    else
        print_error "Ollama service is not running!"
        print_status "Attempting to start service..."
        sudo systemctl start ollama
        sleep 3
        
        local new_status=$(systemctl is-active ollama 2>/dev/null || echo "inactive")
        if [ "$new_status" = "active" ]; then
            print_success "Service started successfully"
        else
            print_error "Failed to start service"
        fi
    fi
    
    # Check service logs
    print_status "Recent service logs:"
    sudo journalctl -u ollama --no-pager -n 10
}

# Function to check network connectivity
check_network_connectivity() {
    print_header "Network Connectivity Check"
    
    # Check if port is listening
    if netstat -tlnp 2>/dev/null | grep -q ":$OLLAMA_PORT "; then
        print_success "Port $OLLAMA_PORT is listening"
        
        # Check which interface it's listening on
        local listening_interface=$(netstat -tlnp 2>/dev/null | grep ":$OLLAMA_PORT " | awk '{print $4}')
        print_status "Listening on: $listening_interface"
        
        # Check if it's listening on all interfaces (0.0.0.0)
        if echo "$listening_interface" | grep -q "0.0.0.0"; then
            print_success "Ollama is accessible from remote hosts"
        else
            print_warning "Ollama is only listening on specific interface"
        fi
    else
        print_error "Port $OLLAMA_PORT is not listening!"
        return 1
    fi
    
    # Test localhost connection
    print_status "Testing localhost connection..."
    if curl -s -f "http://localhost:$OLLAMA_PORT/api/tags" > /dev/null 2>&1; then
        print_success "Localhost connection successful"
    else
        print_error "Localhost connection failed!"
        return 1
    fi
    
    # Test remote connection
    local server_ip=$(hostname -I | awk '{print $1}')
    print_status "Testing remote connection ($server_ip:$OLLAMA_PORT)..."
    if curl -s -f "http://$server_ip:$OLLAMA_PORT/api/tags" > /dev/null 2>&1; then
        print_success "Remote connection successful"
    else
        print_warning "Remote connection failed - this may be normal if firewall is blocking"
    fi
}

# Function to check models
check_models() {
    print_header "Models Check"
    
    # Check available models
    print_status "Checking available models..."
    local models_response=$(curl -s "http://localhost:$OLLAMA_PORT/api/tags" 2>/dev/null || echo "")
    
    if [ -n "$models_response" ]; then
        print_success "Successfully retrieved models list"
        
        # Parse models from JSON response
        local models=$(echo "$models_response" | grep -o '"name":"[^"]*"' | sed 's/"name":"//g' | sed 's/"//g' | tr '\n' ' ')
        
        if [ -n "$models" ]; then
            print_success "Available models: $models"
        else
            print_warning "No models found"
        fi
    else
        print_error "Failed to retrieve models list"
    fi
}

# Function to check firewall
check_firewall() {
    print_header "Firewall Check"
    
    # Check if ufw is active
    if command -v ufw &> /dev/null; then
        local ufw_status=$(ufw status 2>/dev/null | head -1 || echo "inactive")
        print_status "UFW status: $ufw_status"
        
        if echo "$ufw_status" | grep -q "active"; then
            print_status "Checking UFW rules for port $OLLAMA_PORT..."
            if ufw status | grep -q "$OLLAMA_PORT"; then
                print_success "UFW rule exists for port $OLLAMA_PORT"
            else
                print_warning "UFW rule missing for port $OLLAMA_PORT"
                print_status "To fix: sudo ufw allow $OLLAMA_PORT/tcp"
            fi
        fi
    fi
    
    # Check if firewalld is active
    if command -v firewall-cmd &> /dev/null; then
        if firewall-cmd --state &>/dev/null; then
            print_status "Firewalld is active"
            if firewall-cmd --list-ports | grep -q "$OLLAMA_PORT"; then
                print_success "Firewalld rule exists for port $OLLAMA_PORT"
            else
                print_warning "Firewalld rule missing for port $OLLAMA_PORT"
                print_status "To fix: sudo firewall-cmd --permanent --add-port=$OLLAMA_PORT/tcp && sudo firewall-cmd --reload"
            fi
        fi
    fi
}

# Function to provide recommendations
provide_recommendations() {
    print_header "Recommendations"
    
    print_status "For Raspberry Pi 4 (4GB RAM):"
    echo "  • Use gemma2:1b model (recommended)"
    echo "  • Limit concurrent requests to 1"
    echo "  • Enable swap if needed"
    
    print_status "For Raspberry Pi 4 (8GB RAM):"
    echo "  • Use gemma2:2b or gemma2:4b models"
    echo "  • Can handle more concurrent requests"
    
    print_status "Performance optimization:"
    echo "  • Use SSD instead of SD card for better I/O"
    echo "  • Ensure adequate cooling"
    echo "  • Close unnecessary services"
    
    print_status "Network optimization:"
    echo "  • Use wired connection instead of WiFi"
    echo "  • Ensure stable power supply"
    echo "  • Monitor system resources"
}

# Function to fix common issues
fix_common_issues() {
    print_header "Fixing Common Issues"
    
    # Fix service permissions
    print_status "Fixing service permissions..."
    sudo chown -R ollama:ollama /usr/share/ollama 2>/dev/null || true
    
    # Restart service
    print_status "Restarting Ollama service..."
    sudo systemctl restart ollama
    sleep 5
    
    # Check if service is running
    local service_status=$(systemctl is-active ollama 2>/dev/null || echo "inactive")
    if [ "$service_status" = "active" ]; then
        print_success "Service restarted successfully"
    else
        print_error "Service failed to restart"
        print_status "Checking service logs..."
        sudo journalctl -u ollama --no-pager -n 20
    fi
}

# Main function
main() {
    print_header "Ollama Troubleshooting Script"
    echo "This script will diagnose common Ollama issues on Raspberry Pi"
    echo
    
    # Run all checks
    check_system_resources
    echo
    
    check_ollama_installation
    echo
    
    check_ollama_service
    echo
    
    check_network_connectivity
    echo
    
    check_models
    echo
    
    check_firewall
    echo
    
    provide_recommendations
    echo
    
    # Ask if user wants to fix issues
    echo
    read -p "Do you want to attempt to fix common issues? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        fix_common_issues
    fi
    
    echo
    print_header "Troubleshooting Complete"
    print_status "If issues persist, check the error logs in your Flutter app"
    print_status "or run: sudo journalctl -u ollama -f"
}

# Run main function
main "$@"
