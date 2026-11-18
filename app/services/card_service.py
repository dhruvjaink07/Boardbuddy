from datetime import datetime, timezone
import hashlib
from typing import List, Optional
import uuid
from sqlalchemy.orm import Session
from app.core.exceptions import NotFoundException, ValidationException
from app.db.models.board import BoardMember
from app.db.models.card import Card
from app.db.models.column import BoardColumn
from app.domain.permissions import Permission, enforce_permission
from app.schemas.card import CardCreate, CardMove, CardRead, CardUpdate
from app.services.activity_service import ActivityService
from app.services.board_service import BoardService


class CardService:
    def __init__(self, db: Session):
        self.db = db
        self.board_service = BoardService(db)
        self.activity_service = ActivityService(db)

    def _compute_card_hash(self, card: Card) -> str:
        content = f"{card.title}|{card.description}|{card.priority}|{card.status}|{','.join(card.labels)}"
        return hashlib.sha256(content.encode("utf-8")).hexdigest()

    def create_card(
        self,
        user_id: uuid.UUID,
        board_id: uuid.UUID,
        data: CardCreate,
    ) -> CardRead:
        role = self.board_service.get_user_role(user_id, board_id)
        enforce_permission(role, Permission.CREATE_CARD)

        # Validate column belongs to board
        col = (
            self.db.query(BoardColumn)
            .filter(BoardColumn.id == data.column_id, BoardColumn.board_id == board_id)
            .first()
        )
        if not col:
            raise ValidationException("Column does not belong to this board.")

        # Validate assignees are members of this board
        if data.assignee_ids:
            member_ids = {
                m.user_id
                for m in self.db.query(BoardMember.user_id)
                .filter(BoardMember.board_id == board_id)
                .all()
            }
            for aid in data.assignee_ids:
                if aid not in member_ids:
                    raise ValidationException(f"Assignee {aid} is not a member of this board.")

        # Compute next position in column
        max_pos = (
            self.db.query(Card.position)
            .filter(Card.column_id == data.column_id, Card.deleted_at.is_(None))
            .order_by(Card.position.desc())
            .first()
        )
        position = (max_pos[0] + 1) if max_pos else 0

        # Infer status from column title
        col_title_lower = col.title.lower()
        if "done" in col_title_lower or "complete" in col_title_lower:
            status = "done"
            completed_at = datetime.now(timezone.utc)
        elif "progress" in col_title_lower or "doing" in col_title_lower:
            status = "in_progress"
            completed_at = None
        else:
            status = "todo"
            completed_at = None

        card = Card(
            board_id=board_id,
            column_id=data.column_id,
            title=data.title,
            description=data.description or "",
            priority=data.priority,
            status=status,
            category=data.category,
            assignee_ids=[str(aid) for aid in data.assignee_ids],
            labels=data.labels,
            due_at=data.due_at,
            estimate_minutes=data.estimate_minutes,
            position=position,
            created_by=user_id,
            completed_at=completed_at,
        )
        self.db.add(card)
        self.db.flush()

        source_hash = self._compute_card_hash(card)
        self.activity_service.record_event(
            board_id=board_id,
            card_id=card.id,
            actor_id=user_id,
            event_type="card.created",
            payload={"title": card.title, "column_id": str(card.column_id)},
        )
        self.activity_service.enqueue_embedding_job(
            card_id=card.id,
            event_type="create",
            source_hash=source_hash,
        )

        self.db.commit()
        self.db.refresh(card)
        return CardRead.model_validate(card)

    def get_card(self, user_id: uuid.UUID, card_id: uuid.UUID) -> CardRead:
        card = self.db.query(Card).filter(Card.id == card_id, Card.deleted_at.is_(None)).first()
        if not card:
            raise NotFoundException("Card")

        role = self.board_service.get_user_role(user_id, card.board_id)
        enforce_permission(role, Permission.READ_BOARD)
        return CardRead.model_validate(card)

    def list_cards(
        self,
        user_id: uuid.UUID,
        board_id: uuid.UUID,
        column_id: Optional[uuid.UUID] = None,
        status: Optional[str] = None,
        priority: Optional[str] = None,
        assignee_id: Optional[uuid.UUID] = None,
        limit: int = 50,
    ) -> List[CardRead]:
        role = self.board_service.get_user_role(user_id, board_id)
        enforce_permission(role, Permission.READ_BOARD)

        query = self.db.query(Card).filter(Card.board_id == board_id, Card.deleted_at.is_(None))

        if column_id:
            query = query.filter(Card.column_id == column_id)
        if status:
            query = query.filter(Card.status == status)
        if priority:
            query = query.filter(Card.priority == priority)

        cards = query.order_by(Card.position.asc()).limit(limit).all()

        if assignee_id:
            aid_str = str(assignee_id)
            cards = [c for c in cards if aid_str in c.assignee_ids]

        return [CardRead.model_validate(c) for c in cards]

    def update_card(
        self,
        user_id: uuid.UUID,
        card_id: uuid.UUID,
        data: CardUpdate,
    ) -> CardRead:
        card = self.db.query(Card).filter(Card.id == card_id, Card.deleted_at.is_(None)).first()
        if not card:
            raise NotFoundException("Card")

        role = self.board_service.get_user_role(user_id, card.board_id)
        enforce_permission(role, Permission.UPDATE_CARD)

        if data.column_id is not None:
            col = (
                self.db.query(BoardColumn)
                .filter(BoardColumn.id == data.column_id, BoardColumn.board_id == card.board_id)
                .first()
            )
            if not col:
                raise ValidationException("Column does not belong to this board.")
            card.column_id = data.column_id

        if data.title is not None:
            card.title = data.title
        if data.description is not None:
            card.description = data.description
        if data.priority is not None:
            card.priority = data.priority
        if data.category is not None:
            card.category = data.category
        if data.progress is not None:
            card.progress = data.progress
        if data.assignee_ids is not None:
            card.assignee_ids = [str(a) for a in data.assignee_ids]
        if data.labels is not None:
            card.labels = data.labels
        if data.due_at is not None:
            card.due_at = data.due_at
        if data.estimate_minutes is not None:
            card.estimate_minutes = data.estimate_minutes
        if data.position is not None:
            card.position = data.position

        if data.status is not None:
            if data.status == "done" and card.status != "done":
                card.completed_at = datetime.now(timezone.utc)
            elif data.status != "done" and card.status == "done":
                card.completed_at = None
            card.status = data.status

        card.updated_at = datetime.now(timezone.utc)

        source_hash = self._compute_card_hash(card)
        self.activity_service.record_event(
            board_id=card.board_id,
            card_id=card.id,
            actor_id=user_id,
            event_type="card.updated",
            payload={"updates": data.model_dump(exclude_unset=True)},
        )
        self.activity_service.enqueue_embedding_job(
            card_id=card.id,
            event_type="update",
            source_hash=source_hash,
        )

        self.db.commit()
        self.db.refresh(card)
        return CardRead.model_validate(card)

    def move_card(
        self,
        user_id: uuid.UUID,
        card_id: uuid.UUID,
        data: CardMove,
    ) -> CardRead:
        card = self.db.query(Card).filter(Card.id == card_id, Card.deleted_at.is_(None)).first()
        if not card:
            raise NotFoundException("Card")

        role = self.board_service.get_user_role(user_id, card.board_id)
        enforce_permission(role, Permission.MOVE_CARD)

        target_col = (
            self.db.query(BoardColumn)
            .filter(BoardColumn.id == data.target_column_id, BoardColumn.board_id == card.board_id)
            .first()
        )
        if not target_col:
            raise ValidationException("Target column does not belong to this board.")

        source_col_id = card.column_id
        is_same_column = source_col_id == data.target_column_id

        # Shift positions in target column to make room
        target_cards = (
            self.db.query(Card)
            .filter(
                Card.column_id == data.target_column_id,
                Card.deleted_at.is_(None),
                Card.id != card.id,
            )
            .order_by(Card.position.asc())
            .all()
        )

        new_pos = max(0, min(data.position, len(target_cards)))
        target_cards.insert(new_pos, card)

        # Re-index target column cards
        for idx, c in enumerate(target_cards):
            c.position = idx

        # If moved across columns, also re-index source column
        if not is_same_column:
            source_cards = (
                self.db.query(Card)
                .filter(
                    Card.column_id == source_col_id,
                    Card.deleted_at.is_(None),
                    Card.id != card.id,
                )
                .order_by(Card.position.asc())
                .all()
            )
            for idx, c in enumerate(source_cards):
                c.position = idx

        card.column_id = data.target_column_id

        # Sync status with target column heuristics
        col_title_lower = target_col.title.lower()
        if "done" in col_title_lower or "complete" in col_title_lower:
            card.status = "done"
            card.completed_at = datetime.now(timezone.utc)
        elif "progress" in col_title_lower or "doing" in col_title_lower:
            card.status = "in_progress"
            card.completed_at = None
        else:
            card.status = "todo"
            card.completed_at = None

        card.updated_at = datetime.now(timezone.utc)

        self.activity_service.record_event(
            board_id=card.board_id,
            card_id=card.id,
            actor_id=user_id,
            event_type="card.moved",
            payload={
                "source_column_id": str(source_col_id),
                "target_column_id": str(data.target_column_id),
                "new_position": new_pos,
                "new_status": card.status,
            },
        )

        self.db.commit()
        self.db.refresh(card)
        return CardRead.model_validate(card)

    def delete_card(self, user_id: uuid.UUID, card_id: uuid.UUID) -> None:
        card = self.db.query(Card).filter(Card.id == card_id, Card.deleted_at.is_(None)).first()
        if not card:
            raise NotFoundException("Card")

        role = self.board_service.get_user_role(user_id, card.board_id)
        enforce_permission(role, Permission.DELETE_CARD)

        card.deleted_at = datetime.now(timezone.utc)

        self.activity_service.record_event(
            board_id=card.board_id,
            card_id=card.id,
            actor_id=user_id,
            event_type="card.deleted",
            payload={"title": card.title},
        )
        self.activity_service.enqueue_embedding_job(
            card_id=card.id,
            event_type="delete",
            source_hash="deleted",
        )

        self.db.commit()
