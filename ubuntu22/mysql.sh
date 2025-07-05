#!/bin/bash

# Enhanced MySQL/MariaDB Management Script
# This script provides comprehensive MySQL/MariaDB management with proper error handling

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
SCRIPT_NAME="MySQL/MariaDB Management"
MARIADB_VERSION="11.4.2"
MYSQL_CONF_FILE="/etc/mysql/my.cnf"
BACKUP_DIR="${BACKUP_DIR:-/opt/backups/mysql}"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Function to validate database credentials
validate_credentials() {
    local user="$1"
    local password="$2"
    
    if [[ -z "$user" || -z "$password" ]]; then
        error_exit "Username and password cannot be empty"
    fi
    
    # Test connection
    if ! mariadb -u"$user" -p"$password" -e "SELECT 1;" &>/dev/null; then
        error_exit "Invalid credentials or database connection failed"
    fi
    
    return 0
}

# Function to show menu
show_menu() {
    echo ""
    echo "📋 Available Options:"
    echo ""
    echo "   🔧 Installation & Setup:"
    echo "     1) Install MariaDB                    - Download và cài đặt MariaDB 11.4.2"
    echo "     2) Check Installation Status          - Kiểm tra trạng thái cài đặt và service"
    echo ""
    echo "   🗄️  Database Management:"
    echo "     3) Create Database                    - Tạo database mới với charset UTF8MB4"
    echo "     4) Drop Database                      - Xóa database (cẩn thận!)"
    echo ""
    echo "   👥 User Management:"
    echo "     5) Create User                        - Tạo user với quyền tùy chỉnh"
    echo "     6) Delete User                        - Xóa user khỏi hệ thống"
    echo "     7) Change Password                    - Đổi mật khẩu user"
    echo ""
    echo "   💾 Backup & Restore:"
    echo "     8) Backup Database                    - Sao lưu database ra file .sql.gz"
    echo "     9) Restore Database                   - Khôi phục database từ backup"
    echo ""
    echo "   🔄 Advanced Features:"
    echo "    10) Setup Replication (Master)        - Cấu hình Master-Slave replication"
    echo "    11) Setup Replication (Slave)         - Cấu hình Slave server"
    echo "    12) Show Database Status               - Hiển thị thông tin databases và users"
    echo "    13) Optimize Database                  - Tối ưu hóa performance database"
    echo "    14) Security Configuration            - Cấu hình bảo mật nâng cao"
    echo "    15) Performance Tuning                - Điều chỉnh hiệu suất MySQL"
    echo ""
    echo "     0) Exit                              - Thoát khỏi MySQL Management"
    echo ""
}

# Function to install MariaDB
install_mariadb() {
    show_progress "Installing MariaDB $MARIADB_VERSION"
    
    # Check if MariaDB is already installed
    if command -v mariadb &> /dev/null; then
        warning "MariaDB is already installed"
        local current_version=$(mariadb --version | cut -d' ' -f3 | cut -d'-' -f1)
        echo "Current version: $current_version"
        if ! prompt_yes_no "Continue with configuration?" "y"; then
            return 0
        fi
    fi
    
    # Check for existing MariaDB repository configuration
    if [[ -f "/etc/apt/sources.list.d/mariadb.list" ]]; then
        if ! handle_repository_conflicts; then
            return 1
        fi
    fi
    
    # Install MariaDB repository
    show_progress "Setting up MariaDB repository"
    if ! curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash -s -- --mariadb-server-version="$MARIADB_VERSION"; then
        error_exit "Failed to setup MariaDB repository"
    fi
    success "MariaDB repository setup completed"
    
    # Update package lists
    show_progress "Updating package lists"
    sudo apt update -q
    
    # Install MariaDB packages
    show_progress "Installing MariaDB packages"
    sudo apt install -y mariadb-server mariadb-client libmysqlclient-dev
    
    # Enable and start MariaDB
    show_progress "Starting MariaDB service"
    sudo systemctl enable mariadb
    sudo systemctl start mariadb
    
    # Verify MariaDB is running
    if ! sudo systemctl is-active mariadb &> /dev/null; then
        error_exit "MariaDB failed to start"
    fi
    success "MariaDB service started successfully"
    
    # Run secure installation
    echo ""
    warning "Please run the following secure installation steps:"
    echo "1. Set root password (if not set)"
    echo "2. Remove anonymous users: Y"
    echo "3. Disallow root login remotely: Y"
    echo "4. Remove test database: Y"
    echo "5. Reload privilege tables: Y"
    echo ""
    if prompt_yes_no "Run MySQL secure installation now?" "y"; then
        sudo mysql_secure_installation
    fi
    
    # Configure MariaDB
    if prompt_yes_no "Configure MariaDB with optimized settings?" "y"; then
        configure_mariadb
    fi
    
    # Show installation summary
    echo ""
    echo "📋 Installation Summary:"
    echo "======================="
    echo "• MariaDB Version: $(mariadb --version | cut -d' ' -f3 | cut -d'-' -f1)"
    echo "• Service Status: $(systemctl is-active mariadb)"
    echo "• Configuration File: $MYSQL_CONF_FILE"
    echo "• Log Directory: /var/log/mysql/"
    echo "• Data Directory: /var/lib/mysql/"
    echo ""
    
    success "MariaDB installation completed successfully"
}

