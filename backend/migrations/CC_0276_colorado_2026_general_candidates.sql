-- CC_0276_colorado_2026_general_candidates.sql
--
-- Colorado 2026 General. 72 unlinked rows in. Colorado then reads 103 of 103.
--
--   LINK  1   CREATE  71   REFUSED (wrong person)  2
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- ═══ THE ONE LINK, AND THE INSTRUMENT THAT MADE IT ═══
--
-- 🔴 COLORADO HAS NO BALLOT DESIGNATION AND NO PRIMARY IN OUR DATA. Instrument A cannot run
-- (measured: zero designations on every CO row). Instrument B cannot run either -- we hold ONE
-- Colorado election, the general; there is no primary row anywhere in `elections` for this state,
-- so no `result = 'advanced'` exists to carry continuity forward. Both of the programme's
-- standing instruments are unavailable here.
--
-- ▶ So this link rests on the THIRD shape, the one CC_0266 established for Colorado: a document
-- that names a SINGLETON OFFICE we independently record the person holding.
--
--   MICHAEL J. ALLEN -- seeking Attorney General -> `daae06aa` "Michael Allen",
--   **District Attorney, El Paso County, CO**, term_start 2021-01-12, source
--   elpasoco.com/elected-officials.
--
--   The document is the candidate's OWN campaign site, michaelallenforcolorado.com, titled
--   "Michael Allen for Colorado Attorney General", which states verbatim:
--     "Elected District Attorney in the Fourth Judicial District (El Paso and Teller counties)
--      in 2020 and re-elected in 2024."
--   Corroborated by Colorado Politics' 2026-10-02 candidate questionnaire (printed under
--   "Name: Michael J. Allen / Office Sought: Attorney General"), in which he describes himself as
--   "the elected District Attorney of Colorado's largest judicial district", and by CPR News
--   2026-06-30, headlined "El Paso County prosecutor Michael Allen wins Republican attorney
--   general primary".
--
--   🟢 WHY THAT CLEARS THE BAR: the Fourth Judicial District has exactly one District Attorney,
--   so the phrase identifies a single living person rather than a KIND of seat. This is the
--   distinction that failed Sonja Shaw at first -- "School District President" names hundreds of
--   seats -- and that passed Phil Weiser in CC_0266. ⚠ And it is a singleton that does NOT move:
--   unlike "chair of the Joint Budget Committee", the DA of a numbered judicial district cannot
--   rotate annually.
--   🟢 THE DATES AGREE INDEPENDENTLY: elected 2020, so took office January 2021; our term_start
--   is 2021-01-12, written from the county's own elected-officials page months before this
--   campaign site was read. Neither source was derived from the other.
--
-- ═══ 🔴 TWO REFUSED -- BOTH CROSS-STATE, AND BOTH CREATED AS SEPARATE PEOPLE ═══
--
--   AMANDA CAMPBELL -- seeking CO Secretary of State -- matches `65bcc688` "Amanda Campbell",
--     **Board Member Place 5, Allen Independent School District, TEXAS**. Already named as a
--     confirmed different person in the handoff's wrong-person table; it is restated here because
--     she is still sitting in the cohort and this is the migration that disposes of her.
--     The Colorado Amanda Campbell is an American Constitution Party candidate who has run for
--     this same office before -- she appears in the Colorado Secretary of State's own historical
--     election data for 2022 -- and is reported as living in Grand Junction, Mesa County. A Mesa
--     County minor-party candidate is not a sitting Texas school trustee.
--   TRAVIS STAR NELSON -- seeking CO Senate 35 -- matches `0f7439ad` "Travis Nelson",
--     **State Representative, House District 44, OREGON**, is_incumbent true, carrying a PHOTO.
--     A sitting Oregon legislator is not standing for a seat on Colorado's eastern plains, and a
--     wrong link here would publish an Oregon representative's face on a Colorado ballot page.
--
-- 🔴 BOTH ARE CREATED BELOW AS NEW PEOPLE, because "different person" is the finding -- leaving
-- them unlinked would assert that we could not tell, and we can.
--
-- ⚠ ONLY ONE OF THE TWO TRIPS THE DUPLICATE GUARD, AND THAT IS LUCK, NOT EVIDENCE.
-- The guard keys on (first_name, last_name). Amanda Campbell splits to ('Amanda','Campbell') and
-- collides. `Travis Star Nelson` splits to ('Travis Star','Nelson') and sails through -- the
-- middle name, not the adjudication, is what silences the guard. The guard did not agree with
-- this migration about Nelson; it simply never looked. This is the fifth blindness to add to the
-- handoff's four.
--
-- ═══ CREATED -- 71 ═══
-- Every remaining unlinked Colorado row. Not one has an existing counterpart under any of the
-- four blind spots: the dedupe pass was run on (last name + first initial) over ALL politicians
-- including archived rows, and again on first-and-last token of `full_name` to catch a differently
-- split name, an accent or a missing full stop. Three hits came back in total -- Allen, Campbell
-- and Nelson -- and all three are disposed of above.
--
--   U.S. Senator (5)   Blake Huber · Christopher Baum · Donald Willoughby · Ryan Apelbaum ·
--                      Will Powers
--   Governor (6)       Eric Mulder · Erik Underwood · Greg Lopez · Jeff Peckman ·
--                      Stephen T. Hamilton · Victor Marx
--   Lt Governor (7)    Frank Atwood · George Washington Markert · James K Treibert ·
--                      Lesley Dahlkemper · T.J. Cole · Taralyn Romero · Wayne Harlos
--   Sec of State (5)   Alex Astley · Amanda Campbell · Amanda Gonzalez · Celeste Landry ·
--                      James Wiley
--   Treasurer (3)      Jodie Barr · Kevin Grantham · Marilee Langner Sturgis
--   U.S. House (22)    CD1 Chad Humphrey · Critter Milton · John Wren · Kevin StClair ·
--                      Shimon Blau · Stephen Replin | CD2 Gaylon Kent | CD3 Clifton Brown ·
--                      Cory Robertson | CD4 Douglas Mangeris · Luis Galvan |
--                      CD5 Christopher Mitchell · Mark "Marky Jr" Elworth · Steven Fuller |
--                      CD6 Meredith Ryan · Patty McMahon · Samir Ezzeldin Witta |
--                      CD7 Dan "Kilo" Sallis · Joe Krzeczkowski · Lawrence Kyle Clark ·
--                      Susan Hall | CD8 Dave Wood
--   State House (15)   HD14 Sarah Emery | HD15 Doug Jones · Jeff K. Livingston · Pricella Tiegen |
--                      HD16 Isaac Contreras · Jill Haffley · John C Hjersman · Steph Vigil |
--                      HD17 John Michael Angle · Laura Martin · Sherrea Sterling |
--                      HD18 Adriana Cuva | HD21 Brenda Miller · Michelle Tweed |
--                      HD22 Michael Pierson | HD56 Amy L. Lunde
--   State Senate (7)   SD9 Terri Carver · William Delano Moses III | SD11 Janet Turner ·
--                      Levon Stilson | SD35 Duane L Gurule · Richard Graf · Travis Star Nelson
--
-- ⚠ SEVERAL OF THESE ARE SITTING OR FORMER OFFICEHOLDERS AND STILL GET A FRESH ROW, because we
-- hold no row for them to link to. Amanda Gonzalez is the Jefferson County Clerk and Recorder;
-- Lesley Dahlkemper is a Jefferson County Commissioner; Kevin Grantham is a Fremont County
-- Commissioner; Steph Vigil and Terri Carver are former state representatives; Greg Lopez is a
-- former U.S. Representative. 🔴 WE SEED NO JEFFERSON COUNTY AND NO FREMONT COUNTY AT ALL --
-- `districts` holds zero rows matching 'Jefferson County' in CO -- so there is nothing to join to
-- and nothing was missed. Colorado's seeded occupancy is the legislature, the statewide
-- executives and El Paso County, which is exactly why Michael Allen was the only link available.
-- ▶ THIS IS AN OCCUPANCY GAP, NOT A LINKING DEFECT, and it is recorded in the handoff rather than
-- fixed here. A person created here holds nothing and claims nothing; if the county is seeded
-- later, these rows are the people to seat, not rows to duplicate.
--
-- 🔴 NONE OF THESE 71 ROWS GETS AN office_terms ROW AND NONE IS is_incumbent. A candidate list
-- dates the SCRAPE, not the seat (CC_0271's correction). Creating a person is an assertion that
-- they exist and are standing; it is not an assertion that they hold anything.
--
-- ⚠ `candidate_status` IS LEFT EXACTLY AS THE SOURCE WROTE IT. 10 of these rows read 'filed'
-- rather than 'active'. They came from the same Secretary of State document on the same day as
-- the 'active' rows and every affected race contains both statuses, so the distinction is the
-- source's own and our importer carried it faithfully. Whether a 'filed' candidate should appear
-- on a ballot page beside an 'active' one is a DISPLAY decision for the operator; it is not a
-- reason to withhold a person record, and this migration does not touch those fields.
--
-- Idempotent: re-running links nothing new and inserts nothing.

BEGIN;

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- PART 1 -- the single evidenced link
-- ═══════════════════════════════════════════════════════════════════════════════════════════

CREATE TEMP TABLE _link (rc_id uuid PRIMARY KEY, cand text NOT NULL, pol_id uuid NOT NULL)
  ON COMMIT DROP;
INSERT INTO _link VALUES
 ('e810ae66-c3ea-435d-a556-a4ca1a83eefa','Michael J. Allen','daae06aa-22ab-4e9d-958e-abd839c8ca93');

DO $$
DECLARE r record; v text; v_pid uuid; v_act bool; n int;
BEGIN
  FOR r IN SELECT * FROM _link LOOP
    SELECT p.full_name, p.is_active INTO v, v_act
      FROM essentials.politicians p WHERE p.id = r.pol_id;
    IF v IS NULL THEN RAISE EXCEPTION 'CC_0276: politician % missing', r.pol_id; END IF;
    IF NOT v_act THEN
      RAISE EXCEPTION 'CC_0276: % is ARCHIVED - linking would resurrect a retired row', v;
    END IF;

    -- 🔴 the evidence is the SEAT, so assert the seat, not the name. If this person is no longer
    -- the El Paso County District Attorney the singleton argument has evaporated and the link
    -- must be re-derived, not re-applied.
    SELECT count(*) INTO n
      FROM essentials.office_terms t
      JOIN essentials.offices o  ON o.id = t.office_id
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE t.politician_id = r.pol_id
       AND o.title = 'District Attorney' AND d.label = 'El Paso County' AND lower(d.state) = 'co';
    IF n <> 1 THEN
      RAISE EXCEPTION 'CC_0276: % does not hold exactly one El Paso County District Attorney '
                      'term (found %) - the singleton-office evidence no longer stands', v, n;
    END IF;

    SELECT rc.full_name, rc.politician_id INTO v, v_pid
      FROM essentials.race_candidates rc WHERE rc.id = r.rc_id;
    IF v IS DISTINCT FROM r.cand THEN
      RAISE EXCEPTION 'CC_0276: row % is "%", expected "%"', r.rc_id, v, r.cand;
    END IF;
    IF v_pid IS NOT NULL AND v_pid <> r.pol_id THEN
      RAISE EXCEPTION 'CC_0276: row % already linked to %', r.rc_id, v_pid;
    END IF;
  END LOOP;
END $$;

UPDATE essentials.race_candidates rc SET politician_id = l.pol_id
FROM _link l WHERE rc.id = l.rc_id AND rc.politician_id IS DISTINCT FROM l.pol_id;

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- PART 2 -- create the remaining 71
-- ═══════════════════════════════════════════════════════════════════════════════════════════

CREATE TEMP TABLE _new AS
WITH src AS (
  SELECT rc.id AS rc_id, rc.full_name,
         btrim(regexp_replace(rc.full_name, '\s*"[^"]*"\s*', ' ', 'g')) AS clean
  FROM essentials.race_candidates rc
  JOIN essentials.races r ON r.id = rc.race_id
  JOIN essentials.elections e ON e.id = r.election_id
  WHERE e.state = 'CO' AND e.election_date >= current_date
    AND rc.politician_id IS NULL
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
BEGIN
  SELECT count(*) INTO n FROM _new;
  IF n <> 71 THEN
    RAISE EXCEPTION 'CC_0276: expected 71 to create, found % - either part 1 did not link Allen '
                    'or the cohort moved. Re-run the dedupe pass before writing', n;
  END IF;

  SELECT count(*) INTO bad FROM _new
   WHERE coalesce(btrim(first_name),'')='' OR coalesce(btrim(last_name),'')='';
  IF bad > 0 THEN RAISE EXCEPTION 'CC_0276: % split to an empty name part', bad; END IF;

  -- 🔴 the quoted nicknames must be gone from the SPLIT and kept in full_name. Two rows carry
  -- one; without stripping, first_name would be a string no other row can ever equal, silently
  -- exempting them from the duplicate guard.
  PERFORM 1 FROM _new WHERE full_name = 'Mark "Marky Jr" Elworth'
                        AND first_name = 'Mark' AND last_name = 'Elworth';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CC_0276: the quoted nickname was not stripped from Elworth''s split';
  END IF;
  PERFORM 1 FROM _new WHERE full_name = 'Dan "Kilo" Sallis'
                        AND first_name = 'Dan' AND last_name = 'Sallis';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CC_0276: the quoted nickname was not stripped from Sallis''s split';
  END IF;
  -- and the generational suffix must leave last_name while staying in full_name
  PERFORM 1 FROM _new WHERE full_name = 'William Delano Moses III' AND last_name = 'Moses';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CC_0276: the generational suffix handling changed';
  END IF;

  -- 🔴 exactly ONE adjudicated collision is expected. More than one means a name arrived that
  -- nobody read, and an unread collision is how a wrong person gets created or merged.
  SELECT count(*) INTO bad FROM _new nw
   WHERE EXISTS (SELECT 1 FROM essentials.politicians p
                  WHERE (lower(p.first_name)=lower(nw.first_name)
                     AND lower(p.last_name)=lower(nw.last_name))
                     OR lower(p.full_name)=lower(nw.full_name));
  IF bad <> 1 THEN
    RAISE EXCEPTION 'CC_0276: expected exactly 1 adjudicated name collision (Amanda Campbell), '
                    'found % - REFUSING until each is read', bad;
  END IF;
  PERFORM 1 FROM _new WHERE full_name = 'Amanda Campbell';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CC_0276: the one expected collision is not Amanda Campbell';
  END IF;
END $$;

DO $$
DECLARE r record; v_id uuid;
BEGIN
  FOR r IN SELECT * FROM _new ORDER BY full_name LOOP
    -- 🔴 the escape hatch is opened for ONE statement and closed immediately. Amanda Campbell of
    -- Mesa County, Colorado is a different human from Amanda Campbell of the Allen ISD board in
    -- Texas; the guard cannot know that, so it is told once, by name, and re-armed.
    IF r.full_name = 'Amanda Campbell' THEN
      PERFORM set_config('essentials.allow_duplicate_name', 'on', true);
    END IF;

    INSERT INTO essentials.politicians (full_name, first_name, last_name,
                                        is_active, is_incumbent, source)
    VALUES (r.full_name, r.first_name, r.last_name, true, false,
            'co-2026-general CC_0276 (certified candidate list; no office asserted)')
    RETURNING id INTO v_id;

    PERFORM set_config('essentials.allow_duplicate_name', 'off', true);
    UPDATE _new SET new_id = v_id WHERE rc_id = r.rc_id;
  END LOOP;
END $$;

UPDATE essentials.race_candidates rc
SET politician_id = nw.new_id
FROM _new nw
WHERE rc.id = nw.rc_id AND nw.new_id IS NOT NULL AND rc.politician_id IS NULL;

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- POST-VERIFY
-- ═══════════════════════════════════════════════════════════════════════════════════════════

DO $$
DECLARE n_link int; n_make int; n_left int; n_bad int; n_terms int; v_hatch text;
BEGIN
  SELECT count(*) INTO n_link FROM essentials.race_candidates rc
    JOIN _link l ON l.rc_id = rc.id WHERE rc.politician_id = l.pol_id;
  IF n_link <> 1 THEN RAISE EXCEPTION 'CC_0276: expected 1 linked, found %', n_link; END IF;

  SELECT count(*) INTO n_make FROM essentials.race_candidates rc
    JOIN _new nw ON nw.rc_id = rc.id WHERE rc.politician_id = nw.new_id;
  IF n_make <> 71 THEN RAISE EXCEPTION 'CC_0276: expected 71 created+linked, found %', n_make; END IF;

  SELECT count(*) INTO n_bad FROM _new nw JOIN essentials.politicians p ON p.id = nw.new_id
   WHERE p.is_incumbent IS DISTINCT FROM false OR p.is_active IS DISTINCT FROM true
      OR p.external_id IS NOT NULL OR p.party IS NOT NULL;
  IF n_bad <> 0 THEN RAISE EXCEPTION 'CC_0276: % new row(s) assert more than existence', n_bad; END IF;

  SELECT count(*) INTO n_terms FROM essentials.office_terms ot
    JOIN _new nw ON nw.new_id = ot.politician_id;
  IF n_terms <> 0 THEN RAISE EXCEPTION 'CC_0276: % new person(s) hold an office term', n_terms; END IF;

  -- 🔴 the guard must be ARMED when this migration ends. A hatch left open is invisible and
  -- outlives the statement that needed it.
  v_hatch := current_setting('essentials.allow_duplicate_name', true);
  IF v_hatch IS NOT NULL AND lower(v_hatch) = 'on' THEN
    RAISE EXCEPTION 'CC_0276: the duplicate-name escape hatch was left OPEN';
  END IF;

  -- 🟢 Colorado must now be complete
  SELECT count(*) INTO n_left FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.state = 'CO' AND e.election_date >= current_date AND rc.politician_id IS NULL;
  IF n_left <> 0 THEN RAISE EXCEPTION 'CC_0276: % CO rows still unlinked, expected 0', n_left; END IF;

  RAISE NOTICE 'CC_0276 OK - 1 linked, 71 created and linked; Colorado fully linked';
END $$;

DROP TABLE _new;
COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE THIS COHORT ADDS: WHEN BOTH INSTRUMENTS ARE UNAVAILABLE, ASK WHAT THE INSTRUMENT
-- WAS DOING. Colorado has no ballot designation and -- unlike Washington -- no primary rows at
-- all, so neither standing instrument could run. The designation worked because it named a seat
-- with ONE occupant. A candidate's own campaign site naming the judicial district he is the
-- elected District Attorney of does the same job for the same reason. The standard is the
-- SINGLETON OFFICE, not the form it arrives on.
-- ⚠ AND THE OTHER 71 ARE NOT A FAILURE OF THAT STANDARD. Colorado seeds its legislature, its
-- statewide executives and El Paso County; it seeds no other county. Five of these candidates
-- hold or have held real office and still get a new row, because there is no row to link them to.
-- A missing link is sometimes an occupancy gap wearing a linking defect's clothes -- check which
-- before concluding the evidence is thin.
-- ───────────────────────────────────────────────────────────────────────────────────────────
