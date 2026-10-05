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

## Status recorded for this change

- `origin/main` at `d8408525` includes `upstream/main` at `a45c7be1`
  (v2.6.0) plus PraxStack environment/docs commits.
- There were **no** unmerged upstream/main commits when this branch was cut.
