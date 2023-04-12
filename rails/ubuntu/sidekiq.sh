#!/bin/bash

# Lấy giá trị của sidekiq version, project path và sidekiq file từ các tham số dòng lệnh
read -p "=> Enter user deploy: " user_deploy_app
read -p "=> Sidekiq version 6/7: " sidekiq_version
read -p "=> Project path: " project_path
read -p "=> Sidekiq file name: " sidekiq_file_name
read -p "=> Project alias name: " project_name


service_name="${project_name}_${sidekiq_file_name}_v${sidekiq_version}"
# Kiểm tra file sidekiq
sidekiq_full_path="${user_deploy_app}/config/${sidekiq_file_name}.yml"
if ! test -e $sidekiq_full_path; then
  echo ""
  echo "=====> ERROR: Không tìm thấy file $sidekiq_full_path."
  echo ""
  exit 126
fi

echo $sidekiq_version
if [ $sidekiq_version == 6 ]; then
cat > /etc/systemd/system/$service_name.service << EOF
[Unit]
Description=Sidekiq Background Processor
After=network.target

[Service]
Type=simple
User=${user_deploy_app}
Group=${user_deploy_app}
WorkingDirectory=${project_path}
Environment=RAILS_ENV=production
ExecStart=/usr/bin/env bundle exec sidekiq -C config/${sidekiq_file_name}.yml
TimeoutSec=15
Restart=always

[Install]
WantedBy=multi-user.target
EOF
echo "Create success service ${service_name}.service"

elif [$sidekiq_version == 7]; then
cat > /etc/systemd/system/$service_name.service << EOF
[Unit]
Description=Sidekiq Background Processor
After=network.target

[Service]
Type=simple
User=${user_deploy_app}
Group=${user_deploy_app}
WorkingDirectory=${project_path}
Environment=RAILS_ENV=production
ExecStart=/usr/bin/env bundle exec sidekiq -e production -C config/${sidekiq_file_name}.yml
ExecReload=/bin/kill -USR1 $MAINPID
KillMode=process
Restart=always

[Install]
WantedBy=multi-user.target
EOF
echo "Create success service ${service_name}.service"

else
  echo ""
  echo "+++Chỉ hỗ trợ cài đặt sidekiq 6/7 xin vui lòng nhập đúng+++"
  echo ""
fi

sudo systemctl daemon-reload
sudo systemctl restart $service_name
sudo systemctl status $service_name
sudo systemctl enable $service_name
