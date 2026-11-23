# 08 — Instruments pass for the new effects, write-up

Status: ready-for-human (recording), then ready-for-agent (write-up)
Blocked by: 01–07

## Human part (user records on device, Release build)

1. SwiftUI + Animation Hitches templates: swipe through 50 photos in full screen; dismiss with a drag; pull and scroll the hero.
2. Allocations: memory after swiping through 200 photos stays flat (only ±1 pages hold full-size images).
3. Time Profiler: the ambient blur during the dismiss drag.
4. Animation Hitches: hitches during the dismiss drag with the ambient backdrop on (blur radius 60 on the 32×32 Preview), and when the chrome toggles (glow fade). If it hitches, try `.drawingGroup()` on the backdrop and compare.

## Agent part

- `docs/decision-log.md`: numbers and conclusions under `## M9 — Photos-style polish`.
- README: a short "Design" section (Photos structure, ambient glow from BlurHash, swipe with parallax, hero) with two screenshots; update the full-screen and grid lines; ADR 0007 in the ADR list.
- Roadmap: M9 done; unblock M8 ticket 08 (snapshot matrix) and add the new screens to it (hero, Info sheet, paging mid-swipe if stable).

## Commit

`docs: record the M9 Instruments pass and describe the design`
