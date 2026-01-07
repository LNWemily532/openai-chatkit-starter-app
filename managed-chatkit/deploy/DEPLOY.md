# Deployment Guide for sop-chatbot.livelihoodnw.org

This guide will help you deploy the Managed ChatKit application to your subdomain using GitHub HTTPS.

## 🔒 Security First - Protect Your API Keys

**BEFORE deploying, ensure your secrets are protected:**

1. **Verify your repository is private** (see `SECURITY.md` for details)
2. **Never commit `.env.local`** - it's already in `.gitignore`
3. **Use `.env.example`** as a template (no real values)
4. **Create `.env.local` on your server** (not in the repo)

See `SECURITY.md` for a complete security guide and checklist.

## Quick Start (GitHub Workflow)

If you're already familiar with server setup, here's the quick version:

1. **On your server:**
   ```bash
   cd /var/www
   git clone https://github.com/your-username/your-repo.git sop-chatbot.livelihoodnw.org
   cd sop-chatbot.livelihoodnw.org
   ```

2. **Create `.env.local`** with your production environment variables

3. **Run the deployment script:**
   ```bash
   sudo bash deploy/quick-deploy.sh
   ```

4. **Set up SSL:**
   ```bash
   sudo certbot --nginx -d sop-chatbot.livelihoodnw.org
   ```

5. **For future updates:**
   ```bash
   cd /var/www/sop-chatbot.livelihoodnw.org
   git pull
   bash deploy/update.sh
   ```

## Prerequisites

- A server with Ubuntu/Debian (or similar Linux distribution)
- Root or sudo access
- Domain DNS pointing to your server IP
- Python 3.11+ installed
- Node.js 18+ and npm installed
- Nginx installed

## Step 1: Prepare Your Server

### Install Required Software

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Python 3.11 and pip
sudo apt install python3.11 python3.11-venv python3-pip -y

# Install Node.js 18+ (using NodeSource repository)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install Nginx
sudo apt install nginx -y

# Install Certbot for SSL certificates
sudo apt install certbot python3-certbot-nginx -y
```

## Step 2: Clone Your Code from GitHub

Clone your repository from GitHub using HTTPS:

```bash
# Navigate to web directory
cd /var/www

# Clone your repository (replace with your actual GitHub URL)
git clone https://github.com/your-username/your-repo-name.git sop-chatbot.livelihoodnw.org

# If the repository is private, you'll need to authenticate
# Option 1: Use a Personal Access Token (recommended)
# When prompted for password, use your GitHub Personal Access Token
# Create one at: https://github.com/settings/tokens

# Option 2: Set up credential helper to cache credentials
git config --global credential.helper store

# Set ownership
sudo chown -R $USER:$USER sop-chatbot.livelihoodnw.org
```

**Note:** If your repository is private, you'll need to authenticate:

1. **Create a GitHub Personal Access Token:**
   - Go to: https://github.com/settings/tokens
   - Click "Generate new token" → "Generate new token (classic)"
   - Give it a name like "Server Deployment"
   - Select the `repo` scope (full control of private repositories)
   - Generate and copy the token

2. **Use the token when cloning:**
   - When prompted for username: enter your GitHub username
   - When prompted for password: paste your Personal Access Token (not your GitHub password)

3. **Store credentials (optional but recommended):**
   ```bash
   # This will save your credentials so you don't need to enter them every time
   git config --global credential.helper store
   ```

4. **For automated pulls (update script):**
   - The credential helper will remember your token
   - Or you can embed the token in the URL (less secure):
     ```bash
     git remote set-url origin https://YOUR_TOKEN@github.com/your-username/your-repo.git
     ```

## Step 3: Set Up Environment Variables

Create a `.env.local` file in the project root with your production environment variables:

```bash
cd /var/www/sop-chatbot.livelihoodnw.org
nano .env.local
```

Add the following (replace with your actual values):

```env
OPENAI_API_KEY=sk-your-api-key-here
VITE_CHATKIT_WORKFLOW_ID=wf-your-workflow-id-here
CHATKIT_API_BASE=https://api.openai.com
ENVIRONMENT=production
NODE_ENV=production
```

**Important:** Make sure this file has proper permissions:
```bash
chmod 600 .env.local
```

## Step 4: Build the Frontend

```bash
cd /var/www/sop-chatbot.livelihoodnw.org

# Install root dependencies
npm install

# Build the frontend
npm run frontend:build
```

This will create a `frontend/dist` directory with the production build.

## Step 5: Set Up the Backend

```bash
cd /var/www/sop-chatbot.livelihoodnw.org/backend

