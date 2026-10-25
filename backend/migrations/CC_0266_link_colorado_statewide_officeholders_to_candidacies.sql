-- CC_0266_link_colorado_statewide_officeholders_to_candidacies.sql
--
-- Links the THREE Colorado candidacies CC_0265 refused for want of a citation, to the
-- officeholders the citations name:
--
--   7a64fd31-482c-45a1-9409-7971fa20c615  Jena Griswold  CO Attorney General, 2026 General
--     -> 31667cca-d1c9-43f5-bc82-45312793aad0  holds Colorado SECRETARY OF STATE
--   094d2cfc-7063-467a-ad8b-5d642d334ec8  Phil Weiser    CO Governor,         2026 General
--     -> 5bad420d-17de-48ec-94ef-14b901c0ed1d  holds Colorado ATTORNEY GENERAL
--   1c1f3903-4dbe-4bc9-afeb-aa1634324aee  Jeff Bridges   CO Treasurer,        2026 General
--     -> cb0906d5-b6d5-495c-9af0-335a8ad72920  holds COLORADO STATE SENATE DISTRICT 26
--
-- CC_0265 named these three as "the best candidates for a follow-up: one citation each from
-- a Colorado source naming the officeholder as the candidate and they meet the CC_0263 bar."
-- This is that follow-up. The citations were fetched and READ, not summarised from a search
-- result -- the quoted sentences below were extracted from the page bytes.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 WHY A CITATION IS NEEDED AT ALL, AND WHY THESE THREE CLEAR THE BAR THAT SHAW DID NOT.
--
-- CC_0263 linked California candidacies on the BALLOT DESIGNATION -- the candidate's own
-- sworn occupation, printed by the Secretary of State beside their name. CC_0265 then found
-- that no such field exists in Colorado: the CO SOS certified list carries names and parties
-- only. So the evidence has to come from somewhere else, and what it must establish is the
-- same thing the designation established -- that the CANDIDATE and the OFFICEHOLDER are one
-- person, not two people who share a name.
--
-- What makes these three different from Sonja Shaw (linked by CC_0263, reverted by CC_0264):
--
--   * Shaw's designation, "School District President", named a ROLE TYPE held by hundreds of
--     people across California and no district. Nothing in it identified WHICH board.
--   * Each of these three cites a SINGLETON OFFICE. There is exactly one Colorado Secretary
--     of State, exactly one Colorado Attorney General, and exactly one Colorado Senate
--     District 26. A source that says "Colorado Attorney General Phil Weiser is running for
--     governor" has therefore named a seat with ONE occupant, and we independently record
--     who that occupant is. That is the same logical move the ballot designation makes.
--
-- ⚠ Griswold and Weiser hold STATEWIDE seats, so the ST_Intersects corroborator CC_0263 used
-- cannot run for them -- exactly the gap that sank Shaw. What replaces it is that their seats
-- are singletons by construction: a statewide office has no district to intersect BECAUSE
-- there is only one of it. Shaw's role type was a singleton of nothing.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- THE CITATIONS. One per person, each naming the office we independently record them holding,
-- in the same document that reports the candidacy.
--
-- GRISWOLD and WEISER -- one sentence covers both:
--   Denver7 (KMGH, Scripps), "Colorado Secretary of State Jena Griswold announces run for
--   state attorney general", by Stephanie Butzer.
--   https://www.denver7.com/news/local-news/colorado-secretary-of-state-jena-griswold-announces-run-for-colorado-attorney-general
--     "On Monday morning, Colorado Secretary of State Jena Griswold announced that she is
--      running for Colorado attorney general to replace current Attorney General Phil Weiser,
--      who is running for governor."
--   -> Griswold: the office cited is "Colorado Secretary of State"; office_terms seats her on
--      office fe7d477f (Secretary of State, State of Colorado).
--   -> Weiser:   the office cited is "Attorney General"; office_terms seats him on office
--      4fa59236 (Attorney General, State of Colorado).
--
-- WEISER -- second, independent citation:
--   The Colorado Sun, "Colorado Attorney General Phil Weiser launches 2026 campaign for
--   governor". https://coloradosun.com/2025/01/02/phil-weiser-colorado-governor-2026/
--     "Colorado Attorney General Phil Weiser on Thursday launched a 2026 campaign for
--      governor, becoming the first major Democratic candidate to jump into what's expected
--      to be a crowded contest to replace Gov. [Polis]."
--
-- BRIDGES -- names the DISTRICT, which is the strongest of the three:
--   Colorado Politics, "Colorado Democratic Sen. Jeff Bridges announces bid for state
--   treasurer in 2026", by Marianne Goodland.
--   https://www.coloradopolitics.com/2025/04/15/colorado-democratic-sen-jeff-bridges-announces-bid-for-state-treasurer-in-2026-78819f72-3eac-43cc-b1b3-f5f430e26c11
--     "Bridges, of Greenwood Village, has represented Senate District 26 since 2020."
--   -> office_terms seats him on office 8ecafd9d, district "State Senate District 26".
--   Corroborated by the Colorado General Assembly's own roster, which is also the source our
--   office_terms row cites: https://leg.colorado.gov/legislators/jeff-bridges
--     "Senator Jeff Bridges | PARTY Democrat | Representing Counties: Arapahoe Denver
--      Jefferson | District: 26"
--
-- 🟢 AND THE GEOGRAPHIC CORROBORATOR RUNS FOR BRIDGES, because his seat is districted.
-- Colorado Politics places him in Greenwood Village. Measured against our own geometry:
--     Greenwood Village city (G4110/0833035) is 100.0% inside State Senate District 26
--     (G5210/08026) -- ST_Intersects true, area ratio 1.000.
-- ⚠ CONTROL, RUN FIRST AND WATCHED TO FAIL: the same test against Pueblo city (0862000),
-- Fort Collins city (0827425) and Grand Junction city (0831660) returns FALSE at 0.0% for
-- all three. The test discriminates; it is not answering "true" to everything. (Cherry Hills
-- Village also returns 100%, which is correct -- SD-26 contains more than one municipality.)
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ ONE SOURCE WAS AUTHORITATIVE FOR THE IDENTITY AND STALE FOR A ROLE, AND IT NEARLY GOT USED.
-- The Colorado Sun's April 2025 Bridges story calls him "chair of the legislature's Joint
-- Budget Committee", and chair of the JBC is a singleton role -- it looked like a second
-- identity key. leg.colorado.gov TODAY lists him as "Vice Chair Joint Budget Committee". The
-- JBC chairship rotates between the chambers annually, so that field was true when written
-- and is false now. It is deliberately NOT part of the evidence here. The DISTRICT is, because
-- a district number does not rotate.
--
-- ▶ WHAT EACH LINK CARRIES BEYOND A PHOTOGRAPH, stated because CC_0262 made it the rule:
--   * Phil Weiser holds 20 compass answers -- 17 in CLOSED Season 1, 3 in OPEN Season 2 (2 of
--     those 3 are blanks, value = 0). Both seasons are PUBLISHED; none are draft. Linking
--     makes 18 non-blank positions reachable from the Governor race page.
--   * Jena Griswold holds 6, all in closed Season 1, all non-blank, all published. They become
--     reachable from the Attorney General race page.
--   * Jeff Bridges holds 0. His link changes a photograph and nothing else.
-- No answer, context or evidence row is created, altered or moved by this migration.
--
-- ▶ PHOTOGRAPHS. All three candidacy rows have photo_url IS NULL, so there is nothing to clear
-- and the COALESCE(rc.photo_url, pi.url) in electionService falls straight through to each
-- politician's default image. All three images live in our own storage (nothing hotlinked),
-- all three were re-fetched and face-checked for this migration, and all three pass at
-- rotation 0: Bridges 0.955, Weiser 0.946, Griswold 0.920. A blank 600x750 control scored
-- 0.000 at every rotation, so the detector was failing correctly when those numbers were read.
--
-- 🔴 BUT THE FACE GATE IS NOT A COMPOSITION GATE, AND GRISWOLD'S PHOTOGRAPH IS A DEFECT.
-- Her 600x750 is a mid-speech press photo: near-profile, mouth open, eyes off camera, a
-- microphone across the lower left of the frame. It scores 0.920 and every automated check we
-- own passes it. Looking at it is what caught it. It is NOT changed here, for two reasons:
-- it already renders on her profile page, so this migration extends its reach rather than
-- introducing it; and a photograph swap rests on different evidence from an identity link and
-- should be revertible separately. Recorded as owed, with the sourcing already done:
--   * The Colorado SOS biography page carries the correct official portrait, alt="Jena
--     Griswold", https://www.coloradosos.gov/pubs/images/Griswold.png -- front-facing, eyes to
--     camera, scores 0.948. It is 250x376. Cropping it to our 600x750 is a 2.4x UPSCALE, which
--     is the defect CC_0261 refused to create. No larger copy exists on that host (@2x, Large,
--     _large and .jpg variants all 404).
--   * Wikimedia Commons holds three Jeffrey Beall photographs (CC BY 4.0). The 1409x2050
--     "(cropped)" file is the source of the picture we already publish. "Jena Griswold 2024"
--     is 3227x2553 and is a PrideFest parade group shot -- t-shirt, baseball cap, umbrella,
--     several faces. It scores 0.933, which is a clean demonstration that a high face score
--     says nothing about whether the frame is a portrait or who is in it.
--   The honest options are therefore (a) publish the official portrait upscaled 2.4x, or
--   (b) keep the sharp wrong-composition frame. That is an operator call, not a migration's.
--
-- ▶ NOT DONE HERE: occupational_designation stays NULL on all three. Colorado does not print
-- a ballot designation -- that is the whole finding of CC_0265 -- so there is nothing to put
-- in it. The column is not a place to write a fact the state did not publish.
-- ▶ NOT DONE HERE: Kevin Grantham (Treasurer) is a former Colorado Senate President now
-- serving as a Fremont County Commissioner. He is the next plausible link in these three
-- races and he has no citation yet, so he stays unlinked.
--
-- Idempotent: re-running changes nothing.

