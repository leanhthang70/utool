#!/bin/bash

MENU="
  ==========================================
                  MENU
  ==========================================
  1. Install dependencies for compiling Ruby
  2. Install lib support image processing
  3. Install Redis and sidekiq 7
  4. Tạo deploy user
  5. Install Database PostgreSQL 15/ MySQL 8
  6. Install Rails
  7. Add Domain (Nginx/Host)
  8. Setup capitrano deploy
  9. Install docker
  Exit (q/quit/exit)
  Select one number: "

SCRIPT_PATH="$(realpath "$BASH_SOURCE")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

while true; do
  echo "$MENU"
  read -p "=> Nhập lựa chọn: " INPUT
  echo "=================== START ===================="
  case "$INPUT" in
    1)
      sh $SCRIPT_DIR/ubuntu22/install_dev_libs.sh;;
    2)
      sh $SCRIPT_DIR/ubuntu22/image_lib.sh;;
    3)
      sh $SCRIPT_DIR/ubuntu22/sidekiq.sh;;
    4)
      sh $SCRIPT_DIR/ubuntu22/user.sh;;
    5)
      sh $SCRIPT_DIR/ubuntu22/database.sh;;
    6)
      sh $SCRIPT_DIR/ubuntu22/rails_setup.sh;;
    7)
      sh $SCRIPT_DIR/ubuntu22/nginx_ssl.sh;;
    9)
      sh $SCRIPT_DIR/ubuntu22/nginx_ssl.sh;;
    q|0|quit|exit)
      if [ "$INPUT" == "q" ] ]; then
        break
      fi;;
  esac
done



