-- CC_0271_link_la_county_2026_general_candidates.sql
--
-- Links SIXTEEN 2026 LA County General candidacies to politician rows we already hold, found by
-- the dedupe pass the handoff requires before any creation
-- (.planning/todos/2026-10-20-candidate-person-linking-handoff.md).
--
-- 427 rows were unlinked. 25 matched an existing person on a name variant. Of those 25: 16 are
-- linked here, 5 are confirmed DIFFERENT PEOPLE, and 4 are left unlinked for want of a document.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- ═══ EVIDENCE, BY INSTRUMENT ═══
--
-- ▶ A. PRIMARY-ADVANCED CONTINUITY -- the seven judicial rows, and they are the cleanest links
-- this programme has made. Each politician already holds a candidacy for the SAME numbered LA
-- Superior Court office with result 'runoff'. A runoff candidate for Office 87 IS the November
-- candidate for Office 87; the office number is matched exactly, not by title text.
--     Bayne & DeJute      -> Office  87   (both runoff)
--     Ross & Tryfman      -> Office 131   (both runoff)
--     Clayton             -> Office  65
--     Ghobadi & Haymon    -> Office  64
-- ⚠ The handoff recorded the judicial rows as carrying NO ballot designation and therefore being
-- hard to evidence. That was true and irrelevant: instrument B does not need one. All seven
-- bring a photograph, and five bring compass answers.
--
-- ▶ B. GEOGRAPHIC CORROBORATION -- the seat held lies inside the seat sought. Area share, never
-- the bare ST_Intersects predicate. Controls in brackets, all 0.0%:
--     Alfonso Morales   Lynwood Unified Board -> Lynwood City Council        97.7%  [Hawthorne 0.0%]
--       🟢 AND THE DESIGNATION AGREES: "Attorney/School Boardmember". Designation + record +
--          geometry all name the same city. This is the CC_0262 shape exactly.
--     Sergio R. Mortara Hawthorne Board       -> Hawthorne City Council      96.5%  [Lynwood 0.0%]
--     David Siegrist    El Monte City Board   -> Rio Hondo CCD Trustee Area 1 58.5% [Lynwood 0.0%]
--       ⚠ 58.5% is the WEAKEST geometric link here and is named as such. A community college
--          district overlays several K-12 districts, so partial containment is the expected
--          shape rather than a defect -- but if one row in this migration is to be reverted,
--          it is this one.
--
-- ▶ C. IMPORT-COHORT PROVENANCE -- Phil Brock and Oscar de la Torre.
-- Both carry 4 compass answers, so a wrong link would publish another person's positions. Neither
-- has an office_terms row, so geometry could not run. What identified them was the SCRAPE COHORT:
-- their external_ids sit inside an unbroken block of Santa Monica City Council members --
--     -201401 Lana Negrete     Council Member, City of Santa Monica
--     -201404 Caroline Torosis Council Member, City of Santa Monica
--     -201405 Jesse Zwick      Council Member, City of Santa Monica
--     -201400 Phil Brock       (no office recorded)
--     -201402 Oscar de la Torre(no office recorded)
-- -- and the races they seek are Santa Monica City Council and Santa Monica Community College
-- Board. Same roster, same city.
-- ⚠ THIS IS AN INFERENCE FROM IMPORT ORDERING, NOT A DOCUMENT. It is weaker than A or B and is
-- labelled so. It is accepted because the city matches on both sides and because the alternative
-- -- creating a second Phil Brock -- would split four researched answers off a live ballot page.
-- 🔴 SEPARATE DEFECT FOUND, NOT FIXED HERE: Brock, de la Torre and Christine Parra (-201403) are
-- Santa Monica councilmembers with NO office_terms row, so they are invisible in Essentials.
-- That is the `offices_missing_terms` failure CLAUDE.md warns of. Owed a seating migration.
--
-- ▶ D. PRIOR DOCUMENTED CANDIDACY IN THE SAME COUNTY -- Elaine Alaniz and Tonia Arey. Each holds
-- a recorded Los Angeles County Board of Supervisors candidacy (result 'lost') and now seeks a
-- Los Angeles Community College Board seat. Exact name, same county, and each brings an image.
--
-- ▶ E. BARE ROW, SAME COUNTY -- Dora D. Sandoval and Stacy Fortner. Both existing rows came from
-- `netfile_laco_2024`, i.e. an LA County campaign-finance filer of that name, and both are BARE:
-- no office, no term, no answers, no image, no candidacy. Linking a bare row cannot misattribute
-- anything, and creating a second row would be the duplicate the house rule forbids. This is the
-- weakest tier in the migration and is only acceptable because the downside is empty.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- ═══ 🔴🔴 FIVE CONFIRMED DIFFERENT PEOPLE -- REFUSED ═══
-- Each had exactly one plausible namesake. Four were caught by comparing the election's state
-- with the state of the seat the matched person actually holds.
--
--   Alisa Gentry     Saugus Union School Board  vs "Al Gentry", KENTUCKY State House
--   Cheryl Williams  Inglewood USD TA-1         vs Collin County commissioner, TEXAS
--                      (already confirmed wrong in CC_0265 and STILL matching)
--   Melissa C. Smith Hacienda La Puente USD     vs Prosecuting Attorney, St. Louis County, MISSOURI
--   James M. Bishop Sr. Lynwood Unified Board   vs "Jim Bishop", ARIZONA State Senate 26 (advanced)
--   Francisco Sanchez Palmdale City Council D4  vs "Francis De Leon Sanchez", Bell Gardens council
--                      -- Bell Gardens against Palmdale D4: NO intersection, 0.0%. Same county,
--                         opposite ends of it. Geography refuted this one, not the state test.
--
-- ═══ ⚠ FOUR LEFT UNLINKED FOR WANT OF A DOCUMENT ═══
-- Not "different people" -- "not shown to be the same person". They keep the honest state.
--
--   🔴 MARK COPLAND -- holds Norwalk-La Mirada Unified TRUSTEE AREA 6, seeks TRUSTEE AREA 5 of
--      the SAME district. The two areas return ST_Intersects = TRUE at **0.0% shared area** --
--      they are disjoint by construction and touch along a line. This is the Santa Barbara trap
--      in miniature: the predicate says yes, the area says no. A sitting TA-6 member may well be
--      the TA-5 candidate after a boundary redraw, but that needs the redraw, not an inference.
--      Same shape as the Nikki Torres refusal in CC_0265.
--   CHRISTINE R. SARMIENTO -- holds a CA GOVERNOR candidacy, seeks EL MONTE MAYOR. Statewide to
--      city on an exact name alone is the Sonja Shaw shape: a strong prior, not evidence. She
--      carries an image, so a wrong link publishes a wrong FACE on a ballot page.
--   MICHAEL BRAUN -- Walnut Valley Water District Board. Matches THREE rows: an ARIZONA State
--      Senate 28 candidate, an archived row, and a bare row. One of them may be him; nothing
--      says which. (The same name also matches Mike Braun, Governor of Indiana.)
--   JOSE R. GONZALEZ -- Cudahy City Council, vs a bare "Jose Gonzalez" netfile row. The name is
--      too common for a bare-row link to mean anything. He gets a NEW row in CC_0272.
--
-- ▶ WHAT THIS CARRIES: 9 of the 16 bring a default image to a ballot page that had none, and
-- 19 published compass answers come into view (Brock 4, de la Torre 4, Tryfman 3, Clayton 2,
-- Ghobadi 2, Haymon 2, Ross 2). None are draft. Every one of the 16 candidacy rows has
-- photo_url NULL, so nothing is overridden and nothing is cleared.
--
-- Idempotent: re-running changes nothing.

