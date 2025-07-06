#!/bin/bash

# Enhanced PostgreSQL 16 Management Script
# This script provides comprehensive PostgreSQL management with proper error handling

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
SCRIPT_NAME="PostgreSQL 16 Management"
POSTGRESQL_VERSION="16"  # Default version
POSTGRESQL_CONF_FILE="/etc/postgresql/16/main/postgresql.conf"
POSTGRESQL_HBA_FILE="/etc/postgresql/16/main/pg_hba.conf"
BACKUP_DIR="${BACKUP_DIR:-/opt/backups/postgresql}"

# Available PostgreSQL versions
AVAILABLE_POSTGRESQL_VERSIONS=(
    "16"
    "15"
    "14"
    "13"
    "12"
    "11"
)

# Function to show available PostgreSQL versions
show_postgresql_versions() {
    echo ""
    echo "📋 Available PostgreSQL Versions:"
    echo "================================="
    for i in "${!AVAILABLE_POSTGRESQL_VERSIONS[@]}"; do
        local version="${AVAILABLE_POSTGRESQL_VERSIONS[$i]}"
        local status=""
        if [[ "$version" == "$POSTGRESQL_VERSION" ]]; then
            status=" (Default)"
        fi
        echo "  $((i+1))) PostgreSQL $version$status"
    done
    echo "  0) Custom version (manual input)"
    echo ""
}

# Function to select PostgreSQL version
select_postgresql_version() {
    show_postgresql_versions
    
    while true; do
        read -p "Choose PostgreSQL version (1-${#AVAILABLE_POSTGRESQL_VERSIONS[@]} or 0 for custom): " version_choice
        
        if [[ "$version_choice" =~ ^[0-9]+$ ]]; then
            if [[ "$version_choice" -eq 0 ]]; then
                # Custom version input
                read -p "Enter custom PostgreSQL version (e.g., 16, 15, 14): " custom_version
                if [[ -n "$custom_version" && "$custom_version" =~ ^[0-9]+$ ]]; then
                    POSTGRESQL_VERSION="$custom_version"
                    # Update configuration paths
                    POSTGRESQL_CONF_FILE="/etc/postgresql/$POSTGRESQL_VERSION/main/postgresql.conf"
                    POSTGRESQL_HBA_FILE="/etc/postgresql/$POSTGRESQL_VERSION/main/pg_hba.conf"
                    success "Selected custom version: PostgreSQL $POSTGRESQL_VERSION"
                    break
                else
                    error "Invalid version. Please enter a numeric version (e.g., 16)."
                fi
            elif [[ "$version_choice" -ge 1 && "$version_choice" -le "${#AVAILABLE_POSTGRESQL_VERSIONS[@]}" ]]; then
                # Selected from list
                POSTGRESQL_VERSION="${AVAILABLE_POSTGRESQL_VERSIONS[$((version_choice-1))]}"
                # Update configuration paths
                POSTGRESQL_CONF_FILE="/etc/postgresql/$POSTGRESQL_VERSION/main/postgresql.conf"
                POSTGRESQL_HBA_FILE="/etc/postgresql/$POSTGRESQL_VERSION/main/pg_hba.conf"
                success "Selected version: PostgreSQL $POSTGRESQL_VERSION"
                break
            else
                error "Invalid option. Please choose 1-${#AVAILABLE_POSTGRESQL_VERSIONS[@]} or 0."
            fi
        else
            error "Please enter a valid number."
        fi
    done
}

# Function to update script title based on selected version
update_script_title() {
    SCRIPT_NAME="PostgreSQL $POSTGRESQL_VERSION Management"
}

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Function to automatically detect and get PostgreSQL credentials
get_postgresql_credentials() {
    local force_prompt="${1:-false}"
    local db_name="${2:-postgres}"
    
    # If force_prompt is true, always ask for credentials
    if [[ "$force_prompt" == "true" ]]; then
        local pg_user
        local pg_password
        pg_user=$(prompt_with_default "PostgreSQL username" "postgres")
        read -s -p "Enter PostgreSQL password: " pg_password
        echo
        echo "$pg_user:$pg_password:$db_name"
        return 0
    fi
    
    show_progress "Detecting PostgreSQL connection method"
    
    # Check if PostgreSQL service is running first
    if ! systemctl is-active postgresql &>/dev/null; then
        error "❌ PostgreSQL service is not running"
        echo "   Try: sudo systemctl start postgresql"
        return 1
    fi
    
    # Method 1: Try connecting as postgres user without password
    if sudo -u postgres psql -d "$db_name" -c "SELECT 1;" &>/dev/null; then
        success "✅ Connected as postgres user (system auth)"
        echo "sudo:postgres:$db_name"
        return 0
    fi
    
    # Method 2: Try connecting with peer authentication
    if psql -U postgres -d "$db_name" -c "SELECT 1;" &>/dev/null; then
        success "✅ Connected with peer authentication"
        echo "peer:postgres:$db_name"
        return 0
    fi
    
    # Method 3: Ask for credentials
    warning "⚠️  Cannot connect automatically, please provide credentials"
    local pg_user
    local pg_password
    pg_user=$(prompt_with_default "PostgreSQL username" "postgres")
    read -s -p "Enter PostgreSQL password: " pg_password
    echo
    
    # Test the provided credentials
    if PGPASSWORD="$pg_password" psql -U "$pg_user" -d "$db_name" -c "SELECT 1;" &>/dev/null; then
        success "✅ Connected with provided credentials"
        echo "$pg_user:$pg_password:$db_name"
        return 0
    else
        error "❌ Cannot connect with provided credentials"
        echo ""
        echo "🔧 Try these options:"
        echo "1. Use option 16 (Reset PostgreSQL Password)"
        echo "2. Use option 17 (Connection Troubleshoot)"
        echo "3. Check if PostgreSQL service is running: sudo systemctl status postgresql"
        return 1
    fi
}

