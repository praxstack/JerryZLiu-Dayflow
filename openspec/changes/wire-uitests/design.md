# Design

## What this change actually ships

Xcode project-file fix so `DayflowUITests` is a synchronized group like
`DayflowTests` (unique ID `C4C1D2FF2DB56806007D5A56`). No UITest code rewrite.

## What this does not ship

- Running UITests in this Linux environment
- Adding DayflowUITests to CI

## Risks

Correctness is pbxproj structure until a macOS `xcodebuild` run.
