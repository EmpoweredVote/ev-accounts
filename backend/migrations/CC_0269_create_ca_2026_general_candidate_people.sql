-- CC_0269_create_ca_2026_general_candidate_people.sql
--
-- Finishes the CA 2026 Statewide General ballot. Two parts:
--   PART A -- links ONE more candidacy to a person we already hold (Tom Umberg).
--   PART B -- CREATES 110 politician rows for candidates who genuinely have no person
--             record, and links each to its candidacy row.
--
-- After CC_0268 there were 112 unlinked rows. This leaves ONE: Sonja Shaw, held by ruling.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- ═══ PART A ═══ TOM UMBERG, AND WHY HE ARRIVED LATE
--
--   126de854-e5e7-41a8-bf79-c93ef6c8eed0  Tom Umberg, State Board of Equalization, 4th District
--     -> 712be98b-a05d-4605-9603-cd5d86abfad1  "Thomas Umberg", Senator, CA State Senate 34
--
-- 🔴 HE WAS IN THE CREATE LIST UNTIL THE LAST CHECK. CC_0268's dedupe pass matched first names
-- by equality or prefix, and "thomas" is neither equal to nor a prefix of "tom" -- so a sitting
-- California State Senator was one migration away from being created a second time. An earlier,
-- noisier version of the pass HAD caught him, on first-initial alone; tightening the query to
-- cut false positives silently cut a true one.
-- ⚠ THE NICKNAME IS THE THIRD BLINDNESS the duplicate guard has, beside archived rows and a
-- differently-split full_name. A prefix test does not model it: Bill/William, Jim/James,
-- Tony/Anthony and Tom/Thomas all fail it. An explicit diminutive list is required.
--
-- EVIDENCE. CA Senate District 34 is 93.3% inside Board of Equalization District 4, the seat
-- sought. Control: SD-34 against BoE District 1 returns 0.0%.
-- ▶ THIS LINK CARRIES 23 COMPASS ANSWERS -- 21 in closed Season 1, 2 in open Season 2, all
-- PUBLISHED, none draft, no blanks. They become reachable from the BoE 4th District race page.
-- That is the largest stance move this programme has made and it is stated here, before the
-- write, because CC_0262 made that the rule.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- ═══ THE THREE WRONG PEOPLE THE NICKNAME PASS FOUND, ALL REFUSED ═══
--
-- Each has exactly one plausible namesake, which is the signal that justified ten links in
-- CC_0268. Each is a different person. All three are CREATED as new people in Part B instead.
--
--   Mike Murphy      (CA Assembly 27)  vs "Michael Murphy"  -- a KANSAS state senator.
--   Tony Rodriguez   (CA Senate 20)    vs "Anthony Rodriguez" -- a MIAMI-DADE, FLORIDA commissioner.
--   William Brown Jr.(CA Senate 12)    vs "Bill Brown" -- Sheriff-Coroner of Santa Barbara County, CA.
--
-- 🔴🔴 BROWN IS THE DANGEROUS ONE, AND HE IS WHY `ST_Intersects` ALONE IS NOT THE TEST.
-- Santa Barbara County against Senate District 12 returns **intersects = TRUE** -- and an area
-- share of **0.0%**. They share a boundary line and nothing else. A test that reads only the
-- boolean would have attached a Santa Barbara sheriff to a Central Valley senate seat. Read the
-- AREA SHARE, not the predicate. (Control: SD-19 returns false, 0.0%.)
-- ⚠ Murphy and Rodriguez were caught by the cheaper test -- the state of the seat the matched
-- person actually holds. That is now 5 confirmed cross-state wrong people in this programme.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- ═══ PART B ═══ CREATING 110 PEOPLE
--
-- 🔴 THIS IS THE PART THAT WAS DELIBERATELY NOT DONE BEFORE. Asked whether to do it, the
-- earlier answer was "not yet", for three reasons. Two have since been answered and one is
-- now an explicit operator decision:
--   1. SCALE -- it is ~1,083 nationally, not 117. Still true. This does CALIFORNIA only, and
--      that asymmetry is accepted knowingly: CA is the state whose ballot pages are live now.
--   2. DUPLICATE RISK -- answered. CC_0268 linked 10, Part A links an 11th, and the archived
--      and nickname blindnesses were both swept explicitly. The remaining 110 were checked
--      against ACTIVE names, ARCHIVED names, name-variant splits, accents and diminutives.
--   3. "NO DOCUMENT BEHIND CREATE" -- decided by the operator, 2026-10-20. The record created
--      is not a claim that the person holds anything; it is the person the certified candidate
--      list names. Accordingly every row is written with NO office, NO term and NO party.
--
-- WHAT EACH NEW ROW ASSERTS, AND WHAT IT CAREFULLY DOES NOT:
--   is_active     = true   -- they are standing in a live election
--   is_incumbent  = FALSE  -- 🔴 NAMED EXPLICITLY. It defaulted to true until CA_0188 and that
--                             created 1,817 active "incumbents" with no seat. check:occupancy
--                             fails an INSERT that omits it.
--   external_id   = NULL   -- an external_id collision seats the WRONG person silently, and we
--                             have no external identifier for these people.
--   party         = NULL   -- party is antipartisan here: it lives on races.primary_party, and
--                             the general-election rows carry none.
--   NO office_terms row    -- they hold nothing. An office with no term is invisible, which is
--                             the correct state for a candidate.
-- Names are split first/last by the existing convention (all-but-last-token / last token), with
-- quoted nicknames removed from the SPLIT only -- full_name keeps the ballot spelling, accents
-- and all, because that is what the voter sees.
-- ⚠ A generational suffix is excluded from last_name (Raul Ortiz Jr. -> "Raul" / "Ortiz"), so
-- the (first_name, last_name) duplicate guard keys on the part that identifies the family name.
--
-- Idempotent: re-running inserts nothing (guarded on the candidacy row already being linked).

