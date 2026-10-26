# Design

## What this change actually ships

Guarded `lipo -thin` on Sparkle **Autoupdate** and the bundled **`dayflow` CLI**
when `lipo -archs` shows the main app is single-arch (arm64-only or
x86_64-only). Output goes through a temp file in the helper's directory, then
`mv`, restoring the original file mode (not just `chmod +x`). Predicates use
`lipo -archs`, not `lipo -info`, so build/temp paths cannot skew the decision.

Default DMG builds pass `ARCHS="${RELEASE_ARCHS:-arm64}"` to xcodebuild so the
thinning path runs without a manual override. After thinning, the script
asserts Autoupdate and the CLI match the main executable's architecture list.

## What this does not ship

- Thinning Sparkle.framework as a whole
- Running `lipo` in this Linux environment

## Risks

Universal `RELEASE_ARCHS="arm64 x86_64"` releases skip thinning and may still
trigger macOS Intel-deprecation warnings if any bundled slice is x86_64.