# Function to execute PostgreSQL query with auto-detected credentials
execute_postgresql_query() {
    local query="$1"
    local db_name="${2:-postgres}"
    local credentials
    
    credentials=$(get_postgresql_credentials false "$db_name")
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    local method="${credentials%%:*}"
    local user_pass="${credentials#*:}"
    local user="${user_pass%%:*}"
    local password_db="${user_pass#*:}"
    local password="${password_db%%:*}"
    local database="${password_db#*:}"
    
    case "$method" in
        "sudo")
            # Use sudo -u postgres
            sudo -u postgres psql -d "$database" -c "$query" 2>/dev/null
            ;;
        "peer")
            # Use peer authentication
            psql -U "$user" -d "$database" -c "$query" 2>/dev/null
            ;;
        *)
            # Use provided credentials
            PGPASSWORD="$password" psql -U "$user" -d "$database" -c "$query" 2>/dev/null
            ;;
    esac
}

# Function to execute PostgreSQL query with error handling and output
execute_postgresql_query_with_output() {
    local query="$1"
    local db_name="${2:-postgres}"
    local error_msg="${3:-Failed to execute query}"
    local temp_error="/tmp/postgresql_error_$$.log"
    
    local credentials
    credentials=$(get_postgresql_credentials false "$db_name")
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    local method="${credentials%%:*}"
    local user_pass="${credentials#*:}"
    local user="${user_pass%%:*}"
    local password_db="${user_pass#*:}"
    local password="${password_db%%:*}"
    local database="${password_db#*:}"
    local result=0
    
    case "$method" in
        "sudo")
            # Use sudo -u postgres
            sudo -u postgres psql -d "$database" -c "$query" 2>"$temp_error" || result=1
            ;;
        "peer")
            # Use peer authentication
            psql -U "$user" -d "$database" -c "$query" 2>"$temp_error" || result=1
            ;;
        *)
            # Use provided credentials
            PGPASSWORD="$password" psql -U "$user" -d "$database" -c "$query" 2>"$temp_error" || result=1
            ;;
    esac
    
    if [[ $result -ne 0 ]]; then
        echo ""
        error "❌ $error_msg"
        if [[ -s "$temp_error" ]]; then
            local error_content=$(cat "$temp_error")
            echo "Error details:"
            echo "$error_content"
            
            # Handle specific role errors
            if [[ "$error_content" =~ "role.*does not exist" ]]; then
                handle_role_error "$error_content" "${user:-unknown}"
            fi
        fi
        # SAFETY: Skip file deletion to prevent accidental damage
        # rm -f "$temp_error"  # Commented out for safety
        return 1
    fi
    
    # SAFETY: Skip file deletion to prevent accidental damage  
    # rm -f "$temp_error"  # Commented out for safety
    return 0
}

# Function to execute pg_dump with auto-detected credentials
execute_pg_dump() {
    local db_name="$1"
    local credentials
    
    credentials=$(get_postgresql_credentials false "$db_name")
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    local method="${credentials%%:*}"
    local user_pass="${credentials#*:}"
    local user="${user_pass%%:*}"
    local password_db="${user_pass#*:}"
    local password="${password_db%%:*}"
    
    case "$method" in
        "sudo")
            # Use sudo -u postgres
            sudo -u postgres pg_dump "$db_name" 2>/dev/null
            ;;
        "peer")
            # Use peer authentication
            pg_dump -U "$user" "$db_name" 2>/dev/null
            ;;
        *)
            # Use provided credentials
            PGPASSWORD="$password" pg_dump -U "$user" "$db_name" 2>/dev/null
            ;;
    esac
}

# Function to execute psql restore with auto-detected credentials
execute_postgresql_restore() {
    local db_name="$1"
    local input_file="$2"
    local credentials
    
    credentials=$(get_postgresql_credentials false "$db_name")
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    local method="${credentials%%:*}"
    local user_pass="${credentials#*:}"
    local user="${user_pass%%:*}"
    local password_db="${user_pass#*:}"
    local password="${password_db%%:*}"
    
    case "$method" in
        "sudo")
            # Use sudo -u postgres
            sudo -u postgres psql -d "$db_name" < "$input_file" 2>/dev/null
            ;;
        "peer")
            # Use peer authentication
            psql -U "$user" -d "$db_name" < "$input_file" 2>/dev/null
            ;;
        *)
            # Use provided credentials
            PGPASSWORD="$password" psql -U "$user" -d "$db_name" < "$input_file" 2>/dev/null
            ;;
    esac
}

