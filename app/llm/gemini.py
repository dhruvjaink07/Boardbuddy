import json
import logging
from typing import Any, Dict, List, Optional
import httpx

from app.core.config import settings
from app.core.exceptions import BoardBuddyException
from app.llm.base import LLMClient, LLMMessage, LLMResponse, ToolCall, ToolDefinition

logger = logging.getLogger(__name__)


class GeminiClient(LLMClient):
    BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models"

    def __init__(
        self,
        api_key: Optional[str] = None,
        model: Optional[str] = None,
        timeout: Optional[int] = None,
    ):
        self.api_key = api_key or settings.GEMINI_API_KEY
        self.model = model or settings.GEMINI_MODEL
        self.timeout = timeout or settings.LLM_TIMEOUT_SECONDS

    def _convert_messages(
        self, messages: List[LLMMessage]
    ) -> tuple[Optional[str], List[Dict[str, Any]]]:
        system_instruction: Optional[str] = None
        contents: List[Dict[str, Any]] = []

        for msg in messages:
            if msg.role == "system":
                system_instruction = msg.content
            elif msg.role == "user":
                contents.append({
                    "role": "user",
                    "parts": [{"text": msg.content or ""}],
                })
            elif msg.role == "assistant":
                parts: List[Dict[str, Any]] = []
                if msg.content:
                    parts.append({"text": msg.content})
                if msg.tool_calls:
                    for tc in msg.tool_calls:
                        parts.append({
                            "functionCall": {
                                "name": tc.name,
                                "args": tc.arguments,
                            }
                        })
                contents.append({"role": "model", "parts": parts})
            elif msg.role == "tool":
                contents.append({
                    "role": "function",
                    "parts": [{
                        "functionResponse": {
                            "name": msg.tool_call_id or "tool_result",
                            "response": {"result": msg.content},
                        }
                    }],
                })

        return system_instruction, contents

    def generate(
        self,
        messages: List[LLMMessage],
        tools: Optional[List[ToolDefinition]] = None,
        response_schema: Optional[Dict[str, Any]] = None,
        temperature: Optional[float] = None,
    ) -> LLMResponse:
        if not self.api_key:
            raise BoardBuddyException(
                code="ai_service_unavailable",
                message="Gemini API key is not configured.",
                status_code=503,
            )

        system_instruction, contents = self._convert_messages(messages)

        payload: Dict[str, Any] = {"contents": contents}

        if system_instruction:
            payload["systemInstruction"] = {
                "parts": [{"text": system_instruction}]
            }

        generation_config: Dict[str, Any] = {
            "temperature": temperature if temperature is not None else settings.LLM_TEMPERATURE,
        }

        if response_schema:
            generation_config["responseMimeType"] = "application/json"
            generation_config["responseSchema"] = response_schema

        payload["generationConfig"] = generation_config

        if tools:
            function_declarations = [
                {
                    "name": t.name,
                    "description": t.description,
                    "parameters": t.parameters,
                }
                for t in tools
            ]
            payload["tools"] = [{"functionDeclarations": function_declarations}]

        url = f"{self.BASE_URL}/{self.model}:generateContent?key={self.api_key}"

        try:
            with httpx.Client(timeout=self.timeout) as client:
                res = client.post(url, json=payload)
                if res.status_code != 200:
                    logger.error("Gemini API error %d: %s", res.status_code, res.text)
                    raise BoardBuddyException(
                        code="ai_provider_error",
                        message=f"Gemini API returned status {res.status_code}: {res.text[:200]}",
                        status_code=502,
                    )
                data = res.json()
        except httpx.TimeoutException:
            logger.error("Gemini API request timed out after %d seconds.", self.timeout)
            raise BoardBuddyException(
                code="ai_timeout",
                message="AI provider request timed out. Please retry.",
                status_code=504,
            )
        except httpx.RequestError as exc:
            logger.error("Gemini API network connection failed: %s", exc)
            raise BoardBuddyException(
                code="ai_network_error",
                message="Failed to connect to AI provider.",
                status_code=502,
            )

        # Parse response candidates
        candidates = data.get("candidates", [])
        if not candidates:
            return LLMResponse(content="", model=self.model, finish_reason="no_candidates")

        first_cand = candidates[0]
        content_obj = first_cand.get("content", {})
        parts = content_obj.get("parts", [])

        text_content_list: List[str] = []
        tool_calls: List[ToolCall] = []

        for p in parts:
            if "text" in p:
                text_content_list.append(p["text"])
            if "functionCall" in p:
                fc = p["functionCall"]
                tool_calls.append(
                    ToolCall(
                        id=f"call_{fc.get('name')}",
                        name=fc.get("name", ""),
                        arguments=fc.get("args", {}),
                    )
                )

        usage = data.get("usageMetadata")

        return LLMResponse(
            content="\n".join(text_content_list) if text_content_list else None,
            tool_calls=tool_calls,
            usage=usage,
            model=self.model,
            finish_reason=first_cand.get("finishReason"),
        )
