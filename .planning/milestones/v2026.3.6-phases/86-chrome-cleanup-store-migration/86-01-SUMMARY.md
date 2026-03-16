---
phase: 86-chrome-cleanup-store-migration
plan: 01
subsystem: ui
tags: [zustand, typescript, store-migration, readrank]

requires: []
provides:
  - Zustand store v2 with clean-reset migration (wipes v1 state on upgrade)
  - Phase type narrowed to 'hub' | 'evaluation' | 'results' (ranking removed)
  - Badge system fully removed from store and algorithm
  - Rank-only scoring: rank 1 = N pts, rank N = 1 pt, maxPossible = N*(N+1)/2
affects: [86-02, 86-03, 86-04, 86-05]

tech-stack:
  added: []
  patterns:
    - "Zustand persist v2 migrate with unconditional clean-reset for breaking state shape changes"
    - "Rank-position scoring: linear weight from top rank using triangular sum for normalization"

key-files:
  created: []
  modified:
    - EV-readrank/src/store/useReadRankStore.ts
    - EV-readrank/src/utils/matchingAlgorithm.ts

key-decisions:
  - "migrate() returns hardcoded initial state regardless of version — guarantees any returning user with old localStorage lands on hub cleanly"
  - "nextQuote caps index at quotesToEvaluate.length rather than auto-transitioning to 'ranking' — explicit phase transitions delegated to EvaluationPhase.handleComplete"
  - "selectIssue drops IssueData parameter writes to flat fields — all state lives in issueProgress[issueId]"

patterns-established:
  - "Rank-only scoring: totalQuotes - index gives rank 1 the highest weight, capped by triangular sum"

requirements-completed: [FLOW-06]

duration: 2min
completed: 2026-03-15
---

# Phase 86 Plan 01: Store v2 Migration Summary

**Zustand store migrated to v2 with clean-reset migration, badge system removed, and matchingAlgorithm converted to rank-position scoring (no badge bonuses)**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-15T02:38:31Z
- **Completed:** 2026-03-15T02:41:01Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Store bumped to version 2; migrate() unconditionally resets to `{ phase: 'hub', currentIssueId: null, issueProgress: {} }` so returning users with old localStorage state land on hub without errors
- All badge types (BadgeType, BadgeAssignment), interfaces, and actions (assignBadge, clearBadge) removed
- All legacy flat state fields removed from interface, initialState, and all action implementations
- Phase union narrowed: `'hub' | 'evaluation' | 'results'` (ranking dropped)
- partialize now returns only 3 fields: phase, currentIssueId, issueProgress
- matchingAlgorithm scores by rank position only: rank 1 = N points, rank N = 1 point, max = N*(N+1)/2

## Task Commits

Each task was committed atomically:

1. **Task 1: Migrate Zustand store to v2** - `423c4eb` (feat)
2. **Task 2: Convert matchingAlgorithm to rank-only scoring** - `e64e61b` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `EV-readrank/src/store/useReadRankStore.ts` - v2 store: no badge system, no flat state, clean-reset migrate
- `EV-readrank/src/utils/matchingAlgorithm.ts` - Rank-only scoring, no BadgeAssignment import or BADGE_POINTS

## Decisions Made
- migrate() returns a hardcoded initial object rather than trying to transform old state — any v1 state is structurally incompatible (has 'ranking' phase, badge fields) so a clean reset is the only safe migration path
- nextQuote no longer auto-transitions to 'ranking' phase — it caps the index and lets EvaluationPhase.handleComplete drive explicit phase transitions, keeping phase control in one place
- IssueData parameter is kept in selectIssue signature (consumers pass it) but writes to flat fields are removed — callers updated in Plan 02

## Deviations from Plan

None - plan executed exactly as written.

The plan explicitly stated "TypeScript errors exist only in consumer files (not in the store itself)" — this is confirmed: both modified files have zero TypeScript errors; all 47+ errors are in consumer components that Plan 02 will fix.

## Issues Encountered
- `tsc --noEmit` with project references (tsconfig.json) returns zero files processed — must use `tsc --project tsconfig.app.json --noEmit` to get real consumer errors. This is a project config characteristic, not an issue.

## Next Phase Readiness
- Store type changes are the ground truth for Plan 02 consumer cleanup
- TypeScript errors in consumers serve as the exact work queue for Plan 02
- No blockers

---
*Phase: 86-chrome-cleanup-store-migration*
*Completed: 2026-03-15*

## Self-Check: PASSED

- FOUND: EV-readrank/src/store/useReadRankStore.ts
- FOUND: EV-readrank/src/utils/matchingAlgorithm.ts
- FOUND: .planning/phases/86-chrome-cleanup-store-migration/86-01-SUMMARY.md
- FOUND: commit 423c4eb (feat: store v2 migration)
- FOUND: commit e64e61b (feat: rank-only scoring)
