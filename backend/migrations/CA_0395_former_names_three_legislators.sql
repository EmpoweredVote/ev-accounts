-- CA_0395: the earlier names of three sitting legislators, in essentials.politicians.alternate_names.
--
-- Why. A legislature's roll call prints the name a member held on the day of the vote. The roll-call readers
-- (src/lib/stateRollCallEvidence.ts) match a printed label to the politician's stored name, so a vote cast under an
-- earlier name gets no line and cannot be cited. From this change the readers also try `alternate_names` when the
-- stored name fits no label on the page (stateRollCallLinesFor / verifyStateRollCallLine, same pull request).
--   - Maryland, md-01, 2026-11-18: Jennifer White Holland's Yes on 2023 SB 1 got no line (the 2023 vote file prints
--     her as "White"; the session's committee pages list "Jennifer White"). It was one of two votes that stopped the
--     desk's standing yes at the write.
--   - Kansas, ks-01, 2026-11-18: the desk matched two members by hand in its compare of roll calls:
--     Arnberger -> Blew and Clayton -> Sawyer-Clayton.
--
-- Evidence for each name (the legislature's own record, read 2026-11-18/19):
--   d80816fc  Jennifer White Holland   was "Jennifer White": mgaleg.maryland.gov 2023RS vote files and committee pages
--                                      (md/HANDOVER-B.md: "Jennifer White" (2023) prints a name that is not the stored one).
--   f4c40416  Tory Marie Blew          was "Tory Arnberger": printed in full on kslegislature.gov roll calls
--                                      (11 stored Kansas vote records name "Tory Arnberger").
--   4e794e5d  Stephanie Sawyer Clayton was "Stephanie Clayton": her member id on kslegislature.gov is
--                                      rep_clayton_stephanie_1 (230 uses in the Kansas vote data), and the reader
--                                      renders a member from that id.
--
-- Values overwritten (the rule: a migration records what it replaces). Read from production 2026-11-19:
--   d80816fc-da1d-48f4-95c9-467f8831933c  alternate_names = '{}'
--   f4c40416-ec82-443a-917a-9c3b7d5dd031  alternate_names = '{}'
--   4e794e5d-ab7d-4012-9369-f1f3f04e4dca  alternate_names = '{}'
-- To undo: set alternate_names back to '{}' on these three ids.
--
-- A name is added, never replaced: a value already in the array is kept, and a second run changes nothing.
-- No Season data, seat, term or stance is touched.

BEGIN;

WITH names (id, full_name, was) AS (
  VALUES
    ('d80816fc-da1d-48f4-95c9-467f8831933c'::uuid, 'Jennifer White Holland',   'Jennifer White'),
    ('f4c40416-ec82-443a-917a-9c3b7d5dd031'::uuid, 'Tory Marie Blew',          'Tory Arnberger'),
    ('4e794e5d-ab7d-4012-9369-f1f3f04e4dca'::uuid, 'Stephanie Sawyer Clayton', 'Stephanie Clayton')
)
UPDATE essentials.politicians p
   SET alternate_names = array_append(coalesce(p.alternate_names, '{}'), n.was)
  FROM names n
 WHERE p.id = n.id
   AND p.full_name = n.full_name                      -- the id still names the person this was written for
   AND NOT (coalesce(p.alternate_names, '{}') @> ARRAY[n.was]);

DO $$
DECLARE
  ok integer;
BEGIN
  SELECT count(*) INTO ok
    FROM essentials.politicians p
   WHERE (p.id = 'd80816fc-da1d-48f4-95c9-467f8831933c' AND p.full_name = 'Jennifer White Holland'   AND p.alternate_names @> ARRAY['Jennifer White'])
      OR (p.id = 'f4c40416-ec82-443a-917a-9c3b7d5dd031' AND p.full_name = 'Tory Marie Blew'          AND p.alternate_names @> ARRAY['Tory Arnberger'])
      OR (p.id = '4e794e5d-ab7d-4012-9369-f1f3f04e4dca' AND p.full_name = 'Stephanie Sawyer Clayton' AND p.alternate_names @> ARRAY['Stephanie Clayton']);
  IF ok <> 3 THEN
    RAISE EXCEPTION 'CA_0395: expected 3 people to carry their earlier name, found %', ok;
  END IF;
  RAISE NOTICE 'CA_0395: 3 of 3 people carry their earlier name';
END $$;

COMMIT;
