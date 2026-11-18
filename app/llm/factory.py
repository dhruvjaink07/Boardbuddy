from typing import Optional
from app.core.config import settings
from app.llm.base import LLMClient
from app.llm.gemini import GeminiClient
from app.llm.mock import MockLLMClient

_mock_instance: Optional[MockLLMClient] = None


def get_llm_client(provider: Optional[str] = None) -> LLMClient:
    global _mock_instance
    chosen_provider = provider or settings.LLM_PROVIDER

    if chosen_provider == "mock" or (chosen_provider == "gemini" and not settings.GEMINI_API_KEY):
        if _mock_instance is None:
            _mock_instance = MockLLMClient()
        return _mock_instance

    if chosen_provider == "gemini":
        return GeminiClient()

    # Fallback to mock for unrecognized providers
    return MockLLMClient()


def set_mock_llm_client(mock_client: Optional[MockLLMClient]) -> None:
    global _mock_instance
    _mock_instance = mock_client
