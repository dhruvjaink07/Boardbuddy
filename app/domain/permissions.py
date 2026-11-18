from enum import Enum
from app.core.exceptions import PermissionDeniedException


class Role(str, Enum):
    OWNER = "owner"
    EDITOR = "editor"
    VIEWER = "viewer"


class Permission(str, Enum):
    READ_BOARD = "read_board"
    UPDATE_BOARD = "update_board"
    DELETE_BOARD = "delete_board"
    INVITE_MEMBERS = "invite_members"
    MANAGE_MEMBERS = "manage_members"
    CREATE_COLUMN = "create_column"
    UPDATE_COLUMN = "update_column"
    DELETE_COLUMN = "delete_column"
    CREATE_CARD = "create_card"
    UPDATE_CARD = "update_card"
    MOVE_CARD = "move_card"
    DELETE_CARD = "delete_card"
    ADD_COMMENT = "add_comment"


ROLE_PERMISSIONS: dict[Role, set[Permission]] = {
    Role.OWNER: {
        Permission.READ_BOARD,
        Permission.UPDATE_BOARD,
        Permission.DELETE_BOARD,
        Permission.INVITE_MEMBERS,
        Permission.MANAGE_MEMBERS,
        Permission.CREATE_COLUMN,
        Permission.UPDATE_COLUMN,
        Permission.DELETE_COLUMN,
        Permission.CREATE_CARD,
        Permission.UPDATE_CARD,
        Permission.MOVE_CARD,
        Permission.DELETE_CARD,
        Permission.ADD_COMMENT,
    },
    Role.EDITOR: {
        Permission.READ_BOARD,
        Permission.CREATE_COLUMN,
        Permission.UPDATE_COLUMN,
        Permission.DELETE_COLUMN,
        Permission.CREATE_CARD,
        Permission.UPDATE_CARD,
        Permission.MOVE_CARD,
        Permission.DELETE_CARD,
        Permission.ADD_COMMENT,
    },
    Role.VIEWER: {
        Permission.READ_BOARD,
    },
}


def has_permission(role_str: str, permission: Permission) -> bool:
    try:
        role = Role(role_str)
        return permission in ROLE_PERMISSIONS.get(role, set())
    except ValueError:
        return False


def enforce_permission(role_str: str, permission: Permission) -> None:
    if not has_permission(role_str, permission):
        raise PermissionDeniedException(
            f"Role '{role_str}' does not have permission '{permission.value}'"
        )
