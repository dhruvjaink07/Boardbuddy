# 04 · REST API contract

## Conventions

**[NEW]** Base path `/api/v1`, JSON bodies, UUID strings, UTC ISO-8601 timestamps, bearer access tokens. Every board endpoint checks membership/role server-side. Mutations should support `Idempotency-Key` where retries could duplicate effects.

Error shape:
```json
{"error":{"code":"permission_denied","message":"You cannot edit this board.","request_id":"req_..."}}
```

Pagination: `limit` default 25, max 100, opaque `cursor`.

## Auth and profile

`POST /auth/register`
```json
{"email":"sam@example.com","password":"strong-password","display_name":"Sam"}
```
`201`:
```json
{"user":{"id":"uuid","email":"sam@example.com","display_name":"Sam"},"access_token":"...","token_type":"bearer","expires_in":3600}
```

`POST /auth/login` accepts email/password and returns the same shape. `GET /users/me` returns `{id,email,display_name,photo_url,created_at}`. OAuth/Google sign-in is **[ORIGINAL]** in the design direction; provider setup is **[ASSUMPTION]** and can be added without changing board APIs.

## Boards

- `GET /boards?filter=all|recent|favorites&limit=&cursor=`: returns visible boards with `id,name,description,theme,role,progress,task_count,updated_at,members_preview,is_favorite`.
- `POST /boards`: create board and optional initial columns.
- `GET /boards/{board_id}`: board metadata, role and ordered columns; do not return every card by default.
- `PATCH /boards/{board_id}`: update name/description/theme/favorite.
- `DELETE /boards/{board_id}`: owner-only soft archive, `204`.

Create request:
```json
{"name":"Capstone Project","description":"Build the app","theme":{"accent":"orange"},"initial_columns":["To Do","In Progress","Done"]}
```
Response `201`:
```json
{"id":"uuid","name":"Capstone Project","description":"Build the app","owner_id":"uuid","columns":[{"id":"uuid","title":"To Do","position":0},{"id":"uuid","title":"In Progress","position":1},{"id":"uuid","title":"Done","position":2}]}
```

## Columns

- `POST /boards/{board_id}/columns` body `{ "title":"Review", "position":2 }`
- `PATCH /boards/{board_id}/columns/{column_id}` body `{ "title":"Ready for QA" }`
- `POST /boards/{board_id}/columns/reorder` body `{ "ordered_column_ids":["uuid-1","uuid-2"] }`
- `DELETE /boards/{board_id}/columns/{column_id}`. Non-empty column deletion requires `move_cards_to_column_id` or explicit archive policy; never silently discard cards.

## Cards

- `GET /boards/{board_id}/cards?column_id=&status=&assignee_id=&priority=&q=&limit=&cursor=`
- `POST /boards/{board_id}/cards`
- `GET /cards/{card_id}`
- `PATCH /cards/{card_id}`
- `POST /cards/{card_id}/move`
- `DELETE /cards/{card_id}` (soft delete, `204`)

Create request:
```json
{"column_id":"uuid","title":"Implement login","description":"Add auth flow","priority":"high","assignee_ids":[],"labels":["backend"],"due_at":null,"estimate_minutes":180}
```
Card response:
```json
{"id":"uuid","board_id":"uuid","column_id":"uuid","title":"Implement login","description":"Add auth flow","status":"todo","priority":"high","assignee_ids":[],"labels":["backend"],"due_at":null,"estimate_minutes":180,"progress":0,"position":0,"created_at":"2026-01-01T10:00:00Z","updated_at":"2026-01-01T10:00:00Z"}
```

Patch body changes only supplied fields; explicit `null` clears nullable fields. Move request `{ "target_column_id":"uuid", "position":1 }`; response `{ "card_id":"uuid", "column_id":"uuid", "status":"in_progress", "position":1, "updated_at":"..." }`.

## Task detail children

- `POST /cards/{card_id}/checklist-items`, `PATCH /checklist-items/{item_id}`, `DELETE /checklist-items/{item_id}`
- `POST /cards/{card_id}/comments`, `GET /cards/{card_id}/comments`
- `POST /cards/{card_id}/attachments/presign`, `POST /cards/{card_id}/attachments/complete`, `DELETE /attachments/{attachment_id}`

Attachment bytes go to object storage. API stores metadata and validates ownership/content type/size.

## Invitations and members

- `POST /boards/{board_id}/invitations` body `{ "email":"teammate@example.com", "role":"editor" }`
- `GET /boards/{board_id}/invitations`
- `POST /invitations/{invitation_id}/accept`
- `POST /invitations/{invitation_id}/decline`
- `DELETE /boards/{board_id}/members/{user_id}`

## Goal-to-board

`POST /ai/boards/plan`:
```json
{"prompt":"Launch a campus event registration app in three weeks. Split design, backend, testing and launch work.","preferences":{"column_count":"auto","include_estimates":true,"timezone":"Asia/Kolkata"}}
```
Response:
```json
{"plan_id":"uuid","board":{"name":"Campus Event Registration App","description":"Three-week launch plan"},"columns":[{"title":"Backlog","position":0},{"title":"In Progress","position":1},{"title":"Review","position":2},{"title":"Done","position":3}],"cards":[{"temporary_id":"tmp-1","column_title":"Backlog","title":"Define registration flow","description":"Map attendee registration and confirmation","priority":"high","estimate_minutes":180,"labels":["planning"],"due_at":null}],"assumptions":["No fixed launch date was supplied."],"warnings":[],"requires_confirmation":true}
```
`POST /ai/boards/commit` body `{ "plan_id":"uuid", "selected_card_ids":["tmp-1"], "confirm":true }`; idempotent per plan ID; returns persisted board/columns/cards.

## Assistant

`POST /boards/{board_id}/assistant/messages`:
```json
{"conversation_id":null,"message":"Find onboarding tasks and move the documentation one to Review.","confirm_actions":false}
```
Response:
```json
{"conversation_id":"uuid","message_id":"uuid","answer":"I found two onboarding-related cards. I can move the documentation card to Review.","actions":[{"tool":"list_board","status":"completed","summary":"Read board columns and cards"},{"tool":"search_cards","status":"completed","summary":"Found two matches"},{"tool":"move_card","status":"awaiting_confirmation","arguments":{"card_id":"uuid","target_column_id":"uuid","position":0}}],"requires_confirmation":true,"trace_id":"uuid"}
```
`POST /assistant/actions/{action_id}/confirm` body `{ "confirm":true }`; returns `{ "status":"completed", "result":{...} }`. `GET /conversations/{conversation_id}/messages` returns paginated history; verify conversation owner and current board access.

## Search, analytics, standup

`POST /search/cards` body `{ "query":"the thing about onboarding", "board_id":"uuid", "mode":"hybrid", "limit":10 }`; response items include `card_id,board_id,title,snippet,score,matched_by`.

`GET /boards/{board_id}/analytics` returns deterministic board metrics and definitions. `GET /analytics/me` returns cross-board aggregate for boards visible to caller. `POST /boards/{board_id}/standup` body `{ "date":"2026-01-02", "timezone":"Asia/Kolkata" }`; response includes summary, completed_yesterday, today_focus, blockers, suggestions and data_limitations.

## Flutter client contract

**[NEW]** Flutter is a thin REST client: secure token storage, DTO parsing, typed loading/success/empty/error/offline states. Do not embed Gemini prompts, database logic or authoritative permissions in Flutter. Client role gating is UX only; server checks are authoritative. Keep API responses provider-neutral.
