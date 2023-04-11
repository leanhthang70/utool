#!/bin/bash

menu="
  ==========================================
                  MENU
  ==========================================
  1. Install dependencies for compiling Ruby
  2. Install lib support image processing
  3. Tạo deploy user
  3. Install Database PostgreSQL 15/ MySQL 8
  5. Install Redis / sidekiq 6/7
  6. Install Rails
  7. Add Domain (Nginx/Host)
  9. Install docker
  11. test
  Exit (q/quit/exit)
  Select one number: "
root_path=$(pwd)

while true; do
  clear
  echo "$menu"
  read -p "Nhập lựa chọn: " input
  echo "=================== START ===================="
  case "$input" in
    1)
      sh "${root_path}/rails/ubuntu/install_dev_libs.sh";;
    2)
      sh "${root_path}/rails/ubuntu/image_lib.sh";;
    3)
      read -p "Enter user deploy: " user_deploy_app
      read -p "Sidekiq version 6/7: " sidekiq_version
      read -p "Project path: " project_path
      read -p "Sidekiq file name: " sidekiq_file_name
      sh "${root_path}/rails/ubuntu/sidekiq.sh ${user_deploy_app} ${sidekiq_version} ${project_path} ${sidekiq_file_name}";;
    4)
      read -p "Choose database (PostgreSQL enter 1/ MySQL enter 2): " db_type
      sh "${root_path}/rails/ubuntu/database.sh db_type";;
    5)
      read -p "Nhập domain_name: " domain_name
      sh "${root_path}/rails/ubuntu/template_nginx.sh ${domain_name}";;
    6)
      sh "${root_path}/rails/ubuntu/rails_setup.sh";;
    7)
      sh "${root_path}/rails/ubuntu/template_nginx.sh";;
    q|0|quit|exit)
      if [ "$input" == "q" ] || [ "$input" == "quit" ] || [ "$input" == "exit" ]; then
        break
      fi;;
  esac

  cd "$root_path"
  echo "=================== END ===================="
  echo ""
  read -p "Nhập bất kỳ để tiếp tục hoặc q để kết thúc: " new_input
  if [ "$new_input" == "q" ]; then
    break
  else
    clear
  fi
done