# Function to configure MariaDB
configure_mariadb() {
    show_progress "Configuring MariaDB"
    
    # Get port configuration
    read -p "Enter MySQL port (default 3306): " MYSQL_PORT
    MYSQL_PORT=${MYSQL_PORT:-3306}
    
    # Validate port
    if ! [[ "$MYSQL_PORT" =~ ^[0-9]+$ ]] || [ "$MYSQL_PORT" -lt 1 ] || [ "$MYSQL_PORT" -gt 65535 ]; then
        warning "Invalid port number. Using default 3306."
        MYSQL_PORT=3306
    fi
    
    # Backup original configuration
    sudo cp "$MYSQL_CONF_FILE" "$MYSQL_CONF_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Create optimized configuration
    sudo tee "$MYSQL_CONF_FILE" > /dev/null << EOF
[client]
port = $MYSQL_PORT
socket = /var/run/mysqld/mysqld.sock

[mysql_safe]
socket = /var/run/mysqld/mysqld.sock
nice = 0

[mysqld]
user = mysql
pid-file = /var/run/mysqld/mysqld.pid
socket = /var/run/mysqld/mysqld.sock
port = $MYSQL_PORT
basedir = /usr
datadir = /var/lib/mysql
tmpdir = /tmp
lc-messages-dir = /usr/share/mysql
skip-external-locking

# Character set and collation
character-set-server = utf8mb4
collation-server = utf8mb4_general_ci

# Network settings
bind-address = 0.0.0.0
max_connections = 500
max_connect_errors = 1000
timeout = 60
interactive_timeout = 300
wait_timeout = 300

# Buffer pool and memory settings
innodb_buffer_pool_size = 2G
innodb_buffer_pool_instances = 8
innodb_log_file_size = 512M
innodb_log_buffer_size = 128M
innodb_flush_log_at_trx_commit = 1
innodb_file_per_table = 1

# Query cache
query_cache_type = 1
query_cache_size = 256M
query_cache_limit = 2M

# Temporary tables
tmp_table_size = 128M
max_heap_table_size = 128M

# Thread settings
thread_cache_size = 256
thread_stack = 192K

# Logging
log_error = /var/log/mysql/error.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

# Security
local_infile = 0
symbolic-links = 0

[mysqldump]
quick
quote-names
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 256M
sort_buffer_size = 256M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout

EOF
    
    # Set proper permissions
    sudo chown mysql:mysql "$MYSQL_CONF_FILE"
    sudo chmod 644 "$MYSQL_CONF_FILE"
    
    # Restart MariaDB to apply changes
    sudo systemctl restart mariadb
    
    # Verify MariaDB is running
    if ! sudo systemctl is-active mariadb &> /dev/null; then
        error_exit "MariaDB failed to start after configuration"
    fi
    
    success "MariaDB configuration completed"
}

# Function to create database
create_database() {
    show_progress "Creating new database"
    
    # Get credentials
    local root_user
    local root_password
    local db_name
    
    root_user=$(prompt_with_default "MySQL root username" "root")
    read -s -p "Enter MySQL root password: " root_password
    echo
    
    read -p "Enter new database name: " db_name
    validate_not_empty "$db_name" "Database name"
    
    # Create database
    local query="CREATE DATABASE IF NOT EXISTS \`$db_name\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
    
    if mysql --user="$root_user" --password="$root_password" -e "$query" 2>/dev/null; then
        success "Database '$db_name' created successfully"
    else
        error_exit "Failed to create database '$db_name'"
    fi
}

