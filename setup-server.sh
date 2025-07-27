#!/bin/bash

set -e  # Exit on error

echo "=== 🟢 Updating system and installing dependencies ==="
sudo apt install -y nginx git curl build-essential

echo "=== 🌐 Installing Node.js (LTS) ==="
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

echo "=== 📦 Installing project dependencies ==="
npm install
npm run build

echo "=== 🚀 Running Next.js on port 3000 (HOST=0.0.0.0) ==="
sudo npm install -g pm2
pm2 delete my-app || true
pm2 start "HOST=0.0.0.0 PORT=3000 npm start" --name my-app
pm2 save

echo "=== 🌐 Configuring Nginx reverse proxy (port 80 to 3000) ==="
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

# Remove default site if exists
sudo rm -f /etc/nginx/sites-enabled/default

# Enable new config
sudo ln -sf /etc/nginx/sites-available/my-app /etc/nginx/sites-enabled/my-app
sudo nginx -t && sudo systemctl reload nginx

echo "=== 🔓 Opening firewall for HTTP (port 80) ==="
sudo ufw allow 'Nginx Full' || true

echo "✅ Setup complete! Visit: http://<your-ec2-ip>"
