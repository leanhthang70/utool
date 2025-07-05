#!/bin/bash

# Development Environment Setup Script
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

# --- Configuration & Colors ---
SCRIPT_NAME="Development Environment Setup"
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Helper Functions ---
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}


# --- Installation Functions ---

function install_core_deps() {
    show_progress "Installing core Ruby development dependencies"
    
    # Update package lists first
    if ! sudo apt-get update; then
        error "Failed to update package lists"
        return 1
    fi
    
    # Install core packages for Ruby and general development
    if sudo apt-get install -y \
        git-core curl wget \
        zlib1g-dev build-essential autoconf automake bison \
        libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 \
        libxml2-dev libxslt1-dev libcurl4-openssl-dev \
        software-properties-common libffi-dev \
        ca-certificates gnupg lsb-release \
        pkg-config libtool nasm cmake \
        libpq-dev libmysqlclient-dev \
        imagemagick libmagickwand-dev \
        libgmp-dev libncurses5-dev libgdbm-dev libgdbm-compat-dev \
        libjemalloc2 libjemalloc-dev; then
        show_completion "Core development dependencies installed successfully"
        return 0
    else
        error "Failed to install core dependencies"
        return 1
    fi
}

function install_nodejs() {
    local node_version
    node_version=$(prompt_with_default "Which Node.js version to install" "18.x")
    
    show_progress "Setting up Node.js $node_version repository"
    if ! curl -sL "https://deb.nodesource.com/setup_$node_version" | sudo -E bash -; then
        error "Failed to setup Node.js repository"
        return 1
    fi
    
    show_progress "Installing Node.js $node_version"
    if install_package "nodejs"; then
        show_completion "Node.js $node_version installed successfully"
        echo "   Node.js version: $(node --version 2>/dev/null || echo 'Error getting version')"
        echo "   npm version: $(npm --version 2>/dev/null || echo 'Error getting version')"
        return 0
    else
        error "Failed to install Node.js"
        return 1
    fi
}

function install_wkhtmltopdf() {
    show_progress "Installing wkhtmltopdf"
    
    if install_package "wkhtmltopdf"; then
        show_completion "wkhtmltopdf installed successfully"
        echo "   Version: $(wkhtmltopdf --version 2>/dev/null | head -1 || echo 'Error getting version')"
        return 0
    else
        error "Failed to install wkhtmltopdf"
        return 1
    fi
}

function install_yarn() {
    show_progress "Installing Yarn package manager"
    
    # Add Yarn repository
    if ! curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -; then
        error "Failed to add Yarn GPG key"
        return 1
    fi
    
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    
    if ! sudo apt-get update; then
        error "Failed to update package lists for Yarn"
        return 1
    fi
    
    if install_package "yarn"; then
        show_completion "Yarn package manager installed successfully"
        echo "   Yarn version: $(yarn --version 2>/dev/null || echo 'Error getting version')"
        return 0
    else
        error "Failed to install Yarn"
        return 1
    fi
}

function install_postgresql_client() {
    show_progress "Installing PostgreSQL client libraries"
    
    if sudo apt-get install -y postgresql-client libpq-dev; then
        show_completion "PostgreSQL client installed successfully"
        echo "   psql version: $(psql --version 2>/dev/null || echo 'Error getting version')"
        return 0
    else
        error "Failed to install PostgreSQL client"
        return 1
    fi
}

function install_mysql_client() {
    show_progress "Installing MySQL/MariaDB client libraries"
    
    if sudo apt-get install -y mysql-client libmysqlclient-dev default-libmysqlclient-dev; then
        show_completion "MySQL client installed successfully"
        echo "   mysql version: $(mysql --version 2>/dev/null || echo 'Error getting version')"
        return 0
    else
        error "Failed to install MySQL client"
        return 1
    fi
}

function install_python_dev() {
    show_progress "Installing Python development tools"
    
    if sudo apt-get install -y python3 python3-pip python3-dev python3-venv; then
        show_completion "Python development tools installed successfully"
        echo "   Python version: $(python3 --version 2>/dev/null || echo 'Error getting version')"
        echo "   pip version: $(pip3 --version 2>/dev/null || echo 'Error getting version')"
        return 0
    else
        error "Failed to install Python development tools"
        return 1
    fi
}

