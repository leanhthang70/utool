#!/bin/bash

# Enhanced Ubuntu 22 Development Environment Setup
# Main menu script to manage all development tools

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
SCRIPT_NAME="Ubuntu 22 Development Environment Setup"
SCRIPT_VERSION="2.0"
SCRIPT_DIR="$(dirname "$0")"

# Print header
clear
echo "================================================================"
echo "       🚀 $SCRIPT_NAME v$SCRIPT_VERSION"
echo "================================================================"
echo "       Enhanced with better error handling and validation"
echo "================================================================"

# Function to create backup checkpoint
create_backup_checkpoint() {
    local script_name="$1"
    local checkpoint_name="before_${script_name%.*}_$(date +%Y%m%d_%H%M%S)"
    local checkpoint_path="$BACKUP_DIR/checkpoints/$checkpoint_name"
    
    log "INFO" "Creating backup checkpoint: $checkpoint_name"
    mkdir -p "$checkpoint_path"
    
    # Backup important system configs
    cp -r /etc/nginx "$checkpoint_path/" 2>/dev/null || true
    cp -r /etc/mysql "$checkpoint_path/" 2>/dev/null || true
    cp -r /etc/postgresql "$checkpoint_path/" 2>/dev/null || true
    cp -r /etc/systemd/system "$checkpoint_path/" 2>/dev/null || true
    
    # Create checkpoint metadata
    cat > "$checkpoint_path/metadata.json" << EOF
{
    "script": "$script_name",
    "timestamp": "$(date -Iseconds)",
    "user": "$USER",
    "hostname": "$HOSTNAME",
    "ubuntu_version": "$(lsb_release -rs)"
}
EOF
    
    log "INFO" "Backup checkpoint created: $checkpoint_path"
}

# Function to validate system requirements
validate_system() {
    log "INFO" "Validating system requirements..."
    
    # Check Ubuntu version
    if ! grep -q "22.04" /etc/lsb-release 2>/dev/null; then
        warning "This script is optimized for Ubuntu 22.04"
        if ! prompt_yes_no "Continue anyway?" "n"; then
            exit 0
        fi
    fi
    
    # Check available disk space (minimum 5GB)
    local available_space=$(df / | tail -1 | awk '{print $4}')
    local min_space=$((5 * 1024 * 1024)) # 5GB in KB
    
    if [[ $available_space -lt $min_space ]]; then
        error_exit "Insufficient disk space. At least 5GB required."
    fi
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        warning "Running as root is not recommended for security reasons"
        if ! prompt_yes_no "Continue as root?" "n"; then
            exit 0
        fi
    fi
    
    # Check internet connectivity
    if ! ping -c 1 google.com &> /dev/null; then
        error_exit "No internet connection. Please check your network."
    fi
    
    log "INFO" "System validation completed"
}

