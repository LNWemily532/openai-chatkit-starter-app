#!/usr/bin/env bash

# Update script - run this after pulling changes from GitHub
# Usage: ./update.sh

set -euo pipefail

PROJECT_ROOT="/var/www/sop-chatbot.livelihoodnw.org"
cd "$PROJECT_ROOT"

echo "🔄 Updating application..."

# Pull latest changes
echo "📥 Pulling latest changes from GitHub..."
git pull origin main || git pull origin master

# Rebuild frontend
echo "📦 Rebuilding frontend..."
npm install
npm run frontend:build

# Restart backend
echo "🔄 Restarting backend..."
sudo systemctl restart chatkit-backend

# Check status
echo "✅ Checking services..."
sudo systemctl status chatkit-backend --no-pager -l | head -10

echo ""
echo "🎉 Update complete!"
echo "📝 Check logs: sudo journalctl -u chatkit-backend -f"
