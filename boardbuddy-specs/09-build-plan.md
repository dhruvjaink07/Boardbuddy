# 09 · Four-day build plan

## Execution rule

**[NEW]** Each checkbox should leave the repository runnable and testable. Keep scope narrow: one board-scoped agent, one provider adapter, one embedding model and a thin API. Do not rebuild the full Flutter client in this sprint.

## Day 1 · Foundation and deterministic board API

- [ ] Create public repo, license, `.gitignore`, README, `.env.example`.
- [ ] Set up Python 3.12, FastAPI, Pydantic v2, SQLAlchemy, Alembic and pytest.
- [ ] Add Dockerfile and Compose with PostgreSQL + pgvector.
- [ ] Add `/health` and OpenAPI docs.
- [ ] Migrate users, boards, members, columns, cards and activity events.
- [ ] Implement auth dependency, password hashing and token issuance.
- [ ] Implement board create/list/read.
- [ ] Implement column/card create/list/update/move.
- [ ] Enforce owner/editor/viewer rules in services.
- [ ] Write tests for card transitions and permission rules.
- [ ] Verify clean checkout → Compose up → tests.
- [ ] Commit: `day-1: api foundation and board CRUD`.

**Runnable checkpoint:** authenticate and create a board with columns/cards using curl or Swagger.

## Day 2 · Agent and goal-to-board

- [ ] Define provider-neutral `LLMClient` and normalized response types.
- [ ] Implement Gemini adapter in `app/llm/gemini.py`.
- [ ] Add Pydantic schemas for board plans and each tool's arguments.
- [ ] Implement `create_card`, `move_card`, `update_card`, `list_board`, `search_cards` (keyword-only fallback is acceptable initially).
- [ ] Inject user/board context server-side; never accept identity from model.
- [ ] Implement bounded loop, tool trace, timeout and confirmation policy.
- [ ] Implement goal-to-board preview and commit endpoints.
- [ ] Implement one repair attempt and safe fallback.
- [ ] Persist conversations/messages and rolling summary.
- [ ] Test invalid args, unknown tool, prompt injection, unauthorized board, timeout and invalid JSON.
- [ ] Smoke-test through Swagger; commit `day-2: goal planning and safe tool agent`.

**Runnable checkpoint:** generate/preview/commit a board plan and ask agent to inspect/move/update cards safely.

## Day 3 · Search and board intelligence

- [ ] Add `card_embeddings` and embedding outbox migrations.
- [ ] Define provider-neutral `EmbeddingClient`.
- [ ] Implement embedding adapter after verifying model ID/dimension.
- [ ] Implement idempotent worker and canonical card text/hash.
- [ ] Implement PostgreSQL full-text keyword search.
- [ ] Implement pgvector retrieval with permission filtering.
- [ ] Add RRF hybrid fusion and `/search/cards`.
- [ ] Implement deterministic prioritisation with transparent factors.
- [ ] Implement standup endpoint from activity events/current state.
- [ ] Add relevance fixtures and standup factuality tests.
- [ ] Verify edit refreshes embedding and deleted cards disappear.
- [ ] Commit `day-3: hybrid search and board intelligence`.

**Runnable checkpoint:** hybrid search works and standup facts are grounded in persisted events.

## Day 4 · Evals, hardening and public release

- [ ] Add 30 eval prompts and deterministic fixture boards.
- [ ] Add LLM-as-judge as supplementary evaluator.
- [ ] Store eval JSON artifacts and prompt/schema version metadata.
- [ ] Add CI for lint, type checks, unit/integration tests and eval gate.
- [ ] Add structured logs, request IDs, rate limits and safe error responses.
- [ ] Add idempotency for board-plan commit and mutation confirmation.
- [ ] Port/reconnect the existing [ORIGINAL] per-board Deerflow + LLM + Tavily insight workflow behind a `BoardInsightProvider` interface.
- [ ] Add timeouts, bounded retries, typed output validation, persisted run status, and a clearly labelled deterministic analytics-only fallback.
- [ ] Add mocked integration tests for provider timeout, malformed output, empty research results and partial failure.
- [ ] Keep Deerflow insight generation separate from Gemini goal-to-board generation.
- [ ] Document setup, architecture, API examples and known limitations.
- [ ] Add contribution guide, security policy and issue templates.
- [ ] Test fresh clone → env → Compose → migration → tests.
- [ ] Scan Git history for secrets and private board data.
- [ ] Tag `v0.1.0`; commit `day-4: eval gate, docs and release hardening`.

**Runnable checkpoint:** a new contributor can run the API locally, trigger a per-board insight run, receive a validated report or clearly labelled fallback, and CI blocks unsafe/regressed agent and insight changes.

## Scope guardrails

- [ ] Do not implement full Flutter client in this sprint.
- [ ] Do not add autonomous deletion.
- [ ] Do not claim contribution analytics from assignee counts alone.
- [ ] Do not claim velocity/deadline adherence without event timestamps.
- [ ] Do not let LLM handle authorization, SQL or final state.
