#!/bin/bash

# Image Processing Libraries Installation Script
# Installs ImageMagick, libvips, FFmpeg and optimization tools

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
SCRIPT_NAME="Image Processing Libraries Installation"

# Print header
clear
echo "================================================================"
echo "       🖼️  $SCRIPT_NAME"
echo "================================================================"
echo "This script will install comprehensive image processing libraries:"
echo ""
echo "📦 Included Libraries:"
echo "   • libvips-dev       - High-performance image processing"
echo "   • OptipNG           - PNG optimization"
echo "   • WebP              - Modern image format support"
echo "   • MozJPEG           - Advanced JPEG encoder"
echo "   • ImageMagick       - Full-featured image manipulation"
echo "   • FFmpeg            - Video/audio processing"
echo "   • Various optimizers - advancecomp, gifsicle, jpegoptim, etc."
echo ""

if ! prompt_yes_no "Continue with installation?" "y"; then
    exit 0
fi

show_progress "Updating package list"
sudo apt update

show_progress "Installing basic image processing libraries"
install_package "libvips-dev"
install_package "optipng"
install_package "webp"

show_progress "Installing build dependencies"
sudo apt-get install -y cmake autoconf automake libtool nasm make pkg-config libpng-dev bzip2

show_progress "Installing image optimization tools"
sudo apt-get install -y advancecomp gifsicle jhead jpegoptim libjpeg-progs optipng pngcrush pngquant

show_completion "Basic libraries installed"

# MozJPEG installation
echo ""
echo "🔧 MozJPEG Advanced JPEG Encoder:"
echo "   High-quality JPEG encoder from Mozilla for better compression"
echo ""
if prompt_yes_no "Do you want to install MozJPEG?" "y"; then
    show_progress "Installing MozJPEG from source"
    
    cd /tmp
    if [[ -d "mozjpeg" ]]; then
        sudo rm -rf mozjpeg
    fi
    
    git clone https://github.com/mozilla/mozjpeg.git
    cd mozjpeg
    mkdir build && cd build
    sudo cmake -G "Unix Makefiles" ../
    sudo make install
    
    cd "$ORIGINAL_DIR"
    show_completion "MozJPEG installed successfully"
else
    log "INFO" "Skipping MozJPEG installation"
fi

# ImageMagick and FFmpeg
echo ""
echo "🖼️  ImageMagick & FFmpeg Installation:"
echo "   • ImageMagick - Full-featured image manipulation suite"
echo "   • FFmpeg      - Multimedia framework for video/audio processing"
echo ""
if prompt_yes_no "Do you want to install ImageMagick and FFmpeg?" "y"; then
    show_progress "Installing ImageMagick"
    install_package "imagemagick"
    
    show_progress "Installing FFmpeg"
    install_package "ffmpeg"
    
    show_completion "ImageMagick and FFmpeg installed successfully"
else
    log "INFO" "Skipping ImageMagick and FFmpeg installation"
fi
cd

# Return to original directory
if [[ -n "$ORIGINAL_DIR" && -d "$ORIGINAL_DIR" ]]; then
    cd "$ORIGINAL_DIR"
    echo "Returned to original directory: $ORIGINAL_DIR"
fi
