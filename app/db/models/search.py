import uuid
from datetime import datetime
from typing import Optional
from sqlalchemy import DateTime, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base, GUID, VectorType, utc_now


class CardEmbedding(Base):
    __tablename__ = "card_embeddings"

    card_id: Mapped[uuid.UUID] = mapped_column(
        GUID,
        ForeignKey("cards.id", ondelete="CASCADE"),
        primary_key=True,
    )
    board_id: Mapped[uuid.UUID] = mapped_column(
        GUID,
        ForeignKey("boards.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    embedding_model: Mapped[str] = mapped_column(String(60), nullable=False)
    source_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    embedded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utc_now,
        nullable=False,
    )
    embedding: Mapped[Optional[list[float]]] = mapped_column(VectorType(768), nullable=True)
    search_document: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