BEGIN;

CREATE TEMP TABLE _link (
  rc_id uuid PRIMARY KEY, cand text NOT NULL, pol_id uuid NOT NULL, basis text NOT NULL
) ON COMMIT DROP;

INSERT INTO _link VALUES
 ('1b73dbbe-8ece-4dbb-acca-b4bd92d86eca','Anthony (A.J.) Bayne','9f40d56d-8e04-4ef9-8d26-bd5f3ca5fbeb','A: runoff, office 87'),
 ('3d99fd4e-d8c5-41b7-943d-3071b03e9fa3','David DeJute','b60a7b50-a9e6-4262-834d-2577adc30762','A: runoff, office 87'),
 ('de31542f-6c41-4b76-ab53-825bd8525ea3','David Ross','475d512a-6737-460d-8634-03b86712d594','A: runoff, office 131'),
 ('091ba449-045d-4ddf-8b77-ffe179786cc1','Donna Tryfman','7f32a8a4-fac8-44d3-af71-01f40895f5ba','A: runoff, office 131'),
 ('f0fd73d0-a05e-406e-a214-a1f969a148d6','Justin Allen Clayton','92e8db0a-71f7-4195-b092-0b3ae1ca1fe5','A: runoff, office 65'),
 ('9a921111-74c9-4d40-9495-8021619f5f03','Maria Ghobadi','861e2613-73ff-41a1-b938-e8f43dda52de','A: runoff, office 64'),
 ('497f9686-bf33-4c8b-afc1-38702c07b653','Rhonda A. Haymon','5926b32e-56b9-48a5-9de2-a17beb0101a7','A: runoff, office 64'),
 ('5ca34dfd-f70e-4078-ad0a-cd38c70c0918','Alfonso Morales','6c43482f-7ede-443a-aa87-072d1c555eb6','B: geo 97.7% + designation'),
 ('41beea01-311d-43d7-8507-29e866e038f0','Sergio Roberto Mortara','9fa27bc9-c6a3-5e43-a632-560280f3ae56','B: geo 96.5%'),
 ('176cc030-f725-4713-9cd7-9b907c78fd60','David Stephen Siegrist','c4d72241-cf6d-5b5b-b3fc-7d2b6e2c8552','B: geo 58.5% WEAKEST'),
 ('c95f6617-ddc3-425e-9533-cc1d3806460a','Phil Brock','7714b7c6-9283-4ab8-802e-cbcfba5ddc96','C: Santa Monica roster'),
 ('684c24e4-3ee0-42bc-bba5-b12e33885310','Oscar de la Torre','86e513e7-d0a7-4419-8edd-6113629d7998','C: Santa Monica roster'),
 ('164694ef-c883-479d-9158-a63c31af3ea5','Elaine Alaniz','fbe6117e-f8e0-45c4-8b6d-c85a73d79810','D: prior LA County candidacy'),
 ('743be493-69da-4d49-88b1-7bb83c97a192','Tonia Arey','73f1625a-888d-434a-bb7c-af97198d9069','D: prior LA County candidacy'),
 ('79852088-a16f-4228-b78f-29285ca8a1c7','Dora D. Sandoval','ac02eb00-b29d-48a3-95f4-62508c8ba7b8','E: bare netfile row'),
 ('87923846-5505-464d-a722-020c8d3925eb','Stacy Fortner','3e0c7109-e0a8-469a-b252-8e62b1353ec3','E: bare netfile row');

