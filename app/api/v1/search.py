from typing import Annotated, List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.models.user import User
from app.db.session import get_db
from app.services.search.search_service import (
    CardSearchRequest,
    CardSearchResult,
    SearchService,
)

router = APIRouter(prefix="/search", tags=["Search"])


@router.post(
    "/cards",
    response_model=List[CardSearchResult],
    status_code=status.HTTP_200_OK,
    summary="Hybrid semantic and full-text search across authorized cards",
)
def search_cards(
    request: CardSearchRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> List[CardSearchResult]:
    service = SearchService(db)
    return service.search_cards(user_id=current_user.id, request=request)
