# Design

## What this change actually ships

Docs + `scripts/check-upstream-sync.sh` + scheduled workflow. Fetches
`https://github.com/JerryZLiu/Dayflow.git` as `upstream` when missing.
Compares with `git merge-base --is-ancestor upstream/main origin/main`
(or HEAD if origin/main is unavailable). HTTPS URL, no tokens in tree.

## What this does not ship

- Force-push or merge to main
- Rewriting git history

## Risks

Scheduled Actions need network. The check fails closed rather than open.