DO $$
DECLARE r record; v_name text; v_pid uuid; v_act bool; v_imgs int;
BEGIN
  FOR r IN SELECT * FROM _link LOOP
    SELECT p.full_name, p.is_active INTO v_name, v_act
      FROM essentials.politicians p WHERE p.id = r.pol_id;
    IF v_name IS NULL THEN
      RAISE EXCEPTION 'CC_0271: politician % does not exist', r.pol_id;
    END IF;
    IF NOT v_act THEN
      RAISE EXCEPTION 'CC_0271: % is ARCHIVED - linking would resurrect a retired row', v_name;
    END IF;
    SELECT count(*) INTO v_imgs FROM essentials.politician_images pi
     WHERE pi.politician_id = r.pol_id AND pi.type='default';
    IF v_imgs > 1 THEN
      RAISE EXCEPTION 'CC_0271: % has % default images - ambiguous photo', v_name, v_imgs;
    END IF;

    SELECT rc.full_name, rc.politician_id INTO v_name, v_pid
      FROM essentials.race_candidates rc WHERE rc.id = r.rc_id;
    IF v_name IS NULL THEN
      RAISE EXCEPTION 'CC_0271: race_candidates row % does not exist', r.rc_id;
    END IF;
    IF v_name <> r.cand THEN
      RAISE EXCEPTION 'CC_0271: row % is "%", expected "%"', r.rc_id, v_name, r.cand;
    END IF;
    IF v_pid IS NOT NULL AND v_pid <> r.pol_id THEN
      RAISE EXCEPTION 'CC_0271: row % already linked to %, REFUSING to repoint', r.rc_id, v_pid;
    END IF;
  END LOOP;
