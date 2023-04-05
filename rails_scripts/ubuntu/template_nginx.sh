#!/bin/bash

if [ $# -ne 1 ]; then
echo "Usage: $0 domain_name"
exit 1
fi

domain=$1

cat > /etc/nginx/sites-available/$domain << EOF
server {
  listen 80;
  server_name $domain;

  location / {
    proxy_pass http://localhost:3000;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  }
}
EOF

ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/

service nginx reload
