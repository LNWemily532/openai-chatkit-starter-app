# Deploying to Netlify

Yes, you can use Netlify! Here's how:

## Architecture Overview

- **Frontend**: Deploy to Netlify (static hosting)
- **Backend**: Deploy separately to a Python-friendly platform (Railway, Render, Fly.io, etc.)

## Option 1: Frontend on Netlify + Backend on Railway/Render (Recommended)

This is the easiest approach - keep your FastAPI backend as-is and just host it elsewhere.

### Step 1: Deploy Backend to Railway (Easiest)

1. Go to [railway.app](https://railway.app) and sign up
2. Click "New Project" → "Deploy from GitHub repo" (or upload your code)
3. Select your `backend` folder
4. Railway will auto-detect Python and install dependencies
5. Add environment variables:
   - `OPENAI_API_KEY=sk-your-key`
   - `VITE_CHATKIT_WORKFLOW_ID=wf-your-workflow-id`
   - `ENVIRONMENT=production`
   - `NODE_ENV=production`
6. Railway will give you a URL like `https://your-app.up.railway.app`
7. Set the root command to: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`

### Step 2: Deploy Frontend to Netlify

1. **Create `netlify.toml`** in your project root (see below)
2. **Update frontend config** to point to your Railway backend URL
3. Go to [netlify.com](https://netlify.com) and sign up
4. Click "Add new site" → "Import an existing project"
5. Connect your GitHub repo (or drag & drop the `frontend/dist` folder)
6. Set build settings:
   - **Build command**: `npm run frontend:build`
   - **Publish directory**: `frontend/dist`
7. Add environment variables in Netlify dashboard:
   - `VITE_CHATKIT_WORKFLOW_ID=wf-your-workflow-id`
   - `VITE_API_URL=https://your-app.up.railway.app` (your Railway backend URL)
8. Deploy!

### Step 3: Configure Custom Domain

1. In Netlify dashboard → Site settings → Domain management
2. Add custom domain: `sop-chatbot.livelihoodnw.org`
3. Follow DNS instructions to point your domain to Netlify
4. Netlify will automatically provision SSL

---

## Option 2: Frontend on Netlify + Backend as Netlify Function

Convert your FastAPI endpoint to a Netlify Function. This keeps everything on Netlify but requires code changes.

### Step 1: Create Netlify Function

Create `netlify/functions/create-session.py`:

```python
import json
import os
import uuid
import httpx

DEFAULT_CHATKIT_BASE = "https://api.openai.com"

def handler(event, context):
    """Netlify function to create ChatKit session."""
    if event['httpMethod'] != 'POST':
        return {
            'statusCode': 405,
            'body': json.dumps({'error': 'Method not allowed'})
        }
    
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Missing OPENAI_API_KEY'})
        }
    
    try:
        body = json.loads(event.get('body', '{}'))
        workflow_id = body.get('workflow', {}).get('id') or body.get('workflowId')
        
        if not workflow_id:
            workflow_id = os.getenv("VITE_CHATKIT_WORKFLOW_ID")
        
        if not workflow_id:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Missing workflow id'})
            }
        
        # Get or create user ID from cookies
        cookies = event.get('headers', {}).get('cookie', '')
        user_id = None
        for cookie in cookies.split(';'):
            if 'chatkit_session_id=' in cookie:
                user_id = cookie.split('chatkit_session_id=')[1].split(';')[0].strip()
                break
        
        if not user_id:
            user_id = str(uuid.uuid4())
        
        # Call OpenAI ChatKit API
        api_base = os.getenv("CHATKIT_API_BASE", DEFAULT_CHATKIT_BASE)
        
        with httpx.Client(base_url=api_base, timeout=10.0) as client:
            response = client.post(
                "/v1/chatkit/sessions",
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "OpenAI-Beta": "chatkit_beta=v1",
                    "Content-Type": "application/json",
                },
                json={"workflow": {"id": workflow_id}, "user": user_id},
            )
        
        if not response.is_success:
            error_msg = response.json().get('error', 'Failed to create session')
            return {
                'statusCode': response.status_code,
                'body': json.dumps({'error': error_msg})
            }
        
        payload = response.json()
        client_secret = payload.get('client_secret')
        
        if not client_secret:
            return {
                'statusCode': 502,
                'body': json.dumps({'error': 'Missing client secret in response'})
            }
        
        # Set cookie in response
        cookie_value = user_id
        cookie_header = f"chatkit_session_id={cookie_value}; Path=/; HttpOnly; SameSite=Lax; Max-Age=2592000"
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Set-Cookie': cookie_header
            },
            'body': json.dumps({
                'client_secret': client_secret,
                'expires_after': payload.get('expires_after')
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
```

### Step 2: Update Frontend to Use Netlify Function

The frontend will automatically use `/api/create-session` which Netlify will route to the function.

### Step 3: Configure Netlify

Create `netlify.toml` in project root (see below).

---

## Required Files

### `netlify.toml` (for Option 1 - Frontend only)

```toml
[build]
  command = "npm run frontend:build"
  publish = "frontend/dist"

[[redirects]]
  from = "/api/*"
  to = "https://your-backend-url.up.railway.app/api/:splat"
  status = 200
  force = true

[build.environment]
  NODE_VERSION = "18"
```

**Important**: Replace `your-backend-url.up.railway.app` with your actual Railway backend URL.

### `netlify.toml` (for Option 2 - Frontend + Functions)

```toml
[build]
  command = "npm run frontend:build"
  publish = "frontend/dist"

[functions]
  directory = "netlify/functions"

[build.environment]
  NODE_VERSION = "18"
  PYTHON_VERSION = "3.11"
```

---

## Environment Variables

Set these in Netlify Dashboard → Site settings → Environment variables:

**For Frontend:**
- `VITE_CHATKIT_WORKFLOW_ID=wf-your-workflow-id`
- `VITE_API_URL=https://your-backend-url.up.railway.app` (only if using Option 1)

**For Backend (Railway/Render):**
- `OPENAI_API_KEY=sk-your-key`
- `VITE_CHATKIT_WORKFLOW_ID=wf-your-workflow-id`
- `ENVIRONMENT=production`
- `NODE_ENV=production`

---

## Quick Start (Option 1 - Recommended)

1. **Deploy backend to Railway:**
   ```bash
   # Install Railway CLI
   npm i -g @railway/cli
   
   # Login
   railway login
   
   # In your backend directory
   cd backend
   railway init
   railway up
   
   # Set environment variables
   railway variables set OPENAI_API_KEY=sk-your-key
   railway variables set VITE_CHATKIT_WORKFLOW_ID=wf-your-workflow-id
   ```

2. **Get your Railway URL** (something like `https://your-app.up.railway.app`)

3. **Create `netlify.toml`** in project root with your Railway URL

4. **Deploy frontend to Netlify:**
   - Connect GitHub repo OR drag & drop `frontend/dist` folder
   - Netlify will auto-detect settings from `netlify.toml`
   - Add environment variables in dashboard
   - Deploy!

5. **Add custom domain** in Netlify dashboard

---

## Alternative Backend Hosting Options

If Railway doesn't work for you:

- **Render.com**: Similar to Railway, free tier available
- **Fly.io**: Great for Python apps, free tier
- **PythonAnywhere**: Simple Python hosting
- **Heroku**: Paid but reliable (no free tier anymore)

All of these can host your FastAPI backend, then you just point Netlify to them.

---

## Troubleshooting

**Frontend can't reach backend?**
- Check `VITE_API_URL` is set correctly in Netlify
- Verify your Railway/Render backend is running
- Check CORS settings in backend (should allow your Netlify domain)

**Netlify build fails?**
- Make sure `netlify.toml` has correct paths
- Check Node.js version (needs 18+)
- Verify build command works locally first

**Functions not working?**
- Make sure Python runtime is specified in `netlify.toml`
- Check function logs in Netlify dashboard
- Verify environment variables are set
