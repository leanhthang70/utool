#!/bin/bash

echo "Smartgit Version 20_1_6"
RESOURCE_PATH="$HOME/.utool/resources"
SMARTGIT_VERSION="smartgit-linux-20_1_6.tar.gz"

read -p "=> Smartgit setup (Install enter 1/ Reset enter 2): " OPTION
read -p "=> Alias to run SmartGit (default smg): " SMARTGIT_ALIAS
SMARTGIT_ALIAS=${SMARTGIT_ALIAS:-smg}

if [ "$OPTION" -eq 1 ]; then
  sudo apt update && sudo apt full-upgrade -y
  sudo apt install gedit libgtk-3-0 -y
  sudo apt install default-jre -y
  sudo apt install default-jdk -y

  rm -rf smartgit

  cd $HOME/.utool/resources
  curl -L -o $SMARTGIT_VERSION https://www.syntevo.com/downloads/smartgit/archive/$SMARTGIT_VERSION

  tar -xvzf $SMARTGIT_VERSION
  rm -rf $SMARTGIT_VERSION

  EXEC_BASH="alias $SMARTGIT_ALIAS='cd $HOME/.utool/resources/smartgit/bin/ && source smartgit.sh'"
  grep -v "$EXEC_PATH" ~/.bashrc > temp_file && mv temp_file ~/.bashrc
  sleep 1
  echo "$EXEC_BASH" | sudo tee -a ~/.bashrc
elif [ "$OPTION" -eq 2 ]; then
  rm -rf $HOME/.config/smartgit/
else
  echo "Wrong input option (only 1 or 2) ! "
fi
