"""
db.py — Database engine, session factory, and declarative Base.

Defaults to SQLite (no setup required) for development.
Set the DATABASE_URL environment variable to switch to PostgreSQL:

    DATABASE_URL=postgresql://user:password@localhost:5432/food_app

SQLite path: ./food_app.db  (relative to where uvicorn is launched)
"""

import os

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

# ---------------------------------------------------------------------------
# Engine
# ---------------------------------------------------------------------------
DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./food_app.db")

# SQLite requires check_same_thread=False when used with FastAPI's thread pool.
_connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}

engine = create_engine(DATABASE_URL, connect_args=_connect_args)

# ---------------------------------------------------------------------------
# Session factory
# ---------------------------------------------------------------------------
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


# ---------------------------------------------------------------------------
# Declarative Base — all ORM models inherit from this
# ---------------------------------------------------------------------------
class Base(DeclarativeBase):
    pass


# ---------------------------------------------------------------------------
# FastAPI dependency — yields a DB session, closes it after the request
# ---------------------------------------------------------------------------
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
