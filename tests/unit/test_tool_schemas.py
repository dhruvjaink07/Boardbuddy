import uuid
import pytest
from pydantic import ValidationError

from app.schemas.ai import (
    CreateCardToolArgs,
    GoalBoardPlan,
    ListBoardToolArgs,
    MoveCardToolArgs,
    SearchCardsToolArgs,
    UpdateCardToolArgs,
)


def test_create_card_tool_args_validation():
    col_id = uuid.uuid4()
    # Valid
    args = CreateCardToolArgs(
        column_id=col_id,
        title="Valid Task",
        priority="high",
        estimate_minutes=90,
    )
    assert args.title == "Valid Task"
    assert args.priority == "high"

    # Missing title
    with pytest.raises(ValidationError):
        CreateCardToolArgs(column_id=col_id, priority="high")  # type: ignore

    # Unknown priority
    with pytest.raises(ValidationError):
        CreateCardToolArgs(column_id=col_id, title="Task", priority="super_urgent")  # type: ignore

    # Extra forbidden field
    with pytest.raises(ValidationError):
        CreateCardToolArgs(
            column_id=col_id,
            title="Task",
            priority="low",
            extra_hack="dangerous",  # type: ignore
        )


def test_move_card_tool_args_validation():
    card_id = uuid.uuid4()
    col_id = uuid.uuid4()

    valid = MoveCardToolArgs(card_id=card_id, target_column_id=col_id, position=2)
    assert valid.position == 2

    # Negative position
    with pytest.raises(ValidationError):
        MoveCardToolArgs(card_id=card_id, target_column_id=col_id, position=-1)


def test_search_cards_tool_args_validation():
    valid = SearchCardsToolArgs(query="documentation", limit=5)
    assert valid.limit == 5

    # Query too short (<2 chars)
    with pytest.raises(ValidationError):
        SearchCardsToolArgs(query="a")

    # Limit too large (>20)
    with pytest.raises(ValidationError):
        SearchCardsToolArgs(query="valid query", limit=50)


def test_goal_board_plan_validation():
    valid_data = {
        "board_name": "Event Launch",
        "board_description": "Launch college tech fest",
        "columns": [
            {"title": "To Do", "position": 0},
            {"title": "In Progress", "position": 1},
            {"title": "Done", "position": 2},
        ],
        "cards": [
            {
                "temporary_id": "tmp-1",
                "column_title": "To Do",
                "title": "Book Venue",
                "priority": "urgent",
            }
        ],
    }
    plan = GoalBoardPlan.model_validate(valid_data)
    assert len(plan.columns) == 3
    assert plan.cards[0].title == "Book Venue"

    # Less than 2 columns fails
    invalid_data = dict(valid_data)
    invalid_data["columns"] = [{"title": "Only One", "position": 0}]
    with pytest.raises(ValidationError):
        GoalBoardPlan.model_validate(invalid_data)
