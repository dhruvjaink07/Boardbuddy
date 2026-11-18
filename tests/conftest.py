import uuid
from typing import Generator
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.api.deps import get_db
from app.core.security import create_access_token, hash_password
from app.db.base import Base
from app.db.models.board import Board, BoardMember
from app.db.models.column import BoardColumn
from app.db.models.user import User
from app.main import app

# In-memory SQLite for high-speed, isolated test execution
TEST_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(scope="session", autouse=True)
def setup_database():
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def db_session() -> Generator[Session, None, None]:
    connection = engine.connect()
    transaction = connection.begin()
    session = TestingSessionLocal(bind=connection)

    yield session

    session.close()
    transaction.rollback()
    connection.close()


@pytest.fixture
def client(db_session: Session) -> Generator[TestClient, None, None]:
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture
def test_user(db_session: Session) -> User:
    user = User(
        id=uuid.uuid4(),
        email="testuser@example.com",
        password_hash=hash_password("Password123!"),
        display_name="Test User",
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture
def test_user_token(test_user: User) -> str:
    return create_access_token(subject=str(test_user.id))


@pytest.fixture
def auth_headers(test_user_token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {test_user_token}"}


@pytest.fixture
def other_user(db_session: Session) -> User:
    user = User(
        id=uuid.uuid4(),
        email="otheruser@example.com",
        password_hash=hash_password("Password123!"),
        display_name="Other User",
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture
def other_user_token(other_user: User) -> str:
    return create_access_token(subject=str(other_user.id))


@pytest.fixture
def other_auth_headers(other_user_token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {other_user_token}"}


@pytest.fixture
def test_board(db_session: Session, test_user: User) -> Board:
    board = Board(
        id=uuid.uuid4(),
        name="Demo Board",
        description="Demo project board for testing",
        theme={"accent": "orange"},
        owner_id=test_user.id,
    )
    db_session.add(board)
    db_session.flush()

    member = BoardMember(
        board_id=board.id,
        user_id=test_user.id,
        role="owner",
    )
    db_session.add(member)

    for idx, title in enumerate(["To Do", "In Progress", "Done"]):
        col = BoardColumn(
            id=uuid.uuid4(),
            board_id=board.id,
            title=title,
            position=idx,
        )
        db_session.add(col)

    db_session.commit()
    db_session.refresh(board)
    return board