# Function to drop database
drop_database() {
    show_progress "Dropping database"
    
    # Get credentials
    local root_user
    local root_password
    local db_name
    
    root_user=$(prompt_with_default "MySQL root username" "root")
    read -s -p "Enter MySQL root password: " root_password
    echo
    
    read -p "Enter database name to drop: " db_name
    validate_not_empty "$db_name" "Database name"
    
    # Confirmation
    if ! prompt_yes_no "Are you sure you want to drop database '$db_name'? This action cannot be undone!" "n"; then
        log "INFO" "Database drop cancelled"
        return 0
    fi
    
    # Drop database
    local query="DROP DATABASE IF EXISTS \`$db_name\`;"
    
    if mysql --user="$root_user" --password="$root_password" -e "$query" 2>/dev/null; then
        success "Database '$db_name' dropped successfully"
    else
        error_exit "Failed to drop database '$db_name'"
    fi
}

# Function to create user
create_user() {
    show_progress "Creating new user"
    
    # Get admin credentials
    local root_user
    local root_password
    
    root_user=$(prompt_with_default "MySQL root username" "root")
    read -s -p "Enter MySQL root password: " root_password
    echo
    
    # Get user details
    local username
    local password
    local user_type
    local remote_access
    local host
    local database
    
    read -p "Enter new username: " username
    validate_not_empty "$username" "Username"
    
    read -s -p "Enter password for new user: " password
    echo
    validate_not_empty "$password" "Password"
    
    echo "User Types:"
    echo "  1) Application user (CREATE, SELECT, INSERT, UPDATE, DELETE, INDEX, ALTER)"
    echo "  2) Read-only user (SELECT)"
    echo "  3) Full privileges (ALL PRIVILEGES)"
    read -p "Choose user type (1-3): " user_type
    
    echo "Remote Access:"
    echo "  1) All hosts (%)"
    echo "  2) Localhost only"
    echo "  3) Specific IP address"
    read -p "Choose access type (1-3): " remote_access
    
    # Set host based on choice
    case "$remote_access" in
        1) host="%" ;;
        2) host="localhost" ;;
        3) 
            read -p "Enter IP address: " host
            validate_ip "$host"
            ;;
        *) error_exit "Invalid access type" ;;
    esac
    
    # Set permissions based on user type
    local permissions
    case "$user_type" in
        1) permissions="CREATE, SELECT, INSERT, UPDATE, DELETE, INDEX, ALTER" ;;
        2) permissions="SELECT" ;;
        3) permissions="ALL PRIVILEGES" ;;
        *) error_exit "Invalid user type" ;;
    esac
    
    # Get database
    read -p "Enter database name (or press Enter for all databases): " database
    database=${database:-"*"}
    
    # Create user
    local queries=(
        "CREATE USER IF NOT EXISTS '$username'@'$host' IDENTIFIED BY '$password';"
        "GRANT $permissions ON \`$database\`.* TO '$username'@'$host';"
        "FLUSH PRIVILEGES;"
    )
    
    for query in "${queries[@]}"; do
        if ! mysql --user="$root_user" --password="$root_password" -e "$query" 2>/dev/null; then
            error_exit "Failed to create user '$username'"
        fi
    done
    
    success "User '$username' created successfully with $permissions privileges"
}

# Function to backup database
backup_database() {
    show_progress "Backing up database"
    
    # Get credentials
    local root_user
    local root_password
    local db_name
    local backup_name
    
    root_user=$(prompt_with_default "MySQL root username" "root")
    read -s -p "Enter MySQL root password: " root_password
    echo
    
    read -p "Enter database name to backup: " db_name
    validate_not_empty "$db_name" "Database name"
    
    # Generate backup filename
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    backup_name=$(prompt_with_default "Backup filename" "${db_name}_backup_${timestamp}.sql")
    
    local backup_path="$BACKUP_DIR/$backup_name"
    
    # Create backup
    if mysqldump --single-transaction --routines --triggers --user="$root_user" --password="$root_password" --databases "$db_name" | gzip > "$backup_path.gz"; then
        success "Database backup created: $backup_path.gz"
        log "INFO" "Backup size: $(du -h "$backup_path.gz" | cut -f1)"
    else
        error_exit "Failed to create backup"
    fi
}

