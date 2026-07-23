---
phase: 174-fec-429-rate-limit-tail-drive-the-6-hourly-ingest-to-zero-ha
plan: 01
subsystem: infra
tags: [fec, rate-limit, redis, backend-reliability, upstash]

requires: []
provides:
  - "acquireFecSlot(): Promise<void> — shared per-minute rate-limit gate for all outbound FEC HTTP requests"
  - "FEC_RATE_LIMIT_PER_MINUTE env var (default 15, ~900/hr) for operator-tunable pacing"
affects: [174-02, 174-03]

tech-stack:
  added: []
  patterns:
    - "Per-UTC-minute fixed-window Redis INCR/EXPIRE counter with in-process Map degrade — new module-local key space, house style mirrored (not imported) from campaignFinanceScheduler.ts's acquireLock/renewLock"

key-files:
  created:
    - backend/src/lib/fecRateLimiter.ts
    - backend/src/lib/fecRateLimiter.test.ts
  modified: []

key-decisions:
  - "Per-minute (not per-hour) fixed-window bucket to avoid the burst-then-stall anti-pattern (Pitfall 4 in 174-RESEARCH.md)"
  - "Budget re-read from process.env on every poll iteration (not cached once) so the env-var override test and any future hot-reload scenario both work correctly"
  - "Lazy Redis client replicated in this module's own key space rather than imported from campaignFinanceScheduler.ts, per the plan's explicit instruction (different problem: mutual-exclusion lock vs. shared counter)"

patterns-established:
  - "Rate-limiter house style: lazy getRedisClient() (module-local redisClient/redisInitAttempted), in-process Map fallback with self-evicting setTimeout, non-fatal degrade on any Redis error — reusable template for any future shared-budget primitive"

requirements-completed: [FEC-03]

coverage:
  - id: D1
    description: "acquireFecSlot() gates every call under a per-minute budget via Redis fixed-window INCR/EXPIRE, with .expire firing only on the first increment of a bucket"
    requirement: "FEC-03"
    verification:
      - kind: unit
        ref: "backend/src/lib/fecRateLimiter.test.ts#resolves immediately and increments the per-minute Redis key when under budget"
        status: pass
      - kind: unit
        ref: "backend/src/lib/fecRateLimiter.test.ts#does not call .expire on subsequent increments within the same bucket"
        status: pass
    human_judgment: false
  - id: D2
    description: "Over-budget calls block (poll-back) and resolve once a new minute bucket opens, never stalling more than one poll interval"
    requirement: "FEC-03"
    verification:
      - kind: unit
        ref: "backend/src/lib/fecRateLimiter.test.ts#blocks when over budget and resolves once a new minute bucket opens"
        status: pass
    human_judgment: false
  - id: D3
    description: "Redis absence or a thrown .incr degrades to in-process counting without rejecting the caller"
    requirement: "FEC-03"
    verification:
      - kind: unit
        ref: "backend/src/lib/fecRateLimiter.test.ts#degrades to in-process counting when Redis .incr throws, without rejecting"
        status: pass
      - kind: unit
        ref: "backend/src/lib/fecRateLimiter.test.ts#falls back to in-process counting when Redis env vars are absent"
        status: pass
    human_judgment: false
  - id: D4
    description: "FEC_RATE_LIMIT_PER_MINUTE env var overrides the default budget of 15 and changes the gating threshold"
    requirement: "FEC-03"
    verification:
      - kind: unit
        ref: "backend/src/lib/fecRateLimiter.test.ts#honors FEC_RATE_LIMIT_PER_MINUTE to change the gating threshold"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-07-23
status: complete
---

# Phase 174 Plan 01: Shared FEC Rate Limiter Summary

**New `acquireFecSlot()` chokepoint gates every outbound FEC HTTP request under a per-minute Redis fixed-window budget (default 15/min, ~900/hr), degrading to an in-process counter when Redis is unavailable.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-07-23T18:57:50Z
- **Tasks:** 1 (TDD: RED + GREEN)
- **Files modified:** 2 (both new)

