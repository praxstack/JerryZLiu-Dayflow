# Proposal

## Why
praxstack/jerryzliu-dayflow is a fork of JerryZLiu/Dayflow. Without a documented remote and an automated behind-check, origin/main can silently lag upstream.

## What Changes
- Document upstream remote, sync commands, and current merge status.
- Add `scripts/check-upstream-sync.sh` that fails when origin/main is behind JerryZLiu/Dayflow main.
- Add a GitHub Actions workflow that runs the check on a schedule and on main.
- Ignore local worktree/ledger scratch directories.

## Capabilities

### New Capabilities
- `upstream-sync`: keep the PraxStack fork from falling behind JerryZLiu/Dayflow.

### Modified Capabilities

## Impact
docs/UPSTREAM.md, scripts/check-upstream-sync.sh, .github/workflows/upstream-sync.yml, .gitignore.
