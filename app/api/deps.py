import uuid
from typing import Annotated, Optional
from fastapi import Depends, Header, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.exceptions import BoardBuddyException
from app.core.security import decode_access_token
from app.db.models.user import User
from app.db.session import get_db

security_scheme = HTTPBearer(auto_error=False)


def get_current_user(
    auth: Annotated[Optional[HTTPAuthorizationCredentials], Depends(security_scheme)],
    db: Annotated[Session, Depends(get_db)],
) -> User:
    if not auth or not auth.credentials:
        raise BoardBuddyException(
            code="unauthorized",
            message="Missing or invalid authentication credentials.",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )

    payload = decode_access_token(auth.credentials)
    if not payload or "sub" not in payload:
        raise BoardBuddyException(
            code="unauthorized",
            message="Invalid or expired access token.",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )

    try:
        user_id = uuid.UUID(payload["sub"])
    except (ValueError, TypeError):
        raise BoardBuddyException(
            code="unauthorized",
            message="Invalid user identifier in token.",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise BoardBuddyException(
            code="unauthorized",
            message="User associated with token not found.",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )

    return user
