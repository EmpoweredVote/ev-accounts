---
phase: 10-term-dates
plan: 01
subsystem: ui
tags: [react, ev-ui, component-library, npm-publish]

# Dependency graph
requires:
  - phase: 09-building-imagery
    provides: Results.jsx with current politician card structure
provides:
  - Term date subtitle below office title on PoliticianProfile (PROF-02)
  - Dashboard politician cards without term date clutter (PROF-01)
  - ev-ui 0.1.19 published with getTermLine/formatTermDate helpers
affects: [essentials, ev-ui, future profile enhancements]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "formatTermDate/getTermLine helper pattern: null-safe date formatting with en-dash range and Since prefix"
    - "ev-ui publish + essentials install cycle for shared component updates"

key-files:
  created: []
  modified:
    - ev-ui/src/PoliticianProfile.jsx
    - ev-ui/package.json
    - essentials/src/pages/Results.jsx
    - essentials/package.json

key-decisions:
  - "Use en-dash (U+2013) for date ranges (Jan 2023 - Jan 2027), not em-dash — typographically correct for date spans"
  - "Hide term date line entirely when both start and end are null — no placeholder text"
  - "Start-only dates display as Since Jan 2023 — forward-looking phrasing for ongoing terms"

patterns-established:
  - "Term date formatting: formatTermDate returns short month+year (Jan 2023); getTermLine composes full display string"
  - "Muted subtitle pattern: fontSizes.sm + colors.textMuted below office title h2 for secondary context"

requirements-completed: [PROF-01, PROF-02]

# Metrics
duration: 20min
completed: 2026-02-18
---

# Phase 10 Plan 01: Term Dates Summary

**Term dates relocated from dashboard cards to profile pages — ev-ui 0.1.19 published with formatTermDate/getTermLine helpers and muted subtitle display below office title**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-02-18T19:40:00Z
- **Completed:** 2026-02-18T19:45:00Z (human verification approved)
- **Tasks:** 2 (1 auto + 1 human-verify checkpoint)
- **Files modified:** 4

## Accomplishments
- Removed term start/end date rendering from `renderPoliticianCard` in Results.jsx — dashboard cards now show only name, office title, and party (candidate cards retain election date display)
- Added `formatTermDate` and `getTermLine` helpers to PoliticianProfile.jsx with full edge case handling: null dates hidden, start-only shows "Since Jan 2023", full range shows "Jan 2023 – Jan 2027" with en-dash
- Published ev-ui 0.1.19 to GitHub npm registry and installed in essentials — shared component update follows established publish/install cycle

## Task Commits

Each task was committed atomically:

1. **Task 1: Remove term dates from cards and add term date subtitle to profile**
   - ev-ui: `e44631b` (feat) — `feat(10-01): add term date subtitle to PoliticianProfile`
   - essentials: `38d9e8f` (feat) — `feat(10-01): remove term dates from dashboard politician cards`
2. **Task 2: Verify term date relocation visually** — human-verify checkpoint, approved by user

**Plan metadata:** (docs commit — created with final state update)

## Files Created/Modified
- `ev-ui/src/PoliticianProfile.jsx` — Added formatTermDate/getTermLine helpers and termDate style; renders `<p>` subtitle below `<h2>` office title inside nameTitle div
- `ev-ui/package.json` — Version bumped from 0.1.18 to 0.1.19
- `essentials/src/pages/Results.jsx` — Removed formatTermDate, getTermLine, termLine const, and conditional term date `<p>` from renderPoliticianCard; candidate election date rendering untouched
- `essentials/package.json` — ev-ui dependency updated to ^0.1.19

## Decisions Made
- **En-dash not em-dash for date ranges:** en-dash (U+2013) is typographically correct for date spans; em-dash was used in the old card rendering but this was corrected in the profile version
- **Hide entirely when null:** When both term_start and term_end are null, no line renders at all — avoids empty space or confusing placeholder
- **"Since" prefix for open-ended terms:** Ongoing terms without an end date display as "Since Jan 2023" — forward-looking phrasing appropriate for current officeholders

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 10 complete — term dates now surface contextually on profile, not cluttering cards
- essentials and ev-ui both building successfully at 0.1.19
- No blockers for future phases

---
*Phase: 10-term-dates*
*Completed: 2026-02-18*
