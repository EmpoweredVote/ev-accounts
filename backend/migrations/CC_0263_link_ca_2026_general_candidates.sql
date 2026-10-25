-- CC_0263_link_ca_2026_general_candidates.sql
--
-- Links ELEVEN candidacy rows, for TEN people, in the CA 2026 Statewide General (and two
-- primary rows that advanced into it), to the politician rows that are the same person.
-- Same job as CC_0262 did for Ben Allen, held to the same standard of evidence.
--
-- 🔴 A NAME MATCH IS A LEAD, NOT EVIDENCE. Of 324 candidates in that election, 131 were
-- unlinked. 117 of those have NO politician row at all and are untouched here. 14 had exactly
-- one active same-name politician row -- and FOUR OF THOSE FOURTEEN ARE REFUSED BELOW,
-- because a name was all they had.
--
-- THE TEST, per CC_0262: the California Secretary of State's Official Certified List of
-- Candidates (8/27/2026, elections.cdn.sos.ca.gov/statewide-elections/2026-general/
-- cert-list-candidates.pdf) prints each candidate's BALLOT DESIGNATION -- their own sworn
-- statement of occupation. A link is made only where that designation corroborates the office
-- we INDEPENDENTLY record the matched politician holding. Where the designation names only a
-- ROLE TYPE ("City Councilmember") rather than a specific body, the role match is backed by a
-- GEOGRAPHIC test run against our own boundaries: ST_Intersects between the jurisdiction they
-- hold and the district they seek. Both are recorded per row below.
-- ⚠ Control: the same extraction prints "California State Senator" for Ben Allen, matching the
-- separate March primary notice CC_0262 used. The document reads correctly.
--
-- ─── LINKED (10 people, 11 rows) ──────────────────────────────────────────────────────────
--   designation (SOS)                     office we record                    corroboration
--   Eleni Kounalakis
--     "Lieutenant Governor of California"  Lieutenant Governor, California     EXACT OFFICE
--     + her PRIMARY row was already linked to this politician by an earlier pass
--   Donald P. (Don) Wagner
--     "Orange County Supervisor"           Supervisor, District 3, Orange Cty  EXACT OFFICE
--     + his PRIMARY row was already linked to this politician by an earlier pass
--   Avelino Valencia
--     "California State Assemblymember"    Assembly Member, AD 68              OFFICE TYPE + AD68 intersects SD34
--   Damon Connolly
--     "California State Assemblymember"    Assembly Member, AD 12              OFFICE TYPE + AD12 intersects SD2
--   Shannon Grove
--     "State Senator/Businesswoman"        Senator, State Senate District 12   OFFICE TYPE + SD12 intersects BOE 1
--   Gracey Van Der Mark
--     "Councilwoman/Business Owner"        Council Member, Huntington Beach    ROLE + city intersects AD72
--   Deborah Klein Lopez
--     "City Councilmember"                 Council Member, Agoura Hills        ROLE + city intersects AD42
--   Paul Seo
--     "Mayor/Corruption Prosecutor"        Council Member, Rancho Palos Verdes ROLE + city intersects AD66
--       ⚠ "Mayor" vs our "Council Member" is consistent, not contradictory: in Rancho Palos
--         Verdes the mayor is a sitting council member chosen by the council, not separately
--         elected. The geographic test is what carries this row.
--   Sara Deen
--     "School Boardmember/Businesswoman"   Board Member, Palos Verdes Peninsula Unified
--                                                                              ROLE + district intersects AD66
--   Sonja Shaw (TWO rows: the primary she advanced from, and the general)
--     "School District President"          Board Member (Trustee Area 3), Chino Valley USD
--                                                                              ROLE ONLY
--       ⚠ WEAKEST OF THE TEN AND SAID SO. Superintendent of Public Instruction is a STATEWIDE
--         race, so there is no geographic test to run, and the designation does not name which
--         district. It rests on an exact unique name plus a role type we independently record
--         in California. If that is judged too thin, this is the row to revert.
--
-- ─── REFUSED (4), name-only ───────────────────────────────────────────────────────────────
--   Michael E. Gates     "Deputy United States Attorney"  -- we record NO office for him
--   Jennifer Hawks       "Retired Business Executive"     -- we record NO office for her
--   Ashley M. Brown      "School Social Worker"           -- we record NO office for her
--   Ed Delgado           "City Council Member"            -- we record NO office for him
--     ⚠ Delgado is the interesting refusal: his designation DOES claim an office, and we hold
--       a same-named active politician with NO term at all. So either our occupancy data is
--       incomplete or this is a different Ed Delgado -- and nothing in either record tells us
--       which. That is precisely the case to leave alone.
--
-- ▶ WHAT THE LINKS CARRY BEYOND A JOIN, stated because it is the point of the care:
--   * PHOTOGRAPHS. None of the 11 rows carries its own photo_url, so each inherits the
--     politician's image through electionService's COALESCE(rc.photo_url, pi.url). Seven of
--     the ten have one; Seo, Deen and Shaw have none and will still render blank.
--   * PUBLISHED STANCES, now reachable from a live November race rather than only a profile:
--     Valencia 24, Kounalakis 22, Connolly 20, Grove 17. The other six have none.
--     No answer is created, altered or moved by this migration.
--   * is_incumbent is NOT touched on either table. politicians.is_incumbent describes the seat
--     each already holds; race_candidates.is_incumbent describes the race being contested.
--     They answer different questions and both are already right.
--
-- Idempotent: re-running changes nothing.

