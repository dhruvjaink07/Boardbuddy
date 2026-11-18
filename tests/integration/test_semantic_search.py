import uuid
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.db.models.search import CardEmbedding
from app.llm.embedding import set_mock_embedding_client, MockEmbeddingClient
from app.services.search.worker import EmbeddingWorker


def test_embedding_outbox_worker_and_hybrid_search(
    client: TestClient,
    db_session: Session,
    auth_headers: dict[str, str],
    other_auth_headers: dict[str, str],
    test_board,
):
    mock_emb = MockEmbeddingClient()
    set_mock_embedding_client(mock_emb)

    col_id = test_board.columns[0].id

    # 1. Create cards
    c1 = client.post(
        f"/api/v1/boards/{test_board.id}/cards",
        headers=auth_headers,
        json={
            "column_id": str(col_id),
            "title": "Onboarding Documentation Guide",
            "description": "Walkthrough guide for new engineering hires on development setup.",
            "labels": ["documentation", "onboarding"],
        },
    ).json()

    c2 = client.post(
        f"/api/v1/boards/{test_board.id}/cards",
        headers=auth_headers,
        json={
            "column_id": str(col_id),
            "title": "Database Schema Migrations",
            "description": "Configure PostgreSQL pgvector extensions and Alembic scripts.",
            "labels": ["backend", "database"],
        },
    ).json()

    # 2. Run the embedding worker to process the outbox
    worker = EmbeddingWorker(db_session, embedding_client=mock_emb)
    processed = worker.process_outbox_jobs(limit=10)
    assert processed >= 2

    # Verify embeddings exist in database
    embeddings = db_session.query(CardEmbedding).filter(CardEmbedding.board_id == test_board.id).all()
    assert len(embeddings) >= 2

    # 3. Hybrid Search on active board
    search_res = client.post(
        "/api/v1/search/cards",
        headers=auth_headers,
        json={
            "query": "the thing about onboarding",
            "board_id": str(test_board.id),
            "mode": "hybrid",
            "limit": 5,
        },
    )
    assert search_res.status_code == 200
    results = search_res.json()
    assert len(results) >= 1
    # Top match should be the onboarding documentation guide
    assert results[0]["title"] == "Onboarding Documentation Guide"
    assert "score" in results[0]
    assert results[0]["matched_by"] in ["hybrid", "semantic", "keyword"]

    # 4. Permission filtering: Other user (not member) cannot search this board
    forbidden_search = client.post(
        "/api/v1/search/cards",
        headers=other_auth_headers,
        json={
            "query": "onboarding",
            "board_id": str(test_board.id),
        },
    )
    assert forbidden_search.status_code == 403


def test_card_deletion_removes_embedding(
    client: TestClient,
    db_session: Session,
    auth_headers: dict[str, str],
    test_board,
):
    mock_emb = MockEmbeddingClient()
    set_mock_embedding_client(mock_emb)
    worker = EmbeddingWorker(db_session, embedding_client=mock_emb)

    col_id = test_board.columns[0].id

    # Create and embed
    card = client.post(
        f"/api/v1/boards/{test_board.id}/cards",
        headers=auth_headers,
        json={"column_id": str(col_id), "title": "Temporary Task To Delete"},
    ).json()
    card_id = uuid.UUID(card["id"])

    worker.process_outbox_jobs(limit=5)
    assert db_session.query(CardEmbedding).filter(CardEmbedding.card_id == card_id).count() == 1

    # Delete card
    del_res = client.delete(f"/api/v1/cards/{card_id}", headers=auth_headers)
    assert del_res.status_code == 204

    # Run worker to process delete event
    worker.process_outbox_jobs(limit=5)
    assert db_session.query(CardEmbedding).filter(CardEmbedding.card_id == card_id).count() == 0
