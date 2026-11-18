from pathlib import Path

from sqlalchemy import create_engine, event
from sqlalchemy.engine import make_url
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from app.core.config import settings, BASE_DIR

# Resolve relative SQLite paths against the project directory, never the caller's CWD.
_database_url = make_url(settings.DATABASE_URL)
_is_sqlite = _database_url.get_backend_name() == "sqlite"
if _is_sqlite:
    _database_name = _database_url.database
    if _database_name and _database_name != ":memory:" and not _database_name.startswith("file:"):
        _db_path = Path(_database_name).expanduser()
        if not _db_path.is_absolute():
            _db_path = BASE_DIR / _db_path
        _db_path = _db_path.resolve()
        _db_path.parent.mkdir(parents=True, exist_ok=True)
        _database_url = _database_url.set(database=_db_path.as_posix())

_connect_args = {"check_same_thread": False, "timeout": 30} if _is_sqlite else {}
engine = create_engine(
    _database_url,
    connect_args=_connect_args,
    echo=settings.DEBUG,
    pool_pre_ping=not _is_sqlite,
)

if _is_sqlite:
    @event.listens_for(engine, "connect")
    def set_sqlite_pragma(dbapi_connection, connection_record):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.execute("PRAGMA journal_mode=WAL")
        cursor.execute("PRAGMA busy_timeout=30000")
        cursor.close()

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def begin_write_transaction(db):
    bind = db.get_bind()
    if bind.dialect.name == "sqlite":
        db.connection().exec_driver_sql("BEGIN IMMEDIATE")


def init_db():
    from app.models import (  # noqa: F401
        user, expert, province, center, activity,
        product, purchase, payment, permit, audit, salesops
    )
    Base.metadata.create_all(bind=engine)
