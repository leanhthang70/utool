#!/bin/bash

menu="
  ==========================================
                  MENU
  ==========================================
  1. Install dependencies for compiling Ruby
  2. Install lib support image processing
  3. Install Redis and sidekiq 6/7
  4. Tạo deploy user
  5. Install Database PostgreSQL 15/ MySQL 8
  6. Install Rails
  7. Add Domain (Nginx/Host)
  9. Install Mina deploy
  9. Install docker
  11. test
  Exit (q/quit/exit)
  Select one number: "
root_path=$(pwd)

while true; do
  clear
  echo "$menu"
  read -p "=> Nhập lựa chọn: " input
  echo "=================== START ===================="
  case "$input" in
    1)
      sh $root_path/rails/ubuntu/install_dev_libs.sh;;
    2)
      sh $root_path/rails/ubuntu/image_lib.sh;;
    3)
      sh $root_path/rails/ubuntu/sidekiq.sh;;
    4)
      sh $root_path/rails/ubuntu/user.sh;;
    5)
      sh $root_path/rails/ubuntu/database.sh;;
    6)
      sh $root_path/rails/ubuntu/rails_setup.sh;;
    7)
      sh $root_path/rails/ubuntu/nginx_ssl.sh;;
    q|0|quit|exit)
      if [ "$input" == "q" ] ]; then
        break
      fi;;
  esac

  cd "$root_path"
  echo "=================== END ===================="
  echo ""
  read -p "=> Nhập bất kỳ để tiếp tục hoặc q để kết thúc: " new_input
  if [ "$new_input" == "q" ]; then
    break
  else
    clear
  fi
done
