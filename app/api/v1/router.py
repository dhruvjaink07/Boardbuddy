from fastapi import APIRouter

from app.api.v1.ai import router as ai_router
from app.api.v1.analytics import router as analytics_router
from app.api.v1.assistant import router as assistant_router
from app.api.v1.auth import router as auth_router
from app.api.v1.boards import router as boards_router
from app.api.v1.cards import router as cards_router
from app.api.v1.columns import router as columns_router
from app.api.v1.search import router as search_router

api_router = APIRouter(prefix="/api/v1")

api_router.include_router(auth_router)
api_router.include_router(boards_router)
api_router.include_router(columns_router)
api_router.include_router(cards_router)
api_router.include_router(ai_router)
api_router.include_router(assistant_router)
api_router.include_router(search_router)
api_router.include_router(analytics_router)
