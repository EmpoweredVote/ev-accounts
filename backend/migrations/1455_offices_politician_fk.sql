-- 1434_offices_politician_fk.sql
-- Repair 2 orphaned office rows, then add the missing FOREIGN KEY on
-- essentials.offices.politician_id. Idempotent.
--
-- WHY THIS IS A PREREQUISITE, not housekeeping: essentials.offices is the table that answers
--   "who represents this address", and its politician_id had NO referential integrity at all.
--   essentials.politicians is referenced by 21 foreign keys across 6 schemas — but offices,
--   the single most important referrer, was not one of them. Verified: zero FK constraints on
--   that column. The consequence is that deleting a politician silently vacated seats instead
--   of failing, which is exactly the failure mode any temporal/term-history work would be
--   built on top of. Fix the foundation first.
--
-- THE 2 ORPHANS (found while auditing the 1450 dedup merge; both predate this branch):
--   IN  'Assessor'            Monroe County Assessor  -> dangling d3977ab4-22b8-4ac3-a14f-565bc2969f1a
--   CA  'U.S. Representative' district_id IS NULL      -> dangling c2881f48-7972-4b8e-8547-a89617fb3069
--   The CA row is doubly broken: with a NULL district_id it cannot match an address at all, so
--   it has been inert rather than serving wrong data.
--
-- REPAIR = set politician_id NULL and flag the seat vacant, NOT delete. An office with no
--   occupant is a legitimate, already-common state (854 rows have NULL politician_id, 161 are
--   flagged vacant). Deleting rows whose history we cannot reconstruct would destroy
--   information; vacating them is honest and reversible.
--
-- ON DELETE NO ACTION is deliberate (matching the majority convention among the existing 21
--   FKs). The alternative, ON DELETE SET NULL, would silently vacate a seat whenever a
--   politician row was deleted — precisely the silent-corruption behaviour this fixes. Failing
--   loudly forces the correct order of operations: re-point the offices, THEN delete the
--   politician. Migration 1450 already had to do exactly that four times; with this constraint
--   in place, getting that order wrong becomes an error instead of a silent orphan.
BEGIN;

-- ── 1. Vacate the 2 orphaned seats ──
UPDATE essentials.offices o
   SET politician_id = NULL,
       is_vacant     = true,
       vacant_since  = coalesce(o.vacant_since, now())
 WHERE o.politician_id IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = o.politician_id);

-- ── 2. Add the FK (idempotent on constraint name) ──
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
     WHERE conname = 'offices_politician_id_fkey'
       AND conrelid = 'essentials.offices'::regclass
  ) THEN
    ALTER TABLE essentials.offices
      ADD CONSTRAINT offices_politician_id_fkey
      FOREIGN KEY (politician_id) REFERENCES essentials.politicians(id);
    RAISE NOTICE 'added offices_politician_id_fkey';
  ELSE
    RAISE NOTICE 'offices_politician_id_fkey already present — skipping';
  END IF;
END $$;

-- ── 3. Post-verify gate ──
DO $$
DECLARE n_orphan int; n_fk int;
BEGIN
  SELECT count(*) INTO n_orphan FROM essentials.offices o
   WHERE o.politician_id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = o.politician_id);
  IF n_orphan <> 0 THEN
    RAISE EXCEPTION '% orphaned office rows remain', n_orphan;
  END IF;

  SELECT count(*) INTO n_fk FROM pg_constraint
   WHERE conname = 'offices_politician_id_fkey' AND conrelid = 'essentials.offices'::regclass;
  IF n_fk <> 1 THEN
    RAISE EXCEPTION 'offices_politician_id_fkey missing after migration';
  END IF;

  RAISE NOTICE 'offices FK verify PASSED: 0 orphans, FK present. Deleting a politician who still holds an office will now fail loudly.';
END $$;

COMMIT;
