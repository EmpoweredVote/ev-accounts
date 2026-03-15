---
phase: 87-unified-evaluatephase-inlinerankpanel
plan: 01
subsystem: ui
tags: [zustand, dnd-kit, typescript, read-rank, store-migration]

requires:
  - phase: 86-chrome-cleanup-store-migration
    provides: Store v2 with rankedQuotes field, matchingAlgorithm index-based scoring, EvaluationPhase.handleComplete

provides:
  - Unified IssueProgress with single rankedQuotes list as sole source of truth for agreed quotes
  - pendingRankQuoteId and rankSkipCount fields for Plan 02 inline rank UI
  - New store actions: insertAtRank, skipRankPrompt, dismissPending, reorderRankedQuotes
  - Store version bumped to v3 with clean-reset migration

affects:
  - 87-02 (inline rank panel reads pendingRankQuoteId)
  - 87-03 (EvaluatePhase UI reads rankedQuotes)
  - 87-04 (results and navigation consumers)

tech-stack:
  added: []
  patterns:
    - "Single-list store: agreed quotes appended to rankedQuotes with positional rank, no separate agreedQuotes array"
    - "Pending rank UI hint: agreeWithQuote sets pendingRankQuoteId, UI reads it to show inline placement prompt"

key-files:
  created: []
  modified:
    - EV-readrank/src/store/useReadRankStore.ts
    - EV-readrank/src/utils/verdictFragment.ts
    - EV-readrank/src/utils/verdictSync.ts
    - EV-readrank/src/components/ResultsPhase.tsx
    - EV-readrank/src/components/PhaseNavigation.tsx
    - EV-readrank/src/components/EvaluationPhase.tsx
    - EV-readrank/src/components/AgreedQuotesSidebar.tsx
    - EV-readrank/src/components/CandidateAlignmentPage.tsx

key-decisions:
  - "agreedQuotes field removed entirely — rankedQuotes is the single source of truth for agreed quotes with positional ranks"
  - "AgreedQuotesSidebar updated in-place (reorderRankedQuotes + RankedQuote type) rather than deferred — TypeScript build required it; Plan 02 will rename the component"
  - "CandidateAlignmentPage redundant agreedQuotes check removed — rankedQuotes alone is sufficient for verdict lookup"

patterns-established:
  - "All agreed quote consumers now read progress.rankedQuotes exclusively — no dual-loop pattern"

requirements-completed: [FLOW-01, FLOW-05]

duration: 2min
completed: 2026-03-15
---

# Phase 87 Plan 01: Unified Store Migration Summary

**Merged dual-array store (agreedQuotes + rankedQuotes) into single rankedQuotes list as sole source of truth, with pendingRankQuoteId/rankSkipCount fields for inline rank UI**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-15T03:50:13Z
- **Completed:** 2026-03-15T03:52:33Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- IssueProgress.agreedQuotes removed from interface and all consumers — rankedQuotes is the single agreed-quote list
- agreeWithQuote now appends directly to rankedQuotes as RankedQuote with positional rank
- New actions (insertAtRank, skipRankPrompt, dismissPending, reorderRankedQuotes) ready for Plan 02 inline rank panel
- Store version bumped to v3 with clean-reset migration for returning users
- npm run build succeeds with zero TypeScript errors across all 8 changed files

## Task Commits

Each task was committed atomically:

1. **Task 1: Merge store to unified rankedQuotes list with new actions** - `8acd34c` (feat)
2. **Task 2: Update all consumers to read from unified rankedQuotes** - `da9639c` (feat)

## Files Created/Modified
- `EV-readrank/src/store/useReadRankStore.ts` - Removed agreedQuotes, added pendingRankQuoteId/rankSkipCount, new actions, version 3
- `EV-readrank/src/utils/verdictFragment.ts` - Single rankedQuotes loop only
- `EV-readrank/src/utils/verdictSync.ts` - Single rankedQuotes loop only
- `EV-readrank/src/components/ResultsPhase.tsx` - Uses rankedQuotes for agreed display and count
- `EV-readrank/src/components/PhaseNavigation.tsx` - rankedCount replaces agreedCount
- `EV-readrank/src/components/EvaluationPhase.tsx` - rankedQuotes replaces agreedQuotes, text updated to "Ranked/Disagreed"
- `EV-readrank/src/components/AgreedQuotesSidebar.tsx` - reorderRankedQuotes + RankedQuote type (component rename deferred to Plan 02)
- `EV-readrank/src/components/CandidateAlignmentPage.tsx` - Removed redundant agreedQuotes check

## Decisions Made
- AgreedQuotesSidebar updated to use reorderRankedQuotes and RankedQuote type now (not deferred) because the TypeScript build required it — the component rename to RankedQuotesSidebar is still deferred to Plan 02
- CandidateAlignmentPage had a redundant dual-check (`agreedQuotes.find || rankedQuotes.find`) — collapsed to single `rankedQuotes.find` since they were the same set

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Updated AgreedQuotesSidebar type references**
- **Found during:** Task 2 (Update all consumers)
- **Issue:** AgreedQuotesSidebar used `reorderAgreedQuotes` and `Quote` type — both removed from store; TypeScript build blocked
- **Fix:** Updated to `reorderRankedQuotes`, `RankedQuote` type, and explicit type annotation in findIndex callbacks
- **Files modified:** EV-readrank/src/components/AgreedQuotesSidebar.tsx
- **Verification:** TypeScript clean, build passes
- **Committed in:** da9639c (Task 2 commit)

**2. [Rule 2 - Missing Critical] Removed agreedQuotes check in CandidateAlignmentPage**
- **Found during:** Task 2 (Update all consumers)
- **Issue:** CandidateAlignmentPage still checked `progress.agreedQuotes` alongside `rankedQuotes` — agreedQuotes no longer exists
- **Fix:** Collapsed to single `rankedQuotes.find` check
- **Files modified:** EV-readrank/src/components/CandidateAlignmentPage.tsx
- **Verification:** TypeScript clean, correct verdict logic preserved
- **Committed in:** da9639c (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 2 - missing critical updates in consumer files not listed in plan)
**Impact on plan:** Both auto-fixes required for TypeScript build. No scope creep — verdictSync.ts was also fixed as an unlisted consumer (same pattern).

## Issues Encountered
None - plan executed cleanly once all consumers were identified (verdictSync.ts was an additional consumer not listed in the plan's files list but followed the same pattern).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Store v3 is live with rankedQuotes as single truth and pendingRankQuoteId/rankSkipCount ready
- Plan 02 can immediately read pendingRankQuoteId to show inline rank placement panel
- Plan 02 can rename AgreedQuotesSidebar to RankedQuotesSidebar

---
*Phase: 87-unified-evaluatephase-inlinerankpanel*
*Completed: 2026-03-15*
