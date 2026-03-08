---
phase: 71-stance-breakdown-panel
plan: 01
subsystem: ui
tags: [react, accordion, favicon, lazy-fetch, compass, stances]

requires:
  - phase: 70-radar-chart-integration
    provides: "RadarChartCore dual-overlay in CompassCard with intersection filtering"
provides:
  - "StanceAccordion component with lazy context fetching and source attribution"
  - "Favicon utility component for inline source link display"
  - "Complete CompassCard: radar chart (left) + stance breakdown (right)"
affects: [compass-card, politician-profile]

tech-stack:
  added: []
  patterns:
    - "CSS grid-template-rows accordion animation (0fr/1fr toggle)"
    - "useRef Map for client-side context caching"
    - "Lazy fetch on accordion expand with loading state"

key-files:
  created:
    - essentials/src/components/Favicon.jsx
    - essentials/src/components/StanceAccordion.jsx
  modified:
    - essentials/src/components/CompassCard.jsx

key-decisions:
  - "CSS grid-template-rows for smooth accordion animation instead of max-height hack"
  - "useRef Map for context cache — persists across re-renders without triggering them"
  - "Loading guard in right zone — spinner while polAnswers fetch, then StanceAccordion"

patterns-established:
  - "Lazy context fetch: cache in useRef Map, fetch on first expand only"
  - "Accordion: single expandedId state, grid-template-rows 0fr/1fr animation"

requirements-completed: [CARD-04, CARD-05, CARD-06]

duration: 2min
completed: 2026-03-08
---

# Phase 71 Plan 01: Stance Breakdown Panel Summary

**Accordion stance breakdown with lazy-fetched reasoning and source favicons replacing skeleton placeholder in CompassCard**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-08T14:43:16Z
- **Completed:** 2026-03-08T14:45:11Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Replaced CompassCard skeleton placeholder with functional StanceAccordion showing topic rows with stance labels
- Lazy context fetching on expand with client-side caching (useRef Map) and loading spinner
- Source links with Google favicons, truncated URLs, and new-tab navigation
- True accordion behavior (one expanded at a time) with CSS grid animation

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Favicon and StanceAccordion components** - `f023668` (feat)
2. **Task 2: Wire StanceAccordion into CompassCard** - `fce5d9a` (feat)

## Files Created/Modified
- `essentials/src/components/Favicon.jsx` - Google favicon service component (16px default, globe SVG fallback)
- `essentials/src/components/StanceAccordion.jsx` - Accordion topic list with lazy context fetching, stance label resolution, source links
- `essentials/src/components/CompassCard.jsx` - Replaced skeleton placeholder with StanceAccordion, added loading guard

## Decisions Made
- CSS grid-template-rows (0fr/1fr) for smooth accordion height animation — avoids max-height hack and overflow issues
- useRef Map for context caching — persists across renders without triggering re-renders
- Favicon default size 16px (not 32px from CompassV2) since these appear inline with source links
- Loading guard: show spinner in right zone while polAnswers loading, then render StanceAccordion

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- CompassCard is now complete: radar chart (left) + stance breakdown (right)
- All politician profile pages with compass stances will show the full comparison experience
- Future enhancement opportunities: stance filtering, comparison export

---
*Phase: 71-stance-breakdown-panel*
*Completed: 2026-03-08*