function install_redis() {
    show_progress "Installing Redis server"
    
    if install_package "redis-server"; then
        show_progress "Configuring Redis service"
        if enable_service "redis-server"; then
            show_completion "Redis server installed and configured successfully"
            echo "   Version: $(redis-cli --version 2>/dev/null || echo 'Error getting version')"
            echo "   Service status: $(systemctl is-active redis-server 2>/dev/null || echo 'inactive')"
            return 0
        else
            warning "Redis installed but service configuration failed"
            return 1
        fi
    else
        error "Failed to install Redis server"
        return 1
    fi
}


# --- Main Script ---

clear
echo -e "${YELLOW}================================================================${NC}"
echo -e "       � $SCRIPT_NAME for Ubuntu 22.04"
echo -e "${YELLOW}================================================================${NC}"
echo "This script sets up a complete development environment with"
echo "essential libraries, tools, and optional components."
echo ""

# --- Core Dependencies (Always Required) ---
echo -e "${CYAN}📦 Core Dependencies (Essential for Ruby Development)${NC}"
echo "   • build-essential, gcc, make, cmake tools"
echo "   • Ruby compilation libraries (libssl-dev, libyaml-dev, etc.)"
echo "   • Git, cURL, wget and development utilities"
echo "   • Database client libraries (PostgreSQL, MySQL)"
echo "   • ImageMagick development libraries"
echo "   • Jemalloc memory allocator"
echo ""
if ! prompt_yes_no "Install core development libraries?" "y"; then
    print_error "Installation cancelled. Core libraries are required for Ruby development."
    exit 0
fi

# --- Optional Packages Selection ---
echo ""
echo -e "${CYAN}🔧 Optional Development Tools${NC}"
echo "Choose additional tools to install with core libraries:"
echo ""

INSTALL_NODE=false
echo -e "${YELLOW}🟢 Node.js${NC} - JavaScript runtime for modern web development"
if prompt_yes_no "   Install Node.js?" "y"; then
    INSTALL_NODE=true
fi

INSTALL_YARN=false
if [ "$INSTALL_NODE" = true ]; then
    echo -e "${YELLOW}📦 Yarn${NC} - Alternative package manager for Node.js (faster than npm)"
    if prompt_yes_no "   Install Yarn package manager?" "y"; then
        INSTALL_YARN=true
    fi
fi

INSTALL_PYTHON=false
echo -e "${YELLOW}🐍 Python${NC} - Python development tools (pip, venv, dev headers)"
if prompt_yes_no "   Install Python development tools?" "y"; then
    INSTALL_PYTHON=true
fi

INSTALL_POSTGRESQL_CLIENT=false
echo -e "${YELLOW}🐘 PostgreSQL Client${NC} - PostgreSQL client tools and libraries"
if prompt_yes_no "   Install PostgreSQL client?" "y"; then
    INSTALL_POSTGRESQL_CLIENT=true
fi

INSTALL_MYSQL_CLIENT=false
echo -e "${YELLOW}🗄️ MySQL Client${NC} - MySQL/MariaDB client tools and libraries"
if prompt_yes_no "   Install MySQL client?" "y"; then
    INSTALL_MYSQL_CLIENT=true
fi

INSTALL_WKHTMLTOPDF=false
echo -e "${YELLOW}📄 wkhtmltopdf${NC} - Convert HTML to PDF/images (useful for reports)"
if prompt_yes_no "   Install wkhtmltopdf?" "y"; then
    INSTALL_WKHTMLTOPDF=true
fi

INSTALL_REDIS=false
echo -e "${YELLOW}🔄 Redis${NC} - In-memory data store (caching, sessions, background jobs)"
if prompt_yes_no "   Install Redis server?" "y"; then
    INSTALL_REDIS=true
fi

# Option to quit
echo ""
echo -e "${YELLOW}❓ Final confirmation${NC}"
if ! prompt_yes_no "Continue with the selected installations?" "y"; then
    print_info "Installation cancelled by user. No changes were made."
    exit 0
fi

