import uuid
from typing import List, Optional
from sqlalchemy.orm import Session
from app.core.exceptions import NotFoundException, ValidationException
from app.db.models.card import Card
from app.db.models.column import BoardColumn
from app.domain.permissions import Permission, enforce_permission
from app.schemas.column import ColumnCreate, ColumnRead, ColumnUpdate
from app.services.activity_service import ActivityService
from app.services.board_service import BoardService


class ColumnService:
    def __init__(self, db: Session):
        self.db = db
        self.board_service = BoardService(db)
        self.activity_service = ActivityService(db)

    def create_column(
        self,
        user_id: uuid.UUID,
        board_id: uuid.UUID,
        data: ColumnCreate,
    ) -> ColumnRead:
        role = self.board_service.get_user_role(user_id, board_id)
        enforce_permission(role, Permission.CREATE_COLUMN)

        # Calculate position if not provided
        if data.position is None:
            max_pos = (
                self.db.query(BoardColumn.position)
                .filter(BoardColumn.board_id == board_id)
                .order_by(BoardColumn.position.desc())
                .first()
            )
            position = (max_pos[0] + 1) if max_pos else 0
        else:
            position = data.position

        column = BoardColumn(
            board_id=board_id,
            title=data.title,
            position=position,
        )
        self.db.add(column)
        self.db.flush()

        self.activity_service.record_event(
            board_id=board_id,
            actor_id=user_id,
            event_type="column.created",
            payload={"column_id": str(column.id), "title": column.title},
        )

        self.db.commit()
        self.db.refresh(column)
        return ColumnRead.model_validate(column)

    def update_column(
        self,
        user_id: uuid.UUID,
        board_id: uuid.UUID,
        column_id: uuid.UUID,
        data: ColumnUpdate,
    ) -> ColumnRead:
        role = self.board_service.get_user_role(user_id, board_id)
        enforce_permission(role, Permission.UPDATE_COLUMN)

        column = (
            self.db.query(BoardColumn)
            .filter(BoardColumn.id == column_id, BoardColumn.board_id == board_id)
            .first()
        )
        if not column:
            raise NotFoundException("Column")

        if data.title is not None:
            column.title = data.title
        if data.position is not None:
            column.position = data.position

        self.activity_service.record_event(
            board_id=board_id,
            actor_id=user_id,
            event_type="column.updated",
            payload={"column_id": str(column.id), "title": column.title},
        )

        self.db.commit()
        self.db.refresh(column)
        return ColumnRead.model_validate(column)

    def reorder_columns(
        self,
        user_id: uuid.UUID,
        board_id: uuid.UUID,
        ordered_column_ids: List[uuid.UUID],
    ) -> List[ColumnRead]:
        role = self.board_service.get_user_role(user_id, board_id)
        enforce_permission(role, Permission.UPDATE_COLUMN)

        columns = (
            self.db.query(BoardColumn)
            .filter(BoardColumn.board_id == board_id)
            .all()
        )
        col_map = {c.id: c for c in columns}

        for idx, col_id in enumerate(ordered_column_ids):
            if col_id in col_map:
                col_map[col_id].position = idx

        self.activity_service.record_event(
            board_id=board_id,
            actor_id=user_id,
            event_type="columns.reordered",
            payload={"ordered_ids": [str(cid) for cid in ordered_column_ids]},
        )

        self.db.commit()
        updated_cols = (
            self.db.query(BoardColumn)
            .filter(BoardColumn.board_id == board_id)
            .order_by(BoardColumn.position)
            .all()
        )
        return [ColumnRead.model_validate(c) for c in updated_cols]

    def delete_column(
        self,
        user_id: uuid.UUID,
        board_id: uuid.UUID,
        column_id: uuid.UUID,
        move_cards_to_column_id: Optional[uuid.UUID] = None,
    ) -> None:
        role = self.board_service.get_user_role(user_id, board_id)
        enforce_permission(role, Permission.DELETE_COLUMN)

        column = (
            self.db.query(BoardColumn)
            .filter(BoardColumn.id == column_id, BoardColumn.board_id == board_id)
            .first()
        )
        if not column:
            raise NotFoundException("Column")

        active_cards = (
            self.db.query(Card)
            .filter(Card.column_id == column_id, Card.deleted_at.is_(None))
            .all()
        )

        if active_cards:
            if not move_cards_to_column_id:
                raise ValidationException(
                    "Cannot delete a non-empty column without specifying move_cards_to_column_id."
                )

            target_col = (
                self.db.query(BoardColumn)
                .filter(
                    BoardColumn.id == move_cards_to_column_id,
                    BoardColumn.board_id == board_id,
                )
                .first()
            )
            if not target_col:
                raise NotFoundException("Target column")

            # Move active cards to target column
            for card in active_cards:
                card.column_id = move_cards_to_column_id
            self.db.flush()

        self.activity_service.record_event(
            board_id=board_id,
            actor_id=user_id,
            event_type="column.deleted",
            payload={
                "column_id": str(column_id),
                "moved_cards_to": str(move_cards_to_column_id) if move_cards_to_column_id else None,
            },
        )

        self.db.delete(column)
        self.db.commit()
