---
phase: 88-practice-round
plan: 01
subsystem: ui
tags: [zustand, react, typescript, localStorage, practice-round, readrank]

# Dependency graph
requires:
  - phase: 87.1-head-to-head-matchup-ranking
    provides: Store v4 with matchup algorithm, QuoteCard swipe component, matchupAlgorithm utilities
provides:
  - Store v5 with isolated PracticeProgress state, 7 practice actions, v5 migration
  - practiceData.ts with PRACTICE_ISSUE, PRACTICE_CHARACTERS, PRACTICE_QUOTES (5 pizza quotes)
  - QuoteCard with optional onAgree/onDisagree callback props (backward-compatible)
affects: [88-02-practice-round-ui, plan-02]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Practice state isolated from issueProgress — no contamination of real verdict payloads"
    - "Store migration distinguishes new users (practiceCompleted: false) from upgrades (practiceCompleted: true) via version > 0 check"
    - "QuoteCard callbacks use ?? fallback to store actions — consumers opt in to custom behavior without breaking existing usage"

key-files:
  created:
    - EV-readrank/src/data/practiceData.ts
  modified:
    - EV-readrank/src/store/useReadRankStore.ts
    - EV-readrank/src/components/QuoteCard.tsx

key-decisions:
  - "Store version bumped to 5 — existing v4 users get practiceCompleted: true (skip practice), brand-new users get practiceCompleted: false (see practice)"
  - "PracticeProgress stored flat alongside issueProgress — not nested inside it — to avoid polluting real issue data sent in verdict POST payloads"
  - "QuoteCard fallback pattern (onAgree ?? store.agreeWithQuote) preserves EvaluationPhase behavior without any changes to that consumer"

patterns-established:
  - "Practice actions mirror real issue actions: agreePracticeQuote/disagreePracticeQuote advance currentQuoteIndex and manage rankedQuotes/disagreedQuotes"
  - "recordPracticeMatchupWin calls computeRankings + getPendingMatchups from shared matchupAlgorithm — same algorithm for practice and real"

requirements-completed: [ONBD-01, ONBD-03, ONBD-04]

# Metrics
duration: 3min
completed: 2026-03-15
---

# Phase 88 Plan 01: Practice Round Foundation Summary

**Zustand store v5 with isolated PracticeProgress state, pizza-topping practice data, and backward-compatible QuoteCard callback props**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-15T20:08:37Z
- **Completed:** 2026-03-15T20:11:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Store bumped to v5 with PracticeProgress interface, 7 practice actions, and migration that correctly gates new vs. returning users
- practiceData.ts created with 5 pizza-topping quotes using fake characters — fully self-contained practice scenario
- QuoteCard refactored with optional onAgree/onDisagree props using ?? fallback — EvaluationPhase unchanged, PracticeRound (Plan 02) can inject custom callbacks

## Task Commits

Each task was committed atomically:

1. **Task 1: Store v5 with practice state and pizza practice data** - `246ede0` (feat)
2. **Task 2: QuoteCard optional onAgree/onDisagree callback props** - `e93da46` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `EV-readrank/src/data/practiceData.ts` - PRACTICE_ISSUE, PRACTICE_CHARACTERS, PRACTICE_QUOTES (5 entries with ids pq-1 through pq-5, all issue: 'practice-pizza')
- `EV-readrank/src/store/useReadRankStore.ts` - PracticeProgress interface, 7 practice actions, v5 migration, updated partialize
- `EV-readrank/src/components/QuoteCard.tsx` - Optional onAgree/onDisagree props with store-action fallback

## Decisions Made

- Store version 5 migration uses `const isUpgrade = version > 0` to detect returning users — avoids showing practice to anyone who already has localStorage data
- Practice state lives at top-level store (not inside issueProgress) to prevent practice data from appearing in real issue verdicts
- QuoteCard callback pattern uses `??` null-coalescing so existing consumers pass zero new props

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

EV-readrank has its own git repository (not tracked by the workspace root repo). All commits were made inside `EV-readrank/` using `cd /Users/chrisandrews/Documents/GitHub/EV-readrank && git commit`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Store v5 fully ready — Plan 02 can import `startPractice`, `agreePracticeQuote`, `disagreePracticeQuote`, `recordPracticeMatchupWin`, `completePractice`, `skipPractice` from store
- PRACTICE_ISSUE, PRACTICE_CHARACTERS, PRACTICE_QUOTES importable from `src/data/practiceData.ts`
- QuoteCard ready to accept practice callbacks — Plan 02 builds the PracticeRound UI component

---
*Phase: 88-practice-round*
*Completed: 2026-03-15*

## Self-Check: PASSED

- practiceData.ts: FOUND
- useReadRankStore.ts: FOUND
- QuoteCard.tsx: FOUND
- SUMMARY.md: FOUND
- Commit 246ede0: FOUND
- Commit e93da46: FOUND
