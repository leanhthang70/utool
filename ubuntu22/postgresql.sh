#!/bin/bash

# PostgreSQL 16 Management Script
# Provides comprehensive PostgreSQL management with proper error handling

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

# Print header
clear
echo "================================================================"
echo "       🐘 $SCRIPT_NAME"
echo "================================================================"

# Function to show menu
show_menu() {
    echo ""
    echo "📋 Available Options:"
    echo ""
    echo "   🔧 Installation & Setup:"
    echo "     1) Install PostgreSQL 16              - Cài đặt PostgreSQL 16 với remote access"
    echo ""
    echo "   🗄️  Database Management:"
    echo "    21) Create Database                    - Tạo database mới với owner"
    echo "    22) Drop Database                      - Xóa database (cẩn thận!)"
    echo ""
    echo "   👥 User Management:"
    echo "    31) Create User                        - Tạo user với quyền tùy chỉnh"
    echo "    32) Delete User                        - Xóa user khỏi PostgreSQL"
    echo "     4) Change Password                    - Đổi mật khẩu user"
    echo ""
    echo "   💾 Backup & Restore:"
    echo "     5) Backup Database                    - Sao lưu database ra file .sql"
    echo "     6) Restore Database                   - Khôi phục database từ backup"
    echo ""
    echo "     0) Exit                              - Thoát khỏi PostgreSQL Management"
    echo ""
}

# Show menu and get user choice
show_menu
read -p "=> Choose one option: " OPTION


if [ "$OPTION" = "q" ] || [ "$OPTION" = "0" ] || [ "$OPTION" = "quit" ] || [ "$OPTION" = "exit" ]; then
    echo "Exiting the script..."

  exit 0
elif [ "$OPTION" -eq 1 ]; then
  echo "=== Install postgreSQL 16 ==="
  sudo apt update -y
  sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
  sudo apt update -y

  sudo apt install postgresql-16 postgresql-contrib-16 -y

  sudo systemctl start postgresql
  sudo systemctl enable postgresql

  sudo systemctl status postgresql
  psql --version

  echo "================================"
  echo "Edit to allow remote connections"
  read -p "=> Do you want allow remote connections? Yes(y): " REMOTE_CONNECTION
  if [ "$REMOTE_CONNECTION" = "y" ]; then
    sudo nano /etc/postgresql/16/main/postgresql.conf
    echo "listen_addresses = '*'" | sudo tee -a /etc/postgresql/16/main/postgresql.conf

    sudo sed -i '/^host/s/ident/md5/' /etc/postgresql/16/main/pg_hba.conf
    sudo sed -i '/^local/s/peer/trust/' /etc/postgresql/16/main/pg_hba.conf
    echo "host all all 0.0.0.0/0 md5" | sudo tee -a /etc/postgresql/16/main/pg_hba.conf
    sudo systemctl restart postgresql
    sudo ufw allow 5432/tcp
  fi
elif [ "$OPTION" -eq 22 ]; then # Drop DB
  # Prompt the user for the database name to delete
  read -p "Enter the database name to delete: " DB_TO_DELETE

  # Drop the database
  echo "Dropping database '$DB_TO_DELETE'..."
  sudo -u postgres psql -c "DROP DATABASE IF EXISTS $DB_TO_DELETE;"

  echo "Database '$DB_TO_DELETE' has been dropped."
elif [ "$OPTION" -eq 21 ]; then # Create DB
  # Prompt the user for new database and user details
  read -p "Enter new database name: " NEW_DB_NAME
  read -p "Enter new username for the database: " NEW_DB_USER
  read -p "Enter password for the new user: " NEW_DB_PASSWORD
  echo # Move to the next line after password input

  # Create new database
  echo "Creating database '$NEW_DB_NAME'..."
  sudo -u postgres psql -c "CREATE DATABASE $NEW_DB_NAME;"

  # Create new user and grant permissions
  echo "Creating user '$NEW_DB_USER'..."
  sudo -u postgres psql -c "CREATE USER $NEW_DB_USER WITH PASSWORD '$NEW_DB_PASSWORD';"
  echo "Granting permissions to user '$NEW_DB_USER'..."
  sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $NEW_DB_NAME TO $NEW_DB_USER;"
  sudo -u postgres psql -c "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO $NEW_DB_USER;"

  echo "Database '$NEW_DB_NAME' and user '$NEW_DB_USER' have been created."