END $$;

UPDATE essentials.race_candidates rc
SET politician_id = l.pol_id
FROM _link l
WHERE rc.id = l.rc_id AND rc.politician_id IS DISTINCT FROM l.pol_id;

DO $$
DECLARE n_linked int; n_render int; n_bad int;
BEGIN
  SELECT count(*) INTO n_linked FROM essentials.race_candidates rc
    JOIN _link l ON l.rc_id = rc.id WHERE rc.politician_id = l.pol_id;
  IF n_linked <> 16 THEN
    RAISE EXCEPTION 'CC_0271: expected 16 linked rows, found %', n_linked;
  END IF;

  SELECT count(*) INTO n_render
    FROM essentials.race_candidates rc JOIN _link l ON l.rc_id = rc.id
    LEFT JOIN LATERAL (SELECT pi.url FROM essentials.politician_images pi
                        WHERE pi.politician_id = rc.politician_id AND pi.type='default' LIMIT 1) pi ON true
   WHERE NULLIF(COALESCE(rc.photo_url, pi.url),'') IS NOT NULL;
  IF n_render <> 9 THEN
    RAISE EXCEPTION 'CC_0271: expected 9 ballot pages to gain a photograph, found %', n_render;
  END IF;

  -- 🔴 the five confirmed wrong people and the four undocumented must all stay unlinked
  SELECT count(*) INTO n_bad FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id=rc.race_id
    JOIN essentials.elections e ON e.id=r.election_id
   WHERE e.name='2026 LA County General' AND rc.politician_id IS NOT NULL
     AND rc.full_name IN ('Alisa Gentry','Cheryl Williams','Melissa C. Smith',
                          'James M. Bishop Sr.','Francisco Sanchez',
                          'Mark Copland','Christine R. Sarmiento','Michael Braun','Jose R. Gonzalez');
  IF n_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0271: % refused row(s) got linked', n_bad;
  END IF;

  RAISE NOTICE 'CC_0271 OK - 16 linked, 9 ballot pages gain a photograph, 9 refusals hold';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE: WHEN GEOMETRY CANNOT RUN, SAY WHAT YOU USED INSTEAD AND HOW STRONG IT IS.
-- Four instruments carried these sixteen, and they are not equal. A runoff for the same numbered
-- office is a document. An import cohort is an inference. A bare row in the right county is
-- barely anything -- it is acceptable only because linking a row with nothing attached cannot
-- misattribute anything. Labelling the tier is what makes a later revert a two-line decision.
-- ⚠ AND THE REFUSALS ARE THE PRODUCT TOO: five of twenty-five were different people, which is
-- the 1-in-5 end of the rate this programme has been measuring. Cheryl Williams was confirmed
-- wrong in CC_0265 and was still sitting there matching, because a refusal recorded in a
-- migration header does not stop the next sweep finding her again.
-- ───────────────────────────────────────────────────────────────────────────────────────────
