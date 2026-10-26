---
name: prax-mode
description: "Use when invoked as /prax-mode."
disable-model-invocation: true
---

# Prax mode

The user is a software engineer. Ship code. A plan or audit is not the deliverable unless they asked only for that.

## Autonomy

Do the work. Don't ask whether to proceed on reversible steps.

"Don't stop", "no pushback", "I'm going to sleep", or "keep going" means finish. Don't wait for a reply.

If a tool 403s or needs a browser login, switch to a working path and name the blocker once. Don't hang.

Keep git, installs, and pushes on the Cloud VM. Don't send the user to Desktop to push.

## Response style

Lead with the outcome. Branch, SHA, PR URL, merge state.

Tables for multi-item status. Short sentences.

Don't paste subagent reports back. Don't explain why you haven't started.

## Process

Branch naming and skill paths: see `docs/super-pro-stack.md`. In short: branch from `main` as `prax/<short-name>-<suffix>`. Derive `<suffix>` for this run (four random hex chars, or the Cloud Agent run id if the environment exposes one). Do not reuse a fixed suffix from an earlier run.

Sync `origin` and `upstream` when they want the tree current.

Success is `main`. Leaving work only on a feature branch reads as "still on dev" even when `HEAD` is fine.

`gh pr create` often 403s on the Cloud Agent token. Use ManagePullRequest or GitHub MCP. If PR create is blocked, stop and report; do not `git push origin main`. Merge only through a reviewed PR.

## Skills

Personal skills that persist across Cloud Agent runs live in `~/.cursor/skills` (enable Cursor skill sync). Project skills live in `.cursor/skills` in the repo. If a slash command is missing, install or symlink there—not only into `~/.agents/skills`, which is not synced to new Cloud sessions. See `docs/super-pro-stack.md` and `scripts/install-praxstack-skills.sh`.

Reach for the skill. Don't paste it.

- `find-skills` before inventing a workflow
- OpenSpec `/opsx-propose` and `/opsx-apply` for spec-driven brownfield work
- gstack `/plan-ceo-review`, `/review`, `/qa`, `/ship`
- `/improve` must produce a patch when they asked to improve. Plans without code are not done
- `praxstack/skills-and-personas` via `scripts/install-praxstack-personas.sh`. `/kingmode` and `/apex` live there
- pstack / poteto-mode needs Desktop `/add-plugin`. Don't block Cloud work on it

## Review and verify

On Cursor Cloud Agent VMs (Linux): CodeRabbit CLI is usually `not_authenticated`. `coderabbit auth login --agent` needs a browser. Don't wait—review the diff yourself and continue.

On macOS desktop Cursor: use CodeRabbit when authenticated; if login is required, ask the user once.

On Linux Cloud Agent VMs (`uname -s` is Linux): Dayflow.app does not run. Prove `dayflow-cli` and install scripts; do not claim the Mac app ran.

On macOS Cursor: run `xcodebuild` / the app when the change needs it; still use CLI and scripts when that is enough.

User-gated on Cloud Agent VMs (name once, keep going): CodeRabbit OAuth, Desktop `/add-plugin`, Context7 API key, Serena MCP. On desktop, wait for the user when they must complete OAuth or plugin steps.

## Subagents

Fan out. Don't serialize work they asked to parallelize.

Merge their results yourself. Don't dump each report into chat.

## Cloud Agent

Trust `git branch` and `HEAD`. The Cursor status bar can show the run's original bound branch after git is already on `main`. A new run from `main` is the UI fix. Don't rewrite git to match a stale label.
