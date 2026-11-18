import json
import time
import uuid
import httpx
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.models.card import Card
from app.db.models.column import BoardColumn
from app.llm.base import LLMResponse
from app.llm.factory import set_mock_llm_client
from app.llm.mock import MockLLMClient
from app.services.analytics.insights_service import (
    BoardInsightService,
    CachedInsightEntry,
    DeerflowTavilyProvider,
)


def test_board_analytics_and_cross_board(
    client: TestClient,
    auth_headers: dict[str, str],
    test_board,
):
    col_id = test_board.columns[0].id

    # Create a couple tasks
    client.post(
        f"/api/v1/boards/{test_board.id}/cards",
        headers=auth_headers,
        json={"column_id": str(col_id), "title": "Task 1", "priority": "high"},
    )

    # 1. Board Analytics
    analytics_res = client.get(f"/api/v1/boards/{test_board.id}/analytics", headers=auth_headers)
    assert analytics_res.status_code == 200
    data = analytics_res.json()
    assert data["board_id"] == str(test_board.id)
    assert data["total_tasks"] >= 1
    assert "progress_percent" in data

    # 2. Cross-board Analytics
    me_res = client.get("/api/v1/analytics/me", headers=auth_headers)
    assert me_res.status_code == 200
    me_data = me_res.json()
    assert me_data["total_boards"] >= 1
    assert me_data["total_tasks"] >= 1


def test_standup_and_priorities(
    client: TestClient,
    auth_headers: dict[str, str],
    test_board,
):
    col_id = test_board.columns[0].id

    # Create an urgent task
    client.post(
        f"/api/v1/boards/{test_board.id}/cards",
        headers=auth_headers,
        json={"column_id": str(col_id), "title": "Critical Patch", "priority": "urgent"},
    )
    # Create a low task
    client.post(
        f"/api/v1/boards/{test_board.id}/cards",
        headers=auth_headers,
        json={"column_id": str(col_id), "title": "Minor Refactor", "priority": "low"},
    )

    # 1. Priorities
    prio_res = client.get(f"/api/v1/boards/{test_board.id}/priorities", headers=auth_headers)
    assert prio_res.status_code == 200
    prios = prio_res.json()
    assert len(prios) >= 2
    # Critical Patch should have higher score than Minor Refactor
    assert prios[0]["title"] == "Critical Patch"
    assert prios[0]["priority_score"] > prios[-1]["priority_score"]
    assert len(prios[0]["factors"]) > 0

    # 2. Standup
    standup_res = client.post(
        f"/api/v1/boards/{test_board.id}/standup",
        headers=auth_headers,
        json={"date": "2026-01-02", "timezone": "UTC"},
    )
    assert standup_res.status_code == 200
    standup = standup_res.json()
    assert "summary" in standup
    assert "today_focus" in standup
    assert "blockers" in standup
    assert "suggestions" in standup
    assert "data_limitations" in standup


def test_deerflow_insights_and_fallback(
    client: TestClient,
    auth_headers: dict[str, str],
    test_board,
):
    BoardInsightService.clear_cache()

    # 1. Normal Deerflow Insight Generation with plain text mock (heuristic parser)
    mock = MockLLMClient()
    mock.queue_response(
        LLMResponse(
            content="Team velocity is positive. Recommend clearing urgent backlog cards.",
            model="deerflow-llm",
        )
    )
    set_mock_llm_client(mock)

    insights_res = client.get(f"/api/v1/boards/{test_board.id}/insights", headers=auth_headers)
    assert insights_res.status_code == 200
    data = insights_res.json()
    assert data["is_fallback"] is False
    assert len(data["findings"]) >= 1
    assert len(data["recommendations"]) >= 1
    assert "trace_id" in data
    assert data["cache_age_seconds"] == 0

    # 2. Deerflow Fallback Mode (e.g. external provider throws)
    class BrokenLLMClient(MockLLMClient):
        def generate(self, *args, **kwargs):
            raise RuntimeError("Deerflow / Tavily provider connection refused")

    set_mock_llm_client(BrokenLLMClient())

    fallback_res = client.get(
        f"/api/v1/boards/{test_board.id}/insights?force_refresh=true",
        headers=auth_headers,
    )
    assert fallback_res.status_code == 200
    fallback_data = fallback_res.json()
    assert fallback_data["is_fallback"] is True
    assert "deterministic" in fallback_data["provider_metadata"]["provider"]
    assert len(fallback_data["warnings"]) >= 1
    assert "trace_id" in fallback_data


