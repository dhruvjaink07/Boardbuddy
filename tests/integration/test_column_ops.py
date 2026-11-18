import uuid
from fastapi.testclient import TestClient


def test_column_crud_and_reorder(client: TestClient, auth_headers: dict[str, str], test_board):
    # 1. Add new column
    res = client.post(
        f"/api/v1/boards/{test_board.id}/columns",
        headers=auth_headers,
        json={"title": "QA Testing"},
    )
    assert res.status_code == 201
    new_col = res.json()
    assert new_col["title"] == "QA Testing"
    assert new_col["position"] == 3

    col_id = new_col["id"]

    # 2. Update column title
    patch_res = client.patch(
        f"/api/v1/boards/{test_board.id}/columns/{col_id}",
        headers=auth_headers,
        json={"title": "Verified in QA"},
    )
    assert patch_res.status_code == 200
    assert patch_res.json()["title"] == "Verified in QA"

    # 3. Get board to verify column list
    board_res = client.get(f"/api/v1/boards/{test_board.id}", headers=auth_headers)
    columns = board_res.json()["columns"]
    assert len(columns) == 4

    # 4. Reorder columns reverse
    col_ids = [c["id"] for c in reversed(columns)]
    reorder_res = client.post(
        f"/api/v1/boards/{test_board.id}/columns/reorder",
        headers=auth_headers,
        json={"ordered_column_ids": col_ids},
    )
    assert reorder_res.status_code == 200
    reordered = reorder_res.json()
    assert reordered[0]["id"] == col_ids[0]
    assert reordered[0]["position"] == 0

    # 5. Delete empty column
    del_res = client.delete(
        f"/api/v1/boards/{test_board.id}/columns/{col_id}",
        headers=auth_headers,
    )
    assert del_res.status_code == 204


def test_delete_non_empty_column_safely(
    client: TestClient,
    auth_headers: dict[str, str],
    test_board,
):
    board_res = client.get(f"/api/v1/boards/{test_board.id}", headers=auth_headers)
    columns = board_res.json()["columns"]
    source_col_id = columns[0]["id"]
    target_col_id = columns[1]["id"]

    # Create a card in source column
    card_res = client.post(
        f"/api/v1/boards/{test_board.id}/cards",
        headers=auth_headers,
        json={"column_id": source_col_id, "title": "Important task in source col"},
    )
    assert card_res.status_code == 201
    card_id = card_res.json()["id"]

    # Try deleting source column without specifying move_cards_to_column_id -> Should fail with 422
    del_fail = client.delete(
        f"/api/v1/boards/{test_board.id}/columns/{source_col_id}",
        headers=auth_headers,
    )
    assert del_fail.status_code == 422
    assert del_fail.json()["error"]["code"] == "validation_error"

    # Delete with move_cards_to_column_id
    del_success = client.delete(
        f"/api/v1/boards/{test_board.id}/columns/{source_col_id}?move_cards_to_column_id={target_col_id}",
        headers=auth_headers,
    )
    assert del_success.status_code == 204

    # Verify card was moved to target column, not deleted
    card_check = client.get(f"/api/v1/cards/{card_id}", headers=auth_headers)
    assert card_check.status_code == 200
    assert card_check.json()["column_id"] == target_col_id
