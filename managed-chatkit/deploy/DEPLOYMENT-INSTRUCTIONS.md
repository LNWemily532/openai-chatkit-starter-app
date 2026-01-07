# Quick Deployment Instructions

## Option 1: Automated Deployment (Recommended)

### On Your Local Machine:

1. **Prepare the deployment package:**
   ```bash
   cd /path/to/managed-chatkit
   bash deploy/prepare-deployment.sh
   ```
   This will:
   - Build the frontend
   - Create a `deployment.tar.gz` file

2. **Upload to your server:**
   ```bash
   # Upload the archive
   scp deployment.tar.gz user@your-server:/tmp/
   
   # Upload .env.local (separately for security)
   scp .env.local user@your-server:/tmp/
   ```

### On Your Server:

1. **Extract and set up:**
   ```bash
   # Create project directory
   sudo mkdir -p /var/www/sop-chatbot.livelihoodnw.org
   cd /var/www/sop-chatbot.livelihoodnw.org
   
   # Extract archive
   sudo tar -xzf /tmp/deployment.tar.gz
   
   # Copy .env.local
   sudo cp /tmp/.env.local .
   sudo chmod 600 .env.local
   
   # Run automated deployment
   sudo bash deploy/remote-deploy.sh
   ```

2. **Set up SSL (if not done automatically):**
   ```bash
   sudo certbot --nginx -d sop-chatbot.livelihoodnw.org
   ```

## Option 2: Manual Deployment

Follow the detailed steps in `DEPLOY.md`

## Option 3: Using Git (If you have a repository)

### On Your Server:

```bash
# Clone repository
cd /var/www
sudo git clone <your-repo-url> sop-chatbot.livelihoodnw.org
cd sop-chatbot.livelihoodnw.org

# Create .env.local
sudo nano .env.local
# Add your environment variables

# Run deployment
sudo bash deploy/remote-deploy.sh
```

## Verification

After deployment, verify everything is working:

```bash
# Check backend
curl http://127.0.0.1:8000/health

# Check services
sudo systemctl status chatkit-backend
sudo systemctl status nginx

# Visit in browser
# https://sop-chatbot.livelihoodnw.org
```

## Troubleshooting

### Backend not starting:
```bash
sudo journalctl -u chatkit-backend -n 50
```

### Nginx errors:
```bash
sudo tail -f /var/log/nginx/error.log
```

### Check if ports are in use:
```bash
sudo netstat -tulpn | grep -E ':(8000|80|443)'
```

### Restart services:
```bash
sudo systemctl restart chatkit-backend
sudo systemctl restart nginx
```
