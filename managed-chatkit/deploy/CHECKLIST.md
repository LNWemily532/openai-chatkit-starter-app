# Deployment Checklist

## Step 1: Test Production Build Locally ✅ (Do this first!)

Before deploying to your server, test that everything builds correctly:

```bash
# In the project root directory
npm run frontend:build
```

This should create a `frontend/dist` folder. If it succeeds, you're ready to deploy!

---

## Step 2: Prepare Your Server

Make sure you have:
- [ ] A server with Ubuntu/Debian Linux
- [ ] Root or sudo access
- [ ] DNS pointing `sop-chatbot.livelihoodnw.org` to your server IP
- [ ] SSH access to your server

---

## Step 3: Upload Code to Server

Upload your project to `/var/www/sop-chatbot.livelihoodnw.org` on your server.

**Option A: Using Git (Recommended)**
```bash
# On your server
cd /var/www
sudo git clone <your-repo-url> sop-chatbot.livelihoodnw.org
sudo chown -R $USER:$USER sop-chatbot.livelihoodnw.org
```

**Option B: Using SCP (from your local machine)**
```bash
# From your local machine
scp -r managed-chatkit user@your-server:/var/www/sop-chatbot.livelihoodnw.org
```

**Option C: Using rsync (from your local machine)**
```bash
# From your local machine
rsync -avz --exclude 'node_modules' --exclude '.venv' --exclude '__pycache__' \
  managed-chatkit/ user@your-server:/var/www/sop-chatbot.livelihoodnw.org/
```

---

## Step 4: Set Up Environment Variables on Server

On your server, create `.env.local`:

```bash
cd /var/www/sop-chatbot.livelihoodnw.org
nano .env.local
```

Add:
```env
OPENAI_API_KEY=sk-your-actual-api-key
VITE_CHATKIT_WORKFLOW_ID=wf-your-actual-workflow-id
CHATKIT_API_BASE=https://api.openai.com
ENVIRONMENT=production
NODE_ENV=production
```

Save and set permissions:
```bash
chmod 600 .env.local
```

---

## Step 5: Run Quick Deploy Script

On your server:
```bash
cd /var/www/sop-chatbot.livelihoodnw.org
sudo bash deploy/quick-deploy.sh
```

This will:
- Build the frontend
- Set up the backend
- Configure nginx
- Start the services

---

## Step 6: Set Up SSL Certificate

```bash
sudo certbot --nginx -d sop-chatbot.livelihoodnw.org
```

Follow the prompts to get your SSL certificate.

---

## Step 7: Verify Everything Works

1. Visit: `https://sop-chatbot.livelihoodnw.org`
2. Check backend: `curl http://127.0.0.1:8000/health`
3. Check logs: `sudo journalctl -u chatkit-backend -f`

---

## Troubleshooting

- **Build fails?** Check Node.js version (needs 18+)
- **Backend won't start?** Check `.env.local` has correct values
- **Nginx errors?** Check: `sudo nginx -t`
- **SSL issues?** Make sure DNS is pointing correctly first
