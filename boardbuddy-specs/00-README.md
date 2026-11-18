# BoardBuddy AI Core Rebuild

> Implementation specification for rebuilding BoardBuddy as a public, API-first project.

## Evidence labels

- **[ORIGINAL]** Recovered from retained BoardBuddy discussions and the available design exports. Historical product direction or visible UI.
- **[NEW]** Requested for this rebuild or an implementation improvement not established as historical behavior.
- **[ASSUMPTION]** A practical choice where the retained context does not establish a definitive decision.
- **[VERIFY]** Confirm against original source code or higher-resolution design files before claiming exact parity.

## What BoardBuddy is

**[ORIGINAL]** BoardBuddy is a mobile-first Kanban project-management app. It helps people plan and manage tasks, collaborate, and understand progress. Students are a primary audience, but the product is meant for mentors, freelancers, startups, small teams, professionals, and industrial teams too. Project management is framed as an everyday skill: everyone manages goals, deadlines, responsibilities, and collaborative work.

**[ORIGINAL]** The product direction combines approachable task organization with project intelligence: analytics, insights, and AI assistance should make work easier to understand, not make the basic board harder to use.

**[NEW]** This rebuild provides a Python 3.12 backend with FastAPI, PostgreSQL + pgvector, Pydantic, Docker, and a provider-neutral LLM interface initially backed by Gemini. Flutter is an optional thin client.

## Original UI recovered from available designs

- **[ORIGINAL] Home / board overview:** dark background, greeting header (“Hey Dhruv”), settings affordance, “Your boards await!” subheading, All Boards / Recent / Favorites filters, a two-column grid of board cards, colored top accent strips, progress/task summaries, member avatars, and a prominent floating orange create button.
- **[ORIGINAL] Board cards:** sample boards include Work, Personal Tasks, Trip to Norway, UI Revamp, Groceries and other project boards. Cards use distinct accent colors and may show progress, last-updated time, member avatars, or a favorite/completion affordance.
- **[ORIGINAL] Kanban board:** dark UI with board title, columns such as To Do / In Progress / Done, task cards with title, short description, priority chips, labels, due dates, progress/checklist indicators, assignee avatars, and add-task controls.
- **[ORIGINAL] AI Assistant surface:** a prompt such as “What would you like to do?”, quick filters/chips including All, Personal, Work and Shopping, board-style choices including Classic, Orbit and Fluid, and a “Magic Sort” action. The designs show an AI assistant integrated into the board workflow, not a replacement for it.
- **[ORIGINAL] Task details:** editable task title/description, priority and category chips, due date, assignee, progress, subtasks/checklist, attachments, comments, a comment composer, and a Save Changes action.
- **[ORIGINAL] Authentication/onboarding:** BoardBuddy branding, login/sign-up, email/password, Google sign-in option, password recovery, and an onboarding proposition around planning smarter/together.
- **[ORIGINAL] Visual language:** black/dark surfaces, orange as the main action/accent color, rounded cards and controls, restrained glow/highlight treatments, and colored board accents. The design exports also show purple, green, blue and other colors as board-specific accents.

## Original vs rebuild feature table

