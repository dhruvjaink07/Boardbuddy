from datetime import datetime
from typing import List, Optional
import uuid
from pydantic import BaseModel, ConfigDict, Field


class ColumnCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    title: str = Field(min_length=1, max_length=100)
    position: Optional[int] = Field(default=None, ge=0)


class ColumnUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    title: Optional[str] = Field(default=None, min_length=1, max_length=100)
    position: Optional[int] = Field(default=None, ge=0)


class ColumnReorder(BaseModel):
    model_config = ConfigDict(extra="forbid")
    ordered_column_ids: List[uuid.UUID] = Field(min_length=1)


class ColumnRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    board_id: uuid.UUID
    title: str
    position: int
    created_at: datetime
    updated_at: datetime
