# BoardBuddy

> **Project management is for everyone.**  
> An AI-powered Kanban and project-management platform built with a high-performance Python FastAPI backend and a responsive Flutter BLoC client.

---

## 🌟 Key Features

- **Mobile-First Kanban Board**: Distinct Home Overview, customizable board vibes/themes, columns, task cards with priority badges, checklist subtasks, and progress indicators.
- **Gemini Goal-to-Board Planning**: Transforms unstructured project goals into structured Kanban workflows with auto-suggested columns, cards, estimates, and priorities, providing a preview before persistent commit.
- **Bounded AI Assistant**: 5-step bounded tool-calling agent (`create_card`, `move_card`, `update_card`, `list_board`, `search_cards`) enforcing server-side authorization and confirmation policies for consequential mutations.
- **Deerflow Contextual Board Insights**: Preserves original BoardBuddy per-board contextual intelligence, enriched with bounded retries, timeouts, and deterministic fallback when external research is unavailable.
- **Hybrid Semantic Search**: Combines pgvector cosine similarity and keyword matching using Reciprocal Rank Fusion (RRF, $k=60$) over transactional embedding outboxes.
- **Deterministic Standups & Priorities**: Generates daily standup summaries from audit activity events and transparently calculates multi-factor priority scores without fabricating contributions.
- **Responsive Flutter Client**: Mobile, Tablet, and Desktop responsive Flutter app engineered with the BLoC pattern, matching the product design specifications.

---

## 🏗️ Architecture

```
BoardBuddy/
├── app/
│   ├── api/             # Thin FastAPI v1 REST routers & error handlers
│   ├── core/            # Config, security (bcrypt & JWT), custom exceptions
│   ├── db/              # SQLAlchemy 2.x models (GUID, VectorType, audit logs)
│   ├── domain/          # Pure domain RBAC permissions (Owner, Editor, Viewer)
│   ├── llm/             # Provider-neutral LLM & embedding clients (Gemini & Mock)
│   ├── schemas/         # Pydantic v2 validated DTOs & tool argument contracts
│   ├── services/        # Application business logic (Card, Board, Column, Search, Agent)
│   └── workers/         # Asynchronous transactional outbox embedding poller
├── client/              # Flutter mobile/desktop app using BLoC state management
├── migrations/          # Alembic database migration versions
├── scripts/             # Regression evaluation runners & tools
└── tests/               # 75 passing unit, integration, and eval scenario tests
```

---

## 🚀 Quick Start

### 1. Run with Docker Compose

```bash
cp .env.example .env
docker compose up --build
```
The API is available at `http://localhost:8000` and Swagger documentation at `http://localhost:8000/docs`.

### 2. Run Backend Locally

```bash
# Set up virtual environment
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"

# Run database migrations
alembic upgrade head

# Start API server
uvicorn app.main:app --reload --port 8000
```

### 3. Run Flutter Client

```bash
cd client
flutter pub get
flutter run
```

---

## 🧪 Testing & Verification

The project includes 75 automated tests with 100% pass rate:
- **Unit Tests**: Security (bcrypt, JWT), RBAC permissions matrix, tool argument validation.
- **Integration Tests**: Auth API, Board CRUD, Column atomic reorder, Card lifecycle & atomic movement, RBAC enforcement, Hybrid search, Daily standup, Deerflow insights with fallback, Alembic migration sanity.
- **30 Regression Evaluation Scenarios**: Covering planning, boundary refusal, prompt injection resistance, state factuality, and conversation memory persistence.

```bash
# Run pytest test suite
pytest tests/

# Run standalone 30 evaluation scenarios runner
python scripts/run_evals.py

# Run Flutter tests
cd client && flutter test
```

---

## 📄 License & Specifications

All product decisions, UI directions, data models, and feature specifications are documented in the `boardbuddy-specs/` directory.
