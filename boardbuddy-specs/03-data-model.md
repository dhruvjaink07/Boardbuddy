# 03 · Data model

## Conventions

**[NEW]** PostgreSQL is the system of record. Use UUID primary keys, UTC `timestamptz`, SQLAlchemy 2.x, Alembic and JSONB only for genuinely flexible metadata. Historical concepts include users, boards, columns, cards, assignees, labels, due dates, checklist/subtasks, attachments, comments, invitations and insights **[ORIGINAL]**.

## Tables

### `users`

`id uuid PK`, `email citext UNIQUE NOT NULL`, `password_hash text NULL`, `display_name text NULL`, `photo_url text NULL`, `created_at timestamptz`, `last_seen_at timestamptz NULL`.

`display_name`, `photo_url`, `created_at`, `last_seen_at` are **[ORIGINAL]** fields/concepts. Password hash and citext normalization are **[NEW]** for this auth implementation.

### `boards`

`id uuid PK`, `name varchar(160) NOT NULL`, `description text`, `theme jsonb`, `owner_id uuid FK users`, `created_at timestamptz`, `updated_at timestamptz`, `archived_at timestamptz NULL`.

Name, description, theme, owner and timestamps are **[ORIGINAL]**. Soft archive is **[NEW]**.

### `board_members`

`board_id uuid FK boards`, `user_id uuid FK users`, `role text CHECK role IN ('owner','editor','viewer')`, `joined_at timestamptz`, composite PK `(board_id,user_id)`.

Board membership and roles are **[ORIGINAL]** concepts. This normalized join table and role set are **[ASSUMPTION]** for the rebuild. Owner must have owner role.

### `board_invitations`

`id uuid PK`, `board_id uuid FK boards`, `invited_email citext NOT NULL`, `invited_user_id uuid FK users NULL`, `invited_by uuid FK users`, `role text`, `status text CHECK status IN ('pending','accepted','declined','expired','revoked')`, `expires_at timestamptz`, `created_at timestamptz`, `accepted_at timestamptz NULL`.

Invitation, email, inviter, role, status and expiry are **[ORIGINAL]** concepts. Canonical email normalization, invited UID, extra statuses and acceptance timestamp are **[NEW]**. Historical implementation had inconsistent invitedEmail/UID handling; normalize email and store UID separately.

### `board_columns`

`id uuid PK`, `board_id uuid FK boards`, `title varchar(100)`, `position integer`, `created_at timestamptz`, `updated_at timestamptz`.

Column ID/title/order/creation are **[ORIGINAL]**. Updated timestamp is **[NEW]**. Unique `(board_id, position)`; handle reorder in a transaction.

### `cards`

`id uuid PK`, `board_id uuid FK boards`, `column_id uuid FK board_columns`, `title varchar(240)`, `description text`, `status text CHECK status IN ('todo','in_progress','done')`, `priority text CHECK priority IN ('low','medium','high','urgent')`, `category text NULL`, `progress smallint CHECK progress BETWEEN 0 AND 100`, `assignee_ids uuid[]`, `labels text[]`, `due_at timestamptz NULL`, `estimate_minutes integer NULL`, `position integer`, `created_by uuid FK users`, `created_at timestamptz`, `updated_at timestamptz`, `completed_at timestamptz NULL`, `deleted_at timestamptz NULL`.

Most task fields are **[ORIGINAL]**. `board_id` is a deliberate **[NEW]** denormalization for board-scoped queries and vector filtering. It was not present in the earlier `TaskCard` model/schema, so do not treat it as recovered. `estimate_minutes`, `position`, `completed_at` and soft delete are **[NEW]**. Historical `TaskCard` had assignee, assignees, progress, labels, tags, dueDate, checklist/subtasks, attachments, createdBy/createdAt/lastUpdated.

### `card_checklist_items`

`id uuid PK`, `card_id uuid FK cards`, `title text`, `is_completed boolean`, `position integer`, `created_at timestamptz`, `completed_at timestamptz NULL`.

Checklist/subtasks are **[ORIGINAL]**. Separate stable IDs and completion timestamps are **[NEW]**. Do not recreate legacy subtasks with blank IDs or synthetic `createdAt=now` when computing analytics.

### `card_attachments` and `card_comments`

Attachments: `id uuid PK`, `card_id uuid FK cards`, `uploaded_by uuid FK users`, `file_name text`, `content_type text`, `size_bytes bigint`, `storage_key text`, `url text`, `created_at timestamptz`.

Comments: `id uuid PK`, `card_id uuid FK cards`, `user_id uuid FK users`, `body text`, `created_at timestamptz`, `updated_at timestamptz NULL`.

Attachments/comments are **[ORIGINAL]** product/model concepts and visible in task detail designs. Normalized tables and storage key are **[NEW]**. Store files in object storage, not PostgreSQL.

