# BoardBuddy Free-Tier Hosting Guide (No Render)

This guide shows how to deploy the entire BoardBuddy stack (PostgreSQL + pgvector, FastAPI Backend, and Flutter Web Frontend) for **$0 / month** using modern developer platforms with **no cold-start degradation** and **native pgvector support**.

---

## Architecture Overview

```
┌─────────────────────────────────┐
│     Cloudflare Pages / Vercel    │  <-- Flutter Web Client (100% Free, Global CDN)
│       (https://boardbuddy.dev)   │
└────────────────┬────────────────┘
                 │ REST / WebSockets
┌────────────────▼────────────────┐
│         Fly.io / Koyeb          │  <-- FastAPI Backend (Docker, 100% Free Tier)
│    (https://api.boardbuddy.dev) │
└────────────────┬────────────────┘
                 │ TCP / SSL
┌────────────────▼────────────────┐
│      Supabase / Neon.tech       │  <-- PostgreSQL 16 + pgvector (100% Free Tier)
│    (Native Vector Embeddings)   │
└─────────────────────────────────┘
```

---

## 1. Database: Supabase or Neon (PostgreSQL + pgvector)

### Why NOT Render?
Render free tier does not support persistent storage or custom Postgres extensions like `pgvector` on free accounts, and shuts down aggressively.

### Option A: Supabase (Recommended)
1. Sign up at [supabase.com](https://supabase.com) (Free account, no credit card required).
2. Click **New Project** $\rightarrow$ Name: `boardbuddy` $\rightarrow$ Set a strong database password.
3. Once provisioned, navigate to **Project Settings** $\rightarrow$ **Database** $\rightarrow$ **Connection String** (select **URI** or **Transaction Pooler**).
4. Go to **SQL Editor** and run:
   ```sql
   CREATE EXTENSION IF NOT EXISTS vector;
   ```
5. Format your connection string for Python `psycopg`:
   ```bash
   DATABASE_URL=postgresql+psycopg://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres
   ```

### Option B: Neon.tech (Alternative)
1. Sign up at [neon.tech](https://neon.tech) (Free tier with 0.5 GB storage).
2. Create project `boardbuddy`.
3. In SQL Console, run `CREATE EXTENSION IF NOT EXISTS vector;`.
4. Copy the connection string with `postgresql+psycopg://...`.

---

## 2. Backend: Fly.io (Container Hosting)

Fly.io runs our native [`Dockerfile`](../Dockerfile) directly with sub-second wake times and global edge SSL.

### Step 1: Install Fly CLI
```bash
# macOS
brew install flyctl

# Linux / WSL
curl -L https://fly.io/install.sh | sh
```

### Step 2: Login & Launch
```bash
fly auth login
fly launch --no-deploy
```

### Step 3: Set Secrets
```bash
fly secrets set \
  APP_ENV=production \
  APP_SECRET_KEY="generate-a-secure-32-char-random-secret" \
  DATABASE_URL="postgresql+psycopg://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres" \
  GEMINI_API_KEY="your-gemini-api-key" \
  TAVILY_API_KEY="your-tavily-api-key" \
  CORS_ORIGINS="https://your-frontend-domain.pages.dev,http://localhost:3000"
```

### Step 4: Deploy & Run Migrations
```bash
# Run database migrations remotely
fly ssh console -C "alembic upgrade head"

# Deploy container
fly deploy
```

---

## 3. Backend Alternative: Koyeb (Zero-Config Docker)

Koyeb offers an **Always Free Eco Tier** (512 MB RAM, 0.1 vCPU) with continuous deployment from GitHub:

1. Sign up at [koyeb.com](https://koyeb.com).
2. Click **Create Service** $\rightarrow$ Select **GitHub**.
3. Select your `Boardbuddy` repository.
4. Builder: Select **Dockerfile**.
5. Under **Environment Variables**, add:
   - `DATABASE_URL` (from Supabase/Neon)
   - `APP_SECRET_KEY`
   - `GEMINI_API_KEY`
   - `PORT=8000`
6. Click **Deploy**. Koyeb automatically provisions an SSL endpoint (e.g. `https://boardbuddy-yourname.koyeb.app`).

---

## 4. Frontend: Flutter Web on Cloudflare Pages or Vercel

### Step 1: Build Web Release
```bash
cd client
flutter build web --release
```

### Step 2: Deploy to Cloudflare Pages (Completely Free, Unlimited Bandwidth)
```bash
# Using Wrangler CLI
npx wrangler pages deploy build/web --project-name=boardbuddy
```
Or simply drag-and-drop the `client/build/web` folder into the Cloudflare Pages web dashboard.

---

## 5. Cost Summary

| Service | Provider | Cost | Tier Details |
|---|---|---|---|
| **Database + pgvector** | Supabase | **$0** | 500 MB storage, native vector indexing |
| **Backend API** | Fly.io / Koyeb | **$0** | Free tier container hosting, global SSL |
| **Frontend Web** | Cloudflare Pages | **$0** | Unlimited bandwidth, custom domain included |
| **Total Monthly Cost** | | **$0.00** | Production-ready with zero Render cold-starts |
