# 08 · Deployment

## Runtime

**[NEW]** Python 3.12, FastAPI/Uvicorn, PostgreSQL + pgvector, SQLAlchemy 2.x, Alembic, Pydantic v2, Docker/Compose. Gemini is the initial LLM adapter behind `LLMClient`.

## Dockerfile

```dockerfile
FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends build-essential libpq-dev \
 && rm -rf /var/lib/apt/lists/*
COPY pyproject.toml ./
COPY app ./app
COPY migrations ./migrations
COPY alembic.ini ./
RUN pip install --upgrade pip && pip install .
RUN useradd --create-home appuser
USER appuser
EXPOSE 8000
CMD ["uvicorn","app.main:app","--host","0.0.0.0","--port","8000"]
```

## docker-compose.yml

```yaml
services:
  db:
    image: pgvector/pgvector:pg16
    environment:
      POSTGRES_DB: boardbuddy
      POSTGRES_USER: boardbuddy
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-local-dev-only}
    ports: ["5432:5432"]
    volumes: ["pgdata:/var/lib/postgresql/data"]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U boardbuddy -d boardbuddy"]
      interval: 5s
      timeout: 3s
      retries: 10
  api:
    build: .
    env_file: .env
    environment:
      DATABASE_URL: postgresql+psycopg://boardbuddy:${POSTGRES_PASSWORD:-local-dev-only}@db:5432/boardbuddy
    ports: ["8000:8000"]
    depends_on:
      db: {condition: service_healthy}
    command: sh -c "alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port 8000"
  worker:
    build: .
    env_file: .env
    environment:
      DATABASE_URL: postgresql+psycopg://boardbuddy:${POSTGRES_PASSWORD:-local-dev-only}@db:5432/boardbuddy
    depends_on:
      db: {condition: service_healthy}
    command: ["python", "-m", "app.workers.embeddings"]
volumes:
  pgdata:
```

For early local development, omit worker until outbox exists. Do not expose production database publicly.

## `.env.example`

```dotenv
APP_ENV=development
APP_SECRET_KEY=replace-with-random-secret
ACCESS_TOKEN_EXPIRE_MINUTES=60
CORS_ORIGINS=http://localhost:3000,http://localhost:8080
POSTGRES_PASSWORD=local-dev-only
DATABASE_URL=postgresql+psycopg://boardbuddy:local-dev-only@localhost:5432/boardbuddy
LLM_PROVIDER=gemini
GEMINI_API_KEY=
GEMINI_MODEL=
LLM_TEMPERATURE=0.2
LLM_TIMEOUT_SECONDS=30
EMBEDDING_PROVIDER=gemini
EMBEDDING_MODEL=
EMBEDDING_DIMENSIONS=768
EMBEDDING_BATCH_SIZE=32
MAX_AGENT_STEPS=5
MAX_TOOL_CALLS=8
MAX_AGENT_CONTEXT_TOKENS=12000
LOG_LEVEL=INFO
SENTRY_DSN=
```

Verify current Gemini model IDs, embedding API availability and dimensions before deployment. Never hardcode secrets or model IDs in source.

## Local run

```bash
cp .env.example .env
# Set strong APP_SECRET_KEY and GEMINI_API_KEY in .env
docker compose up --build
```

Health: `http://localhost:8000/health`; OpenAPI: `http://localhost:8000/docs`.

## Fly.io steps

1. Install `flyctl`, authenticate and create app: `fly launch --no-deploy`.
2. Provision PostgreSQL that supports pgvector; verify extension availability on the selected offering.
3. Set secrets with `fly secrets set APP_SECRET_KEY=... GEMINI_API_KEY=...` and database credentials/URL.
4. Configure production CORS allowlist, `APP_ENV=production`, logging and error reporting.
5. Deploy with `fly deploy`.
6. Run Alembic migrations as a release command or one-off machine, not independently on every API replica.
7. Deploy embedding worker as a separate process group if needed.
8. Verify health, auth, board permissions, agent smoke evals, backups and logs.

**[ASSUMPTION]** Fly.io product names, managed Postgres/pgvector availability and CLI syntax can change. Verify current Fly.io docs before production launch.

## Production checklist

- TLS enforced; secrets in platform secret manager.
- Database backups and restore test; migration rollback plan.
- Rate limits for auth, AI generation, chat and search.
- CORS allowlist; no wildcard in production.
- Request/prompt size limits and connection pooling.
- PII-safe logs; never log API keys or raw secrets.
- Worker retries/dead-letter visibility; health/readiness endpoints.
- CI tests and eval gate pass before deployment.
