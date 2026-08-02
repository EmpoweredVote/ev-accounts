-- 1525_retire_queue_validation_stances.sql
--
-- Retire 6 published stance answers found by working the top of the calibrated reading queue. Same
-- rule as 1517/1520/1521/1522: the topic itself is absent from the cited site, so there is no stance
-- to show. ALL 6 TOPICS ARE OWED RE-RESEARCH.
--   Rollback record: data/stance-retirement/2026-08-01-queue-remedies-rollback.json
--   Review:          data/stance-retirement/2026-08-01-queue-validation.md
--
-- Every row below was checked against RAW HTML with scripts/read-site.mjs, haystack size printed.
--
-- KATHLEEN ANDERSON x3 (kathleen4council.com, 1,631c body / 2,115c raw) -- 🔴 A WHOLE PERSON'S
--   COMPASS CUT FROM ONE SENTENCE. All three of her rows are chair 4.0 and all three derive from:
--   "Taxes keep rising. Roads stay torn up too long. Parks feel less safe. Small businesses are
--   treated like collateral damage. Public spaces are too often affected by drugs, crime, trash,
--   vandalism and disorder."
--     Public Safety, chair 4 "increase police staffing, equipment, and pay": police MISS, staffing
--       MISS. The row itself says her messaging "implies adding police staffing".
--     Transportation, chair 4 "focus on road capacity and traffic flow": transit/bike/pedestrian MISS
--       (the row says so), but "roads stay torn up too long" is a MAINTENANCE-DURATION complaint, not
--       a position on road capacity or on prioritising drivers.
--     Sanitation, chair 4 "rely primarily on enforcement of anti-littering and property maintenance
--       laws": enforce MISS, litter MISS, sanitation MISS, "property maintenance" MISS. The row
--       reaches it from "common sense, accountability, and taxpayer respect".
--   ⚠ THIS EMPTIES HER, AND HER TIMESTAMP IS CLEARED BELOW ON OPERATOR DECISION 2026-08-01.
--   This is the first person emptied while holding a SET last_stances_researched_at, and the two
--   recorded rules point opposite ways: 1494 CLEARED the timestamp for politicians emptied by a
--   retirement, while 1521 notes that a SET timestamp with zero answers is an honest "we looked and
--   found nothing" that must never be erased. Cleared, following 1494 and the operator's ruling: the
--   research pass that set the timestamp is the same pass that produced three unsupported rows, so
--   its "we looked" is not evidence of anything. She returns to the queue as unresearched.
--
-- SILVIA CATTEN / Taxes (silviacatten.com, 13,009c raw over 3 pages) -- the word "tax" does not occur
--   ANYWHERE on the site. The row infers "implies modestly raising taxes on high earners" from
--   "working class policies that ensure our economy works for the people who power it" and "strengthen
--   wages". Identical to 1521's Bowen retirement, where "taxes" occurred zero times.
--   ⚠ Her other two queued rows are FINE and stay -- Housing and Homelessness both quote the site
--   verbatim. This is one bad row on a person whose other rows are sound.
--
-- AARON WILEY / Healthcare (wileyfor21.com) -- the quotations are real: "Healthcare shouldn't depend
--   on your ZIP code" and a pledge to bring "an Emergency Room and Instacares to the Westside" are
--   both verbatim. But insurance MISS and coverage MISS. The topic's scale is about HOW CARE IS PAID
--   FOR (chair 2: "affordable coverage through a mix of public programs and regulated private
--   insurance"); the site is about WHERE FACILITIES SIT. Retired rather than re-charted for the same
--   reason as 1522's Benson: the position is real but is not on this axis, and every available chair
--   would tell a voter something the source does not support.
--
-- HILDA L. SOLIS / Residential Zoning (hildalsolis.org) -- density MISS, zoning MISS, "community
--   benefit" MISS. The row describes "increased housing density near transit corridors alongside
--   community input and environmental review ... prioritizing community benefit agreements". The only
--   related content is "allocated funding to build thousands of affordable housing units".
--   ⚠ Found in the CONTROL sample, not the flagged queue -- no risk marker fired on it. She is a
--   sitting Supervisor with 32 answers, so this position is likely well documented in county records;
--   retiring it here is "no valid source CITED", not "no such position exists". Prime re-source
--   candidate.
--   ⚠ Also note: "transit" appeared to hit this page only because the raw-HTML search matched
--   'HTML 4.0 Transitional//EN' in the doctype. Hits must be read, never counted.

BEGIN;

CREATE TEMP TABLE _retire_1525 (politician_id uuid, topic_id uuid) ON COMMIT DROP;
INSERT INTO _retire_1525 (politician_id, topic_id) VALUES
  ('09d9691d-0352-45c0-9efd-31c38b69c302', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Anderson: Public Safety Approach
  ('09d9691d-0352-45c0-9efd-31c38b69c302', 'ba59337e-30e2-4aba-a39a-426b3366eb27'),  -- Anderson: Transportation Priorities
  ('09d9691d-0352-45c0-9efd-31c38b69c302', '7687de4f-4d0b-462a-b803-bdfb23b16b42'),  -- Anderson: City Sanitation
  ('63d60b50-2395-4cde-8999-97a9166d3563', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- Catten: Taxes
  ('fee24b69-dd56-4b07-a890-a08e898dc031', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),  -- Wiley: Healthcare
  ('f1f3e6ca-5532-4f33-8ec2-64791b08f59b', 'd4f18138-a2e0-4110-b925-7387d9d0d16d')   -- Solis: Residential Zoning
;

DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM inform.politician_answers a
    JOIN _retire_1525 r ON r.politician_id = a.politician_id AND r.topic_id = a.topic_id;
  IF v_n <> 6 THEN RAISE EXCEPTION 'expected 6 targeted answers, found % — target set has moved', v_n; END IF;
END $$;

DELETE FROM inform.politician_context c USING _retire_1525 r
 WHERE c.politician_id = r.politician_id AND c.topic_id = r.topic_id;

DELETE FROM inform.politician_answers a USING _retire_1525 r
 WHERE a.politician_id = r.politician_id AND a.topic_id = r.topic_id;

-- Anderson is emptied deliberately. Clear the timestamp so she reads as UNRESEARCHED and resurfaces,
-- rather than asserting "we looked and found nothing" on the strength of the pass being corrected.
UPDATE essentials.politicians
   SET last_stances_researched_at = NULL
 WHERE id = '09d9691d-0352-45c0-9efd-31c38b69c302';

DO $$
DECLARE
  v_left int;
  v_ctx  int;
  v_bad  text;
BEGIN
  SELECT count(*) INTO v_left FROM inform.politician_answers a
    JOIN _retire_1525 r ON r.politician_id = a.politician_id AND r.topic_id = a.topic_id;
  IF v_left <> 0 THEN RAISE EXCEPTION 'expected 0 targeted answers to remain, found %', v_left; END IF;

  SELECT count(*) INTO v_ctx FROM inform.politician_context c
    JOIN _retire_1525 r ON r.politician_id = c.politician_id AND r.topic_id = c.topic_id;
  IF v_ctx <> 0 THEN RAISE EXCEPTION 'expected 0 orphaned context rows, found %', v_ctx; END IF;

  -- Anderson MUST be empty and MUST be timestamp-free. Both halves are the point.
  SELECT count(*) INTO v_left FROM inform.politician_answers
   WHERE politician_id = '09d9691d-0352-45c0-9efd-31c38b69c302';
  IF v_left <> 0 THEN RAISE EXCEPTION 'Anderson expected 0 answers, found %', v_left; END IF;
  SELECT count(*) INTO v_left FROM essentials.politicians
   WHERE id = '09d9691d-0352-45c0-9efd-31c38b69c302' AND last_stances_researched_at IS NOT NULL;
  IF v_left <> 0 THEN
    RAISE EXCEPTION 'Anderson has 0 answers but still carries a research timestamp — that reads as "we looked and found nothing"';
  END IF;

  -- 🔴 NOBODY ELSE MAY BE EMPTIED. Catten, Wiley and Solis all keep the rest of their compass.
  SELECT string_agg(p.full_name, ', ') INTO v_bad
    FROM essentials.politicians p
   WHERE p.id IN ('63d60b50-2395-4cde-8999-97a9166d3563','fee24b69-dd56-4b07-a890-a08e898dc031',
                  'f1f3e6ca-5532-4f33-8ec2-64791b08f59b')
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers a WHERE a.politician_id = p.id);
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'unexpectedly emptied: %', v_bad; END IF;
END $$;

COMMIT;
