import pytest
from app.core.exceptions import PermissionDeniedException
from app.domain.permissions import (
    Permission,
    Role,
    enforce_permission,
    has_permission,
)


def test_owner_permissions():
    assert has_permission(Role.OWNER, Permission.READ_BOARD) is True
    assert has_permission(Role.OWNER, Permission.UPDATE_BOARD) is True
    assert has_permission(Role.OWNER, Permission.DELETE_BOARD) is True
    assert has_permission(Role.OWNER, Permission.INVITE_MEMBERS) is True
    assert has_permission(Role.OWNER, Permission.CREATE_CARD) is True


def test_editor_permissions():
    assert has_permission(Role.EDITOR, Permission.READ_BOARD) is True
    assert has_permission(Role.EDITOR, Permission.CREATE_CARD) is True
    assert has_permission(Role.EDITOR, Permission.MOVE_CARD) is True
    # Editor cannot delete board or invite members
    assert has_permission(Role.EDITOR, Permission.DELETE_BOARD) is False
    assert has_permission(Role.EDITOR, Permission.INVITE_MEMBERS) is False


def test_viewer_permissions():
    assert has_permission(Role.VIEWER, Permission.READ_BOARD) is True
    assert has_permission(Role.VIEWER, Permission.CREATE_CARD) is False
    assert has_permission(Role.VIEWER, Permission.MOVE_CARD) is False
    assert has_permission(Role.VIEWER, Permission.DELETE_BOARD) is False


def test_enforce_permission_success():
    # Should not raise
    enforce_permission(Role.OWNER, Permission.DELETE_BOARD)
    enforce_permission(Role.EDITOR, Permission.CREATE_CARD)
    enforce_permission(Role.VIEWER, Permission.READ_BOARD)


def test_enforce_permission_failure():
    with pytest.raises(PermissionDeniedException) as exc_info:
        enforce_permission(Role.VIEWER, Permission.CREATE_CARD)
    assert exc_info.value.code == "permission_denied"

    with pytest.raises(PermissionDeniedException):
        enforce_permission(Role.EDITOR, Permission.DELETE_BOARD)

    with pytest.raises(PermissionDeniedException):
        enforce_permission("unknown_role", Permission.READ_BOARD)
