---
phase: 07-admin-tool-and-calibration-cron
plan: 02
subsystem: infra
tags: [node-cron, postgres, supabase, cron, notifications, calibration, demotion]

# Dependency graph
requires:
  - phase: 07-01
    provides: calibration_lapse_runs table, notifications table, get_calibration_lapsed_users RPC (timestamp-aware)
  - phase: 05-empower-flow
    provides: executeDemotion function in empowerService.ts
  - phase: 04-compass-routes
    provides: inform.compass_topics with went_live_at (used by RPC)
provides:
  - cronService.ts: runCalibrationLapseJob with three-threshold approach (day 25/30/31)
  - calibrationLapse.ts: node-cron registration for daily 2am UTC job
  - CRON-01: daily lapse identification via get_calibration_lapsed_users RPC
  - CRON-02: day-25 warning notifications in public.notifications
  - CRON-03: day-31 demotion via executeDemotion + demotion confirmation notification
  - CRON-04: calibration_lapse_runs DATE PK prevents double execution
  - Day-30 final warning notification (in-app, pre-demotion warning)
affects:
  - 07-03: admin React UI displays cron run history from calibration_lapse_runs

# Tech tracking
tech-stack:
  added: [node-cron, "@types/node-cron"]
  patterns:
    - "Insert-then-check idempotency: INSERT ON CONFLICT DO NOTHING returns rowCount=0 if already ran — abort immediately"
    - "Priority-order processing: day-31 demotions first, then day-30 warnings, then day-25 warnings — higher threshold always takes precedence"
    - "Set-based deduplication: day31Set and day30Set built before notification loops — O(1) membership test"
    - "Per-user try/catch in demotion loop: one demotion failure does not abort the job or block other users"
    - "Cron guard: startCalibrationLapseCron() only called inside NODE_ENV !== 'test' block in index.ts"

key-files:
  created:
    - backend/src/lib/cronService.ts
    - backend/src/cron/calibrationLapse.ts
  modified:
    - backend/src/index.ts
    - backend/package.json

key-decisions:
  - "node-cron timezone: UTC explicit in options — no system TZ dependency"
  - "Deduplication logic: day31Set and day30Set built from RPC results; loops skip users already processed at higher threshold — ensures no dual notifications"
  - "Individual demotion try/catch: a single user failure (e.g. already demoted) logs error and continues — job never aborts mid-run due to one bad user"
  - "finished_at NULL on error: error path writes error_message but does NOT set finished_at — cron log view can distinguish failed vs. successful runs"
  - "Cron not started in test mode: NODE_ENV !== 'test' guard in index.ts prevents node-cron from registering during vitest runs"

patterns-established:
  - "Cron job module pattern: cronService.ts (logic) + cron/calibrationLapse.ts (registration) — separation allows unit testing of logic without cron overhead"
  - "Notification payload pattern: user_id, type (string enum), payload (JSONB with message + structured data) — reusable for future notification types"

# Metrics
duration: 3min
completed: 2026-02-27
---

# Phase 7 Plan 2: Calibration Lapse Cron Summary

**Daily 2am UTC calibration lapse job with three-threshold approach: day-25 warning, day-30 final warning, day-31 demotion — idempotent via calibration_lapse_runs DATE primary key**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-27T21:10:59Z
- **Completed:** 2026-02-27T21:14:03Z
- **Tasks:** 2
- **Files modified:** 4 (2 created, 2 modified)

## Accomplishments

- `runCalibrationLapseJob()` with full three-threshold detection: calls get_calibration_lapsed_users RPC at thresholds 25, 30, 31 and dispatches appropriate notifications
- CRON-04 idempotency: INSERT ON CONFLICT (run_date) DO NOTHING — running job twice on same day produces no duplicate notifications or demotions
- Day-31 demotion calls executeDemotion from empowerService (SECURITY DEFINER RPC path) + writes demotion_confirmed notification
- node-cron registered at '0 2 * * *' UTC — cron ONLY starts in non-test environments (NODE_ENV !== 'test' guard in index.ts)
- Architecture test continues passing (2/2 green) — cronService.ts was pre-whitelisted in 07-01

## Task Commits

Each task was committed atomically:

1. **Task 1: Install node-cron + create cronService.ts** - `1e6a9d2` (feat)
2. **Task 2: Cron registration + index.ts integration** - `8f30dc7` (feat)

**Plan metadata:** (created after this summary)

## Files Created/Modified

- `backend/src/lib/cronService.ts` — runCalibrationLapseJob: idempotency check, three-threshold RPC calls, per-user demotion with individual try/catch, notification inserts, stats update
- `backend/src/cron/calibrationLapse.ts` — startCalibrationLapseCron: node-cron schedule registration at 02:00 UTC with timezone explicit
- `backend/src/index.ts` — import + call startCalibrationLapseCron inside NODE_ENV !== 'test' guard
- `backend/package.json` — node-cron (dep) + @types/node-cron (devDep) added

## Decisions Made

- **Deduplication via Sets:** After RPC calls return all three user lists, day31Set and day30Set are built before processing loops. Each loop checks membership before inserting notifications — a user who qualifies at day 31 will NOT also receive a day-25 or day-30 notification on the same run.
- **Individual demotion try/catch:** Each day-31 user's demotion is wrapped in its own try/catch. One user failure (e.g., user already demoted, RPC error) is logged and the counter incremented but does not stop processing remaining users.
- **finished_at null on error:** When the outer try/catch catches a job-level error, it writes error_message but deliberately does NOT set finished_at. Downstream cron log views can use `finished_at IS NULL AND error_message IS NOT NULL` to detect failed runs.
- **Cron guard placement:** startCalibrationLapseCron() is called AFTER app.listen() inside the NODE_ENV !== 'test' block — consistent with the plan requirement. Vitest always sets NODE_ENV=test so the cron registration path is never reached during tests.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Pre-existing TypeScript errors in cache.ts, inviteService.ts, auth.ts, tierGuards.ts, account.ts, social.ts — documented in 07-01 summary, unrelated to this plan. No new errors introduced by cronService.ts or calibrationLapse.ts.
- Pre-existing auth.test.ts failures for "requires Supabase connectivity" tests (signup/login with ENOTFOUND test.supabase.co) — pre-existing, no real Supabase URL in test env.
- node-cron sourcemap warning in test output ("Sourcemap for node-cron/dist/esm/node-cron.js points to missing source files") — cosmetic, not a failure.

## User Setup Required

None - no external service configuration required. node-cron is an in-process scheduler with no external dependencies.

## Next Phase Readiness

- 07-03 (Admin React UI) can proceed — all /api/admin/* endpoints from 07-01 and cron infrastructure from 07-02 are complete
- Admin UI Cron Log view can query calibration_lapse_runs table via GET /api/admin/cron/log endpoint (implemented in 07-01)
- Calibration lapse runs will appear in cron log after first 2am UTC execution

---
*Phase: 07-admin-tool-and-calibration-cron*
*Completed: 2026-02-27*
