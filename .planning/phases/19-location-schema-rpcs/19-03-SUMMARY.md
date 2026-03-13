---
phase: 19-location-schema-rpcs
plan: 03
subsystem: database
tags: [postgres, postgis, pgcrypto, supabase-vault, migrations, tiger-line]

requires:
  - phase: 19-01
    provides: Migration files 031 and 032 for location schema and RPCs
  - phase: 19-02
    provides: docs/RUNBOOK-TIGER-LOAD.md operator guide for Vault secret and TIGER/Line load

provides:
  - Migrations 031 and 032 applied to production DB — columns, table, and RPCs live
  - inform.district_boundaries populated with Indiana TIGER/Line 2024 data (5 district types)
  - Vault secret 'location_encryption_key' created in Supabase Vault
  - End-to-end smoke test confirmed: bytea ciphertext storage + jurisdiction resolution working

affects: [20-location-endpoints]

tech-stack:
  added: []
  patterns:
    - "convert_from(pgp_sym_decrypt_bytea(...), 'UTF8') for bytea→text decode — ::text cast gives hex"
    - "public.geometry as DECLARE type when SET search_path = '' — geometry type is in public schema, not extensions"
    - "DO block with pg_policies check replaces CREATE POLICY IF NOT EXISTS — unsupported in Supabase Postgres 17.4"

key-files:
  created: []
  modified:
    - backend/migrations/031_location_schema.sql
    - backend/migrations/032_location_rpcs.sql
    - supabase/migrations/20260310000032_location_rpcs.sql

key-decisions:
  - "convert_from(bytea, 'UTF8') not bytea::text — ::text on bytea returns hex repr (\\x33392e...), not the original string"
  - "PostGIS types (geometry) are in public schema; PostGIS functions (ST_*) are in extensions schema — different schemas for types vs functions"
  - "public.geometry required in DECLARE block with SET search_path = '' — extensions.geometry is not a valid type reference"
  - "CREATE POLICY IF NOT EXISTS not supported in Supabase Postgres 17.4 — replaced with DO block checking pg_policies"
  - "Session-mode pooler (pooler.supabase.com:5432) supports multi-statement SQL for these migrations — direct connection not required in this case"

patterns-established:
  - "Bytea decrypt pattern: convert_from(extensions.pgp_sym_decrypt_bytea(col, key), 'UTF8')::float8"

duration: ~35 minutes (automated apply + human runbook execution)
completed: 2026-03-12
---

# Phase 19 Plan 03: Apply & Verify Migrations Summary

**Migrations 031 and 032 applied to production, Indiana TIGER/Line boundaries loaded, Vault secret created, and all 5 Phase 19 success criteria confirmed via direct DB smoke tests.**

## Performance

- **Duration:** ~35 minutes (automated + human checkpoint execution)
- **Started:** 2026-03-12
- **Completed:** 2026-03-12
- **Tasks:** 2 (Task 1 automated, checkpoint approved by human)
- **Files modified:** 2 migration files (bug fixes applied during apply)

## Accomplishments

- Applied migration 031 to production: `connect.connected_profiles` gained `encrypted_lat`, `encrypted_lng`, `location_consent`, `location_set_at` columns; `inform.district_boundaries` table created with GIST/btree indexes and RLS authenticated read policy.
- Applied migration 032 to production: `connect.upsert_user_location` and `connect.resolve_user_jurisdiction` SECURITY DEFINER RPCs created and callable.
- Human operator completed RUNBOOK-TIGER-LOAD.md: Vault secret created, 5 Indiana TIGER/Line shapefiles loaded into `inform.district_boundaries`, all row counts verified (9 CD, 50 state_senate, 100 state_house, 92 county, 200+ school_district).
- All 5 Phase 19 success criteria confirmed: bytea ciphertext storage, Bloomington GEOID '1809', correct Monroe County district resolution, no raw coordinates in RPC return value, runbook executed.

## Task Commits

1. **Task 1: Apply migrations 031 and 032** — `b78b1a9` (feat) — schema + RPCs in DB
2. **Bug fix: CREATE POLICY IF NOT EXISTS syntax** — `b78b1a9` (bundled) — 031 migration fixed
3. **Bug fix: geometry type + convert_from decode** — `7ed0a84` (fix) — 032 migration fixed, applied to DB

**Plan metadata:** (this commit)

## Files Created/Modified

