#!/bin/bash

MENU="
  ==========================================
                  MENU
  ==========================================
  1. Install dependencies for compiling Ruby            50. WSLSmartGit UI
  2. Install lib support image processing               51. WSL2 add some alias by IDE
  3. Install Redis and sidekiq 7                        52. Install docker
  4. Tạo deploy user
  5. Setup Database MySQL 8
  6. Setup Database PostgreSQL 15
  7. Install Rails
  8. Add Domain (Nginx/Host)
  12. Setup capitrano deploy

  100. Remove UTool
  Exit (q/quit/exit)

  Select one number: "

SCRIPT_PATH="$(realpath "$BASH_SOURCE")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

while true; do
  echo "$MENU"
  read -p "=> Select one: " INPUT
  echo "=================== START ===================="
  case "$INPUT" in
    1)
      sh $SCRIPT_DIR/ubuntu22/install_common_dev_libs.sh;;
    2)
      sh $SCRIPT_DIR/ubuntu22/image_lib.sh;;
    3)
      sh $SCRIPT_DIR/ubuntu22/sidekiq.sh;;
    4)
      sh $SCRIPT_DIR/ubuntu22/user.sh;;
    5)
      sh $SCRIPT_DIR/ubuntu22/mysql.sh;;
    6)
      sh $SCRIPT_DIR/ubuntu22/postgresql.sh;;
    7)
      sh $SCRIPT_DIR/ubuntu22/rails_setup.sh;;
    8)
      sh $SCRIPT_DIR/ubuntu22/nginx_ssl.sh;;
    50)
      sh $SCRIPT_DIR/wsl2/wsl2_smartgit.sh;;
    51)
      sh $SCRIPT_DIR/wsl2/wsl2_add_alias.sh;;
    100)
      bash $SCRIPT_DIR/uninstall_utool;;
    q|0|quit|exit)
      if [ "$INPUT" == "q" ] ]; then
        break
      fi;;
  esac

  echo "=================== END ===================="
  echo ""
  read -p "=> Enter any to continue or q to end: " NEW_INPUT

  if [ "$NEW_INPUT" == "q" ]; then
    break
  fi
done
