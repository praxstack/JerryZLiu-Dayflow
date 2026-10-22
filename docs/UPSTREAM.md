# Upstream sync

This repository (`praxstack/jerryzliu-dayflow`) is a fork of
[JerryZLiu/Dayflow](https://github.com/JerryZLiu/Dayflow).

## Remotes

```bash
git remote add upstream https://github.com/JerryZLiu/Dayflow.git   # if missing
git fetch origin
git fetch upstream
```

Do not put access tokens in committed remote URLs.

## Check

`scripts/check-upstream-sync.sh` exits 0 when `origin/main` already contains
every commit on `upstream/main` (origin may be *ahead* with PraxStack work).
It exits 1 when origin is behind upstream.

## Merge (never force-push)

```bash
git checkout -b prax/sync-origin-upstream main
git merge upstream/main
# open a PR into main — do not push to main directly
```

## Status snapshot

Frozen SHAs go stale quickly; `scripts/check-upstream-sync.sh` is the source of
truth after `git fetch origin` and `git fetch upstream`.

As of 2026-10-18 (when this branch was last updated):

- `origin/main` at `a98c049` includes `upstream/main` at `e90d25d` (v2.7.1
  appcast) plus PraxStack commits.
- There were **no** unmerged upstream/main commits when this branch was cut.
