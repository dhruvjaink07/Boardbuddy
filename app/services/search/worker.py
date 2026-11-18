from datetime import datetime, timezone
import hashlib
import logging
import re
from typing import List, Optional
import uuid
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.models.activity import EmbeddingOutbox
from app.db.models.card import Card
from app.db.models.column import BoardColumn
from app.db.models.search import CardEmbedding
from app.llm.embedding import EmbeddingClient, get_embedding_client

logger = logging.getLogger(__name__)


def canonicalize_card(card: Card, column_title: Optional[str] = None) -> str:
    """Produces normalized canonical text for embedding and full-text indexing."""
    parts: List[str] = [card.title]
    if card.description:
        parts.append(card.description)
    if column_title:
        parts.append(f"Column: {column_title}")
    if card.priority:
        parts.append(f"Priority: {card.priority}")
    if card.category:
        parts.append(f"Category: {card.category}")
    if card.labels:
        parts.append(f"Labels: {', '.join(card.labels)}")

    raw_text = " \n ".join(parts)
    # Normalize excessive whitespace
    clean_text = re.sub(r"\s+", " ", raw_text).strip()
    return clean_text


def compute_source_hash(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


class EmbeddingWorker:
    def __init__(self, db: Session, embedding_client: Optional[EmbeddingClient] = None):
        self.db = db
        self.client = embedding_client or get_embedding_client()

    def process_outbox_jobs(self, limit: int = 32) -> int:
        now = datetime.now(timezone.utc)
        jobs = (
            self.db.query(EmbeddingOutbox)
            .filter(
                EmbeddingOutbox.processed_at.is_(None),
                EmbeddingOutbox.available_at <= now,
            )
            .order_by(EmbeddingOutbox.created_at.asc())
            .limit(limit)
            .all()
        )

        if not jobs:
            return 0

        processed_count = 0

        for job in jobs:
            job.attempts += 1
            card = self.db.query(Card).filter(Card.id == job.card_id).first()

            # Handle soft delete or hard deleted cards
            if not card or card.deleted_at is not None or job.event_type == "delete":
                self.db.query(CardEmbedding).filter(CardEmbedding.card_id == job.card_id).delete()
                job.processed_at = now
                processed_count += 1
                continue

            # Load column title for canonical text
            col = self.db.query(BoardColumn).filter(BoardColumn.id == card.column_id).first()
            col_title = col.title if col else None

            canonical_text = canonicalize_card(card, col_title)
            current_hash = compute_source_hash(canonical_text)

            try:
                # Generate embedding
                vector = self.client.embed_text(canonical_text)

                # Upsert into card_embeddings
                existing_emb = (
                    self.db.query(CardEmbedding)
                    .filter(CardEmbedding.card_id == card.id)
                    .first()
                )

                if existing_emb:
                    existing_emb.source_hash = current_hash
                    existing_emb.embedding_model = settings.EMBEDDING_MODEL
                    existing_emb.embedded_at = now
                    existing_emb.embedding = vector
                    existing_emb.search_document = canonical_text
                else:
                    new_emb = CardEmbedding(
                        card_id=card.id,
                        board_id=card.board_id,
                        embedding_model=settings.EMBEDDING_MODEL,
                        source_hash=current_hash,
                        embedded_at=now,
                        embedding=vector,
                        search_document=canonical_text,
                    )
                    self.db.add(new_emb)

                job.processed_at = now
                processed_count += 1

            except Exception as exc:
                logger.exception("Failed to process embedding outbox job %s: %s", job.id, exc)
                job.last_error = str(exc)[:500]

        self.db.commit()
        return processed_count
