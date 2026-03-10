---
phase: 17-live-alpha-deployment
plan: 02
subsystem: infra
tags: [smoke-test, typescript, fetch, tsx, production-verification]

# Dependency graph
requires:
  - phase: 17-live-alpha-deployment/17-01
    provides: migration apply script and DEPLOY.md runbook (defines what the smoke test validates)
provides:
  - Standalone smoke test script (backend/scripts/smokeTest.ts) — 5 HTTP checks, configurable base URL, exits 1 on any failure
  - Production go/no-go gate runnable via SMOKE_TEST_URL env var before announcing Alpha
affects:
  - Phase 17 deployment execution (DEPLOY.md references smoke test as post-migration verification step)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Standalone Node.js script pattern: runs via npx tsx, not part of Express app or Vitest suite"
    - "AbortController timeout pattern: 10s per fetch request, network errors caught and reported as [FAIL]"
    - "Sequential check execution: order matters for diagnostics (health before auth before data endpoints)"

key-files:
  created:
    - backend/scripts/smokeTest.ts
  modified: []

key-decisions:
  - "Auth check passes on 401 only — 500 means Supabase unreachable, 200 would be catastrophic. No other status is acceptable."
  - "Admin UI check hardcoded as [SKIP] — keeps it visible in output without blocking automated exit code"
  - "Essentials politicians check doubles as migration 026 is_candidate column verification"
  - "Sequential execution chosen over parallel — diagnostics require knowing which check failed in order"

patterns-established:
  - "Smoke test output format: [PASS]/[FAIL]/[SKIP] prefix, array(<count>) for array responses, summary line then SMOKE TEST PASSED/FAILED"

# Metrics
duration: 2min
completed: 2026-03-09
---

# Phase 17 Plan 02: Smoke Test Script Summary

**Standalone 5-check HTTP smoke test suite — health, auth reachability, compass topics, essentials politicians (validates migration 026 is_candidate), and admin UI skip — exits 1 on any failure.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-10T02:35:44Z
- **Completed:** 2026-03-10T02:37:50Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Created `backend/scripts/smokeTest.ts` — runnable via `SMOKE_TEST_URL=https://<domain> npx tsx backend/scripts/smokeTest.ts`
- All 5 checks implemented with `[PASS]`/`[FAIL]`/`[SKIP]` output format and `array(<count>)` for array responses
- Network errors caught per-check via try/catch (no unhandled exceptions); AbortController 10s timeout per request
- Script exits 1 on any `[FAIL]`, exits 0 on all `[PASS]`/`[SKIP]`; verified against non-existent host

## Task Commits

Each task was committed atomically:

1. **Task 1: Smoke test script** - `b6030fe` (feat)

**Plan metadata:** (pending — docs commit follows)

## Files Created/Modified

- `backend/scripts/smokeTest.ts` — 5-check smoke test suite, SMOKE_TEST_URL-configurable, AbortController timeout, sequential execution

## Decisions Made

- **Auth check: 401 is the only pass** — 500 means Supabase auth is unreachable (bad), 200 would mean bad credentials were accepted (catastrophic). Rationale: each status code has distinct diagnostic meaning and only 401 confirms the auth subsystem is functional.
- **Admin UI as SKIP not FAIL** — The admin UI is a Vite frontend; programmatic JS error detection is not feasible in a fetch-based script. Keeping it in the output list maintains visibility in the checklist without blocking automated runs.
- **Essentials politicians check validates migration 026** — The endpoint queries `is_candidate`, added by migration 026. A 500 here during Alpha deployment would indicate the migration wasn't applied. Comment in code makes this explicit for future operators.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. TypeScript strict mode compilation passed without adjustments. The script used built-in Node 18+ fetch throughout — no external HTTP client needed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Smoke test script is ready to use. Run it after applying migrations 026–029 to production (per DEPLOY.md Step 2).
- Phase 17 is now complete: migration tooling (17-01) + smoke test (17-02) are both committed.
- Next: Phase 18 (CompassV2 API compatibility — CV2-01 through CV2-05).

---
*Phase: 17-live-alpha-deployment*
*Completed: 2026-03-09*