# Function to show menu
show_menu() {
    show_postgresql_version_info
    echo "📋 Available Options:"
    echo ""
    echo "   🔧 Installation & Setup:"
    echo "     1) Install PostgreSQL $POSTGRESQL_VERSION              - Download và cài đặt PostgreSQL $POSTGRESQL_VERSION"
    echo "     2) Check Installation Status          - Kiểm tra trạng thái cài đặt và service"
    echo "    18) Select PostgreSQL Version         - Chọn phiên bản PostgreSQL khác"
    echo "    19) Check Development Libraries        - Kiểm tra thư viện phát triển Rails"
    echo ""
    echo "   🗄️  Database Management:"
    echo "     3) Create Database                    - Tạo database mới với owner"
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
    echo "    15) Performance Tuning                - Điều chỉnh hiệu suất PostgreSQL"
    echo "    16) Reset PostgreSQL Password         - Đặt lại mật khẩu postgres user"
    echo "    17) Connection Troubleshoot            - Kiểm tra kết nối PostgreSQL"
    echo ""
    echo "     0) Exit                              - Thoát khỏi PostgreSQL Management"
    echo ""
}

# Function to install PostgreSQL 16
install_postgresql() {
    echo ""
    echo "🚀 PostgreSQL Installation Setup"
    echo "================================"
    
    # Version selection
    echo ""
    echo "📦 Step 1: Select PostgreSQL Version"
    select_postgresql_version
    update_script_title
    
    show_progress "Installing PostgreSQL $POSTGRESQL_VERSION"
    
    # Check if PostgreSQL is already installed
    if command -v psql &> /dev/null; then
        warning "PostgreSQL is already installed"
        local current_version=$(psql --version | cut -d' ' -f3 | cut -d'.' -f1)
        echo "Current version: $current_version"
        echo "Selected version: $POSTGRESQL_VERSION"
        
        if [[ "$current_version" == "$POSTGRESQL_VERSION" ]]; then
            echo "✅ Requested version is already installed"
            if ! prompt_yes_no "Continue with configuration?" "y"; then
                return 0
            fi
        else
            echo ""
            warning "⚠️  Different version detected!"
            echo "This will install PostgreSQL $POSTGRESQL_VERSION alongside existing version"
            echo "Multiple PostgreSQL versions can coexist with different ports"
            if ! prompt_yes_no "Continue with installation?" "n"; then
                return 0
            fi
        fi
    fi
    
    # Update package lists
    show_progress "Updating package lists"
    sudo apt update -q
    
    # Install PostgreSQL repository
    show_progress "Setting up PostgreSQL repository"
    sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
    sudo apt update -q
    
    # Install PostgreSQL packages
    show_progress "Installing PostgreSQL packages"
    sudo apt install -y postgresql-$POSTGRESQL_VERSION postgresql-contrib-$POSTGRESQL_VERSION postgresql-client-$POSTGRESQL_VERSION
    
    # Install development libraries for Rails compatibility
    show_progress "Installing PostgreSQL development libraries"
    sudo apt install -y libpq-dev postgresql-server-dev-$POSTGRESQL_VERSION build-essential
    success "PostgreSQL development libraries installed for Rails compatibility"
    
    # Enable and start PostgreSQL
    show_progress "Starting PostgreSQL service"
    sudo systemctl enable postgresql
    sudo systemctl start postgresql
    
    # Verify PostgreSQL is running
    if ! sudo systemctl is-active postgresql &> /dev/null; then
        error "PostgreSQL failed to start"
        echo "Please check PostgreSQL installation and try again"
        return 1
    fi
    success "PostgreSQL service started successfully"
    
    # Configure PostgreSQL
    if prompt_yes_no "Configure PostgreSQL with optimized settings?" "y"; then
        configure_postgresql
    fi
    
    # Configure remote access
    if prompt_yes_no "Configure PostgreSQL for remote access?" "y"; then
        configure_remote_access
    fi
    
    # Show installation summary
    echo ""
    echo "📋 Installation Summary:"
    echo "======================="
    echo "• PostgreSQL Version: $(psql --version | cut -d' ' -f3)"
    echo "• Service Status: $(systemctl is-active postgresql)"
    echo "• Configuration File: $POSTGRESQL_CONF_FILE"
    echo "• HBA Configuration: $POSTGRESQL_HBA_FILE"
    echo "• Log Directory: /var/log/postgresql/"
    echo "• Data Directory: /var/lib/postgresql/$POSTGRESQL_VERSION/main/"
    echo "• Development Libraries: ✅ Installed (libpq-dev, postgresql-server-dev)"
    echo ""
    echo "🎯 Rails Integration:"
    echo "   • pg gem: ✅ Ready to install"
    echo "   • Development headers: ✅ Available"
    echo ""
    
    success "PostgreSQL installation completed successfully"
}