BEGIN;

-- ═══ PART A ═══════════════════════════════════════════════════════════════════════════════
DO $$
DECLARE v_rc text; v_pid uuid; v_pol text; v_act bool; v_seeks text;
BEGIN
  SELECT rc.full_name, rc.politician_id, ra.position_name INTO v_rc, v_pid, v_seeks
    FROM essentials.race_candidates rc JOIN essentials.races ra ON ra.id = rc.race_id
   WHERE rc.id = '126de854-e5e7-41a8-bf79-c93ef6c8eed0'::uuid;
  IF v_rc IS DISTINCT FROM 'Tom Umberg' THEN
    RAISE EXCEPTION 'CC_0269: the Umberg candidacy row is "%", expected "Tom Umberg"', v_rc;
  END IF;
  IF v_seeks IS DISTINCT FROM 'State Board of Equalization, 4th District' THEN
    RAISE EXCEPTION 'CC_0269: Umberg row seeks "%", not the seat the geometry was tested against',
                    v_seeks;
  END IF;
  SELECT p.full_name, p.is_active INTO v_pol, v_act FROM essentials.politicians p
   WHERE p.id = '712be98b-a05d-4605-9603-cd5d86abfad1'::uuid;
  IF v_pol IS DISTINCT FROM 'Thomas Umberg' OR NOT v_act THEN
    RAISE EXCEPTION 'CC_0269: target politician is "%" active=% - expected an active Thomas Umberg',
                    v_pol, v_act;
  END IF;
  IF v_pid IS NOT NULL AND v_pid <> '712be98b-a05d-4605-9603-cd5d86abfad1'::uuid THEN
    RAISE EXCEPTION 'CC_0269: the Umberg row is already linked to %', v_pid;
  END IF;
END $$;

UPDATE essentials.race_candidates
SET politician_id = '712be98b-a05d-4605-9603-cd5d86abfad1'::uuid
WHERE id = '126de854-e5e7-41a8-bf79-c93ef6c8eed0'::uuid
  AND politician_id IS DISTINCT FROM '712be98b-a05d-4605-9603-cd5d86abfad1'::uuid;

-- ═══ PART B ═══════════════════════════════════════════════════════════════════════════════
-- The cohort, computed once so the INSERT and the link cannot drift apart.
CREATE TEMP TABLE _new AS
WITH src AS (
  SELECT rc.id AS rc_id, rc.full_name,
         btrim(regexp_replace(rc.full_name, '\s*"[^"]*"\s*', ' ', 'g')) AS clean
  FROM essentials.race_candidates rc
  JOIN essentials.races r ON r.id = rc.race_id
  JOIN essentials.elections e ON e.id = r.election_id
  WHERE e.name = 'CA 2026 Statewide General'
    AND rc.politician_id IS NULL
    AND rc.full_name <> 'Sonja Shaw'          -- held by operator ruling (CC_0264)
)
SELECT rc_id, full_name,
       btrim(regexp_replace(
         btrim(regexp_replace(clean, '\s+(Jr\.?|Sr\.?|I{2,3}|IV)$', '', 'i')),
         '\s+\S+$', '')) AS first_name,
       regexp_replace(
         btrim(regexp_replace(clean, '\s+(Jr\.?|Sr\.?|I{2,3}|IV)$', '', 'i')),
         '^.*\s', '') AS last_name,
       NULL::uuid AS new_id
FROM src;

