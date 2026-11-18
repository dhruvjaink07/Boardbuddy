# 100% Free Hosting Guide (Zero Cost, No Credit Card, No Render)

This guide documents completely free hosting options where you can run the BoardBuddy Backend and Database with **$0 / month**, **NO credit card required**, and **NO Render cold-start lag**.

---

## The 100% Free Stack

| Layer | Service | Cost | Credit Card? | Why it works for BoardBuddy |
|---|---|---|---|---|
| **Database** | **Supabase** or **Neon.tech** | **$0** | ❌ **No CC needed** | PostgreSQL 16 with native `pgvector` pre-installed |
| **Backend API** | **Hugging Face Spaces** (Docker) | **$0** | ❌ **No CC needed** | 16 GB RAM, 2 vCPUs, runs our Dockerfile 24/7 with public HTTPS |
| **Alternative API** | **Cloudflare Tunnel** (`cloudflared`) | **$0** | ❌ **No CC needed** | Exposes your local Docker instance to a global HTTPS URL |
| **Frontend Web** | **Cloudflare Pages** or **Vercel** | **$0** | ❌ **No CC needed** | Unlimited global CDN bandwidth for Flutter Web build |

---

## 1. Database: Supabase (PostgreSQL + pgvector)

Supabase gives 2 free PostgreSQL databases with native `pgvector` support and **no credit card required** at signup.

### Steps:
1. Go to [supabase.com](https://supabase.com) $\rightarrow$ Sign in with GitHub.
2. Click **New Project**:
   - Name: `boardbuddy`
   - Database Password: Choose a strong password.
3. Once the database is ready (takes ~1 minute), open the **SQL Editor** tab and execute:
   ```sql
   CREATE EXTENSION IF NOT EXISTS vector;
   ```
4. Go to **Project Settings** $\rightarrow$ **Database** $\rightarrow$ **Connection String** $\rightarrow$ **URI**.
5. Copy the connection string. In BoardBuddy, prefix it with `postgresql+psycopg://`:
   ```bash
   DATABASE_URL=postgresql+psycopg://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres
   ```

*(Alternative: [neon.tech](https://neon.tech) also offers a 100% free serverless PostgreSQL database with native `pgvector` and no credit card).*

---

## 2. Backend: Hugging Face Spaces (Docker SDK)

Hugging Face Spaces provides a **free container hosting tier with 16 GB RAM and 2 vCPUs** that runs any Dockerfile directly, requires **NO credit card**, and gives you a free public HTTPS endpoint.

### Steps:
1. Create a free account at [huggingface.co](https://huggingface.co) (no credit card).
2. Click **New Space** $\rightarrow$ [huggingface.co/new-space](https://huggingface.co/new-space).
   - Space Name: `boardbuddy-api`
   - License: `mit`
   - Space SDK: Select **Docker** $\rightarrow$ **Blank**
   - Space Hardware: **CPU Basic (Free - 2 vCPU, 16 GB RAM)**
   - Visibility: **Public**
3. In your Space's **Settings** $\rightarrow$ **Variables and Secrets**, add your secrets:
   - `DATABASE_URL`: `postgresql+psycopg://postgres:[PASSWORD]@db.[REF].supabase.co:5432/postgres`
   - `APP_SECRET_KEY`: `your-random-32-char-secret`
   - `GEMINI_API_KEY`: `your-gemini-api-key`
   - `TAVILY_API_KEY`: `your-tavily-api-key` (optional)
   - `CORS_ORIGINS`: `*`
4. Push the BoardBuddy repository to your Space:
   ```bash
   git remote add space https://huggingface.co/spaces/[YOUR-USERNAME]/boardbuddy-api
   git push space main
   ```
5. Hugging Face builds the `Dockerfile` and starts Uvicorn on port `7860`.
6. Your backend API is instantly live at:
   ```
   https://[YOUR-USERNAME]-boardbuddy-api.hf.space
   ```
   Open `https://[YOUR-USERNAME]-boardbuddy-api.hf.space/docs` to see the interactive Swagger UI!

---

## 3. Alternative: Run Locally with Cloudflare Tunnel (100% Free, Private & Powerful)

If you have Docker running locally on your computer and want to make your API available to mobile phones, Flutter Web, or collaborators anywhere in the world for **$0 with zero deployment hassle**:

```bash
# 1. Start BoardBuddy locally with Docker Compose
docker compose up -d

# 2. Run Cloudflare Tunnel (free, no sign-up or credit card required)
brew install cloudflared
cloudflared tunnel --url http://localhost:8000
```
Cloudflare will instantly print a public secure URL:
```
https://random-words.trycloudflare.com
```
Any request sent to this URL securely proxies directly to your local FastAPI backend!

---

## 4. Frontend: Flutter Web on Cloudflare Pages (100% Free)

1. Build the production web bundle:
   ```bash
   cd client
   flutter build web --release
   ```
2. Deploy to Cloudflare Pages (no credit card):
   - Open [dash.cloudflare.com](https://dash.cloudflare.com) $\rightarrow$ **Workers & Pages** $\rightarrow$ **Pages** $\rightarrow$ **Upload Assets**.
   - Drag and drop the `client/build/web` directory.
   - Name your project `boardbuddy`.
3. Your web app is live with free global CDN and SSL at `https://boardbuddy.pages.dev`!

---

## Summary: $0.00 Total Cost

- **Database**: Supabase (Free tier PostgreSQL + `pgvector`)
- **Backend API**: Hugging Face Spaces (Free Docker, 16 GB RAM) OR Cloudflare Tunnel
- **Frontend App**: Cloudflare Pages (Free unlimited web hosting)
- **Credit Card Required**: **NONE**
- **Cold-Start Delays**: **NONE** (Hugging Face Spaces runs continuously without sleeping)
