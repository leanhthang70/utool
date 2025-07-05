#!/bin/bash

# Enhanced Docker Installation Script
# This script provides flexible Docker installation with proper error handling and logging

# Save original directory
ORIGINAL_DIR="$(pwd)"
export ORIGINAL_DIR

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions with error checking
COMMON_FILE="$SCRIPT_DIR/common.sh"
if [[ -f "$COMMON_FILE" ]]; then
    source "$COMMON_FILE"
else
    echo "Error: Cannot find common.sh at $COMMON_FILE"
    echo "Current directory: $(pwd)"
    echo "Script directory: $SCRIPT_DIR"
    exit 1
fi

# Script configuration
SCRIPT_NAME="Docker Installation"
DOCKER_COMPOSE_VERSION="2.21.0"

# Print header
echo "================================================================"
echo "              🐳 $SCRIPT_NAME"
echo "================================================================"
log "INFO" "Starting Docker installation process"

# Function to remove old Docker packages
remove_old_docker() {
    show_progress "Removing old Docker packages"
    
    local packages=("docker.io" "docker-doc" "docker-compose" "docker-compose-v2" "podman-docker" "containerd" "runc")
    
    for pkg in "${packages[@]}"; do
        if dpkg -l | grep -q "^ii  $pkg "; then
            log "INFO" "Removing package: $pkg"
            sudo apt-get remove -y "$pkg"
        fi
    done
    
    show_completion "Old Docker packages removed"
}

# Function to install Docker dependencies
install_dependencies() {
    show_progress "Installing Docker dependencies"
    
    sudo apt-get update -q
    install_package "ca-certificates"
    install_package "curl"
    install_package "gnupg"
    install_package "lsb-release"
    
    show_completion "Dependencies installed"
}

# Function to add Docker GPG key
add_docker_gpg_key() {
    show_progress "Adding Docker GPG key"
    
    # Create keyrings directory
    sudo install -m 0755 -d /etc/apt/keyrings
    
    # Download and add GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    show_completion "Docker GPG key added"
}

# Function to add Docker repository
add_docker_repository() {
    show_progress "Adding Docker repository"
    
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt-get update -q
    
    show_completion "Docker repository added"
}

# Function to install Docker Engine
install_docker_engine() {
    show_progress "Installing Docker Engine"
    
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    show_completion "Docker Engine installed"
}

# Function to configure Docker for user
configure_docker_user() {
    local username="$1"
    
    show_progress "Configuring Docker for user: $username"
    
    # Validate user exists
    validate_user_exists "$username"
    
    # Add user to docker group
    sudo usermod -aG docker "$username"
    sudo gpasswd -a "$username" docker
    
    show_completion "Docker configured for user: $username"
}

# Function to configure Docker daemon
configure_docker_daemon() {
    show_progress "Configuring Docker daemon"
    
    # Enable and start Docker service
    enable_service "docker"
    
    # Set proper permissions
    sudo chmod 666 /var/run/docker.sock
    
    # Create Docker daemon configuration
    local daemon_config='{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}'
    
    if prompt_yes_no "Do you want to configure Docker daemon with optimized settings?" "y"; then
        echo "$daemon_config" | sudo tee /etc/docker/daemon.json > /dev/null
        sudo systemctl restart docker
        log "INFO" "Docker daemon configured with optimized settings"
    fi
    
    show_completion "Docker daemon configured"
}

# Function to install Docker Compose standalone (optional)
install_docker_compose_standalone() {
    if prompt_yes_no "Do you want to install Docker Compose standalone?" "n"; then
        show_progress "Installing Docker Compose standalone"
        
        local compose_url="https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)"
        
        sudo curl -L "$compose_url" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        
        # Create symlink for compatibility
        sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
        
        show_completion "Docker Compose standalone installed"
    fi
}

# Function to verify installation
verify_installation() {
    show_progress "Verifying Docker installation"
    
    # Check Docker version
    if docker --version; then
        log "INFO" "Docker version: $(docker --version)"
    else
        error_exit "Docker installation verification failed"
    fi
    
    # Check Docker Compose version
    if docker compose version; then
        log "INFO" "Docker Compose version: $(docker compose version)"
    else
        warning "Docker Compose plugin not available"
    fi
    
    # Check Docker service status
    if is_service_running "docker"; then
        log "INFO" "Docker service is running"
    else
        error_exit "Docker service is not running"
    fi
    
    show_completion "Installation verified successfully"
}

# Function to show post-installation info
show_post_installation_info() {
    echo ""
    echo "================================================================"
    echo "            🎉 Docker Installation Complete!"
    echo "================================================================"
    echo ""
    echo "📋 Next Steps:"
    echo "   1. Log out and log back in for group changes to take effect"
    echo "   2. Test Docker: docker run hello-world"
    echo "   3. Check Docker status: systemctl status docker"
    echo ""
    echo "📖 Useful Commands:"
    echo "   • docker --version              - Check Docker version"
    echo "   • docker compose version        - Check Docker Compose version"
    echo "   • docker info                   - Show Docker system info"
    echo "   • docker ps                     - List running containers"
    echo "   • docker images                 - List Docker images"
    echo ""
    echo "🔧 Configuration Files:"
    echo "   • Docker daemon: /etc/docker/daemon.json"
    echo "   • Docker service: /etc/systemd/system/docker.service"
    echo ""
    echo "📚 Documentation: https://docs.docker.com/"
    echo "================================================================"
}

# Main installation function
main() {
    # Get user input
    local user_docker_app
    user_docker_app=$(prompt_with_default "Enter username for Docker access" "$DEFAULT_USER")
    
    # Validate input
    validate_not_empty "$user_docker_app" "Username"
    
    # Check if running with appropriate privileges
    if [[ $EUID -eq 0 ]]; then
        warning "Running as root. Consider running as regular user with sudo."
    fi
    
    # Confirm installation
    if ! prompt_yes_no "Proceed with Docker installation?" "y"; then
        log "INFO" "Installation cancelled by user"
        exit 0
    fi
    
    # Installation steps
    remove_old_docker
    install_dependencies
    add_docker_gpg_key
    add_docker_repository
    install_docker_engine
    configure_docker_user "$user_docker_app"
    configure_docker_daemon
    install_docker_compose_standalone
    verify_installation
    show_post_installation_info
    
    success "Docker installation completed successfully for user: $user_docker_app"
}

# Run main function
main "$@"