-- Guards on the cohort BEFORE any insert.
DO $$
DECLARE n int; bad int;
BEGIN
  SELECT count(*) INTO n FROM _new;
  IF n <> 110 THEN
    RAISE EXCEPTION 'CC_0269: expected 110 candidates to create, found % - the set moved, '
                    're-run the dedupe pass before writing', n;
  END IF;

  -- no empty name parts: a blank first_name is how "John Armenian" ended up unusable
  SELECT count(*) INTO bad FROM _new
   WHERE coalesce(btrim(first_name),'') = '' OR coalesce(btrim(last_name),'') = '';
  IF bad > 0 THEN
    RAISE EXCEPTION 'CC_0269: % row(s) split to an empty first or last name', bad;
  END IF;

  -- 🔴 none of them may match an EXISTING politician on the guard's own key, active OR archived.
  -- ⚠ ONE ADJUDICATED EXCEPTION, AND IT IS NAMED. Ed Delgado (CA Assembly 60) collides with the
  -- existing Ed Delgado, who is the WISCONSIN Assembly 57 candidate that LOST. They are two
  -- different people who share a name, so a second row is CORRECT -- the house rule is one row
  -- per PERSON, not one row per name. The pair is recorded as `different_people` in
  -- data/duplicate-people-baseline.json in the same change, with the state evidence as its note,
  -- so check:duplicate-people stays quiet about it for ever instead of re-reporting it.
  -- 🔴 This carve-out is keyed on ONE rc_id. It cannot widen: any OTHER collision still fails.
  SELECT count(*) INTO bad FROM _new nw
   WHERE nw.rc_id <> 'f9225814-f223-4426-96d3-d73852fda05a'::uuid
     AND EXISTS (SELECT 1 FROM essentials.politicians p
                  WHERE lower(p.first_name) = lower(nw.first_name)
                    AND lower(p.last_name)  = lower(nw.last_name));
  IF bad > 0 THEN
    RAISE EXCEPTION 'CC_0269: % of the 110 already match an existing (first_name, last_name) '
                    '- the dedupe pass missed them, REFUSING to create duplicates', bad;
  END IF;

  -- and none on full_name either, same single exception
  SELECT count(*) INTO bad FROM _new nw
   WHERE nw.rc_id <> 'f9225814-f223-4426-96d3-d73852fda05a'::uuid
     AND EXISTS (SELECT 1 FROM essentials.politicians p
                  WHERE lower(p.full_name) = lower(nw.full_name));
  IF bad > 0 THEN
    RAISE EXCEPTION 'CC_0269: % of the 110 already match an existing full_name', bad;
  END IF;

  -- the carve-out must still BE the Delgado row, or it is silently excusing someone else
  PERFORM 1 FROM _new WHERE rc_id='f9225814-f223-4426-96d3-d73852fda05a'::uuid
                        AND full_name='Ed Delgado';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CC_0269: the adjudicated-collision carve-out no longer points at Ed Delgado';
  END IF;
END $$;

-- Create the people. is_incumbent is named EXPLICITLY (CA_0188).
--
-- 🔴 THE DATABASE HAS ITS OWN DUPLICATE-NAME TRIGGER, essentials.politician_name_duplicate_guard,
-- and it fires on INSERT. It is LEFT ARMED for 109 of the 110. For Ed Delgado alone it is
-- lowered with the house escape hatch the trigger itself names
-- (essentials.allow_duplicate_name), for one statement, and raised again immediately -- so the
-- exception cannot leak onto any other row in this transaction.
-- ⚠ Inserted ONE AT A TIME on purpose. A set-based INSERT ... RETURNING would have to be mapped
-- back to its candidacy row by full_name, and two candidates in different districts can share a
-- name -- which is the very thing this migration exists to handle. The loop keys on rc_id.
DO $$
DECLARE r record; v_id uuid;
  c_delgado CONSTANT uuid := 'f9225814-f223-4426-96d3-d73852fda05a';
BEGIN
  FOR r IN SELECT * FROM _new ORDER BY full_name LOOP
    IF r.rc_id = c_delgado THEN
      PERFORM set_config('essentials.allow_duplicate_name', 'on', true);   -- true = LOCAL
    END IF;

    INSERT INTO essentials.politicians (full_name, first_name, last_name,
                                        is_active, is_incumbent, source)
    VALUES (r.full_name, r.first_name, r.last_name, true, false,
            'ca-sos-2026-general CC_0269 (certified candidate list; no office asserted)')
    RETURNING id INTO v_id;

    IF r.rc_id = c_delgado THEN
      PERFORM set_config('essentials.allow_duplicate_name', 'off', true);  -- re-arm at once
    END IF;

    UPDATE _new SET new_id = v_id WHERE rc_id = r.rc_id;
  END LOOP;

  -- the hatch must be shut before this transaction does anything else
  IF coalesce(current_setting('essentials.allow_duplicate_name', true), 'off') <> 'off' THEN
    RAISE EXCEPTION 'CC_0269: the duplicate-name escape hatch was left open';
  END IF;
