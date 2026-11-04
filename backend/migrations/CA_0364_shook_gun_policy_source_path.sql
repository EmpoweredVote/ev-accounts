-- CA_0364: give Steven Shook's (TX-26) gun-policy context row a path, so its citation points at the section that
-- carries the claim instead of the bare campaign root.
--
-- Found 2026-11-04: `stance sourcing` went red on master with one PRIMARY_SITE_NO_PATH row not in the recorded
-- backlog -- tx Steven Shook / Gun Policy, identity
-- df786fca-5c25-4954-8909-06b491ac0565:56125933-b82a-46c5-847b-b2e9a146b89f:7b3a066c-815d-43b2-a6a0-6a3029778075,
-- sources {https://shookforcongress.com}. Written by gun-policy Season 3 Stage 5 (#1295); the two own-words
-- findings it rests on are in backend/data/source-store/findings/df786fca-5c25-4954-8909-06b491ac0565.json.
--
-- The site is one page. Read 2026-11-04: both quoted bullets ("Close loopholes that allow guns to be sold without
-- background checks." and "Support red-flag laws to keep firearms away from those who pose an imminent danger.")
-- appear verbatim under "Public Safety & Gun Violence Prevention" inside the section the nav labels
-- "Policies & Issues", anchor #17b945f4-7126-4ae7-b5ce-14b44729811e. Same shape as 1512's HOMEPAGE_ANCHOR repairs.
--
-- 🔴 SAME HOST ON PURPOSE. shookforcongress.com now 307s to shookforcongress2026.com, which serves the page above.
-- The new host is very likely the same campaign, but a host change is not a path repair (see
-- scripts/emit-repoint-migration.mjs); the runner chose to keep the cited host and add the anchor.
--
-- Old value, recorded here because the UPDATE overwrites it: sources = '{https://shookforcongress.com}'.
-- Guarded on the exact old array: idempotent, and it refuses a row someone has since edited.

BEGIN;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id = 'df786fca-5c25-4954-8909-06b491ac0565'
     AND topic_id      = '56125933-b82a-46c5-847b-b2e9a146b89f'
     AND season_id     = '7b3a066c-815d-43b2-a6a0-6a3029778075'
     AND sources IN (ARRAY['https://shookforcongress.com'],
                     ARRAY['https://shookforcongress.com/#17b945f4-7126-4ae7-b5ce-14b44729811e']);
  IF n <> 1 THEN RAISE EXCEPTION 'pre-flight: expected Shook gun-policy context row as authored, found % rows', n; END IF;
END $$;

UPDATE inform.politician_context
   SET sources = ARRAY['https://shookforcongress.com/#17b945f4-7126-4ae7-b5ce-14b44729811e']
 WHERE politician_id = 'df786fca-5c25-4954-8909-06b491ac0565'
   AND topic_id      = '56125933-b82a-46c5-847b-b2e9a146b89f'
   AND season_id     = '7b3a066c-815d-43b2-a6a0-6a3029778075'
   AND sources = ARRAY['https://shookforcongress.com'];

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id = 'df786fca-5c25-4954-8909-06b491ac0565'
     AND topic_id      = '56125933-b82a-46c5-847b-b2e9a146b89f'
     AND season_id     = '7b3a066c-815d-43b2-a6a0-6a3029778075'
     AND sources = ARRAY['https://shookforcongress.com/#17b945f4-7126-4ae7-b5ce-14b44729811e'];
  IF n <> 1 THEN RAISE EXCEPTION 'post-verify: expected Shook gun-policy row re-pointed, found %', n; END IF;
END $$;

COMMIT;