BEGIN;

CREATE TEMP TABLE _link (
  rc_id        uuid PRIMARY KEY,
  name_like    text NOT NULL,
  pol_id       uuid NOT NULL,
  pol_name     text NOT NULL,
  office_id    uuid NOT NULL,   -- the seat the CITATION names; the link's premise
  office_desc  text NOT NULL,
  seeks        text NOT NULL
) ON COMMIT DROP;

INSERT INTO _link VALUES
  ('7a64fd31-482c-45a1-9409-7971fa20c615'::uuid, 'Jena Griswold',
   '31667cca-d1c9-43f5-bc82-45312793aad0'::uuid, 'Jena Griswold',
   'fe7d477f-2762-43ce-a615-c5bf52cbdfe5'::uuid, 'Colorado Secretary of State',
   'Colorado Attorney General'),
  ('094d2cfc-7063-467a-ad8b-5d642d334ec8'::uuid, 'Phil Weiser',
   '5bad420d-17de-48ec-94ef-14b901c0ed1d'::uuid, 'Phil Weiser',
   '4fa59236-cdcf-452d-b4b8-c99cc379fc40'::uuid, 'Colorado Attorney General',
   'Colorado Governor'),
  ('1c1f3903-4dbe-4bc9-afeb-aa1634324aee'::uuid, 'Jeff Bridges',
   'cb0906d5-b6d5-495c-9af0-335a8ad72920'::uuid, 'Jeff Bridges',
   '8ecafd9d-a5b5-4e0a-bb0e-95a654051a48'::uuid, 'State Senate District 26',
   'Colorado Treasurer');

