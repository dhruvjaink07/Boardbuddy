import json
import logging
from typing import Any, Dict, List, Optional
import uuid
from sqlalchemy.orm import Session

from app.core.exceptions import BoardBuddyException, NotFoundException, ValidationException
from app.llm.base import LLMClient, LLMMessage
from app.llm.factory import get_llm_client
from app.schemas.ai import (
    GoalBoardCommitRequest,
    GoalBoardPlan,
    GoalBoardPlanRequest,
    GoalBoardPlanResponse,
)
from app.schemas.board import BoardCreate, BoardRead
from app.schemas.card import CardCreate
from app.services.board_service import BoardService
from app.services.card_service import CardService

logger = logging.getLogger(__name__)

# Temporary in-memory cache for previewed plans prior to user confirmation
_PLAN_CACHE: Dict[uuid.UUID, GoalBoardPlan] = {}

GOAL_SYSTEM_PROMPT = """You are BoardBuddy's intelligent agile project planner.
Your job is to convert messy, unstructured project goals or descriptions into a clear, structured Kanban board.
Break the user's goal down into 3 to 5 logical workflow columns (e.g., Backlog, In Progress, Review, Done) and 3 to 12 realistic, actionable task cards.
Assign sensible priorities (low, medium, high, urgent), workload estimates in minutes, and relevant labels.
Return ONLY valid JSON matching the required schema. Never include markdown code fences or conversational preamble."""


class GoalPlannerService:
    def __init__(self, db: Session, llm_client: Optional[LLMClient] = None):
        self.db = db
        self.llm_client = llm_client or get_llm_client()
        self.board_service = BoardService(db)
        self.card_service = CardService(db)

    def plan_board(
        self,
        user_id: uuid.UUID,
        request: GoalBoardPlanRequest,
    ) -> GoalBoardPlanResponse:
        messages = [
            LLMMessage(role="system", content=GOAL_SYSTEM_PROMPT),
            LLMMessage(
                role="user",
                content=f"Project description: {request.prompt}\nPreferences: {json.dumps(request.preferences or {})}",
            ),
        ]

        response_schema = GoalBoardPlan.model_json_schema()

        # Step 1: Initial Generation
        res = self.llm_client.generate(
            messages=messages,
            response_schema=response_schema,
            temperature=0.2,
        )

        plan = self._parse_and_validate_plan(res.content)

        # Step 2: One bounded repair attempt on failure
        if not plan:
            logger.warning("Initial goal-to-board JSON generation invalid, attempting repair...")
            repair_messages = list(messages)
            repair_messages.append(LLMMessage(role="assistant", content=res.content or ""))
            repair_messages.append(
                LLMMessage(
                    role="user",
                    content="The JSON output was invalid or did not conform to the schema. Please output ONLY the corrected JSON object matching the required schema.",
                )
            )
            repair_res = self.llm_client.generate(
                messages=repair_messages,
                response_schema=response_schema,
                temperature=0.0,
            )
            plan = self._parse_and_validate_plan(repair_res.content)

        # Step 3: Fallback if repair still failed
        if not plan:
            logger.error("Goal-to-board generation failed after repair attempt.")
            raise BoardBuddyException(
                code="ai_invalid_output",
                message="Failed to generate a valid board plan from the prompt. Please provide more details and try again.",
                status_code=502,
            )

        plan_id = uuid.uuid4()
        _PLAN_CACHE[plan_id] = plan

        return GoalBoardPlanResponse(
            plan_id=plan_id,
            board={
                "name": plan.board_name,
                "description": plan.board_description,
            },
            columns=plan.columns,
            cards=plan.cards,
            assumptions=plan.assumptions,
            warnings=plan.warnings,
            requires_confirmation=True,
        )

    def _parse_and_validate_plan(self, content: Optional[str]) -> Optional[GoalBoardPlan]:
        if not content:
            return None
        text = content.strip()
        if text.startswith("```"):
            lines = text.split("\n")
            if lines[0].startswith("```"):
                lines = lines[1:]
            if lines and lines[-1].strip() == "```":
                lines = lines[:-1]
            text = "\n".join(lines).strip()

        try:
            data = json.loads(text)
            return GoalBoardPlan.model_validate(data)
        except Exception as exc:
            logger.warning("Failed to parse GoalBoardPlan: %s", exc)
            return None

    def commit_plan(
        self,
        user_id: uuid.UUID,
        request: GoalBoardCommitRequest,
    ) -> BoardRead:
        if not request.confirm:
            raise ValidationException("Board creation was cancelled (confirm=false).")

        plan = _PLAN_CACHE.get(request.plan_id)
        if not plan:
            raise NotFoundException("Plan expired or not found")

        # 1. Create the Board with plan columns
        col_titles = [c.title for c in plan.columns]
        board_create = BoardCreate(
            name=plan.board_name,
            description=plan.board_description,
            theme={"accent": "orange"},
            initial_columns=col_titles,
        )
        created_board = self.board_service.create_board(user_id=user_id, data=board_create)

        # Create mapping of column title -> column ID
        col_map = {c.title.lower(): c.id for c in created_board.columns}
        default_col_id = created_board.columns[0].id

        # 2. Persist cards
        selected_temp_ids = set(request.selected_card_ids) if request.selected_card_ids else None

        for card_plan in plan.cards:
            if selected_temp_ids is not None and card_plan.temporary_id not in selected_temp_ids:
                continue

            target_col_id = col_map.get(card_plan.column_title.lower(), default_col_id)
            card_create = CardCreate(
                column_id=target_col_id,
                title=card_plan.title,
                description=card_plan.description,
                priority=card_plan.priority,
                labels=card_plan.labels,
                estimate_minutes=card_plan.estimate_minutes,
            )
            self.card_service.create_card(
                user_id=user_id,
                board_id=created_board.id,
                data=card_create,
            )

        # Clear plan from cache after successful commit
        _PLAN_CACHE.pop(request.plan_id, None)

        return self.board_service.get_board(user_id=user_id, board_id=created_board.id)
