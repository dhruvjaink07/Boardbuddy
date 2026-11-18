from typing import Annotated, Any, Dict, List
import uuid
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.models.board import BoardMember
from app.db.models.card import Card
from app.db.models.user import User
from app.db.session import get_db
from app.domain.permissions import Permission, enforce_permission
from app.services.analytics.insights_service import BoardInsightService, InsightReport
from app.services.analytics.standup_service import (
    CardPriorityItem,
    StandupAnalyticsService,
    StandupRequest,
    StandupResponse,
)
from app.services.board_service import BoardService

router = APIRouter(tags=["Analytics & Insights"])


@router.get(
    "/boards/{board_id}/analytics",
    status_code=status.HTTP_200_OK,
    summary="Get deterministic analytics for a board",
)
def get_board_analytics(
    board_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> Dict[str, Any]:
    board_service = BoardService(db)
    role = board_service.get_user_role(current_user.id, board_id)
    enforce_permission(role, Permission.READ_BOARD)

    cards = db.query(Card).filter(Card.board_id == board_id, Card.deleted_at.is_(None)).all()
    total = len(cards)
    done = len([c for c in cards if c.status == "done"])
    in_progress = len([c for c in cards if c.status == "in_progress"])
    todo = len([c for c in cards if c.status == "todo"])
    progress = int((done / total) * 100) if total > 0 else 0

    return {
        "board_id": str(board_id),
        "total_tasks": total,
        "completed_tasks": done,
        "in_progress_tasks": in_progress,
        "todo_tasks": todo,
        "progress_percent": progress,
        "metrics_definition": "Deterministic metrics computed from live database cards snapshot.",
    }


@router.get(
    "/analytics/me",
    status_code=status.HTTP_200_OK,
    summary="Get cross-board aggregate analytics for current user",
)
def get_user_cross_board_analytics(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> Dict[str, Any]:
    memberships = (
        db.query(BoardMember.board_id)
        .filter(BoardMember.user_id == current_user.id)
        .all()
    )
    board_ids = [m[0] for m in memberships]

    if not board_ids:
        return {
            "total_boards": 0,
            "total_tasks": 0,
            "completed_tasks": 0,
            "in_progress_tasks": 0,
            "overall_progress_percent": 0,
        }

    cards = (
        db.query(Card)
        .filter(Card.board_id.in_(board_ids), Card.deleted_at.is_(None))
        .all()
    )
    total = len(cards)
    done = len([c for c in cards if c.status == "done"])
    in_progress = len([c for c in cards if c.status == "in_progress"])
    overall_progress = int((done / total) * 100) if total > 0 else 0

    return {
        "total_boards": len(board_ids),
        "total_tasks": total,
        "completed_tasks": done,
        "in_progress_tasks": in_progress,
        "overall_progress_percent": overall_progress,
    }


@router.post(
    "/boards/{board_id}/standup",
    response_model=StandupResponse,
    status_code=status.HTTP_200_OK,
    summary="Generate daily standup summary from activity history and current board state",
)
def generate_standup(
    board_id: uuid.UUID,
    request: StandupRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> StandupResponse:
    service = StandupAnalyticsService(db)
    return service.generate_standup(
        user_id=current_user.id,
        board_id=board_id,
        request=request,
    )


@router.get(
    "/boards/{board_id}/priorities",
    response_model=List[CardPriorityItem],
    status_code=status.HTTP_200_OK,
    summary="Calculate deterministic priority rankings for board cards",
)
def get_board_priorities(
    board_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> List[CardPriorityItem]:
    service = StandupAnalyticsService(db)
    return service.calculate_priorities(user_id=current_user.id, board_id=board_id)


@router.get(
    "/boards/{board_id}/insights",
    response_model=InsightReport,
    status_code=status.HTTP_200_OK,
    summary="Generate contextual board insights via Deerflow/LLM enrichment with reliable fallback",
)
def get_board_insights(
    board_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    force_refresh: bool = False,
) -> InsightReport:
    service = BoardInsightService(db)
    return service.generate_insights(
        user_id=current_user.id,
        board_id=board_id,
        force_refresh=force_refresh,
    )