# Function to restore database
restore_database() {
    show_progress "Restoring database"
    
    # Get credentials
    local root_user
    local root_password
    local target_db
    local backup_file
    
    root_user=$(prompt_with_default "MySQL root username" "root")
    read -s -p "Enter MySQL root password: " root_password
    echo
    
    read -p "Enter target database name: " target_db
    validate_not_empty "$target_db" "Target database name"
    
    read -p "Enter backup file path: " backup_file
    validate_file_exists "$backup_file"
    
    # Confirmation
    if ! prompt_yes_no "This will overwrite database '$target_db'. Continue?" "n"; then
        log "INFO" "Database restore cancelled"
        return 0
    fi
    
    # Create database if it doesn't exist
    local create_query="CREATE DATABASE IF NOT EXISTS \`$target_db\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
    mysql --user="$root_user" --password="$root_password" -e "$create_query" 2>/dev/null
    
    # Restore from backup
    if [[ "$backup_file" == *.gz ]]; then
        if gunzip -c "$backup_file" | mysql --user="$root_user" --password="$root_password" "$target_db"; then
            success "Database restored successfully to '$target_db'"
        else
            error_exit "Failed to restore database"
        fi
    else
        if mysql --user="$root_user" --password="$root_password" "$target_db" < "$backup_file"; then
            success "Database restored successfully to '$target_db'"
        else
            error_exit "Failed to restore database"
        fi
    fi
}

# Function to show database status
show_database_status() {
    show_progress "Gathering database status"
    
    # Get credentials
    local root_user
    local root_password
    
    root_user=$(prompt_with_default "MySQL root username" "root")
    read -s -p "Enter MySQL root password: " root_password
    echo
    
    echo ""
    echo "📊 Database Status:"
    echo "=================="
    
    # Show databases
    echo "📋 Databases:"
    mysql --user="$root_user" --password="$root_password" -e "SHOW DATABASES;" 2>/dev/null | grep -v "Database\|information_schema\|performance_schema\|mysql\|sys"
    
    echo ""
    echo "👥 Users:"
    mysql --user="$root_user" --password="$root_password" -e "SELECT User, Host FROM mysql.user WHERE User != '';" 2>/dev/null
    
    echo ""
    echo "🔄 Process List:"
    mysql --user="$root_user" --password="$root_password" -e "SHOW PROCESSLIST;" 2>/dev/null
    
    echo ""
    echo "📈 Status Variables:"
    mysql --user="$root_user" --password="$root_password" -e "SHOW STATUS LIKE 'Connections';" 2>/dev/null
    mysql --user="$root_user" --password="$root_password" -e "SHOW STATUS LIKE 'Uptime';" 2>/dev/null
    mysql --user="$root_user" --password="$root_password" -e "SHOW STATUS LIKE 'Threads_connected';" 2>/dev/null
}

# Function to check MariaDB installation status
check_installation_status() {
    echo ""
    echo "🔍 MariaDB Installation Status:"
    echo "==============================="
    
    # Check if MariaDB is installed
    if command -v mariadb &> /dev/null; then
        echo "• MariaDB Binary: ✅ Installed"
        echo "• Version: $(mariadb --version | cut -d' ' -f3 | cut -d'-' -f1)"
    else
        echo "• MariaDB Binary: ❌ Not installed"
        return 1
    fi
    
    # Check service status
    local service_status=$(systemctl is-active mariadb 2>/dev/null)
    case "$service_status" in
        "active") echo "• Service Status: ✅ Running" ;;
        "inactive") echo "• Service Status: ⚠️ Stopped" ;;
        "failed") echo "• Service Status: ❌ Failed" ;;
        *) echo "• Service Status: ❓ Unknown" ;;
    esac
    
    # Check if service is enabled
    local enabled_status=$(systemctl is-enabled mariadb 2>/dev/null)
    case "$enabled_status" in
        "enabled") echo "• Auto-start: ✅ Enabled" ;;
        "disabled") echo "• Auto-start: ⚠️ Disabled" ;;
        *) echo "• Auto-start: ❓ Unknown" ;;
    esac
    
    # Check configuration file
    if [[ -f "$MYSQL_CONF_FILE" ]]; then
        echo "• Configuration: ✅ $MYSQL_CONF_FILE"
    else
        echo "• Configuration: ⚠️ Not found"
    fi
    
    # Check data directory
    if [[ -d "/var/lib/mysql" ]]; then
        local db_count=$(sudo ls /var/lib/mysql/ | grep -v ".*\.pid\|.*\.sock" | wc -l)
        echo "• Data Directory: ✅ /var/lib/mysql ($db_count databases)"
    else
        echo "• Data Directory: ❌ Not found"
    fi
    
    # Check repository
    if [[ -f "/etc/apt/sources.list.d/mariadb.list" ]]; then
        echo "• Repository: ✅ Configured"
    else
        echo "• Repository: ⚠️ Not configured"
    fi
    
    echo ""
}