-- ── Guards. Every one of these is a fact the citation rests on. If any has moved, the
-- reasoning in the header no longer describes the database and the migration REFUSES.
DO $$
DECLARE r record; v text; v_pid uuid; v_active bool; v_imgs int; v_namesakes int;
        v_seeks text;
BEGIN
  FOR r IN SELECT * FROM _link LOOP

    -- 1. the politician exists, is named as cited, and is active
    SELECT p.full_name, p.is_active INTO v, v_active
      FROM essentials.politicians p WHERE p.id = r.pol_id;
    IF v IS NULL THEN
      RAISE EXCEPTION 'CC_0266: politician % does not exist', r.pol_id;
    END IF;
    IF v <> r.pol_name THEN
      RAISE EXCEPTION 'CC_0266: politician % is "%", expected "%"', r.pol_id, v, r.pol_name;
    END IF;
    IF NOT v_active THEN
      RAISE EXCEPTION 'CC_0266: % is not active - refusing to link a candidacy to them', v;
    END IF;

    -- 2. 🔴 THE PREMISE. They must still HOLD the seat the citation names. Read office-rooted
    -- (och has exactly one row per office, guaranteed); the politician-rooted direction can
    -- fan out and is the wrong question here anyway.
    SELECT och.politician_id INTO v_pid
      FROM essentials.office_current_holder och WHERE och.office_id = r.office_id;
    IF v_pid IS DISTINCT FROM r.pol_id THEN
      RAISE EXCEPTION 'CC_0266: % no longer holds % (office %) - holder is now % - the fact '
                      'the citation rests on is gone, REFUSING',
                      r.pol_name, r.office_desc, r.office_id, coalesce(v_pid::text, 'nobody');
    END IF;

    -- 3. exactly one active namesake, or the name stops identifying anyone
    SELECT count(*) INTO v_namesakes FROM essentials.politicians p
     WHERE p.is_active AND p.full_name = r.pol_name;
    IF v_namesakes <> 1 THEN
      RAISE EXCEPTION 'CC_0266: % active politician rows are named "%" - expected 1, REFUSING',
                      v_namesakes, r.pol_name;
    END IF;

    -- 4. exactly one default image, or the ballot page inherits an ambiguous photo
    SELECT count(*) INTO v_imgs FROM essentials.politician_images pi
     WHERE pi.politician_id = r.pol_id AND pi.type = 'default';
    IF v_imgs <> 1 THEN
      RAISE EXCEPTION 'CC_0266: % has % default images, expected 1', r.pol_name, v_imgs;
    END IF;

    -- 5. the candidacy row is the one researched, seeks the office cited, and is unlinked
    SELECT rc.full_name, rc.politician_id, ra.position_name
      INTO v, v_pid, v_seeks
      FROM essentials.race_candidates rc
      JOIN essentials.races ra ON ra.id = rc.race_id
     WHERE rc.id = r.rc_id;
    IF v IS NULL THEN
      RAISE EXCEPTION 'CC_0266: race_candidates row % does not exist', r.rc_id;
    END IF;
    IF v <> r.name_like THEN
      RAISE EXCEPTION 'CC_0266: row % is "%", expected "%"', r.rc_id, v, r.name_like;
    END IF;
    IF v_seeks IS DISTINCT FROM r.seeks THEN
      RAISE EXCEPTION 'CC_0266: row % seeks "%", expected "%" - the citation was read against '
                      'the other race, REFUSING', r.rc_id, v_seeks, r.seeks;
    END IF;
    IF v_pid IS NOT NULL AND v_pid <> r.pol_id THEN
      RAISE EXCEPTION 'CC_0266: row % is already linked to %, REFUSING to repoint it',
                      r.rc_id, v_pid;
    END IF;

  END LOOP;
