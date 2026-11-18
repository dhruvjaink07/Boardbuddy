from fastapi.testclient import TestClient

from app.llm.base import LLMResponse
from app.llm.factory import set_mock_llm_client
from app.llm.mock import MockLLMClient


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
    # 1. Normal Deerflow Insight Generation
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
    # Verify fallback flag is set and safe deterministic report is returned without crashing
    assert fallback_data["is_fallback"] is True
    assert "deterministic" in fallback_data["provider_metadata"]["provider"]
    assert len(fallback_data["warnings"]) >= 1