# Function to handle repository conflicts
handle_repository_conflicts() {
    local repo_file="/etc/apt/sources.list.d/mariadb.list"
    
    if [[ -f "$repo_file" ]]; then
        echo ""
        echo "⚠️  Repository Conflict Detected:"
        echo "================================="
        echo "Found existing MariaDB repository configuration."
        echo "This can cause conflicts during installation."
        echo ""
        echo "Options:"
        echo "1) Remove existing repository and continue"
        echo "2) Keep existing repository (may cause conflicts)"
        echo "3) Show existing repository content"
        echo "4) Cancel installation"
        echo ""
        
        while true; do
            read -p "Choose option (1-4): " repo_choice
            case "$repo_choice" in
                1)
                    show_progress "Removing existing repository configuration"
                    sudo rm -f "$repo_file"*
                    success "Repository configuration removed"
                    return 0
                    ;;
                2)
                    warning "Keeping existing repository - installation may fail"
                    return 0
                    ;;
                3)
                    echo ""
                    echo "📄 Current repository content:"
                    echo "=============================="
                    sudo cat "$repo_file"
                    echo ""
                    ;;
                4)
                    echo "Installation cancelled by user"
                    return 1
                    ;;
                *)
                    warning "Invalid option. Please choose 1-4."
                    ;;
            esac
        done
    fi
    
    return 0
}

# Function to cleanup after failed installation
cleanup_failed_installation() {
    warning "Cleaning up after failed installation..."
    
    # Stop MariaDB service if running
    sudo systemctl stop mariadb 2>/dev/null || true
    
    # Remove packages
    sudo apt remove --purge mariadb-server mariadb-client mariadb-common -y 2>/dev/null || true
    
    # Remove repository
    sudo rm -f /etc/apt/sources.list.d/mariadb.list* 2>/dev/null || true
    
    # Clean package cache
    sudo apt autoremove -y
    sudo apt autoclean
    
    warning "Cleanup completed. You can try installation again."
}

# Main function
main() {
    # Print header
    echo "================================================================"
    echo "              🗄️  $SCRIPT_NAME (Enhanced)"
    echo "================================================================"
    
    log "INFO" "Starting MySQL/MariaDB management"
    
    while true; do
        show_menu
        read -p "Choose an option: " choice
        
        case "$choice" in
            1) install_mariadb ;;
            2) check_installation_status ;;
            3) create_database ;;
            4) drop_database ;;
            5) create_user ;;
            6) 
                log "INFO" "User deletion feature - coming soon"
                ;;
            7) 
                log "INFO" "Password change feature - coming soon"
                ;;
            8) backup_database ;;
            9) restore_database ;;
            10) 
                log "INFO" "Replication setup - coming soon"
                ;;
            11) 
                log "INFO" "Database status feature - coming soon"
                ;;
            12) show_database_status ;;
            13) 
                log "INFO" "Database optimization - coming soon"
                ;;
            14) 
                log "INFO" "Security configuration feature - coming soon"
                ;;
            15) 
                log "INFO" "Performance tuning feature - coming soon"
                ;;
            0) 
                log "INFO" "Exiting MySQL/MariaDB management"
                exit 0
                ;;
            *) 
                warning "Invalid option. Please choose 0-15."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run main function
main "$@"