# Function to configure PostgreSQL
configure_postgresql() {
    show_progress "Configuring PostgreSQL"
    
    # Get port configuration
    read -p "Enter PostgreSQL port (default 5432): " PG_PORT
    PG_PORT=${PG_PORT:-5432}
    
    # Validate port
    if ! [[ "$PG_PORT" =~ ^[0-9]+$ ]] || [ "$PG_PORT" -lt 1 ] || [ "$PG_PORT" -gt 65535 ]; then
        warning "Invalid port number. Using default 5432."
        PG_PORT=5432
    fi
    
    # Backup original configuration
    sudo cp "$POSTGRESQL_CONF_FILE" "$POSTGRESQL_CONF_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Configure PostgreSQL settings
    sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$POSTGRESQL_CONF_FILE"
    sudo sed -i "s/#port = 5432/port = $PG_PORT/" "$POSTGRESQL_CONF_FILE"
    sudo sed -i "s/#max_connections = 100/max_connections = 200/" "$POSTGRESQL_CONF_FILE"
    sudo sed -i "s/#shared_buffers = 128MB/shared_buffers = 256MB/" "$POSTGRESQL_CONF_FILE"
    sudo sed -i "s/#effective_cache_size = 4GB/effective_cache_size = 1GB/" "$POSTGRESQL_CONF_FILE"
    sudo sed -i "s/#maintenance_work_mem = 64MB/maintenance_work_mem = 128MB/" "$POSTGRESQL_CONF_FILE"
    sudo sed -i "s/#checkpoint_completion_target = 0.9/checkpoint_completion_target = 0.9/" "$POSTGRESQL_CONF_FILE"
    sudo sed -i "s/#wal_buffers = -1/wal_buffers = 16MB/" "$POSTGRESQL_CONF_FILE"
    sudo sed -i "s/#default_statistics_target = 100/default_statistics_target = 100/" "$POSTGRESQL_CONF_FILE"
    
    # Enable logging
    sudo sed -i "s/#log_destination = 'stderr'/log_destination = 'stderr'/" "$POSTGRESQL_CONF_FILE"
    sudo sed -i "s/#logging_collector = off/logging_collector = on/" "$POSTGRESQL_CONF_FILE"
    sudo sed -i "s/#log_directory = 'log'/log_directory = 'log'/" "$POSTGRESQL_CONF_FILE"
    sudo sed -i "s/#log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'/log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'/" "$POSTGRESQL_CONF_FILE"
    sudo sed -i "s/#log_line_prefix = '%m [%p] '/log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '/" "$POSTGRESQL_CONF_FILE"
    sudo sed -i "s/#log_min_duration_statement = -1/log_min_duration_statement = 1000/" "$POSTGRESQL_CONF_FILE"
    
    success "PostgreSQL configuration completed"
}

# Function to configure remote access
configure_remote_access() {
    show_progress "Configuring remote access"
    
    # Backup HBA configuration
    sudo cp "$POSTGRESQL_HBA_FILE" "$POSTGRESQL_HBA_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Update authentication methods
    sudo sed -i '/^local/s/peer/trust/' "$POSTGRESQL_HBA_FILE"
    sudo sed -i '/^host.*all.*all.*127.0.0.1/s/ident/md5/' "$POSTGRESQL_HBA_FILE"
    sudo sed -i '/^host.*all.*all.*::1/s/ident/md5/' "$POSTGRESQL_HBA_FILE"
    
    # Add remote access rule
    echo "host all all 0.0.0.0/0 md5" | sudo tee -a "$POSTGRESQL_HBA_FILE"
    
    # Restart PostgreSQL to apply changes
    sudo systemctl restart postgresql
    
    # Configure firewall
    if command -v ufw &> /dev/null; then
        sudo ufw allow 5432/tcp
        success "Firewall rule added for PostgreSQL"
    fi
    
    success "Remote access configuration completed"
}

# Function to create database
create_database() {
    show_progress "Creating new database"
    
    # Get database details
    local db_name
    local db_owner
    local encoding
    
    read -p "Enter new database name: " db_name
    validate_not_empty "$db_name" "Database name"
    
    db_owner=$(prompt_with_default "Database owner (leave empty for current user)" "")
    encoding=$(prompt_with_default "Database encoding" "UTF8")
    
    # Create database using auto-detected credentials
    local query="CREATE DATABASE \"$db_name\" WITH ENCODING='$encoding'"
    if [[ -n "$db_owner" ]]; then
        query="$query OWNER=\"$db_owner\""
    fi
    query="$query;"
    
    if execute_postgresql_query_with_output "$query" "postgres" "Failed to create database '$db_name'"; then
        success "✅ Database '$db_name' created successfully"
    else
        return 1
    fi
}

# Function to drop database
drop_database() {
    show_progress "Dropping database"
    
    # Get database name
    local db_name
    read -p "Enter database name to drop: " db_name
    validate_not_empty "$db_name" "Database name"
    
    # Confirmation
    if ! prompt_yes_no "Are you sure you want to drop database '$db_name'? This action cannot be undone!" "n"; then
        log "INFO" "Database drop cancelled"
        return 0
    fi
    
    # Drop database using auto-detected credentials
    local query="DROP DATABASE IF EXISTS \"$db_name\";"
    
    if execute_postgresql_query_with_output "$query" "postgres" "Failed to drop database '$db_name'"; then
        success "✅ Database '$db_name' dropped successfully"
    else
        return 1
    fi
}

