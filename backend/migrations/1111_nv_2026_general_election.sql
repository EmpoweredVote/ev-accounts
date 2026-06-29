-- Migration 1111: Seed NV 2026 Statewide General election row
--
-- Phase 167-01 (v18.0 NV 2026 Elections & Discovery). Seeds the single foundational
-- essentials.elections row for Nevada's November 3, 2026 statewide general election.
-- Every race row in migration 1112 resolves its election_id FK by name-matching this row,
-- so it must exist first.
--
-- Election name convention: 'NV 2026 Statewide General' — follows the {ST} 2026 Statewide General
-- pattern established by migration 1109 (TX/NY). NOT the older VA/MD style ('2026 Virginia General
-- Election'). This exact casing is required — Plan 02 race rows JOIN on this literal string.
--
-- Idempotent: NOT EXISTS guard on (name). A re-run inserts 0 rows.
-- No schema_migrations ledger INSERT — the on-disk counter is authoritative (matches 1109 pattern).

BEGIN;

-- 1. The NV 2026 statewide general election (mirrors CA/TX/NY 2026 Statewide General shape).
INSERT INTO essentials.elections (id, name, election_date, election_type, jurisdiction_level, state)
SELECT gen_random_uuid(), 'NV 2026 Statewide General', '2026-11-03T08:00:00.000Z'::timestamptz, 'general', 'state', 'NV'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.elections e WHERE e.name = 'NV 2026 Statewide General'
);

-- 2. Post-write assertion (abort the transaction if the invariant fails).
DO $$
DECLARE
  n_elections int;
BEGIN
  SELECT count(*) INTO n_elections FROM essentials.elections
   WHERE name = 'NV 2026 Statewide General';
  IF n_elections <> 1 THEN
    RAISE EXCEPTION 'Expected 1 NV election, found %', n_elections;
  END IF;
  RAISE NOTICE 'OK: NV 2026 Statewide General election row present';
END $$;

COMMIT;
-- NO schema_migrations ledger INSERT (matches 1109 pattern; on-disk counter is authoritative)
