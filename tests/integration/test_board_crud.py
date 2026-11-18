import uuid
from fastapi.testclient import TestClient


def test_create_board(client: TestClient, auth_headers: dict[str, str]):
    response = client.post(
        "/api/v1/boards",
        headers=auth_headers,
        json={
            "name": "Mobile Redesign",
            "description": "Redesign mobile app Kanban interface",
            "theme": {"accent": "orange"},
            "initial_columns": ["Backlog", "Designing", "Ready", "Done"],
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Mobile Redesign"
    assert len(data["columns"]) == 4
    assert data["columns"][0]["title"] == "Backlog"
    assert data["columns"][0]["position"] == 0
    assert data["role"] == "owner"


def test_list_boards(client: TestClient, auth_headers: dict[str, str]):
    # Create two boards
    client.post(
        "/api/v1/boards",
        headers=auth_headers,
        json={"name": "Board Alpha", "theme": {"accent": "purple"}},
    )
    client.post(
        "/api/v1/boards",
        headers=auth_headers,
        json={"name": "Board Beta", "theme": {"accent": "orange", "is_favorite": True}},
    )

    response = client.get("/api/v1/boards", headers=auth_headers)
    assert response.status_code == 200
    boards = response.json()
    assert len(boards) >= 2

    # Test favorite filter
    fav_res = client.get("/api/v1/boards?filter=favorites", headers=auth_headers)
    assert fav_res.status_code == 200
    fav_boards = fav_res.json()
    assert all(b["is_favorite"] is True for b in fav_boards)


def test_get_board_by_id(client: TestClient, auth_headers: dict[str, str], test_board):
    response = client.get(f"/api/v1/boards/{test_board.id}", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == str(test_board.id)
    assert data["name"] == "Demo Board"
    assert len(data["columns"]) == 3


def test_update_board(client: TestClient, auth_headers: dict[str, str], test_board):
    response = client.patch(
        f"/api/v1/boards/{test_board.id}",
        headers=auth_headers,
        json={
            "name": "Updated Board Name",
            "description": "Brand new description",
            "is_favorite": True,
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Updated Board Name"
    assert data["description"] == "Brand new description"
    assert data["theme"].get("is_favorite") is True


def test_archive_board(client: TestClient, auth_headers: dict[str, str]):
    # Create board to delete
    create_res = client.post(
        "/api/v1/boards",
        headers=auth_headers,
        json={"name": "Board To Delete"},
    )
    board_id = create_res.json()["id"]

    # Delete (archive)
    del_res = client.delete(f"/api/v1/boards/{board_id}", headers=auth_headers)
    assert del_res.status_code == 204

    # Getting archived board returns 404
    get_res = client.get(f"/api/v1/boards/{board_id}", headers=auth_headers)
    assert get_res.status_code == 404
    assert get_res.json()["error"]["code"] == "not_found"
