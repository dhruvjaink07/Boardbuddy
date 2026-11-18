import json
import logging
from typing import Any, Dict, List, Optional
import uuid
from sqlalchemy.orm import Session

from app.core.exceptions import BoardBuddyException, ValidationException
from app.db.models.card import Card
from app.db.models.column import BoardColumn
from app.llm.base import ToolDefinition
from app.schemas.ai import (
    CreateCardToolArgs,
    ListBoardToolArgs,
    MoveCardToolArgs,
    SearchCardsToolArgs,
    UpdateCardToolArgs,
)
from app.schemas.card import CardCreate, CardMove, CardUpdate
from app.services.board_service import BoardService
from app.services.card_service import CardService

logger = logging.getLogger(__name__)

# Provider-neutral tool declarations matching 05-llm-agent.md
TOOL_DEFINITIONS = [
    ToolDefinition(
        name="create_card",
        description="Create a card in a column on the active board.",
        parameters={
            "type": "object",
            "properties": {
                "column_id": {"type": "string", "description": "Column UUID"},
                "title": {"type": "string", "minLength": 1, "maxLength": 240},
                "description": {"type": "string"},
                "priority": {
                    "type": "string",
                    "enum": ["low", "medium", "high", "urgent"],
                },
                "assignee_ids": {
                    "type": "array",
                    "items": {"type": "string"},
                },
                "estimate_minutes": {
                    "type": "integer",
                    "minimum": 1,
                    "maximum": 100000,
                },
                "labels": {
                    "type": "array",
                    "items": {"type": "string", "maxLength": 40},
                },
            },
            "required": ["column_id", "title", "priority"],
            "additionalProperties": False,
        },
    ),
    ToolDefinition(
        name="move_card",
        description="Move a card to another column and position.",
        parameters={
            "type": "object",
            "properties": {
                "card_id": {"type": "string", "description": "Card UUID"},
                "target_column_id": {
                    "type": "string",
                    "description": "Destination column UUID",
                },
                "position": {"type": "integer", "minimum": 0},
            },
            "required": ["card_id", "target_column_id"],
            "additionalProperties": False,
        },
    ),
    ToolDefinition(
        name="update_card",
        description="Update allowed fields on a card.",
        parameters={
            "type": "object",
            "properties": {
                "card_id": {"type": "string", "description": "Card UUID"},
                "title": {"type": "string", "minLength": 1, "maxLength": 240},
                "description": {"type": "string"},
                "priority": {
                    "type": "string",
                    "enum": ["low", "medium", "high", "urgent"],
                },
                "status": {"type": "string", "enum": ["todo", "in_progress", "done"]},
                "due_at": {"type": ["string", "null"], "format": "date-time"},
                "estimate_minutes": {"type": ["integer", "null"], "minimum": 1},
                "assignee_ids": {
                    "type": "array",
                    "items": {"type": "string"},
                },
                "labels": {"type": "array", "items": {"type": "string"}},
            },
            "required": ["card_id"],
            "additionalProperties": False,
        },
    ),
    ToolDefinition(
        name="list_board",
        description="Read columns and cards from the active board.",
        parameters={
            "type": "object",
            "properties": {
                "include_done": {"type": "boolean"},
                "column_id": {"type": ["string", "null"]},
                "limit": {"type": "integer", "minimum": 1, "maximum": 100},
            },
            "additionalProperties": False,
        },
    ),
    ToolDefinition(
        name="search_cards",
        description="Search cards semantically and by keyword on the active board.",
        parameters={
            "type": "object",
            "properties": {
                "query": {"type": "string", "minLength": 2, "maxLength": 500},
                "limit": {"type": "integer", "minimum": 1, "maximum": 20},
            },
            "required": ["query"],
            "additionalProperties": False,
        },
    ),
]


