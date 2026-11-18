# BoardBuddy Deployment & Operations Guide

## 1. System Overview

BoardBuddy is an AI-powered Kanban project-management backend built with:
- **FastAPI** (Python 3.12)
- **SQLAlchemy 2.x & Alembic** (Database ORM & Migrations)
- **PostgreSQL 16 + pgvector** (Relational data + vector embeddings)
- **Gemini 1.5 Flash & text-embedding-004** (AI Goal-to-board & Embeddings)
- **Deerflow Contextual Insights** (Bounded, reliable contextual intelligence with deterministic fallbacks)
- **Docker & Docker Compose** (Containerized orchestration)

---

## 2. Environment Configuration

Copy `.env.example` to `.env` and configure appropriate variables:

```bash
cp .env.example .env
```

### Configuration Variables

| Variable | Description | Default |
|---|---|---|
| `APP_ENV` | Application environment (`development` / `production`) | `development` |
| `APP_SECRET_KEY` | JWT signing secret (minimum 32 characters in production) | Dev secret |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Access token lifespan in minutes | `60` |
| `CORS_ORIGINS` | Comma-separated allowed HTTP origins | `http://localhost:3000,http://localhost:8080` |
| `DATABASE_URL` | PostgreSQL connection string | `postgresql+psycopg://boardbuddy:local-dev-only@localhost:5432/boardbuddy` |
| `LLM_PROVIDER` | LLM client (`gemini` or `mock`) | `gemini` |
| `GEMINI_API_KEY` | Google Gemini API key | None |
| `GEMINI_MODEL` | Gemini model name | `gemini-1.5-flash` |
| `EMBEDDING_PROVIDER` | Embedding provider (`gemini` or `mock`) | `gemini` |
| `EMBEDDING_MODEL` | Gemini embedding model name | `text-embedding-004` |
| `EMBEDDING_DIMENSIONS` | Embedding vector dimensions | `768` |
| `MAX_AGENT_STEPS` | Maximum tool-calling loop iterations | `5` |
| `MAX_TOOL_CALLS` | Maximum cumulative tool calls per turn | `8` |

---

## 3. Running with Docker Compose

To build and start the database, backend API, and background embedding worker:

```bash
docker compose up --build
```

Services started:
1. `db`: PostgreSQL 16 with pgvector (`pgvector/pgvector:pg16`) on port `5432`
2. `api`: FastAPI application running Alembic migrations automatically on port `8000`
3. `worker`: Background embedding outbox worker polling for card mutations

---

## 4. Running Locally without Docker

### Setup Virtual Environment

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
```

### Database Migrations

```bash
# Run migrations up to latest version
alembic upgrade head

# Rollback one migration
alembic downgrade -1
```

### Start Development Server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Start Background Outbox Worker

```bash
python -m app.workers.embeddings
```

---

## 5. Testing & Evaluation

### Run Test Suite (75 passing tests)

```bash
pytest tests/
```

### Run 30 Evaluation Scenarios Runner

```bash
python scripts/run_evals.py
```

### Run Flutter Client Tests

```bash
cd client
flutter test
```

---

## 6. Production Hardening Checklist

1. **Secrets**: Ensure `APP_SECRET_KEY` is cryptographically random and rotated periodically. Never commit `.env`.
2. **CORS**: Set `CORS_ORIGINS` strictly to production client domain names.
3. **Database Access**: Ensure PostgreSQL port `5432` is bound to private internal networks only.
4. **Rate Limiting & Timeouts**: Maintain proxy timeouts (Nginx/Cloudflare) at 60s to accommodate bounded agent multi-step turns.
5. **AI Reliability**: The system automatically uses deterministic fallbacks if external AI or research APIs experience transient outages.