- `backend/migrations/031_location_schema.sql` — replaced `CREATE POLICY IF NOT EXISTS` with DO block (Postgres 17.4 compatibility)
- `backend/migrations/032_location_rpcs.sql` — changed `v_point` DECLARE type from bare `geometry` to `public.geometry`; changed decrypt decode from `::text::float8` to `convert_from(..., 'UTF8')::float8`; changed `extensions.ST_*` to `public.ST_*` in resolve_user_jurisdiction (PostGIS functions in public schema on this Supabase instance, confirmed by smoke test)
- `supabase/migrations/20260310000032_location_rpcs.sql` — same fixes as backend/migrations/032

## Decisions Made

- **`convert_from(bytea, 'UTF8')` not `bytea::text`** — `bytea::text` in PostgreSQL produces a hex representation (`\x33392e31363533`) rather than the original string. `convert_from()` correctly decodes the raw bytes back to UTF-8 text. This was the critical bug that prevented `resolve_user_jurisdiction` from returning numeric floats.
- **`public.geometry` in DECLARE block** — PostGIS installs its type definitions into the `public` schema and its functions into the `extensions` schema. With `SET search_path = ''`, bare `geometry` is unresolved. Must use `public.geometry` for the variable declaration.
- **Session-mode pooler (port 5432) accepted multi-statement SQL** — The `.env` DATABASE_URL points to `aws-0-us-west-1.pooler.supabase.com:5432` (session mode), which handled these migrations without issue. The project concern about pooler is specifically for the transaction-mode pooler (port 6543).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `CREATE POLICY IF NOT EXISTS` syntax error in migration 031**

- **Found during:** Task 1 (applying migration 031)
- **Issue:** `psql` returned `syntax error at or near "NOT"` — Supabase Postgres 17.4 does not support `IF NOT EXISTS` on `CREATE POLICY` statements
- **Fix:** Replaced with a `DO $$` block that queries `pg_policies` to check existence before creating. The policy was created successfully via direct SQL after confirming it didn't exist.
- **Files modified:** `backend/migrations/031_location_schema.sql`
- **Verification:** `SELECT tablename, policyname FROM pg_policies WHERE schemaname='inform'` returned the policy row
- **Committed in:** `b78b1a9`

**2. [Rule 1 - Bug] Bare `geometry` type unresolved with `SET search_path = ''` in migration 032**

- **Found during:** Task 1 (applying migration 032, second function `resolve_user_jurisdiction`)
- **Issue:** `type "geometry" does not exist` — with `SET search_path = ''`, the unqualified `geometry` type in the `DECLARE` block couldn't be resolved
- **Fix:** Changed `v_point geometry` to `v_point public.geometry` (PostGIS types are in `public` schema in Supabase)
- **Files modified:** `backend/migrations/032_location_rpcs.sql`
- **Verification:** `CREATE FUNCTION` succeeded; RPC exists in `information_schema.routines`
- **Committed in:** `b78b1a9`

**3. [Rule 1 - Bug] `bytea::text` decode produces hex string not original value**

- **Found during:** Checkpoint human execution (Step 5 RPC smoke tests)
- **Issue:** `resolve_user_jurisdiction` was returning null or incorrect GEOID — `pgp_sym_decrypt_bytea(...)::text` yields `\x33392e31363533` (hex) not `39.1653`, so `::float8` cast failed
- **Fix:** Changed decode chain from `...::text::float8` to `convert_from(..., 'UTF8')::float8` in both lat and lng decrypt lines
- **Files modified:** `backend/migrations/032_location_rpcs.sql`, `supabase/migrations/20260310000032_location_rpcs.sql`
- **Verification:** `resolve_user_jurisdiction` returned `{"congressional": "1809", ...}` with correct Monroe County GEOIDs for Bloomington coordinates
- **Committed in:** `7ed0a84`

---

**Total deviations:** 3 auto-fixed (3 bugs)
**Impact on plan:** All three fixes were necessary for correctness — without them, the migrations would not apply or the RPCs would not produce correct output. No scope creep.

## Issues Encountered

- The 19-01 summary documented `extensions.ST_*` as the correct prefix pattern (based on Supabase docs). On this Supabase instance, PostGIS functions may be in `public` rather than `extensions` — confirmed by smoke test passing. The `extensions.` prefix pattern in the 19-01 summary should be treated as instance-dependent.

## User Setup Required

None — Vault secret creation and TIGER/Line data load were completed by the operator following `docs/RUNBOOK-TIGER-LOAD.md`.

## Next Phase Readiness

- Phase 20 (Location Endpoints) is unblocked: `connect.upsert_user_location` and `connect.resolve_user_jurisdiction` are live in production and smoke-tested.
- Phase 20 can build `POST /account/location` and `GET /account/jurisdiction` against the working RPC layer.
- No blockers or outstanding concerns.

---
*Phase: 19-location-schema-rpcs*
*Completed: 2026-03-12*
