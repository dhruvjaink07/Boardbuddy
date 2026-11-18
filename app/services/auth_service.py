from datetime import datetime, timezone
import uuid
from fastapi import status
from sqlalchemy.orm import Session
from app.core.exceptions import BoardBuddyException, ConflictException, ValidationException
from app.core.security import create_access_token, hash_password, verify_password
from app.db.models.user import User
from app.schemas.auth import TokenResponse, UserLogin, UserRead, UserRegister


class AuthService:
    def __init__(self, db: Session):
        self.db = db

    def register(self, data: UserRegister) -> TokenResponse:
        canonical_email = data.email.lower().strip()
        existing = self.db.query(User).filter(User.email == canonical_email).first()
        if existing:
            raise ConflictException("An account with this email already exists.")

        user = User(
            email=canonical_email,
            password_hash=hash_password(data.password),
            display_name=data.display_name or canonical_email.split("@")[0],
        )
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)

        token = create_access_token(subject=str(user.id))
        return TokenResponse(
            user=UserRead.model_validate(user),
            access_token=token,
        )

    def login(self, data: UserLogin) -> TokenResponse:
        canonical_email = data.email.lower().strip()
        user = self.db.query(User).filter(User.email == canonical_email).first()
        if not user or not user.password_hash or not verify_password(data.password, user.password_hash):
            raise BoardBuddyException(
                code="unauthorized",
                message="Invalid email or password.",
                status_code=status.HTTP_401_UNAUTHORIZED,
            )

        user.last_seen_at = datetime.now(timezone.utc)
        self.db.commit()
        self.db.refresh(user)

        token = create_access_token(subject=str(user.id))
        return TokenResponse(
            user=UserRead.model_validate(user),
            access_token=token,
        )

    # Convenience aliases
    register_user = register
    authenticate_user = login

    def get_user_by_id(self, user_id: uuid.UUID) -> User | None:
        return self.db.query(User).filter(User.id == user_id).first()
