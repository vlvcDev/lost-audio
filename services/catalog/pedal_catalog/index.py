from __future__ import annotations

import hashlib
import sqlite3
from dataclasses import dataclass
from pathlib import Path


SCHEMA = """
CREATE TABLE IF NOT EXISTS models (
    sha256 TEXT NOT NULL,
    name TEXT NOT NULL,
    path TEXT PRIMARY KEY,
    size_bytes INTEGER NOT NULL,
    modified_ns INTEGER NOT NULL,
    source TEXT NOT NULL DEFAULT 'local',
    favorite INTEGER NOT NULL DEFAULT 0 CHECK (favorite IN (0, 1))
);
CREATE INDEX IF NOT EXISTS models_name_idx ON models(name COLLATE NOCASE);
CREATE INDEX IF NOT EXISTS models_sha256_idx ON models(sha256);
"""


@dataclass(frozen=True)
class ModelRecord:
    sha256: str
    name: str
    path: str
    size_bytes: int
    modified_ns: int
    source: str = "local"
    favorite: bool = False


def _sha256(path: Path, chunk_size: int = 1024 * 1024) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as model_file:
        while chunk := model_file.read(chunk_size):
            digest.update(chunk)
    return digest.hexdigest()


def inspect_model(path: Path, *, source: str = "local") -> ModelRecord:
    resolved = path.resolve(strict=True)
    stat = resolved.stat()
    return ModelRecord(
        sha256=_sha256(resolved),
        name=resolved.stem,
        path=str(resolved),
        size_bytes=stat.st_size,
        modified_ns=stat.st_mtime_ns,
        source=source,
    )


def upsert_model(path: Path, database: Path, *, source: str = "local") -> ModelRecord:
    record = inspect_model(path, source=source)
    database.parent.mkdir(parents=True, exist_ok=True)
    with sqlite3.connect(database) as connection:
        connection.execute("PRAGMA journal_mode=WAL")
        connection.executescript(SCHEMA)
        connection.execute(
            """
            INSERT INTO models (sha256, name, path, size_bytes, modified_ns, source)
            VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT(path) DO UPDATE SET
                sha256=excluded.sha256,
                name=excluded.name,
                size_bytes=excluded.size_bytes,
                modified_ns=excluded.modified_ns,
                source=excluded.source
            """,
            (
                record.sha256,
                record.name,
                record.path,
                record.size_bytes,
                record.modified_ns,
                record.source,
            ),
        )
    return record


def scan_models(models_dir: Path, database: Path) -> list[ModelRecord]:
    models_dir = models_dir.resolve()
    database.parent.mkdir(parents=True, exist_ok=True)
    records = [inspect_model(path) for path in sorted(models_dir.rglob("*.nam"))]

    with sqlite3.connect(database) as connection:
        connection.execute("PRAGMA journal_mode=WAL")
        connection.executescript(SCHEMA)
        connection.executemany(
            """
            INSERT INTO models (sha256, name, path, size_bytes, modified_ns, source)
            VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT(path) DO UPDATE SET
                sha256=excluded.sha256,
                name=excluded.name,
                size_bytes=excluded.size_bytes,
                modified_ns=excluded.modified_ns,
                source=excluded.source
            """,
            [
                (
                    record.sha256,
                    record.name,
                    record.path,
                    record.size_bytes,
                    record.modified_ns,
                    record.source,
                )
                for record in records
            ],
        )
        indexed_paths = {record.path for record in records}
        existing_paths = connection.execute("SELECT path FROM models").fetchall()
        stale_paths = [
            (path,)
            for (path,) in existing_paths
            if Path(path).is_relative_to(models_dir) and path not in indexed_paths
        ]
        connection.executemany("DELETE FROM models WHERE path = ?", stale_paths)
    return records


def list_models(database: Path, *, query: str = "") -> list[ModelRecord]:
    if not database.exists():
        return []
    pattern = f"%{query}%"
    with sqlite3.connect(database) as connection:
        connection.executescript(SCHEMA)
        rows = connection.execute(
            """
            SELECT sha256, name, path, size_bytes, modified_ns, source, favorite
            FROM models
            WHERE name LIKE ? COLLATE NOCASE
            ORDER BY favorite DESC, name COLLATE NOCASE, path
            """,
            (pattern,),
        ).fetchall()
    return [
        ModelRecord(
            sha256=row[0],
            name=row[1],
            path=row[2],
            size_bytes=row[3],
            modified_ns=row[4],
            source=row[5],
            favorite=bool(row[6]),
        )
        for row in rows
    ]
