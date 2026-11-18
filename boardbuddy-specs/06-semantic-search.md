# 06 · Semantic search

## Goal

**[NEW]** Support natural-language retrieval such as “find the thing about onboarding” when the query does not repeat the card title. Search must always be permission-filtered; similarity is not authorization.

## Embedding pipeline

1. On card create/update, create canonical text from title, description, labels, category, column title and optionally checklist titles.
2. Normalize whitespace and duplicate fields; compute `source_hash`.
3. If the hash differs from stored embedding, write an outbox event in the same transaction as the card mutation.
4. Worker loads current card content, calls `EmbeddingClient`, then upserts `card_embeddings` with vector, model ID, hash, timestamp and tsvector.
5. Before write, compare current hash again. Discard stale embeddings if card changed during generation and enqueue latest content.
6. On soft delete, remove/deactivate the vector row.
7. Search can return keyword-only results while embeddings are pending.

**[ASSUMPTION]** Start with 768 dimensions, but verify selected model output dimension and API support before creating the migration. Keep `EmbeddingClient` provider-neutral.

## Hybrid retrieval

- Vector candidates: pgvector cosine distance (`<=>`).
- Keyword candidates: PostgreSQL full-text search (`ts_rank_cd`).
- Optional filters: board, column, status, assignee, labels.
- Candidate generation: up to 30 from each retrieval path.
- Fusion: Reciprocal Rank Fusion (RRF), initial `k=60`.

\[
RRF(d)=\sum_{r\in\{vector,keyword\}}\frac{1}{k+rank_r(d)}
\]

MVP uses RRF only. Later reranker may reorder top candidates but cannot add IDs or bypass permissions.

## Example SQL shape

```sql
WITH vector_hits AS (
  SELECT card_id, row_number() OVER (ORDER BY embedding <=> :query_vec) AS rank
  FROM card_embeddings
  WHERE (:board_id IS NULL OR board_id=:board_id)
  ORDER BY embedding <=> :query_vec LIMIT 30
), keyword_hits AS (
  SELECT card_id, row_number() OVER (
    ORDER BY ts_rank_cd(search_document, websearch_to_tsquery('english', :q)) DESC
  ) AS rank
  FROM card_embeddings
  WHERE search_document @@ websearch_to_tsquery('english', :q)
    AND (:board_id IS NULL OR board_id=:board_id)
  LIMIT 30
), fused AS (
  SELECT card_id, sum(1.0/(60+rank)) AS score FROM (
    SELECT card_id,rank FROM vector_hits UNION ALL
    SELECT card_id,rank FROM keyword_hits
  ) hits GROUP BY card_id
)
SELECT c.id,c.board_id,c.title,c.description,fused.score
FROM fused JOIN cards c ON c.id=fused.card_id
JOIN board_members bm ON bm.board_id=c.board_id
WHERE bm.user_id=:user_id AND c.deleted_at IS NULL
ORDER BY fused.score DESC LIMIT :limit;
```

In production, pre-filter to boards the user can access and apply authorization before returning any card details. Use parameterized queries only.

## Reranking

**[NEW]** MVP: RRF. Later optional cross-encoder/LLM reranking may reorder authorized candidates. Reranker returns only candidate IDs and scores. If it times out or returns invalid IDs, fall back to RRF. Do not let reranker fabricate card snippets or content.

## Freshness and recovery

- Transactional outbox ensures card change and embedding job are committed together.
- Worker retries transient errors with exponential backoff and jitter.
- Upsert is idempotent by `card_id`.
- Rebuild command re-embeds all active cards for one board or whole deployment.
- Track queue depth, oldest pending age, success/failure rate, embedding latency, percentage of cards with current vectors, search p50/p95.

## Security and privacy

- Never expose vectors, hashes or embedding provider metadata in ordinary card DTOs.
- Disclose external processing of private card text in privacy policy.
- Filter vector and keyword retrieval by authorized boards.
- Treat retrieved card content as untrusted if passed to an LLM.