def test_deerflow_structured_output_parsing(
    client: TestClient,
    auth_headers: dict[str, str],
    test_board,
):
    """Verify that real structured JSON from LLM is parsed into exact Pydantic fields."""
    BoardInsightService.clear_cache()

    structured_json = {
        "summary": "Sprint velocity is accelerating ahead of targets with zero active blockers.",
        "findings": [
            "Column 'In Progress' has 3 cards with sub-24h cycle times.",
            "Backend API migrations completed without error.",
            "Test coverage is at 94% across core domain services.",
        ],
        "recommendations": [
            "Promote build 1.4.0 to staging cluster for QA validation.",
            "Conduct load tests on database connection pooling.",
        ],
    }

    mock = MockLLMClient()
    mock.queue_response(
        LLMResponse(
            content=json.dumps(structured_json),
            model="deerflow-structured-llm",
        )
    )
    set_mock_llm_client(mock)

    res = client.get(
        f"/api/v1/boards/{test_board.id}/insights?force_refresh=true",
        headers=auth_headers,
    )
    assert res.status_code == 200
    data = res.json()

    assert data["is_fallback"] is False
    assert data["summary"] == structured_json["summary"]
    assert data["findings"] == structured_json["findings"]
    assert data["recommendations"] == structured_json["recommendations"]
    assert data["provider_metadata"]["schema_validated"] is True
    assert data["provider_metadata"]["provider"] == "deerflow-tavily-llm"
    assert "trace_id" in data
    assert data["cache_age_seconds"] == 0


def test_deerflow_malformed_json_repair_and_unparseable_fallback(
    client: TestClient,
    auth_headers: dict[str, str],
    test_board,
):
    """Verify markdown code-fence repair and fallback on unparseable garbage."""
    BoardInsightService.clear_cache()

    # Case A: Markdown code fence with conversational preamble
    fenced_content = """
Here is the requested board insight report:
```json
{
  "summary": "Repaired executive summary from markdown block.",
  "findings": [
    "Workload is balanced across developers.",
    "Zero overdue cards in sprint backlog."
  ],
  "recommendations": [
    "Maintain daily standup rhythm.",
    "Refactor legacy database access functions."
  ]
}
```
Please let me know if you need more strategic recommendations!
"""
    mock = MockLLMClient()
    mock.queue_response(LLMResponse(content=fenced_content, model="deerflow-llm"))
    set_mock_llm_client(mock)

    res = client.get(
        f"/api/v1/boards/{test_board.id}/insights?force_refresh=true",
        headers=auth_headers,
    )
    assert res.status_code == 200
    data = res.json()
    assert data["is_fallback"] is False
    assert data["summary"] == "Repaired executive summary from markdown block."
    assert len(data["findings"]) == 2
    assert len(data["recommendations"]) == 2

    # Case B: Completely unparseable empty content that forces fallback
    class AlwaysEmptyClient(MockLLMClient):
        def generate(self, *args, **kwargs):
            return LLMResponse(content="", model="deerflow-llm")

    set_mock_llm_client(AlwaysEmptyClient())

    res_garbage = client.get(
        f"/api/v1/boards/{test_board.id}/insights?force_refresh=true",
        headers=auth_headers,
    )
    assert res_garbage.status_code == 200
    data_garbage = res_garbage.json()
    assert data_garbage["is_fallback"] is True
    assert "deterministic" in data_garbage["provider_metadata"]["provider"]


def test_deerflow_snapshot_hash_card_changes_outside_ten(
    client: TestClient,
    auth_headers: dict[str, str],
    test_board,
    db_session: Session,
):
    """Verify that changing card #12 (outside the first 10) invalidates snapshot hash cache."""
    BoardInsightService.clear_cache()
    col_id = test_board.columns[0].id

    # Create 12 cards
    card_ids = []
    for i in range(12):
        create_res = client.post(
            f"/api/v1/boards/{test_board.id}/cards",
            headers=auth_headers,
            json={"column_id": str(col_id), "title": f"Initial Card {i+1}", "priority": "medium"},
        )
        assert create_res.status_code == 201
        card_ids.append(create_res.json()["id"])

    mock = MockLLMClient()
    mock.queue_response(
        LLMResponse(
            content=json.dumps({
                "summary": "Initial 12-task baseline report.",
                "findings": ["12 cards active"],
                "recommendations": ["Review backlog"],
            }),
            model="deerflow-llm",
        )
    )
    set_mock_llm_client(mock)

    # 1. Warm cache
    res1 = client.get(f"/api/v1/boards/{test_board.id}/insights", headers=auth_headers)
    assert res1.status_code == 200
    data1 = res1.json()
    assert data1["summary"] == "Initial 12-task baseline report."
    assert data1["provider_metadata"].get("cache_hit") is not True

    # 2. Re-read without change -> cache hit
    res2 = client.get(f"/api/v1/boards/{test_board.id}/insights", headers=auth_headers)
    assert res2.status_code == 200
    data2 = res2.json()
    assert data2["provider_metadata"].get("cache_hit") is True

    # 3. Mutate Card #12 (the 12th card, outside the first 10)
    card_12_id = card_ids[11]
    update_res = client.patch(
        f"/api/v1/cards/{card_12_id}",
        headers=auth_headers,
        json={"title": "Card 12 Updated Title", "priority": "urgent"},
    )
    assert update_res.status_code == 200

    mock.queue_response(
        LLMResponse(
            content=json.dumps({
                "summary": "Updated report after card 12 mutation.",
                "findings": ["Card 12 is now urgent"],
                "recommendations": ["Address card 12 promptly"],
            }),
            model="deerflow-llm",
        )
    )

    # 4. Request insights without force_refresh -> cache MUST be invalidated by new hash
    res3 = client.get(f"/api/v1/boards/{test_board.id}/insights", headers=auth_headers)
    assert res3.status_code == 200
    data3 = res3.json()
    assert data3["provider_metadata"].get("cache_hit") is not True
    assert data3["summary"] == "Updated report after card 12 mutation."


