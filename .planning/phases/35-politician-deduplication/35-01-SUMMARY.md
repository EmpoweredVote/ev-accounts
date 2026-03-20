---
phase: 35-politician-deduplication
plan: 01
subsystem: database
tags: [postgres, migration, deduplication, fk, rpc, essentials, inform]

# Dependency graph
requires:
  - phase: 34-database-schema-migration
    provides: RLS enabled on all 6 schemas including essentials and empower; clean slate for FK reassignment
provides:
  - public.politician_id_bridge table with 30 rows mapping inform → essentials UUIDs
  - inform.politician_answers FK now references essentials.politicians
  - inform.politician_context FK now references essentials.politicians
  - empower.empowered_profiles FK now references essentials.politicians
  - connect.confirm_vq_stance RPC rebuilt to validate against essentials.politicians
  - public.admin_list_politicians RPC rebuilt to query essentials.politicians
  - 4 politicians (Bass, Barragan, Cardenas, Cisneros) inserted into essentials.politicians
  - inform.politicians table dropped
affects:
  - 36-express-ports-wave1 (any endpoints using inform.politicians must now reference essentials.politicians)
  - 38-express-ports-wave3-essentials (admin_list_politicians return shape changed)
  - seedPoliticians.ts (targets inform.politicians — must be updated to target essentials.politicians)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Bridge table pattern: public.politician_id_bridge as permanent audit trail for UUID migrations"
    - "Identity insert pattern: 4 unmatched politicians inserted into essentials with their original inform UUIDs (essentials_id = inform_id)"

key-files:
  created:
    - supabase/migrations/20260320000050_phase35_politician_deduplication.sql
  modified: []

key-decisions:
  - "4 politicians not in essentials (Bass, Barragan, Cardenas, Cisneros) were INSERTed into essentials.politicians using their original inform UUIDs — identity mapping avoids data migration for their answers/context rows"
  - "Alex Padilla mapped to essentials UUID 2717ff94 (the one with office_id set — most complete record among 3 duplicates)"
  - "admin_list_politicians return signature changed: removed inform-specific columns (district_type, district_id, district_label, chamber_name, chamber_name_formal, government_name, representing_city, representing_state, is_candidate, office_title, created_at); added essentials columns (is_incumbent, party, party_short_name, slug, bio_text)"
  - "admin_list_politicians now filters to only return politicians with answer or context rows (not all 1,854 essentials records)"
  - "empower.empowered_profiles had an undocumented FK to inform.politicians (all NULL values) — reassigned to essentials.politicians"
  - "FK constraints must be dropped BEFORE UPDATE when reassigning to a different parent table (Postgres validates FK on UPDATE against current constraint)"

patterns-established:
  - "UUID bridge table: create before DROP TABLE; inform_id has no FK since parent table is dropped in same migration"
  - "Drop FKs before UPDATE when reassigning to different parent; re-add after"

# Metrics
duration: 13min
completed: 2026-03-20
---

# Phase 35 Plan 01: Politician Deduplication Summary

**Atomic SQL migration drops inform.politicians (30 records) and establishes essentials.politicians as sole source of truth via bridge table, FK reassignment on 3 tables, and rebuilds of confirm_vq_stance + admin_list_politicians RPCs**

## Performance

- **Duration:** 13 min
- **Started:** 2026-03-20T05:26:46Z
- **Completed:** 2026-03-20T05:39:35Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Created `public.politician_id_bridge` with 30 rows (26 name-matched + 4 identity-inserted)
- Reassigned `politician_id` FK in `inform.politician_answers` (588 rows), `inform.politician_context` (500 rows), and `empower.empowered_profiles` to reference `essentials.politicians`
- Rebuilt `connect.confirm_vq_stance` to validate politician existence against `essentials.politicians`
- Rebuilt `public.admin_list_politicians` to query `essentials.politicians` (updated return signature)
- Dropped `inform.politicians` — zero orphaned rows after migration
- RLS + public read policy added to bridge table

## Task Commits

Each task was committed atomically:

1. **Task 1: Query production for UUID mapping data** — query-only, no commit (no files changed)
2. **Task 2: Write and apply the atomic deduplication migration** — `5931936` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified

