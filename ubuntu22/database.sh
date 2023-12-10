#!/bin/bash


echo "1) Install PostgreSQL 16 "
echo "1) Install Mariadb "
read -p "=> Choose database (PostgreSQL enter 1/ MySQL enter 2): " db_type

if [ "$db_type" -eq 1 ]; then
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
  read -p "=> Do you want allow remote connections? Yes(y): " option
  if [ "$option" == "y" ]; then
    sudo nano /etc/postgresql/16/main/postgresql.conf
    echo "listen_addresses = '*'" | sudo tee -a /etc/postgresql/16/main/postgresql.conf

    sudo sed -i '/^host/s/ident/md5/' /etc/postgresql/16/main/pg_hba.conf
    sudo sed -i '/^local/s/peer/trust/' /etc/postgresql/16/main/pg_hba.conf
    echo "host all all 0.0.0.0/0 md5" | sudo tee -a /etc/postgresql/16/main/pg_hba.conf
    sudo systemctl restart postgresql
    sudo ufw allow 5432/tcp
  fi
elif [ "$db_type" -eq 2 ]; then
  echo "=== Install Mariadb ==="
  sudo apt update
  sudo apt-get install libmysqlclient-dev
  sudo apt install mariadb-server
  sudo mysql_secure_installation
  sudo systemctl status mariadb &
  sudo mysqladmin version
else
  echo "Wrong input option (only 1 or 2) ! "
fi
