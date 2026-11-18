from typing import Annotated
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.models.user import User
from app.db.session import get_db
from app.schemas.ai import (
    GoalBoardCommitRequest,
    GoalBoardPlanRequest,
    GoalBoardPlanResponse,
)
from app.schemas.board import BoardRead
from app.services.agent.goal_planner import GoalPlannerService

router = APIRouter(prefix="/ai/boards", tags=["AI Goal Planning"])


@router.post(
    "/plan",
    response_model=GoalBoardPlanResponse,
    status_code=status.HTTP_200_OK,
    summary="Generate a structured board plan preview from natural-language goal",
)
def plan_board(
    request: GoalBoardPlanRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> GoalBoardPlanResponse:
    service = GoalPlannerService(db)
    return service.plan_board(user_id=current_user.id, request=request)


@router.post(
    "/commit",
    response_model=BoardRead,
    status_code=status.HTTP_201_CREATED,
    summary="Commit and persist an approved board plan",
)
def commit_board(
    request: GoalBoardCommitRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> BoardRead:
    service = GoalPlannerService(db)
    return service.commit_plan(user_id=current_user.id, request=request)
