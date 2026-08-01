-- 1519_resource_neighbors4faye_to_archive.sql
--
-- Re-point 4 PUBLISHED stance rows for Faye Johnson (Mayor Pro Tem, Hawthorne CA) away from a
-- campaign domain that is NOW PARKED and onto the Wayback capture of that same site.
-- NOTHING IS RETIRED and no stance value or reasoning changes -- only the URL a voter clicks.
--   Rollback record: data/stance-retirement/2026-08-01-neighbors4faye-rollback.json
--   Review:          data/stance-retirement/2026-08-01-not-found-hand-review.md
--
-- 🔴 A CITATION POINTING AT A PARKED DOMAIN IS WORSE THAN A VAGUE ONE. neighbors4faye.com has
-- left the campaign: http:// now redirects to a ww19.* domain-parking host and one fetch during
-- review returned a "PrivacyKeeper" software-download page. These four rows are published on a
-- SITTING official profile, so a voter checking the evidence was being sent to an ad prompt.
--
-- 🔴 THIS WAS VERY NEARLY A RETIREMENT, AND THAT WOULD HAVE BEEN WRONG. Two tooling faults made
-- the rows look unsourced: a Wayback CDX query using collapse=urlkey reported 2 snapshots where
-- there are 46, and our text extractor scoped to <main>, which on this Webflow site discarded the
-- entire issues section (2,667 chars kept of 4,797). With both fixed, the archived page carries
-- homelessness, public safety, housing and infrastructure planks -- including the exact string one
-- row quotes. All four claims were re-verified against the capture before this migration:
--   Homelessness   "Treatment First, Housing Second"                      verbatim
--   Public Safety  "Public safety is my top priority"                     verbatim
--   Housing        "opportunity to own a home" + "keep rents manageable"  verbatim
--   Growth         "roads, utilities, and public spaces" + "growing city" verbatim
--
-- The Ballotpedia page for this name is a DIFFERENT PERSON (Staley Town Council, North Carolina)
-- and was deliberately NOT used. A 200 response is not identity confirmation.

BEGIN;

-- Growth and Development Pace
UPDATE inform.politician_context SET sources = ARRAY['https://web.archive.org/web/20260520011443/https://www.neighbors4faye.com/']
 WHERE politician_id = 'e44eb637-79e2-43a2-a867-5d3a06bca338' AND topic_id = 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4';

-- Homelessness Response
UPDATE inform.politician_context SET sources = ARRAY['https://web.archive.org/web/20260520011443/https://www.neighbors4faye.com/']
 WHERE politician_id = 'e44eb637-79e2-43a2-a867-5d3a06bca338' AND topic_id = '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f';

-- Housing
UPDATE inform.politician_context SET sources = ARRAY['https://web.archive.org/web/20260520011443/https://www.neighbors4faye.com/']
 WHERE politician_id = 'e44eb637-79e2-43a2-a867-5d3a06bca338' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';

-- Public Safety Approach
UPDATE inform.politician_context SET sources = ARRAY['https://web.archive.org/web/20260520011443/https://www.neighbors4faye.com/']
 WHERE politician_id = 'e44eb637-79e2-43a2-a867-5d3a06bca338' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';

DO $$
DECLARE v_bad int;
BEGIN
  -- No row may still cite the live parked domain.
  SELECT count(*) INTO v_bad FROM inform.politician_context
   WHERE politician_id = 'e44eb637-79e2-43a2-a867-5d3a06bca338'
     AND EXISTS (SELECT 1 FROM unnest(sources) s WHERE s NOT LIKE 'https://web.archive.org/%');
  IF v_bad <> 0 THEN RAISE EXCEPTION 'a Faye Johnson row still cites the parked live domain'; END IF;

  -- All four rows must carry exactly the archive citation, and keep their answers.
  SELECT count(*) INTO v_bad FROM inform.politician_context pc
    JOIN inform.politician_answers pa ON pa.politician_id=pc.politician_id AND pa.topic_id=pc.topic_id
   WHERE pc.politician_id = 'e44eb637-79e2-43a2-a867-5d3a06bca338' AND pc.sources = ARRAY['https://web.archive.org/web/20260520011443/https://www.neighbors4faye.com/'];
  IF v_bad <> 4 THEN RAISE EXCEPTION 'expected 4 re-sourced Faye Johnson rows, found %', v_bad; END IF;
END $$;

COMMIT;
