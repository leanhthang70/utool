#!/bin/bash

# Enhanced MySQL/MariaDB Management Script
# This script provides comprehensive MySQL/MariaDB management with proper error handling

# Save original directory
ORIGINAL_DIR="$(pwd)"
export ORIGINAL_DIR

# Source common functions
source "$(dirname "$0")/common.sh"

# Script configuration
SCRIPT_NAME="MySQL/MariaDB Management"
MARIADB_VERSION="11.4.2"
MYSQL_CONF_FILE="/etc/mysql/my.cnf"
BACKUP_DIR="${BACKUP_DIR:-/opt/backups/mysql}"

# Print header
echo "================================================================"
echo "              🗄️  $SCRIPT_NAME (Enhanced)"
echo "================================================================"

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
    echo "   1) Install MariaDB"
    echo "   2) Create Database"
    echo "   3) Drop Database"
    echo "   4) Create User"
    echo "   5) Delete User"
    echo "   6) Change Password"
    echo "   7) Backup Database"
    echo "   8) Restore Database"
    echo "   9) Setup Replication (Master)"
    echo "   10) Setup Replication (Slave)"
    echo "   11) Show Database Status"
    echo "   12) Optimize Database"
    echo "   13) Security Configuration"
    echo "   14) Performance Tuning"
    echo "   0) Exit"
    echo ""
}

# Function to install MariaDB
install_mariadb() {
    show_progress "Installing MariaDB $MARIADB_VERSION"
    
    # Check if MariaDB is already installed
    if command -v mariadb &> /dev/null; then
        warning "MariaDB is already installed"
        if ! prompt_yes_no "Continue with configuration?" "y"; then
            return 0
        fi
    fi
    
    # Install MariaDB repository
    if ! curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash -s -- --mariadb-server-version="$MARIADB_VERSION"; then
        error_exit "Failed to setup MariaDB repository"
    fi
    
    # Update package lists
    sudo apt update
    
    # Install MariaDB packages
    sudo apt install -y mariadb-server mariadb-client libmysqlclient-dev
    
    # Enable and start MariaDB
    sudo systemctl enable mariadb
    sudo systemctl start mariadb
    
    # Run secure installation
    show_progress "Running MySQL secure installation"
    sudo mysql_secure_installation
    
    # Configure MariaDB
    configure_mariadb
    
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
    
    # Add MariaDB repository
    curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash -s -- --mariadb-server-version="$MARIADB_VERSION"
    
    # Update package list
    sudo apt update -q
    
    # Install packages
    install_package "libmysqlclient-dev"
    install_package "mariadb-server"
    install_package "mariadb-client"
    
    # Secure installation
    if prompt_yes_no "Run mysql_secure_installation?" "y"; then
        sudo mysql_secure_installation
    fi
    
    # Configure port
    local mysql_port
    mysql_port=$(prompt_with_default "MySQL port" "$DEFAULT_MYSQL_PORT")
    
    # Backup original config
    backup_file "$MYSQL_CONF_FILE"
    
    # Add port configuration
    if ! grep -q "port = $mysql_port" "$MYSQL_CONF_FILE"; then
        sudo sed -i "/^\[client-server\]/a port = $mysql_port" "$MYSQL_CONF_FILE"
    fi
    
    # Show optimization recommendations
    show_optimization_recommendations
    
    # Enable and start service
    enable_service "mariadb"
    
    show_completion "MariaDB installation complete"
}

# Function to show optimization recommendations
show_optimization_recommendations() {
    echo ""
    echo "📝 Optimization Recommendations:"
    echo "   Add these configurations to $MYSQL_CONF_FILE under [mysqld] section:"
    echo ""
    echo "   # Memory settings"
    echo "   innodb_buffer_pool_size = 70% of total RAM"
    echo "   query_cache_size = 256MB"
    echo "   innodb_log_buffer_size = 128MB"
    echo "   tmp_table_size = 128MB"
    echo ""
    echo "   # Connection settings"
    echo "   bind-address = 0.0.0.0"
    echo "   max_connections = 500"
    echo "   interactive_timeout = 300"
    echo "   wait_timeout = 300"
    echo "   thread_cache_size = 256"
    echo ""
    echo "   # InnoDB settings"
    echo "   innodb_file_per_table = 1"
    echo "   innodb_log_file_size = 512MB"
    echo "   innodb_strict_mode = ON"
    echo "   innodb_lock_wait_timeout = 120"
    echo ""
    echo "   # Character set"
    echo "   character-set-server = utf8mb4"
    echo "   character_set_client = utf8mb4"
    echo "   collation-server = utf8mb4_general_ci"
    echo ""
    
    if prompt_yes_no "Apply recommended optimizations automatically?" "y"; then
        apply_optimizations
    fi
}

