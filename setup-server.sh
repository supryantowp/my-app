#!/bin/bash

set -e  # Exit immediately if a command fails

echo "=== 🟢 Updating system and installing dependencies ==="
sudo apt install -y nginx git curl build-essential

echo "=== 🌐 Installing Node.js (LTS) ==="
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

echo "=== 📦 Installing project dependencies ==="
npm install
npm run build

echo "=== 🚀 Starting Next.js app on port 3000 ==="
sudo npm install -g pm2
pm2 start "npm start" --name my-app

echo "=== 🌐 Configuring Nginx reverse proxy ==="
cat <<EOF | sudo tee /etc/nginx/sites-available/my-app
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

echo "=== 🔗 Enabling Nginx configuration ==="
sudo ln -sf /etc/nginx/sites-available/my-app /etc/nginx/sites-enabled/my-app
sudo nginx -t && sudo systemctl reload nginx

echo "=== 🔓 (Optional) Allowing firewall access for Nginx ==="
sudo ufw allow 'Nginx Full' || true

echo "✅ Setup complete. Your Next.js app should be accessible via your EC2 public IP."
