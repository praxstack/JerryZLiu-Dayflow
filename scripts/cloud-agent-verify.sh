#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -f /opt/swiftly/env.sh ]]; then
  # SWIFTLY_HOME_DIR is required; PATH-only is not enough for the swiftly shims.
  export SWIFTLY_HOME_DIR="${SWIFTLY_HOME_DIR:-/opt/swiftly}"
  export SWIFTLY_BIN_DIR="${SWIFTLY_BIN_DIR:-/opt/swiftly/bin}"
  export SWIFTLY_TOOLCHAINS_DIR="${SWIFTLY_TOOLCHAINS_DIR:-/opt/swiftly/toolchains}"
  # shellcheck disable=SC1091
  source /opt/swiftly/env.sh
elif [[ -f "${HOME}/.local/share/swiftly/env.sh" ]]; then
  # shellcheck disable=SC1091
  source "${HOME}/.local/share/swiftly/env.sh"
fi

DAYFLOW_BIN="${DAYFLOW_BIN:-$ROOT/.cursor/bin/dayflow}"
FIXTURE_DB="$ROOT/tools/dayflow-cli/fixtures/chunks.sqlite"

if [[ ! -x "$DAYFLOW_BIN" ]]; then
  DAYFLOW_BIN="$ROOT/tools/dayflow-cli/.build/release/dayflow"
fi

if [[ ! -x "$DAYFLOW_BIN" ]]; then
  echo "dayflow binary not found. Run scripts/cloud-agent-install.sh first." >&2
  exit 1
fi

if [[ ! -f "$FIXTURE_DB" ]]; then
  echo "Fixture database missing at $FIXTURE_DB — generating." >&2
  bash "$ROOT/tools/dayflow-cli/fixtures/create_fixture_db.sh"
fi

export DAYFLOW_DB="$FIXTURE_DB"

echo "[verify] swift --version"
swift --version

echo "[verify] dayflow status --json"
"$DAYFLOW_BIN" status --json | python3 -m json.tool >/dev/null

echo "[verify] dayflow timeline 2026-03-11 --json"
timeline_json="$("$DAYFLOW_BIN" timeline 2026-03-11 --json)"
echo "$timeline_json" | python3 -m json.tool >/dev/null
card_count="$(echo "$timeline_json" | python3 -c 'import json,sys; print(len(json.load(sys.stdin).get("cards", [])))')"
if [[ "$card_count" -lt 2 ]]; then
  echo "Expected at least 2 timeline cards, got $card_count" >&2
  exit 1
fi

echo "[verify] dayflow search CLI --json"
search_json="$("$DAYFLOW_BIN" search CLI --json)"
echo "$search_json" | python3 -m json.tool >/dev/null
match_count="$(echo "$search_json" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(len(d.get("matches") or d.get("cards") or []))')"
if [[ "$match_count" -lt 1 ]]; then
  echo "Expected at least 1 search match for CLI, got $match_count" >&2
  exit 1
fi

echo "[verify] dayflow daily 2026-03-11 --json"
"$DAYFLOW_BIN" daily 2026-03-11 --json | python3 -m json.tool >/dev/null

echo "[verify] dayflow categories"
"$DAYFLOW_BIN" categories >/dev/null

echo "[verify] unknown command exits 2"
set +e
"$DAYFLOW_BIN" definitely-not-a-command >/dev/null 2>&1
unknown_status=$?
set -e
if [[ "$unknown_status" -ne 2 ]]; then
  echo "Expected exit 2 for unknown command, got $unknown_status" >&2
  exit 1
fi

echo "[verify] invalid date exits 2"
set +e
"$DAYFLOW_BIN" timeline not-a-date --json >/dev/null 2>&1
bad_date_status=$?
set -e
if [[ "$bad_date_status" -ne 2 ]]; then
  echo "Expected exit 2 for invalid date, got $bad_date_status" >&2
  exit 1
fi

echo "[verify] MCP initialize"
python3 - "$DAYFLOW_BIN" <<'PY'
import json, os, subprocess, sys, select
binary = sys.argv[1]
env = os.environ.copy()
proc = subprocess.Popen(
    [binary, "mcp"],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
)
assert proc.stdin is not None and proc.stdout is not None
request = {
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
        "protocolVersion": "2025-06-18",
        "capabilities": {},
        "clientInfo": {"name": "verify", "version": "0"},
    },
}
proc.stdin.write((json.dumps(request) + "\n").encode())
proc.stdin.flush()
ready, _, _ = select.select([proc.stdout], [], [], 5)
if not ready:
    proc.kill()
    raise SystemExit("MCP initialize timed out")
line = proc.stdout.readline()
proc.kill()
payload = json.loads(line.decode())
if payload.get("id") != 1:
    raise SystemExit(f"unexpected MCP id: {payload}")
name = payload.get("result", {}).get("serverInfo", {}).get("name")
if name != "dayflow":
    raise SystemExit(f"unexpected MCP serverInfo.name: {name!r}")
print("MCP initialize ok")
PY

echo "[verify] All checks passed."