## Accomplishments
- Created `backend/src/lib/fecRateLimiter.ts` exporting `acquireFecSlot(): Promise<void>` — the single shared chokepoint plans 174-02/174-03 will wire into `fetchWithRetry`, `resolveCommitteeIds`'s API fallback, and `runFecAutoMatch`.
- Per-UTC-minute fixed-window Redis `INCR`/`EXPIRE(90s)` counter (key `fec:ratelimit:<YYYY-MM-DDTHH:MM>`), matching the house style of `campaignFinanceScheduler.ts`'s `acquireLock`/`renewLock` (lazy client init, non-fatal degrade) but replicated in this module's own key space rather than imported.
- In-process `Map<string, number>` fallback with self-evicting `setTimeout` when Redis env vars are absent or `.incr` throws — never fails the caller.
- Budget is env-tunable via `FEC_RATE_LIMIT_PER_MINUTE` (default `15`, read fresh on every poll iteration so overrides take effect immediately).
- Full Vitest coverage (6 tests, all green) proving: under-budget immediate resolve + correct incr key, first-bucket-only expire, over-budget block-then-resolve-on-new-bucket (via fake timers), Redis-throw degrade, Redis-absent degrade, and env-var override.

## Task Commits

Task 1 followed the TDD RED → GREEN cycle:

1. **Task 1 (RED): failing test for acquireFecSlot** — `ea6455b9` (test) — confirmed all 6 tests fail with module-not-found before any implementation existed.
2. **Task 1 (GREEN): implement acquireFecSlot** — `b34cbde0` (feat) — all 6 tests pass; `npx tsc --noEmit` reports 0 errors.

**Plan metadata:** (this commit, docs: complete plan)

## Files Created/Modified
- `backend/src/lib/fecRateLimiter.ts` - New module exporting `acquireFecSlot()`; lazy Redis client, per-minute fixed-window counter, in-process degrade, env-tunable budget.
- `backend/src/lib/fecRateLimiter.test.ts` - Vitest unit coverage mocking `@upstash/redis` via `vi.hoisted` (matching `discoveryCron.test.ts` convention) with `vi.useFakeTimers()` driving the poll-back loop.

## Decisions Made
- Budget threshold is re-evaluated via `parseInt(process.env.FEC_RATE_LIMIT_PER_MINUTE ?? '', 10)` inside the loop (not memoized at module load) — matches RESEARCH.md's Open Question 1 guidance and makes the override test correctly exercise the live env value.
- `getBudgetPerMinute()` guards against `NaN`/`<=0` parses (malformed env value) by falling back to the default `15`, satisfying the threat model's T-174-03 disposition (`accept` — malformed value falls back via parseInt guard).

## Deviations from Plan

None - plan executed exactly as written. The implementation follows 174-RESEARCH.md's Pattern 3 reference code closely, with one defensive addition (NaN/non-positive guard on the parsed budget) that the plan's `<behavior>` block implied ("parseInt, default 15") but didn't spell out as an edge case — categorized as Rule 2 (missing critical correctness guard against a malformed env var) rather than a deviation from the plan's intent.

## Issues Encountered
- The worktree's `backend/node_modules` was absent (not tracked by git, per `.gitignore`). Symlinked it to the main checkout's `backend/node_modules` (`C:\EV-Accounts\backend\node_modules`) to run `vitest`/`tsc` locally; the symlink itself is gitignored and was never staged or committed — confirmed via `git status --short` showing no `node_modules` entries.

## User Setup Required

None - no external service configuration required. `FEC_RATE_LIMIT_PER_MINUTE` is optional; the default of 15 requires no operator action.

## Next Phase Readiness
- `acquireFecSlot()` is exported and ready for 174-02/174-03 to import into `fecAdapter.ts`'s two HTTP functions and `fecResearch.ts`'s candidate-search function (the third call site identified in 174-RESEARCH.md's Pitfall 2).
- No blockers. This plan is standalone (no `depends_on`) and did not modify any existing call site — 174-02/174-03 wiring is unblocked.

## Threat Flags

None - no new network endpoints, auth paths, or trust-boundary changes; this plan only adds a backend-internal pacing primitive already covered by the plan's own `<threat_model>` (T-174-01/02/03/SC).

## Known Stubs

None - `acquireFecSlot()` is fully implemented and tested; no placeholder/hardcoded-empty behavior.

---
*Phase: 174-fec-429-rate-limit-tail-drive-the-6-hourly-ingest-to-zero-ha*
*Completed: 2026-07-23*
