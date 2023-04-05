#!/bin/bash

echo "=== Install dependencies for compiling Ruby ==="

sudo apt-get update
sudo apt-get install curl gnupg git-core zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev -y

echo "=== Install Node JS ==="
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs

echo "=== Install ASDF ==="
cd
git clone https://github.com/excid3/asdf.git ~/.asdf
echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc
echo '. "$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc
echo 'legacy_version_file = yes' >> ~/.asdfrc
echo 'export EDITOR="code --wait"' >> ~/.bashrc
exec $SHELL &
asdf plugin-add ruby
asdf plugin-add nodejs
asdf plugin-add golang

echo "==================== END ===================="
