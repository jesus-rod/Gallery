# M8 — Review sweep, README and submission

Status: in progress

## Goal

Ship: whole-project reviews with their fixes, a README a reviewer can read in five minutes (setup, architecture with a dependency diagram, decisions, performance, testing, trade-offs, AI usage), and the human-only checks (Instruments, VoiceOver, live key, device feel, Loom).

## Tickets

| # | Ticket | Who |
|---|---|---|
| 01 | Refresh error banner visible under the search field | agent |
| 02 | `/code-review` of the whole project (Standards + Spec), fix what holds up | agent |
| 03 | `/security-review`, fix what holds up | agent |
| 04 | SwiftUI performance review (`swiftui-pro`), fix what holds up | agent |
| 05 | Dependency diagram (`/ios-skills:essential-feed diagram`) | agent |
| 06 | README | agent, user reviews |
| 07 | Instruments, VoiceOver, live key, device check, Loom, submission | user |

Each fix gets a decision-log line under `## M8 — Review sweep` when it changes a decision, and lands as its own small commit.

## Ticket 07 checklist (user)

- Live key run (M3/12): feed, paging, images, one Query with its second Page, cancel back, open one Photo full screen.
- Instruments on device, after scrolling ~500 images: Time Profiler (scroll hitches, main-thread decode), Allocations (memory bounded; open/close ~20 Photos, do visible cells reload?), SwiftUI instrument (body updates per scroll). Screenshots into `docs/instruments/` for the README's Performance section.
- `OfflineFeed.saving` writes on every load more until 300 Photos: visible in Time Profiler/File Activity?
- VoiceOver / Accessibility Inspector: focus boxes, full-screen order (Close, image, Caption, credit), large Dynamic Type overlay.
- Device feel: gestures, zoom back into the right cell from feed and Search results, rotation while full screen, iOS 17 simulator if installed.
- Loom ≤ 3 min, English, code-focused, assumptions, limitations, how AI was used.
- Pre-submit: no company names in any file, commit message or the repo name; `Config/Secrets.xcconfig` not tracked; zip or private repo shared.
