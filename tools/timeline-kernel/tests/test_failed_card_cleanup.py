#!/usr/bin/env python3
"""SQLite check for historical Processing failed cleanup (JerryZLiu/Dayflow#285).

Reads the SQL string from TimelineReplacementPolicy.swift so the predicate
cannot drift from what StorageManager.migrate() runs.
"""
from __future__ import annotations

import re
import sqlite3
import sys
import tempfile
from pathlib import Path

KERNEL = Path(__file__).resolve().parents[1]
POLICY = KERNEL / "Sources" / "DayflowTimeline" / "TimelineReplacementPolicy.swift"


def load_sql() -> str:
    text = POLICY.read_text()
    match = re.search(
        r'static var historicalDuplicateFailedCardsSQL: String \{\s+"""(.*?)"""',
        text,
        re.S,
    )
    if not match:
        raise SystemExit("could not find historicalDuplicateFailedCardsSQL")
    sql = match.group(1).strip()
    # Swift string interpolation in source; runtime uses processingFailedTitle.
    return sql.replace("\\(processingFailedTitle)", "Processing failed")


def main() -> None:
    sql = load_sql()
    with tempfile.NamedTemporaryFile(suffix=".sqlite") as handle:
        db = sqlite3.connect(handle.name)
        db.execute(
            """
            CREATE TABLE timeline_cards (
              id INTEGER PRIMARY KEY,
              day TEXT,
              start_ts INTEGER,
              end_ts INTEGER,
              title TEXT,
              is_deleted INTEGER DEFAULT 0
            )
            """
        )
        rows = [
            (10, "2026-06-16", 100, 200, "Processing failed", 0),
            (11, "2026-06-16", 100, 200, "Processing failed", 0),
            (12, "2026-06-16", 200, 300, "Processing failed", 0),
            (13, "2026-06-16", 100, 200, "Wrote tests", 0),
            (14, "2026-06-16", 100, 200, "Processing failed", 1),
        ]
        db.executemany(
            "INSERT INTO timeline_cards VALUES (?, ?, ?, ?, ?, ?)",
            rows,
        )
        db.execute(sql)
        live_failed = list(
            db.execute(
                """
                SELECT id FROM timeline_cards
                WHERE is_deleted = 0 AND title = 'Processing failed'
                ORDER BY id
                """
            )
        )
        assert [row[0] for row in live_failed] == [10, 12], live_failed
        wrote = db.execute(
            "SELECT is_deleted FROM timeline_cards WHERE id = 13"
        ).fetchone()
        assert wrote == (0,)
        already = db.execute(
            "SELECT is_deleted FROM timeline_cards WHERE id = 14"
        ).fetchone()
        assert already == (1,)
        db.close()
    print("ok")


if __name__ == "__main__":
    main()
