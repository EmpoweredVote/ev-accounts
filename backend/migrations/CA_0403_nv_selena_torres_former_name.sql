-- CA_0403: Nevada Sen. Selena Torres-Fossett carries the name the Legislature's vote pages print for her in
-- 2019-2023, "Selena Torres", in essentials.politicians.alternate_names.
--
-- Why. The Nevada roll-call reader (src/lib/stateRollCallEvidence.ts, PR "read Nevada's own vote pages for Open
-- States votes") names each member as NELIS prints them on the day of the vote. NELIS lists her as
-- "Torres, Selena" on every Assembly vote of the 80th, 81st and 82nd sessions (2019, 2021, 2023) and as
-- "Torres-Fossett, Selena" from 2025. The line tool and the verifier match a printed name to the person's full name
-- or an alternate name, so her 27 votes in the gun-policy dry batch of 2026-11-19 got no line (runner's ruling
-- 2026-11-19: add the name).
--
-- Evidence (the legislature's own record, read 2026-11-19):
--   https://www.leg.state.nv.us/App/NELIS/REL/80th2019/Bill/GetBillVoteMembers?voteKey=6556&voteResultPanel=All
--   lists "Torres, Selena" (Assembly, 2019 AB 168); the 2025 member list voteKey=12948 lists "Torres-Fossett, Selena".
--   The Open States dump holds both as one person (ocd-person, Assembly District 3), and its 2023 votes name her
--   "Torres, Selena" on the same person record its 2025 votes name "Torres-Fossett, Selena".
--   No other politician row is named "Selena ... Torres ..." or carries "Selena Torres" (read 2026-11-19).
--
-- Value overwritten (the rule: a migration records what it replaces). Read from production 2026-11-19:
--   0f31ccad-c79c-43cb-bb06-9392b9b2c908  alternate_names = '{}'
-- To undo: set alternate_names back to '{}' on this id.
--
-- A name is added, never replaced: a second run changes nothing. No Season data, seat, term or stance is touched.

BEGIN;

UPDATE essentials.politicians p
   SET alternate_names = array_append(coalesce(p.alternate_names, '{}'), 'Selena Torres')
 WHERE p.id = '0f31ccad-c79c-43cb-bb06-9392b9b2c908'
   AND p.full_name = 'Selena Torres-Fossett'           -- the id still names the person this was written for
   AND NOT (coalesce(p.alternate_names, '{}') @> ARRAY['Selena Torres']);

DO $$
DECLARE
  ok integer;
BEGIN
  SELECT count(*) INTO ok
    FROM essentials.politicians p
   WHERE p.id = '0f31ccad-c79c-43cb-bb06-9392b9b2c908'
     AND p.full_name = 'Selena Torres-Fossett'
     AND p.alternate_names @> ARRAY['Selena Torres'];
  IF ok <> 1 THEN
    RAISE EXCEPTION 'CA_0403: expected Selena Torres-Fossett to carry "Selena Torres", found %', ok;
  END IF;
  RAISE NOTICE 'CA_0403: Selena Torres-Fossett carries "Selena Torres"';
END $$;

COMMIT;