# Function to apply optimizations
apply_optimizations() {
    show_progress "Applying MySQL optimizations"
    
    # Get total RAM in GB
    local total_ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    local buffer_pool_size=$((total_ram_gb * 70 / 100))
    
    # Create optimization config
    local optimization_config="
# MySQL Optimization - Added by utool
[mysqld]
# Memory settings
innodb_buffer_pool_size = ${buffer_pool_size}G
query_cache_size = 256MB
innodb_log_buffer_size = 128MB
tmp_table_size = 128MB

# Connection settings
bind-address = 0.0.0.0
max_connections = 500
interactive_timeout = 300
wait_timeout = 300
thread_cache_size = 256

# InnoDB settings
innodb_file_per_table = 1
innodb_log_file_size = 512MB
innodb_strict_mode = ON
innodb_lock_wait_timeout = 120

# Character set
character-set-server = utf8mb4
character_set_client = utf8mb4
collation-server = utf8mb4_general_ci"
    
    # Append to config file
    echo "$optimization_config" | sudo tee -a "$MYSQL_CONF_FILE" > /dev/null
    
    # Restart service
    sudo systemctl restart mariadb
    
    show_completion "Optimizations applied"
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
    
    if execute_mysql_query "$root_user" "$root_password" "$query"; then
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
    
    if execute_mysql_query "$root_user" "$root_password" "$query"; then
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
        if ! execute_mysql_query "$root_user" "$root_password" "$query"; then
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
    execute_mysql_query "$root_user" "$root_password" "$create_query"
    
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
    execute_mysql_query "$root_user" "$root_password" "SHOW DATABASES;" | grep -v "Database\|information_schema\|performance_schema\|mysql\|sys"
    
    echo ""
    echo "👥 Users:"
    execute_mysql_query "$root_user" "$root_password" "SELECT User, Host FROM mysql.user WHERE User != '';"
    
    echo ""
    echo "🔄 Process List:"
    execute_mysql_query "$root_user" "$root_password" "SHOW PROCESSLIST;"
    
    echo ""
    echo "📈 Status Variables:"
    execute_mysql_query "$root_user" "$root_password" "SHOW STATUS LIKE 'Connections';"
    execute_mysql_query "$root_user" "$root_password" "SHOW STATUS LIKE 'Uptime';"
    execute_mysql_query "$root_user" "$root_password" "SHOW STATUS LIKE 'Threads_connected';"
}

# Function to execute MySQL query
execute_mysql_query() {
    local user="$1"
    local password="$2"
    local query="$3"
    
    mysql --user="$user" --password="$password" -e "$query" 2>/dev/null
}

# Main function
main() {
    log "INFO" "Starting MySQL/MariaDB management"
    
    while true; do
        show_menu
        read -p "Choose an option: " choice
        
        case "$choice" in
            1) install_mariadb ;;
            2) create_database ;;
            3) drop_database ;;
            4) create_user ;;
            5) 
                log "INFO" "User deletion feature - coming soon"
                ;;
            6) 
                log "INFO" "Password change feature - coming soon"
                ;;
            7) backup_database ;;
            8) restore_database ;;
            9) 
                log "INFO" "Replication setup - coming soon"
                ;;
            10) 
                log "INFO" "Replication setup - coming soon"
                ;;
            11) show_database_status ;;
            12) 
                log "INFO" "Database optimization - coming soon"
                ;;
            0) 
                log "INFO" "Exiting MySQL/MariaDB management"
                exit 0
                ;;
            *) 
                warning "Invalid option. Please choose 0-12."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run main function
main "$@"
