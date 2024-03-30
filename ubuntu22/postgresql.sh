#!/bin/bash

echo "1) Install PostgreSQL 16 "
echo "21) Create database "
echo "22) Drop database "
echo "31) Create user "
echo "32) Delete user "
echo "4) Change password "
echo "5) Backup database "
echo "6) Restore database "
echo "Enter to exit (q/quit/exit/0)"
read -p "=> Choose one option: " OPTION


if [ "$OPTION" = "q" ] || [ "$OPTION" = "0" ] || [ "$OPTION" = "quit" ] || [ "$OPTION" = "exit" ]; then
    echo "Exiting the script..."

  exec "$0"
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
  if [ "$REMOTE_CONNECTION" == "y" ]; then
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
  sudo -u postgres psql -c "ALTER USER $NEW_DB_USER WITH SELECT, INSERT, UPDATE, DELETE;"

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
  sudo -u postgres psql -c "CREATE USER $NEW_USERNAME WITH PASSWORD '$NEW_USERNAME';"
  sudo -u postgres psql -c "GRANT $PRIVILEGES ON DATABASE dbname TO $NEW_USERNAME;"

  echo "User '$NEW_USERNAME' has been created with privileges: $PRIVILEGES."
elif [ "$OPTION" -eq 32 ]; then
  # Prompt the user for the username to delete
  read -p "Enter the username to delete: " USER_TO_DELETE

  # Delete the user
  echo "Deleting user '$USER_TO_DELETE'..."
  sudo -u postgres psql -c "DROP ROLE IF EXISTS $USER_TO_DELETE;"

  echo "User '$USER_TO_DELETE' has been deleted."
fi

sh $(realpath "$0")