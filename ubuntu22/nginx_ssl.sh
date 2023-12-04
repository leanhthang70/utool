#!/bin/bash

read -p "=> Enter user deploy: " username
read -p "=> Enter domain_name: " domain
read -p "=> Enter email: " email
nginx_file="$domain.conf"

# Open port
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload
# Add SSL
sudo certbot --nginx --agree-tos --email $email -d $domain -d www.$domain

# Renew certbot
# service nginx stop && certbot renew && service nginx start


# Add Nginx domain
cat > /etc/nginx/sites-available/$nginx_file << EOF
server {
  if ($host = $domain) {
      return 301 https://$host$request_uri;
  } # managed by Certbot

  server_name $domain www.$domain;
  return 301 https://$host$request_uri;
}

server {
  listen 443 ssl http2;
  server_name $domain www.$domain;

  ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;

  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_prefer_server_ciphers on;
  ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";

  root /home/$username/$domain/current/public;
  index index.html index.htm;

  location / {
    passenger_enabled on;
    passenger_app_env production;
    try_files $uri $uri/ =404;
  }

  error_page 500 502 503 504 /50x.html;
  location = /50x.html {
      root /usr/share/nginx/html;
  }

  location ~ /\.ht {
      deny all;
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

  # enable server-side caching
  proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=1g
                       inactive=60m use_temp_path=off;

  location / {
      proxy_cache my_cache;
      proxy_pass http://your_upstream;
      proxy_cache_valid 200 302 60m;
      proxy_cache_valid 404 1m;
  }

  # enable client-side caching
  location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 30d;
    }

  # enable websocket anycable
  location /cable {
      proxy_pass http://localhost:3334;
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "Upgrade";
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Host $host;
      proxy_set_header X-NginX-Proxy true;
  }
}
}
EOF

sudo ln -s /etc/nginx/sites-available/$nginx_file /etc/nginx/sites-enabled/
sudo nginx -t
sudo service nginx reload