# Create virtual environment
python3.11 -m venv .venv

# Activate virtual environment
source .venv/bin/activate

# Install dependencies
pip install .

# Test that it works
python -c "from app.main import app; print('Backend OK')"
```

## Step 6: Configure Nginx

1. Copy the nginx configuration:

```bash
sudo cp /var/www/sop-chatbot.livelihoodnw.org/deploy/nginx.conf /etc/nginx/sites-available/sop-chatbot.livelihoodnw.org
```

2. Update the paths in the nginx config if needed (especially the root directory):

```bash
sudo nano /etc/nginx/sites-available/sop-chatbot.livelihoodnw.org
```

Make sure the `root` directive points to your frontend dist directory:
```
root /var/www/sop-chatbot.livelihoodnw.org/frontend/dist;
```

3. Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/sop-chatbot.livelihoodnw.org /etc/nginx/sites-enabled/
```

4. Test nginx configuration:

```bash
sudo nginx -t
```

5. If the test passes, reload nginx:

```bash
sudo systemctl reload nginx
```

## Step 7: Set Up SSL Certificate

```bash
sudo certbot --nginx -d sop-chatbot.livelihoodnw.org
```

Follow the prompts. Certbot will automatically configure SSL and update your nginx configuration.

## Step 8: Set Up Backend as a Systemd Service

1. Copy the systemd service file:

```bash
sudo cp /var/www/sop-chatbot.livelihoodnw.org/deploy/chatkit-backend.service /etc/systemd/system/
```

2. Update the service file with correct paths:

```bash
sudo nano /etc/systemd/system/chatkit-backend.service
```

Make sure all paths match your actual deployment location.

3. Reload systemd and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable chatkit-backend
sudo systemctl start chatkit-backend
```

4. Check the status:

```bash
sudo systemctl status chatkit-backend
```

5. View logs if needed:

```bash
sudo journalctl -u chatkit-backend -f
```

## Step 9: Set Permissions

```bash
# Set ownership
sudo chown -R www-data:www-data /var/www/sop-chatbot.livelihoodnw.org

# Set permissions
sudo chmod -R 755 /var/www/sop-chatbot.livelihoodnw.org
sudo chmod 600 /var/www/sop-chatbot.livelihoodnw.org/.env.local
```

## Step 10: Verify Deployment

1. Check backend health:
```bash
curl http://127.0.0.1:8000/health
```

2. Check nginx:
```bash
sudo systemctl status nginx
```

3. Visit your site:
Open `https://sop-chatbot.livelihoodnw.org` in your browser.

## Troubleshooting

### Backend not starting
- Check logs: `sudo journalctl -u chatkit-backend -n 50`
- Verify environment variables are set correctly
- Check that the virtual environment is activated in the service file

### Frontend not loading
- Verify the build was successful: `ls -la frontend/dist`
- Check nginx error logs: `sudo tail -f /var/log/nginx/error.log`
- Verify nginx root path is correct

### API requests failing
- Check backend is running: `sudo systemctl status chatkit-backend`
- Check nginx proxy configuration
- Verify CORS settings in backend (should allow your domain)

### SSL issues
- Renew certificate: `sudo certbot renew`
- Check certificate status: `sudo certbot certificates`

## Updating the Application

When you need to update after pushing changes to GitHub:

```bash
cd /var/www/sop-chatbot.livelihoodnw.org

# Pull latest changes from GitHub
git pull origin main  # or 'master' if that's your default branch

# If prompted for credentials, use your GitHub username and Personal Access Token

# Rebuild frontend
npm run frontend:build

# Restart backend
sudo systemctl restart chatkit-backend

# Reload nginx (usually not needed, but safe)
sudo systemctl reload nginx
```

### Automated Deployment Script

You can create a simple update script to automate this process:

```bash
# Create update script
cat > /var/www/sop-chatbot.livelihoodnw.org/update.sh << 'EOF'
#!/bin/bash
cd /var/www/sop-chatbot.livelihoodnw.org
git pull origin main
npm run frontend:build
sudo systemctl restart chatkit-backend
echo "Update complete!"
EOF

chmod +x /var/www/sop-chatbot.livelihoodnw.org/update.sh
```

Then you can simply run:
```bash
/var/www/sop-chatbot.livelihoodnw.org/update.sh
```

## Monitoring

Set up monitoring for:
- Backend service status: `sudo systemctl status chatkit-backend`
- Nginx status: `sudo systemctl status nginx`
- Disk space: `df -h`
- System resources: `htop` or `top`

Consider setting up log rotation and monitoring tools like `pm2` or `supervisor` for more advanced process management.
