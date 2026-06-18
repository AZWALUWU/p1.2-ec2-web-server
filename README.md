# EC2 Web Server: Nginx + Express.js + SSL Automation

This repository contains the complete codebase, configuration files, and an automated bootstrap script to provision, deploy, and secure a Node.js Express.js REST API on an AWS EC2 instance from scratch. The environment is secured with an SSL certificate from Let's Encrypt and exposed via a free DuckDNS subdomain.

## 🚀 Project Architecture
- **Cloud Infrastructure**: AWS EC2 (t2.micro / Ubuntu LTS) + Elastic IP (Static IPv4)
- **Application Layer**: Node.js & Express.js REST API
- **Process Management**: Systemd Service (for background process & auto-restart)
- **Web Server & Reverse Proxy**: Nginx (handling port 80/443 mapping to port 3000)
- **Security & Encryption**: Let's Encrypt SSL/TLS via Certbot

---

## 📁 Repository Structure
```text
ec2-web-server/
├── .gitignore
├── README.md
├── bootstrap.sh
├── express-app.service
├── index.js
├── nginx.conf
├── package-lock.json
└── package.json

```

---

## 🛠️ Detailed Step-by-Step Guide

### Step 1: Local Application Setup

Initialize the Node.js project and create a baseline Express.js application locally.

1. Initialize repository and dependencies:
```bash
mkdir ec2-web-server && cd ec2-web-server
git init
npm init -y
npm install express

```


2. App entry point (`index.js`):
```javascript
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get('/', (req, res) => {
    res.json({
        status: "success",
        message: "Welcome to EC2 Web Server API!",
        timestamp: new Date()
    });
});

app.listen(PORT, () => {
    console.log(`Application is running on port ${PORT}`);
});

```


3. Exclude `node_modules` in `.gitignore`:
```text
node_modules/
.env

```



---

### Step 2: AWS EC2 Provisioning & Networking

1. **Launch Instance**: Deploy an AWS EC2 `t2.micro` instance running **Ubuntu LTS**.
2. **Key Pair**: Generate a `.pem` private key named `ec2-server-key.pem`.
3. **Security Group**: Configure the virtual firewall with inbound rules:
* **SSH (Port 22)**: Restricted to your IP or Anywhere.
* **HTTP (Port 80)**: Allowed from Anywhere.
* **HTTPS (Port 443)**: Allowed from Anywhere.


4. **Elastic IP**: Allocate and associate an Elastic IP to prevent the public IP from changing upon system restarts.

To connect to your server via SSH:

```bash
chmod 400 ec2-server-key.pem
ssh -i ec2-server-key.pem ubuntu@<YOUR_SERVER_IP>

```

---

### Step 3: Domain Configuration (DuckDNS)