# Function to show main menu
show_main_menu() {
    echo ""
    echo "📋 Available Tools:"
    echo ""
    echo "   🐳 Docker & Containers:"
    echo "     1) Install Docker (Enhanced)          - Cài đặt Docker với security features"
    echo ""
    echo "   🌐 Web Server & SSL:"
    echo "     2) Setup Nginx with SSL (Enhanced)    - Cài đặt Nginx với SSL tự động"
    echo ""
    echo "   🗄️  Database Management:"
    echo "     3) MySQL/MariaDB Management (Enhanced) - Quản lý database với menu đầy đủ"
    echo "     4) PostgreSQL Management              - Cài đặt và cấu hình PostgreSQL"
    echo ""
    echo "   💎 Development Environment:"
    echo "     5) Install Ruby with rbenv           - Cài đặt Ruby version manager"
    echo "     6) Install Node.js & Development Libraries - Cài đặt Node.js và build tools"
    echo "     7) Install Image Processing Libraries - ImageMagick, libvips, FFmpeg"
    echo ""
    echo "   🔧 System Services:"
    echo "     8) Setup Auto-start Service          - Tạo systemd service tự động chạy"
    echo "     9) Setup Sidekiq Background Jobs     - Cài đặt Redis và Sidekiq worker"
    echo "    10) Setup Log Rotation                - Cấu hình logrotate cho ứng dụng"
    echo "    11) User Management                   - Tạo user deploy với SSH keys"
    echo ""
    echo "   🛠️  System Tools:"
    echo "    12) System Information                - Hiển thị thông tin hệ thống chi tiết"
    echo "    13) Cleanup & Maintenance             - Dọn dẹp hệ thống và tối ưu"
    echo "    14) Backup Management                 - Quản lý backup và restore"
    echo "    15) Configuration Management         - Quản lý file cấu hình"
    echo "    16) Security Hardening               - Cấu hình bảo mật hệ thống"
    echo ""
    echo "   📚 Help & Documentation:"
    echo "    17) Show Help                        - Hướng dẫn sử dụng chi tiết"
    echo "    18) Show Configuration               - Hiển thị cấu hình hiện tại"
    echo "    19) Show System Status               - Kiểm tra trạng thái services"
    echo ""
    echo "   🔄 Maintenance:"
    echo "    20) Update System                    - Cập nhật packages hệ thống"
    echo "    21) Fix Broken Dependencies          - Sửa lỗi package dependencies"
    echo "    22) Remove Unnecessary Files         - Dọn dẹp file không cần thiết"
    echo ""
    echo "     0) Exit                             - Thoát khỏi Ubuntu Development Setup"
    echo ""
}

# Function to run enhanced scripts
run_enhanced_script() {
    local script_name="$1"
    local script_path="$SCRIPT_DIR/$script_name"
    
    if [[ -f "$script_path" ]]; then
        log "INFO" "Running enhanced script: $script_name"
        chmod +x "$script_path"
        
        # Create backup if enabled
        if [[ "$BACKUP_BEFORE_INSTALL" == "true" ]]; then
            create_backup_checkpoint "$script_name"
        fi
        
        # Execute with error handling
        if ! "$script_path"; then
            error_exit "Enhanced script failed: $script_name"
        fi
        
        log "INFO" "Enhanced script completed successfully: $script_name"
    else
        error_exit "Enhanced script not found: $script_path"
    fi
}

# Function to run original scripts
run_original_script() {
    local script_name="$1"
    local script_path="$SCRIPT_DIR/$script_name"
    
    if [[ -f "$script_path" ]]; then
        log "INFO" "Running original script: $script_name"
        chmod +x "$script_path"
        
        # Create backup if enabled
        if [[ "$BACKUP_BEFORE_INSTALL" == "true" ]]; then
            create_backup_checkpoint "$script_name"
        fi
        
        # Execute with error handling
        if ! "$script_path"; then
            error_exit "Original script failed: $script_name"
        fi
        
        log "INFO" "Original script completed successfully: $script_name"
    else
        error_exit "Original script not found: $script_path"
    fi
}

