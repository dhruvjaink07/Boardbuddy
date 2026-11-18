import hashlib
from typing import Any, Optional
import uuid
from sqlalchemy.orm import Session
from app.db.models.activity import ActivityEvent, EmbeddingOutbox


class ActivityService:
    def __init__(self, db: Session):
        self.db = db

    def record_event(
        self,
        board_id: uuid.UUID,
        actor_id: uuid.UUID,
        event_type: str,
        card_id: Optional[uuid.UUID] = None,
        payload: Optional[dict[str, Any]] = None,
    ) -> ActivityEvent:
        event = ActivityEvent(
            board_id=board_id,
            card_id=card_id,
            actor_id=actor_id,
            event_type=event_type,
            payload=payload or {},
        )
        self.db.add(event)
        return event

    def enqueue_embedding_job(
        self,
        card_id: uuid.UUID,
        event_type: str,
        source_hash: str,
    ) -> EmbeddingOutbox:
        outbox = EmbeddingOutbox(
            card_id=card_id,
            event_type=event_type,
            source_hash=source_hash,
        )
        self.db.add(outbox)
        return outbox
