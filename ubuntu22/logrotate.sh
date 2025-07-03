#!/bin/bash

# Save original directory
ORIGINAL_DIR="$(pwd)"

# FILEPATH: /home/lat/utool/ubuntu22/logrotate.sh

# Check if logrotate is installed
if ! command -v logrotate &> /dev/null; then
  echo "logrotate is not installed. Installing..."
  sudo apt-get update
  sudo apt-get install -y logrotate
fi

# Prompt for logrotate name and log directory path
# user: ruby
# logrotate_name: rails_rotator_logs
# log_directory_path: /home/ruby/app_dir/current/log/*.log
echo
echo "==============================="
echo "=== Logrotate configuration ==="
echo "==============================="
read -p "Enter user: " user
read -p "Enter max size of log (MB - default 100MB): " max_size
read -p "Enter logrotate name (e.g., rails_rotator_logs): " logrotate_name
read -p "Enter log directory path (e.g., /home/ruby/app_dir/current/log): " log_directory_path

# Prompt for confirmation to exit
read -n 1 -r -s -p $'Press any key to continue or Ctrl+C to exit...\n'

# Create logrotate configuration file
sudo tee "/etc/logrotate.d/$logrotate_name" <<EOF
$log_directory_path/*.log {
  su $user $user
  size ${max_size:-100}M
  missingok
  rotate 3
  compress
  delaycompress
  notifempty
  copytruncate
  minsize 100
  hourly
}
EOF
sudo logrotate -f "/etc/logrotate.d/$logrotate_name"

# Return to original directory
if [[ -n "$ORIGINAL_DIR" && -d "$ORIGINAL_DIR" ]]; then
    cd "$ORIGINAL_DIR"
    echo "Returned to original directory: $ORIGINAL_DIR"
fi