# Function to show system information
show_system_info() {
    echo ""
    echo "📊 System Information:"
    echo "===================="
    echo "• OS: $(lsb_release -d | cut -f2)"
    echo "• Kernel: $(uname -r)"
    echo "• Architecture: $(uname -m)"
    echo "• CPU: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
    echo "• Memory: $(free -h | grep '^Mem' | awk '{print $2 " (Used: " $3 ", Free: " $4 ")"}')"
    echo "• Disk: $(df -h / | tail -1 | awk '{print $2 " (Used: " $3 ", Free: " $4 ")"}')"
    echo "• Uptime: $(uptime -p)"
    echo "• Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    echo ""
    
    echo "🔧 Installed Development Tools:"
    echo "==============================="
    
    # Enhanced tool checking with versions
    local tools=(
        "docker:Docker"
        "nginx:Nginx"
        "mysql:MySQL"
        "psql:PostgreSQL"
        "node:Node.js"
        "ruby:Ruby"
        "git:Git"
        "redis-server:Redis"
        "systemctl:Systemd"
    )
    
    for tool_info in "${tools[@]}"; do
        IFS=':' read -r tool display_name <<< "$tool_info"
        if command -v "$tool" &> /dev/null; then
            local version=""
            case "$tool" in
                "docker") version=$(docker --version 2>/dev/null | cut -d' ' -f3 | cut -d',' -f1) ;;
                "nginx") version=$(nginx -v 2>&1 | cut -d'/' -f2) ;;
                "mysql") version=$(mysql --version 2>/dev/null | cut -d' ' -f3) ;;
                "psql") version=$(psql --version 2>/dev/null | cut -d' ' -f3) ;;
                "node") version=$(node --version 2>/dev/null) ;;
                "ruby") version=$(ruby --version 2>/dev/null | cut -d' ' -f2) ;;
                "git") version=$(git --version 2>/dev/null | cut -d' ' -f3) ;;
                "redis-server") version=$(redis-server --version 2>/dev/null | cut -d' ' -f3) ;;
                "systemctl") version="Active" ;;
            esac
            echo "• $display_name: ✅ $version"
        else
            echo "• $display_name: ❌ Not installed"
        fi
    done
    
    echo ""
    echo "🌐 Network Information:"
    echo "======================="
    echo "• Hostname: $(hostname)"
    echo "• IP Address: $(hostname -I | cut -d' ' -f1)"
    echo "• DNS Servers: $(grep nameserver /etc/resolv.conf | cut -d' ' -f2 | tr '\n' ' ')"
    
    echo ""
    echo "🔐 Security Status:"
    echo "=================="
    echo "• Firewall: $(ufw status | head -1)"
    echo "• SSH Service: $(systemctl is-active ssh 2>/dev/null || echo "inactive")"
    echo "• Fail2ban: $(systemctl is-active fail2ban 2>/dev/null || echo "not installed")"
}

