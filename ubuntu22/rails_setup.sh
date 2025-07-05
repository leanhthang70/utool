#!/bin/bash

# Ruby with rbenv Installation Script
# Installs Ruby version manager (rbenv) with Jemalloc for better performance

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
SCRIPT_NAME="Ruby with rbenv Installation"

# Print header
clear
echo "================================================================"
echo "       💎 $SCRIPT_NAME"
echo "================================================================"
echo "This script will install Ruby using rbenv with performance optimizations:"
echo ""
echo "📦 Components:"
echo "   • Jemalloc      - Memory allocator for better performance"
echo "   • rbenv         - Ruby version manager"
echo "   • Ruby          - Programming language (version of your choice)"
echo ""

if ! prompt_yes_no "Continue with installation?" "y"; then
    exit 0
fi

# Install Jemalloc
show_progress "Installing Jemalloc for Ruby performance optimization"
sudo apt-get update
sudo apt-get install -y libjemalloc2 libjemalloc-dev curl gnupg2 dirmngr
show_completion "Jemalloc installed"

# Install rbenv
show_progress "Installing rbenv (Ruby version manager)"
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash

# Setup rbenv in bashrc
if ! grep -q 'rbenv' ~/.bashrc; then
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc
fi

# Source bashrc and initialize rbenv
source ~/.bashrc
~/.rbenv/bin/rbenv init
eval "$(/root/.rbenv/bin/rbenv init - bash)" 2>/dev/null || eval "$(~/.rbenv/bin/rbenv init - bash)"

show_completion "rbenv installed and configured"

# Get Ruby version
echo ""
ruby_version=$(prompt_with_default "Enter Ruby version to install" "3.1.4")

echo ""
show_progress "Installing Ruby $ruby_version with Jemalloc optimization"
echo "This may take several minutes..."

# Install Ruby with Jemalloc
if RUBY_CONFIGURE_OPTS=--with-jemalloc ~/.rbenv/bin/rbenv install "$ruby_version"; then
    ~/.rbenv/bin/rbenv global "$ruby_version"
    
    show_completion "Ruby $ruby_version installed successfully"
    
    # Verify installation
    echo ""
    echo "🔍 Verification:"
    echo "Ruby path: $(which ruby)"
    echo "Ruby version: $(ruby -v)"
    echo "Jemalloc check:"
    ruby -e "p RbConfig::CONFIG['MAINLIBS']"
else
    error_exit "Failed to install Ruby $ruby_version"
fi

# Return to original directory
if [[ -n "$ORIGINAL_DIR" && -d "$ORIGINAL_DIR" ]]; then
    cd "$ORIGINAL_DIR"
    echo "Returned to original directory: $ORIGINAL_DIR"
fi
