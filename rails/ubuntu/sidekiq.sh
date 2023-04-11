#!/bin/bash

# Lấy giá trị của sidekiq version, project path và sidekiq file từ các tham số dòng lệnh
user_deploy_app=$1
sidekiq_version=$2
project_path=$3
sidekiq_file_name=$4
service_name="${sidekiq_file_name}_v${sidekiq_version}"

if [ $sidekiq_version -eq 6 ]; then
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

elif [$sidekiq_version -eq 7]
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
  echo "Chỉ hỗ trợ cài đặt sidekiq 6/7 xin vui lòng nhập đúng"
fi

sudo systemctl daemon-reload
sudo systemctl restart $service_name
sudo systemctl status $service_name
sudo systemctl enable $service_name
