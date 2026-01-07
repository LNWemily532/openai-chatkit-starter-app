# Netlify Deployment Guide

This guide will help you deploy your ChatKit application using **Netlify for the frontend** and a backend hosting service.

## Architecture Overview

- **Frontend**: Deploy to Netlify (static React app)
- **Backend**: Deploy to Railway, Render, or Fly.io (FastAPI Python app)
- **Domain**: Configure subdomain in IONOS to point to Netlify

## Option 1: Netlify + Railway (Recommended - Easiest)

### Why Railway?
- ✅ Free tier available
- ✅ Automatic deployments from Git
- ✅ Built-in SSL
- ✅ Easy Python/FastAPI support
- ✅ Environment variable management

### Step 1: Deploy Backend to Railway

1. **Sign up/Login to Railway**
   - Go to [railway.app](https://railway.app)
   - Sign up with GitHub (free)

2. **Create New Project**
   - Click "New Project"
   - Select "Deploy from GitHub repo" (or upload the `backend` folder)

3. **Configure Backend**
   - Set root directory to `backend` (if deploying from monorepo)
   - Railway will auto-detect Python
   - Add these environment variables in Railway dashboard:
     ```
     OPENAI_API_KEY=sk-your-key-here
     CHATKIT_WORKFLOW_ID=wf-your-workflow-id
     ENVIRONMENT=production
     NODE_ENV=production
     PORT=8000
     ```

4. **Deploy**
   - Railway will automatically build and deploy
   - Note the generated URL (e.g., `https://your-app.railway.app`)

5. **Create `railway.json` in backend folder** (optional, for custom config):
   ```json
   {
     "$schema": "https://railway.app/railway.schema.json",
     "build": {
       "builder": "NIXPACKS"
     },
     "deploy": {
       "startCommand": "uvicorn app.main:app --host 0.0.0.0 --port $PORT",
       "restartPolicyType": "ON_FAILURE",
       "restartPolicyMaxRetries": 10
     }
   }
   ```

### Step 2: Deploy Frontend to Netlify

1. **Prepare for Deployment**
   - Make sure your code is in a Git repository (GitHub, GitLab, or Bitbucket)
   - Or use Netlify CLI (see below)

2. **Option A: Deploy via Netlify Dashboard**
   - Go to [app.netlify.com](https://app.netlify.com)
   - Click "Add new site" → "Import an existing project"
   - Connect your Git repository
   - Configure build settings:
     - **Build command**: `npm install && npm run frontend:build`
     - **Publish directory**: `frontend/dist`
     - **Base directory**: (leave empty, or set to root)

3. **Set Environment Variables in Netlify**
   - Go to Site settings → Environment variables
   - Add:
     ```
     VITE_CHATKIT_WORKFLOW_ID=wf-your-workflow-id
     VITE_API_URL=https://your-backend.railway.app
     ```
   - Replace `your-backend.railway.app` with your actual Railway URL

4. **Deploy**
   - Netlify will build and deploy automatically
   - You'll get a URL like `https://random-name.netlify.app`

### Step 3: Configure Custom Domain (IONOS)

1. **In Netlify Dashboard**
   - Go to Site settings → Domain management
   - Click "Add custom domain"
   - Enter: `sop-chatbot.livelihoodnw.org`
   - Follow Netlify's DNS instructions

2. **In IONOS DNS Settings**
   - Log into IONOS
   - Go to Domain settings → DNS
   - Add a CNAME record:
     - **Name**: `sop-chatbot`
     - **Value**: `your-site-name.netlify.app` (from Netlify)
     - **TTL**: 3600

3. **SSL Certificate**
   - Netlify automatically provisions SSL certificates via Let's Encrypt
   - Wait a few minutes for DNS propagation and SSL setup

### Step 4: Update CORS in Backend

Update your Railway backend environment variables to allow your Netlify domain:
```
CORS_ORIGINS=https://sop-chatbot.livelihoodnw.org,https://your-site.netlify.app
```

---

## Option 2: Netlify + Render

### Why Render?
- ✅ Free tier available
- ✅ Automatic SSL
- ✅ Good Python support

### Deploy Backend to Render

1. **Sign up at [render.com](https://render.com)**

2. **Create New Web Service**
   - Connect your GitHub repo
   - Select the `backend` directory
   - Choose "Python 3" environment
   - Build command: `pip install .`
   - Start command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`

3. **Set Environment Variables**
   ```
   OPENAI_API_KEY=sk-your-key
   CHATKIT_WORKFLOW_ID=wf-your-workflow-id
   ENVIRONMENT=production
   ```

4. **Deploy** - Render will give you a URL like `https://your-app.onrender.com`

5. **Update Netlify Environment Variables**
   - Set `VITE_API_URL=https://your-app.onrender.com`

---

## Option 3: Netlify + Fly.io

### Why Fly.io?
- ✅ Free tier
- ✅ Global edge network
- ✅ Great for Python apps

### Deploy Backend to Fly.io

1. **Install Fly CLI**: `curl -L https://fly.io/install.sh | sh`

2. **Create `fly.toml` in backend folder**:
   ```toml
   app = "your-chatkit-backend"
   primary_region = "iad"

   [build]

   [http_service]
     internal_port = 8000
     force_https = true
     auto_stop_machines = true
     auto_start_machines = true
     min_machines_running = 0

   [[vm]]
     cpu_kind = "shared"
     cpus = 1
     memory_mb = 256
   ```

3. **Deploy**:
   ```bash
   cd backend
   fly launch
   fly secrets set OPENAI_API_KEY=sk-your-key
   fly secrets set CHATKIT_WORKFLOW_ID=wf-your-workflow-id
   fly deploy
   ```

---

## Option 4: Netlify Functions (Advanced)

If you want everything on Netlify, you can convert the backend to Netlify Functions, but this requires rewriting the FastAPI code. Not recommended unless you're comfortable with serverless functions.

---

## Quick Deploy Checklist

### Backend (Railway/Render/Fly.io)
- [ ] Deploy backend service
- [ ] Set environment variables (OPENAI_API_KEY, CHATKIT_WORKFLOW_ID, etc.)
- [ ] Note the backend URL
- [ ] Test backend: `curl https://your-backend-url/health`

### Frontend (Netlify)
- [ ] Connect Git repository or use Netlify CLI
- [ ] Set build command: `npm install && npm run frontend:build`
- [ ] Set publish directory: `frontend/dist`
- [ ] Set environment variables:
  - [ ] `VITE_CHATKIT_WORKFLOW_ID`
  - [ ] `VITE_API_URL` (your backend URL)
- [ ] Deploy

### Domain (IONOS)
- [ ] Add CNAME record in IONOS pointing to Netlify
- [ ] Add custom domain in Netlify dashboard
- [ ] Wait for SSL certificate provisioning

### Testing
- [ ] Visit `https://sop-chatbot.livelihoodnw.org`
- [ ] Test chat functionality
- [ ] Check browser console for errors
- [ ] Verify API calls are working

---

## Troubleshooting

### Frontend can't reach backend
- Check `VITE_API_URL` is set correctly in Netlify
- Verify backend is running and accessible
- Check CORS settings in backend (should allow your Netlify domain)

### CORS errors
- Update backend `CORS_ORIGINS` to include:
  - `https://sop-chatbot.livelihoodnw.org`
  - `https://your-site.netlify.app`

### Domain not working
- Wait 24-48 hours for DNS propagation
- Check DNS records in IONOS match Netlify's requirements
- Verify SSL certificate is active in Netlify dashboard

### Build failures
- Check Netlify build logs
- Ensure `package.json` has all dependencies
- Verify Node.js version (should be 18+)

---

## Recommended: Railway + Netlify

For the easiest deployment experience, I recommend:
1. **Railway for backend** - Simplest Python deployment
2. **Netlify for frontend** - You already have an account
3. **IONOS DNS** - Point subdomain to Netlify

This gives you:
- ✅ Free tiers on both platforms
- ✅ Automatic SSL
- ✅ Easy environment variable management
- ✅ Git-based deployments
- ✅ No server management needed
