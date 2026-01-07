#!/usr/bin/env bash

# Quick deployment script - run this on your server after cloning from GitHub
# Make sure to set up .env.local first!
# 
# Usage:
#   1. Clone your repo: git clone https://github.com/your-username/repo.git /var/www/sop-chatbot.livelihoodnw.org
#   2. Create .env.local with your environment variables
#   3. Run this script: sudo bash deploy/quick-deploy.sh

set -euo pipefail

PROJECT_ROOT="/var/www/sop-chatbot.livelihoodnw.org"
cd "$PROJECT_ROOT"

echo "🚀 Starting deployment..."

# 1. Build frontend
echo "📦 Building frontend..."
npm install
npm run frontend:build

# 2. Set up backend
echo "🐍 Setting up backend..."
cd backend
if [ ! -d ".venv" ]; then
    python3.11 -m venv .venv
fi
source .venv/bin/activate
pip install .

# 3. Set permissions
echo "🔐 Setting permissions..."
cd "$PROJECT_ROOT"
sudo chown -R www-data:www-data .
sudo chmod -R 755 .
sudo chmod 600 .env.local

# 4. Copy nginx config
echo "🌐 Configuring nginx..."
sudo cp deploy/nginx.conf /etc/nginx/sites-available/sop-chatbot.livelihoodnw.org
sudo ln -sf /etc/nginx/sites-available/sop-chatbot.livelihoodnw.org /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# 5. Set up systemd service
echo "⚙️  Setting up backend service..."
sudo cp deploy/chatkit-backend.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable chatkit-backend
sudo systemctl restart chatkit-backend

# 6. Check status
echo "✅ Checking services..."
sudo systemctl status chatkit-backend --no-pager -l
sudo systemctl status nginx --no-pager -l

echo ""
echo "🎉 Deployment complete!"
echo "📝 Next steps:"
echo "   1. Set up SSL: sudo certbot --nginx -d sop-chatbot.livelihoodnw.org"
echo "   2. Visit: https://sop-chatbot.livelihoodnw.org"
echo "   3. Check logs: sudo journalctl -u chatkit-backend -f"