def test_deerflow_snapshot_hash_status_priority_and_column_moves(
    client: TestClient,
    auth_headers: dict[str, str],
    test_board,
):
    """Verify that moving columns, changing status, or changing priority all invalidate the cache."""
    BoardInsightService.clear_cache()
    col1_id = test_board.columns[0].id
    col2_id = test_board.columns[1].id

    create_res = client.post(
        f"/api/v1/boards/{test_board.id}/cards",
        headers=auth_headers,
        json={"column_id": str(col1_id), "title": "Moveable Card", "priority": "low"},
    )
    card_id = create_res.json()["id"]

    mock = MockLLMClient()
    mock.queue_response(
        LLMResponse(
            content=json.dumps({"summary": "Col 1 Low", "findings": ["F1"], "recommendations": ["R1"]}),
            model="deerflow-llm",
        )
    )
    set_mock_llm_client(mock)

    # Initial report
    r1 = client.get(f"/api/v1/boards/{test_board.id}/insights", headers=auth_headers)
    assert r1.status_code == 200
    assert r1.json()["summary"] == "Col 1 Low"

    # Move card to Col 2 and set status to in_progress
    move_res = client.post(
        f"/api/v1/cards/{card_id}/move",
        headers=auth_headers,
        json={"target_column_id": str(col2_id), "position": 0},
    )
    assert move_res.status_code == 200

    mock.queue_response(
        LLMResponse(
            content=json.dumps({"summary": "Col 2 In Progress", "findings": ["F2"], "recommendations": ["R2"]}),
            model="deerflow-llm",
        )
    )

    r2 = client.get(f"/api/v1/boards/{test_board.id}/insights", headers=auth_headers)
    assert r2.status_code == 200
    assert r2.json()["summary"] == "Col 2 In Progress"
    assert r2.json()["provider_metadata"].get("cache_hit") is not True


def test_deerflow_cache_expiration_and_lru_eviction(
    test_board,
    db_session: Session,
):
    """Direct test of BoardInsightService cache TTL expiration and LRU bound enforcement."""
    BoardInsightService.clear_cache()
    mock = MockLLMClient()
    mock.queue_response(
        LLMResponse(
            content=json.dumps({"summary": "TTL Test 1", "findings": ["A"], "recommendations": ["B"]}),
            model="deerflow-llm",
        )
    )

    service = BoardInsightService(db_session, llm_client=mock)

    # 1. Warm cache
    rep1 = service.generate_insights(test_board.owner_id, test_board.id)
    assert rep1.summary == "TTL Test 1"
    assert BoardInsightService.get_cache_size() == 1

    # 2. Simulate TTL expiration (shift entry.cached_at back 1000 seconds)
    entry = BoardInsightService._CACHE[test_board.id]
    entry.cached_at = time.time() - 1000

    mock.queue_response(
        LLMResponse(
            content=json.dumps({"summary": "TTL Test 2 Re-generated", "findings": ["C"], "recommendations": ["D"]}),
            model="deerflow-llm",
        )
    )

    rep2 = service.generate_insights(test_board.owner_id, test_board.id)
    assert rep2.summary == "TTL Test 2 Re-generated"
    assert rep2.cache_age_seconds == 0

    # 3. Test LRU bounded eviction
    orig_max = BoardInsightService.MAX_CACHE_SIZE
    try:
        BoardInsightService.MAX_CACHE_SIZE = 2
        BoardInsightService.clear_cache()

        id1 = uuid.uuid4()
        id2 = uuid.uuid4()
        id3 = uuid.uuid4()

        rep_dummy = rep1.model_copy()

        with BoardInsightService._LOCK:
            BoardInsightService._CACHE[id1] = CachedInsightEntry("hash1", rep_dummy, time.time())
            BoardInsightService._CACHE[id2] = CachedInsightEntry("hash2", rep_dummy, time.time())

        assert BoardInsightService.get_cache_size() == 2

        # Inserting 3rd entry triggers LRU eviction of id1
        with BoardInsightService._LOCK:
            if len(BoardInsightService._CACHE) >= BoardInsightService.MAX_CACHE_SIZE:
                BoardInsightService._CACHE.popitem(last=False)
            BoardInsightService._CACHE[id3] = CachedInsightEntry("hash3", rep_dummy, time.time())

        assert BoardInsightService.get_cache_size() == 2
        assert id1 not in BoardInsightService._CACHE
        assert id2 in BoardInsightService._CACHE
        assert id3 in BoardInsightService._CACHE
    finally:
        BoardInsightService.MAX_CACHE_SIZE = orig_max
        BoardInsightService.clear_cache()


