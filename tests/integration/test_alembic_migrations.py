import os
import tempfile
import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, inspect


def test_alembic_upgrade_downgrade():
    """Verify that Alembic migrations run cleanly to head and can downgrade without error."""
    with tempfile.NamedTemporaryFile(suffix=".db") as tmp:
        db_url = f"sqlite:///{tmp.name}"
        alembic_cfg = Config("alembic.ini")
        alembic_cfg.set_main_option("sqlalchemy.url", db_url)

        # 1. Upgrade to head
        command.upgrade(alembic_cfg, "head")

        # Check that core tables exist
        engine = create_engine(db_url)
        inspector = inspect(engine)
        tables = set(inspector.get_table_names())
        assert "users" in tables
        assert "boards" in tables
        assert "board_columns" in tables
        assert "cards" in tables
        assert "card_embeddings" in tables
        assert "embedding_outbox" in tables
        assert "activity_events" in tables
        assert "conversations" in tables
        assert "messages" in tables

        # 2. Downgrade to base
        command.downgrade(alembic_cfg, "base")

        # Check that tables were removed
        inspector = inspect(engine)
        assert "cards" not in inspector.get_table_names()

        # 3. Re-upgrade to head
        command.upgrade(alembic_cfg, "head")
        inspector = inspect(engine)
        assert "cards" in inspector.get_table_names()
