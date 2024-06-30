echo "1) Install Mariadb "
echo "2) Create database "
echo "3) Create user "
echo "4) Change password "
echo "5) Backup database "
echo "6) Restore database "
read -p "=> Choose one option: " OPTION

if [ "$OPTION" -eq 1 ]; then
  echo "=== Install 11.4.2-MariaDB ==="
  curl -LsS https://downloads.mariadb.com/MariaDB/mariadb\_repo\_setup | bash -s -- --mariadb-server-version=11.4.2
  sudo apt update
  sudo apt-get install libmysqlclient-dev
  sudo apt install mariadb-server mariadb-client -y
  sudo mysql_secure_installation

  echo "=== Change Port ==="
  read -p "7) Open connection via port (default 3306): " MYSQL_PORT
  if [ -z "$MYSQL_PORT" ]; then
    MYSQL_PORT=3306
  fi
  sed -i "/^\[client-server\]/a port = $MYSQL_PORT" /etc/mysql/my.cnf
  # Allow remote access
  # sudo ufw enable
  # sudo ufw allow 22
  # sudo ufw allow $MYSQL_PORT
  # sudo ufw status

  # Kiểm tra xem đã có phần [mysqld] trong file hay chưa
  echo "=== Config MariaDB ==="
  if ! grep -q "^\[mysqld\]" /etc/mysql/my.cnf; then
      echo "[mysqld]" | sudo tee -a /etc/mysql/my.cnf
  fi
  echo "Please manually add the following configurations to the /etc/mysql/my.cnf file under the [mysqld] section:"
  echo "innodb_buffer_pool_size=(TOTAl OF RAM*0.7)G"
  echo "bind-address = 0.0.0.0 # Allow remote access"
  echo "max_connections = 500 # Maximum connections"
  echo "interactive_timeout = 300 # Maximum time to wait for a connection"
  echo "wait_timeout = 300 # Maximum time to wait for a connection"
  echo "innodb_file_per_table = 1 # Enable file per table"
  echo "query_cache_size = 256MB # Query cache size"
  echo "innodb_log_file_size=512MB # Log file size"
  echo "innodb_log_buffer_size=128MB # Log buffer size"
  echo "innodb_strict_mode = ON # Strict mode"
  echo "tmp_table_size=128MB # Temporary table size"
  echo "thread_cache_size=256 # Thread cache size"
  echo "innodb_lock_wait_timeout=120 # Lock wait timeout"
  echo "character-set-server=utf8mb4 # Character set"
  echo "character_set_client=utf8mb4 # Character set"
  echo "collation-server=utf8mb4_general_ci # Collation"

  sudo systemctl enable mariadb
  sudo systemctl start mariadb
  sudo systemctl status mariadb

elif [ "$OPTION" -eq 2 ]; then # Create DB
  echo "=== Create new database ==="
  # Prompt the user for MySQL credentials
  read -p "Enter MySQL root username (root): " ROOT_USER
  read -p "Enter MySQL root password: " ROOT_PASSWORD
  echo # Move to the next line after password input

  # Prompt the user for new database and user details
  read -p "Enter new database name: " NEW_DB_NAME

  # MySQL queries to create a new database, user, and grant privileges
  MYSQL_QUERY="CREATE DATABASE IF NOT EXISTS ${NEW_DB_NAME};"
  mariadb -u"${ROOT_USER}" -p"${ROOT_PASSWORD}" -e"${MYSQL_QUERY}"
  echo "Database created successfully."

elif [ "$OPTION" -eq 3 ]; then # Create user
  echo "=== Create new user ==="
  # Prompt the user for MySQL credentials
  echo "=== MySQL credentials can Create user =="
  ROOT_USER="root"
  read -p "Enter MySQL root password: " ROOT_PASSWORD

  # Prompt the user for new user details
  echo "=== New user details ==="
  read -p "Type of new user (1 => app; 2 => readonly; 3 => full_permission): " TYPE_USER
  read -p "Remote access type (1 => all; 2 => localhost; 3 => IP) : " REMOTE_ACCESS
  read -p "Enter new db username: " NEW_DB_USER
  read -p "Enter new db password: " NEW_DB_PASSWORD
  read -p "Choose database to add user (leave empty to apply to all): " DB_NAME

  if [ "$REMOTE_ACCESS" -eq 1 ]; then
    HOST="%"
  elif [ "$REMOTE_ACCESS" -eq 2 ]; then
    HOST="localhost"
  elif [ "$REMOTE_ACCESS" -eq 3 ]; then
    read -p "Enter IP address: " REMOTE_IP
    HOST="$REMOTE_IP"
  fi

  if [ "$TYPE_USER" -eq 1 ]; then
    PERMISSION="CREATE, SELECT, INSERT, UPDATE, DELETE, INDEX, ALTER"
  elif [ "$TYPE_USER" -eq 2 ]; then
    PERMISSION="SELECT"
  elif [ "$TYPE_USER" -eq 3 ]; then
    PERMISSION="ALL PRIVILEGES"
  fi

  if [ -z "$DB_NAME" ]; then
    NEW_DB_NAME="*"
  else
    NEW_DB_NAME=$DB_NAME
  fi
  echo "=== Create new user ==="

  # Create a new user for the database
  MYSQL_QUERY="CREATE USER IF NOT EXISTS ${NEW_DB_USER}@'$HOST' IDENTIFIED BY '${NEW_DB_PASSWORD}';"
  mariadb -u"${ROOT_USER}" -p"${ROOT_PASSWORD}" -e"${MYSQL_QUERY}"
  echo "User $NEW_DB_USER created successfully."

  # Grant privileges to the new user on the new database
  MYSQL_QUERY="GRANT $PERMISSION ON ${NEW_DB_NAME}.* TO '${NEW_DB_USER}'@'$HOST';"
  mariadb -u"${ROOT_USER}" -p"${ROOT_PASSWORD}" -e"${MYSQL_QUERY}"
  MYSQL_QUERY="FLUSH PRIVILEGES;"
  mariadb -u"${ROOT_USER}" -p"${ROOT_PASSWORD}" -e"${MYSQL_QUERY}"
  echo "Privileges granted successfully."

