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
echo "   • NVM + Node.js LTS (version manager)"
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

# Node.js installation via NVM
echo ""
echo "🟢 Node.js Installation (via NVM):"
echo "   Node Version Manager for easy version switching"
echo ""
if prompt_yes_no "Do you want to install NVM and Node.js?" "y"; then
    # Install NVM
    show_progress "Installing NVM (Node Version Manager)"
    
    # Download and install NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    
    # Export NVM for current session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    # Add NVM to bashrc if not already there
    if ! grep -q "NVM_DIR" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# NVM (Node Version Manager)" >> ~/.bashrc
        echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc
        echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc
    fi
    
    show_completion "NVM installed successfully"
    
    # Install latest LTS Node.js
    node_version=$(prompt_with_default "Node.js version to install (use 'lts' for latest LTS)" "lts")
    
    show_progress "Installing Node.js $node_version via NVM"
    
    # Source NVM and install Node.js
    source ~/.bashrc
    nvm install "$node_version"
    nvm use "$node_version"
    nvm alias default "$node_version"
    
    show_completion "Node.js installed successfully via NVM"
    echo "Node.js version: $(node --version)"
    echo "npm version: $(npm --version)"
    echo "NVM version: $(nvm --version)"
    
    # Update npm to latest version
    show_progress "Updating npm to latest version"
    npm install -g npm@latest
    echo "Updated npm version: $(npm --version)"
    
    echo ""
    echo "📋 NVM Usage Commands:"
    echo "   • nvm list                    - List installed Node.js versions"
    echo "   • nvm install <version>       - Install a specific Node.js version"
    echo "   • nvm use <version>          - Switch to a specific version"
    echo "   • nvm alias default <version> - Set default version"
    echo "   • nvm install --lts          - Install latest LTS version"
    echo ""
else
    log "INFO" "Skipping Node.js/NVM installation"
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
