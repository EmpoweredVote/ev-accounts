-- 1513_repoint_anderson_renamed_campaign_site.sql
--
-- Re-point 3 stance citations for Jessica L. Anderson (VA HD-71) from her old campaign domain to the
-- domain it now redirects to. NOTHING IS DELETED.
--   Evidence:        data/stance-retirement/2026-07-31-primary-site-paths.json
--   Rollback record: data/stance-retirement/2026-07-31-host-change-rollback.json
--                    (carries the exact prior sources array for all 3 rows)
--
-- WHY THIS IS A SEPARATE MIGRATION FROM 1512. Migration 1512 re-pointed 43 citations from a bare root
-- to a specific page ON THE SAME HOST, and that same-host constraint is the entire reason it was safe
-- to generate mechanically: a script that only ever lengthens a path cannot accidentally substitute a
-- different source. These 3 rows break that constraint, so the generator REFUSED to emit them
-- (scripts/emit-repoint-migration.mjs holds any off-host proposal rather than applying or dropping
-- it). Deciding that two hostnames are the same campaign is a human judgement, and this file is that
-- judgement written down.
--
-- THE EVIDENCE FOR "SAME CAMPAIGN", CHECKED RATHER THAN ASSUMED:
--
--   $ curl -sIL https://jessicaandersonforva.com
--     HTTP/1.1 301 Moved Permanently
--     Location: https://jess4va.com/
--     HTTP/1.1 200 OK
--
--   jess4va.com <title>  Jessica Anderson for Virginia House of Delegates, 71st District
--   jess4va.com socials  facebook.com/jessicaanderson4VAHouseOfDelegates
--
-- So the old domain is not dead and not sold on -- it is a permanent redirect the campaign itself
-- set up after renaming. Citing the destination is citing the same source, at its current address.
--
-- AND THE CLAIMS WERE RE-VERIFIED AT THE DESTINATION, not carried over on the strength of the
-- redirect. All three rows quote jess4va.com/issues (6,847 chars) verbatim:
--
--   School Vouchers  "Jessica knows that a fully funded public education system is critical to the
--                     long-term success of our children"
--   Abortion         "She supports prescription drug affordability, paid family and medical leave,
--                     and will always fight to protect ..."
--   Healthcare       "Jessica believes that high-quality, affordable healthcare that includes
--                     medical, dental, vision, and mental ca..."
--
-- 🔴 A REDIRECT ALONE WOULD NOT HAVE JUSTIFIED THIS. A parked or sold domain also 301s, and it would
-- point at a stranger's site while looking exactly like a rename in the headers. The title, the
-- campaign's own social handle and the verbatim quotes are what separate the two cases. If a future
-- host change cannot clear all of those, hold it for a human again rather than trusting the 301.

BEGIN;

CREATE TEMP TABLE _repoint_1513 (
  politician_id uuid,
  topic_id      uuid,
  old_root      text,
  new_url       text
) ON COMMIT DROP;

INSERT INTO _repoint_1513 (politician_id, topic_id, old_root, new_url) VALUES
  ('a0dfdf20-b736-4a1c-84c1-194a6625358e', '00b95a6a-75db-4521-b523-3326bba938de', 'https://jessicaandersonforva.com', 'https://jess4va.com/issues'),  -- Jessica L. Anderson: School Vouchers
  ('a0dfdf20-b736-4a1c-84c1-194a6625358e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 'https://jessicaandersonforva.com', 'https://jess4va.com/issues'),  -- Jessica L. Anderson: Abortion
  ('a0dfdf20-b736-4a1c-84c1-194a6625358e', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'https://jessicaandersonforva.com', 'https://jess4va.com/issues')   -- Jessica L. Anderson: Healthcare
;

-- Match on the trailing-slash-normalised element so a stored ".../" is found by a root recorded
-- without one. Ordinality keeps the array in its original order.
UPDATE inform.politician_context pc
   SET sources = (
     SELECT array_agg(CASE WHEN btrim(s, '/') = r.old_root THEN r.new_url ELSE s END ORDER BY ord)
       FROM unnest(pc.sources) WITH ORDINALITY AS u(s, ord))
  FROM _repoint_1513 r
 WHERE pc.politician_id = r.politician_id
   AND pc.topic_id = r.topic_id;

DO $$
DECLARE
  v_target  int;
  v_stale   int;
  v_lost    int;
BEGIN
  SELECT count(*) INTO v_target FROM _repoint_1513;
  IF v_target <> 3 THEN
    RAISE EXCEPTION 'expected 3 targeted rows, found %', v_target;
  END IF;

  -- No targeted row may still cite the retired domain.
  SELECT count(*) INTO v_stale
    FROM inform.politician_context pc
    JOIN _repoint_1513 r ON r.politician_id = pc.politician_id AND r.topic_id = pc.topic_id
   WHERE EXISTS (SELECT 1 FROM unnest(pc.sources) s WHERE s ILIKE '%jessicaandersonforva.com%');
  IF v_stale <> 0 THEN
    RAISE EXCEPTION '% targeted rows still cite the old domain -- old_root did not match', v_stale;
  END IF;

  -- This migration substitutes; it never drops.
  SELECT count(*) INTO v_lost
    FROM inform.politician_context pc
    JOIN _repoint_1513 r ON r.politician_id = pc.politician_id AND r.topic_id = pc.topic_id
   WHERE coalesce(cardinality(pc.sources), 0) = 0;
  IF v_lost <> 0 THEN
    RAISE EXCEPTION '% targeted rows ended with an empty sources array', v_lost;
  END IF;
END $$;

COMMIT;