# --- Installation Summary ---
echo ""
echo -e "${GREEN}📋 Installation Summary:${NC}"
echo "================================"
echo "✅ Core development libraries"
echo "$([ "$INSTALL_NODE" = true ] && echo "✅ Node.js" || echo "❌ Node.js (skipped)")"
echo "$([ "$INSTALL_YARN" = true ] && echo "✅ Yarn package manager" || echo "❌ Yarn (skipped)")"
echo "$([ "$INSTALL_PYTHON" = true ] && echo "✅ Python development tools" || echo "❌ Python dev tools (skipped)")"
echo "$([ "$INSTALL_POSTGRESQL_CLIENT" = true ] && echo "✅ PostgreSQL client" || echo "❌ PostgreSQL client (skipped)")"
echo "$([ "$INSTALL_MYSQL_CLIENT" = true ] && echo "✅ MySQL client" || echo "❌ MySQL client (skipped)")"
echo "$([ "$INSTALL_WKHTMLTOPDF" = true ] && echo "✅ wkhtmltopdf" || echo "❌ wkhtmltopdf (skipped)")"
echo "$([ "$INSTALL_REDIS" = true ] && echo "✅ Redis server" || echo "❌ Redis server (skipped)")"
echo ""

if ! prompt_yes_no "Proceed with installation?" "y"; then
    print_info "Installation cancelled by user."
    exit 0
fi

echo ""
echo -e "${GREEN}🚀 Starting installation process...${NC}"
echo "================================================================"

# --- Execute Installations ---

# Core dependencies (always installed)
install_core_deps

# Optional packages
INSTALLED_PACKAGES=("Core development libraries")

if [ "$INSTALL_NODE" = true ]; then
    echo -e "\n${CYAN}🟢 Installing Node.js...${NC}"
    if install_nodejs; then
        INSTALLED_PACKAGES+=("Node.js")
    fi
fi

if [ "$INSTALL_YARN" = true ]; then
    echo -e "\n${CYAN}📦 Installing Yarn...${NC}"
    if install_yarn; then
        INSTALLED_PACKAGES+=("Yarn package manager")
    fi
fi

if [ "$INSTALL_PYTHON" = true ]; then
    echo -e "\n${CYAN}🐍 Installing Python development tools...${NC}"
    if install_python_dev; then
        INSTALLED_PACKAGES+=("Python development tools")
    fi
fi

if [ "$INSTALL_POSTGRESQL_CLIENT" = true ]; then
    echo -e "\n${CYAN}🐘 Installing PostgreSQL client...${NC}"
    if install_postgresql_client; then
        INSTALLED_PACKAGES+=("PostgreSQL client")
    fi
fi

if [ "$INSTALL_MYSQL_CLIENT" = true ]; then
    echo -e "\n${CYAN}🗄️ Installing MySQL client...${NC}"
    if install_mysql_client; then
        INSTALLED_PACKAGES+=("MySQL client")
    fi
fi

if [ "$INSTALL_WKHTMLTOPDF" = true ]; then
    echo -e "\n${CYAN}📄 Installing wkhtmltopdf...${NC}"
    if install_wkhtmltopdf; then
        INSTALLED_PACKAGES+=("wkhtmltopdf")
    fi
fi

if [ "$INSTALL_REDIS" = true ]; then
    echo -e "\n${CYAN}🔄 Installing Redis...${NC}"
    if install_redis; then
        INSTALLED_PACKAGES+=("Redis server")
    fi
fi

# --- Final Summary ---
echo ""
echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}🎉 Installation Complete!${NC}"
echo -e "${GREEN}================================================================${NC}"
echo ""
echo -e "${CYAN}📦 Successfully Installed:${NC}"
for package in "${INSTALLED_PACKAGES[@]}"; do
    echo "   ✅ $package"
done

echo ""
echo -e "${YELLOW}💡 Next Steps:${NC}"
echo "   • Restart your terminal or run: source ~/.bashrc"
echo "   • For Node.js: verify with 'node --version' and 'npm --version'"
echo "   • For Yarn: verify with 'yarn --version'"
echo "   • For Python: verify with 'python3 --version' and 'pip3 --version'"
echo "   • For PostgreSQL: verify with 'psql --version'"
echo "   • For MySQL: verify with 'mysql --version'"
echo "   • For Redis: check status with 'systemctl status redis-server'"
echo "   • For Ruby development: install rbenv or rvm next"
echo ""
echo -e "${BLUE}🔗 Recommended Next Scripts:${NC}"
echo "   • Run 'Rails Setup' script to install Ruby with rbenv"
echo "   • Run 'Database Setup' scripts for PostgreSQL or MySQL server"
echo "   • Run 'Image Libraries' script for advanced image processing"
echo ""

# Return to original directory
if [[ -n "$ORIGINAL_DIR" && -d "$ORIGINAL_DIR" ]]; then
    cd "$ORIGINAL_DIR"
fi
