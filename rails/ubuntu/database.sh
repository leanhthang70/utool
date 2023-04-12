#!/bin/bash

read -p "=> Choose database (PostgreSQL enter 1/ MySQL enter 2): " db_type

if [$db_type -eq 1 ]; then
  echo "=== Install postgreSQL 15 ==="

  sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo tee /etc/apt/trusted.gpg.d/pgdg.asc &>/dev/null
  sudo apt install postgresql postgresql-client libpq-dev postgresql-contrib -y

  sudo systemctl status postgresql
  psql --version

elif [$db_type -eq 2 ]; then
  echo "=== Install MySQL 8 ==="
  sudo apt-get install mysql-server mysql-client libmysqlclient-dev
else
  echo "Chỉ hỗ trợ cài đặt postgreSQL/ MySQL xin vui lòng nhập đúng"
fi