END $$;

-- ── The link.
UPDATE essentials.race_candidates rc
SET politician_id = l.pol_id
FROM _link l
WHERE rc.id = l.rc_id
  AND rc.politician_id IS DISTINCT FROM l.pol_id;

-- ── post-verify
DO $$
DECLARE n_linked int; n_render int; n_other int; n_offsite int; n_wrong int;
BEGIN
  SELECT count(*) INTO n_linked
    FROM essentials.race_candidates rc JOIN _link l ON l.rc_id = rc.id
   WHERE rc.politician_id = l.pol_id;
  IF n_linked <> 3 THEN
    RAISE EXCEPTION 'CC_0266: expected 3 linked candidacy rows, found %', n_linked;
  END IF;

  -- each ballot page must now actually SERVE a photograph, computed the way
  -- electionService computes it: COALESCE(rc.photo_url, pi.url)
  SELECT count(*) INTO n_render
    FROM essentials.race_candidates rc
    JOIN _link l ON l.rc_id = rc.id
    LEFT JOIN LATERAL (
      SELECT pi.url FROM essentials.politician_images pi
       WHERE pi.politician_id = rc.politician_id AND pi.type = 'default' LIMIT 1
    ) pi ON rc.politician_id IS NOT NULL
   WHERE NULLIF(COALESCE(rc.photo_url, pi.url), '') IS NOT NULL;
  IF n_render <> 3 THEN
    RAISE EXCEPTION 'CC_0266: expected 3 ballot pages to serve a photograph, found %', n_render;
  END IF;

  -- no OTHER candidacy row may have attached itself to these three people
  SELECT count(*) INTO n_other FROM essentials.race_candidates rc
   WHERE rc.politician_id IN (SELECT pol_id FROM _link)
     AND rc.id NOT IN (SELECT rc_id FROM _link);
  IF n_other <> 0 THEN
    RAISE EXCEPTION 'CC_0266: % unexpected candidacy row(s) now point at these politicians',
                    n_other;
  END IF;

  -- the two cross-state wrong-person matches CC_0265 identified must STAY unlinked. They are
  -- the reason "exactly one active namesake" is a filter and not a licence.
  SELECT count(*) INTO n_wrong FROM essentials.race_candidates rc
   WHERE rc.full_name IN ('Cheryl Williams', 'Amanda Campbell')
     AND rc.politician_id IS NOT NULL;
  IF n_wrong <> 0 THEN
    RAISE EXCEPTION 'CC_0266: % confirmed wrong-person row(s) got linked', n_wrong;
  END IF;

  -- CC_0261's property still holds: nothing we publish renders from an outside host
  SELECT count(*) INTO n_offsite FROM essentials.race_candidates rc
   WHERE NULLIF(rc.photo_url, '') IS NOT NULL
     AND rc.result IS DISTINCT FROM 'not_nominated'
     AND rc.photo_url NOT LIKE '%supabase.co/storage/v1/object/public/%';
  IF n_offsite <> 0 THEN
    RAISE EXCEPTION 'CC_0266: % live ballot row(s) render off-site', n_offsite;
  END IF;

  RAISE NOTICE 'CC_0266 OK - Griswold, Weiser and Bridges linked; all three ballot pages '
               'serve a photograph';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE: WHEN THE DOCUMENT THE STANDARD WANTS DOES NOT EXIST, ASK WHAT THE DOCUMENT WAS
-- DOING. California's ballot designation worked because it named a seat with ONE occupant.
-- Colorado prints no designation, but a Colorado source naming "Colorado Attorney General
-- Phil Weiser" does the same job for the same reason. The standard is not the form; it is the
-- singleton office. That is also exactly why Sonja Shaw failed it -- "School District
-- President" names a KIND of seat, and there are hundreds.
-- ⚠ AND IT IS WHY A SECOND, BETTER-LOOKING KEY WAS DROPPED HERE: "chair of the Joint Budget
-- Committee" is a singleton too, but it ROTATES. A singleton that moves is not an identifier.
-- Prefer the one that cannot change -- the district number.
-- ⚠ THE FACE GATE IS NOT A COMPOSITION GATE. Griswold's microphone photo scores 0.920 and a
-- parade crowd scores 0.933. Both would ship. Looking is still the only check for what the
-- picture IS.
-- ───────────────────────────────────────────────────────────────────────────────────────────
