# 01 · Product specification

## Product framing

**[ORIGINAL]** BoardBuddy is a mobile-first Kanban app for students and everyday teams. It helps people plan, collaborate and understand work. It should not be positioned as only an industrial or enterprise project-management tool.

**[ORIGINAL]** Visual direction: dark/black surfaces, orange primary action color, rounded cards and controls, subtle glow/highlight, and distinct accent colors per board. Main surfaces recovered from designs: onboarding/auth, Home board overview, Kanban board, AI Assistant prompt surface, task details, settings/profile affordance.

## Personas

| Persona | Need | Value |
|---|---|---|
| Student [ORIGINAL] | Manage assignments, projects, deadlines and teammates | Simple board and progress visibility |
| Mentor/faculty [ORIGINAL] | Understand progress and unblock work | Readable board overview and reports |
| Freelancer [ORIGINAL] | Track client work and personal delivery | Lightweight workflow and prioritisation |
| Small team/startup [ORIGINAL] | Coordinate responsibilities | Shared boards and workload visibility |
| Individual professional [ORIGINAL] | Manage goals and workstreams | Personal boards and cross-board overview |

## User stories

### Boards and tasks

- **[ORIGINAL]** As a user, I can create and browse boards, filter All Boards / Recent / Favorites, and open a board.
- **[ORIGINAL]** As a user, I can create, rename, theme and archive boards.
- **[ORIGINAL]** As a user, I can create columns and arrange tasks in a Kanban workflow.
- **[ORIGINAL]** As a user, I can create/edit/move tasks, set priority/category/labels, due date, assignees and progress.
- **[ORIGINAL]** As a user, I can manage subtasks/checklists, attachments and comments in task details.
- **[ORIGINAL]** As a user, I can drag and drop cards to reorder or move them.
- **[ORIGINAL]** As a user, I can use theme styles such as Classic, Orbit and Fluid (shown in design exports).

### Collaboration and insights

- **[ORIGINAL]** As an owner, I can invite collaborators and assign roles.
- **[ORIGINAL]** As a member, I can access boards shared with me.
- **[ORIGINAL]** As a user, I can see analytics across my boards and drill down into a board.
- **[ORIGINAL]** Intended analytics include task totals/status, completion, workload distribution, team contribution, trends, project health and bottlenecks. Do not infer actual contribution from assignee counts alone.
- **[ORIGINAL]** PDF reporting was part of the earlier project direction.

### AI assistant

- **[ORIGINAL]** The UI includes an AI Assistant prompt surface (“What would you like to do?”), contextual filters/chips, board style choices and a Magic Sort action.
- **[ORIGINAL]** A Gemini-backed service previously generated board/column/task JSON from a natural-language project prompt.
- **[NEW]** A user can turn one messy sentence into a board plan with columns, cards, priorities, estimates and assumptions.
- **[NEW]** A user can ask for multi-step actions over the active board; the assistant inspects state, plans, invokes tools and reports results.
- **[NEW]** A user can ask “find the thing about onboarding” and retrieve semantically related cards.
- **[NEW]** A user can request a daily standup or ranked “what should I work on today?” summary.
- **[NEW]** Conversation memory persists across turns but live board state is always re-fetched before mutation.
- **[NEW]** Bulk or ambiguous actions require confirmation.

## Screens and API responsibilities

| Screen | Evidence | Backend data/actions |
|---|---|---|
| Onboarding / Get Started | [ORIGINAL] | Public config; optional onboarding completion flag |
| Login / Sign up | [ORIGINAL] | Register, login, token refresh, Google OAuth integration if implemented |
| Home / board overview | [ORIGINAL] | Board cards, progress summary, last updated, member avatars, favorite/recent filters |
| Boards list | [ORIGINAL] | All/recent/favorites queries, create board |
| Board View | [ORIGINAL] | Ordered columns/cards, board metadata, move/reorder, AI Assistant entry point |
| AI Assistant surface | [ORIGINAL] UI; [NEW] expanded behavior | Prompt, quick filters/context, plan, tool actions, confirmation, Magic Sort |
| Task Details | [ORIGINAL] | Title/description, priority/category, due date, assignees, progress, checklist, attachments, comments, save |
| Members/invitations | [ORIGINAL] model/feature direction | Invite, role, accept/decline/revoke |
| Analytics | [ORIGINAL] | Profile aggregate and board drill-down |
| Reports/PDF | [ORIGINAL] | Report data and export endpoint; PDF generation can be client/server decision |
| Profile/settings | [ORIGINAL] | User profile and preferences |
| Search results | [NEW] | Hybrid search results and matched snippets |
| Standup panel | [NEW] | Completed events, current work, blockers, suggestions |
| Activity history | [NEW] | Audit/activity events |

## UI reconstruction rules

1. **[ORIGINAL]** Home should retain its greeting, settings affordance, board filters, two-column card grid, colored top bars, progress/recency/member hints, and floating orange create button as shown in the design export.
2. **[ORIGINAL]** Board View should remain dense but readable: horizontal Kanban columns, compact task cards, priority/label chips, due/progress indicators, avatars, and obvious add-task actions.
3. **[ORIGINAL]** Task Details should expose editable description, priority/category, due date, assignee, progress, subtasks, attachments, comments, and Save Changes.
4. **[ORIGINAL]** AI Assistant should feel integrated into board work. Preserve prompt entry, contextual chips, style choices and Magic Sort affordance where practical.
5. **[ORIGINAL]** Maintain dark theme and orange primary CTA. Board accents may use other colors.
6. **[NEW]** AI-generated boards must have a review/preview state before persistence.
7. **[NEW]** Keep AI chat from taking over the main Kanban surface.
8. **[NEW]** Provide explicit loading, empty, offline, error and permission-denied states.
9. **[VERIFY]** Match exact type scale, spacing, component heights, animation, iconography and safe-area details from editable source designs before claiming pixel-perfect parity.

## MVP acceptance criteria

- A user can create a board with ordered columns and cards.
- Card identity is stable across moves; card move updates column/status/order atomically.
- Server-side permissions apply to every normal API route and agent tool.
- Goal-to-board returns a validated preview and requires confirmation to save.
- Tool traces are returned to the client in a safe, human-readable form.
- Semantic search returns only cards from boards the caller can access.
- Standup summaries use event-backed facts and clearly disclose missing history.
- Client response contracts are provider-neutral and do not expose Gemini response objects.
