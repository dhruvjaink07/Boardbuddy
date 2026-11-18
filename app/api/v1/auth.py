from typing import Annotated
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.models.user import User
from app.db.session import get_db
from app.schemas.auth import TokenResponse, UserLogin, UserRead, UserRegister
from app.services.auth_service import AuthService

router = APIRouter(tags=["Auth & Users"])


@router.post(
    "/auth/register",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user",
)
def register(
    data: UserRegister,
    db: Annotated[Session, Depends(get_db)],
) -> TokenResponse:
    service = AuthService(db)
    return service.register_user(data)


@router.post(
    "/auth/login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Authenticate user and obtain access token",
)
def login(
    data: UserLogin,
    db: Annotated[Session, Depends(get_db)],
) -> TokenResponse:
    service = AuthService(db)
    return service.authenticate_user(data)


@router.get(
    "/users/me",
    response_model=UserRead,
    status_code=status.HTTP_200_OK,
    summary="Retrieve current user profile",
)
def get_me(
    current_user: Annotated[User, Depends(get_current_user)],
) -> UserRead:
    return UserRead.model_validate(current_user)
