from datetime import datetime
from typing import Any, List, Literal, Optional
import uuid
from pydantic import BaseModel, ConfigDict, Field

PriorityType = Literal["low", "medium", "high", "urgent"]
StatusType = Literal["todo", "in_progress", "done"]


class CardCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    column_id: uuid.UUID
    title: str = Field(min_length=1, max_length=240)
    description: Optional[str] = ""
    priority: PriorityType = "medium"
    category: Optional[str] = None
    assignee_ids: List[uuid.UUID] = Field(default_factory=list)
    labels: List[str] = Field(default_factory=list)
    due_at: Optional[datetime] = None
    estimate_minutes: Optional[int] = Field(default=None, ge=1, le=100000)


class CardUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    column_id: Optional[uuid.UUID] = None
    title: Optional[str] = Field(default=None, min_length=1, max_length=240)
    description: Optional[str] = None
    priority: Optional[PriorityType] = None
    status: Optional[StatusType] = None
    category: Optional[str] = None
    progress: Optional[int] = Field(default=None, ge=0, le=100)
    assignee_ids: Optional[List[uuid.UUID]] = None
    labels: Optional[List[str]] = None
    due_at: Optional[datetime] = None
    estimate_minutes: Optional[int] = Field(default=None, ge=1, le=100000)
    position: Optional[int] = Field(default=None, ge=0)


class CardMove(BaseModel):
    model_config = ConfigDict(extra="forbid")
    target_column_id: uuid.UUID
    position: int = Field(ge=0)


class CardMoveResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    card_id: uuid.UUID
    column_id: uuid.UUID
    status: str
    position: int
    updated_at: datetime


class CardRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    board_id: uuid.UUID
    column_id: uuid.UUID
    title: str
    description: str
    status: str
    priority: str
    category: Optional[str] = None
    progress: int
    assignee_ids: List[Any] = Field(default_factory=list)
    labels: List[str] = Field(default_factory=list)
    due_at: Optional[datetime] = None
    estimate_minutes: Optional[int] = None
    position: int
    created_at: datetime
    updated_at: datetime
    completed_at: Optional[datetime] = None
