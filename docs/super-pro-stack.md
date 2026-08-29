# Super-Pro AI Developer Stack

**Owner:** Prax  
**Repository:** [praxstack/jerryzliu-dayflow](https://github.com/praxstack/jerryzliu-dayflow)  
**Last updated:** 2026-08-29

This document describes the recommended agent skill stack for Dayflow Cloud Agents and local Cursor development. Skills install **globally** to `~/.agents/skills` (not into the repo) to avoid bloating the application tree.

---

## Quick start

```bash
# Install all recommended packs (idempotent, non-interactive)
bash scripts/install-super-pro-skills.sh

# Verify key skills and tools
bash scripts/verify-super-pro-skills.sh
```

**Sync / lock file:** Global installs are tracked in `~/.agents/.skill-lock.json` (skills CLI v3). The repo manifest at `.agents/super-pro-packs.json` lists every pack and install mode; re-run the install script to restore on a fresh VM.

**Cloud Agent VM:** Skills are **user-level**, not part of the Swift/dayflow-cli VM install phase. Run `install-super-pro-skills.sh` once per agent user after the environment boots (or bake into a custom environment snapshot).

---

## 10-Layer Architecture

| Layer | Purpose | Primary tools/skills |
|-------|---------|---------------------|
| 1. **Discover** | Find the right skill for the job | `find-skills`, `npx skills find`, gstack `skillify` |
| 2. **Spec** | Formalize requirements before coding | `specify` (Spec Kit), gstack `spec`, `ce-plan`, `writing-plans` |
| 3. **Interrogate** | Clarify scope, risks, and constraints | superpowers `brainstorming`, `ce-brainstorm`, `karpathy-guidelines` |
| 4. **Plan** | Structured implementation plans | `executing-plans`, `subagent-driven-development`, `ce-plan`, gstack `autoplan` |
| 5. **Implement** | Write code with discipline | superpowers `test-driven-development`, pstack `poteto-mode`, mattpocock, vercel-labs, `tdd` (dot-skills), `red-green-refactor` |
| 6. **Review** | Code review and quality gates | mattpocock `code-review`, `ce-code-review`, trailofbits `differential-review`, gstack `review`, jwynia `security-scan` |
| 7. **Security** | Security analysis and hardening | trailofbits pack, jwynia `config-scan`/`dependency-scan`/`security-scan` |
| 8. **Browser QA** | Visual and E2E verification | `agent-browser`, `ce-test-browser`, gstack `qa`/`browse`, anthropics `webapp-testing` |
| 9. **Ship** | Commit, PR, deploy | `ce-commit-push-pr`, gstack `ship`/`land-and-deploy`, `finishing-a-development-branch` |
| 10. **Learn** | Compound knowledge over time | `ce-compound`, gstack `learn`, `continual-learning` |

### Layer diagram

```
┌─────────────┐     ┌─────────────┐     ┌──────────────┐
│  Discover   │────▶│    Spec     │────▶│ Interrogate  │
│ find-skills │     │ specify/ce  │     │ brainstorm   │
└─────────────┘     └─────────────┘     └──────────────┘
       │                                        │
       ▼                                        ▼
┌─────────────┐     ┌─────────────┐     ┌──────────────┐
│    Plan     │────▶│ Implement   │────▶│   Review     │
│ ce-plan     │     │ TDD/poteto  │     │ code-review  │
└─────────────┘     └─────────────┘     └──────────────┘
       │                   │                    │
       ▼                   ▼                    ▼
┌─────────────┐     ┌─────────────┐     ┌──────────────┐
│  Security   │     │ Browser QA  │────▶│    Ship      │────▶ Learn
│ trailofbits │     │agent-browser│     │ gstack ship  │      ce-compound
└─────────────┘     └─────────────┘     └──────────────┘
```

---

## Core 10 Systems

| # | System | Role | Install location |
|---|--------|------|------------------|
| 1 | **Skills CLI** | Universal skill installer (`npx skills@latest`) | npm (npx) |
| 2 | **find-skills** | Meta-skill for discovering skills on demand | `~/.agents/skills/find-skills` |
| 3 | **gstack** | Full dev lifecycle (spec→plan→review→QA→ship→learn) | `~/gstack` + `~/.cursor/skills` |
| 4 | **superpowers** (obra) | Disciplined dev workflows (TDD, debugging, plans) | `~/.agents/skills` |
| 5 | **Compound Engineering** | End-to-end product engineering loop | `~/.agents/skills/ce-*` |
| 6 | **trailofbits/skills** | Security, fuzzing, static analysis | `~/.agents/skills` |
| 7 | **agent-browser** | Headless browser automation for agents | `~/.npm-global/bin/agent-browser` |
| 8 | **Spec Kit (specify-cli)** | Spec-driven development CLI | `~/.local/bin/specify` |
| 9 | **pstack** | Poteto-mode engineering patterns | `~/.agents/skills` |
| 10 | **awesome-copilot** | Broad Microsoft/GitHub engineering skills | `~/.agents/skills` |

---

## Skill packs (full list)

| Pack | Mode | Skills | Notes |
|------|------|--------|-------|
| `vercel-labs/skills` | selective | `find-skills` | Install first |
| `trailofbits/skills` | full | 80 | Security; on-demand |
| `vercel-labs/agent-browser` | selective | `agent-browser` | + npm global CLI |
| `anthropics/skills` | full | 17 | Use subset on demand |
| `github/awesome-copilot` | full | 415 | Invoke on demand |
| `microsoft/skills` | selective | 8 | Avoid context rot |
| `EveryInc/compound-engineering-plugin` | full | 34 | Product loop |
| `shadcn/improve` | selective | `improve` | UI polish |
| `mattpocock/skills` | full | 37 | TypeScript/React |
| `obra/superpowers` | full | 13 | Workflow discipline |
| `addyosmani/agent-skills` | full | 25 | General patterns |
| `vercel-labs/agent-skills` | full | 9 | Vercel/Next.js |
| `supabase/agent-skills` | full | 2 | Postgres/Supabase |
| `cloudflare/skills` | full | 13 | Workers/Wrangler |
| `aws/agent-toolkit-for-aws` | selective | 6 | Billing, security, serverless, etc. |
| `forrestchang/andrej-karpathy-skills` | full | 1 | `karpathy-guidelines` |
| `brainqub3/red-green-refactor` | full | 6 | TDD workflow variants |
| `jwynia/agent-skills` | selective | 3 | `security-scan`, `dependency-scan`, `config-scan` |
| `pproenca/dot-skills` | selective | `tdd` | Red-green-refactor methodology |
| **gstack** | script | 54 | `./setup --host cursor` in `~/gstack` |
| **pstack** | manual copy | 7 | poteto-mode, setup-pstack, etc. |
| **specify-cli** | uv tool | — | `uv tool install specify-cli` |

### microsoft/skills — selective (8 installed, 5 skipped)

**Installed:** `continual-learning`, `frontend-design-review`, `github-issue-creator`, `mcp-builder`, `skill-creator`, `copilot-sdk`, `microsoft-docs`, `cloud-solution-architect`

**Skipped (Azure/Windows-specific):** `applicationinsights-web-ts`, `debugview`, `entra-agent-id`, `kql`, `podcast-generation`

### jwynia note

The research listed `jwynia/agent-skills` → `code-review`, but that skill does not exist in the repo. We install `security-scan`, `dependency-scan`, and `config-scan` instead for review-adjacent workflows.

---

## Overlap warnings

| Domain | Overlapping skills | Recommendation |
|--------|-------------------|----------------|
| **TDD** | superpowers `test-driven-development`, `tdd` (dot-skills), `red-green-refactor`, trailofbits property/mutation testing | Default: superpowers TDD. Use `red-green-refactor` for CI harness workflows. |
| **Code review** | mattpocock `code-review`, `ce-code-review`, trailofbits `differential-review`, gstack `review` | Default: mattpocock for TS/React. trailofbits for security diffs. |
| **Planning** | superpowers `writing-plans`, `ce-plan`, gstack `autoplan` | superpowers for small tasks; ce-plan/gstack for features. |
| **Browser QA** | agent-browser, `ce-test-browser`, gstack `qa`, anthropics `webapp-testing` | agent-browser for CLI; gstack qa for full workflow. |
| **MCP building** | anthropics `mcp-builder`, microsoft `mcp-builder` | Either; microsoft is Azure-aware. |

---

## Desktop-only steps (Cursor IDE)

These plugins require Cursor Desktop and cannot be fully activated on Cloud Agent VM:

```
/add-plugin pstack
/add-plugin superpowers
/add-plugin compound-engineering
```

The VM has skill *files* installed globally; Desktop plugins wire them into the IDE UI.

---

## gstack setup

```bash
git clone https://github.com/gstack/gstack.git ~/gstack
cd ~/gstack && ./setup --host cursor
```

Result: ~54 skills in `~/.cursor/skills`. See [gstack#2361](https://github.com/gstack/gstack/issues/2361) for Cursor integration notes.

---

## Runtime dependencies

| Tool | Path |
|------|------|
| Node.js (nvm) | v22+ |
| Skills CLI | `npx --yes skills@latest` |
| agent-browser | `~/.npm-global/bin/agent-browser` |
| specify-cli | `~/.local/bin/specify` |
| uv | `~/.local/bin/uv` |
| Chrome (agent-browser) | `~/.agent-browser/browsers/` |

**PATH** (add to `~/.bashrc`):

```bash
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$HOME/.bun/bin:$PATH"
```

---

## Optional flags (install script)

```bash
bash scripts/install-super-pro-skills.sh                   # Full stack (AWS selective included)
bash scripts/install-super-pro-skills.sh --skip-optional   # Core packs only (no supabase/cloudflare/aws)
bash scripts/install-super-pro-skills.sh --no-aws          # Skip AWS selective pack only
bash scripts/install-super-pro-skills.sh --with-gstack     # Clone/setup gstack
bash scripts/install-super-pro-skills.sh --with-tools      # agent-browser + specify-cli
```