# Function to create user
create_user() {
    show_progress "Creating new PostgreSQL user"
    
    # Test connection first using auto-detection
    show_progress "Testing database connection"
    local credentials
    credentials=$(get_postgresql_credentials)
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    success "✅ Database connection successful"
    
    # Get user details
    local username
    local password
    local confirm_password
    local user_type
    local database
    
    echo ""
    echo "⚠️  IMPORTANT: PostgreSQL User vs System User"
    echo "=============================================="
    echo "• This creates a PostgreSQL database user (for connecting to databases)"
    echo "• This is NOT a Linux system user (for logging into the server)"
    echo "• For system users, use: sudo useradd -m username"
    echo "• The error 'role \"55\" does not exist' suggests system/PostgreSQL user confusion"
    echo ""
    
    read -p "Enter new PostgreSQL username: " username
    validate_not_empty "$username" "Username"
    
    # Validate username (PostgreSQL naming rules)
    if [[ ! "$username" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        error "Invalid username. Use only letters, numbers, and underscores. Must start with letter or underscore."
        return 1
    fi
    
    # Check if user already exists
    show_progress "Checking if user '$username' already exists"
    local user_exists_query="SELECT 1 FROM pg_roles WHERE rolname='$username';"
    if execute_postgresql_query "$user_exists_query" "postgres" | grep -q "1"; then
        warning "⚠️  PostgreSQL user '$username' already exists"
        if ! prompt_yes_no "Continue to modify existing user?" "n"; then
            log "INFO" "User creation cancelled"
            return 0
        fi
        local user_exists=true
    else
        local user_exists=false
        success "✅ Username '$username' is available"
    fi
    
    while true; do
        read -s -p "Enter password for PostgreSQL user '$username': " password
        echo
        validate_not_empty "$password" "Password"
        
        # Validate password strength
        if [[ ${#password} -lt 8 ]]; then
            error "Password must be at least 8 characters long"
            continue
        fi
        
        read -s -p "Confirm password: " confirm_password
        echo
        
        if [[ "$password" == "$confirm_password" ]]; then
            break
        else
            error "Passwords do not match. Please try again."
            echo
        fi
    done
    
    echo "User Types:"
    echo "  1) Read-only user (SELECT)"
    echo "  2) Application user (SELECT, INSERT, UPDATE, DELETE)"
    echo "  3) Database owner (ALL PRIVILEGES)"
    echo "  4) Superuser (SUPERUSER)"
    read -p "Choose user type (1-4): " user_type
    
    read -p "Enter database name (or press Enter for all databases): " database
    database=${database:-""}
    
    # Create or alter user with better error handling
    echo ""
    if [[ "$user_exists" == "true" ]]; then
        show_progress "Modifying existing user '$username'"
        
        # Alter existing user
        local alter_query
        case "$user_type" in
            1) alter_query="ALTER USER \"$username\" WITH PASSWORD '$password';" ;;
            2) alter_query="ALTER USER \"$username\" WITH PASSWORD '$password';" ;;
            3) alter_query="ALTER USER \"$username\" WITH PASSWORD '$password';" ;;
            4) alter_query="ALTER USER \"$username\" WITH PASSWORD '$password' SUPERUSER;" ;;
            *) 
                error "Invalid user type"
                return 1
                ;;
        esac
        
        if ! execute_postgresql_query_with_output "$alter_query" "postgres" "Failed to modify user '$username'"; then
            return 1
        fi
        success "✅ User '$username' modified successfully"
    else
        show_progress "Creating new user '$username'"
        
        # Create new user with escaped username and password
        local create_query
        case "$user_type" in
            1) create_query="CREATE USER \"$username\" WITH PASSWORD '$password';" ;;
            2) create_query="CREATE USER \"$username\" WITH PASSWORD '$password';" ;;
            3) create_query="CREATE USER \"$username\" WITH PASSWORD '$password';" ;;
            4) create_query="CREATE USER \"$username\" WITH PASSWORD '$password' SUPERUSER;" ;;
            *) 
                error "Invalid user type"
                return 1
                ;;
        esac
        
        if ! execute_postgresql_query_with_output "$create_query" "postgres" "Failed to create user '$username'"; then
            error "❌ User creation failed. This might be due to:"
            echo "   • PostgreSQL service not running properly"
            echo "   • Authentication configuration issues"
            echo "   • Invalid username or password format"
            echo ""
            echo "🔧 Try these solutions:"
            echo "   1. Check PostgreSQL service: sudo systemctl status postgresql"
            echo "   2. Reset postgres password with option 16"
            echo "   3. Use connection troubleshoot with option 17"
            return 1
        fi
        success "✅ User '$username' created successfully"
    fi
    
    # Step 2: Grant permissions based on user type
    if [[ "$user_type" != "4" ]]; then  # Skip for superuser
        show_progress "Setting up permissions for user '$username'"
        
        if [[ -n "$database" ]]; then
            # Grant permissions on specific database
            local grant_query
            case "$user_type" in
                1) # Read-only
                    grant_query="GRANT CONNECT ON DATABASE \"$database\" TO \"$username\"; GRANT USAGE ON SCHEMA public TO \"$username\"; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"$username\"; ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO \"$username\";"
                    ;;
                2) # Application user
                    grant_query="GRANT CONNECT ON DATABASE \"$database\" TO \"$username\"; GRANT USAGE, CREATE ON SCHEMA public TO \"$username\"; GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"$username\"; ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO \"$username\";"
                    ;;
                3) # Database owner
                    grant_query="ALTER DATABASE \"$database\" OWNER TO \"$username\"; GRANT ALL PRIVILEGES ON DATABASE \"$database\" TO \"$username\";"
                    ;;
            esac
            
            if ! execute_postgresql_query_with_output "$grant_query" "$database" "Failed to grant permissions to '$username' on database '$database'"; then
                warning "⚠️  User created but permission assignment failed"
                echo "   You may need to grant permissions manually"
            else
                success "✅ Permissions granted on database '$database'"
            fi
        else
            warning "⚠️  No specific database specified"
            echo "   User created with basic login permissions only"
            echo "   Grant database permissions manually as needed"
        fi
    fi
    
    echo ""
    success "🎉 PostgreSQL user setup completed!"
    echo ""
    echo "📋 User Summary:"
    echo "================"
    echo "   • Username: $username"
    echo "   • User Type: $(case $user_type in 1) echo "Read-only user";; 2) echo "Application user";; 3) echo "Database owner";; 4) echo "Superuser";; esac)"
    if [[ -n "$database" ]]; then
        echo "   • Target Database: $database"
    else
        echo "   • Target Database: (none specified - basic login only)"
    fi
    echo ""
    echo "🔐 Connection Information:"
    echo "   • Host: localhost (or your server IP)"
    echo "   • Port: 5432 (default)"
    echo "   • Username: $username"
    echo "   • Password: [the password you set]"
    if [[ -n "$database" ]]; then
        echo "   • Database: $database"
    fi
    echo ""
    echo "💡 Test connection:"
    echo "   psql -U $username -d ${database:-postgres} -h localhost"
    echo ""
}

