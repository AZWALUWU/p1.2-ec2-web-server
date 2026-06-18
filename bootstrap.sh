#!/bin/bash

# ====================================================================
# BOOTSTRAP SCRIPT: EC2 Web Server (Nginx + Express + SSL)
# ====================================================================

# Ubah variabel di bawah ini sesuai dengan data Anda sebelum menjalankan script!
DOMAIN="api-server-saya.duckdns.org"
EMAIL="azwaluwu@gmail.com"
REPO_URL="https://github.com/AZWALUWU/p1.2-ec2-web-server.git"

echo "🎨 [1/7] Mengupdate package manager Ubuntu..."
sudo apt update && sudo apt upgrade -y

echo "🟢 [2/7] Menginstall Node.js 20 LTS..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

echo "🛡️ [3/7] Menginstall Nginx, Certbot, dan Git..."
sudo apt install nginx certbot python3-certbot-nginx git -y

echo "📁 [4/7] Menyiapkan direktori aplikasi & Clone Repository..."
sudo mkdir -p /var/www/ec2-web-server
sudo chown -R ubuntu:ubuntu /var/www/ec2-web-server
# Membersihkan folder jika sebelumnya sudah ada isi
rm -rf /var/www/ec2-web-server/* git clone $REPO_URL /var/www/ec2-web-server
cd /var/www/ec2-web-server
npm install

echo "⚙️ [5/7] Mengonfigurasi Systemd Service untuk Express..."
sudo cp express-app.service /etc/systemd/system/express-app.service
sudo systemctl daemon-reload
sudo systemctl enable express-app
sudo systemctl start express-app

echo "🕸️ [6/7] Mengonfigurasi Nginx sebagai Reverse Proxy..."
# Mengganti placeholder di nginx.conf dengan domain asli
sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" nginx.conf
sudo cp nginx.conf /etc/nginx/sites-available/ec2-web-server
sudo ln -sf /etc/nginx/sites-available/ec2-web-server /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

echo "🔒 [7/7] Mendaftarkan SSL gratis dengan Let's Encrypt..."
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL

echo "🚀 [SELESAI] Server Anda berhasil di-bootstrap dengan sukses!"
