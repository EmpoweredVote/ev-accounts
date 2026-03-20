---
phase: 34-database-schema-migration
plan: 02
subsystem: database
tags: [postgres, rls, supabase, grants, policies, essentials, meetings, treasury, transparent_motivations, compass]

# Dependency graph
requires:
  - phase: 34-01
    provides: "Complete table inventory for 5 schemas with policy category assignments and clean-slate confirmation"
provides:
  - "RLS enabled on all 62 tables across essentials, meetings, treasury, transparent_motivations, compass"
  - "62 SELECT policies applied (36 public-read + 7 public-read + 4 public-read + 7 mixed + 8 mixed)"
  - "GRANT USAGE + GRANT SELECT applied to all 5 schemas for anon and authenticated roles"
  - "ALTER DEFAULT PRIVILEGES set on all 5 schemas for future table inheritance"
  - "Owner-read policies using (select auth.uid()) form for compass user-linked tables"
affects:
  - 34-03 (staging schema RLS — final schema remaining)
  - 36-express-ports-wave-1-treasury-meetings
  - 37-express-ports-wave-2-staging
  - 38-express-ports-wave-3-essentials
  - 39-compass-additions

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "RLS pattern: public-read = USING (true) TO anon, authenticated"
    - "RLS pattern: authenticated-read = USING (true) TO authenticated (no anon)"
    - "RLS pattern: owner-read = USING (user_id::uuid = (select auth.uid())) TO authenticated"
    - "No INSERT/UPDATE/DELETE policies — all writes via service role bypassing RLS"
    - "ALTER DEFAULT PRIVILEGES ensures future tables in schema inherit grants automatically"

key-files:
  created:
    - "supabase/migrations/20260319000044_phase34_essentials_rls.sql"
    - "supabase/migrations/20260319000045_phase34_meetings_rls.sql"
    - "supabase/migrations/20260319000046_phase34_treasury_rls.sql"
    - "supabase/migrations/20260319000047_phase34_transparent_motivations_rls.sql"
    - "supabase/migrations/20260319000048_phase34_compass_rls.sql"
  modified: []

key-decisions:
  - "transparent_motivations.ingestion_runs + source_audit_log: authenticated-read only (not public) — internal pipeline audit data"
  - "compass owner-read policy uses (select auth.uid()) subquery form for query plan caching (not direct auth.uid() call)"
  - "user_id::uuid cast required in compass owner-read policies — column is text type storing UUID-formatted values"
  - "GRANT SELECT + ALTER DEFAULT PRIVILEGES both applied — covers existing tables and future tables added to schema"

patterns-established:
  - "Migration structure: BEGIN; enable RLS; CREATE POLICY per table; GRANT USAGE + SELECT; ALTER DEFAULT PRIVILEGES; COMMIT;"
  - "Policy naming: '{table}: public read', '{table}: authenticated read', '{table}: owner read' — consistent across all schemas"

# Metrics
duration: 22min
completed: 2026-03-20
---

# Phase 34 Plan 02: Database Schema Migration — RLS Summary

**RLS enabled on all 62 tables across 5 schemas (essentials/meetings/treasury/transparent_motivations/compass) with 62 SELECT policies and schema-level GRANT USAGE applied to production.**

## Performance

- **Duration:** 22 min
- **Started:** 2026-03-20T02:37:35Z
- **Completed:** 2026-03-20T02:59:20Z
- **Tasks:** 2
- **Files modified:** 5 (migration SQL files created)

## Accomplishments

- Applied RLS to all 62 tables across 5 schemas — verified via `pg_tables` query returning 0 rows with `rowsecurity = false`
- Created 62 SELECT policies: 51 public-read (anon+authenticated), 2 authenticated-read only (transparent_motivations admin audit tables), 4 owner-read with `user_id::uuid` cast (compass user tables), 5 additional public-read on compass
- Applied `GRANT USAGE ON SCHEMA` + `GRANT SELECT ON ALL TABLES` + `ALTER DEFAULT PRIVILEGES` to all 5 schemas
- Policy count verification: compass=8, essentials=36, meetings=7, transparent_motivations=7, treasury=4

## Task Commits

1. **Task 1: essentials + meetings + treasury migrations** — `f25a038` (feat)
2. **Task 2: transparent_motivations + compass migrations** — `c2fd547` (feat)

## Files Created/Modified

- `supabase/migrations/20260319000044_phase34_essentials_rls.sql` — 36 tables: RLS enable + 36 public-read policies + grants
- `supabase/migrations/20260319000045_phase34_meetings_rls.sql` — 7 tables: RLS enable + 7 public-read policies + grants
- `supabase/migrations/20260319000046_phase34_treasury_rls.sql` — 4 tables: RLS enable + 4 public-read policies + grants
- `supabase/migrations/20260319000047_phase34_transparent_motivations_rls.sql` — 7 tables: RLS enable + 5 public-read + 2 authenticated-read policies + grants
- `supabase/migrations/20260319000048_phase34_compass_rls.sql` — 8 tables: RLS enable + 4 public-read + 4 owner-read policies + grants

## Decisions Made

1. **transparent_motivations admin tables restricted to authenticated** — `ingestion_runs` and `source_audit_log` are pipeline audit data; anon access would be inappropriate even though no PII. Policy: `TO authenticated USING (true)`.

2. **compass owner-read uses `(select auth.uid())` subquery form** — Required by project constraint for query plan caching. Direct `auth.uid()` would prevent caching; subquery form allows it.

3. **`user_id::uuid` cast required for compass policies** — All 4 compass user-linked tables store `user_id` as `text` type with UUID-formatted values. The cast `user_id::uuid = (select auth.uid())` is necessary because `auth.uid()` returns `uuid`.

4. **Both GRANT and ALTER DEFAULT PRIVILEGES applied** — `GRANT SELECT ON ALL TABLES` covers current tables; `ALTER DEFAULT PRIVILEGES` ensures future tables added to the schema automatically inherit grants without requiring another migration.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

**Connection method discovery:** Direct `pg` Pool connection to the Supavisor pooler URL timed out from the local Windows environment (IPv4/IPv6 routing issue noted in `backend/src/db.ts` — requires Render's IPv4 add-on). Resolved by using `npx supabase db query --linked --file` which was confirmed working in plan 34-01. No impact on outcomes.

## User Setup Required

None — all changes are schema-level SQL applied directly to production via Supabase CLI.

## Next Phase Readiness

- **Plan 34-03 (staging schema):** Final schema needing RLS. 6 tables, all authenticated-read. Unblocked.
- **Phase 36-38 (Express ports):** essentials, meetings, and treasury are now properly protected and ready for endpoint development. Service role writes continue to work (RLS bypassed for service role by default).
- **compass tables:** Owner-read policies are in place. Phase 39 (Compass Additions) can proceed with confidence that user data is gated by `auth.uid()`.

---
*Phase: 34-database-schema-migration*
*Completed: 2026-03-20*
