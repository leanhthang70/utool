#!/bin/bash

# Common functions library for utool scripts
# Source this file in other scripts: source "$(dirname "$0")/common.sh"

# Save original directory
ORIGINAL_DIR="${ORIGINAL_DIR:-$(pwd)}"

# Load configuration
SCRIPT_DIR="$(dirname "$0")"
CONFIG_FILE="$SCRIPT_DIR/config.conf"

# Load config if exists
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create necessary directories with proper permissions
if [[ ! -d "$TEMP_DIR" ]]; then
    mkdir -p "$TEMP_DIR"
fi

if [[ "$LOG_TO_FILE" == "true" && ! -d "$LOG_DIR" ]]; then
    mkdir -p "$LOG_DIR"
fi

if [[ ! -d "$BACKUP_DIR" ]]; then
    mkdir -p "$BACKUP_DIR"
fi

# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Color based on level
    case "$level" in
        "ERROR") color="$RED" ;;
        "WARN") color="$YELLOW" ;;
        "INFO") color="$GREEN" ;;
        "DEBUG") color="$BLUE" ;;
        *) color="$NC" ;;
    esac
    
    # Log to console
    if [[ "$LOG_TO_CONSOLE" == "true" ]]; then
        echo -e "${color}[$timestamp] [$level] $message${NC}"
    fi
    
    # Log to file
    if [[ "$LOG_TO_FILE" == "true" ]]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_DIR/utool.log"
    fi
}

# Function to show progress
show_progress() {
    local message="$1"
    echo -e "${BLUE}⏳ $message...${NC}"
    log "INFO" "$message"
}

# Function to show success message
success() {
    local message="$1"
    echo -e "${GREEN}✅ $message${NC}"
    log "INFO" "SUCCESS: $message"
}

# Function to show warning message
warning() {
    local message="$1"
    echo -e "${YELLOW}⚠️ $message${NC}"
    log "WARN" "$message"
}

# Function to show debug message
debug() {
    local message="$1"
    if [[ "$LOG_LEVEL" == "DEBUG" ]]; then
        echo -e "${BLUE}🔍 $message${NC}"
    fi
    log "DEBUG" "$message"
}

# Function to show error and exit
error_exit() {
    local message="$1"
    echo -e "${RED}❌ $message${NC}"
    log "ERROR" "$message"
    exit 1
}

# Check if script is run as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error_exit "This script should not be run as root"
    fi
}

# Check if script is run with sudo
check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run with sudo privileges"
    fi
}

# Validate input (non-empty)
validate_not_empty() {
    local input="$1"
    local field_name="$2"
    
    if [[ -z "$input" ]]; then
        error_exit "$field_name cannot be empty"
    fi
}

# Validate user exists
validate_user_exists() {
    local username="$1"
    
    if ! id "$username" &>/dev/null; then
        error_exit "User '$username' does not exist"
    fi
}

# Validate file exists
validate_file_exists() {
    local filepath="$1"
    
    if [[ ! -f "$filepath" ]]; then
        error_exit "File '$filepath' does not exist"
    fi
}

# Validate directory exists
validate_dir_exists() {
    local dirpath="$1"
    
    if [[ ! -d "$dirpath" ]]; then
        error_exit "Directory '$dirpath' does not exist"
    fi
}

# Create backup of file
backup_file() {
    local filepath="$1"
    local backup_suffix=$(date +"%Y%m%d_%H%M%S")
    local backup_path="$BACKUP_DIR/$(basename "$filepath")_$backup_suffix"
    
    if [[ -f "$filepath" ]]; then
        cp "$filepath" "$backup_path"
        success "Backup created: $backup_path"
    fi
}

# Prompt with default value
prompt_with_default() {
    local prompt_text="$1"
    local default_value="$2"
    local user_input
    
    read -p "$prompt_text (default: $default_value): " user_input
    echo "${user_input:-$default_value}"
}

# Prompt yes/no with default
prompt_yes_no() {
    local prompt_text="$1"
    local default_value="$2"
    local user_input
    
    while true; do
        read -p "$prompt_text (y/n, default: $default_value): " user_input
        user_input="${user_input:-$default_value}"
        
        case "$user_input" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

# Install package if not exists
install_package() {
    local package_name="$1"
    
    if ! dpkg -l | grep -q "^ii  $package_name "; then
        log "INFO" "Installing package: $package_name"
        sudo apt-get update -q
        sudo apt-get install -y "$package_name"
    else
        log "INFO" "Package $package_name is already installed"
    fi
}

# Check if service is running
is_service_running() {
    local service_name="$1"
    systemctl is-active --quiet "$service_name"
}

# Enable and start service
enable_service() {
    local service_name="$1"
    
    if [[ "$ENABLE_SYSTEMD_SERVICES" == "true" ]]; then
        sudo systemctl enable "$service_name"
        if [[ "$AUTO_START_SERVICES" == "true" ]]; then
            sudo systemctl start "$service_name"
        fi
        success "Service $service_name enabled and started"
    fi
}

# Validate IP address
validate_ip() {
    local ip="$1"
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    
    if [[ ! $ip =~ $regex ]]; then
        error_exit "Invalid IP address format: $ip"
    fi
    
    # Check each octet
    IFS='.' read -ra octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if ((octet < 0 || octet > 255)); then
            error_exit "Invalid IP address: $ip"
        fi
    done
}

# Validate domain name
validate_domain() {
    local domain="$1"
    local regex='^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$'
    
    if [[ ! $domain =~ $regex ]]; then
        error_exit "Invalid domain format: $domain"
    fi
}

# Validate email
validate_email() {
    local email="$1"
    local regex='^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    
    if [[ ! $email =~ $regex ]]; then
        error_exit "Invalid email format: $email"
    fi
}

# Show completion
show_completion() {
    local message="$1"
    echo ""
    echo -e "${GREEN}🎉 $message${NC}"
    echo ""
    log "INFO" "COMPLETED: $message"
}

# Cleanup function
cleanup() {
    debug "Cleaning up temporary files"
    rm -rf "$TEMP_DIR"/*
    
    # Return to original directory
    if [[ -n "$ORIGINAL_DIR" && -d "$ORIGINAL_DIR" ]]; then
        cd "$ORIGINAL_DIR"
        debug "Returned to original directory: $ORIGINAL_DIR"
    fi
}

# Set trap for cleanup
trap cleanup EXIT