- `supabase/migrations/20260320000050_phase35_politician_deduplication.sql` — Full atomic migration: bridge table, FK reassignment, RPC rebuilds, DROP TABLE

## Decisions Made

- **4 unmatched politicians identity-inserted:** Karen Bass (mayor), Nanette Barragan (congressional), Tony Cardenas (former congressional), Gilbert Cisneros (former congressional) had no records in essentials.politicians. Rather than deleting their 82 answers + ~60 context rows, they were inserted into essentials with their original inform UUIDs. This is the cleanest path — avoids data loss, keeps audit trail complete.
- **Padilla selection:** 3 Alex Padilla records exist in essentials. The one with `office_id = 24a4f107-b36c-4291-82c1-347235e31226` (UUID `2717ff94`) was chosen as the most complete record.
- **admin_list_politicians return shape changed:** essentials.politicians doesn't have `district_type`, `district_id`, `office_title`, `representing_city`, etc. New shape uses essentials-native columns: `is_incumbent`, `party`, `party_short_name`, `slug`, `bio_text`. Frontend admin UI will need updating in a later phase.
- **admin_list_politicians filters to relevant records:** Instead of returning all 1,854 essentials politicians, the new function only returns politicians that have answer or context rows.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] FK constraint ordering — drop before UPDATE, not after**
- **Found during:** Task 2 (applying migration)
- **Issue:** Original plan dropped FK constraints after reassigning data. Postgres validates FK on every UPDATE against the current constraint (pointing to inform.politicians). Writing essentials UUIDs into politician_answers failed with FK violation.
- **Fix:** Reordered steps — drop all FK constraints first, then UPDATE data, then add new FK constraints pointing to essentials.politicians.
- **Files modified:** supabase/migrations/20260320000050_phase35_politician_deduplication.sql
- **Verification:** Migration applied cleanly; zero orphaned rows confirmed.
- **Committed in:** 5931936

**2. [Rule 2 - Missing Critical] empower.empowered_profiles FK undocumented dependency**
- **Found during:** Task 2 (applying migration — DROP TABLE failed)
- **Issue:** Plan did not document that `empower.empowered_profiles.politician_id` also references `inform.politicians`. DROP TABLE failed with "constraint empowered_profiles_politician_id_fkey depends on table inform.politicians".
- **Fix:** Added DROP + re-add for `empowered_profiles_politician_id_fkey` in migration (all values NULL, no data migration needed).
- **Files modified:** supabase/migrations/20260320000050_phase35_politician_deduplication.sql
- **Verification:** Migration applied successfully after fix; constraint now references essentials.politicians.
- **Committed in:** 5931936

**3. [Rule 3 - Blocking] inform.politicians had 30 records, not 4 as researched**
- **Found during:** Task 1 (production query)
- **Issue:** Research document stated "4 seed records". Production had 30 politicians with full data (588 answers, 500 context rows).
- **Fix:** Queried all 30 records, built complete name-match mapping for all of them.
- **Impact:** Required more work than planned but all handled automatically.
- **Committed in:** 5931936

---

**Total deviations:** 3 auto-fixed (1 bug, 1 missing critical, 1 blocking)
**Impact on plan:** All auto-fixes necessary for correct migration. No scope creep. One migration file as planned.

## Issues Encountered

- **Alex Padilla duplicate in essentials:** 3 records with the same name. Selected the one with `office_id` set as most authoritative. The other 2 duplicates remain in essentials (data quality issue in EV-Backend's import, out of scope for this phase).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `essentials.politicians` is now the sole source of truth for politician identity
- Plan 02 (adminSetPoliticianContext PostgREST fix) is unblocked — it can now target `essentials.politicians` via pool.query()
- `scripts/seedPoliticians.ts` still targets `inform.politicians` — will error on next run; needs update before any re-seeding
- Admin UI admin_list_politicians response shape has changed — consumer code needs to handle new columns (is_incumbent, party, party_short_name, slug, bio_text) instead of old inform-specific columns

---
*Phase: 35-politician-deduplication*
*Completed: 2026-03-20*
