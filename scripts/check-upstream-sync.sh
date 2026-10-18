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

origin_branch="${ORIGIN_REF#refs/remotes/origin/}"
upstream_branch="${UPSTREAM_REF#refs/heads/}"

git fetch --quiet origin "$origin_branch"
git fetch --quiet upstream "$upstream_branch"

origin_sha="$(git rev-parse "$ORIGIN_REF")"
upstream_sha="$(git rev-parse "upstream/$upstream_branch")"

echo "origin/$origin_branch   $origin_sha"
echo "upstream/$upstream_branch $upstream_sha"

if git merge-base --is-ancestor "$upstream_sha" "$origin_sha"; then
  echo "OK: origin/main contains upstream/main"
  exit 0
fi

echo "FAIL: origin/main is behind upstream/main" >&2
echo "Missing commits:" >&2
git log --oneline --max-count=20 "$origin_sha".."$upstream_sha" >&2
exit 1
