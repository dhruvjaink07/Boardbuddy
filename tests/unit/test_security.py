from datetime import timedelta
import uuid
import pytest
from app.core.security import (
    create_access_token,
    decode_access_token,
    hash_password,
    verify_password,
)


def test_password_hashing():
    raw = "MySecretPassword123!"
    hashed = hash_password(raw)

    assert hashed != raw
    assert verify_password(raw, hashed) is True
    assert verify_password("WrongPassword!", hashed) is False


def test_token_encode_decode():
    user_id = str(uuid.uuid4())
    token = create_access_token(subject=user_id, expires_delta=timedelta(minutes=15))

    payload = decode_access_token(token)
    assert payload is not None
    assert payload.get("sub") == user_id
    assert "exp" in payload
    assert "iat" in payload


def test_token_expired():
    user_id = str(uuid.uuid4())
    # Create token already expired 5 minutes ago
    token = create_access_token(subject=user_id, expires_delta=timedelta(minutes=-5))

    payload = decode_access_token(token)
    assert payload is None


def test_token_tampered():
    user_id = str(uuid.uuid4())
    token = create_access_token(subject=user_id)
    tampered = token[:-4] + "fake"

    payload = decode_access_token(tampered)
    assert payload is None
