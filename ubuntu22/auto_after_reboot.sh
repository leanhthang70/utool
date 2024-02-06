#!/bin/bash

# Lấy giá trị của sidekiq version, project path và sidekiq file từ các tham số dòng lệnh
echo "Tạo service tự động run mỗi khi reboot"
read -p "=> Nhập path chứa script: " script_path
read -p "=> Nhập service_name: " service_name

if test -e $script_path; then

sudo chmod +x $script_path

cat > /etc/systemd/system/$service_name.service << EOF
[Unit]
Description=Run ABCDF Command on Reboot

[Service]
ExecStart=${script_path}

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable $service_name
sudo systemctl start $service_name

else
  echo "Tệp tin không tồn tại."
fi
