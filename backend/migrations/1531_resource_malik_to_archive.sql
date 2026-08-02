-- 1531_resource_malik_to_archive.sql
--
-- Re-point all 19 Faizah Malik rows from her dead campaign site to the Wayback capture that still
-- carries the content they rest on. Nothing is retired and no stance value changes.
--   Review: data/stance-retirement/2026-08-02-dead-site-resourcing.md
--
-- faizahforla.com now returns 404 on every variant. This is the 1519 remedy exactly: the research was
-- sound, the site simply went away, and an archive that demonstrably contains the claims is a better
-- citation than a dead link.
--
-- 🔴 THE CAPTURE WAS VERIFIED TO CARRY THE CLAIMS, NOT MERELY TO EXIST. Snapshot 20260609024810
-- archives EIGHT pages including /policy, /housing-tenants-rights, /homelessness and
-- /immigrants-rights, and every specific these rows assert is present in it:
--   "50,000" sidewalk repair backlog · "Windward" Plaza · "sanctuary" (x5) · "rapid response" teams ·
--   "Public Counsel" · "climate-resilient" · "Venice Dell" (x6)
-- That matters because a Wayback record can be a bare landing page that proves nothing -- which is
-- exactly the situation for Erin Jemison, whose only capture is 2,026 chars and confirms none of her
-- claims, so her 10 rows are deliberately NOT re-sourced here.
--
-- ⚠ SCOPE NOTE, WORTH MORE THAN THIS MIGRATION. The 2026-08-01 reachability sweep reported only SIX
-- Malik rows, because its query required EVERY source on a row to be a bare host. Rows that pair the
-- dead host with a second pathed source were invisible to it. The true count is 19. The sweep
-- undercounts dead-citation exposure across the board, and a deep-URL sweep is owed.

BEGIN;

UPDATE inform.politician_context
   SET sources = array_replace(sources,
                   'https://www.faizahforla.com/',
                   'https://web.archive.org/web/20260609024810/https://www.faizahforla.com/')
 WHERE politician_id = 'a9882d8b-b20d-4b0c-b509-c2883b4352e0'
   AND 'https://www.faizahforla.com/' = ANY(sources);

DO $$
DECLARE v_n int;
BEGIN
  -- Every one of the 19 must now cite the archive...
  SELECT count(*) INTO v_n FROM inform.politician_context pc
    JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
   WHERE pc.politician_id = 'a9882d8b-b20d-4b0c-b509-c2883b4352e0' AND pa.value <> 0
     AND 'https://web.archive.org/web/20260609024810/https://www.faizahforla.com/' = ANY(pc.sources);
  IF v_n <> 19 THEN RAISE EXCEPTION 'expected 19 Malik rows citing the archive, found %', v_n; END IF;

  -- ...and none may still point at the dead site, in any variant.
  SELECT count(*) INTO v_n FROM inform.politician_context pc
   WHERE pc.politician_id = 'a9882d8b-b20d-4b0c-b509-c2883b4352e0'
     AND EXISTS (SELECT 1 FROM unnest(pc.sources) s
                  WHERE s ILIKE '%faizahforla%' AND s NOT ILIKE '%web.archive.org%');
  IF v_n <> 0 THEN RAISE EXCEPTION '% Malik row(s) still cite the dead site directly', v_n; END IF;
END $$;

COMMIT;