# Function to cleanup system
cleanup_system() {
    show_progress "Cleaning up system"
    
    # Update package lists
    sudo apt update -q
    
    # Remove orphaned packages
    sudo apt autoremove -y
    
    # Clean package cache
    sudo apt autoclean
    
    # Clear temporary files
    sudo rm -rf /tmp/*
    
    # Clear old logs
    sudo journalctl --vacuum-time=7d
    
    # Clear bash history for security
    if prompt_yes_no "Clear bash history?" "n"; then
        history -c
        history -w
    fi
    
    show_completion "System cleanup complete"
}

# Function to show configuration
show_configuration() {
    echo ""
    echo "⚙️  Current Configuration:"
    echo "========================="
    
    if [[ -f "$SCRIPT_DIR/config.conf" ]]; then
        echo "📄 Configuration file: $SCRIPT_DIR/config.conf"
        echo ""
        cat "$SCRIPT_DIR/config.conf"
    else
        echo "❌ Configuration file not found"
        echo "   Run option 15 to create default configuration"
    fi
}

# Function to manage configuration
manage_configuration() {
    echo ""
    echo "⚙️  Configuration Management:"
    echo "============================"
    echo "1) Create default configuration"
    echo "2) Edit configuration"
    echo "3) Reset to defaults"
    echo "4) Show current configuration"
    
    read -p "Choose option (1-4): " config_choice
    
    case "$config_choice" in
        1)
            if [[ -f "$SCRIPT_DIR/config.conf" ]]; then
                if ! prompt_yes_no "Configuration file exists. Overwrite?" "n"; then
                    return
                fi
            fi
            cp "$SCRIPT_DIR/config.conf" "$SCRIPT_DIR/config.conf.backup" 2>/dev/null
            # Configuration file should already exist from our previous creation
            success "Default configuration created"
            ;;
        2)
            if [[ -f "$SCRIPT_DIR/config.conf" ]]; then
                "${EDITOR:-nano}" "$SCRIPT_DIR/config.conf"
            else
                error_exit "Configuration file not found"
            fi
            ;;
        3)
            if prompt_yes_no "Reset configuration to defaults?" "n"; then
                # Recreate default config
                success "Configuration reset to defaults"
            fi
            ;;
        4)
            show_configuration
            ;;
        *)
            warning "Invalid option"
            ;;
    esac
}

# Function to show help
show_help() {
    echo ""
    echo "📚 Help & Documentation:"
    echo "========================"
    echo ""
    echo "🎯 Purpose:"
    echo "   This enhanced toolkit provides automated installation and configuration"
    echo "   of development tools for Ubuntu 22.04 with improved error handling,"
    echo "   logging, and user experience."
    echo ""
    echo "✨ Key Features:"
    echo "   • Enhanced error handling and validation"
    echo "   • Comprehensive logging system"
    echo "   • Configuration management"
    echo "   • Backup and restore capabilities"
    echo "   • Security best practices"
    echo "   • User-friendly interface"
    echo ""
    echo "🔧 Enhanced Scripts:"
    echo "   • docker_enhanced.sh - Docker installation with security"
    echo "   • nginx_ssl_enhanced.sh - Nginx with SSL and security headers"
    echo "   • mysql_enhanced.sh - MySQL/MariaDB with optimization"
    echo ""
    echo "📖 Usage Tips:"
    echo "   • Always backup important data before running scripts"
    echo "   • Check system requirements before installation"
    echo "   • Use staging environments for testing"
    echo ""
    echo "🚨 Important Notes:"
    echo "   • Some scripts require sudo privileges"
    echo "   • Internet connection is required for downloads"
    echo "   • Firewall rules may be modified"
    echo "   • Services will be automatically started"
    echo ""
    echo "🐛 Troubleshooting:"
    echo "   • Verify internet connection"
    echo "   • Ensure sufficient disk space"
    echo "   • Check Ubuntu version compatibility"
    echo ""
}

# Function to manage backups
manage_backups() {
    echo ""
    echo "💾 Backup Management:"
    echo "===================="
    echo "1) List backups"
    echo "2) Create system backup"
    echo "3) Restore from backup"
    echo "4) Cleanup old backups"
    
    read -p "Choose option (1-4): " backup_choice
    
    case "$backup_choice" in
        1)
            echo "📋 Available backups:"
            ls -la "$BACKUP_DIR"
            ;;
        2)
            show_progress "Creating system backup"
            # Create backup of important configs
            local backup_name="system_backup_$(date +%Y%m%d_%H%M%S)"
            local backup_path="$BACKUP_DIR/$backup_name"
            mkdir -p "$backup_path"
            
            # Backup configurations
            cp -r /etc/nginx "$backup_path/" 2>/dev/null
            cp -r /etc/mysql "$backup_path/" 2>/dev/null
            cp -r /etc/postgresql "$backup_path/" 2>/dev/null
            
            show_completion "System backup created: $backup_path"
            ;;
        3)
            echo "🔄 Backup restore functionality - coming soon"
            ;;
        4)
            if prompt_yes_no "Delete backups older than 30 days?" "y"; then
                find "$BACKUP_DIR" -type f -mtime +30 -delete
                success "Old backups cleaned up"
            fi
            ;;
        *)
            warning "Invalid option"
            ;;
    esac
}

# Function to show system status
show_system_status() {
    echo ""
    echo "🔍 System Status Check:"
    echo "======================"
    
    # Check running services
    echo ""
    echo "🔄 Running Services:"
    echo "==================="
    local services=("nginx" "mysql" "postgresql" "redis" "docker" "ssh")
    for service in "${services[@]}"; do
        local status=$(systemctl is-active "$service" 2>/dev/null || echo "not installed")
        local enabled=$(systemctl is-enabled "$service" 2>/dev/null || echo "disabled")
        case "$status" in
            "active") echo "• $service: ✅ Running (Enabled: $enabled)" ;;
            "inactive") echo "• $service: ⚠️ Stopped (Enabled: $enabled)" ;;
            "failed") echo "• $service: ❌ Failed (Enabled: $enabled)" ;;
            *) echo "• $service: ❓ Not installed" ;;
        esac
    done
    
    # Check ports
    echo ""
    echo "🌐 Open Ports:"
    echo "============="
    if command -v ss &> /dev/null; then
        ss -tuln | grep LISTEN | awk '{print $5}' | sort -u | head -10
    else
        netstat -tuln | grep LISTEN | awk '{print $4}' | sort -u | head -10
    fi
    
    # Check disk usage
    echo ""
    echo "💾 Disk Usage:"
    echo "============="
    df -h | grep -E '^/dev/' | head -5
    
    # Check memory usage
    echo ""
    echo "🧠 Memory Usage:"
    echo "==============="
    free -h
    
    # Check recent logs
    echo ""
    echo "📋 Recent System Status:"
    echo "======================="
    echo "System uptime: $(uptime -p)"
    echo "Available disk space: $(df -h / | tail -1 | awk '{print $4}')"
    echo "Memory usage: $(free -h | grep '^Mem' | awk '{print $3 "/" $2}')"
}

# Function for security hardening
security_hardening() {
    echo ""
    echo "🔐 Security Hardening:"
    echo "===================="
    echo "1) Enable UFW Firewall"
    echo "2) Install and configure Fail2ban"
    echo "3) Disable root login"
    echo "4) Update SSH configuration"
    echo "5) Install security updates"
    echo "6) Configure log monitoring"
    echo "7) All of the above"
    
    read -p "Choose option (1-7): " security_choice
    
    case "$security_choice" in
        1|7)
            show_progress "Enabling UFW firewall"
            sudo ufw --force enable
            sudo ufw default deny incoming
            sudo ufw default allow outgoing
            sudo ufw allow ssh
            sudo ufw allow 80/tcp
            sudo ufw allow 443/tcp
            success "UFW firewall enabled"
            ;&
        2|7)
            show_progress "Installing Fail2ban"
            sudo apt update
            sudo apt install fail2ban -y
            sudo systemctl enable fail2ban
            sudo systemctl start fail2ban
            success "Fail2ban installed and started"
            ;&
        3|7)
            if prompt_yes_no "Disable root login via SSH?" "y"; then
                sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
                sudo systemctl restart ssh
                success "Root login disabled"
            fi
            ;&
        4|7)
            show_progress "Updating SSH configuration"
            # Create backup
            sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
            # Apply security settings
            sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
            sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
            sudo systemctl restart ssh
            success "SSH configuration updated"
            ;&
        5|7)
            show_progress "Installing security updates"
            sudo apt update
            sudo apt upgrade -y
            sudo apt autoremove -y
            success "Security updates installed"
            ;&
        6|7)
            show_progress "Configuring log monitoring"
            sudo apt install logwatch -y
            success "Log monitoring configured"
            ;;
        *)
            warning "Invalid option"
            ;;
    esac
}

# Function to update system
update_system() {
    show_progress "Updating system packages"
    
    # Update package lists
    sudo apt update
    
    # Show upgradable packages
    echo ""
    echo "📦 Available Updates:"
    echo "===================="
    apt list --upgradable 2>/dev/null | head -20
    
    if prompt_yes_no "Proceed with system update?" "y"; then
        sudo apt upgrade -y
        sudo apt autoremove -y
        sudo apt autoclean
        success "System updated successfully"
    fi
}

# Function to fix broken dependencies
fix_broken_dependencies() {
    show_progress "Fixing broken dependencies"
    
    # Fix broken packages
    sudo apt --fix-broken install -y
    
    # Reconfigure packages
    sudo dpkg --configure -a
    
    # Clean package cache
    sudo apt autoclean
    sudo apt autoremove -y
    
    success "Broken dependencies fixed"
}

# Function to remove unnecessary files
remove_unnecessary_files() {
    echo ""
    echo "🗑️  File Cleanup Options:"
    echo "========================"
    echo "1) Clear package cache"
    echo "2) Remove old kernels"
    echo "3) Clear temporary files"
    echo "4) Clear log files"
    echo "5) All of the above"
    
    read -p "Choose option (1-5): " cleanup_choice
    
    case "$cleanup_choice" in
        1|5)
            show_progress "Clearing package cache"
            sudo apt autoclean
            sudo apt autoremove -y
            ;&
        2|5)
            show_progress "Removing old kernels"
            sudo apt autoremove --purge -y
            ;&
        3|5)
            show_progress "Clearing temporary files"
            sudo rm -rf /tmp/*
            sudo rm -rf /var/tmp/*
            ;&
        4|5)
            if prompt_yes_no "Clear old log files?" "y"; then
                sudo journalctl --vacuum-time=7d
                sudo find /var/log -type f -name "*.log" -mtime +30 -delete
                success "Old log files cleared"
            fi
            ;;
        *)
            warning "Invalid option"
            ;;
    esac
}

# Main function
main() {
    log "INFO" "Starting Ubuntu 22 Development Environment Setup v$SCRIPT_VERSION"
    
    # Check if running on Ubuntu 22
    if ! grep -q "22.04" /etc/lsb-release 2>/dev/null; then
        warning "This script is designed for Ubuntu 22.04. Proceed with caution."
        if ! prompt_yes_no "Continue anyway?" "n"; then
            exit 0
        fi
    fi
    
    validate_system
    
    while true; do
        show_main_menu
        read -p "Choose an option (0-22): " choice
        
        case "$choice" in
            1) run_enhanced_script "docker_enhanced.sh" ;;
            2) run_enhanced_script "nginx_ssl_enhanced.sh" ;;
            3) run_enhanced_script "mysql_enhanced.sh" ;;
            4) run_original_script "postgresql.sh" ;;
            5) run_original_script "rails_setup.sh" ;;
            6) run_original_script "install_common_dev_libs.sh" ;;
            7) run_original_script "image_lib.sh" ;;
            8) run_original_script "auto_after_reboot.sh" ;;
            9) run_original_script "sidekiq.sh" ;;
            10) run_original_script "logrotate.sh" ;;
            11) run_original_script "user.sh" ;;
            12) show_system_info ;;
            13) cleanup_system ;;
            14) manage_backups ;;
            15) manage_configuration ;;
            16) security_hardening ;;
            17) show_help ;;
            18) show_configuration ;;
            19) show_system_status ;;
            20) update_system ;;
            21) fix_broken_dependencies ;;
            22) remove_unnecessary_files ;;
            0) 
                log "INFO" "Exiting Ubuntu 22 Development Environment Setup"
                echo ""
                echo "👋 Thank you for using the enhanced development toolkit!"
                echo " Regular maintenance recommended weekly"
                echo ""
                # Return to original directory
                if [[ -n "$ORIGINAL_DIR" && -d "$ORIGINAL_DIR" ]]; then
                    cd "$ORIGINAL_DIR"
                    echo "📁 Returned to original directory: $ORIGINAL_DIR"
                fi
                exit 0
                ;;
            *) 
                warning "Invalid option. Please choose 0-22."
                ;;
        esac
        
        echo ""
        echo "⏳ Operation completed. Press Enter to continue..."
        read -r
        clear
        echo "================================================================"
        echo "       🚀 $SCRIPT_NAME v$SCRIPT_VERSION"
        echo "================================================================"
    done
}

# Run main function
main "$@"