| Feature | Evidence | Notes |
|---|---|---|
| Mobile-first Kanban project management | [ORIGINAL] | Main product concept |
| Home overview distinct from Boards and Board View | [ORIGINAL] | Home shows board cards and filters |
| Board cards with color, progress, recency and members | [ORIGINAL] | Visible in UI exports |
| Kanban columns and task cards | [ORIGINAL] | To Do / In Progress / Done shown |
| Task details, priority, category, due date, assignees | [ORIGINAL] | Visible in task-detail designs/models |
| Subtasks/checklist, attachments, comments | [ORIGINAL] | Visible in designs and earlier model definitions; historical implementation status was partial |
| AI Assistant prompt surface and Magic Sort | [ORIGINAL] | Visible in board UI design |
| Theme choices Classic / Orbit / Fluid | [ORIGINAL] | Visible in AI/board design |
| Firebase Auth + Cloud Firestore | [ORIGINAL] | Historical backend, replaced in this rebuild |
| Hive/local cache and offline fallback | [ORIGINAL] | Historical client-side direction |
| GetX navigation/state management | [ORIGINAL] | Retained code status; verify current client branch |
| Gemini natural-language board generation | [ORIGINAL] | Prior `AIBoardService` generated JSON board/columns/tasks |
| Profile-wide analytics across boards + board drill-down | [ORIGINAL] | Product vision; metrics need event history to be reliable |
| Dart-isolate deterministic analytics | [ORIGINAL] | Historical intended client-side compute design |
| Deerflow + LLM + Tavily contextual insights per board | [ORIGINAL] | Implemented and working for board-level insight generation; reliability was intermittent and needs polishing. Not used for board generation. |
| PDF reports | [ORIGINAL] | PDF generation code existed; Android save UX was incomplete |
| Goal-to-board from one messy sentence | [NEW] | Structured columns/cards/priorities/estimates |
| Multi-step tool-calling agent with cross-turn memory | [NEW] | Explicitly requested for rebuild |
| Semantic/hybrid card search | [NEW] | PostgreSQL full-text + pgvector |
| Smart prioritisation and daily standup summaries | [NEW] | Grounded in persisted board/activity data |
| Pydantic-validated structured outputs and safe fallback | [NEW] | Strict runtime contract |
| Eval suite gating prompt changes | [NEW] | 25+ test prompts; this spec defines 30 |
| Python/FastAPI/Postgres/pgvector/Docker backend | [NEW] | Rebuild stack |
| Swappable LLM/embedding provider interfaces | [NEW] | Provider-neutral application core |

## Architecture and product principles

1. **[ORIGINAL] Project management is for everyone.** Avoid enterprise-only language in onboarding and marketing.
2. **[ORIGINAL] Kanban is the center.** AI should assist the board, not bury it under chat.
3. **[ORIGINAL] Keep Home, board list, board view, and task details distinct.**
4. **[ORIGINAL] Preserve the black + orange visual identity**, with board-specific accent colors.
5. **[NEW] Deterministic core first.** Authorization, state transitions, analytics calculations and validation must not depend on model correctness.
6. **[NEW] The model proposes; application services validate and execute.** Never permit model-generated SQL or direct database access.
7. **[NEW] Explainability.** Every recommendation should expose the factors/data behind it.
8. **[NEW] Provider independence.** Domain/application code must not import Gemini SDK types.

## Assumptions

- **[ASSUMPTION]** Rebuild as a modular monolith: one FastAPI service, PostgreSQL, and a separate background worker for embeddings.
- **[ASSUMPTION]** A board has one owner and multiple members with `owner`, `editor`, `viewer` roles.
- **[ASSUMPTION]** A card belongs to one column; columns are ordered within a board.
- **[ASSUMPTION]** Estimates are stored in minutes and formatted by the client.
- **[ASSUMPTION]** Agent conversations are user-owned and optionally board-scoped. Board access is rechecked on every request.
- **[ASSUMPTION]** The selected embedding model initially returns 768 dimensions. Verify the exact provider model and dimension before migration.
- **[ASSUMPTION]** New AI board generation returns a preview; persistence requires a separate explicit commit.
- **[VERIFY]** Exact font family, sizes, spacing, radii, icon pack, transition animations and responsive breakpoints are not legible in all exports. Use the designs as visual reference and inspect original editable files for pixel-level values.

## Rebuild requirement: existing per-board insight generation

- **[ORIGINAL]** Deerflow + LLM + Tavily was already implemented and working for insight generation on individual boards. It was separate from Gemini-powered goal-to-board generation. The insight flow could fail intermittently.
- **[NEW]** Preserve/port this capability into the Python backend and polish reliability. Add instrumentation before diagnosing intermittent failures; use bounded retries, timeouts, typed validation, persisted run status, and a clearly labelled deterministic fallback.

## Non-goals for the first backend release

- **[NEW]** Rebuilding the full Flutter UI in this four-day backend sprint.
- **[NEW]** Real-time collaborative cursors/presence, billing, SSO, multi-region infrastructure.
- **[NEW]** Autonomous destructive actions or bulk mutations without confirmation.
- **[NEW]** Predictive productivity claims unsupported by event history.

## Definition of done

A first public release is ready when users can authenticate, create/manage boards and cards, generate a structured board plan, use a bounded permission-aware agent with the five tools, continue conversations with persisted memory, search authorized cards semantically, receive grounded prioritisation/standup output, run the stack through Docker Compose, and pass unit/integration/eval gates in CI. No secrets may be committed.
