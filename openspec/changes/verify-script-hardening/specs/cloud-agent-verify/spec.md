# Spec Delta

## Purpose
scripts/cloud-agent-verify.sh SHALL fail if fixture search returns no cards, if unknown commands exit 0, or if MCP initialize does not return a JSON-RPC result.

## ADDED Requirements

### Requirement: Verify script catches empty search and bad arguments
scripts/cloud-agent-verify.sh SHALL fail if fixture search returns no cards, if unknown commands exit 0, or if MCP initialize does not return a JSON-RPC result.

#### Scenario: Fixture search
- **WHEN** the fixture DB contains a card titled with CLI
- **THEN** dayflow search CLI --json yields a non-empty cards (or results) list or the script exits non-zero
