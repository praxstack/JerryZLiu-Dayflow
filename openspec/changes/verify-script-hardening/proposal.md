# Proposal

## Why
cloud-agent-verify.sh checks JSON parseability but not search hits, unknown-command exit codes, or MCP ping. Broken queries can still "pass".

## What Changes
- Assert search returns at least one match for the fixture title token.
- Assert unknown command exits 2.
- Assert invalid date exits 2.
- Add a one-shot MCP initialize ping.

## Capabilities

### New Capabilities
- `cloud-agent-verify`: Cloud Agent verify script fails on empty search, bad args, and MCP init failure.

### Modified Capabilities

## Impact
scripts/cloud-agent-verify.sh only.
