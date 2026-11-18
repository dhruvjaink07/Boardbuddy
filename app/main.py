import time
import uuid
from pathlib import Path
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
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


# Static asset mounting & logo endpoints
STATIC_DIR = Path(__file__).resolve().parent / "static"
if STATIC_DIR.is_dir():
    app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")


@app.get("/logo.png", tags=["Assets"], include_in_schema=False)
def serve_logo_png():
    logo_file = STATIC_DIR / "logo.png"
    if logo_file.is_file():
        return FileResponse(logo_file, media_type="image/png")
    return JSONResponse(status_code=404, content={"error": "logo not found"})


@app.get("/logo.svg", tags=["Assets"], include_in_schema=False)
def serve_logo_svg():
    logo_file = STATIC_DIR / "logo.svg"
    if logo_file.is_file():
        return FileResponse(logo_file, media_type="image/svg+xml")
    return JSONResponse(status_code=404, content={"error": "logo not found"})


@app.get("/favicon.ico", tags=["Assets"], include_in_schema=False)
def serve_favicon():
    favicon_file = STATIC_DIR / "favicon.ico"
    if favicon_file.is_file():
        return FileResponse(favicon_file, media_type="image/x-icon")
    return JSONResponse(status_code=404, content={"error": "favicon not found"})

