-- 1511_retire_a1_oregon_disambiguation_cited_stances.sql
--
-- Retire the last 9 failing A1 stance answers across 5 Oregon legislators. These were held back by
-- migration 1508 as PAGE_UNREADABLE -- their cited page returned under 400 chars, which the audit
-- correctly refused to score as a miss, because an unread page is the same false negative as
-- Ballotpedia's silent HTTP-202 empty body.
--   Evidence:        data/stance-retirement/2026-07-31-a1-disambiguation-recheck.json
--   Rollback record: data/stance-retirement/2026-07-29-suspect-stance-backlog.csv carries
--                    politician_id, topic_id, value, write_in_text, reasoning and sources for every
--                    row deleted here, so this is fully reversible from the repo.
--
-- 🔴 THE PAGES WERE NEVER UNREADABLE. THEY ARE DISAMBIGUATION STUBS. Re-fetched with Playwright,
-- which renders Ballotpedia, all five resolve to a "may refer to" list of unrelated people:
--
--   /Rob_Wagner    -> redirects to /Robert_Wagner, 399 chars, lists Bob Wagner (Illinois),
--                     Bob Wagner (Wisconsin), Robert L. Wagner Jr. (Pennsylvania), Robert Wagner
--                     (Maryland), Robert Wagner (Montana)...
--   /James_Manning -> 249 chars, lists New Hampshire, New York, Oregon, South Carolina
--   /Travis_Nelson -> 138 chars, lists Colorado, Oregon
--   /Nathan_Sosa   -> 131 chars, lists Nevada, Oregon
--   /Paul_Evans    -> 148 chars, lists Illinois, Oregon, Texas
--
-- So the cited URL does not merely fail to contain the claim -- it does not refer to the politician
-- at all. That is a DEAD CITATION, the class migration 1507 retired as DEAD_URL_404, arriving by a
-- different route: HTTP 200 on a page about other people. A short page is not evidence of a failed
-- fetch; test for "may refer to" before concluding extraction broke.
--
-- 🔴 RE-POINTING THE URL WOULD NOT SAVE THEM, AND THIS WAS CHECKED FOR ALL FIVE, not extrapolated
-- from one. The correctly-titled page exists in every case and was fetched in full:
--
--   Rob Wagner (Oregon)    27,628 chars -- campaign finance transparency, disclosure requirement,
--                                          political spending, clean energy transition, fossil fuel,
--                                          Oregon Health Plan, universal healthcare, mental health
--                                          parity, Medicaid: ALL NINE ABSENT
--   James Manning (Oregon) 27,529 chars -- Oregon Health Plan, Medicaid, anti-discrimination, civil
--                                          rights ABSENT; not even the bare word "healthcare"
--   Nathan Sosa (Oregon)   20,633 chars -- anti-discrimination, civil rights, progressive ABSENT.
--                                          Only "Hillsboro" matches, which is an IDENTITY term the
--                                          method discards: the page names his city because it is his
--                                          page, which proves nothing about the claim.
--   Paul Evans (Oregon)    32,843 chars -- anti-discrimination, civil rights ABSENT; not even the
--                                          bare word "discrimination"
--   Travis Nelson (Oregon) 20,175 chars -- see below
--
-- All five pages also state the member did not complete Ballotpedia's candidate survey.
--
-- TRAVIS NELSON IS THE ONE THAT LOOKED SALVAGEABLE AND IS NOT. His correct page DOES contain
-- "Medicaid", so on a term-presence test his Healthcare Access row would score as supported. Read in
-- context, both hits are entries in the SPONSORED LEGISLATION list: "OR HB4127 - Relating to Medicaid
-- payments to reproductive health care providers", chaptered 2026. The row claims he "voted for
-- Medicaid expansion and health programs". Sponsoring is not voting, and Medicaid payments to
-- reproductive health providers is not Medicaid expansion. A term's PRESENCE is not support -- this is
-- the same trap that held Drazan's climate row out of 1508, and it resolves the same way.
--
-- Two independent grounds for every row here, which is one more than 1508 had: the cited page is
-- about other people, AND the right page does not carry the claim.
--
-- Idempotent: the target set is an explicit (politician_id, topic_id) list, so a re-run deletes
-- nothing. Structure follows migrations 1494, 1507, 1508, 1509 and 1510.

BEGIN;

