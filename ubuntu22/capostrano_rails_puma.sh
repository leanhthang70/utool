#!/bin/bash

# Save original directory
ORIGINAL_DIR="$(pwd)"

#
echo "Puma Rails Server"

read -p "=> Service name (<app_name>-puma_production.service): " app_service
read -p "=> Enter user deploy (ruby): " user_deploy
read -p "=> Project path (/home/ruby/project_name): " project_path
read -p "=> Sidekiq file name: " sidekiq_file_name

cat > /etc/systemd/system/$app_service.service << EOF
[Unit]
Description=Puma Rails Server
After=network.target

[Service]
Type=simple
User=${user_deploy}
Group=${user_deploy}
WorkingDirectory=${project_path}/current/
ExecStart=/home/${user_deploy}/.rbenv/bin/rbenv exec bundle exec puma -C ${project_path}/current/config/puma.rb
ExecStop=/home/${user_deploy}/.rbenv/bin/rbenv exec bundle exec pumactl -S ${project_path}/shared/tmp/pids/puma.state stop
TimeoutSec=15
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "=== NGinx ==="

# Return to original directory
if [[ -n "$ORIGINAL_DIR" && -d "$ORIGINAL_DIR" ]]; then
    cd "$ORIGINAL_DIR"
    echo "Returned to original directory: $ORIGINAL_DIR"
fi
