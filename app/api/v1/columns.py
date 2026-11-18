from typing import Annotated, List, Optional
import uuid
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.models.user import User
from app.db.session import get_db
from app.schemas.column import ColumnCreate, ColumnRead, ColumnReorder, ColumnUpdate
from app.services.column_service import ColumnService

router = APIRouter(prefix="/boards/{board_id}/columns", tags=["Columns"])


@router.post(
    "",
    response_model=ColumnRead,
    status_code=status.HTTP_201_CREATED,
    summary="Add a new column to a board",
)
def create_column(
    board_id: uuid.UUID,
    data: ColumnCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> ColumnRead:
    service = ColumnService(db)
    return service.create_column(user_id=current_user.id, board_id=board_id, data=data)


@router.patch(
    "/{column_id}",
    response_model=ColumnRead,
    status_code=status.HTTP_200_OK,
    summary="Update column title or position",
)
def update_column(
    board_id: uuid.UUID,
    column_id: uuid.UUID,
    data: ColumnUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> ColumnRead:
    service = ColumnService(db)
    return service.update_column(
        user_id=current_user.id,
        board_id=board_id,
        column_id=column_id,
        data=data,
    )


@router.post(
    "/reorder",
    response_model=List[ColumnRead],
    status_code=status.HTTP_200_OK,
    summary="Atomically reorder all columns on a board",
)
def reorder_columns(
    board_id: uuid.UUID,
    data: ColumnReorder,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> List[ColumnRead]:
    service = ColumnService(db)
    return service.reorder_columns(
        user_id=current_user.id,
        board_id=board_id,
        ordered_column_ids=data.ordered_column_ids,
    )


@router.delete(
    "/{column_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a column (must specify target column if non-empty)",
)
def delete_column(
    board_id: uuid.UUID,
    column_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    move_cards_to_column_id: Optional[uuid.UUID] = Query(default=None),
) -> None:
    service = ColumnService(db)
    service.delete_column(
        user_id=current_user.id,
        board_id=board_id,
        column_id=column_id,
        move_cards_to_column_id=move_cards_to_column_id,
    )