BEGIN;

CREATE TEMP TABLE _link (
  rc_id         uuid PRIMARY KEY,
  name_like     text NOT NULL,
  politician_id uuid NOT NULL,
  designation   text NOT NULL        -- the SOS ballot designation this link rests on
) ON COMMIT DROP;

INSERT INTO _link (rc_id, name_like, politician_id, designation) VALUES
  ('92098672-ed73-4f9e-8fe7-ee80c1d8f27b'::uuid, 'Eleni Kounalakis',
   '03df7cce-7502-4089-acd5-139841002cbe'::uuid, 'Lieutenant Governor of California'),
  ('d4da5724-bfbb-4862-9d6b-ed246cd50934'::uuid, 'Donald P. Wagner',
   'c09bed40-e329-45a5-a5f1-5293e038cc66'::uuid, 'Orange County Supervisor'),
  ('62b18a26-5030-43df-9f70-05a76bd80374'::uuid, 'Avelino Valencia',
   'a1467b58-9cc8-4611-a03e-07defc1679bf'::uuid, 'California State Assemblymember'),
  ('382f7d0e-9513-4814-b5a3-3d91ca632dc5'::uuid, 'Damon Connolly',
   'ab26d178-4f69-4ffc-9485-ac03f87643e2'::uuid, 'California State Assemblymember'),
  ('fb0bd62e-d070-48b1-ab15-3b2516d97929'::uuid, 'Shannon Grove',
   '03ee06fb-9b51-41cc-8942-4632f3a724e3'::uuid, 'State Senator/Businesswoman'),
  ('d2844400-1923-4d9a-81c1-0f0641b070e4'::uuid, 'Gracey Van Der Mark',
   'a5595064-ce36-4b12-8eca-a2d796759d53'::uuid, 'Councilwoman/Business Owner'),
  ('c0ebc8be-2514-4f72-a22c-64466b57546c'::uuid, 'Deborah Klein Lopez',
   'f1f9d53e-2972-406d-9979-90119d893508'::uuid, 'City Councilmember'),
  ('8fb37db6-1429-496a-a51c-23d48310cd71'::uuid, 'Paul Seo',
   'cb39159d-d293-41c7-a1ac-a379c39de3c4'::uuid, 'Mayor/Corruption Prosecutor'),
  ('94749547-4695-479c-a049-407cb5847eb1'::uuid, 'Sara Deen',
   '7369ca2d-8aa8-40af-ace0-99a039b6e940'::uuid, 'School Boardmember/Businesswoman'),
  ('4939c2c8-9bc4-4524-bdaf-daadff60f38c'::uuid, 'Sonja Shaw',
   '5f76110b-eb6c-59b4-8c6a-c97e8722cc05'::uuid, 'School District President'),
  ('3e2a7783-ebf5-4d35-b9cb-f396c30dceab'::uuid, 'Sonja Shaw',
   '5f76110b-eb6c-59b4-8c6a-c97e8722cc05'::uuid, 'School District President');

