import json
import uuid
from fastapi.testclient import TestClient

from app.llm.base import LLMResponse, ToolCall
from app.llm.factory import set_mock_llm_client
from app.llm.mock import MockLLMClient


def test_agent_list_board_tool(
    client: TestClient,
    auth_headers: dict[str, str],
    test_board,
):
    mock = MockLLMClient()
    # Step 1: Model calls list_board
    mock.queue_response(
        LLMResponse(
            content=None,
            tool_calls=[
                ToolCall(
                    id="call_list_board",
                    name="list_board",
                    arguments={"limit": 10},
                )
            ],
            model="mock",
        )
    )
    # Step 2: Model summarizes result
    mock.queue_response(
        LLMResponse(
            content="I inspected the board. It currently has 3 columns: To Do, In Progress, and Done.",
            model="mock",
        )
    )
    set_mock_llm_client(mock)

    res = client.post(
        f"/api/v1/boards/{test_board.id}/assistant/messages",
        headers=auth_headers,
        json={"message": "What columns and cards are on this board?"},
    )
    assert res.status_code == 200
    data = res.json()
    assert "conversation_id" in data
    assert "3 columns" in data["answer"]
    assert len(data["actions"]) == 1
    assert data["actions"][0]["tool"] == "list_board"
    assert data["actions"][0]["status"] == "completed"


def test_agent_create_card_tool(
    client: TestClient,
    auth_headers: dict[str, str],
    test_board,
):
    col_id = str(test_board.columns[0].id)
    mock = MockLLMClient()
    mock.queue_response(
        LLMResponse(
            content=None,
            tool_calls=[
                ToolCall(
                    id="call_create_card",
                    name="create_card",
                    arguments={
                        "column_id": col_id,
                        "title": "Agent Created Task",
                        "priority": "urgent",
                    },
                )
            ],
            model="mock",
        )
    )
    mock.queue_response(
        LLMResponse(
            content="Created task 'Agent Created Task' in your To Do column.",
            model="mock",
        )
    )
    set_mock_llm_client(mock)

    res = client.post(
        f"/api/v1/boards/{test_board.id}/assistant/messages",
        headers=auth_headers,
        json={"message": "Add an urgent task called Agent Created Task to To Do."},
    )
    assert res.status_code == 200
    data = res.json()
    assert data["actions"][0]["tool"] == "create_card"
    assert data["actions"][0]["status"] == "completed"

    # Verify task in database
    cards_res = client.get(f"/api/v1/boards/{test_board.id}/cards", headers=auth_headers)
    assert any(c["title"] == "Agent Created Task" for c in cards_res.json())


def test_agent_mutation_confirmation_flow(
    client: TestClient,
    auth_headers: dict[str, str],
    test_board,
):
    col1_id = test_board.columns[0].id
    col2_id = test_board.columns[1].id

    # Create a card first
    create_res = client.post(
        f"/api/v1/boards/{test_board.id}/cards",
        headers=auth_headers,
        json={"column_id": str(col1_id), "title": "Card To Move"},
    )
    card_id = create_res.json()["id"]

    # Ask assistant to move card with confirm_actions=False (default)
    mock = MockLLMClient()
    mock.queue_response(
        LLMResponse(
            content="I can move this card for you, but I need your confirmation first.",
            tool_calls=[
                ToolCall(
                    id="call_move",
                    name="move_card",
                    arguments={"card_id": card_id, "target_column_id": str(col2_id), "position": 0},
                )
            ],
            model="mock",
        )
    )
    set_mock_llm_client(mock)

    res = client.post(
        f"/api/v1/boards/{test_board.id}/assistant/messages",
        headers=auth_headers,
        json={"message": "Move Card To Move to In Progress", "confirm_actions": False},
    )
    assert res.status_code == 200
    data = res.json()
    assert data["requires_confirmation"] is True
    assert len(data["actions"]) == 1
    action = data["actions"][0]
    assert action["status"] == "awaiting_confirmation"
    action_id = action["action_id"]

    # Confirm the pending action
    confirm_res = client.post(
        f"/api/v1/assistant/actions/{action_id}/confirm",
        headers=auth_headers,
        json={"confirm": True},
    )
    assert confirm_res.status_code == 200
    assert confirm_res.json()["status"] == "completed"

    # Verify card was moved in DB
    card_check = client.get(f"/api/v1/cards/{card_id}", headers=auth_headers)
    assert card_check.json()["column_id"] == str(col2_id)


def test_agent_unauthorized_board_access(
    client: TestClient,
    other_auth_headers: dict[str, str],
    test_board,
):
    res = client.post(
        f"/api/v1/boards/{test_board.id}/assistant/messages",
        headers=other_auth_headers,
        json={"message": "List cards on this board."},
    )
    assert res.status_code == 403
    assert res.json()["error"]["code"] == "permission_denied"


def test_conversation_history_persistence(
    client: TestClient,
    auth_headers: dict[str, str],
    test_board,
):
    mock = MockLLMClient()
    mock.queue_response(LLMResponse(content="Hello! How can I help with your board?", model="mock"))
    set_mock_llm_client(mock)

    msg_res = client.post(
        f"/api/v1/boards/{test_board.id}/assistant/messages",
        headers=auth_headers,
        json={"message": "Hello BoardBuddy!"},
    )
    conv_id = msg_res.json()["conversation_id"]

    history_res = client.get(f"/api/v1/conversations/{conv_id}/messages", headers=auth_headers)
    assert history_res.status_code == 200
    messages = history_res.json()
    assert len(messages) == 2
    assert messages[0]["role"] == "user"
    assert messages[0]["content"] == "Hello BoardBuddy!"
    assert messages[1]["role"] == "assistant"
    assert "Hello! How can I help" in messages[1]["content"]
