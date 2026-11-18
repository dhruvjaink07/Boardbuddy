from abc import ABC, abstractmethod
import hashlib
import math
import random
from typing import List, Optional
import httpx

from app.core.config import settings
from app.core.exceptions import BoardBuddyException


class EmbeddingClient(ABC):
    @abstractmethod
    def embed_text(self, text: str) -> List[float]:
        """Embed a single text string into a float vector."""
        pass

    @abstractmethod
    def embed_batch(self, texts: List[str]) -> List[List[float]]:
        """Embed a batch of text strings into float vectors."""
        pass


class GeminiEmbeddingClient(EmbeddingClient):
    BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models"

    def __init__(
        self,
        api_key: Optional[str] = None,
        model: Optional[str] = None,
        dimensions: int = 768,
    ):
        self.api_key = api_key or settings.GEMINI_API_KEY
        self.model = model or settings.EMBEDDING_MODEL
        self.dimensions = dimensions

    def embed_text(self, text: str) -> List[float]:
        results = self.embed_batch([text])
        return results[0]

    def embed_batch(self, texts: List[str]) -> List[List[float]]:
        if not self.api_key:
            raise BoardBuddyException(
                code="ai_service_unavailable",
                message="Gemini API key is not configured for embeddings.",
                status_code=503,
            )

        url = f"{self.BASE_URL}/{self.model}:batchEmbedContents?key={self.api_key}"
        requests = [
            {
                "model": f"models/{self.model}",
                "content": {"parts": [{"text": t}]},
                "outputDimensionality": self.dimensions,
            }
            for t in texts
        ]

        with httpx.Client(timeout=settings.LLM_TIMEOUT_SECONDS) as client:
            res = client.post(url, json={"requests": requests})
            if res.status_code != 200:
                raise BoardBuddyException(
                    code="embedding_provider_error",
                    message=f"Gemini embedding API error {res.status_code}: {res.text[:200]}",
                    status_code=502,
                )
            data = res.json()

        embeddings = data.get("embeddings", [])
        return [e.get("values", [0.0] * self.dimensions) for e in embeddings]


class MockEmbeddingClient(EmbeddingClient):
    """Deterministic mock embedding generator for tests and offline development."""

    def __init__(self, dimensions: int = 768):
        self.dimensions = dimensions

    def _generate_vector(self, text: str) -> List[float]:
        # Hash text deterministically to generate stable pseudo-vector
        seed = int(hashlib.sha256(text.encode("utf-8")).hexdigest()[:8], 16)
        rng = random.Random(seed)
        vec = [rng.gauss(0, 1) for _ in range(self.dimensions)]
        # Normalize to unit length for cosine similarity
        norm = math.sqrt(sum(x * x for x in vec))
        return [x / norm for x in vec] if norm > 0 else vec

    def embed_text(self, text: str) -> List[float]:
        return self._generate_vector(text)

    def embed_batch(self, texts: List[str]) -> List[List[float]]:
        return [self._generate_vector(t) for t in texts]


_mock_embedding_instance: Optional[MockEmbeddingClient] = None


def get_embedding_client(provider: Optional[str] = None) -> EmbeddingClient:
    global _mock_embedding_instance
    chosen = provider or settings.EMBEDDING_PROVIDER

    if chosen == "mock" or (chosen == "gemini" and not settings.GEMINI_API_KEY):
        if _mock_embedding_instance is None:
            _mock_embedding_instance = MockEmbeddingClient()
        return _mock_embedding_instance

    if chosen == "gemini":
        return GeminiEmbeddingClient()

    return MockEmbeddingClient()


def set_mock_embedding_client(client: Optional[MockEmbeddingClient]) -> None:
    global _mock_embedding_instance
    _mock_embedding_instance = client
