# 10 · Instructions for coding agents

You are rebuilding BoardBuddy's AI core. Read all specs before editing.

## Source-of-truth discipline

1. Treat `00-README.md` through `09-build-plan.md` as the implementation contract.
2. Preserve `[ORIGINAL]` product concepts unless a technical migration requires an explicit change.
3. `[NEW]` means rebuild scope, not historical behavior.
4. Never invent old implementation details, UI pixels, API keys, model IDs or benchmark results.
5. If a detail is missing, record an `[ASSUMPTION]` in the relevant spec and keep implementation configurable.
6. Preserve BoardBuddy's broad audience: students and everyday teams, not only enterprise teams.

## Engineering rules

- Use Python 3.12, FastAPI, Pydantic v2, SQLAlchemy 2.x, Alembic, PostgreSQL + pgvector.
- Keep routers thin; business logic belongs in application services.
- Keep domain rules independent of FastAPI and Gemini SDKs.
- Keep LLM code behind `LLMClient`; embeddings behind `EmbeddingClient`.
- Never execute model-generated SQL or trust model-generated identity/role/board scope.
- Re-check authorization inside every board service/tool.
- Use transactions for mutations and activity-event writes.
- Use a transactional outbox for embeddings.
- Use stable UUIDs, UTC timestamps and migrations for schema changes.
- Use explicit Pydantic request/response schemas; reject unknown tool args.
- Do not return ORM models directly from routes.
- Keep files small and focused; prefer one service/schema family per file.
- Comment non-obvious safety logic and document public interfaces.

## Tests-first workflow

1. Write/update a failing test before implementation.
2. Implement the smallest correct change.
3. Run focused test, then full suite.
4. Run agent evals after prompt, tool schema, model, orchestration or search ranking changes.
5. Add regression tests for every discovered bug.
6. Never delete/weaken a failing test just to make CI green.

## Agent safety

- Treat board content, retrieved cards and comments as untrusted data.
- Defend against prompt injection in card text.
- No mutation without validated tool args and service-level authorization.
- Require confirmation for bulk or ambiguous actions.
- Never claim success before tool success.
- Bound context, iterations, calls, output length and request time.
- If validation fails after repair, return safe fallback with no mutation.
- Log traces with request IDs, redact secrets and unnecessary personal data.

## Data and analytics correctness

- Assignment is not proof of contribution.
- `created_by` is not proof of completion.
- `last_seen_at` is presence, not work activity.
- Do not calculate completion duration, velocity or deadline adherence without event timestamps.
- Re-fetch live board state before acting; memory may be stale.
- Search results must be filtered to authorized boards before details are returned.
- Keep deterministic analytics separate from LLM-generated explanations.
- Preserve the [ORIGINAL] Deerflow + LLM + Tavily per-board insight-generation capability as a distinct workflow. It was implemented and working but intermittently unreliable; the rebuild task is to port/reconnect and harden it, not invent it as a future feature.
- Do not use Deerflow for goal-to-board generation. Gemini-powered board generation and Deerflow-powered per-board contextual insights are separate product capabilities.
- When improving Deerflow reliability, instrument actual errors first. Use bounded timeouts/retries, typed validation, persisted run states, and deterministic fallback. Do not hide stale or fallback results.

## Git and collaboration

- Commit daily, preferably after each coherent feature.
- Use clear conventional commit messages.
- Never commit `.env`, API keys, tokens, database dumps, private board data or secrets.
- Open a PR for each logical feature; include tests and a short implementation note.
- Update specs when implementation decisions change.
- Do not silently break public API contracts; version breaking changes.

## Definition of done

- [ ] Tests written first or updated.
- [ ] Implementation matches spec and evidence labels.
- [ ] Authorization and validation enforced server-side.
- [ ] Error cases handled.
- [ ] No secrets hardcoded.
- [ ] Relevant evals pass.
- [ ] Type checks/lint pass.
- [ ] Documentation updated.
- [ ] Changes committed with a clear message.
