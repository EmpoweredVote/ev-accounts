---
phase: 81-profile-integration
plan: 01
subsystem: ui
tags: [ev-ui, react, component-library, npm-publish, github-registry]

# Dependency graph
requires:
  - phase: 80-ev-ui
    provides: StanceAccordion v0.1.42 with inline styles and apiUrl prop
provides:
  - ev-ui v0.1.43 published to GitHub npm registry
  - StanceAccordion verdictsByQuote prop for per-quote verdict badges in expanded rows
  - Lazy quote fetch infrastructure (ensureQuotesFetched + quotesCache) using /essentials/quotes endpoint
  - verdictsByTopic deprecated from collapsed-row render (kept in prop signature for backward compat)
affects: [82-verdict-sync, essentials, CompassV2]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single-fetch quote cache: quotesCache useRef(null) — null=unfetched, array=fetched (including empty); fetched once per politicianId lifetime"
    - "Parallel expand fetch: Promise.all([fetchContext(topicId), ensureQuotesFetched()]) in handleToggle"
    - "ev-ui inline styles only: no Tailwind in component library source — all badge/card styles use inline style objects"

key-files:
  created: []
  modified:
    - ev-ui/src/StanceAccordion.jsx
    - ev-ui/package.json

key-decisions:
  - "verdictsByTopic prop kept in signature for backward compat but removed from collapsed-row render — badges move to expanded-row per quote"
  - "quotesCache initialized to null (not empty array) to distinguish unfetched from fetched-but-empty"
  - "Quote-to-topic mapping uses case-insensitive q.issue === topic.short_title comparison"
  - "Quote cards rendered in both task commits — Tasks 1 and 2 implemented together for build coherence"

patterns-established:
  - "Per-quote verdict display: verdictsByQuote[quote.id] drives left-border color and badge pill in expanded accordion rows"

requirements-completed: [PROF-02]

# Metrics
duration: 3min
completed: 2026-03-12
---

# Phase 81 Plan 01: StanceAccordion verdictsByQuote + ev-ui v0.1.43 Summary

**ev-ui StanceAccordion updated with per-quote verdict badges in expanded rows via verdictsByQuote prop, single-fetch quote cache from /essentials/quotes, and published as v0.1.43 to GitHub npm registry**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-12T17:13:48Z
- **Completed:** 2026-03-12T17:17:11Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Added `verdictsByQuote` prop (Record<quote_id, 'agreed'|'disagreed'>) to StanceAccordion
- Implemented `quotesCache` useRef pattern — fetches `/essentials/quotes?politician_id` once per mount and filters per topic in expanded rows
- Quote cards render with inline left-border color coding (neutral/cyan/amber) and verdict badge pills
- Removed `verdictsByTopic` badges from collapsed row; prop retained for backward compat but no longer rendered
- ev-ui v0.1.43 built and published to `https://npm.pkg.github.com`

## Task Commits

Each task was committed atomically (in ev-ui repo):

1. **Task 1: Add verdictsByQuote prop and quote fetch infrastructure** - `de68fa6` (feat)
2. **Task 2: Render quote cards with verdict badges; bump to v0.1.43** - `d1152b8` (feat)

## Files Created/Modified
- `ev-ui/src/StanceAccordion.jsx` - Added verdictsByQuote prop, quotesCache ref, fetchContext/ensureQuotesFetched functions, parallel fetch in handleToggle, quote card render in expanded rows, removed collapsed-row verdict badges
- `ev-ui/package.json` - Version bumped from 0.1.42 to 0.1.43

## Decisions Made
- `verdictsByTopic` kept in prop signature (backward compat) but removed from collapsed-row render — verdict display moves exclusively to expanded-row per-quote cards
- `quotesCache` initialized as `null` (not `[]`) to unambiguously distinguish "not yet fetched" from "fetched but empty"
- Case-insensitive matching (`q.issue.toLowerCase() === topic.short_title.toLowerCase()`) used for quote-to-topic filtering — more robust than exact match
- Both Tasks 1 and 2 changes implemented in the same file write since the expanded-row quote render depends on quotesCache being present

## Deviations from Plan

None - plan executed exactly as written. Both tasks implemented in sequence with build verification after each commit.

## Issues Encountered
- ev-ui is a separate git repository (has its own `.git` folder) — commits made directly in ev-ui repo rather than workspace root. Expected behavior, no action needed.

## User Setup Required
None - no external service configuration required. Package published to GitHub npm registry automatically.

## Next Phase Readiness
- ev-ui v0.1.43 is live on GitHub npm registry — Phase 81 Plan 02 (Essentials integration) can now consume `verdictsByQuote` prop
- Phase 82 (logged-in verdict sync) depends on the URL fragment `v` key bridge established in Phase 81 planning

---
*Phase: 81-profile-integration*
*Completed: 2026-03-12*

## Self-Check: PASSED

- ev-ui/src/StanceAccordion.jsx: FOUND
- ev-ui/package.json: FOUND
- 81-01-SUMMARY.md: FOUND
- Commit de68fa6: FOUND
- Commit d1152b8: FOUND
