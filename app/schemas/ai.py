from datetime import datetime
from typing import Any, Dict, List, Literal, Optional
import uuid
from pydantic import BaseModel, ConfigDict, Field

ToolName = Literal[
    "create_card",
    "move_card",
    "update_card",
    "list_board",
    "search_cards",
]

PriorityType = Literal["low", "medium", "high", "urgent"]
StatusType = Literal["todo", "in_progress", "done"]


# --- Dedicated Tool Argument Schemas ---

class CreateCardToolArgs(BaseModel):
    model_config = ConfigDict(extra="forbid")
    column_id: uuid.UUID
    title: str = Field(min_length=1, max_length=240)
    description: Optional[str] = ""
    priority: PriorityType = "medium"
    assignee_ids: List[uuid.UUID] = Field(default_factory=list)
    estimate_minutes: Optional[int] = Field(default=None, ge=1, le=100000)
    labels: List[str] = Field(default_factory=list, max_length=10)


class MoveCardToolArgs(BaseModel):
    model_config = ConfigDict(extra="forbid")
    card_id: uuid.UUID
    target_column_id: uuid.UUID
    position: int = Field(default=0, ge=0)


class UpdateCardToolArgs(BaseModel):
    model_config = ConfigDict(extra="forbid")
    card_id: uuid.UUID
    title: Optional[str] = Field(default=None, min_length=1, max_length=240)
    description: Optional[str] = None
    priority: Optional[PriorityType] = None
    status: Optional[StatusType] = None
    due_at: Optional[datetime] = None
    estimate_minutes: Optional[int] = Field(default=None, ge=1, le=100000)
    assignee_ids: Optional[List[uuid.UUID]] = None
    labels: Optional[List[str]] = None


class ListBoardToolArgs(BaseModel):
    model_config = ConfigDict(extra="forbid")
    include_done: bool = True
    column_id: Optional[uuid.UUID] = None
    limit: int = Field(default=50, ge=1, le=100)


class SearchCardsToolArgs(BaseModel):
    model_config = ConfigDict(extra="forbid")
    query: str = Field(min_length=2, max_length=500)
    limit: int = Field(default=10, ge=1, le=20)


# --- Goal-To-Board Schemas ---

class GeneratedColumn(BaseModel):
    title: str = Field(min_length=1, max_length=100)
    position: int = Field(ge=0)


class GeneratedCard(BaseModel):
    temporary_id: str
    column_title: str
    title: str = Field(min_length=1, max_length=240)
    description: str = ""
    priority: PriorityType = "medium"
    estimate_minutes: Optional[int] = Field(default=None, ge=1, le=100000)
    labels: List[str] = Field(default_factory=list, max_length=10)
    due_at: Optional[str] = None


class GoalBoardPlan(BaseModel):
    board_name: str
    board_description: str = ""
    columns: List[GeneratedColumn] = Field(min_length=2, max_length=8)
    cards: List[GeneratedCard] = Field(min_length=1, max_length=60)
    assumptions: List[str] = Field(default_factory=list)
    warnings: List[str] = Field(default_factory=list)


class GoalBoardPlanRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    prompt: str = Field(min_length=5, max_length=4000)
    preferences: Optional[Dict[str, Any]] = None


class GoalBoardPlanResponse(BaseModel):
    plan_id: uuid.UUID
    board: Dict[str, str]
    columns: List[GeneratedColumn]
    cards: List[GeneratedCard]
    assumptions: List[str]
    warnings: List[str]
    requires_confirmation: bool = True


class GoalBoardCommitRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    plan_id: uuid.UUID
    selected_card_ids: Optional[List[str]] = None
    confirm: bool = True


# --- Assistant Agent Schemas ---

class AgentAction(BaseModel):
    model_config = ConfigDict(extra="forbid")
    action_id: str
    tool: ToolName
    arguments: Dict[str, Any]
    rationale: str = Field(default="", max_length=500)
    status: Literal["proposed", "awaiting_confirmation", "completed", "failed"]
    summary: Optional[str] = None


class AgentFinal(BaseModel):
    model_config = ConfigDict(extra="forbid")
    answer: str = Field(max_length=4000)
    actions: List[AgentAction] = Field(default_factory=list, max_length=12)
    assumptions: List[str] = Field(default_factory=list, max_length=8)
    warnings: List[str] = Field(default_factory=list, max_length=8)
    requires_confirmation: bool = False


class AssistantMessageRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    conversation_id: Optional[uuid.UUID] = None
    message: str = Field(min_length=1, max_length=4000)
    confirm_actions: bool = False


class AssistantMessageResponse(BaseModel):
    conversation_id: uuid.UUID
    message_id: uuid.UUID
    answer: str
    actions: List[AgentAction] = Field(default_factory=list)
    requires_confirmation: bool = False
    trace_id: str


class ActionConfirmRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    confirm: bool = True


class ActionConfirmResponse(BaseModel):
    status: str
    result: Optional[Dict[str, Any]] = None
