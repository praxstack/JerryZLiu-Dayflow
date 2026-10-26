# CLI fixtures

`create_fixture_db.sh` builds a tiny WAL sqlite file with two `timeline_cards`
rows on 2026-03-11, plus screenshot / batch / standup rows. Cloud Agent
install and `swift test` / `tests/test_cli.py` generate it on demand.

The generated `chunks.sqlite` is gitignored (WAL sidecars too). Do not commit
live user databases.
