-- CC_0265_link_wa_house_members_to_senate_candidacies.sql
--
-- Links FIVE candidacy rows: sitting Washington State House members running for the Senate
-- seat in THEIR OWN legislative district.
--
--   Alex Ybarra       House LD 13 -> WA State Senate LD 13
--   Jeremie Dufault   House LD 15 -> WA State Senate LD 15
--   Sharlett Mena     House LD 29 -> WA State Senate LD 29
--   Cindy Ryu         House LD 32 -> WA State Senate LD 32
--   Chipalo Street    House LD 37 -> WA State Senate LD 37
--
-- 🔴 THIS IS 5 OF 40, AND THE OTHER 35 ARE REFUSED. THE REASON IS STRUCTURAL AND WORTH MORE
-- THAN THE FIVE LINKS: THE EVIDENCE INSTRUMENT CC_0263 RELIED ON DOES NOT EXIST OUTSIDE
-- CALIFORNIA.
-- CC_0262 and CC_0263 linked candidates on the California BALLOT DESIGNATION -- a candidate's
-- own sworn statement of occupation, printed beside their name on the Secretary of State's
-- certified list ("California State Senator", "Orange County Supervisor"). It is what ties a
-- CANDIDACY to an OFFICEHOLDER rather than merely to a name.
-- Washington, Colorado, Indiana and Oregon do not print one. Washington's certified list is
-- names and parties only -- and is published as a SCANNED IMAGE from a photocopier (producer
-- "SHARP MX-4071") with no text layer at all. So for 35 of the 40 there is no document that
-- says the candidate is the officeholder, and a name is what is left.
--
-- WHAT CARRIES THESE FIVE INSTEAD: a non-name fact present in BOTH records. The district
-- NUMBER is identical on each side -- the person we record sitting for House District 13 and
-- the person filing for Senate District 13 -- in the same state, with the two districts
-- confirmed to intersect by ST_Intersects over essentials.geofence_boundaries. Two people of
-- the same name inside one legislative district, one of them its sitting representative, is
-- not a coincidence this corpus should absorb silently. A House member standing for their own
-- district's Senate seat is also the most ordinary progression in a state legislature.
-- ⚠ It is an inference from a pattern, not a document. It is weaker than CC_0263's standard
-- and is recorded as such. If that is judged too thin, these five revert the way CC_0264
-- reverted Sonja Shaw.
--
-- ─── REFUSED (35), and why ────────────────────────────────────────────────────────────────
--  23  WE RECORD NO OFFICE FOR THE MATCHED PERSON AT ALL -- nothing to corroborate against.
--      Includes seven LA County Superior Court judicial candidates, five Indiana township
--      races, and the four CC_0263 already refused (Gates, Hawks, Brown, Delgado).
--   2  🔴 WRONG STATE -- CONFIRMED WRONG PERSON, and the find that justifies the whole method:
--        Cheryl Williams, candidate for Inglewood Unified School Board (CA), name-matches a
--          politician who is a Commissioner in COLLIN COUNTY, TEXAS.
--        Amanda Campbell, candidate for Colorado Secretary of State, name-matches a board
--          member of ALLEN INDEPENDENT SCHOOL DISTRICT, TEXAS.
--      Both would have linked cleanly on "exactly one active namesake". A same-state check
--      costs nothing and caught two wrong people in forty.
--   5  OVERLAP ONLY -- a real jurisdiction that intersects the district sought, but no second
--      fact: Jessica Forsythe and Vanessa Kritzer (Redmond councilmembers -> WA House 48/45),
--      Alfonso Morales (Lynwood Unified board -> Lynwood City Council), Mark Copland
--      (Norwalk-La Mirada trustee area 6 -> area 5), John Dugger (Beaverton council position
--      5 -> position 1). These are the tier CC_0263 accepted WITH a designation; without one
--      they are left alone.
--   3  COLORADO STATEWIDE, strong but undocumented: Jena Griswold (sitting CO Secretary of
--      State -> CO Attorney General), Phil Weiser (sitting CO Attorney General -> CO
--      Governor), Jeff Bridges (CO Senate 26 -> CO Treasurer). Statewide races have no
--      district geometry, so the geographic corroborator cannot run, and Colorado prints no
--      designation. ▶ These three are the best candidates for a follow-up: one citation each
--      from a Colorado source naming the officeholder as the candidate and they meet the
--      CC_0263 bar.
--   1  Nikki Torres -- sitting WA senator for district 15, filing in district 8, so the
--      district-number fact that carries the other five does NOT apply. Press reports a
--      court-ordered redistricting moved her out of the new 15th, which would explain it
--      exactly -- but a press summary is the thing CC_0262 refused for Ben Allen, and it is
--      refused here for the same reason.
--   1  Sonja Shaw -- reverted by CC_0264 on an operator ruling; not re-linked here.
--
-- ▶ EFFECT: all five already have a politician photograph and none of the five candidacy rows
-- carries its own photo_url, so each ballot page gains an image through
-- COALESCE(rc.photo_url, pi.url). Stance counts are checked but not changed by this file.
--
-- Idempotent: re-running changes nothing.

