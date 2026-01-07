#!/usr/bin/env bash

# Local script to prepare deployment package
# Run this on your local machine before uploading to server

set -euo pipefail

echo "📦 Preparing deployment package..."

# Build frontend
echo "Building frontend..."
npm run frontend:build

# Verify build
if [ ! -d "frontend/dist" ]; then
    echo "❌ Frontend build failed!"
    exit 1
fi

echo "✅ Frontend built successfully"

# Create deployment archive (excluding unnecessary files)
echo "Creating deployment archive..."
tar -czf deployment.tar.gz \
    --exclude='node_modules' \
    --exclude='.venv' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='.git' \
    --exclude='frontend/node_modules' \
    --exclude='backend/build' \
    --exclude='backend/*.egg-info' \
    --exclude='.env.local' \
    frontend/dist \
    frontend/src \
    frontend/public \
    frontend/package.json \
    frontend/package-lock.json \
    frontend/vite.config.ts \
    frontend/tsconfig.json \
    frontend/tsconfig.node.json \
    frontend/index.html \
    frontend/postcss.config.mjs \
    frontend/eslint.config.mjs \
    backend/app \
    backend/pyproject.toml \
    backend/scripts \
    deploy \
    package.json \
    package-lock.json \
    README.md

echo "✅ Deployment archive created: deployment.tar.gz"
echo ""
echo "📤 Next steps:"
echo "   1. Upload deployment.tar.gz to your server"
echo "   2. Upload .env.local separately (for security)"
echo "   3. On server, extract: tar -xzf deployment.tar.gz"
echo "   4. Run: sudo bash deploy/remote-deploy.sh"