# Function to backup database
backup_database() {
    show_progress "Backing up database"
    
    # Get database details
    local db_name
    local backup_name
    
    read -p "Enter database name to backup: " db_name
    validate_not_empty "$db_name" "Database name"
    
    # Generate backup filename
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    backup_name=$(prompt_with_default "Backup filename" "${db_name}_backup_${timestamp}.sql")
    
    local backup_path="$BACKUP_DIR/$backup_name"
    
    # Create backup using auto-detected credentials
    show_progress "Creating backup with auto-detected credentials"
    if execute_pg_dump "$db_name" | gzip > "$backup_path.gz"; then
        success "✅ Database backup created: $backup_path.gz"
        log "INFO" "Backup size: $(du -h "$backup_path.gz" | cut -f1)"
    else
        error "Failed to create backup"
        return 1
    fi
}

# Function to restore database
restore_database() {
    show_progress "Restoring database"
    
    # Get restore details
    local target_db
    local backup_file
    
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
    local create_query="CREATE DATABASE IF NOT EXISTS \"$target_db\" WITH ENCODING='UTF8';"
    execute_postgresql_query_with_output "$create_query" "postgres" "Failed to create target database"
    
    # Restore from backup
    show_progress "Restoring from backup file"
    if [[ "$backup_file" == *.gz ]]; then
        if gunzip -c "$backup_file" | execute_postgresql_restore "$target_db" /dev/stdin; then
            success "✅ Database restored successfully to '$target_db'"
        else
            error "Failed to restore database"
            return 1
        fi
    else
        if execute_postgresql_restore "$target_db" "$backup_file"; then
            success "✅ Database restored successfully to '$target_db'"
        else
            error "Failed to restore database"
            return 1
        fi
    fi
}

# Function to show database status
show_database_status() {
    show_progress "Gathering database status"
    
    echo ""
    echo "📊 Database Status:"
    echo "=================="
    
    # Show databases
    echo "📋 Databases:"
    execute_postgresql_query "SELECT datname FROM pg_database WHERE datistemplate = false;" "postgres"
    
    echo ""
    echo "👥 Users:"
    execute_postgresql_query "SELECT usename, usesuper, usecreatedb FROM pg_user;" "postgres"
    
    echo ""
    echo "🔄 Active Connections:"
    execute_postgresql_query "SELECT datname, usename, client_addr, state FROM pg_stat_activity WHERE state = 'active';" "postgres"
    
    echo ""
    echo "📈 Status Information:"
    execute_postgresql_query "SELECT version();" "postgres"
    execute_postgresql_query "SHOW max_connections;" "postgres"
    execute_postgresql_query "SELECT count(*) as active_connections FROM pg_stat_activity;" "postgres"
}

# Function to check PostgreSQL installation status
check_installation_status() {
    echo ""
    echo "🔍 PostgreSQL Installation Status:"
    echo "=================================="
    
    # Check if PostgreSQL is installed
    if command -v psql &> /dev/null; then
        echo "• PostgreSQL Binary: ✅ Installed"
        echo "• Version: $(psql --version | cut -d' ' -f3)"
    else
        echo "• PostgreSQL Binary: ❌ Not installed"
        return 1
    fi
    
    # Check service status
    local service_status=$(systemctl is-active postgresql 2>/dev/null)
    case "$service_status" in
        "active") echo "• Service Status: ✅ Running" ;;
        "inactive") echo "• Service Status: ⚠️ Stopped" ;;
        "failed") echo "• Service Status: ❌ Failed" ;;
        *) echo "• Service Status: ❓ Unknown" ;;
    esac
    
    # Check if service is enabled
    local enabled_status=$(systemctl is-enabled postgresql 2>/dev/null)
    case "$enabled_status" in
        "enabled") echo "• Auto-start: ✅ Enabled" ;;
        "disabled") echo "• Auto-start: ⚠️ Disabled" ;;
        *) echo "• Auto-start: ❓ Unknown" ;;
    esac
    
    # Check configuration files
    if [[ -f "$POSTGRESQL_CONF_FILE" ]]; then
        echo "• Configuration: ✅ $POSTGRESQL_CONF_FILE"
    else
        echo "• Configuration: ⚠️ Not found"
    fi
    
    if [[ -f "$POSTGRESQL_HBA_FILE" ]]; then
        echo "• HBA Configuration: ✅ $POSTGRESQL_HBA_FILE"
    else
        echo "• HBA Configuration: ⚠️ Not found"
    fi
    
    # Check data directory
    if [[ -d "/var/lib/postgresql/$POSTGRESQL_VERSION/main" ]]; then
        echo "• Data Directory: ✅ /var/lib/postgresql/$POSTGRESQL_VERSION/main"
    else
        echo "• Data Directory: ❌ Not found"
    fi
    
    # Check development libraries
    check_postgresql_dev_libs
    
    echo ""
}

