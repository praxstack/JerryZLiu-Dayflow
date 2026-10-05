# Design

## What this change actually ships

Guarded `lipo -thin arm64` on Sparkle **Autoupdate only** (not the whole
framework), writing through a temp file then `mv` + `chmod +x` so `lipo`
does not rewrite the binary onto itself. `lipo -info` no-ops when there is
no x86_64 slice.

## What this does not ship

- Thinning Sparkle.framework as a whole
- Running `lipo` in this Linux environment

## Risks

Intel Dayflow builds would break if someone shipped an x86 app with this
script — Dayflow is arm64-only.