class AgentToolExecutor:
    """Executes agent tool calls strictly within the authorized user and board boundary."""

    def __init__(self, db: Session, user_id: uuid.UUID, board_id: uuid.UUID):
        self.db = db
        self.user_id = user_id
        self.board_id = board_id
        self.card_service = CardService(db)
        self.board_service = BoardService(db)

    def execute_tool(self, tool_name: str, arguments: Dict[str, Any]) -> Dict[str, Any]:
        try:
            handler_map = {
                "create_card": self._create_card,
                "move_card": self._move_card,
                "update_card": self._update_card,
                "list_board": self._list_board,
                "search_cards": self._search_cards,
            }

            handler = handler_map.get(tool_name)
            if not handler:
                raise ValidationException(f"Unknown tool '{tool_name}'.")

            return handler(arguments)
        except BoardBuddyException as exc:
            return {
                "status": "failed",
                "error": exc.message,
                "code": exc.code,
            }
        except Exception as exc:
            logger.exception("Unexpected error executing tool %s: %s", tool_name, exc)
            return {
                "status": "failed",
                "error": str(exc),
                "code": "internal_tool_error",
            }

    def _create_card(self, arguments: Dict[str, Any]) -> Dict[str, Any]:
        args = CreateCardToolArgs.model_validate(arguments)
        card_data = CardCreate(
            column_id=args.column_id,
            title=args.title,
            description=args.description,
            priority=args.priority,
            assignee_ids=args.assignee_ids,
            estimate_minutes=args.estimate_minutes,
            labels=args.labels,
        )
        card = self.card_service.create_card(
            user_id=self.user_id,
            board_id=self.board_id,
            data=card_data,
        )
        return {
            "status": "completed",
            "card_id": str(card.id),
            "title": card.title,
            "column_id": str(card.column_id),
            "summary": f"Created card '{card.title}' in column {card.column_id}.",
        }

    def _move_card(self, arguments: Dict[str, Any]) -> Dict[str, Any]:
        args = MoveCardToolArgs.model_validate(arguments)
        move_data = CardMove(
            target_column_id=args.target_column_id,
            position=args.position,
        )
        card = self.card_service.move_card(
            user_id=self.user_id,
            card_id=args.card_id,
            data=move_data,
        )
        return {
            "status": "completed",
            "card_id": str(card.id),
            "target_column_id": str(card.column_id),
            "new_status": card.status,
            "position": card.position,
            "summary": f"Moved card '{card.title}' to column {card.column_id} (status: {card.status}).",
        }

    def _update_card(self, arguments: Dict[str, Any]) -> Dict[str, Any]:
        args = UpdateCardToolArgs.model_validate(arguments)
        update_data = CardUpdate(
            title=args.title,
            description=args.description,
            priority=args.priority,
            status=args.status,
            due_at=args.due_at,
            estimate_minutes=args.estimate_minutes,
            assignee_ids=args.assignee_ids,
            labels=args.labels,
        )
        card = self.card_service.update_card(
            user_id=self.user_id,
            card_id=args.card_id,
            data=update_data,
        )
        return {
            "status": "completed",
            "card_id": str(card.id),
            "title": card.title,
            "summary": f"Updated card '{card.title}'.",
        }

    def _list_board(self, arguments: Dict[str, Any]) -> Dict[str, Any]:
        args = ListBoardToolArgs.model_validate(arguments)
        board = self.board_service.get_board(user_id=self.user_id, board_id=self.board_id)

        cards = self.card_service.list_cards(
            user_id=self.user_id,
            board_id=self.board_id,
            column_id=args.column_id,
            limit=args.limit,
        )
        if not args.include_done:
            cards = [c for c in cards if c.status != "done"]

        return {
            "status": "completed",
            "board_id": str(board.id),
            "name": board.name,
            "columns": [
                {"id": str(c.id), "title": c.title, "position": c.position}
                for c in board.columns
            ],
            "cards": [
                {
                    "id": str(c.id),
                    "column_id": str(c.column_id),
                    "title": c.title,
                    "status": c.status,
                    "priority": c.priority,
                    "position": c.position,
                }
                for c in cards
            ],
            "summary": f"Found {len(board.columns)} columns and {len(cards)} cards on board '{board.name}'.",
        }

    def _search_cards(self, arguments: Dict[str, Any]) -> Dict[str, Any]:
        args = SearchCardsToolArgs.model_validate(arguments)
        query_term = args.query.lower().strip()

        # Deterministic keyword search across active board
        query = (
            self.db.query(Card)
            .filter(Card.board_id == self.board_id, Card.deleted_at.is_(None))
        )
        cards = query.all()

        matches = []
        for card in cards:
            title_match = query_term in card.title.lower()
            desc_match = bool(card.description and query_term in card.description.lower())
            label_match = any(query_term in l.lower() for l in card.labels)
            if title_match or desc_match or label_match:
                matches.append({
                    "card_id": str(card.id),
                    "board_id": str(card.board_id),
                    "title": card.title,
                    "status": card.status,
                    "priority": card.priority,
                    "matched_by": "keyword",
                    "snippet": card.description[:100] if card.description else card.title,
                })
                if len(matches) >= args.limit:
                    break

        return {
            "status": "completed",
            "query": args.query,
            "total_matches": len(matches),
            "cards": matches,
            "summary": f"Found {len(matches)} matching cards for query '{args.query}'.",
        }
