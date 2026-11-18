from fastapi.testclient import TestClient


def test_card_lifecycle_and_movement(
    client: TestClient,
    auth_headers: dict[str, str],
    test_board,
):
    board_res = client.get(f"/api/v1/boards/{test_board.id}", headers=auth_headers)
    cols = board_res.json()["columns"]
    todo_col = next(c for c in cols if c["title"] == "To Do")
    inprogress_col = next(c for c in cols if c["title"] == "In Progress")
    done_col = next(c for c in cols if c["title"] == "Done")

    # 1. Create card in To Do
    create_res = client.post(
        f"/api/v1/boards/{test_board.id}/cards",
        headers=auth_headers,
        json={
            "column_id": todo_col["id"],
            "title": "Build Authentication",
            "description": "JWT-based authentication flow",
            "priority": "high",
            "labels": ["security", "backend"],
            "estimate_minutes": 120,
        },
    )
    assert create_res.status_code == 201
    card = create_res.json()
    assert card["title"] == "Build Authentication"
    assert card["status"] == "todo"
    assert card["position"] == 0
    assert card["completed_at"] is None

    card_id = card["id"]

    # 2. Update card
    patch_res = client.patch(
        f"/api/v1/cards/{card_id}",
        headers=auth_headers,
        json={
            "priority": "urgent",
            "progress": 40,
        },
    )
    assert patch_res.status_code == 200
    updated_card = patch_res.json()
    assert updated_card["priority"] == "urgent"
    assert updated_card["progress"] == 40

    # 3. Move card to In Progress
    move_res = client.post(
        f"/api/v1/cards/{card_id}/move",
        headers=auth_headers,
        json={
            "target_column_id": inprogress_col["id"],
            "position": 0,
        },
    )
    assert move_res.status_code == 200
    move_data = move_res.json()
    assert move_data["column_id"] == inprogress_col["id"]
    assert move_data["status"] == "in_progress"

    # 4. Move card to Done -> should automatically set status to 'done' and record completed_at
    move_done_res = client.post(
        f"/api/v1/cards/{card_id}/move",
        headers=auth_headers,
        json={
            "target_column_id": done_col["id"],
            "position": 0,
        },
    )
    assert move_done_res.status_code == 200
    assert move_done_res.json()["status"] == "done"

    card_check = client.get(f"/api/v1/cards/{card_id}", headers=auth_headers)
    assert card_check.status_code == 200
    assert card_check.json()["status"] == "done"
    assert card_check.json()["completed_at"] is not None

    # 5. Delete card
    del_res = client.delete(f"/api/v1/cards/{card_id}", headers=auth_headers)
    assert del_res.status_code == 204

    # Verification: card should now return 404
    get_del = client.get(f"/api/v1/cards/{card_id}", headers=auth_headers)
    assert get_del.status_code == 404


def test_card_reordering_within_column(
    client: TestClient,
    auth_headers: dict[str, str],
    test_board,
):
    board_res = client.get(f"/api/v1/boards/{test_board.id}", headers=auth_headers)
    todo_col = next(c for c in board_res.json()["columns"] if c["title"] == "To Do")

    # Create 3 cards in To Do
    card_ids = []
    for i in range(3):
        res = client.post(
            f"/api/v1/boards/{test_board.id}/cards",
            headers=auth_headers,
            json={"column_id": todo_col["id"], "title": f"Card {i}"},
        )
        assert res.status_code == 201
        card_ids.append(res.json()["id"])

    # Move Card 2 (currently at position 2) to position 0
    move_res = client.post(
        f"/api/v1/cards/{card_ids[2]}/move",
        headers=auth_headers,
        json={"target_column_id": todo_col["id"], "position": 0},
    )
    assert move_res.status_code == 200
    assert move_res.json()["position"] == 0
