---
phase: 15-compass-admin-react-ui
plan: "03"
subsystem: ui
tags: [react, headlessui, typescript, vite, tailwind, compass, politicians]

# Dependency graph
requires:
  - phase: 15-01
    provides: navigation scaffold, apiFetch utility, admin app shell
  - phase: 14-03
    provides: PUT /admin/compass/politicians/:id/answers, POST /admin/compass/politicians/:id/context, GET /compass/politicians/:id/answers endpoints
provides:
  - Full PoliticiansPage replacing stub — list + create modal + slide-out panel
  - PoliticianDetailPanel with Compass Answers section (topic rows, stance selector, reasoning, sources)
  - Two-call save pattern (PUT answers + POST context in parallel)
  - topicStances lazy-loading cache (Record<number, Stance[]>)
affects:
  - Phase 15 plan 04 (checkpoint verification of admin UI)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Disclosure/DisclosureButton/DisclosurePanel for collapsible topic rows (Headless UI v2)
    - RadioGroup/Radio for stance selection (Headless UI v2, no dot notation)
    - SaveButton state machine (idle/saving/done/error) reused from TopicsPage
    - Lazy stances cache at page level — fetch once per topicId, shared across all rows

key-files:
  created: []
  modified:
    - admin/src/pages/admin/PoliticiansPage.tsx

key-decisions:
  - "RadioGroup value prop requires number | undefined, not number | null — use value ?? undefined"
  - "Both tasks implemented in single file/commit — inseparable when same file is target"
  - "onUpdate prop retained on PoliticianDetailPanel for future profile edit save; void-cast to suppress TS warning"

patterns-established:
  - "TopicAnswerRow: eagerly loads stances via onStancesNeeded on mount (not on expand)"
  - "Two-call save: PUT /answers and POST /context run in parallel via Promise.all"
  - "answers fetch uses /compass/politicians/:id/answers (public route, no /admin prefix)"

# Metrics
duration: 4min
completed: 2026-03-07
---

# Phase 15 Plan 03: Politicians Page Summary

**Full Politicians admin page: list with answer counts, create modal, slide-out panel with per-topic RadioGroup stance selector, reasoning textarea, and sources list — two-call save (PUT answers + POST context)**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-07T04:18:43Z
- **Completed:** 2026-03-07T04:22:37Z
- **Tasks:** 2 (committed together — same file)
- **Files modified:** 1

## Accomplishments

- Politicians list with inactive dimming (opacity-50 + "(inactive)" label + Inactive badge in panel)
- CreatePoliticianModal with 6 fields (first/last/preferred/full name, office title, photo URL); on success adds to list and auto-opens panel
- PoliticianDetailPanel with profile header and Compass Answers section
- TopicAnswerRow with Disclosure, RadioGroup stance selector, reasoning textarea, SourcesList (add/remove URL list)
- topicStances cache at page level prevents duplicate fetch per topic
- Two-call save: PUT /admin/compass/politicians/:id/answers + POST /admin/compass/politicians/:id/context (parallel Promise.all)
- Topic filter search field in panel header
- SaveButton state machine (idle/saving/done/error) reused verbatim from TopicsPage

## Task Commits

Both tasks target the same file and were implemented together:

1. **Task 1 + Task 2: Full PoliticiansPage implementation** - `a284c5a` (feat)

**Plan metadata:** (docs commit to follow)

## Files Created/Modified

- `admin/src/pages/admin/PoliticiansPage.tsx` — Full implementation, 668 lines, replacing 33-line stub

## Decisions Made

- `RadioGroup value` prop expects `number | undefined` not `number | null` — used `value ?? undefined` to convert
- `onUpdate` prop on `PoliticianDetailPanel` retained for future profile edit feature; `void onUpdate` suppresses unused variable TS warning without removing the prop from the interface
- Both tasks were implemented in a single commit because they both target the same file with no intermediate state that could be committed independently

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed RadioGroup null vs undefined type mismatch**

- **Found during:** Task 2 (TypeScript compilation)
- **Issue:** `RadioGroup value` prop typed as `number | undefined` by Headless UI; plan used `number | null` for selectedValue state; TypeScript error TS2322
- **Fix:** Pass `value ?? undefined` to RadioGroup, keeping internal state as `number | null`
- **Files modified:** admin/src/pages/admin/PoliticiansPage.tsx
- **Verification:** `tsc --noEmit` exits 0
- **Committed in:** a284c5a

---

**Total deviations:** 1 auto-fixed (1 type bug)
**Impact on plan:** Minor type conversion fix, no behavioral change.

## Issues Encountered

None beyond the null/undefined type fix above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- PoliticiansPage fully implemented — ready for 15-04 human-verify checkpoint
- Admins can list, create, and set compass answers + context for politicians
- topicStances cache is page-level state, cleared on page navigation (acceptable for Alpha)
- Profile editing (updating first_name, office_title etc.) not implemented — out of scope for this plan

---
*Phase: 15-compass-admin-react-ui*
*Completed: 2026-03-07*
