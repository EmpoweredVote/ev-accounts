-- CA_0353_jerry_carl_bioguide_id.sql
-- Author: Chris Andrews (CA_ namespace). Slot reserved from the steward allocator 2026-11-03.
--
-- =============================================================================
-- CA_0353: set politicians.bioguide_id = 'C001054' on Jerry Carl (former U.S. House member, AL-1, 2021-2025)
-- =============================================================================
-- WHY: federal roll-call votes reach a person only through bioguide id (the federal vote loaders and the Stage 5
-- federal lane, #1287, match by it and never by surname). CA_0339 set ids on SITTING members only, so this former
-- member has none and 0 rows in essentials.legislative_votes. The #1287 replay of the voting-rights federal batch
-- held his House roll call 345 (2024) line for exactly this reason (97 of 98 lines).
--
-- SOURCE: the House Clerk's official roll-call XML, https://clerk.house.gov/evs/2024/roll345.xml, fetched
-- 2026-11-03: <legislator name-id="C001054" sort-field="Carl" unaccented-name="Carl" state="AL"
-- role="legislator">Carl</legislator> (party attribute not read).
-- MATCHING: one politician row named Jerry Carl (6a04d1f3-1065-45cb-9084-60906a70383b), no bioguide id, and no
-- other row carries C001054 (checked read-only 2026-11-03). Party is neither read nor written.
--
-- WHAT THIS DOES: sets bioguide_id on that one row, only where it is NULL or empty. Writes nothing else; his votes
-- are loaded afterwards by federal_votes_legiscan.py (a separate, approved run). Idempotent: a re-run updates
-- 0 rows and the gate still passes.
-- GATE: the row carries C001054 and is still named Jerry Carl; no other politician row carries C001054.
--
-- DRY RUN: wrap in BEGIN ... ROLLBACK (replace COMMIT) and confirm afterwards that the row's bioguide id is still
-- empty.
-- Dry run on prod 2026-11-03 (yes #1 from Chris Andrews): UPDATE 1, gate OK (1 set, 0 clashes); rolled back;
-- rows carrying C001054 0 before and 0 after.
-- APPLIED: 2026-11-03 on production, on yes #2 from Chris Andrews. UPDATE 1, gate OK; C001054 now on exactly
-- this row. Then (yes #3 and #4) federal_votes_legiscan.py --congress 117 / 118 --commit added 958 + 1,144 vote
-- rows, all his (rehearsed first; roll 345/2024 = yea, matching the Clerk's Aye). The #1287 replay of voting-rights
-- federal-01 now gives 98/98 House lines, 0 disagree.
-- =============================================================================

BEGIN;

UPDATE essentials.politicians
   SET bioguide_id = 'C001054'
 WHERE id = '6a04d1f3-1065-45cb-9084-60906a70383b'::uuid
   AND coalesce(bioguide_id, '') = ''
   AND first_name = 'Jerry' AND last_name = 'Carl';

DO $$
DECLARE n_set int; n_clash int;
BEGIN
  SELECT count(*) INTO n_set FROM essentials.politicians
   WHERE id = '6a04d1f3-1065-45cb-9084-60906a70383b'::uuid AND bioguide_id = 'C001054'
     AND first_name = 'Jerry' AND last_name = 'Carl';
  SELECT count(*) INTO n_clash FROM essentials.politicians
   WHERE bioguide_id = 'C001054' AND id <> '6a04d1f3-1065-45cb-9084-60906a70383b'::uuid;
  IF n_set <> 1 THEN RAISE EXCEPTION 'CA_0353: Jerry Carl row does not carry C001054 (% rows)', n_set; END IF;
  IF n_clash <> 0 THEN RAISE EXCEPTION 'CA_0353: C001054 also sits on % other politician row(s)', n_clash; END IF;
  RAISE NOTICE 'CA_0353 gate OK: 1 set, 0 clashes';
END $$;

COMMIT;
