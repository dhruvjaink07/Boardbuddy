from datetime import datetime
from typing import Any, List, Optional
import uuid
from pydantic import BaseModel, ConfigDict, Field
from app.schemas.column import ColumnRead


class BoardCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    name: str = Field(min_length=1, max_length=160)
    description: Optional[str] = None
    theme: Optional[dict[str, Any]] = None
    initial_columns: Optional[List[str]] = Field(
        default=["To Do", "In Progress", "Done"],
        max_length=10,
    )


class BoardUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    name: Optional[str] = Field(default=None, min_length=1, max_length=160)
    description: Optional[str] = None
    theme: Optional[dict[str, Any]] = None
    is_favorite: Optional[bool] = None


class MemberPreview(BaseModel):
    id: uuid.UUID
    display_name: Optional[str] = None
    photo_url: Optional[str] = None
    role: str


class BoardOverview(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    name: str
    description: Optional[str] = None
    theme: Optional[dict[str, Any]] = None
    role: str
    progress: int = 0
    task_count: int = 0
    updated_at: datetime
    members_preview: List[MemberPreview] = Field(default_factory=list)
    is_favorite: bool = False


class BoardRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    name: str
    description: Optional[str] = None
    theme: Optional[dict[str, Any]] = None
    owner_id: uuid.UUID
    role: Optional[str] = "owner"
    columns: List[ColumnRead] = Field(default_factory=list)
    created_at: datetime
    updated_at: datetime
