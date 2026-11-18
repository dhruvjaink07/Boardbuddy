import uuid
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.db.models.board import BoardMember
from app.db.models.user import User


def test_non_member_cannot_access_board(
    client: TestClient,
    other_auth_headers: dict[str, str],
    test_board,
):
    # User B is not a member of test_board
    # 1. Read board
    get_res = client.get(f"/api/v1/boards/{test_board.id}", headers=other_auth_headers)
    assert get_res.status_code == 403
    assert get_res.json()["error"]["code"] == "permission_denied"

    # 2. Create card
    col_id = test_board.columns[0].id
    create_card_res = client.post(
        f"/api/v1/boards/{test_board.id}/cards",
        headers=other_auth_headers,
        json={"column_id": str(col_id), "title": "Unauthorized task"},
    )
    assert create_card_res.status_code == 403

    # 3. Delete board
    del_res = client.delete(f"/api/v1/boards/{test_board.id}", headers=other_auth_headers)
    assert del_res.status_code == 403


def test_viewer_role_restrictions(
    client: TestClient,
    db_session: Session,
    other_user: User,
    other_auth_headers: dict[str, str],
    test_board,
):
    # Add other_user as VIEWER
    member = BoardMember(
        board_id=test_board.id,
        user_id=other_user.id,
        role="viewer",
    )
    db_session.add(member)
    db_session.commit()

    # Viewer CAN read board
    get_res = client.get(f"/api/v1/boards/{test_board.id}", headers=other_auth_headers)
    assert get_res.status_code == 200
    assert get_res.json()["role"] == "viewer"

    # Viewer CANNOT create cards
    col_id = test_board.columns[0].id
    create_res = client.post(
        f"/api/v1/boards/{test_board.id}/cards",
        headers=other_auth_headers,
        json={"column_id": str(col_id), "title": "Should fail"},
    )
    assert create_res.status_code == 403

    # Viewer CANNOT delete board
    del_res = client.delete(f"/api/v1/boards/{test_board.id}", headers=other_auth_headers)
    assert del_res.status_code == 403


def test_editor_role_capabilities_and_limits(
    client: TestClient,
    db_session: Session,
    other_user: User,
    other_auth_headers: dict[str, str],
    test_board,
):
    # Add other_user as EDITOR
    member = BoardMember(
        board_id=test_board.id,
        user_id=other_user.id,
        role="editor",
    )
    db_session.add(member)
    db_session.commit()

    # Editor CAN create cards
    col_id = test_board.columns[0].id
    create_res = client.post(
        f"/api/v1/boards/{test_board.id}/cards",
        headers=other_auth_headers,
        json={"column_id": str(col_id), "title": "Editor task"},
    )
    assert create_res.status_code == 201
    card_id = create_res.json()["id"]

    # Editor CAN update cards
    patch_res = client.patch(
        f"/api/v1/cards/{card_id}",
        headers=other_auth_headers,
        json={"priority": "high"},
    )
    assert patch_res.status_code == 200

    # Editor CANNOT delete (archive) the board
    del_res = client.delete(f"/api/v1/boards/{test_board.id}", headers=other_auth_headers)
    assert del_res.status_code == 403
