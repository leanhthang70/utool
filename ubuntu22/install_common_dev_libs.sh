#!/bin/bash

# Common Development Libraries Installation Script
# Installs essential development tools for Ruby, Node.js and other frameworks

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
SCRIPT_NAME="Common Development Libraries Installation"

# Print header
clear
echo "================================================================"
echo "       💎 $SCRIPT_NAME"
echo "================================================================"
echo "This script will install essential development libraries:"
echo ""
echo "📦 Core Development Tools:"
echo "   • Ruby compilation dependencies"
echo "   • Build tools (gcc, make, autoconf, etc.)"
echo "   • SSL, YAML, SQLite, XML libraries"
echo "   • Node.js (optional)"
echo "   • wkhtmltopdf (optional)"
echo "   • Redis server (optional)"
echo ""

if ! prompt_yes_no "Continue with installation?" "y"; then
    exit 0
fi

show_progress "Installing Ruby compilation dependencies"
sudo apt-get update
sudo apt-get install -y git-core curl zlib1g-dev build-essential autoconf bison \
    libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev \
    libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev
show_completion "Ruby dependencies installed"

# Node.js installation
echo ""
echo "🟢 Node.js Installation:"
echo "   Modern JavaScript runtime for web development"
echo ""
if prompt_yes_no "Do you want to install Node.js?" "y"; then
    node_version=$(prompt_with_default "Node.js version to install" "18.x")
    
    show_progress "Installing Node.js $node_version"
    curl -sL "https://deb.nodesource.com/setup_$node_version" | sudo -E bash -
    install_package "nodejs"
    
    show_completion "Node.js $node_version installed successfully"
    node --version
    npm --version
else
    log "INFO" "Skipping Node.js installation"
fi

# wkhtmltopdf installation
echo ""
echo "📄 wkhtmltopdf Installation:"
echo "   Tool for rendering HTML to PDF and images"
echo ""
if prompt_yes_no "Do you want to install wkhtmltopdf?" "y"; then
    show_progress "Installing wkhtmltopdf"
    install_package "wkhtmltopdf"
    
    show_completion "wkhtmltopdf installed successfully"
    wkhtmltopdf --version
else
    log "INFO" "Skipping wkhtmltopdf installation"
fi

# Redis installation
echo ""
echo "🔄 Redis Server Installation:"
echo "   In-memory data structure store, used as database and cache"
echo ""
if prompt_yes_no "Do you want to install Redis?" "y"; then
    show_progress "Installing Redis server"
    install_package "redis-server"
    
    show_progress "Starting and enabling Redis service"
    enable_service "redis-server"
    
    show_completion "Redis server installed and started"
    redis-cli --version
else
    log "INFO" "Skipping Redis installation"
fi

echo ""
echo "✅ Development libraries installation completed!"

# Return to original directory
if [[ -n "$ORIGINAL_DIR" && -d "$ORIGINAL_DIR" ]]; then
    cd "$ORIGINAL_DIR"
    echo "Returned to original directory: $ORIGINAL_DIR"
fi
