---
phase: 58-contributor-portal
plan: 03
subsystem: ui
tags: [react, typescript, vite, tailwind, contributor-portal, compass, stance-editor]

# Dependency graph
requires:
  - phase: 58-02
    provides: stub pages CompassEditorPage and CampaignManagerPage + contributor routes
  - phase: 55-03
    provides: GET /api/compass/contributors/politicians endpoint (jurisdiction-scoped)
  - phase: 55-01
    provides: PUT /api/compass/stances/:id/bulk endpoint for stance writes

provides:
  - "Full CompassEditorPage: politician list -> inline stance editor -> bulk save"
  - "Full CampaignManagerPage: single-politician list -> inline stance editor -> bulk save"
  - "Jurisdiction/scope badge visible in both editor headers"
  - "Toast feedback (success/error) on save in both editors"
  - "Stance values 1-5 from API, not 0-indexed"

affects:
  - 58-04 (EssentialsEditorPage — parallel wave, no shared component dependency)
  - Future phases using compass contributor workflows

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Two-view page pattern: list view / inline editor view via selectedPolitician state"
    - "Parallel fetch on selection: Promise.all([topics, answers]) when politician clicked"
    - "changedStances map (topic_id -> value) tracks dirty state, cleared on save"
    - "Optimistic existingAnswers update after save (merge changedStances into existingAnswers)"
    - "Toast pattern: useState + fixed bottom-6 positioning + setTimeout(2500)"
    - "Wave isolation: no shared StanceEditor component — stance JSX duplicated across Plan 03 and 04"
    - "Stance button selected state: ev-yellow (Compass) / ev-red (Coordinator) when selected, gray border otherwise"

key-files:
  created: []
  modified:
    - app/src/pages/contributor/CompassEditorPage.tsx
    - app/src/pages/contributor/CampaignManagerPage.tsx

key-decisions:
  - "No shared StanceEditor.tsx component — Plans 03 and 04 run in parallel (Wave 3), shared file would create race condition"
  - "CampaignManagerPage: single-item list view intentional — UI consistency per spec, not a shortcut"
  - "changedStances only tracks mutations; display value merges changedStances over existingAnswers"
  - "Save button disabled when no changes pending (zero keys in changedStances map)"
  - "Scope badge: jurisdiction geoid for CompassEditor, politician name + office for CandidateCoordinator"

patterns-established:
  - "Compass contributor pages: fetch /compass/contributors/politicians -> show list -> click -> fetch topics + answers in parallel -> render stance selector buttons"
  - "Bulk save always sends only changed stances (not full topic list)"

# Metrics
duration: 2min
completed: 2026-04-04
---

# Phase 58 Plan 03: Compass Editor and Candidate Coordinator Summary

**Full stance editing UIs for CompassEditorPage (jurisdiction-scoped politician list) and CampaignManagerPage (single-politician Candidate Coordinator), both with parallel fetch, 1-5 stance values, and bulk PUT save with toast feedback**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-04-04T07:20:22Z
- **Completed:** 2026-04-04T07:22:41Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- CompassEditorPage (351 lines): politician list with jurisdiction badge, inline stance editor with topic list, bulk save, toast feedback, back-to-list navigation
- CampaignManagerPage (343 lines): single-politician card list with scope badge (politician name + office), identical inline stance editor, bulk save, toast feedback — header "Candidate Coordinator" everywhere
- Both pages: stance values 1-5 from `stance.value`, not array indices; error states for load and save failures; spinners during loading

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement CompassEditorPage** - `a0e8292` (feat)
2. **Task 2: Implement CampaignManagerPage** - `9e973b7` (feat)

**Plan metadata:** (pending docs commit)

## Files Created/Modified
- `app/src/pages/contributor/CompassEditorPage.tsx` - Full Compass Editor: politician list + inline stance editor with ev-yellow accent
- `app/src/pages/contributor/CampaignManagerPage.tsx` - Full Candidate Coordinator: single-politician list + inline stance editor with ev-red accent

## Decisions Made
- No shared `StanceEditor.tsx` component extracted — Plans 03 and 04 execute in parallel (Wave 3), shared file would create a file-system race condition between plan agents
- CampaignManagerPage intentionally shows a one-item list before opening the editor, per spec (UI consistency)
- `changedStances` map tracks only mutations; merged over `existingAnswers` for display value; cleared on successful save
- Scope badge in CampaignManagerPage shows `{politicianName} — {officeTitle}`, visible at all times including in stance editor view (via existing state)

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Plan 03 complete. CompassEditorPage and CampaignManagerPage fully functional.
- Plan 04 (EssentialsEditorPage) runs in same Wave 3 and was already implemented (commit f769dca visible in log from parallel execution).
- Phase 58 ready to finalize: run overall verification across all contributor portal pages.

---
*Phase: 58-contributor-portal*
*Completed: 2026-04-04*