CREATE TEMP TABLE _retire_1511 (politician_id uuid, topic_id uuid) ON COMMIT DROP;
INSERT INTO _retire_1511 (politician_id, topic_id) VALUES
  ('14faa864-de9f-497f-a78a-db41f42ee5e0'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),  -- Rob Wagner · Campaign Finance Reform · cited /Rob_Wagner (disambiguation) · absent on Rob Wagner (Oregon): campaign finance transparency, disclosure requirement, political spending
  ('14faa864-de9f-497f-a78a-db41f42ee5e0'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),  -- Rob Wagner · Fossil Fuel Policy · cited /Rob_Wagner (disambiguation) · absent: clean energy transition, fossil fuel
  ('14faa864-de9f-497f-a78a-db41f42ee5e0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Rob Wagner · Healthcare Access · cited /Rob_Wagner (disambiguation) · absent: Oregon Health Plan, universal healthcare, mental health parity, Medicaid
  ('bef7b04c-a2ba-4daf-9359-ae1ae0e38e9e'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- James I. Manning Jr. · Civil Rights and Social Justice · cited /James_Manning (disambiguation) · absent: anti-discrimination, civil rights
  ('bef7b04c-a2ba-4daf-9359-ae1ae0e38e9e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- James I. Manning Jr. · Healthcare Access · cited /James_Manning (disambiguation) · absent: Oregon Health Plan, Medicaid, healthcare
  ('0f7439ad-5832-42e9-a1c5-75f1720e14d3'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Travis Nelson · Civil Rights and Social Justice · cited /Travis_Nelson (disambiguation) · absent: anti-discrimination, civil rights
  ('0f7439ad-5832-42e9-a1c5-75f1720e14d3'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Travis Nelson · Healthcare Access · cited /Travis_Nelson (disambiguation) · Medicaid present ONLY as sponsored HB4127 (2026, payments to reproductive providers); row claims a VOTE for Medicaid EXPANSION
  ('f2bc3bbf-0d29-4ad9-b675-9c53cf081969'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Nathan Sosa · Civil Rights and Social Justice · cited /Nathan_Sosa (disambiguation) · absent: anti-discrimination, civil rights, progressive (only Hillsboro, an identity term)
  ('e5c0549e-4454-4cea-b7dc-67eb17d28b49'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid);  -- Paul Evans · Civil Rights and Social Justice · cited /Paul_Evans (disambiguation) · absent: anti-discrimination, civil rights, discrimination

-- Politicians who will be left with no answers at all, computed BEFORE the delete.
CREATE TEMP TABLE _emptied_1511 ON COMMIT DROP AS
SELECT a.politician_id FROM inform.politician_answers a
 GROUP BY a.politician_id
HAVING count(*) = count(*) FILTER (WHERE EXISTS (
         SELECT 1 FROM _retire_1511 r
          WHERE r.politician_id = a.politician_id AND r.topic_id = a.topic_id));

DELETE FROM inform.politician_context c USING _retire_1511 r
 WHERE c.politician_id = r.politician_id AND c.topic_id = r.topic_id;

DELETE FROM inform.politician_answers a USING _retire_1511 r
 WHERE a.politician_id = r.politician_id AND a.topic_id = r.topic_id;

-- A timestamp with zero answers asserts research that no longer exists, and would keep these people
-- out of the re-research queue. All five were verified NULL against prod before this ran, so this is
-- expected to affect 0 rows -- it is here so the invariant holds if that ever changes.
UPDATE essentials.politicians p SET last_stances_researched_at = NULL
  FROM _emptied_1511 e
 WHERE p.id = e.politician_id AND p.last_stances_researched_at IS NOT NULL;

DO $$
DECLARE
  v_left int;
  v_ctx  int;
  v_ts   int;
BEGIN
  SELECT count(*) INTO v_left FROM inform.politician_answers a
    JOIN _retire_1511 r ON r.politician_id = a.politician_id AND r.topic_id = a.topic_id;
  IF v_left <> 0 THEN
    RAISE EXCEPTION 'expected 0 targeted answers to remain, found %', v_left;
  END IF;

  SELECT count(*) INTO v_ctx FROM inform.politician_context c
    JOIN _retire_1511 r ON r.politician_id = c.politician_id AND r.topic_id = c.topic_id;
  IF v_ctx <> 0 THEN
    RAISE EXCEPTION 'expected 0 orphaned context rows, found %', v_ctx;
  END IF;

  -- Nobody may be left carrying a research timestamp with no answers behind it.
  SELECT count(*) INTO v_ts
    FROM essentials.politicians p
    JOIN _emptied_1511 e ON e.politician_id = p.id
   WHERE p.last_stances_researched_at IS NOT NULL;
  IF v_ts <> 0 THEN
    RAISE EXCEPTION '% emptied politicians still carry a research timestamp', v_ts;
  END IF;
END $$;

COMMIT;
