echo "1) Install Mariadb "
echo "2) Create database "
echo "3) Create user "
echo "4) Change password "
echo "5) Backup database "
echo "6) Restore database "
read -p "=> Choose one option: " option

if [ "$option" -eq 1 ]; then
  echo "=== Install 11.4.2-MariaDB ==="
  curl -LsS https://downloads.mariadb.com/MariaDB/mariadb\_repo\_setup | bash -s -- --mariadb-server-version=11.4.2
  sudo apt update
  sudo apt-get install libmysqlclient-dev
  sudo apt install mariadb-server mariadb-client -y
  sudo mysql_secure_installation
  sudo systemctl status mariadb
  sudo systemctl enable mariadb
  sudo systemctl start mariadb
elif [ "$option" -eq 2 ]; then # Create DB
  # Prompt the user for MySQL credentials
  read -p "Enter MySQL root username: " MYSQL_ROOT_USER
  read -p "Enter MySQL root password: " MYSQL_ROOT_PASSWORD
  echo # Move to the next line after password input

  # Prompt the user for new database and user details
  read -p "Enter new database name: " NEW_DB_NAME
  read -p "Enter new username for the database: " NEW_DB_USER
  read -p "Enter password for the new user: " NEW_DB_PASSWORD
  echo # Move to the next line after password input

  # MySQL queries to create a new database, user, and grant privileges
  MYSQL_QUERY="CREATE DATABASE IF NOT EXISTS \`${NEW_DB_NAME}\`;"
  MYSQL_QUERY+="CREATE USER '${NEW_DB_USER}'@'localhost' IDENTIFIED BY '${NEW_DB_PASSWORD}';"
  MYSQL_QUERY+="GRANT ALL PRIVILEGES ON \`${NEW_DB_NAME}\`.* TO '${NEW_DB_USER}'@'localhost';"
  MYSQL_QUERY+="FLUSH PRIVILEGES;"

  # Execute the MySQL queries
  mysql -u"${MYSQL_ROOT_USER}" -p"${MYSQL_ROOT_PASSWORD}" -e"${MYSQL_QUERY}"

  # Check for errors
  if [ $? -eq 0 ]; then
      echo "Database and user created successfully."
  else
      echo "Error: Failed to create database and user."
  fi
elif [ "$option" -eq 3 ]; then # Create user
  # Prompt the user for MySQL credentials
  read -p "Enter MySQL username: " MYSQL_USER
  read -p "Enter MySQL password: " MYSQL_PASSWORD
  echo # Move to the next line after password input
  read -p "Enter MySQL database name: " MYSQL_DATABASE

  # Prompt the user for new user details
  read -p "Enter new username: " NEW_USERNAME
  read -p "Enter new user password: " NEW_USER_PASSWORD
  echo # Move to the next line after password input

  # MySQL query to create a new user
  MYSQL_QUERY="CREATE USER '${NEW_USERNAME}'@'localhost' IDENTIFIED BY '${NEW_USER_PASSWORD}';"
  MYSQL_QUERY+="GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${NEW_USERNAME}'@'localhost';"
  MYSQL_QUERY+="FLUSH PRIVILEGES;"

  # Execute the MySQL query
  mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e"${MYSQL_QUERY}"
elif [ "$option" -eq 4 ]; then # Change password
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
elif [ "$option" -eq 5 ]; then # Backup DB
  # Prompt the user for MySQL credentials
  read -p "Enter MySQL username: " MYSQL_USER
  read -p "Enter MySQL password: " MYSQL_PASSWORD
  echo # Move to the next line after password input
  read -p "Enter MySQL database name: " MYSQL_DATABASE

  # Prompt the user for the backup file name
  read -p "Enter backup file name (e.g., backup.sql): " BACKUP_FILE

  # mysqldump command to create a backup
  mysqldump -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" > "${BACKUP_FILE}"

  # Check for errors
  if [ $? -eq 0 ]; then
      echo "Backup completed successfully. File saved as ${BACKUP_FILE}."
  else
      echo "Error: Backup failed."
  fi
elif [ "$option" -eq 6 ]; then # Restore DB
  # Prompt the user for MySQL credentials
  read -p "Enter MySQL username: " MYSQL_USER
  read -p "Enter MySQL password: " MYSQL_PASSWORD
  echo # Move to the next line after password input

  # Prompt the user for the current and new database names
  read -p "Enter the current database name in the dump: " CURRENT_DB_NAME
  read -p "Enter the new database name for restoration: " NEW_DB_NAME

  # Prompt the user for the SQL dump file name
  read -p "Enter SQL dump file name (e.g., backup.sql): " DUMP_FILE

  # Use sed to replace the old database name with the new one
  sed -i "s/\`${CURRENT_DB_NAME}\`/\`${NEW_DB_NAME}\`/g" "${DUMP_FILE}"

  # Restore the modified SQL dump file
  mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS \`${NEW_DB_NAME}\`;"
  mysql --verbose -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${NEW_DB_NAME}" < "${DUMP_FILE}"

  # Check for errors
  if [ $? -eq 0 ]; then
      echo "Database restoration completed successfully. Database name changed to ${NEW_DB_NAME}."
  else
      echo "Error: Database restoration failed."
  fi
else
  echo "Wrong input option (only 1 or 2) ! "
fi
