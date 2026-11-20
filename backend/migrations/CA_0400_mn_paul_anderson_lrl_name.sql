-- CA_0400: Minnesota Rep. Paul Anderson (12A) carries the Legislative Reference Library's name for him,
-- "Paul H. Anderson", in essentials.politicians.alternate_names.
--
-- Why. The research verifier accepts a Minnesota Revisor bill author by the legislature's own member link
-- (src/lib/mnRevisorAuthors.ts, PR "accept a Minnesota Revisor author by the legislature's member link"): it
-- follows the author link to the LRL record and requires that record to name the person exactly, by full
-- name or an alternate name. A middle initial is never dropped, so that former Sen. Paul T. Anderson (a
-- different member, whose bills the Open States dump once credited to this Paul Anderson) cannot pass for
-- him. The LRL titles this member's record "Paul H. Anderson", so his one sponsorship seat in gun-policy
-- batch mn-01 (2025 HF 636) verified nothing and stayed pending (runner's ruling 2026-11-19: add the name).
--
-- Evidence (the legislature's own record, read 2026-11-19):
--   the Revisor page for 2025 HF 636 lists the author "Anderson, P. H." linked to
--   https://www.house.mn.gov/members/profile/15301 ("Rep. Paul Anderson (12A)"), and
--   https://www.lrl.mn.gov/legdb/fulldetail?ID=15301 is titled "Paul H. Anderson - Legislator Record".
--   Our record's photo_origin_url is the same House profile, .../members/profile/15301.
--   No other politician row is named "Paul <x> Anderson" or carries "Paul H. Anderson" (read 2026-11-19).
--
-- Value overwritten (the rule: a migration records what it replaces). Read from production 2026-11-19:
--   8d46d88e-ad1e-4a88-81c2-782da83d77f1  alternate_names = '{}'
-- To undo: set alternate_names back to '{}' on this id.
--
-- A name is added, never replaced: a second run changes nothing. No Season data, seat, term or stance is touched.

BEGIN;

UPDATE essentials.politicians p
   SET alternate_names = array_append(coalesce(p.alternate_names, '{}'), 'Paul H. Anderson')
 WHERE p.id = '8d46d88e-ad1e-4a88-81c2-782da83d77f1'
   AND p.full_name = 'Paul Anderson'                   -- the id still names the person this was written for
   AND NOT (coalesce(p.alternate_names, '{}') @> ARRAY['Paul H. Anderson']);

DO $$
DECLARE
  ok integer;
BEGIN
  SELECT count(*) INTO ok
    FROM essentials.politicians p
   WHERE p.id = '8d46d88e-ad1e-4a88-81c2-782da83d77f1'
     AND p.full_name = 'Paul Anderson'
     AND p.alternate_names @> ARRAY['Paul H. Anderson'];
  IF ok <> 1 THEN
    RAISE EXCEPTION 'CA_0400: expected Paul Anderson to carry "Paul H. Anderson", found %', ok;
  END IF;
  RAISE NOTICE 'CA_0400: Paul Anderson carries "Paul H. Anderson"';
END $$;

COMMIT;
