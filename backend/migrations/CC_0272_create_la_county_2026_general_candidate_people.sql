-- CC_0272_create_la_county_2026_general_candidate_people.sql
--
-- Creates politician rows for the 2026 LA County General candidates who genuinely have no person
-- record, and links each to its candidacy. Follows CC_0269's pattern exactly.
--
-- 427 rows were unlinked. CC_0271 linked 16 found by the dedupe pass. This creates **408** and
-- leaves **3** unlinked by judgement.
--
-- ═══ THE THREE LEFT UNLINKED, AND WHY NO ROW IS CREATED FOR THEM ═══
-- Each has an EXACT full_name match in the corpus. Creating a second row would assert "these are
-- different people", and we cannot show that. Linking would assert "these are the same person",
-- and we cannot show that either. Unlinked is the only honest third state -- the one CC_0264
-- established for Sonja Shaw.
--   d1f1dea6  Christine R. Sarmiento  El Monte Mayor      -- existing row holds a CA GOVERNOR
--             candidacy and an IMAGE. Statewide-to-city on an exact name is the Shaw shape, and
--             a wrong link would publish a wrong FACE.
--   2dbb3828  Mark Copland  Norwalk-La Mirada USD TA-5    -- existing row holds TA-6 of the SAME
--             district. TA-5 and TA-6 return ST_Intersects TRUE at 0.0% shared area: disjoint,
--             touching along a line. Needs the boundary redraw, not an inference.
--   a63fd90b  Michael Braun  Walnut Valley Water District -- matches THREE rows (an ARIZONA
--             senate candidate, an archived row, a bare row) and the name also matches the
--             Governor of Indiana. Nothing says which, if any, is him.
--
-- ═══ 🔴 ONE ADJUDICATED COLLISION: CHERYL WILLIAMS ═══
--   9e13be3e  Cheryl Williams  Inglewood Unified School Board - Trustee Area 1
-- An exact full_name match with a politician who is a **Commissioner in Collin County, TEXAS** --
-- confirmed a different person in CC_0265 and still matching every sweep since. She IS created,
-- because here we can show they are different people: the election is California and the matched
-- person's seat is Texas.
-- ⚠ NO BASELINE ENTRY WAS NEEDED, AND THAT SURPRISED ME. I intended to record the pair as
-- `different_people`; running the guard afterwards showed it never flags them. check:duplicate-people
-- keys on (first_name, last_name) WITHIN A STATE, and these two resolve to different states --
-- so the gate is already silent about exactly the collision the database's own trigger blocks.
-- 🔴 THE TWO GUARDS DISAGREE ON PURPOSE AND NEITHER IS WRONG: the INSERT trigger asks "does this
-- name already exist at all", the sweep asks "do two rows look like one person in one place".
-- A cross-state namesake trips the first and not the second. Know which one you are satisfying.
--
-- ▶ ONE PAIR WAS ADDED to the baseline by this change, and it is not hers:
--   "Jose Gonzalez ~ Jose R. Gonzalez" (ca), left `unreviewed`. He is created rather than linked
--   because the existing row is a bare netfile filer and the name is too common for a bare-row
--   link to mean anything. `unreviewed` is the honest verdict -- I cannot show same or different.
--
-- ═══ WHAT EACH NEW ROW ASSERTS ═══
--   is_active=true · is_incumbent=FALSE (named EXPLICITLY -- CA_0188) · external_id NULL ·
--   party NULL (antipartisan; it lives on races.primary_party) · NO office_terms row ·
--   source names the import. Nothing claims they hold anything.
-- Inserted ONE AT A TIME, linking on rc_id, because two candidates in different districts can
-- share a name. The database's own duplicate-name trigger stays ARMED for 407 of the 408; for
-- Cheryl Williams alone the house escape hatch opens for ONE statement and re-arms immediately.
--
-- Idempotent: re-running inserts nothing.

BEGIN;

