#!/usr/bin/env bash
# Verify the super-pro agent skill stack is installed globally.
# Exit 0 if all checks pass; exit 1 on any failure.
#
# Usage: bash scripts/verify-super-pro-skills.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="${HOME}/.local/bin:${HOME}/.npm-global/bin:${PATH}"

PASS=0
FAIL=0
WARN=0

ok()   { echo "  ✓ $*"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $*" >&2; FAIL=$((FAIL + 1)); }
warn() { echo "  ⚠ $*"; WARN=$((WARN + 1)); }

check_skill() {
  local name="$1"
  if [[ -f "${HOME}/.agents/skills/${name}/SKILL.md" ]]; then
    ok "skill: ${name}"
  else
    fail "skill missing: ${name} (~/.agents/skills/${name}/SKILL.md)"
  fi
}

check_cmd() {
  local cmd="$1"
  local label="${2:-$1}"
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "command: ${label}"
  else
    fail "command missing: ${label}"
  fi
}

echo "[verify-super-pro] Checking manifest exists ..."
if [[ -f "${ROOT}/.agents/super-pro-packs.json" ]]; then
  ok "manifest: .agents/super-pro-packs.json"
else
  fail "manifest missing: .agents/super-pro-packs.json"
fi

echo "[verify-super-pro] Checking key skills ..."
check_skill find-skills
check_skill improve
check_skill test-driven-development
check_skill code-review
check_skill ce-code-review
check_skill agent-browser
check_skill karpathy-guidelines
check_skill red-green-refactor
check_skill tdd
check_skill security-scan
check_skill supabase
check_skill cloudflare
check_skill aws-security

echo "[verify-super-pro] Checking gstack skills ..."
check_skill plan-ceo-review
check_skill office-hours
check_skill review

echo "[verify-super-pro] Checking tools (optional) ..."
if command -v agent-browser >/dev/null 2>&1; then
  ok "agent-browser CLI"
else
  warn "agent-browser CLI not in PATH (run install script with --with-tools)"
fi

if command -v specify >/dev/null 2>&1; then
  ok "specify CLI"
else
  warn "specify CLI not in PATH (run install script with --with-tools)"
fi

echo "[verify-super-pro] Checking skills CLI ..."
check_cmd npx "npx (skills CLI)"

if npx --yes skills@latest list -g >/dev/null 2>&1; then
  ok "skills list -g"
else
  fail "skills list -g failed"
fi

echo "[verify-super-pro] Checking global lock ..."
if [[ -f "${HOME}/.agents/.skill-lock.json" ]]; then
  ok "global lock: ~/.agents/.skill-lock.json"
else
  warn "no global lock yet (run install-super-pro-skills.sh)"
fi

SKILL_COUNT=$(find "${HOME}/.agents/skills" -maxdepth 2 -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ')
echo "[verify-super-pro] Installed skill count: ${SKILL_COUNT}"
if [[ "${SKILL_COUNT}" -ge 100 ]]; then
  ok "skill count >= 100 (${SKILL_COUNT})"
else
  warn "low skill count (${SKILL_COUNT}); expected 100+ after full install"
fi

echo ""
echo "[verify-super-pro] Results: ${PASS} passed, ${FAIL} failed, ${WARN} warnings"

if [[ "${FAIL}" -gt 0 ]]; then
  echo "[verify-super-pro] FAILED" >&2
  exit 1
fi

echo "[verify-super-pro] PASSED"
exit 0
