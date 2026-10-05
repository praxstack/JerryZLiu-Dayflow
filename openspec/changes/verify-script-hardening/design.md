# Design

## What this change actually ships

Hardened `scripts/cloud-agent-verify.sh`: bash + python3 only. Fixture path
via `DAYFLOW_DB`. MCP child: 5s timeout, `initialize`, require
`serverInfo.name == dayflow`, then kill.

## What this does not ship

- A Python rewrite of the verifier
- GUI verification

## Risks

The MCP child must be killed even if jq/python assertions fail.