### `conversations` and `messages`

`conversations`: `id uuid PK`, `user_id uuid FK users`, `board_id uuid FK boards NULL`, `title text NULL`, `summary text NULL`, `summary_through_message_id uuid NULL`, `created_at timestamptz`, `updated_at timestamptz`.

`messages`: `id uuid PK`, `conversation_id uuid FK conversations`, `role text CHECK role IN ('system','user','assistant','tool')`, `content text`, `structured_content jsonb NULL`, `tool_name text NULL`, `tool_call_id text NULL`, `token_count integer NULL`, `created_at timestamptz`.

Both are **[NEW]** for persistent multi-turn agent memory.

### `card_embeddings`

`card_id uuid PK/FK cards`, `board_id uuid FK boards`, `embedding vector(768)`, `embedding_model text`, `source_hash text`, `embedded_at timestamptz`, `search_document tsvector`.

All are **[NEW]**. **[ASSUMPTION]** 768 dimensions; verify actual embedding model dimensions before migration. Keep model name and hash to support provider changes and freshness checks.

### `activity_events` and `embedding_outbox`

`activity_events`: `id uuid PK`, `board_id uuid FK boards`, `card_id uuid FK cards NULL`, `actor_id uuid FK users`, `event_type text`, `payload jsonb`, `created_at timestamptz`.

`embedding_outbox`: `id uuid PK`, `card_id uuid FK cards`, `event_type text`, `source_hash text`, `attempts integer`, `available_at timestamptz`, `processed_at timestamptz NULL`, `last_error text NULL`, `created_at timestamptz`.

Both are **[NEW]**. Event history is necessary for trustworthy completion trends, standups and auditability. `created_by`, `lastUpdated` and `last_seen` alone cannot reconstruct velocity or actual contribution.

## Indexes

```sql
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS citext;
CREATE INDEX ix_board_members_user ON board_members(user_id, board_id);
CREATE INDEX ix_columns_board_position ON board_columns(board_id, position);
CREATE INDEX ix_cards_board_column_position ON cards(board_id, column_id, position) WHERE deleted_at IS NULL;
CREATE INDEX ix_cards_board_status ON cards(board_id, status) WHERE deleted_at IS NULL;
CREATE INDEX ix_cards_due ON cards(due_at) WHERE due_at IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX ix_cards_assignees ON cards USING GIN(assignee_ids);
CREATE INDEX ix_cards_labels ON cards USING GIN(labels);
CREATE INDEX ix_invites_email_status_expiry ON board_invitations(invited_email, status, expires_at);
CREATE INDEX ix_messages_conversation_time ON messages(conversation_id, created_at);
CREATE INDEX ix_activity_board_time ON activity_events(board_id, created_at DESC);
CREATE INDEX ix_embedding_board ON card_embeddings(board_id);
CREATE INDEX ix_embedding_fts ON card_embeddings USING GIN(search_document);
CREATE INDEX ix_embedding_hnsw ON card_embeddings USING hnsw (embedding vector_cosine_ops);
```

## Example queries

Cards in board order:
```sql
SELECT c.* FROM cards c JOIN board_columns col ON col.id=c.column_id
WHERE c.board_id=:board_id AND c.deleted_at IS NULL
ORDER BY col.position,c.position;
```

Boards visible to user:
```sql
SELECT b.* FROM boards b JOIN board_members bm ON bm.board_id=b.id
WHERE bm.user_id=:user_id AND b.archived_at IS NULL ORDER BY b.updated_at DESC;
```

Semantic candidates (permission filter required before return):
```sql
SELECT c.id,c.title,c.description,1-(e.embedding <=> :query_vec) AS similarity
FROM card_embeddings e JOIN cards c ON c.id=e.card_id
JOIN board_members bm ON bm.board_id=c.board_id
WHERE bm.user_id=:user_id AND (:board_id IS NULL OR c.board_id=:board_id)
AND c.deleted_at IS NULL ORDER BY e.embedding <=> :query_vec LIMIT :limit;
```

Overdue open cards:
```sql
SELECT id,title,priority,due_at,assignee_ids FROM cards
WHERE board_id=:board_id AND status<>'done' AND due_at<now()
AND deleted_at IS NULL ORDER BY due_at ASC;
```

## Integrity rules

- A card's `column_id` must belong to its `board_id`; enforce in service and preferably composite FK constraints.
- Every assignee must be an active member of that board.
- Only owner/editor may mutate; viewer is read-only.
- Move updates column, status and position atomically.
- Set `completed_at` on transition to done; clear it when reopened.
- Mutation and activity event are written in one transaction; card change and embedding outbox event are also transactional.
- Never expose password hashes, provider tokens or raw embedding vectors in API DTOs.
