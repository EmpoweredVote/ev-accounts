---
phase: 50-precise-representatives-pre-phase-49-users
plan: 01
subsystem: api
tags: [representatives, jurisdiction, postgis, encrypted-coords, write-back, adminRpc]

# Dependency graph
requires:
  - phase: 49-stored-jurisdiction
    provides: encrypted_lat column + resolve_user_jurisdiction RPC + geo_id columns on connected_profiles
  - phase: quick-011
    provides: getLocalOfficialsByUserId() helper used in Path 1.5 response
provides:
  - Path 1.5 in GET /essentials/representatives/me for pre-Phase-49 users with encrypted coords but null geo_ids
  - Fire-and-forget geo_id write-back so next request hits fast Path 1
affects:
  - 50-02 (backfill script — this plan documents the per-request fallback; backfill eliminates the need for Path 1.5 long-term)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Path 1.5: lazy hydration — on-read write-back of computed columns (geo_ids) when stale"
    - "adminRpc for Vault-dependent RPCs even in non-auth routes"
    - "Single consolidated pool.query to replace two separate round-trips"

key-files:
  created: []
  modified:
    - backend/src/routes/essentials.ts

key-decisions:
  - "Import adminRpc from ../lib/supabase.js (NOT ../lib/supabaseAdmin.js — that file does not exist)"
  - "Combined two pool.query calls (home_address + geo_ids) into one query adding has_coords boolean"
  - "Write-back is fire-and-forget (void pool.query) — response is not gated on write completing"
  - "All-null RPC result falls through to Path 2 rather than 204 — allows home_address geocode to run if present"

patterns-established:
  - "Lazy hydration pattern: if computed columns are missing, compute inline and write back async"

# Metrics
duration: 8min
completed: 2026-04-01
---

# Phase 50 Plan 01: Path 1.5 in /representatives/me Summary

**Path 1.5 in GET /essentials/representatives/me: on-read coordinate decryption + geo_id write-back for pre-Phase-49 users with encrypted_lat but null geo_id columns**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-04-01T05:24:48Z
- **Completed:** 2026-04-01T05:32:30Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Combined two separate `pool.query` calls (home_address + geo_ids) into one round-trip that also fetches `(encrypted_lat IS NOT NULL) AS has_coords`
- Inserted Path 1.5 between Path 1 and Path 2: detects `has_coords=true && congressional_geo_id=null`, calls `resolve_user_jurisdiction` RPC, serves correct district politicians
- Fire-and-forget `pool.query` write-back updates all 10 geo_id/name columns so next request hits fast Path 1
- All-null RPC result (no boundary match) falls through to Path 2 geocode rather than dead-ending
- Added `adminRpc` import from `../lib/supabase.js`

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Path 1.5 to /representatives/me route** - `493aba0` (feat)

**Plan metadata:** _(see below)_

## Files Created/Modified

- `backend/src/routes/essentials.ts` - Added adminRpc import; combined two pool.query calls into one; inserted Path 1.5 block between Path 1 and Path 2

## Decisions Made

- `adminRpc` is exported from `../lib/supabase.js` — confirmed by grepping connect.ts import (plan frontmatter incorrectly said `../lib/supabaseAdmin.js`)
- Write-back is intentionally fire-and-forget: response latency is not affected by the UPDATE completing
- Path 1.5 uses the same `jd.congressional || jd.state_senate` gate as Path 1 — if the RPC returns all nulls, we fall through to Path 2 so home_address geocoding can still work

## Deviations from Plan

None - plan executed exactly as written. The plan itself had an inline IMPORTANT CORRECTION noting the right import path (`../lib/supabase.js`), which was followed.

## Issues Encountered

None. `npx tsc --noEmit` had one pre-existing error in `src/lambda/sqs-worker.ts` (missing `aws-lambda` types) unrelated to this plan — no new errors introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Path 1.5 live in essentials.ts — pre-Phase-49 users will now receive correct representatives on first request after deploy, and subsequent requests will hit fast Path 1
- Phase 50-02 (backfill script) can now be executed — it bulk-populates geo_ids for all users with encrypted_lat so Path 1.5 becomes unnecessary at steady state

---
*Phase: 50-precise-representatives-pre-phase-49-users*
*Completed: 2026-04-01*