-- Guard, per row: the candidacy must be the expected person and unlinked (or already linked to
-- the SAME politician); the politician must be active and named the same; and the name must
-- still identify exactly ONE active politician. A second namesake appearing invalidates the
-- reasoning for that row, so it REFUSES rather than guessing.
DO $$
DECLARE r record; v_rc_name text; v_rc_pol uuid; v_p_name text; v_active bool; v_namesakes int;
BEGIN
  FOR r IN SELECT * FROM _link LOOP
    SELECT rc.full_name, rc.politician_id INTO v_rc_name, v_rc_pol
      FROM essentials.race_candidates rc WHERE rc.id = r.rc_id;
    IF v_rc_name IS NULL THEN
      RAISE EXCEPTION 'CC_0263: race_candidates row % does not exist', r.rc_id;
    END IF;
    IF v_rc_name <> r.name_like THEN
      RAISE EXCEPTION 'CC_0263: row % is "%", expected "%"', r.rc_id, v_rc_name, r.name_like;
    END IF;
    IF v_rc_pol IS NOT NULL AND v_rc_pol <> r.politician_id THEN
      RAISE EXCEPTION 'CC_0263: row % is already linked to %, REFUSING to repoint it',
        r.rc_id, v_rc_pol;
    END IF;

    SELECT p.full_name, p.is_active INTO v_p_name, v_active
      FROM essentials.politicians p WHERE p.id = r.politician_id;
    IF v_p_name IS NULL THEN
      RAISE EXCEPTION 'CC_0263: politician % does not exist', r.politician_id;
    END IF;
    IF lower(v_p_name) <> lower(r.name_like) THEN
      RAISE EXCEPTION 'CC_0263: politician % is "%", expected "%"',
        r.politician_id, v_p_name, r.name_like;
    END IF;
    IF NOT v_active THEN
      RAISE EXCEPTION 'CC_0263: % is not active - refusing to link a candidacy to them', r.name_like;
    END IF;

    SELECT count(*) INTO v_namesakes FROM essentials.politicians p
     WHERE p.is_active = true AND lower(p.full_name) = lower(r.name_like);
    IF v_namesakes <> 1 THEN
      RAISE EXCEPTION 'CC_0263: % now matches % active politicians - no longer unambiguous, REFUSING',
        r.name_like, v_namesakes;
    END IF;
  END LOOP;
END $$;

UPDATE essentials.race_candidates rc
SET politician_id = l.politician_id
FROM _link l
WHERE rc.id = l.rc_id AND rc.politician_id IS DISTINCT FROM l.politician_id;

-- post-verify: every row linked, no politician gained a row this migration did not name, and
-- the four refusals are still unlinked.
DO $$
DECLARE n_linked int; n_extra int; n_refused int; n_multi int;
BEGIN
  SELECT count(*) INTO n_linked
    FROM _link l JOIN essentials.race_candidates rc
      ON rc.id = l.rc_id AND rc.politician_id = l.politician_id;
  IF n_linked <> 11 THEN
    RAISE EXCEPTION 'CC_0263: expected 11 linked rows, found %', n_linked;
  END IF;

  -- nothing else attached itself to these ten people in the CA general
  SELECT count(*) INTO n_extra
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.name = 'CA 2026 Statewide General'
     AND rc.politician_id IN (SELECT politician_id FROM _link)
     AND rc.id NOT IN (SELECT rc_id FROM _link);
  IF n_extra <> 0 THEN
    RAISE EXCEPTION 'CC_0263: % unexpected general row(s) now point at these politicians', n_extra;
  END IF;

  -- the four name-only candidates must remain UNLINKED; this migration's discipline is the
  -- refusal as much as the links, so it is asserted rather than trusted.
  SELECT count(*) INTO n_refused
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.name = 'CA 2026 Statewide General'
     AND rc.full_name IN ('Michael E. Gates','Jennifer Hawks','Ashley M. Brown','Ed Delgado')
     AND rc.politician_id IS NOT NULL;
  IF n_refused <> 0 THEN
    RAISE EXCEPTION 'CC_0263: % name-only candidate(s) got linked - that is the thing this '
                    'migration refuses to do', n_refused;
  END IF;

  -- and no linked politician carries two default images, which would make the inherited
  -- photograph ambiguous
  SELECT count(*) INTO n_multi FROM (
    SELECT pi.politician_id FROM essentials.politician_images pi
     WHERE pi.politician_id IN (SELECT politician_id FROM _link) AND pi.type = 'default'
     GROUP BY pi.politician_id HAVING count(*) > 1) x;
  IF n_multi <> 0 THEN
    RAISE EXCEPTION 'CC_0263: % linked politician(s) have more than one default image', n_multi;
  END IF;

  RAISE NOTICE 'CC_0263 OK - 11 rows linked for 10 people; 4 name-only candidates left alone';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE, RESTATED BECAUSE THIS MIGRATION IS MOSTLY AN EXERCISE IN IT: THE REFUSALS ARE
-- THE WORK. Fourteen candidates had exactly one same-name politician row and all fourteen
-- would have linked cleanly. Ten had a document behind them; four had a name. Linking all
-- fourteen would have looked identical in the diff and been wrong four times.
-- 🟢 TWO CORROBORATORS, AND THE SECOND IS OURS: where the SOS designation names only a role
-- ("City Councilmember"), ST_Intersects between the jurisdiction held and the district sought
-- turns a plausible match into a measured one, using boundary data we already hold. Reach for
-- it whenever a designation is generic and the race has geography. It cannot help on a
-- STATEWIDE race -- which is exactly why Sonja Shaw is the weakest row here and is flagged.
-- ▶ STILL OPEN: 117 CA general candidates have no politician row at all, Jane Kim among them.
-- Whether every certified candidate should get one is a policy question well beyond this file.
-- ───────────────────────────────────────────────────────────────────────────────────────────