BEGIN;

CREATE TEMP TABLE _wa (
  rc_id         uuid PRIMARY KEY,
  name_like     text NOT NULL,
  politician_id uuid NOT NULL,
  district_no   text NOT NULL        -- identical on both sides; the fact this link rests on
) ON COMMIT DROP;

INSERT INTO _wa (rc_id, name_like, politician_id, district_no) VALUES
  ('3d91f561-055f-4f12-ac37-da9a5fff0353'::uuid, 'Alex Ybarra',
   'b0ba6ded-89b3-49f4-9aab-8aefea840384'::uuid, '13'),
  ('4d853d2e-b0e6-498d-81f1-96c3e40d26db'::uuid, 'Jeremie Dufault',
   '72f1981b-ff10-48dd-8c92-e6ea2c169902'::uuid, '15'),
  ('425cc40e-76b7-4ca9-8843-ab8bc8ba292f'::uuid, 'Sharlett Mena',
   '363fe07c-171e-4044-b6f9-979662962027'::uuid, '29'),
  ('37bdc3b0-47f9-4764-8d32-6de499c39ea8'::uuid, 'Cindy Ryu',
   '86e6a2bf-5216-4022-900c-621a8480f2e7'::uuid, '32'),
  ('0ae76fff-72fd-4a0d-b5b3-02f65f13cbbb'::uuid, 'Chipalo Street',
   '7a0da48f-2c29-463e-969a-52d06137cde9'::uuid, '37');

-- Guard: name on both sides, politician active and unambiguous, candidacy unlinked -- AND the
-- district number must still be the one on both records. That last check is the whole
-- argument of this migration, so it is asserted rather than assumed.
DO $$
DECLARE r record; v_rc_name text; v_rc_pol uuid; v_p_name text; v_active bool;
        v_namesakes int; v_held text; v_sought text;
