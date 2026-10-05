# Design

## Context
Automate fork-vs-upstream lag detection without rewriting git history.

## Goals / Non-Goals
- Goals: ship a focused, reviewable change that can merge independently of other overnight PRs.
- Non-goals: rewriting the macOS app UI, adding MCP servers, merging to main.

## Decisions
- Fetch `https://github.com/JerryZLiu/Dayflow.git` as `upstream` when missing.
- Compare with `git merge-base --is-ancestor upstream/main origin/main` (or the current HEAD if origin/main is unavailable).

## Design review loop

### Principal engineer (round 1)
A scheduled workflow is enough; do not force-push or merge to main from the agent.

### Senior principal engineer (round 1)
Use HTTPS GitHub URL without tokens in committed files. Fetch depth must include both SHAs.

### Second senior principal engineer (round 2)
Keep the script usable offline after remotes exist (CI adds upstream). Approve.

### Decision
Approved after round 2. Scope is docs + check script + workflow.

## Risks / Trade-offs
Scheduled Actions needs network; false positives if GitHub is down — fail open is worse than fail closed for this check, so fail closed.

## Migration Plan
None. Additive on a feature branch.

## Open Questions
None remaining for this scoped change.