END $$;

-- Link each candidacy to the person just created for it.
UPDATE essentials.race_candidates rc
SET politician_id = nw.new_id
FROM _new nw
WHERE rc.id = nw.rc_id AND nw.new_id IS NOT NULL AND rc.politician_id IS NULL;

-- ═══ post-verify ══════════════════════════════════════════════════════════════════════════
DO $$
DECLARE n_created int; n_linked int; n_left int; n_shaw int; n_inc int; n_terms int;
        n_offsite int; n_umberg int;
BEGIN
  SELECT count(*) INTO n_created FROM _new WHERE new_id IS NOT NULL;
  IF n_created <> 110 THEN
    RAISE EXCEPTION 'CC_0269: created % people, expected 110', n_created;
  END IF;

  SELECT count(*) INTO n_linked
    FROM essentials.race_candidates rc JOIN _new nw ON nw.rc_id = rc.id
   WHERE rc.politician_id = nw.new_id;
  IF n_linked <> 110 THEN
    RAISE EXCEPTION 'CC_0269: linked % of 110 candidacy rows', n_linked;
  END IF;

  SELECT count(*) INTO n_umberg FROM essentials.race_candidates
   WHERE id='126de854-e5e7-41a8-bf79-c93ef6c8eed0'::uuid
     AND politician_id='712be98b-a05d-4605-9603-cd5d86abfad1'::uuid;
  IF n_umberg <> 1 THEN
    RAISE EXCEPTION 'CC_0269: the Umberg link did not take';
  END IF;

  -- 🔴 every new person must be a NON-incumbent holding NO seat
  SELECT count(*) INTO n_inc FROM _new nw
    JOIN essentials.politicians p ON p.id = nw.new_id
   WHERE p.is_incumbent IS DISTINCT FROM false OR p.is_active IS DISTINCT FROM true;
  IF n_inc <> 0 THEN
    RAISE EXCEPTION 'CC_0269: % new row(s) are not active non-incumbents', n_inc;
  END IF;

  SELECT count(*) INTO n_terms FROM essentials.office_terms ot
    JOIN _new nw ON nw.new_id = ot.politician_id;
  IF n_terms <> 0 THEN
    RAISE EXCEPTION 'CC_0269: % new person(s) somehow hold an office term', n_terms;
  END IF;

  -- exactly one unlinked row must remain, and it must be Shaw
  SELECT count(*) INTO n_left FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id=rc.race_id
    JOIN essentials.elections e ON e.id=r.election_id
   WHERE e.name='CA 2026 Statewide General' AND rc.politician_id IS NULL;
  IF n_left <> 1 THEN
    RAISE EXCEPTION 'CC_0269: % unlinked rows remain, expected exactly 1 (Sonja Shaw)', n_left;
  END IF;
  SELECT count(*) INTO n_shaw FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id=rc.race_id
    JOIN essentials.elections e ON e.id=r.election_id
   WHERE e.name='CA 2026 Statewide General' AND rc.politician_id IS NULL
     AND rc.full_name='Sonja Shaw';
  IF n_shaw <> 1 THEN
    RAISE EXCEPTION 'CC_0269: the one remaining unlinked row is not Sonja Shaw';
  END IF;

  SELECT count(*) INTO n_offsite FROM essentials.race_candidates rc
   WHERE NULLIF(rc.photo_url,'') IS NOT NULL
     AND rc.result IS DISTINCT FROM 'not_nominated'
     AND rc.photo_url NOT LIKE '%supabase.co/storage/v1/object/public/%';
  IF n_offsite <> 0 THEN
    RAISE EXCEPTION 'CC_0269: % live ballot row(s) render off-site', n_offsite;
  END IF;

  RAISE NOTICE 'CC_0269 OK - Umberg linked, 110 people created and linked, only Shaw remains';
END $$;

DROP TABLE _new;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE: TIGHTENING A MATCH TO CUT FALSE POSITIVES CUTS TRUE ONES SILENTLY.
-- The dedupe pass first matched first names on shared initial, which was noisy, and was then
-- tightened to equality-or-prefix. That removed the noise AND removed Tom Umberg, a sitting
-- State Senator with 23 published compass answers, who was then one migration from being
-- created a second time. When you narrow a matcher, re-check what it USED to find.
-- ⚠ A NICKNAME IS NOT A PREFIX. Tom/Thomas, Bill/William, Jim/James, Tony/Anthony all fail a
-- prefix test. Diminutives need an explicit list; there is one in this migration's history.
-- 🔴🔴 `ST_Intersects` IS NOT "IS INSIDE". Santa Barbara County and Senate District 12 intersect
-- at 0.0% shared area -- they touch along a line. Always read the area share.
-- ───────────────────────────────────────────────────────────────────────────────────────────
