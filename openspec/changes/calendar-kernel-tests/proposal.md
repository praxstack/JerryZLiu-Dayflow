# Proposal

## Why
The bundled CLI copied 4 AM day/week logic from the app. If those copies
drift, MCP/agent queries return the wrong Dayflow day. plans/002 wants one
kernel.

## What Changes
- Extract `DayflowCalendar` / `DayflowCategories` into Shared sources.
- Point CLI and app wrappers at that kernel.
- Add Linux SwiftPM tests plus XCTest files for macOS.

## Capabilities

### New Capabilities
- `calendar-boundaries`: Dayflow days start at 04:00 and weeks start Monday 04:00, from one implementation.

### Modified Capabilities

## Impact
App date helpers, weekly range, CLI DayBoundary/Categories, new
`tools/dayflow-kernel` package.