# Function to reset PostgreSQL password
reset_postgresql_password() {
    show_progress "Resetting PostgreSQL postgres user password"
    
    echo ""
    echo "🔐 PostgreSQL Password Reset:"
    echo "============================"
    echo ""
    echo "⚠️  This will reset the postgres user password."
    echo "    Make sure to remember the new password!"
    echo ""
    
    if ! prompt_yes_no "Continue with postgres password reset?" "n"; then
        log "INFO" "PostgreSQL password reset cancelled"
        return 0
    fi
    
    # Get new password
    local new_password
    local confirm_password
    
    while true; do
        read -s -p "Enter new postgres password: " new_password
        echo
        validate_not_empty "$new_password" "Password"
        
        read -s -p "Confirm new postgres password: " confirm_password
        echo
        
        if [[ "$new_password" == "$confirm_password" ]]; then
            break
        else
            error "Passwords do not match. Please try again."
            echo
        fi
    done
    
    # Reset password using sudo
    show_progress "Resetting postgres password"
    if sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$new_password';" 2>/dev/null; then
        success "✅ PostgreSQL postgres password reset successfully!"
        echo "📋 New credentials:"
        echo "   • Username: postgres"
        echo "   • Password: [the password you just set]"
        echo ""
        echo "⚠️  Please save this password securely!"
    else
        error "Failed to reset postgres password"
        return 1
    fi
}

# Function to connect to PostgreSQL without password (for troubleshooting)
connect_without_password() {
    show_progress "Testing PostgreSQL connection methods"
    
    echo ""
    echo "🔍 PostgreSQL Connection Troubleshoot:"
    echo "======================================"
    echo ""
    
    # Check PostgreSQL service first
    echo "0️⃣  Checking PostgreSQL service status"
    local service_status=$(systemctl is-active postgresql 2>/dev/null)
    case "$service_status" in
        "active") 
            echo "   ✅ PostgreSQL service is running"
            local service_enabled=$(systemctl is-enabled postgresql 2>/dev/null)
            echo "   ✅ Auto-start: $service_enabled"
            ;;
        "inactive") 
            echo "   ❌ PostgreSQL service is stopped"
            echo "   🔧 Fix: sudo systemctl start postgresql"
            if prompt_yes_no "Start PostgreSQL service now?" "y"; then
                sudo systemctl start postgresql
                if systemctl is-active postgresql &>/dev/null; then
                    success "✅ PostgreSQL service started successfully"
                else
                    error "❌ Failed to start PostgreSQL service"
                    echo "   Check logs: sudo journalctl -u postgresql"
                    return 1
                fi
            else
                return 1
            fi
            ;;
        "failed") 
            echo "   ❌ PostgreSQL service failed to start"
            echo "   🔧 Check logs: sudo journalctl -u postgresql"
            return 1
            ;;
        *) 
            echo "   ❓ PostgreSQL service status unknown"
            echo "   🔧 Try: sudo systemctl status postgresql"
            return 1
            ;;
    esac
    
    echo ""
    
    # Method 1: Try connecting using sudo -u postgres
    echo "1️⃣  Testing: sudo -u postgres psql"
    if timeout 10 sudo -u postgres psql -c "SELECT 'Connection successful' as status, version();" 2>/dev/null; then
        success "✅ Can connect using sudo -u postgres psql"
        echo "   📋 This is the recommended method for admin tasks"
        echo "   🔧 Use: sudo -u postgres psql"
        return 0
    else
        echo "   ❌ Cannot connect using sudo"
        echo "   🔍 Possible causes:"
        echo "      • PostgreSQL not properly initialized"
        echo "      • Permission issues"
        echo "      • Socket file missing"
    fi
    
    echo ""
    
    # Method 2: Try connecting with peer authentication
    echo "2️⃣  Testing: psql -U postgres"
    if timeout 10 psql -U postgres -c "SELECT 'Connection successful' as status;" 2>/dev/null; then
        success "✅ Can connect with peer authentication"
        echo "   🔧 Use: psql -U postgres"
        return 0
    else
        echo "   ❌ Cannot connect with peer authentication"
        echo "   🔍 Check /etc/postgresql/*/main/pg_hba.conf for peer auth settings"
    fi
    
    echo ""
    
    # Check listening ports
    echo "3️⃣  Checking PostgreSQL listening ports"
    local listening_ports=$(netstat -tlnp 2>/dev/null | grep :5432 || ss -tlnp 2>/dev/null | grep :5432)
    if [[ -n "$listening_ports" ]]; then
        echo "   ✅ PostgreSQL is listening on port 5432"
        echo "   $listening_ports"
    else
        echo "   ❌ PostgreSQL is not listening on port 5432"
        echo "   🔧 Check configuration file: $POSTGRESQL_CONF_FILE"
    fi
    
    echo ""
    
    # Check socket files
    echo "4️⃣  Checking PostgreSQL socket files"
    if [[ -S /var/run/postgresql/.s.PGSQL.5432 ]]; then
        echo "   ✅ Socket file exists: /var/run/postgresql/.s.PGSQL.5432"
        local socket_perms=$(ls -la /var/run/postgresql/.s.PGSQL.5432)
        echo "   📋 Permissions: $socket_perms"
    else
        echo "   ❌ Socket file missing: /var/run/postgresql/.s.PGSQL.5432"
        echo "   🔧 This indicates PostgreSQL is not running properly"
    fi
    
    echo ""
    
    # Check data directory
    echo "5️⃣  Checking PostgreSQL data directory"
    local data_dir="/var/lib/postgresql/$POSTGRESQL_VERSION/main"
    if [[ -d "$data_dir" ]]; then
        echo "   ✅ Data directory exists: $data_dir"
        local data_owner=$(stat -c '%U:%G' "$data_dir")
        echo "   📋 Owner: $data_owner"
        if [[ -f "$data_dir/PG_VERSION" ]]; then
            local pg_version=$(cat "$data_dir/PG_VERSION")
            echo "   📋 Database version: $pg_version"
        fi
    else
        echo "   ❌ Data directory missing: $data_dir"
        echo "   🔧 PostgreSQL may not be properly initialized"
        echo "   🔧 Try: sudo -u postgres initdb -D $data_dir"
    fi
    
    echo ""
    echo "🔧 Recommended troubleshooting steps:"
    echo "1. Use option 16 (Reset PostgreSQL Password) to set a known password"
    echo "2. Use 'sudo -u postgres psql' for administrative access"
    echo "3. Check service status with option 2"
    echo "4. Review PostgreSQL logs: sudo journalctl -u postgresql"
    echo "5. Check configuration files:"
    echo "   • $POSTGRESQL_CONF_FILE"
    echo "   • $POSTGRESQL_HBA_FILE"
    echo ""
}

