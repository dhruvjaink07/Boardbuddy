import json
import uuid
from fastapi.testclient import TestClient
from app.llm.base import LLMResponse
from app.llm.factory import get_llm_client, set_mock_llm_client
from app.llm.mock import MockLLMClient


def test_goal_to_board_plan_and_commit(client: TestClient, auth_headers: dict[str, str]):
    # Ensure mock client is active
    mock = MockLLMClient()
    set_mock_llm_client(mock)

    # 1. Generate plan preview
    plan_res = client.post(
        "/api/v1/ai/boards/plan",
        headers=auth_headers,
        json={
            "prompt": "Launch a campus event registration app in three weeks.",
            "preferences": {"column_count": "auto"},
        },
    )
    assert plan_res.status_code == 200
    plan_data = plan_res.json()
    assert "plan_id" in plan_data
    assert plan_data["requires_confirmation"] is True
    assert len(plan_data["columns"]) >= 2
    assert len(plan_data["cards"]) >= 1

    plan_id = plan_data["plan_id"]

    # 2. Commit plan to database
    commit_res = client.post(
        "/api/v1/ai/boards/commit",
        headers=auth_headers,
        json={
            "plan_id": plan_id,
            "confirm": True,
        },
    )
    assert commit_res.status_code == 201
    board_data = commit_res.json()
    assert board_data["name"] == plan_data["board"]["name"]
    assert len(board_data["columns"]) == len(plan_data["columns"])

    # Verify cards were created on the board
    board_id = board_data["id"]
    cards_res = client.get(f"/api/v1/boards/{board_id}/cards", headers=auth_headers)
    assert cards_res.status_code == 200
    created_cards = cards_res.json()
    assert len(created_cards) == len(plan_data["cards"])


def test_goal_plan_commit_cancel(client: TestClient, auth_headers: dict[str, str]):
    mock = MockLLMClient()
    set_mock_llm_client(mock)

    plan_res = client.post(
        "/api/v1/ai/boards/plan",
        headers=auth_headers,
        json={"prompt": "Build an open-source analytics dashboard"},
    )
    plan_id = plan_res.json()["plan_id"]

    # Cancel commit
    cancel_res = client.post(
        "/api/v1/ai/boards/commit",
        headers=auth_headers,
        json={"plan_id": plan_id, "confirm": False},
    )
    assert cancel_res.status_code == 422
    assert cancel_res.json()["error"]["code"] == "validation_error"


def test_goal_plan_repair_on_invalid_json(client: TestClient, auth_headers: dict[str, str]):
    mock = MockLLMClient()
    # 1st call returns broken JSON
    mock.queue_response(
        LLMResponse(content="Here is your plan: {board_name: missing_quotes", model="mock")
    )
    # 2nd call (repair) returns valid JSON
    valid_plan = {
        "board_name": "Repaired Plan Board",
        "board_description": "Clean repaired JSON",
        "columns": [
            {"title": "To Do", "position": 0},
            {"title": "Done", "position": 1},
        ],
        "cards": [
            {
                "temporary_id": "tmp-1",
                "column_title": "To Do",
                "title": "Repaired Card",
                "priority": "low",
            }
        ],
    }
    mock.queue_response(
        LLMResponse(content=json.dumps(valid_plan), model="mock")
    )
    set_mock_llm_client(mock)

    plan_res = client.post(
        "/api/v1/ai/boards/plan",
        headers=auth_headers,
        json={"prompt": "Fix broken project setup"},
    )
    assert plan_res.status_code == 200
    assert plan_res.json()["board"]["name"] == "Repaired Plan Board"
