-- CA_0407: two California legislators carry the names the Legislature's vote record prints for them in earlier
-- sessions, in essentials.politicians.alternate_names:
--   Asm. Tasha Boerner         <- "Tasha Boerner Horvath" (2019-2024)
--   Sen. Akilah Weber Pierson  <- "Akilah Weber"          (Assembly, 2021-2024)
--
-- Why. The California roll-call reader (src/lib/stateRollCallEvidence.ts, PR "California reader for the Legislature's
-- PUBINFO download") names each member as the session's member list (LEGISLATOR_TBL) names them: first and last
-- name as of that session. The line tool and the verifier match a printed name to the person's full name or an
-- alternate name, so 323 of their votes in the gun-policy dry batch of 2026-11-20 got no line (190 Akilah Weber
-- Pierson, 133 Tasha Boerner). With these two names as alternate names, all 323 get a line (checked offline against
-- the same cached record, 2026-11-20).
--
-- Evidence (the Legislature's own PUBINFO member tables, downloads.leginfo.legislature.ca.gov, read 2026-11-20):
--   20192020 and 20212022: AD76, first_name 'Tasha', last_name 'Boerner Horvath'.
--   20232024: AD77, two rows, 'Boerner Horvath' and 'Boerner', both first_name 'Tasha'.  20252026: AD77, 'Boerner'.
--   20212022 and 20232024: AD79, first_name 'Akilah', last_name 'Weber', legislator_name 'Weber, M.D., Akilah'.
--   20252026: SD39, first_name 'Akilah', last_name 'Weber Pierson', legislator_name 'Weber Pierson, M.D., Akilah'.
--   The Open States dump holds each as one person across these sessions (ocd-person/9e69729e-... for Tasha Boerner).
--   No other politician row is named "Tasha Boerner Horvath" or "Akilah Weber" (read 2026-11-20).
--
-- Values overwritten (the rule: a migration records what it replaces). Read from production 2026-11-20:
--   0a9171c6-0676-4704-b825-a7e16c66f1c2  Tasha Boerner         alternate_names = '{}'
--   e5470008-3c0d-4970-a485-053621d8f0a6  Akilah Weber Pierson  alternate_names = '{}'
-- To undo: set alternate_names back to '{}' on these two ids.
--
-- A name is added, never replaced: a second run changes nothing. No Season data, seat, term or stance is touched.

BEGIN;

UPDATE essentials.politicians p
   SET alternate_names = array_append(coalesce(p.alternate_names, '{}'), 'Tasha Boerner Horvath')
 WHERE p.id = '0a9171c6-0676-4704-b825-a7e16c66f1c2'
   AND p.full_name = 'Tasha Boerner'                    -- the id still names the person this was written for
   AND NOT (coalesce(p.alternate_names, '{}') @> ARRAY['Tasha Boerner Horvath']);

UPDATE essentials.politicians p
   SET alternate_names = array_append(coalesce(p.alternate_names, '{}'), 'Akilah Weber')
 WHERE p.id = 'e5470008-3c0d-4970-a485-053621d8f0a6'
   AND p.full_name = 'Akilah Weber Pierson'
   AND NOT (coalesce(p.alternate_names, '{}') @> ARRAY['Akilah Weber']);

DO $$
DECLARE
  ok integer;
BEGIN
  SELECT count(*) INTO ok
    FROM essentials.politicians p
   WHERE (p.id = '0a9171c6-0676-4704-b825-a7e16c66f1c2' AND p.full_name = 'Tasha Boerner'
          AND p.alternate_names @> ARRAY['Tasha Boerner Horvath'])
      OR (p.id = 'e5470008-3c0d-4970-a485-053621d8f0a6' AND p.full_name = 'Akilah Weber Pierson'
          AND p.alternate_names @> ARRAY['Akilah Weber']);
  IF ok <> 2 THEN
    RAISE EXCEPTION 'CA_0407: expected both legislators to carry their earlier name, found %', ok;
  END IF;
  RAISE NOTICE 'CA_0407: Tasha Boerner carries "Tasha Boerner Horvath"; Akilah Weber Pierson carries "Akilah Weber"';
END $$;

COMMIT;
