import math
from typing import Any, Dict, List, Literal, Optional
import uuid
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy.orm import Session

from app.core.exceptions import PermissionDeniedException
from app.db.models.board import BoardMember
from app.db.models.card import Card
from app.db.models.search import CardEmbedding
from app.domain.permissions import Permission, enforce_permission
from app.llm.embedding import EmbeddingClient, get_embedding_client
from app.services.board_service import BoardService


class CardSearchRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    query: str = Field(min_length=1, max_length=500)
    board_id: Optional[uuid.UUID] = None
    mode: Literal["hybrid", "semantic", "keyword"] = "hybrid"
    limit: int = Field(default=10, ge=1, le=50)


class CardSearchResult(BaseModel):
    card_id: uuid.UUID
    board_id: uuid.UUID
    title: str
    snippet: str
    score: float
    matched_by: Literal["hybrid", "semantic", "keyword"]


def cosine_similarity(v1: List[float], v2: List[float]) -> float:
    if not v1 or not v2 or len(v1) != len(v2):
        return 0.0
    dot = sum(a * b for a, b in zip(v1, v2))
    norm_a = math.sqrt(sum(a * a for a in v1))
    norm_b = math.sqrt(sum(b * b for b in v2))
    if norm_a == 0.0 or norm_b == 0.0:
        return 0.0
    return dot / (norm_a * norm_b)


class SearchService:
    def __init__(self, db: Session, embedding_client: Optional[EmbeddingClient] = None):
        self.db = db
        self.client = embedding_client or get_embedding_client()
        self.board_service = BoardService(db)

    def search_cards(
        self,
        user_id: uuid.UUID,
        request: CardSearchRequest,
    ) -> List[CardSearchResult]:
        # 1. Permission filtering: Determine which boards caller can search
        if request.board_id:
            role = self.board_service.get_user_role(user_id, request.board_id)
            enforce_permission(role, Permission.READ_BOARD)
            allowed_board_ids = {request.board_id}
        else:
            memberships = (
                self.db.query(BoardMember.board_id)
                .filter(BoardMember.user_id == user_id)
                .all()
            )
            allowed_board_ids = {m[0] for m in memberships}

        if not allowed_board_ids:
            return []

        # 2. Vector retrieval path
        vector_ranks: Dict[uuid.UUID, int] = {}
        if request.mode in ["hybrid", "semantic"]:
            query_vector = self.client.embed_text(request.query)
            embeddings = (
                self.db.query(CardEmbedding)
                .filter(CardEmbedding.board_id.in_(allowed_board_ids))
                .all()
            )

            scored_vectors = []
            for emb in embeddings:
                if emb.embedding:
                    sim = cosine_similarity(query_vector, emb.embedding)
                    scored_vectors.append((emb.card_id, sim))

            # Sort descending by similarity
            scored_vectors.sort(key=lambda x: x[1], reverse=True)
            for rank, (cid, _) in enumerate(scored_vectors[:30], start=1):
                vector_ranks[cid] = rank

        # 3. Keyword retrieval path
        keyword_ranks: Dict[uuid.UUID, int] = {}
        if request.mode in ["hybrid", "keyword"]:
            query_terms = [t.lower() for t in request.query.split() if len(t) > 1]
            active_cards = (
                self.db.query(Card)
                .filter(
                    Card.board_id.in_(allowed_board_ids),
                    Card.deleted_at.is_(None),
                )
                .all()
            )

            scored_keywords = []
            for card in active_cards:
                search_text = f"{card.title} {card.description or ''} {' '.join(card.labels)}".lower()
                # Compute term match frequency score
                term_score = sum(search_text.count(t) for t in query_terms)
                if term_score > 0:
                    scored_keywords.append((card.id, term_score))

            scored_keywords.sort(key=lambda x: x[1], reverse=True)
            for rank, (cid, _) in enumerate(scored_keywords[:30], start=1):
                keyword_ranks[cid] = rank

        # 4. Reciprocal Rank Fusion (RRF with k=60)
        k = 60
        all_candidate_ids = set(vector_ranks.keys()) | set(keyword_ranks.keys())
        if not all_candidate_ids:
            return []

        fused_scores: Dict[uuid.UUID, float] = {}
        matched_tags: Dict[uuid.UUID, Literal["hybrid", "semantic", "keyword"]] = {}

        for cid in all_candidate_ids:
            score = 0.0
            in_vec = cid in vector_ranks
            in_kw = cid in keyword_ranks

            if in_vec:
                score += 1.0 / (k + vector_ranks[cid])
            if in_kw:
                score += 1.0 / (k + keyword_ranks[cid])

            fused_scores[cid] = score

            if in_vec and in_kw:
                matched_tags[cid] = "hybrid"
            elif in_vec:
                matched_tags[cid] = "semantic"
            else:
                matched_tags[cid] = "keyword"

        # 5. Fetch cards and format results
        sorted_card_ids = sorted(fused_scores.keys(), key=lambda x: fused_scores[x], reverse=True)[
            : request.limit
        ]

        cards_map = {
            c.id: c
            for c in self.db.query(Card)
            .filter(Card.id.in_(sorted_card_ids), Card.deleted_at.is_(None))
            .all()
        }

        results: List[CardSearchResult] = []
        for cid in sorted_card_ids:
            card = cards_map.get(cid)
            if not card:
                continue
            snippet = card.description[:120] if card.description else card.title
            results.append(
                CardSearchResult(
                    card_id=card.id,
                    board_id=card.board_id,
                    title=card.title,
                    snippet=snippet,
                    score=round(fused_scores[cid], 5),
                    matched_by=matched_tags[cid],
                )
            )

        return results