1. Log in to [DuckDNS](https://www.duckdns.org/) and register a free subdomain (e.g., `your-api.duckdns.org`).
2. Map the domain to your AWS Elastic IP / Public IP.
*Note: AWS Security Groups block ICMP traffic by default, so standard ping requests to the domain will time out. This is expected security behavior.*

---

### Step 4: Server Environment & Systemd Configuration

On the EC2 Server terminal, install Node.js and handle process persistence using Systemd.

1. **Install Node.js 20 LTS**:
```bash
sudo apt update && sudo apt upgrade -y
curl -fsSL [https://deb.nodesource.com/setup_20.x](https://deb.nodesource.com/setup_20.x) | sudo -E bash -
sudo apt-get install -y nodejs

```


2. **Clone Projext & Setup**:
```bash
sudo mkdir -p /var/www/ec2-web-server
sudo chown -R ubuntu:ubuntu /var/www/ec2-web-server
git clone <YOUR_GITHUB_REPO_URL> /var/www/ec2-web-server
cd /var/www/ec2-web-server && npm install

```


3. **Systemd Configuration** (`express-app.service`):
Create a service unit file to ensure the app auto-restarts on crashes or server reboots.
```ini
[Unit]
Description=Express.js Web Server API
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/var/www/ec2-web-server
ExecStart=/usr/bin/node index.js
Restart=on-failure
Environment=PORT=3000

[Install]
WantedBy=multi-user.target

```


Deploy and enable the service:
```bash
sudo cp express-app.service /etc/systemd/system/express-app.service
sudo systemctl daemon-reload
sudo systemctl enable express-app
sudo systemctl start express-app

```



---

### Step 5: Nginx Reverse Proxy Configuration

Nginx intercepts public traffic on standard HTTP (Port 80) and safely forwards it to internal Port 3000.

1. **Install Nginx**:
```bash
sudo apt install nginx -y

```


2. **Nginx Server Block** (`nginx.conf`):
```nginx
server {
    listen 80;
    server_name DOMAIN_PLACEHOLDER;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}

```


Link configuration and restart daemon:
```bash
sudo cp nginx.conf /etc/nginx/sites-available/ec2-web-server
sudo ln -s /etc/nginx/sites-available/ec2-web-server /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx

```



---

### Step 6: SSL/TLS Encryption via Let's Encrypt

Protect transit data using standard TLS encryption managed automatically via Certbot.

1. **Install Certbot**:
```bash
sudo apt install certbot python3-certbot-nginx -y

```


2. **Acquire Certificate**:
```bash
sudo certbot --nginx -d your-api.duckdns.org --non-interactive --agree-tos -m your-email@example.com

```


Certbot automatically updates the Nginx file to securely enforce HTTP to HTTPS redirection.

---

## 🤖 Automation: The Bootstrap Script

The `bootstrap.sh` script automates steps 4 through 6. Run it on any completely fresh Ubuntu instance to duplicate this environment instantly.

```bash
#!/bin/bash

# ====================================================================
# BOOTSTRAP SCRIPT: EC2 Web Server (Nginx + Express + SSL)
# ====================================================================

# Configuration Variables
DOMAIN="your-api.duckdns.org"
EMAIL="your-email@example.com"
REPO_URL="[https://github.com/YOUR_USERNAME/ec2-web-server.git](https://github.com/YOUR_USERNAME/ec2-web-server.git)"

echo "🎨 [1/7] Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "🟢 [2/7] Installing Node.js 20 LTS..."
curl -fsSL [https://deb.nodesource.com/setup_20.x](https://deb.nodesource.com/setup_20.x) | sudo -E bash -
sudo apt-get install -y nodejs

echo "🛡️ [3/7] Installing Nginx, Certbot, and Git..."
sudo apt install nginx certbot python3-certbot-nginx git -y

echo "📁 [4/7] Deploying application directories & cloning source code..."
sudo mkdir -p /var/www/ec2-web-server
sudo chown -R ubuntu:ubuntu /var/www/ec2-web-server
rm -rf /var/www/ec2-web-server/*
git clone $REPO_URL /var/www/ec2-web-server
cd /var/www/ec2-web-server && npm install

echo "⚙️ [5/7] Registering Systemd Daemon Process..."
sudo cp express-app.service /etc/systemd/system/express-app.service
sudo systemctl daemon-reload
sudo systemctl enable express-app
sudo systemctl start express-app

echo "🕸️ [6/7] Setting up Nginx Reverse Proxy Server Blocks..."
sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" nginx.conf
sudo cp nginx.conf /etc/nginx/sites-available/ec2-web-server
sudo ln -sf /etc/nginx/sites-available/ec2-web-server /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

echo "🔒 [7/7] Executing Certbot SSL Certificate challenge..."
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL

echo "🚀 [FINISHED] Web Server initialization sequence completed successfully!"

```

To run the automation on a new server:

```bash
chmod +x bootstrap.sh
./bootstrap.sh

Apakah ada bagian penjelasan teknik atau komando di atas yang ingin disesuaikan lagi?

```