# Function to get current installed PostgreSQL version  
get_current_postgresql_version() {
    if command -v psql &> /dev/null; then
        psql --version | cut -d' ' -f3 | cut -d'.' -f1
    else
        echo "Not installed"
    fi
}

# Function to show version info in menu header
show_postgresql_version_info() {
    local installed_version=$(get_current_postgresql_version)
    echo ""
    echo "📊 Version Information:"
    echo "======================="
    echo "• Selected Version: PostgreSQL $POSTGRESQL_VERSION"
    echo "• Installed Version: $installed_version"
    echo ""
}

# Function to get PostgreSQL service name based on version
get_postgresql_service_name() {
    # For Ubuntu, the service name is typically just 'postgresql'
    # But we can check for version-specific services too
    if systemctl list-units --type=service | grep -q "postgresql@${POSTGRESQL_VERSION}-main"; then
        echo "postgresql@${POSTGRESQL_VERSION}-main"
    else
        echo "postgresql"
    fi
}

# Function to check if development libraries are installed
check_postgresql_dev_libs() {
    echo ""
    echo "🔍 Checking PostgreSQL Development Libraries:"
    echo "============================================="
    
    # Check libpq-dev
    if dpkg -l | grep -q "libpq-dev"; then
        echo "• libpq-dev: ✅ Installed"
    else
        echo "• libpq-dev: ❌ Missing"
        echo "  Install with: sudo apt install libpq-dev"
    fi
    
    # Check postgresql-server-dev
    if dpkg -l | grep -q "postgresql-server-dev"; then
        echo "• postgresql-server-dev: ✅ Installed"
    else
        echo "• postgresql-server-dev: ❌ Missing"
        echo "  Install with: sudo apt install postgresql-server-dev-all"
    fi
    
    # Check build-essential
    if dpkg -l | grep -q "build-essential"; then
        echo "• build-essential: ✅ Installed"
    else
        echo "• build-essential: ❌ Missing"
        echo "  Install with: sudo apt install build-essential"
    fi
    
    echo ""
    echo "💎 Rails gem compatibility:"
    if dpkg -l | grep -q "libpq-dev" && dpkg -l | grep -q "postgresql-server-dev" && dpkg -l | grep -q "build-essential"; then
        echo "   ✅ pg gem can be installed successfully"
    else
        echo "   ❌ Missing libraries - pg gem installation may fail"
        echo "   📋 Quick fix: sudo apt install libpq-dev postgresql-server-dev-all build-essential"
    fi
    echo ""
}

# Function to handle role-related errors (like "role does not exist")
handle_role_error() {
    local error_message="$1"
    local username="$2"
    
    if [[ "$error_message" =~ "role.*does not exist" ]]; then
        echo ""
        error "❌ PostgreSQL role/user error detected"
        echo "Error details: $error_message"
        echo ""
        echo "🔍 This error typically occurs when:"
        echo "   • PostgreSQL tries to connect with a non-existent user"
        echo "   • User ID mapping conflicts (system vs PostgreSQL users)"
        echo "   • Authentication configuration issues"
        echo ""
        echo "🔧 Solutions:"
        echo "   1. Create the missing PostgreSQL user:"
        echo "      sudo -u postgres createuser $username"
        echo "   2. Reset authentication configuration"
        echo "   3. Use option 16 to reset postgres password"
        echo "   4. Use option 17 for detailed connection troubleshooting"
        echo ""
        return 1
    fi
    return 0
}

# Main function
main() {
    # Initialize script title
    update_script_title
    
    # Print header
    echo "================================================================"
    echo "              🐘 $SCRIPT_NAME (Enhanced)"
    echo "================================================================"
    
    log "INFO" "Starting PostgreSQL management"
    
    while true; do
        show_menu
        read -p "Choose an option: " choice
        
        case "$choice" in
            1) install_postgresql ;;
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
                log "INFO" "Database slave setup - coming soon"
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
            16) reset_postgresql_password ;;
            17) connect_without_password ;;
            18) 
                select_postgresql_version
                update_script_title
                success "PostgreSQL version changed to $POSTGRESQL_VERSION"
                ;;
            19) check_postgresql_dev_libs ;;
            0) 
                log "INFO" "Exiting PostgreSQL management"
                exit 0
                ;;
            *) 
                warning "Invalid option. Please choose 0-19."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run main function
main "$@"