CREATE TEMP TABLE _new AS
WITH src AS (
  SELECT rc.id AS rc_id, rc.full_name,
         btrim(regexp_replace(rc.full_name, '\s*"[^"]*"\s*', ' ', 'g')) AS clean
  FROM essentials.race_candidates rc
  JOIN essentials.races r ON r.id = rc.race_id
  JOIN essentials.elections e ON e.id = r.election_id
  WHERE e.name = '2026 LA County General'
    AND rc.politician_id IS NULL
    AND rc.id NOT IN ('d1f1dea6-8d03-433d-87dc-5972032f6f37'::uuid,   -- Sarmiento
                      '2dbb3828-de12-48ee-89b7-dce0353001f9'::uuid,   -- Copland
                      'a63fd90b-02c8-4d08-931b-ffd616f8bac7'::uuid)   -- Braun
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

DO $$
DECLARE n int; bad int;
  c_cheryl CONSTANT uuid := '9e13be3e-7b0e-42c8-83ed-e73b3c2db316';
BEGIN
  SELECT count(*) INTO n FROM _new;
  IF n <> 408 THEN
    RAISE EXCEPTION 'CC_0272: expected 408 to create, found % - the set moved, re-run the '
                    'dedupe pass before writing', n;
  END IF;

  SELECT count(*) INTO bad FROM _new
   WHERE coalesce(btrim(first_name),'')='' OR coalesce(btrim(last_name),'')='';
  IF bad > 0 THEN
    RAISE EXCEPTION 'CC_0272: % row(s) split to an empty first or last name', bad;
  END IF;

  -- 🔴 no collisions on the duplicate guard's own key, active OR archived, bar the one adjudicated
  SELECT count(*) INTO bad FROM _new nw
   WHERE nw.rc_id <> c_cheryl
     AND EXISTS (SELECT 1 FROM essentials.politicians p
                  WHERE lower(p.first_name)=lower(nw.first_name)
                    AND lower(p.last_name)=lower(nw.last_name));
  IF bad > 0 THEN
    RAISE EXCEPTION 'CC_0272: % of the 408 match an existing (first_name, last_name) - the '
                    'dedupe pass missed them, REFUSING to create duplicates', bad;
  END IF;

  SELECT count(*) INTO bad FROM _new nw
   WHERE nw.rc_id <> c_cheryl
     AND EXISTS (SELECT 1 FROM essentials.politicians p
                  WHERE lower(p.full_name)=lower(nw.full_name));
  IF bad > 0 THEN
    RAISE EXCEPTION 'CC_0272: % of the 408 match an existing full_name', bad;
  END IF;

  -- the carve-out must still BE Cheryl Williams
  PERFORM 1 FROM _new WHERE rc_id = c_cheryl AND full_name = 'Cheryl Williams';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CC_0272: the adjudicated-collision carve-out no longer points at Cheryl Williams';
  END IF;

  -- and two candidates in THIS cohort may share a name; the loop handles it, but say so loudly
  SELECT count(*) INTO bad FROM (
    SELECT full_name FROM _new GROUP BY full_name HAVING count(*) > 1) x;
  IF bad > 0 THEN
    RAISE NOTICE 'CC_0272: % name(s) appear twice within this cohort - each gets its own row, '
                 'keyed on rc_id', bad;
  END IF;
END $$;

DO $$
DECLARE r record; v_id uuid;
  c_cheryl CONSTANT uuid := '9e13be3e-7b0e-42c8-83ed-e73b3c2db316';
BEGIN
  FOR r IN SELECT * FROM _new ORDER BY full_name, rc_id LOOP
    IF r.rc_id = c_cheryl THEN
      PERFORM set_config('essentials.allow_duplicate_name', 'on', true);   -- true = LOCAL
    END IF;

    INSERT INTO essentials.politicians (full_name, first_name, last_name,
                                        is_active, is_incumbent, source)
    VALUES (r.full_name, r.first_name, r.last_name, true, false,
            'la-county-2026-general CC_0272 (certified candidate list; no office asserted)')
    RETURNING id INTO v_id;

    IF r.rc_id = c_cheryl THEN
      PERFORM set_config('essentials.allow_duplicate_name', 'off', true); -- re-arm at once
    END IF;

    UPDATE _new SET new_id = v_id WHERE rc_id = r.rc_id;
  END LOOP;

  IF coalesce(current_setting('essentials.allow_duplicate_name', true),'off') <> 'off' THEN
    RAISE EXCEPTION 'CC_0272: the duplicate-name escape hatch was left open';
  END IF;
END $$;

UPDATE essentials.race_candidates rc
SET politician_id = nw.new_id
FROM _new nw
WHERE rc.id = nw.rc_id AND nw.new_id IS NOT NULL AND rc.politician_id IS NULL;

DO $$
DECLARE n_created int; n_linked int; n_left int; n_bad int; n_terms int; n_offsite int;
BEGIN
  SELECT count(*) INTO n_created FROM _new WHERE new_id IS NOT NULL;
  IF n_created <> 408 THEN
    RAISE EXCEPTION 'CC_0272: created % people, expected 408', n_created;
  END IF;

  SELECT count(*) INTO n_linked FROM essentials.race_candidates rc
    JOIN _new nw ON nw.rc_id = rc.id WHERE rc.politician_id = nw.new_id;
  IF n_linked <> 408 THEN
    RAISE EXCEPTION 'CC_0272: linked % of 408', n_linked;
  END IF;

  SELECT count(*) INTO n_bad FROM _new nw JOIN essentials.politicians p ON p.id = nw.new_id
   WHERE p.is_incumbent IS DISTINCT FROM false OR p.is_active IS DISTINCT FROM true
      OR p.external_id IS NOT NULL;
  IF n_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0272: % new row(s) are not active, non-incumbent, external_id-free', n_bad;
  END IF;

  SELECT count(*) INTO n_terms FROM essentials.office_terms ot
    JOIN _new nw ON nw.new_id = ot.politician_id;
  IF n_terms <> 0 THEN
    RAISE EXCEPTION 'CC_0272: % new person(s) hold an office term', n_terms;
  END IF;

  -- exactly the three judged rows remain unlinked
  SELECT count(*) INTO n_left FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id=rc.race_id
    JOIN essentials.elections e ON e.id=r.election_id
   WHERE e.name='2026 LA County General' AND rc.politician_id IS NULL;
  IF n_left <> 3 THEN
    RAISE EXCEPTION 'CC_0272: % LA County rows unlinked, expected exactly 3', n_left;
  END IF;

  SELECT count(*) INTO n_bad FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id=rc.race_id
    JOIN essentials.elections e ON e.id=r.election_id
   WHERE e.name='2026 LA County General' AND rc.politician_id IS NULL
     AND rc.full_name NOT IN ('Christine R. Sarmiento','Mark Copland','Michael Braun');
  IF n_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0272: the 3 remaining unlinked rows are not the 3 that were judged';
  END IF;

  SELECT count(*) INTO n_offsite FROM essentials.race_candidates rc
   WHERE NULLIF(rc.photo_url,'') IS NOT NULL
     AND rc.result IS DISTINCT FROM 'not_nominated'
     AND rc.photo_url NOT LIKE '%supabase.co/storage/v1/object/public/%';
  IF n_offsite <> 0 THEN
    RAISE EXCEPTION 'CC_0272: % live ballot row(s) render off-site', n_offsite;
  END IF;

  RAISE NOTICE 'CC_0272 OK - 408 people created and linked; 3 left unlinked by judgement';
END $$;

DROP TABLE _new;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE: A REFUSAL ONLY STICKS IF A TOOL CAN READ IT.
-- Cheryl Williams was refused in CC_0265, refused again in CC_0271, and matched a third time
-- here -- because a refusal recorded in a migration header is prose, and the sweep reads rows.
-- The decision belongs in duplicate-people-baseline.json, with the evidence as its note.
-- ⚠ AND THERE IS A THIRD STATE BESIDES LINK AND CREATE. For Sarmiento, Copland and Braun we can
-- show neither sameness nor difference, so creating a row would assert "different" just as
-- falsely as linking would assert "same". Unlinked is not a gap in the work; it is the finding.
-- ───────────────────────────────────────────────────────────────────────────────────────────
