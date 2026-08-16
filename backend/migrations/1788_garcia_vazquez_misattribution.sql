-- 1788_garcia_vazquez_misattribution.sql
-- Assemblymember Robert Garcia (CA-AD-50) is carrying Antonio Vazquez's identity. Strip it.
--
-- ── 🔴 WHAT IS WRONG ──────────────────────────────────────────────────────────────────────────────
-- essentials.politicians `8bfb459b-9823-4b0d-81f4-49cb97831a80`, full_name "Robert Garcia", is the
-- record for **Robert Garcia, California State Assembly, District 50 (D)** — verified on the
-- official roster at assembly.ca.gov/assemblymembers ("Garcia, Robert | District: 50 | Democrat").
-- It has additionally accumulated the entire public identity of a DIFFERENT PERSON:
--   · an office_term for **Board of Equalization, 3rd District**
--   · photo_origin_url = https://boe.ca.gov/vazquez/about.htm, and the headshot derived from it
--   · **9 stances**, every one of which names "Vazquez" in its reasoning and cites
--     boe.ca.gov/vazquez/* or an SMDP interview about him
--   · **21 cal_access/la_socrata committee links**, 20 of them `confirmed`
--
-- That person is **Antonio "Tony" Vazquez**, BoE member for the 3rd District — boe.ca.gov/vazquez/
-- about.htm: "Antonio Vazquez, Board Member of the California State Board of Equalization (BOE)
-- representing the 3rd District, was elected to the Board in November 2018 and reelected in November
-- 2022." Two different people, two different offices, one politician row.
--
-- ── 🔑 HOW IT WAS FOUND, BECAUSE THE DETECTOR IS REUSABLE ─────────────────────────────────────────
-- Not by name analysis. Migration 1459 backfilled office_terms from `essentials.offices.politician_id`,
-- which is a CURRENT-OCCUPANCY pointer, so **two terms on one row from that same backfill means the
-- row was the current occupant of two seats at once**, which no person is. Corpus-wide that predicate
-- returns 17 rows. It over-fires as every first cut does — 11 are legitimate (Lt Governors holding a
-- `Candidate for%` placeholder, Massachusetts mayors sitting ex officio on school committees,
-- Cambridge and South Portland mayors who are also councillors), 2 are duplicate office rows for one
-- person (Elliott, Morales), 2 were false alarms where a stale URL slug named a predecessor but the
-- page and the stored headshot were correct (Renee Kelly at /fabi-maldonado, Tom Preusker at
-- /thomas-pringle — both confirmed by page title and image alt text). **This is the one real
-- conflation**, and it is invisible to the dedup guard, which compares two ROWS: here both people are
-- inside a single row, so there is nothing for it to compare.
--
-- ── WHAT THIS MIGRATION DOES ──────────────────────────────────────────────────────────────────────
-- Removes Vazquez from Garcia. It does NOT create a Vazquez record — seeding a half-formed person row
-- is worse than an honest absence, and BoE District 3 showing nobody is more accurate than BoE
-- District 3 showing Robert Garcia.
-- The 9 stances are DELETED (answer and context together, so ORPHAN_CONTEXT does not move) and
-- preserved verbatim in `backend/data/stance-retirement/2026-08-16-garcia-vazquez-misattribution.json`
-- with per-row caveats, so they can be re-verified and re-attached if Vazquez is ever seeded.
-- ⚠ Do not bulk re-attach them: they use an obsolete scale vocabulary ("new stance 2"), one concedes
-- "Evidence is limited", and the medicare/aid row infers a FEDERAL Medicare position from a state
-- official's Medi-Cal comment.
--
-- The 21 committee links are demoted to `not_applicable` with a WRONG PERSON note rather than
-- deleted, per the person-merge recipe in migration 1661 — the notes are the only provenance of how
-- the tangle arose. **No contributions have been ingested through any of them** (verified: 0 rows in
-- transparent_motivations.contributions), so no money is being misattributed and nothing needs purging.
--
-- ── 🔴 THE LARGER FINDING THIS EXPOSED, LOGGED HERE AND NOT FIXED HERE ────────────────────────────
-- Those 21 committees are not Tony Vazquez's either. They belong to at least a dozen unrelated
-- people: "VAZQUEZ CAMPAIGN, JOSE", "VAZQUEZ FOR SCHOOL BOARD 2013, I[sabel]", "VAZQUEZ FOR MAYOR,
-- 2016; BENJAMI[N]", "VAZQUEZ CANO FOR OXNARD CITY COUNCIL", plus Ceres, Petaluma, Santa Ana,
-- Visalia and Fullerton. `backend/scripts/confirm-cal-access.ts` links a committee to a politician
-- when `extractLastName(full_name)` — **the last space-delimited token** — appears as a whole word
-- anywhere in the committee name, and a "signal word" is present. SIGNAL_WORDS is
-- ['FOR','COMMITTEE','CAMPAIGN','ELECT','OFFICEHOLDER','EXPLORATORY'], which every candidate
-- committee name contains, so the guard admits rather than filters. The same script both generates
-- and confirms, so no independent check ever ran.
-- Measured 2026-08-16: **7,853 cal_access links on 578 ACTIVE politicians** (13.6 each; 181 hold 10+),
-- **7,836 of them `confirmed`**. The last-token rule produces: Gracey Van Der **Mark** → 381
-- committees containing the given name MARK; Traci **Park** → 204 containing the common noun PARK
-- (Buena Park, Menlo Park, East Bay Regional Park District); Francis **De** → 190 on a two-letter
-- token; Jesse Avila **Jr** → 115 on the suffix JR.
-- This is the same defect family as `relink-socrata-skipped.ts` (migrations 1664/1665) in a source
-- system that sweep never touched, at roughly sixty times the scale. **It needs an operator decision
-- on remediation scope and is deliberately NOT actioned here.**
BEGIN;

CREATE TEMP TABLE gv_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

DO $$
DECLARE n int;
BEGIN
  -- The row must still be the Garcia row, still hold both seats, and still carry exactly 9 stances.
  -- If any of these has moved, the reasoning in this header is stale and must be redone.
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE id='8bfb459b-9823-4b0d-81f4-49cb97831a80' AND full_name='Robert Garcia'
     AND photo_origin_url='https://boe.ca.gov/vazquez/about.htm';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: target row is not the Garcia/Vazquez row (found %)', n; END IF;

  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='8bfb459b-9823-4b0d-81f4-49cb97831a80';
  IF n <> 9 THEN RAISE EXCEPTION 'pre-check: expected 9 answers to retire, found %', n; END IF;

  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='8bfb459b-9823-4b0d-81f4-49cb97831a80';
  IF n <> 9 THEN RAISE EXCEPTION 'pre-check: expected 9 context rows to retire, found %', n; END IF;

  -- Every one of the 9 must actually be about Vazquez. This is the claim the whole migration rests
  -- on, so assert it rather than trusting the header.
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='8bfb459b-9823-4b0d-81f4-49cb97831a80'
     AND reasoning NOT ILIKE '%Vazquez%';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % of the 9 context rows do not name Vazquez — do NOT delete blindly', n; END IF;

  -- Both seats present: the BoE term to remove, the Assembly term to keep.
  SELECT count(*) INTO n FROM essentials.office_terms t JOIN essentials.offices o ON o.id=t.office_id
   WHERE t.politician_id='8bfb459b-9823-4b0d-81f4-49cb97831a80'
     AND o.district_id='294f92a7-47a8-429e-adae-cf5bb7954f4b';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: BoE District 3 term not found on the Garcia row (found %)', n; END IF;

  SELECT count(*) INTO n FROM essentials.office_terms t JOIN essentials.offices o ON o.id=t.office_id
   WHERE t.politician_id='8bfb459b-9823-4b0d-81f4-49cb97831a80'
     AND o.district_id='b9b45edd-87cf-4c83-80be-913a4303d832';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: Assembly District 50 term missing — this row may not be Garcia at all'; END IF;

  -- No money may be riding on the 21 committee links. If any has been ingested since the audit,
  -- stop: demoting the link would leave orphaned contributions displayed on Garcia.
  SELECT count(*) INTO n
    FROM transparent_motivations.politician_sources ps
    JOIN transparent_motivations.contributions c ON c.politician_source_id = ps.id
   WHERE ps.essentials_politician_id='8bfb459b-9823-4b0d-81f4-49cb97831a80';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % contribution(s) now ingested on this row — purge them before demoting the links', n; END IF;
END $$;

-- 1. The 9 misattributed stances. Answer AND context together: deleting only the answer would
--    manufacture an orphan context row, which is the failure the ORPHAN_CONTEXT gate exists to catch.
DELETE FROM inform.politician_answers WHERE politician_id='8bfb459b-9823-4b0d-81f4-49cb97831a80';
DELETE FROM inform.politician_context WHERE politician_id='8bfb459b-9823-4b0d-81f4-49cb97831a80';

-- 2. Vazquez's seat.
DELETE FROM essentials.office_terms t
 USING essentials.offices o
 WHERE o.id = t.office_id
   AND t.politician_id='8bfb459b-9823-4b0d-81f4-49cb97831a80'
   AND o.district_id='294f92a7-47a8-429e-adae-cf5bb7954f4b';

-- 3. Vazquez's face. Garcia having no headshot is correct-but-empty; serving another man's portrait
--    is not. Leaving photo_origin_url set would let a re-scrape restore it.
DELETE FROM essentials.politician_images WHERE politician_id='8bfb459b-9823-4b0d-81f4-49cb97831a80';
UPDATE essentials.politicians
   SET photo_origin_url = NULL,
       photo_custom_url = NULL,
       photo_custom_url_manual_override = false
 WHERE id='8bfb459b-9823-4b0d-81f4-49cb97831a80';

-- 4. The 21 committee links: demoted, not deleted — the notes are the provenance.
UPDATE transparent_motivations.politician_sources
   SET research_status = 'not_applicable',
       notes = coalesce(notes,'') || ' | WRONG PERSON (migration 1788, 2026-08-16): linked to Robert'
               || ' Garcia (CA Assembly D50) by confirm-cal-access.ts on the last-token rule. These'
               || ' are VAZQUEZ committees belonging to several unrelated people. Not Garcia''s; not'
               || ' all Tony Vazquez''s either. 0 contributions were ingested.',
       updated_at = now()
 WHERE essentials_politician_id='8bfb459b-9823-4b0d-81f4-49cb97831a80';

DO $$
DECLARE n int; s record;
BEGIN
  SELECT * INTO s FROM gv_snap;

  SELECT count(*) INTO n FROM inform.politician_answers;
  IF n <> s.ans_before - 9 THEN RAISE EXCEPTION 'guard 1: answers went % -> %, expected -9', s.ans_before, n; END IF;
  SELECT count(*) INTO n FROM inform.politician_context;
  IF n <> s.ctx_before - 9 THEN RAISE EXCEPTION 'guard 1: context went % -> %, expected -9', s.ctx_before, n; END IF;

  -- Garcia is clean: no stances, no photo, no image row.
  SELECT count(*) INTO n FROM inform.politician_answers WHERE politician_id='8bfb459b-9823-4b0d-81f4-49cb97831a80';
  IF n <> 0 THEN RAISE EXCEPTION 'guard 2: % stance(s) still on Garcia', n; END IF;
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE id='8bfb459b-9823-4b0d-81f4-49cb97831a80'
     AND photo_origin_url IS NULL AND photo_custom_url IS NULL;
  IF n <> 1 THEN RAISE EXCEPTION 'guard 2: Vazquez photo still attached to Garcia'; END IF;
  SELECT count(*) INTO n FROM essentials.politician_images WHERE politician_id='8bfb459b-9823-4b0d-81f4-49cb97831a80';
  IF n <> 0 THEN RAISE EXCEPTION 'guard 2: % image row(s) still on Garcia', n; END IF;

  -- Exactly one seat remains, and it is Assembly District 50. Assert the SURVIVOR, not just the
  -- count: a bug deleting the wrong term would still leave one row.
  SELECT count(*) INTO n FROM essentials.office_terms WHERE politician_id='8bfb459b-9823-4b0d-81f4-49cb97831a80';
  IF n <> 1 THEN RAISE EXCEPTION 'guard 2: Garcia holds % seats, expected 1', n; END IF;
  SELECT count(*) INTO n FROM essentials.office_terms t JOIN essentials.offices o ON o.id=t.office_id
   WHERE t.politician_id='8bfb459b-9823-4b0d-81f4-49cb97831a80'
     AND o.district_id='b9b45edd-87cf-4c83-80be-913a4303d832';
  IF n <> 1 THEN RAISE EXCEPTION 'guard 2: the surviving seat is not Assembly District 50'; END IF;

  -- No confirmed committee link may remain on this row.
  SELECT count(*) INTO n FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id='8bfb459b-9823-4b0d-81f4-49cb97831a80'
     AND research_status <> 'not_applicable';
  IF n <> 0 THEN RAISE EXCEPTION 'guard 2: % committee link(s) still active on Garcia', n; END IF;
  SELECT count(*) INTO n FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id='8bfb459b-9823-4b0d-81f4-49cb97831a80'
     AND notes LIKE '%WRONG PERSON (migration 1788%';
  IF n <> 21 THEN RAISE EXCEPTION 'guard 2: % of 21 links carry the provenance note, expected 21', n; END IF;
END $$;

DO $$
DECLARE orphans int; ans_wo_ctx int;
BEGIN
  -- Predicate copied verbatim from the CI gate. Answer and context were deleted together, so this
  -- must not move.
  SELECT count(*) INTO orphans
    FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
   WHERE pa.politician_id IS NULL
     AND coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF orphans <> 50 THEN RAISE EXCEPTION 'guard 3: ORPHAN_CONTEXT is %, expected 50', orphans; END IF;

  SELECT count(*) INTO ans_wo_ctx FROM inform.politician_answers a
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF ans_wo_ctx > 0 THEN RAISE EXCEPTION 'guard 3: % answer(s) have no context', ans_wo_ctx; END IF;

  RAISE NOTICE 'Garcia/Vazquez: 9 stances retired, BoE seat and headshot removed, 21 links demoted; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
