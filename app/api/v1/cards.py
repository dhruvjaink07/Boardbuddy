from typing import Annotated, List, Optional
import uuid
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.models.user import User
from app.db.session import get_db
from app.schemas.card import (
    CardCreate,
    CardMove,
    CardMoveResponse,
    CardRead,
    CardUpdate,
)
from app.services.card_service import CardService

router = APIRouter(tags=["Cards"])


@router.get(
    "/boards/{board_id}/cards",
    response_model=List[CardRead],
    status_code=status.HTTP_200_OK,
    summary="List cards on a board with optional filtering",
)
def list_cards(
    board_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    column_id: Optional[uuid.UUID] = Query(default=None),
    status_filter: Optional[str] = Query(default=None, alias="status"),
    priority: Optional[str] = Query(default=None),
    assignee_id: Optional[uuid.UUID] = Query(default=None),
    limit: int = Query(default=50, ge=1, le=100),
    cursor: Optional[str] = Query(default=None),
) -> List[CardRead]:
    service = CardService(db)
    return service.list_cards(
        user_id=current_user.id,
        board_id=board_id,
        column_id=column_id,
        status=status_filter,
        priority=priority,
        assignee_id=assignee_id,
        limit=limit,
    )


@router.post(
    "/boards/{board_id}/cards",
    response_model=CardRead,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new card on a board",
)
def create_card(
    board_id: uuid.UUID,
    data: CardCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> CardRead:
    service = CardService(db)
    return service.create_card(
        user_id=current_user.id,
        board_id=board_id,
        data=data,
    )


@router.get(
    "/cards/{card_id}",
    response_model=CardRead,
    status_code=status.HTTP_200_OK,
    summary="Get single card details",
)
def get_card(
    card_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> CardRead:
    service = CardService(db)
    return service.get_card(user_id=current_user.id, card_id=card_id)


@router.patch(
    "/cards/{card_id}",
    response_model=CardRead,
    status_code=status.HTTP_200_OK,
    summary="Update card fields (title, priority, progress, labels, etc.)",
)
def update_card(
    card_id: uuid.UUID,
    data: CardUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> CardRead:
    service = CardService(db)
    return service.update_card(
        user_id=current_user.id,
        card_id=card_id,
        data=data,
    )


@router.post(
    "/cards/{card_id}/move",
    response_model=CardMoveResponse,
    status_code=status.HTTP_200_OK,
    summary="Move a card to a different column or position atomically",
)
def move_card(
    card_id: uuid.UUID,
    data: CardMove,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> CardMoveResponse:
    service = CardService(db)
    card = service.move_card(
        user_id=current_user.id,
        card_id=card_id,
        data=data,
    )
    return CardMoveResponse(
        card_id=card.id,
        column_id=card.column_id,
        status=card.status,
        position=card.position,
        updated_at=card.updated_at,
    )


@router.delete(
    "/cards/{card_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Soft-delete a card",
)
def delete_card(
    card_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> None:
    service = CardService(db)
    service.delete_card(user_id=current_user.id, card_id=card_id)
