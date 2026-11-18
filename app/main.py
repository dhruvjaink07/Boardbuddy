import time
import uuid
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware

from app.api.error_handlers import register_error_handlers
from app.api.v1.router import api_router
from app.core.config import settings


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup hooks if needed
    yield
    # Shutdown hooks if needed


app = FastAPI(
    title="BoardBuddy API",
    version="1.0.0",
    description="AI-powered Kanban & project-management backend",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS if settings.CORS_ORIGINS else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Request ID and timing middleware
class RequestTrackingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        # Read or generate request id
        req_id = request.headers.get("X-Request-ID") or f"req_{uuid.uuid4().hex[:16]}"
        request.state.request_id = req_id
        start_time = time.time()

        response = await call_next(request)

        duration = time.time() - start_time
        response.headers["X-Request-ID"] = req_id
        response.headers["X-Response-Time"] = f"{duration:.4f}s"
        return response


app.add_middleware(RequestTrackingMiddleware)

# Register uniform error responses matching 04-api-contract.md
register_error_handlers(app)

# Include v1 REST endpoints
app.include_router(api_router)


@app.get("/health", tags=["Health"])
def health_check():
    return {
        "status": "ok",
        "app": "BoardBuddy API",
        "environment": settings.APP_ENV,
    }


@app.get("/api/v1/health", tags=["Health"])
def api_v1_health():
    return {"status": "ok"}
