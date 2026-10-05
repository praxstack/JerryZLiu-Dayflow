#!/usr/bin/env bash
# Fail if origin/main does not contain JerryZLiu/Dayflow main.
set -euo pipefail

UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/JerryZLiu/Dayflow.git}"
UPSTREAM_REF="${UPSTREAM_REF:-refs/heads/main}"
ORIGIN_REF="${ORIGIN_REF:-refs/remotes/origin/main}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! git remote get-url upstream >/dev/null 2>&1; then
  git remote add upstream "$UPSTREAM_URL"
fi

git fetch --quiet origin main
git fetch --quiet upstream main

origin_sha="$(git rev-parse origin/main)"
upstream_sha="$(git rev-parse upstream/main)"

echo "origin/main   $origin_sha"
echo "upstream/main $upstream_sha"

if git merge-base --is-ancestor "$upstream_sha" "$origin_sha"; then
  echo "OK: origin/main contains upstream/main"
  exit 0
fi

echo "FAIL: origin/main is behind upstream/main" >&2
echo "Missing commits:" >&2
git log --oneline "$origin_sha".."$upstream_sha" | head -20 >&2
exit 1
