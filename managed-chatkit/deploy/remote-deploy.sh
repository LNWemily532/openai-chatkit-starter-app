#!/usr/bin/env bash

# Remote deployment script - Run this on your server
# This script automates the deployment process

set -euo pipefail

PROJECT_ROOT="/var/www/sop-chatbot.livelihoodnw.org"
DOMAIN="sop-chatbot.livelihoodnw.org"

echo "🚀 Starting deployment to $DOMAIN..."

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run with sudo: sudo bash $0"
    exit 1
fi

# Step 1: Check prerequisites
echo ""
echo "📋 Checking prerequisites..."

# Check Python
if ! command -v python3.11 &> /dev/null; then
    echo "⚠️  Python 3.11 not found. Installing..."
    apt update
    apt install -y python3.11 python3.11-venv python3-pip
else
    echo "✅ Python 3.11 found"
fi

# Check Node.js
if ! command -v node &> /dev/null || [ "$(node -v | cut -d'v' -f2 | cut -d'.' -f1)" -lt 18 ]; then
    echo "⚠️  Node.js 18+ not found. Installing..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
else
    echo "✅ Node.js $(node -v) found"
fi

# Check Nginx
if ! command -v nginx &> /dev/null; then
    echo "⚠️  Nginx not found. Installing..."
    apt install -y nginx
    systemctl enable nginx
    systemctl start nginx
else
    echo "✅ Nginx found"
fi

# Check Certbot
if ! command -v certbot &> /dev/null; then
    echo "⚠️  Certbot not found. Installing..."
    apt install -y certbot python3-certbot-nginx
else
    echo "✅ Certbot found"
fi

# Step 2: Verify project directory
if [ ! -d "$PROJECT_ROOT" ]; then
    echo "❌ Project directory not found: $PROJECT_ROOT"
    echo "   Please upload your code first using git, scp, or rsync"
    exit 1
fi

cd "$PROJECT_ROOT"

# Step 3: Check .env.local
if [ ! -f ".env.local" ]; then
    echo "⚠️  .env.local not found. Creating template..."
    cat > .env.local << 'EOF'
# Production Environment Variables
OPENAI_API_KEY=sk-your-api-key-here
VITE_CHATKIT_WORKFLOW_ID=wf-your-workflow-id-here
CHATKIT_API_BASE=https://api.openai.com
ENVIRONMENT=production
NODE_ENV=production
EOF
    echo "📝 Please edit .env.local with your actual values:"
    echo "   nano $PROJECT_ROOT/.env.local"
    echo "   Then run this script again."
    exit 1
fi

echo "✅ .env.local found"

# Step 4: Build frontend
echo ""
echo "📦 Building frontend..."
cd "$PROJECT_ROOT"
npm install
npm run frontend:build

if [ ! -d "frontend/dist" ]; then
    echo "❌ Frontend build failed - dist directory not found"
    exit 1
fi
echo "✅ Frontend built successfully"

# Step 5: Set up backend
echo ""
echo "🐍 Setting up backend..."
cd "$PROJECT_ROOT/backend"

if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    python3.11 -m venv .venv
fi

source .venv/bin/activate
pip install --upgrade pip
pip install .

echo "✅ Backend dependencies installed"

# Step 6: Set permissions
echo ""
echo "🔐 Setting permissions..."
cd "$PROJECT_ROOT"
chown -R www-data:www-data .
chmod -R 755 .
chmod 600 .env.local
echo "✅ Permissions set"

# Step 7: Configure Nginx
echo ""
echo "🌐 Configuring Nginx..."

# Update nginx config with correct paths
sed -i "s|/var/www/sop-chatbot.livelihoodnw.org|$PROJECT_ROOT|g" deploy/nginx.conf

cp deploy/nginx.conf /etc/nginx/sites-available/$DOMAIN
ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/

# Remove default nginx site if it exists
if [ -f /etc/nginx/sites-enabled/default ]; then
    rm /etc/nginx/sites-enabled/default
fi

# Test nginx configuration
if nginx -t; then
    systemctl reload nginx
    echo "✅ Nginx configured and reloaded"
else
    echo "❌ Nginx configuration test failed"
    exit 1
fi

# Step 8: Set up systemd service
echo ""
echo "⚙️  Setting up backend service..."

# Update service file with correct paths
sed -i "s|/var/www/sop-chatbot.livelihoodnw.org|$PROJECT_ROOT|g" deploy/chatkit-backend.service

cp deploy/chatkit-backend.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable chatkit-backend
systemctl restart chatkit-backend

sleep 2
if systemctl is-active --quiet chatkit-backend; then
    echo "✅ Backend service is running"
else
    echo "⚠️  Backend service may have issues. Check logs:"
    echo "   journalctl -u chatkit-backend -n 50"
fi

# Step 9: Check SSL
echo ""
echo "🔒 Checking SSL certificate..."

if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "✅ SSL certificate found"
else
    echo "⚠️  SSL certificate not found. Setting up..."
    echo "   Running: certbot --nginx -d $DOMAIN"
    certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@livelihoodnw.org || {
        echo "⚠️  SSL setup failed. You may need to run manually:"
        echo "   certbot --nginx -d $DOMAIN"
    }
fi

# Step 10: Final checks
echo ""
echo "🔍 Running final checks..."

# Check backend health
if curl -s http://127.0.0.1:8000/health > /dev/null; then
    echo "✅ Backend health check passed"
else
    echo "⚠️  Backend health check failed"
fi

# Check nginx
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx is running"
else
    echo "❌ Nginx is not running"
fi

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Visit: https://$DOMAIN"
echo "   2. Check backend logs: journalctl -u chatkit-backend -f"
echo "   3. Check nginx logs: tail -f /var/log/nginx/error.log"
echo ""
echo "🔧 Useful commands:"
echo "   - Restart backend: systemctl restart chatkit-backend"
echo "   - Restart nginx: systemctl restart nginx"
echo "   - View backend status: systemctl status chatkit-backend"
echo ""
