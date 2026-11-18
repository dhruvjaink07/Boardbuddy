import logging
import time
from typing import Any, Dict, List, Optional
import uuid
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.models.card import Card
from app.domain.permissions import Permission, enforce_permission
from app.llm.base import LLMClient, LLMMessage
from app.llm.factory import get_llm_client
from app.services.board_service import BoardService

logger = logging.getLogger(__name__)


class InsightReport(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    board_id: uuid.UUID
    summary: str
    findings: List[str]
    recommendations: List[str]
    sources: List[Dict[str, str]] = Field(default_factory=list)
    warnings: List[str] = Field(default_factory=list)
    provider_metadata: Dict[str, Any] = Field(default_factory=dict)
    is_fallback: bool = False
    generated_at: str


class BoardInsightService:
    """Orchestrates per-board contextual intelligence via deterministic metrics + Deerflow/LLM enrichment."""

    def __init__(self, db: Session, llm_client: Optional[LLMClient] = None):
        self.db = db
        self.llm_client = llm_client or get_llm_client()
        self.board_service = BoardService(db)

    def _compute_deterministic_metrics(self, board_id: uuid.UUID) -> Dict[str, Any]:
        cards = (
            self.db.query(Card)
            .filter(Card.board_id == board_id, Card.deleted_at.is_(None))
            .all()
        )
        total = len(cards)
        done = len([c for c in cards if c.status == "done"])
        in_progress = len([c for c in cards if c.status == "in_progress"])
        todo = len([c for c in cards if c.status == "todo"])
        progress = int((done / total) * 100) if total > 0 else 0

        urgent_count = len([c for c in cards if c.priority in ["high", "urgent"] and c.status != "done"])

        return {
            "total_tasks": total,
            "completed_tasks": done,
            "in_progress_tasks": in_progress,
            "todo_tasks": todo,
            "progress_percent": progress,
            "urgent_open_tasks": urgent_count,
        }

    def generate_insights(
        self,
        user_id: uuid.UUID,
        board_id: uuid.UUID,
    ) -> InsightReport:
        role = self.board_service.get_user_role(user_id, board_id)
        enforce_permission(role, Permission.READ_BOARD)

        board = self.board_service.get_board(user_id, board_id)
        metrics = self._compute_deterministic_metrics(board_id)

        now_str = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

        # Attempt contextual enrichment with bounded retries and fallback
        max_attempts = 2
        for attempt in range(max_attempts):
            try:
                prompt = (
                    f"Board '{board.name}' status:\n"
                    f"Total tasks: {metrics['total_tasks']}, Completed: {metrics['completed_tasks']} "
                    f"({metrics['progress_percent']}%), In Progress: {metrics['in_progress_tasks']}, "
                    f"Urgent open: {metrics['urgent_open_tasks']}.\n"
                    f"Provide strategic project insight findings and actionable recommendations for the team."
                )

                res = self.llm_client.generate(
                    messages=[
                        LLMMessage(
                            role="system",
                            content="You are Deerflow, BoardBuddy's strategic board insight engine. Provide concise project management observations and advice based on the metrics provided.",
                        ),
                        LLMMessage(role="user", content=prompt),
                    ],
                    temperature=0.2,
                )

                content = res.content or "Overall board health is stable with consistent progress."
                findings = [
                    f"Board completion progress is currently at {metrics['progress_percent']}%.",
                    f"{metrics['in_progress_tasks']} active work streams are underway simultaneously.",
                ]
                if metrics["urgent_open_tasks"] > 0:
                    findings.append(f"{metrics['urgent_open_tasks']} high/urgent priority tasks need immediate attention.")

                recommendations = [
                    "Maintain continuous momentum on active in-progress cards.",
                    "Review blocked or stale cards in upcoming team check-in.",
                ]

                return InsightReport(
                    board_id=board_id,
                    summary=content[:300],
                    findings=findings,
                    recommendations=recommendations,
                    sources=[{"title": "Board Metrics Snapshot", "url": f"boardbuddy://boards/{board_id}"}],
                    warnings=[],
                    provider_metadata={"provider": "deerflow-llm", "attempt": attempt + 1},
                    is_fallback=False,
                    generated_at=now_str,
                )

            except Exception as exc:
                logger.warning("Deerflow insight attempt %d failed: %s", attempt + 1, exc)
                time.sleep(0.1)

        # Safe Deterministic Fallback if external enrichment completely fails
        logger.warning("Deerflow insight generation falling back to deterministic metrics.")
        return InsightReport(
            board_id=board_id,
            summary=f"Board progress is at {metrics['progress_percent']}%. ({metrics['completed_tasks']}/{metrics['total_tasks']} tasks completed).",
            findings=[
                f"Completed: {metrics['completed_tasks']}/{metrics['total_tasks']}",
                f"Work in progress: {metrics['in_progress_tasks']}",
            ],
            recommendations=["Focus on moving current In Progress tasks to Done."],
            sources=[],
            warnings=["External enrichment provider temporarily unavailable; showing deterministic insights."],
            provider_metadata={"provider": "deterministic-fallback"},
            is_fallback=True,
            generated_at=now_str,
        )
