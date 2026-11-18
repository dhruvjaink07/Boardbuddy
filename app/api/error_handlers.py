import uuid
import logging
from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.core.exceptions import BoardBuddyException

logger = logging.getLogger(__name__)


def get_request_id(request: Request) -> str:
    return getattr(request.state, "request_id", f"req_{uuid.uuid4().hex[:16]}")


def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(BoardBuddyException)
    async def boardbuddy_exception_handler(request: Request, exc: BoardBuddyException):
        req_id = get_request_id(request)
        error_content = {
            "error": {
                "code": exc.code,
                "message": exc.message,
                "request_id": req_id,
            }
        }
        if exc.details is not None:
            error_content["error"]["details"] = exc.details
        return JSONResponse(
            status_code=exc.status_code,
            content=error_content,
            headers={"X-Request-ID": req_id},
        )

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError):
        req_id = get_request_id(request)
        error_content = {
            "error": {
                "code": "validation_error",
                "message": "Validation failed for request parameters or body.",
                "request_id": req_id,
                "details": exc.errors(),
            }
        }
        return JSONResponse(
            status_code=422,
            content=error_content,
            headers={"X-Request-ID": req_id},
        )

    @app.exception_handler(StarletteHTTPException)
    async def http_exception_handler(request: Request, exc: StarletteHTTPException):
        req_id = get_request_id(request)
        code_map = {
            401: "unauthorized",
            403: "permission_denied",
            404: "not_found",
            405: "method_not_allowed",
            409: "conflict",
            422: "validation_error",
        }
        code = code_map.get(exc.status_code, "http_error")
        error_content = {
            "error": {
                "code": code,
                "message": str(exc.detail),
                "request_id": req_id,
            }
        }
        return JSONResponse(
            status_code=exc.status_code,
            content=error_content,
            headers={"X-Request-ID": req_id},
        )

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(request: Request, exc: Exception):
        req_id = get_request_id(request)
        logger.exception("Unhandled server exception: %s", exc)
        error_content = {
            "error": {
                "code": "internal_error",
                "message": "An internal server error occurred.",
                "request_id": req_id,
            }
        }
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content=error_content,
            headers={"X-Request-ID": req_id},
        )
