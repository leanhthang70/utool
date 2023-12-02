#!/bin/bash

echo "Smartgit Version 20.2.6"
RESOURCE_PATH="$HOME/.utool/resources"
SMARTGIT_2026_FILE="smartgit-linux-20_2_6.tar.gz"

read -p "=> Smartgit setup (Install enter 1/ Reset enter 2): " OPTION
read -p "=> Alias to run SmartGit (default smg): " SMARTGIT_ALIAS
SMARTGIT_ALIAS=${SMARTGIT_ALIAS:-smg}

if [ "$OPTION" -eq 1 ]; then
  sudo apt update && sudo apt full-upgrade -y
  sudo apt install gedit libgtk-3-0 -y

  tar -xvzf "$RESOURCE_PATH/$SMARTGIT_2026_FILE"
  cd  RESOURCE_PATH
  rm -rf $SMARTGIT_2026_FILE

  EXEC_BASH="cd $HOME/.utool/resources/smartgit/bin && nohup bash -c 'source smartgit.sh'; cd"
  EXEC_BASH="alias $SMARTGIT_ALIAS='source $HOME/.utool/resources/smartgit.sh'"
   echo "$EXEC_BASH" | sudo tee -a ~/.bashrc
elif [ "$OPTION" -eq 2 ]; then
  rm -rf $HOME/.config/smartgit/
else
  echo "Wrong input option (only 1 or 2) ! "
fi