BEGIN
  FOR r IN SELECT * FROM _wa LOOP
    SELECT rc.full_name, rc.politician_id, rr.position_name
      INTO v_rc_name, v_rc_pol, v_sought
      FROM essentials.race_candidates rc
      JOIN essentials.races rr ON rr.id = rc.race_id
     WHERE rc.id = r.rc_id;
    IF v_rc_name IS NULL THEN
      RAISE EXCEPTION 'CC_0265: race_candidates row % does not exist', r.rc_id;
    END IF;
    IF v_rc_name <> r.name_like THEN
      RAISE EXCEPTION 'CC_0265: row % is "%", expected "%"', r.rc_id, v_rc_name, r.name_like;
    END IF;
    IF v_rc_pol IS NOT NULL AND v_rc_pol <> r.politician_id THEN
      RAISE EXCEPTION 'CC_0265: row % already links to %, REFUSING', r.rc_id, v_rc_pol;
    END IF;
    IF substring(v_sought from '[0-9]+$') IS DISTINCT FROM r.district_no THEN
      RAISE EXCEPTION 'CC_0265: % seeks "%", which is not district % - the fact this link '
                      'rests on is gone, REFUSING', r.name_like, v_sought, r.district_no;
    END IF;

    SELECT p.full_name, p.is_active INTO v_p_name, v_active
      FROM essentials.politicians p WHERE p.id = r.politician_id;
    IF v_p_name IS NULL OR lower(v_p_name) <> lower(r.name_like) THEN
      RAISE EXCEPTION 'CC_0265: politician % is "%", expected "%"',
        r.politician_id, v_p_name, r.name_like;
    END IF;
    IF NOT v_active THEN
      RAISE EXCEPTION 'CC_0265: % is not active', r.name_like;
    END IF;

    SELECT count(*) INTO v_namesakes FROM essentials.politicians p
     WHERE p.is_active AND lower(p.full_name) = lower(r.name_like);
    IF v_namesakes <> 1 THEN
      RAISE EXCEPTION 'CC_0265: % matches % active politicians - no longer unambiguous, REFUSING',
        r.name_like, v_namesakes;
    END IF;

    SELECT d.label INTO v_held
      FROM essentials.office_terms ot
      JOIN essentials.offices o ON o.id = ot.office_id
      LEFT JOIN essentials.districts d ON d.id = o.district_id
     WHERE ot.politician_id = r.politician_id AND ot.term_end IS NULL
     ORDER BY ot.term_start DESC NULLS LAST LIMIT 1;
    IF v_held IS NULL OR substring(v_held from '[0-9]+$') IS DISTINCT FROM r.district_no THEN
      RAISE EXCEPTION 'CC_0265: % holds "%", not district % - REFUSING', r.name_like,
        COALESCE(v_held, '(no seat)'), r.district_no;
    END IF;
  END LOOP;
END $$;

UPDATE essentials.race_candidates rc
SET politician_id = w.politician_id
FROM _wa w
WHERE rc.id = w.rc_id AND rc.politician_id IS DISTINCT FROM w.politician_id;

-- post-verify: five linked, and the two CONFIRMED WRONG-PERSON matches are still unlinked.
DO $$
DECLARE n_linked int; n_wrong int; n_multi int;
BEGIN
  SELECT count(*) INTO n_linked
    FROM _wa w JOIN essentials.race_candidates rc
      ON rc.id = w.rc_id AND rc.politician_id = w.politician_id;
  IF n_linked <> 5 THEN
    RAISE EXCEPTION 'CC_0265: expected 5 linked rows, found %', n_linked;
  END IF;

  -- the cross-state collisions must stay unlinked; they are the reason the method exists
  SELECT count(*) INTO n_wrong
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
   WHERE rc.politician_id IS NOT NULL
     AND ((rc.full_name = 'Cheryl Williams' AND e.state = 'CA')
       OR (rc.full_name = 'Amanda Campbell' AND e.state = 'CO'));
  IF n_wrong <> 0 THEN
    RAISE EXCEPTION 'CC_0265: % cross-state wrong-person match(es) got linked', n_wrong;
  END IF;

  SELECT count(*) INTO n_multi FROM (
    SELECT pi.politician_id FROM essentials.politician_images pi
     WHERE pi.politician_id IN (SELECT politician_id FROM _wa) AND pi.type = 'default'
     GROUP BY pi.politician_id HAVING count(*) > 1) x;
  IF n_multi <> 0 THEN
    RAISE EXCEPTION 'CC_0265: % linked politician(s) have more than one default image', n_multi;
  END IF;

  RAISE NOTICE 'CC_0265 OK - 5 WA House members linked to their own district Senate candidacies';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE FINDING IS THE REFUSAL RATE, NOT THE FIVE LINKS. Forty candidacy rows each had
-- EXACTLY ONE active same-name politician -- the cleanest-looking signal available -- and
-- only five could be evidenced. Two were demonstrably different people in another state.
-- "Exactly one namesake" is a filter for what to INVESTIGATE, never a reason to link.
-- 🟢 THE CHEAPEST CHECK WAS THE BEST ONE: comparing the election's state with the state of the
-- district the matched person holds. One join, no documents, and it caught both wrong people.
-- ▶ WHAT WOULD UNLOCK THE REST: a per-state source that ties a candidacy to an officeholder.
-- California prints one on the ballot; most states do not. Until such a source is identified
-- per state, candidate-to-politician linking outside California cannot be done at the
-- CC_0263 standard, and should not be done at a lower one quietly.
-- ───────────────────────────────────────────────────────────────────────────────────────────