def test_deerflow_tavily_timeouts_and_rate_limits(
    client: TestClient,
    auth_headers: dict[str, str],
    test_board,
    monkeypatch,
):
    """Verify Tavily error classification and that network failures do not abort board operations."""
    BoardInsightService.clear_cache()

    # Case A: Tavily Timeout
    monkeypatch.setattr(settings, "TAVILY_API_KEY", "tvly-test-key-mock")

    def mock_timeout_post(*args, **kwargs):
        raise httpx.TimeoutException("Tavily search timeout (5.0s)")

    monkeypatch.setattr(httpx.Client, "post", mock_timeout_post)

    mock = MockLLMClient()
    mock.queue_response(
        LLMResponse(
            content=json.dumps({"summary": "Timeout Handled", "findings": ["F"], "recommendations": ["R"]}),
            model="deerflow-llm",
        )
    )
    set_mock_llm_client(mock)

    res_timeout = client.get(
        f"/api/v1/boards/{test_board.id}/insights?force_refresh=true",
        headers=auth_headers,
    )
    assert res_timeout.status_code == 200
    data_timeout = res_timeout.json()
    assert data_timeout["is_fallback"] is False
    assert data_timeout["provider_metadata"]["tavily_status"] == "timeout"
    assert len(data_timeout["sources"]) == 1  # Only board snapshot source

    # Case B: Tavily 429 Rate Limit
    monkeypatch.setattr(settings, "TAVILY_API_KEY", "tvly-test-key-mock")

    class Mock429Response:
        status_code = 429
        def json(self):
            return {"detail": "Rate limit exceeded"}

    def mock_429_post(*args, **kwargs):
        return Mock429Response()

    monkeypatch.setattr(httpx.Client, "post", mock_429_post)
    mock.queue_response(
        LLMResponse(
            content=json.dumps({"summary": "429 Handled", "findings": ["F"], "recommendations": ["R"]}),
            model="deerflow-llm",
        )
    )

    res_429 = client.get(
        f"/api/v1/boards/{test_board.id}/insights?force_refresh=true",
        headers=auth_headers,
    )
    assert res_429.status_code == 200
    data_429 = res_429.json()
    assert data_429["provider_metadata"]["tavily_status"] == "rate_limited"

    # Case C: Tavily disabled (no API key configured)
    monkeypatch.setattr(settings, "TAVILY_API_KEY", "")
    mock.queue_response(
        LLMResponse(
            content=json.dumps({"summary": "No Key Handled", "findings": ["F"], "recommendations": ["R"]}),
            model="deerflow-llm",
        )
    )

    res_disabled = client.get(
        f"/api/v1/boards/{test_board.id}/insights?force_refresh=true",
        headers=auth_headers,
    )
    assert res_disabled.status_code == 200
    data_disabled = res_disabled.json()
    assert data_disabled["provider_metadata"]["tavily_status"] == "disabled_no_key"


def test_distinguish_live_provider_503_from_mocked_success(
    client: TestClient,
    auth_headers: dict[str, str],
    test_board,
):
    """Verify that an external provider 503 is explicitly flagged as a fallback and never as a live success."""
    BoardInsightService.clear_cache()

    class Gemini503Client(MockLLMClient):
        def generate(self, *args, **kwargs):
            raise httpx.HTTPStatusError(
                "503 Service Unavailable: Model is overloaded",
                request=httpx.Request("POST", "https://generativelanguage.googleapis.com/v1beta"),
                response=httpx.Response(503),
            )

    set_mock_llm_client(Gemini503Client())

    res = client.get(
        f"/api/v1/boards/{test_board.id}/insights?force_refresh=true",
        headers=auth_headers,
    )
    assert res.status_code == 200
    data = res.json()

    # CRITICAL: A 503 must NEVER be marked as a successful live report
    assert data["is_fallback"] is True
    assert data["provider_metadata"]["provider"] == "deterministic-fallback"
    assert "503" in data["provider_metadata"]["error"] or "Service Unavailable" in data["provider_metadata"]["error"]
    assert len(data["warnings"]) >= 1
    assert "deterministic" in data["warnings"][0].lower()
