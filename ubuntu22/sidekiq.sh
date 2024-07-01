#!/bin/bash

# Lấy giá trị của sidekiq version, project path và sidekiq file từ các tham số dòng lệnh
read -p "=> Enter user deploy (ruby): " user_deploy_app
read -p "=> Project path (/home/ruby/project_name): " project_path
read -p "=> Sidekiq file name: " sidekiq_file_name

service_name="${project_name}_${sidekiq_file_name}_v${sidekiq_version}"
# Kiểm tra file sidekiq
sidekiq_full_path="${project_path}/config/${sidekiq_file_name}.yml"
if ! test -e $sidekiq_full_path; then
  echo ""
  echo "=====> ERROR: Không tìm thấy file $sidekiq_full_path."
  echo ""
  exit 126
fi

echo $sidekiq_version

cat > /etc/systemd/system/$service_name.service << EOF
[Unit]
Description=Sidekiq Background Processor ${sidekiq_file_name}
After=syslog.target network.target

# See these pages for lots of options:
# http://0pointer.de/public/systemd-man/systemd.service.html
# http://0pointer.de/public/systemd-man/systemd.exec.html
[Service]
Type=simple
WatchdogSec=10
WorkingDirectory=${project_path}
Environment=RAILS_ENV=production
# If you use rbenv:
# ExecStart=/bin/bash -lc 'exec /home/deploy/.rbenv/shims/bundle exec sidekiq -e production'
# If you use the system's ruby:
# ExecStart=/usr/local/bin/bundle exec sidekiq -e production
# If you use rvm in production without gemset and your ruby version is 2.6.5
# ExecStart=/home/deploy/.rvm/gems/ruby-2.6.5/wrappers/bundle exec sidekiq -e production
# If you use rvm in production with gemset and your ruby version is 2.6.5

ExecStart=/usr/bin/env bundle exec sidekiq -e production -C config/${sidekiq_file_name}.yml
ExecReload=/bin/kill -USR1 $MAINPID
KillMode=process

User=${user_deploy_app}
Group=${user_deploy_app}

# Greatly reduce Ruby memory fragmentation and heap usage
# https://www.mikeperham.com/2018/04/25/taming-rails-memory-bloat/
Environment=MALLOC_ARENA_MAX=2

# if we crash, restart
# RestartSec=1
# Restart=on-failure
Restart=always

# output goes to /var/log/syslog
StandardOutput=syslog
StandardError=syslog

# This will default to "bundler" if we don't specify it
SyslogIdentifier=${sidekiq_file_name}

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl restart $service_name
sudo systemctl status $service_name
sudo systemctl enable $service_name

echo "${user_deploy_app} ALL=NOPASSWD: /bin/systemctl restart ${service_name}" | sudo tee -a /etc/sudoers
