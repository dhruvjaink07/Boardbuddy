from typing import Annotated, List
import uuid
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.exceptions import NotFoundException, PermissionDeniedException
from app.db.models.conversation import Conversation, Message
from app.db.models.user import User
from app.db.session import get_db
from app.schemas.ai import (
    ActionConfirmRequest,
    ActionConfirmResponse,
    AssistantMessageRequest,
    AssistantMessageResponse,
)
from app.services.agent.agent_service import AgentService

router = APIRouter(tags=["AI Assistant"])


@router.post(
    "/boards/{board_id}/assistant/messages",
    response_model=AssistantMessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Send a message to the AI assistant for the active board",
)
def send_assistant_message(
    board_id: uuid.UUID,
    request: AssistantMessageRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> AssistantMessageResponse:
    service = AgentService(db)
    return service.handle_message(
        user_id=current_user.id,
        board_id=board_id,
        request=request,
    )


@router.post(
    "/assistant/actions/{action_id}/confirm",
    response_model=ActionConfirmResponse,
    status_code=status.HTTP_200_OK,
    summary="Confirm or cancel an action requiring explicit user confirmation",
)
def confirm_action(
    action_id: str,
    request: ActionConfirmRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> ActionConfirmResponse:
    service = AgentService(db)
    return service.confirm_action(
        user_id=current_user.id,
        action_id=action_id,
        request=request,
    )


@router.get(
    "/conversations/{conversation_id}/messages",
    status_code=status.HTTP_200_OK,
    summary="Retrieve conversation history for a given conversation",
)
def get_conversation_messages(
    conversation_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    conv = (
        db.query(Conversation)
        .filter(Conversation.id == conversation_id, Conversation.user_id == current_user.id)
        .first()
    )
    if not conv:
        raise NotFoundException("Conversation")

    messages = (
        db.query(Message)
        .filter(Message.conversation_id == conversation_id)
        .order_by(Message.created_at.asc())
        .all()
    )

    return [
        {
            "id": str(m.id),
            "role": m.role,
            "content": m.content,
            "structured_content": m.structured_content,
            "created_at": m.created_at.isoformat(),
        }
        for m in messages
    ]
