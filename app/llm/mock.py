import json
from typing import Any, Dict, List, Optional
from app.llm.base import LLMClient, LLMMessage, LLMResponse, ToolCall, ToolDefinition


class MockLLMClient(LLMClient):
    """Predictable, deterministic mock client for test suites and offline operation."""

    def __init__(self, canned_responses: Optional[List[LLMResponse]] = None):
        self.canned_responses = list(canned_responses) if canned_responses else []
        self.call_history: List[Dict[str, Any]] = []

    def queue_response(self, response: LLMResponse) -> None:
        self.canned_responses.append(response)

    def generate(
        self,
        messages: List[LLMMessage],
        tools: Optional[List[ToolDefinition]] = None,
        response_schema: Optional[Dict[str, Any]] = None,
        temperature: Optional[float] = None,
    ) -> LLMResponse:
        self.call_history.append({
            "messages": messages,
            "tools": tools,
            "response_schema": response_schema,
            "temperature": temperature,
        })

        if self.canned_responses:
            return self.canned_responses.pop(0)

        last_user_message = next(
            (m.content for m in reversed(messages) if m.role == "user" and m.content),
            "",
        )

        # Default intelligent fallback response for Goal-to-Board
        if response_schema or "goal" in last_user_message.lower() or "plan" in last_user_message.lower():
            sample_plan = {
                "board_name": "Project Launch Plan",
                "board_description": "Auto-generated structured board from prompt",
                "columns": [
                    {"title": "To Do", "position": 0},
                    {"title": "In Progress", "position": 1},
                    {"title": "Review", "position": 2},
                    {"title": "Done", "position": 3},
                ],
                "cards": [
                    {
                        "temporary_id": "tmp-1",
                        "column_title": "To Do",
                        "title": "Define project scope & requirements",
                        "description": "Outline deliverables and success metrics",
                        "priority": "high",
                        "estimate_minutes": 120,
                        "labels": ["planning"],
                        "due_at": None,
                    },
                    {
                        "temporary_id": "tmp-2",
                        "column_title": "To Do",
                        "title": "Design UI wireframes",
                        "description": "Draft component mockups and user flow",
                        "priority": "medium",
                        "estimate_minutes": 180,
                        "labels": ["design"],
                        "due_at": None,
                    },
                    {
                        "temporary_id": "tmp-3",
                        "column_title": "In Progress",
                        "title": "Setup development environment",
                        "description": "Initialize repository and base configurations",
                        "priority": "urgent",
                        "estimate_minutes": 60,
                        "labels": ["setup"],
                        "due_at": None,
                    },
                ],
                "assumptions": ["Standard 4-column Kanban workflow chosen."],
                "warnings": [],
            }
            return LLMResponse(
                content=json.dumps(sample_plan),
                model="mock-gemini",
                finish_reason="stop",
            )

        # Default fallback text
        return LLMResponse(
            content="I have reviewed your request and inspected the board. Everything is in order.",
            model="mock-gemini",
            finish_reason="stop",
        )
