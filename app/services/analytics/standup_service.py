from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional
import uuid
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy.orm import Session

from app.db.models.activity import ActivityEvent
from app.db.models.card import Card
from app.domain.permissions import Permission, enforce_permission
from app.services.board_service import BoardService


class StandupRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    date: Optional[str] = None  # YYYY-MM-DD
    timezone: str = "UTC"


class CardPriorityItem(BaseModel):
    card_id: uuid.UUID
    title: str
    priority_score: int
    factors: List[str]
    suggested_rank: int


class StandupResponse(BaseModel):
    board_id: uuid.UUID
    date: str
    summary: str
    completed_yesterday: List[Dict[str, Any]]
    today_focus: List[Dict[str, Any]]
    blockers: List[Dict[str, Any]]
    suggestions: List[str]
    data_limitations: List[str]


class StandupAnalyticsService:
    def __init__(self, db: Session):
        self.db = db
        self.board_service = BoardService(db)

    def calculate_priorities(
        self,
        user_id: uuid.UUID,
        board_id: uuid.UUID,
    ) -> List[CardPriorityItem]:
        role = self.board_service.get_user_role(user_id, board_id)
        enforce_permission(role, Permission.READ_BOARD)

        now = datetime.now(timezone.utc)
        active_cards = (
            self.db.query(Card)
            .filter(
                Card.board_id == board_id,
                Card.deleted_at.is_(None),
                Card.status != "done",
            )
            .all()
        )

        ranked_items: List[CardPriorityItem] = []

        for card in active_cards:
            score = 0
            factors: List[str] = []

            # 1. Explicit priority factor
            prio_weights = {"urgent": 40, "high": 25, "medium": 10, "low": 0}
            card_prio_weight = prio_weights.get(card.priority, 10)
            score += card_prio_weight
            factors.append(f"Explicit priority: {card.priority} (+{card_prio_weight})")

            # 2. Due date proximity
            if card.due_at:
                due_tz = card.due_at if card.due_at.tzinfo else card.due_at.replace(tzinfo=timezone.utc)
                diff = due_tz - now
                if diff.total_seconds() < 0:
                    score += 50
                    factors.append("Overdue task (+50)")
                elif diff <= timedelta(hours=24):
                    score += 30
                    factors.append("Due within 24 hours (+30)")
                elif diff <= timedelta(days=3):
                    score += 15
                    factors.append("Due within 3 days (+15)")

            # 3. Blocker check
            is_blocked = any("block" in label.lower() for label in card.labels)
            if is_blocked:
                score += 20
                factors.append("Card marked with blocker label (+20)")

            # 4. In-progress staleness
            if card.status == "in_progress":
                days_since_update = (now - card.updated_at).days
                if days_since_update >= 3:
                    score += 15
                    factors.append(f"Stale in-progress task ({days_since_update} days) (+15)")

            ranked_items.append(
                CardPriorityItem(
                    card_id=card.id,
                    title=card.title,
                    priority_score=score,
                    factors=factors,
                    suggested_rank=0,
                )
            )

        ranked_items.sort(key=lambda x: x.priority_score, reverse=True)
        for idx, item in enumerate(ranked_items, start=1):
            item.suggested_rank = idx

        return ranked_items

    def generate_standup(
        self,
        user_id: uuid.UUID,
        board_id: uuid.UUID,
        request: StandupRequest,
    ) -> StandupResponse:
        role = self.board_service.get_user_role(user_id, board_id)
        enforce_permission(role, Permission.READ_BOARD)

        board = self.board_service.get_board(user_id, board_id)
        now = datetime.now(timezone.utc)
        target_date_str = request.date or now.strftime("%Y-%m-%d")

        # 1. Completed Yesterday (look for completions in the last 24-48 hours)
        yesterday_start = now - timedelta(days=1)
        completed_cards = (
            self.db.query(Card)
            .filter(
                Card.board_id == board_id,
                Card.status == "done",
                Card.deleted_at.is_(None),
                Card.completed_at >= yesterday_start,
            )
            .all()
        )
        completed_yesterday = [
            {"card_id": str(c.id), "title": c.title, "completed_at": c.completed_at.isoformat() if c.completed_at else None}
            for c in completed_cards
        ]

        # 2. Today's Focus: cards in progress or due soon
        in_progress_cards = (
            self.db.query(Card)
            .filter(
                Card.board_id == board_id,
                Card.status == "in_progress",
                Card.deleted_at.is_(None),
            )
            .all()
        )
        today_focus = [
            {"card_id": str(c.id), "title": c.title, "priority": c.priority, "progress": c.progress}
            for c in in_progress_cards
        ]

        # 3. Blockers
        all_active_cards = (
            self.db.query(Card)
            .filter(
                Card.board_id == board_id,
                Card.status != "done",
                Card.deleted_at.is_(None),
            )
            .all()
        )
        blockers = []
        for c in all_active_cards:
            if any("block" in l.lower() for l in c.labels):
                blockers.append({"card_id": str(c.id), "title": c.title, "reason": "Blocked label present"})
            elif c.status == "in_progress" and (now - c.updated_at).days >= 3:
                blockers.append({
                    "card_id": str(c.id),
                    "title": c.title,
                    "reason": f"In progress without updates for {(now - c.updated_at).days} days",
                })

        # 4. Suggestions
        suggestions = []
        if not today_focus and all_active_cards:
            suggestions.append("No active cards are currently in progress. Consider moving top priority tasks from To Do.")
        if blockers:
            suggestions.append(f"There are {len(blockers)} tasks stalled or blocked that need team attention.")
        if not completed_yesterday:
            suggestions.append("No tasks were marked done yesterday. Review in-progress estimates.")

        # 5. Data limitations
        data_limitations = []
        events_count = (
            self.db.query(ActivityEvent)
            .filter(ActivityEvent.board_id == board_id)
            .count()
        )
        if events_count < 5:
            data_limitations.append("Recent activity history is limited; standup is primarily derived from current card snapshots.")
        missing_estimates = [c for c in all_active_cards if not c.estimate_minutes]
        if missing_estimates:
            data_limitations.append(f"{len(missing_estimates)} active tasks lack workload estimates.")

        summary = (
            f"Standup for '{board.name}': {len(completed_yesterday)} completed recently, "
            f"{len(today_focus)} currently in progress, and {len(blockers)} potential blockers."
        )

        return StandupResponse(
            board_id=board_id,
            date=target_date_str,
            summary=summary,
            completed_yesterday=completed_yesterday,
            today_focus=today_focus,
            blockers=blockers,
            suggestions=suggestions,
            data_limitations=data_limitations,
        )
