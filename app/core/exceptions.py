import uuid
from typing import Any, Optional
from fastapi import HTTPException, status


class BoardBuddyException(Exception):
    def __init__(
        self,
        code: str,
        message: str,
        status_code: int = status.HTTP_400_BAD_REQUEST,
        details: Optional[Any] = None,
    ):
        self.code = code
        self.message = message
        self.status_code = status_code
        self.details = details
        super().__init__(message)


class PermissionDeniedException(BoardBuddyException):
    def __init__(self, message: str = "You cannot perform this action on this board."):
        super().__init__(
            code="permission_denied",
            message=message,
            status_code=status.HTTP_403_FORBIDDEN,
        )


class NotFoundException(BoardBuddyException):
    def __init__(self, resource: str = "Resource"):
        super().__init__(
            code="not_found",
            message=f"{resource} not found.",
            status_code=status.HTTP_404_NOT_FOUND,
        )


class ConflictException(BoardBuddyException):
    def __init__(self, message: str):
        super().__init__(
            code="conflict",
            message=message,
            status_code=status.HTTP_409_CONFLICT,
        )


class ValidationException(BoardBuddyException):
    def __init__(self, message: str, details: Optional[Any] = None):
        super().__init__(
            code="validation_error",
            message=message,
            status_code=422,
            details=details,
        )
