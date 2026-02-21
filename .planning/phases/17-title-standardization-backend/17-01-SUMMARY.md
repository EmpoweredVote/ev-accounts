---
phase: 17-title-standardization-backend
plan: 01
subsystem: database
tags: [compass, topics, content, naming, anti-partisan]

# Dependency graph
requires: []
provides:
  - Approved tension titles for all 21 compass topics (format: Topic: Pole A — Pole B)
  - Approved short titles (spoke labels) for all 21 topics
  - Approved custom policy questions for all 21 topics
  - Anti-partisan pole order randomization verified (10 right-first, 11 left-first)
affects: [17-02-title-standardization-backend, 18-compass-display, 19-calibration-flow]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Tension title format: [Topic]: [Pole A] — [Pole B] with randomized pole order per topic"
    - "Custom question pattern: direct policy-focused question, no leading phrases"
    - "Anti-partisan verification: track first-pole political lean, balance across full topic set"

key-files:
  created: []
  modified:
    - .planning/phases/17-title-standardization-backend/topic-drafts.md

key-decisions:
  - "Tension title format uses em dash separator and policy outcome pairs (not partisan labels like Left/Right)"
  - "Pole order randomized per topic to prevent detectable partisan framing — verified 10 right-first vs 11 left-first"
  - "Custom questions are direct and level-neutral — work for federal, state, or local framing"
  - "Short titles kept consistent with existing display patterns; Taxes renamed to Taxes & Spending, Tariffs to Trade & Tariffs for clarity"

patterns-established:
  - "Anti-partisan framing check: verify pole order does not follow a consistent political direction pattern"
  - "Content approval checkpoint: draft in topic-drafts.md, get user sign-off before writing to database"

requirements-completed: [TITLE-01]

# Metrics
duration: ~30min (multi-session with user review checkpoint)
completed: 2026-02-20
---

# Phase 17 Plan 01: Topic Naming Drafts Summary

**Drafted and user-approved tension titles, short titles, and custom policy questions for all 21 compass topics with anti-partisan pole order randomization verified.**

## Performance

- **Duration:** ~30 min (including user review checkpoint)
- **Started:** 2026-02-20T22:00:28Z
- **Completed:** 2026-02-20
- **Tasks:** 2 of 2
- **Files modified:** 1

## Accomplishments
- Drafted all 21 tension titles in `[Topic]: [Pole A] — [Pole B]` format using policy outcome pairs (not partisan labels)
- Verified pole order randomization: 10 right-first, 11 left-first — no detectable partisan pattern
- Drafted 21 custom policy questions with no prohibited leading phrases ("Where do you stand on...", "Do you think...", etc.)
- Reviewed and improved short titles where needed (Taxes -> Taxes & Spending, Tariffs -> Trade & Tariffs)
- User reviewed all 21 topics and approved with edits applied to immigration and deportation entries

## Task Commits

Each task was committed atomically:

1. **Task 1: Query current topic data and draft all 21 topic names** - `ec718c3` (feat)
2. **Task 2: User reviews and approves all 21 topic drafts** - `42c68a2` (chore)

**Plan metadata:** _(pending docs commit)_

## Files Created/Modified
- `.planning/phases/17-title-standardization-backend/topic-drafts.md` - Approved naming content for all 21 compass topics

## Decisions Made
- Tension title format uses em dash (`—`) to separate poles — visually clear and typographically correct
- Policy outcome pairs chosen over partisan labels (e.g., "Market-Driven Care — Universal Coverage" rather than "Conservative — Liberal")
- Pole order randomized manually per topic rather than alphabetically or by position, to prevent any detectable pattern
- Two short titles renamed for clarity: `Taxes` -> `Taxes & Spending`, `Tariffs` -> `Trade & Tariffs`
- Custom questions are intentionally level-neutral — they work whether a politician is federal, state, or local level

## Deviations from Plan

None — plan executed exactly as written. The topic-drafts.md was corrected between sessions by the orchestrator to fix topic keys; content review and user approval proceeded on the corrected file.

## Issues Encountered
- The initial topic-drafts.md commit (ec718c3) contained placeholder topic keys. The orchestrator corrected the file with actual database topic keys before user review. The corrected file was committed as 42c68a2.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- topic-drafts.md contains approved canonical content for all 21 topics
- Plan 17-02 can now apply these names to the database via SQL UPDATE statements
- Content is ready: tension titles, short titles, and custom questions all approved

---
*Phase: 17-title-standardization-backend*
*Completed: 2026-02-20*
