#!/bin/bash

read -p "=> Nhập domain_name: " domain
read -p "=> Nhập email: " email
nginx_file="$domain.conf"

# Open port
# sudo ufw enable
# sudo ufw allow 80/tcp
# sudo ufw allow 443/tcp
# sudo ufw reload

echo "=== Install Nginx ==="
if ! command -v nginx &> /dev/null; then
  sudo apt-get install -y nginx
  sudo systemctl start nginx
  sudo systemctl enable nginx
fi

# Install Certbot if not already installed
if ! command -v certbot &> /dev/null; then
  sudo apt remove certbot
  sudo snap install core; sudo snap refresh core
  sudo snap install --classic certbot
  sudo ln -s /snap/bin/certbot /usr/bin/certbot
fi

# Add SSL
sudo certbot --nginx --email $email -d $domain -d www.$domain

# Renew certbot
# service nginx stop && certbot renew && service nginx start


# Add Nginx domain
cat > /etc/nginx/conf.d/$nginx_file << EOF
server {
    if ($host = $domain) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

  server_name $domain;
  return 301 https://$host$request_uri;
}

server {
  listen 443 ssl;
  server_name $domain;
    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;

  ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
  ssl_prefer_server_ciphers on;
  ssl_ciphers AES256+EECDH:AES256+EDH:!aNULL;

  root /home/ruby/$domain/current/public;
  index index.html index.htm;

  location / {
    passenger_enabled on;
    passenger_app_env production;
  }

  client_max_body_size 12M;

  gzip on;
  gzip_static on;
  gzip_disable "msie6";
  gzip_vary on;
  gzip_proxied any;
  gzip_comp_level 6;
  gzip_buffers 16 8k;
  gzip_http_version 1.1;
  gzip_types text/plain text/css application/json text/javascript application/javascript text/xml application/xml application/xml+rss;
  add_header Cache-Control "public, must-revalidate, proxy-revalidate";

  keepalive_timeout  3600;
  proxy_read_timeout 3600s;
}
EOF

sudo ln -s /etc/nginx/sites-available/$nginx_file /etc/nginx/sites-enabled/
sudo nginx -t
sudo service nginx reload
