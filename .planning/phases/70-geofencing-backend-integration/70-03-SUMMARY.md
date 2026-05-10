---
phase: 70-geofencing-backend-integration
plan: 03
subsystem: database, infra
tags: [postgres, plpgsql, security-definer, vault, pgcrypto, tiger, geofencing, admin-scripts, typescript]

# Dependency graph
requires:
  - phase: 69-tiger-schema-data-import
    provides: essentials.cache_user_districts, connect.user_districts table, TIGER geo_districts data
  - phase: 70-geofencing-backend-integration
    plan: 01
    provides: connect.user_districts table schema + resolve_user_jurisdiction decrypt pattern
provides:
  - essentials.recache_user_districts_for_user(uuid) — per-user admin re-cache RPC
  - essentials.recache_user_districts_bulk(cutoff timestamptz) — bulk re-cache RPC with optional staleness filter
  - backend/scripts/recache-user-districts.ts — operator CLI for post-redistricting bulk refresh
affects:
  - phase: 70-04 — Phase 70-04 can call recache_user_districts_for_user after new location is stored
  - phase: 71-geofencing-frontend-integration — redistricting tooling is now available for post-launch ops

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Per-user + bulk SECURITY DEFINER function pair for admin batch operations
    - Exception-wrapped per-row iteration in bulk RPCs (one bad user never aborts batch)
    - Vault decrypt pattern: convert_from(extensions.pgp_sym_decrypt_bytea(encrypted_bytes, key), 'UTF8')::float8
    - Admin script dry-run pattern: inline replica of SQL HAVING clause for count-only preview

key-files:
  created:
    - supabase/migrations/20260510000001_092_recache_user_districts.sql
    - backend/scripts/recache-user-districts.ts
  modified: []

key-decisions:
  - "Per-user function returns status='no_coords' (not an error) when user lacks consent or stored coords"
  - "layers_resolved=0 with status='ok' signals out-of-CA user; Node.js script logs UUID and tallies separately"
  - "Bulk function wraps each per-user call in BEGIN/EXCEPTION so one bad user never aborts the whole batch"
  - "GRANTs limited to service_role; PUBLIC revoked — operator-only infrastructure"

patterns-established:
  - "Operator admin RPCs: per-user variant + bulk variant, both SECURITY DEFINER SET search_path=''"
  - "Dry-run in admin scripts: inline SQL replica of bulk function's HAVING clause, not a separate RPC"

# Metrics
duration: 3min
completed: 2026-05-10
---

# Phase 70 Plan 03: Bulk Recache User Districts Summary

**Two SECURITY DEFINER Postgres functions (per-user + bulk) + admin CLI that re-caches connect.user_districts post-redistricting, decrypting coords entirely inside Postgres via the Vault location_encryption_key**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-10T04:19:07Z
- **Completed:** 2026-05-10T04:22:08Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Migration 092 applied: `essentials.recache_user_districts_for_user(uuid)` decrypts coords via Vault key, calls `essentials.cache_user_districts`, returns `(user_id, layers_resolved, status)` — returns `status='no_coords'` for unconsented users without raising
- `essentials.recache_user_districts_bulk(cutoff timestamptz)` iterates Connected users (all or filtered by `resolved_at < cutoff`), calls per-user variant per row, wraps each in exception block so one bad user never aborts the batch
- `backend/scripts/recache-user-districts.ts` operator CLI: `--dry-run` (count preview), `--before=YYYY-MM-DD` (staleness filter), `--user=<uuid>` (single user), bulk mode (no flags) — verified live against DB (9 users would be processed)

## Task Commits

1. **Task 1: Migration 092 — recache_user_districts_for_user + _bulk RPCs** - `f220e79` (feat)
2. **Task 2: Node.js orchestrator script — recache-user-districts.ts** - `fb28cd7` (feat)

**Plan metadata:** pending docs commit

## Files Created/Modified

- `supabase/migrations/20260510000001_092_recache_user_districts.sql` — Migration 092: two SECURITY DEFINER RPCs for per-user and bulk district re-cache; GRANTs to service_role only
- `backend/scripts/recache-user-districts.ts` — Operator CLI with --dry-run, --before, --user flags; uses pool.query against the essentials schema; no plaintext coords in Node.js

## Decisions Made

- **`status='no_coords'` instead of raising:** Users without consent or stored coords return a clean status row — the bulk caller tallies them without exception handling overhead.
- **`layers_resolved=0` signals out-of-CA:** Rather than a distinct status value, zero layers with `status='ok'` covers the "point resolved but outside all TIGER districts" case. Node.js logs the UUID separately.
- **Exception wrapping per-row in bulk function:** `BEGIN … EXCEPTION WHEN OTHERS THEN … END` on each per-user call means a Vault error or corrupt coord on user N doesn't roll back users 1–N-1.
- **GRANTs limited to service_role:** These are operator-only RPCs; no reason to expose to authenticated or anon roles.
- **Dry-run as inline SQL replica:** Instead of a separate RPC, the dry-run path in the Node.js script mirrors the bulk function's HAVING clause directly — avoids adding a read-only RPC for what is inherently a script-time preview.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Redistricting tooling complete. Operators can run `npx tsx scripts/recache-user-districts.ts` from `backend/` after any TIGER data update.
- Phase 70-04 can call `essentials.recache_user_districts_for_user(user_id)` immediately after `upsert_user_location` if it wants to synchronously populate `user_districts` at location-set time.
- No blockers for remaining Phase 70 plans.

---
*Phase: 70-geofencing-backend-integration*
*Completed: 2026-05-10*
