from typing import Annotated, List, Literal, Optional
import uuid
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.models.user import User
from app.db.session import get_db
from app.schemas.board import BoardCreate, BoardOverview, BoardRead, BoardUpdate
from app.services.board_service import BoardService

router = APIRouter(prefix="/boards", tags=["Boards"])


@router.get(
    "",
    response_model=List[BoardOverview],
    status_code=status.HTTP_200_OK,
    summary="List all accessible boards for current user",
)
def list_boards(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    filter: Literal["all", "recent", "favorites"] = Query(default="all"),
    limit: int = Query(default=25, ge=1, le=100),
    cursor: Optional[str] = Query(default=None),
) -> List[BoardOverview]:
    service = BoardService(db)
    return service.list_boards(user_id=current_user.id, filter_type=filter)


@router.post(
    "",
    response_model=BoardRead,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new board",
)
def create_board(
    data: BoardCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> BoardRead:
    service = BoardService(db)
    return service.create_board(user_id=current_user.id, data=data)


@router.get(
    "/{board_id}",
    response_model=BoardRead,
    status_code=status.HTTP_200_OK,
    summary="Get board metadata, role, and columns",
)
def get_board(
    board_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> BoardRead:
    service = BoardService(db)
    return service.get_board(user_id=current_user.id, board_id=board_id)


@router.patch(
    "/{board_id}",
    response_model=BoardRead,
    status_code=status.HTTP_200_OK,
    summary="Update board name, description, theme, or favorite state",
)
def update_board(
    board_id: uuid.UUID,
    data: BoardUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> BoardRead:
    service = BoardService(db)
    return service.update_board(user_id=current_user.id, board_id=board_id, data=data)


@router.delete(
    "/{board_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Soft-archive a board (owner only)",
)
def delete_board(
    board_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> None:
    service = BoardService(db)
    service.archive_board(user_id=current_user.id, board_id=board_id)
