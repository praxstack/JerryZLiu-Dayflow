#!/usr/bin/env python3
"""MCP initialize checks for scripts/cloud-agent-verify.sh (unit-testable)."""

from __future__ import annotations

import json
import os
import select
import subprocess
import sys
import time


def readline_deadline(fd: int, deadline: float) -> bytes:
    """Read one newline-terminated line from an unbuffered fd, enforcing deadline per byte."""
    buf = bytearray()
    while time.monotonic() < deadline:
        remaining = deadline - time.monotonic()
        ready, _, _ = select.select([fd], [], [], max(0.0, remaining))
        if not ready:
            break
        chunk = os.read(fd, 4096)
        if not chunk:
            break
        buf.extend(chunk)
        if b"\n" in buf:
            line, _, _ = bytes(buf).partition(b"\n")
            return line + b"\n"
    raise SystemExit("MCP initialize timed out")


def parse_initialize_payload(line: bytes) -> dict:
    """Accept the first JSON line with id==1; skip leading non-JSON log lines."""
    for raw in line.splitlines():
        if not raw.strip():
            continue
        try:
            payload = json.loads(raw.decode())
        except json.JSONDecodeError:
            continue
        if payload.get("id") == 1:
            return payload
    raise SystemExit(f"no MCP initialize response in: {line[:200]!r}")


def terminate_proc(proc: subprocess.Popen[bytes]) -> None:
    if proc.poll() is None:
        proc.kill()
        try:
            proc.wait(timeout=1)
        except subprocess.TimeoutExpired:
            pass


def verify_mcp_initialize(binary: str) -> None:
    proc = subprocess.Popen(
        [binary, "mcp"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    assert proc.stdin is not None and proc.stdout is not None
    fd = proc.stdout.fileno()
    try:
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
        proc.stdin.close()

        deadline = time.monotonic() + 5
        line = readline_deadline(fd, deadline)
        payload = parse_initialize_payload(line)
        if payload.get("jsonrpc") != "2.0":
            raise SystemExit(f"unexpected MCP jsonrpc: {payload}")
        if payload.get("id") != 1:
            raise SystemExit(f"unexpected MCP id: {payload}")
        name = payload.get("result", {}).get("serverInfo", {}).get("name")
        if name != "dayflow":
            raise SystemExit(f"unexpected MCP serverInfo.name: {name!r}")
        print("MCP initialize ok")
    finally:
        terminate_proc(proc)


def _self_test() -> None:
    ok_script = (
        "import sys, time\n"
        "line = '{\"jsonrpc\":\"2.0\",\"id\":1,\"result\":{\"serverInfo\":{\"name\":\"dayflow\"}}}\\n'\n"
        "sys.stdout.write(line)\n"
        "sys.stdout.flush()\n"
        "time.sleep(30)\n"
    )
    proc = subprocess.Popen(
        [sys.executable, "-c", ok_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    assert proc.stdout is not None
    fd = proc.stdout.fileno()
    try:
        line = readline_deadline(fd, time.monotonic() + 2)
        payload = parse_initialize_payload(line)
        if payload.get("result", {}).get("serverInfo", {}).get("name") != "dayflow":
            raise SystemExit("self-test ok stub failed")
    finally:
        terminate_proc(proc)

    hang_script = (
        "import sys, time\n"
        "sys.stdout.write('{\"jsonrpc\":\"2.0\",\"id\":1,\"result\":')\n"
        "sys.stdout.flush()\n"
        "time.sleep(30)\n"
    )
    proc = subprocess.Popen(
        [sys.executable, "-c", hang_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    assert proc.stdout is not None
    fd = proc.stdout.fileno()
    try:
        try:
            readline_deadline(fd, time.monotonic() + 0.5)
            raise SystemExit("self-test partial line should time out")
        except SystemExit as exc:
            if "timed out" not in str(exc):
                raise
    finally:
        terminate_proc(proc)

    print("mcp_verify_helpers self-test ok")


def main() -> None:
    if len(sys.argv) == 2 and sys.argv[1] == "--self-test":
        _self_test()
        return
    if len(sys.argv) != 2:
        raise SystemExit(f"usage: {sys.argv[0]} <dayflow-binary>|--self-test")
    verify_mcp_initialize(sys.argv[1])


if __name__ == "__main__":
    main()
