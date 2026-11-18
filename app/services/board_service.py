from datetime import datetime, timezone
from typing import List, Optional
import uuid
from sqlalchemy import func
from sqlalchemy.orm import Session
from app.core.exceptions import NotFoundException, PermissionDeniedException
from app.db.models.activity import ActivityEvent
from app.db.models.board import Board, BoardMember
from app.db.models.card import Card
from app.db.models.column import BoardColumn
from app.db.models.user import User
from app.domain.permissions import Permission, enforce_permission
from app.schemas.board import BoardCreate, BoardOverview, BoardRead, BoardUpdate, MemberPreview
from app.schemas.column import ColumnRead
from app.services.activity_service import ActivityService


class BoardService:
    def __init__(self, db: Session):
        self.db = db
        self.activity_service = ActivityService(db)

    def get_user_role(self, user_id: uuid.UUID, board_id: uuid.UUID) -> str:
        member = (
            self.db.query(BoardMember)
            .filter(BoardMember.board_id == board_id, BoardMember.user_id == user_id)
            .first()
        )
        if not member:
            raise PermissionDeniedException("You are not a member of this board.")
        return member.role

    def create_board(self, user_id: uuid.UUID, data: BoardCreate) -> BoardRead:
        board = Board(
            name=data.name,
            description=data.description,
            theme=data.theme or {"accent": "orange"},
            owner_id=user_id,
        )
        self.db.add(board)
        self.db.flush()

        # Add owner as board member
        member = BoardMember(
            board_id=board.id,
            user_id=user_id,
            role="owner",
        )
        self.db.add(member)

        # Create initial columns
        columns: List[BoardColumn] = []
        col_names = data.initial_columns or ["To Do", "In Progress", "Done"]
        for idx, title in enumerate(col_names):
            col = BoardColumn(
                board_id=board.id,
                title=title,
                position=idx,
            )
            self.db.add(col)
            columns.append(col)

        self.activity_service.record_event(
            board_id=board.id,
            actor_id=user_id,
            event_type="board.created",
            payload={"name": board.name},
        )

        self.db.commit()
        self.db.refresh(board)

        return BoardRead(
            id=board.id,
            name=board.name,
            description=board.description,
            theme=board.theme,
            owner_id=board.owner_id,
            role="owner",
            columns=[ColumnRead.model_validate(c) for c in columns],
            created_at=board.created_at,
            updated_at=board.updated_at,
        )

    def get_board(self, user_id: uuid.UUID, board_id: uuid.UUID) -> BoardRead:
        role = self.get_user_role(user_id, board_id)
        enforce_permission(role, Permission.READ_BOARD)

        board = (
            self.db.query(Board)
            .filter(Board.id == board_id, Board.archived_at.is_(None))
            .first()
        )
        if not board:
            raise NotFoundException("Board")

        return BoardRead(
            id=board.id,
            name=board.name,
            description=board.description,
            theme=board.theme,
            owner_id=board.owner_id,
            role=role,
            columns=[ColumnRead.model_validate(c) for c in board.columns],
            created_at=board.created_at,
            updated_at=board.updated_at,
        )

    def list_boards(
        self,
        user_id: uuid.UUID,
        filter_type: str = "all",
    ) -> List[BoardOverview]:
        query = (
            self.db.query(Board, BoardMember.role)
            .join(BoardMember, BoardMember.board_id == Board.id)
            .filter(BoardMember.user_id == user_id, Board.archived_at.is_(None))
        )

        if filter_type == "recent":
            query = query.order_by(Board.updated_at.desc()).limit(10)
        else:
            query = query.order_by(Board.updated_at.desc())

        results = query.all()
        overviews: List[BoardOverview] = []

        for board, role in results:
            # Calculate cards count and progress
            active_cards = [c for c in board.cards if c.deleted_at is None]
            task_count = len(active_cards)
            done_count = len([c for c in active_cards if c.status == "done"])
            progress = int((done_count / task_count) * 100) if task_count > 0 else 0

            # Member previews
            members_preview = [
                MemberPreview(
                    id=m.user.id,
                    display_name=m.user.display_name,
                    photo_url=m.user.photo_url,
                    role=m.role,
                )
                for m in board.members[:4]
            ]

            is_fav = bool(board.theme and board.theme.get("is_favorite", False))
            if filter_type == "favorites" and not is_fav:
                continue

            overviews.append(
                BoardOverview(
                    id=board.id,
                    name=board.name,
                    description=board.description,
                    theme=board.theme,
                    role=role,
                    progress=progress,
                    task_count=task_count,
                    updated_at=board.updated_at,
                    members_preview=members_preview,
                    is_favorite=is_fav,
                )
            )

        return overviews

    def update_board(
        self,
        user_id: uuid.UUID,
        board_id: uuid.UUID,
        data: BoardUpdate,
    ) -> BoardRead:
        role = self.get_user_role(user_id, board_id)
        enforce_permission(role, Permission.UPDATE_BOARD)

        board = (
            self.db.query(Board)
            .filter(Board.id == board_id, Board.archived_at.is_(None))
            .first()
        )
        if not board:
            raise NotFoundException("Board")

        if data.name is not None:
            board.name = data.name
        if data.description is not None:
            board.description = data.description
        if data.theme is not None:
            current_theme = dict(board.theme or {})
            current_theme.update(data.theme)
            board.theme = current_theme
        if data.is_favorite is not None:
            current_theme = dict(board.theme or {})
            current_theme["is_favorite"] = data.is_favorite
            board.theme = current_theme

        board.updated_at = datetime.now(timezone.utc)

        self.activity_service.record_event(
            board_id=board.id,
            actor_id=user_id,
            event_type="board.updated",
            payload={"updates": data.model_dump(exclude_unset=True)},
        )

        self.db.commit()
        self.db.refresh(board)
        return self.get_board(user_id, board_id)

    def archive_board(self, user_id: uuid.UUID, board_id: uuid.UUID) -> None:
        role = self.get_user_role(user_id, board_id)
        enforce_permission(role, Permission.DELETE_BOARD)

        board = (
            self.db.query(Board)
            .filter(Board.id == board_id, Board.archived_at.is_(None))
            .first()
        )
        if not board:
            raise NotFoundException("Board")

        board.archived_at = datetime.now(timezone.utc)

        self.activity_service.record_event(
            board_id=board.id,
            actor_id=user_id,
            event_type="board.archived",
            payload={"name": board.name},
        )

        self.db.commit()
