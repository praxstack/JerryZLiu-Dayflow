---
name: prax-mode
description: "Use when working with Prax, when invoked as /prax-mode, or when asked to work in their style."
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

Branch from `main` as `prax/<short-name>-6f4f` unless this Cloud Agent run sets another suffix.

Sync `origin` and `upstream` when they want the tree current.

Success is `main`. Leaving work only on a feature branch reads as "still on dev" even when `HEAD` is fine.

`gh pr create` often 403s on the Cloud Agent token. Use ManagePullRequest or GitHub MCP. If PR create is blocked and they asked to merge, push `main`. The token can push. Delete stale `prax/*` branches after the work is on `main`.

## Skills

Cloud Agent discovery is `~/.agents/skills`. `~/.cursor/skills` alone is not enough. If a slash command is missing, symlink or reinstall there. See `docs/super-pro-stack.md` and `scripts/install-praxstack-skills.sh`.

Reach for the skill. Don't paste it.

- `find-skills` before inventing a workflow
- OpenSpec `/opsx-propose` and `/opsx-apply` for spec-driven brownfield work
- gstack `/plan-ceo-review`, `/review`, `/qa`, `/ship`
- `/improve` must produce a patch when they asked to improve. Plans without code are not done
- `praxstack/skills-and-personas` via `scripts/install-praxstack-personas.sh`. `/kingmode` and `/apex` live there
- pstack / poteto-mode needs Desktop `/add-plugin`. Don't block Cloud work on it

## Review and verify

CodeRabbit CLI is usually `not_authenticated` here. `coderabbit auth login --agent` needs a browser. Don't wait. Review the diff yourself and continue.

Dayflow.app is macOS. This VM is Linux. Prove `dayflow-cli` and install scripts here. Don't claim the Mac app ran.

User-gated, name once, keep going: CodeRabbit OAuth, Desktop `/add-plugin`, Context7 API key, Serena MCP.

## Subagents

Fan out. Don't serialize work they asked to parallelize.

Merge their results yourself. Don't dump each report into chat.

## Cloud Agent

Trust `git branch` and `HEAD`. The Cursor status bar can show the run's original bound branch after git is already on `main`. A new run from `main` is the UI fix. Don't rewrite git to match a stale label.
