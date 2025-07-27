#!/bin/bash

set -e  # Stop on error

echo "=== 🔧 Update system & install dependencies ==="
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx git curl build-essential

echo "=== 🧱 Install Node.js LTS ==="
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

echo "=== 📦 Install dependencies & build project ==="
npm install
npm run build

echo "=== 🚀 Start Next.js on port 3000 (0.0.0.0) ==="
sudo npm install -g pm2
pm2 delete my-app || true
pm2 start "HOST=0.0.0.0 PORT=3000 npm start" --name my-app
pm2 save

echo "=== 🌐 Configure Nginx as reverse proxy (port 80 → 3000) ==="
sudo tee /etc/nginx/sites-available/my-app >/dev/null <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/my-app /etc/nginx/sites-enabled/my-app
sudo nginx -t && sudo systemctl reload nginx

echo "=== 🔓 Allow Nginx traffic (HTTP) ==="
sudo ufw allow 'Nginx Full' || true

echo "=== ✅ Deployment complete! App is now accessible at http://<EC2_IP> or http://<your-elb>.elb.amazonaws.com ==="