elif [ "$OPTION" -eq 31 ]; then # Create user
  # Prompt the user for new username
  read -p "Enter new username: " NEW_USERNAME

  # Prompt the user for the type of user
  echo "Choose the type of user:"
  echo "1. Read-only user"
  echo "2. User with SELECT, INSERT, UPDATE, DELETE privileges"
  echo "3. User with SUPERUSER privileges"
  read -p "Enter your choice [1, 2 or 3]: " CHOICE

  # Check the choice and set privileges accordingly
  case $CHOICE in
      1)
          PRIVILEGES="SELECT";;
      2)
          PRIVILEGES="SELECT, INSERT, UPDATE, DELETE";;
      3)
          PRIVILEGES="SUPERUSER";;
      *)
          echo "Invalid choice. Exiting."
          exit 1;;
  esac

  # Create the user with specified privileges
  echo "Creating user '$NEW_USERNAME' with privileges: $PRIVILEGES ..."
  read -p "Enter password for new user: " NEW_USER_PASSWORD
  sudo -u postgres psql -c "CREATE USER $NEW_USERNAME WITH PASSWORD '$NEW_USER_PASSWORD';"
  sudo -u postgres psql -c "GRANT $PRIVILEGES ON DATABASE dbname TO $NEW_USERNAME;"

  echo "User '$NEW_USERNAME' has been created with privileges: $PRIVILEGES."
elif [ "$OPTION" -eq 32 ]; then
  # Prompt the user for the username to delete
  read -p "Enter the username to delete: " USER_TO_DELETE

  # Delete the user
  echo "Deleting user '$USER_TO_DELETE'..."
  sudo -u postgres psql -c "DROP ROLE IF EXISTS $USER_TO_DELETE;"

  echo "User '$USER_TO_DELETE' has been deleted."
# For backup database
elif [ "$OPTION" -eq 5 ]; then
  echo "=== Backup PostgreSQL Database ==="
  # Get database credentials
  read -p "Enter database name to backup: " DB_NAME
  read -p "Enter backup file name (e.g., backup.sql): " BACKUP_FILE

  # Create backup directory if it doesn't exist
  BACKUP_DIR="$HOME/backups"
  mkdir -p "$BACKUP_DIR"

  # Create backup with timestamp
  TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
  BACKUP_PATH="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}_${BACKUP_FILE}"

  echo "Creating backup of $DB_NAME to $BACKUP_PATH..."
  sudo -u postgres pg_dump "$DB_NAME" | gzip > "$BACKUP_PATH.sql.gz"

  if [ $? -eq 0 ]; then
    echo "Backup completed successfully"
    echo "Backup saved to: $BACKUP_PATH"
  else
    echo "Error: Backup failed"
  fi

# For restore database
elif [ "$OPTION" -eq 6 ]; then
  echo "=== Restore PostgreSQL Database ==="
  read -p "Enter target database name: " DB_NAME
  read -p "Enter backup file path to restore: " BACKUP_FILE
  # read -p "Enter user make restore: " USER_NAME

  # Check if backup file exists
  if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not found!"
    exit 1
  fi

  # Check if database exists, if not create it
  echo "Creating database if it doesn't exist..."
  sudo -u postgresql psql -c "CREATE DATABASE $DB_NAME;" 2>/dev/null

  echo "Restoring backup to $DB_NAME..."
  # sudo -u postgres psql "$DB_NAME" < "$BACKUP_FILE"
  gunzip -c "$BACKUP_PATH.sql.gz" | sudo psql -U postgresql "$DB_NAME"

  if [ $? -eq 0 ]; then
    echo "Restore completed successfully"
  else
    echo "Error: Restore failed"
  fi
fi

# Return to original directory
if [[ -n "$ORIGINAL_DIR" && -d "$ORIGINAL_DIR" ]]; then
    cd "$ORIGINAL_DIR"
    echo "Returned to original directory: $ORIGINAL_DIR"
fi
