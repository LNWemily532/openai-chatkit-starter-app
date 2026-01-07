# Next Steps for Deployment

## Immediate Next Steps

### 1. Prepare Your Server ✅
Make sure you have:
- [ ] A server (VPS, cloud instance, etc.) with Ubuntu/Debian Linux
- [ ] SSH access to your server
- [ ] Root or sudo privileges
- [ ] DNS configured: `sop-chatbot.livelihoodnw.org` → Your server IP

### 2. Upload Your Code to the Server

**Option A: Using Git (Recommended)**
```bash
# On your server
cd /var/www
sudo git clone <your-repo-url> sop-chatbot.livelihoodnw.org
sudo chown -R $USER:$USER sop-chatbot.livelihoodnw.org
```

**Option B: Using SCP (from your local machine)**
```bash
# From your local machine (in the project directory)
scp -r . user@your-server-ip:/var/www/sop-chatbot.livelihoodnw.org
```

**Option C: Using rsync (from your local machine)**
```bash
# From your local machine (in the project directory)
rsync -avz --exclude 'node_modules' --exclude '.venv' --exclude '__pycache__' \
  . user@your-server-ip:/var/www/sop-chatbot.livelihoodnw.org/
```

### 3. Create Production Environment File

On your server, create `.env.local`:
```bash
cd /var/www/sop-chatbot.livelihoodnw.org
nano .env.local
```

Add your production environment variables:
```env
OPENAI_API_KEY=sk-your-actual-api-key-here
VITE_CHATKIT_WORKFLOW_ID=wf-your-actual-workflow-id-here
CHATKIT_API_BASE=https://api.openai.com
ENVIRONMENT=production
NODE_ENV=production
```

**Important:** Secure the file:
```bash
chmod 600 .env.local
```

### 4. Install Server Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Python 3.11
sudo apt install python3.11 python3.11-venv python3-pip -y

# Install Node.js 18+
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install Nginx
sudo apt install nginx -y

# Install Certbot for SSL
sudo apt install certbot python3-certbot-nginx -y
```

### 5. Run the Deployment Script

```bash
cd /var/www/sop-chatbot.livelihoodnw.org
sudo bash deploy/quick-deploy.sh
```

This will:
- Build the frontend
- Set up the backend virtual environment
- Configure nginx
- Set up the systemd service
- Start everything

### 6. Set Up SSL Certificate

```bash
sudo certbot --nginx -d sop-chatbot.livelihoodnw.org
```

Follow the prompts. Certbot will automatically configure SSL.

### 7. Verify Everything Works

1. **Check backend health:**
   ```bash
   curl http://127.0.0.1:8000/health
   ```
   Should return: `{"status":"ok"}`

2. **Check services:**
   ```bash
   sudo systemctl status chatkit-backend
   sudo systemctl status nginx
   ```

3. **Visit your site:**
   Open `https://sop-chatbot.livelihoodnw.org` in your browser

## Troubleshooting

### If the deployment script fails:
- Check that all paths in the script match your server setup
- Verify `.env.local` exists and has correct values
- Check logs: `sudo journalctl -u chatkit-backend -n 50`

### If nginx fails:
- Test config: `sudo nginx -t`
- Check error logs: `sudo tail -f /var/log/nginx/error.log`

### If backend won't start:
- Check logs: `sudo journalctl -u chatkit-backend -f`
- Verify Python version: `python3.11 --version`
- Check virtual environment: `ls -la backend/.venv`

## Quick Reference Commands

```bash
# View backend logs
sudo journalctl -u chatkit-backend -f

# Restart backend
sudo systemctl restart chatkit-backend

# Restart nginx
sudo systemctl restart nginx

# Rebuild frontend
cd /var/www/sop-chatbot.livelihoodnw.org
npm run frontend:build

# Update and redeploy
cd /var/www/sop-chatbot.livelihoodnw.org
git pull  # if using git
npm run frontend:build
sudo systemctl restart chatkit-backend
```
