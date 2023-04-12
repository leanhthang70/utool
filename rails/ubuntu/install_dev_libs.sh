#!/bin/bash

echo "=== Install dependencies for compiling Ruby ==="

sudo apt-get update
sudo apt-get install curl gnupg git-core zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev -y

echo "=== Install Node JS ==="
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs

echo "=== Install Nginx ==="
sudo apt-get install -y nginx
sudo systemctl enable nginx

echo "=== Install Redis ==="
sudo apt-get install redis-server -y
sudo systemctl enable redis-server
sudo systemctl restart redis-server

echo "=== Install RBENV ==="
cd
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc
rbenv -v

echo "=== Install Let's Encrypt SSL ==="
sudo apt update && sudo apt upgrade
sudo apt install certbot -y

echo "==================== END ===================="