elif [ "$OPTION" -eq 4 ]; then # Change password
  # Prompt the user for MySQL credentials
  read -p "Enter MySQL username: " MYSQL_USER
  read -p "Enter MySQL current password: " MYSQL_CURRENT_PASSWORD
  echo # Move to the next line after password input
  read -p "Enter MySQL database name: " MYSQL_DATABASE

  # Prompt the user for the new password
  read -p "Enter the new password: " NEW_PASSWORD
  echo # Move to the next line after password input

  # MySQL query to change the user password
  MYSQL_QUERY="SET PASSWORD FOR '${MYSQL_USER}'@'localhost' = PASSWORD('${NEW_PASSWORD}');"
  MYSQL_QUERY+="FLUSH PRIVILEGES;"

  # Execute the MySQL query
  mysql -u"${MYSQL_USER}" -p"${MYSQL_CURRENT_PASSWORD}" -e"${MYSQL_QUERY}" "${MYSQL_DATABASE}"

  # Check for errors
  if [ $? -eq 0 ]; then
      echo "Password for user ${MYSQL_USER} changed successfully."
  else
      echo "Error: Failed to change password for user ${MYSQL_USER}."
  fi
elif [ "$OPTION" -eq 5 ]; then # Backup DB
  echo "=== Backup database ==="
  # Prompt the user for MySQL credentials
  ROOT_USER="root"
  read -p "Enter MySQL root password: " ROOT_PASSWORD
  echo # Move to the next line after password input
  read -p "Enter MySQL database name: " MYSQL_DATABASE

  # Prompt the user for the backup file name
  read -p "Enter backup file name / path (e.g., backup.sql): " BACKUP_FILE

  # mysqldump command to create a backup
  mysqldump -u"${ROOT_USER}" -p"${ROOT_PASSWORD}" "${MYSQL_DATABASE}" > "${BACKUP_FILE}"

  # Check for errors
  if [ $? -eq 0 ]; then
      echo "Backup completed successfully. File saved as ${BACKUP_FILE}."
  else
      echo "Error: Backup failed."
  fi
elif [ "$OPTION" -eq 6 ]; then # Restore DB
  # Prompt the user for MySQL credentials
  echo "=== MySQL credentials can Restore DB ==="
  ROOT_USER="root"
  read -p "Enter MySQL root password: " ROOT_PASSWORD
  echo # Move to the next line after password input

  # Prompt the user for the current and new database names
  read -p "Enter the current database name in the dump: " CURRENT_DB_NAME
  read -p "Enter the new database name for restoration: " NEW_DB_NAME

  # Prompt the user for the SQL dump file name
  read -p "Enter SQL dump file name (e.g., backup.sql): " DUMP_FILE

  # Use sed to replace the old database name with the new one
  if [ "$CURRENT_DB_NAME" != "$NEW_DB_NAME" ]; then
    sed -i "s/\`${CURRENT_DB_NAME}\`/\`${NEW_DB_NAME}\`/g" "${DUMP_FILE}"
  fi

  # Restore the modified SQL dump file
  mariadb -u"${ROOT_USER}" -p"${ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS \`${NEW_DB_NAME}\`;"
  # mariadb -u"${ROOT_USER}" -p"${ROOT_PASSWORD}" "${NEW_DB_NAME}" < "${DUMP_FILE}"
  mysql --verbose -u"${ROOT_USER}" -p"${ROOT_PASSWORD}" "${NEW_DB_NAME}" < "${DUMP_FILE}"

  # Check for errors
  if [ $? -eq 0 ]; then
      echo "Database restoration completed successfully. Database name changed to ${NEW_DB_NAME}."
  else
      echo "Error: Database restoration failed."
  fi
else
  echo "Wrong input option (from 1 to 6) ! "
fi
