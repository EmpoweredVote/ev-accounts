-- CC_0279_san_bernardino_2026_general_candidate_people.sql
--
-- San Bernardino County 2026 General. Creates 3 politician rows and links them.
-- San Bernardino then reads 5 of 5, and **the candidate->person programme is complete**: every
-- cohort in every state has been examined.
--
--   CREATE  3   LINK  0   REFUSED  0
--
-- The whole election is one race: **Director, Wrightwood Community Services District**, five
-- candidates, two of them already linked (David E. Schoenwetter, Erin C. DeGroot).
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- ═══ 🔴 "100% DESIGNATED" IS NOT "INSTRUMENT A CAN RUN" ═══
-- The handoff scoped this cohort as "Smallest in the corpus and 100% designated. An hour's work
-- with instrument A." The first half is true and the second does not follow.
--
-- A ballot designation is only an instrument when it **names an office**. These three name none:
--     Jason Agraz  -> "Business Owner"
--     Russ Drew    -> "Retired / Community Volunteer"
--     Wes Zuber    -> "Local Businessman"
-- 🔴 So instrument A produces NO link here, and that is not a failure of the cohort -- it is the
-- designation doing its job. **A candidate who swears their occupation is "Retired / Community
-- Volunteer" is stating that they hold no office.** Same shape as Angela Taylor's "None." under
-- Elected Experience in CC_0277: a self-description disconfirms as readily as it confirms, and
-- three disconfirmations is why this migration links nobody.
-- ▶ COUNT DESIGNATIONS THAT NAME A SEAT, not designations. The former is the instrument.
--
-- ═══ 🔴 THE RACE'S office_id IS NOT EVIDENCE HERE, AND THE "SAME SEAT" TEST MUST NOT BE USED ═══
-- Wrightwood CSD has FIVE Director offices in our schema, each separately seated from the
-- district's own roster (CA_0250: Schoenwetter, DeGroot, Claiborne, Christensen, McFauls).
-- The single race row carries **five candidates against ONE of those five office ids**
-- (`25a12bc5`, currently Alexis Claiborne's).
-- ⚠ A board election for several seats is flattened onto one arbitrary seat row, so "the
-- candidate holds the very seat sought" -- the strongest test in this programme, and the one that
-- carried nine of Washington's twelve links -- is **meaningless in this race**. It would have
-- matched a candidate against whichever Director row the importer happened to pick.
-- ▶ Recorded in the handoff as a modelling question for whoever owns multi-seat races. It is not
-- fixed here, and nothing in this migration depends on which office the race points at.
--
-- ═══ THE DEDUPE PASS, AND ITS POSITIVE CONTROL ═══
-- 🔴 The pass returned EMPTY for all three names, and an empty answer from a detector is worth
-- nothing until the detector is shown to work. **Controls were planted and they fired**: the same
-- query matched "David Schoenwetter" -> `David E. Schoenwetter` and "Rick Christensen" ->
-- `Rick J. Christensen`, both sitting Wrightwood directors, including across the middle-initial
-- difference. The pass can find a Wrightwood director; it found none of these three.
--
-- A wider surname sweep over every politician row, active and archived, confirms it: we hold a
-- **Claudia** Agraz, a **Henry** Zuber III and a **Jefferson** Van Drew, and nothing closer. The
-- many `Drew *` rows are first-name Drews, and the `ZUBER 2018 GOVERNOR`-style rows are
-- CAL-ACCESS committee names, not people.
--
-- ▶ WHAT EACH ROW ASSERTS: existence, and nothing else. `is_active=true`,
-- **`is_incumbent=FALSE` named explicitly** (CA_0188), `external_id` NULL, `party` NULL
-- (antipartisan -- it lives on `races.primary_party`), and NO office_terms row. All five
-- Wrightwood Director seats are occupied and these three hold none of them.
-- 🔴 Seating any of them would call `seat_officeholder` on an OCCUPIED office, and that helper
-- CLOSES the predecessor's term -- the CC_0271 trap exactly. They are challengers.
--
-- ⚠ SAFE TO RE-RUN, BUT IT REFUSES RATHER THAN NO-OPS -- and the whole family of creation
-- migrations in this programme (CC_0272, CC_0275, CC_0276, CC_0278) behaves the same way while
-- their headers all say "Idempotent: re-running inserts nothing". That sentence is true about the
-- OUTCOME and wrong about the MECHANISM: the cohort is defined as `politician_id IS NULL`, so a
-- second run finds zero and the count gate raises `expected 3 to create, found 0`. Nothing is
-- inserted because the transaction ABORTS, not because the work is skipped.
-- 🔴 So a re-run looks like a FAILURE in any runner that reads exit codes. Measured here by
-- running this file twice in one transaction. Expect the exception; it is not drift.

BEGIN;

CREATE TEMP TABLE _new AS
WITH src AS (
  SELECT rc.id AS rc_id, rc.full_name,
         btrim(regexp_replace(rc.full_name, '\s*"[^"]*"\s*', ' ', 'g')) AS clean
  FROM essentials.race_candidates rc
  JOIN essentials.races r ON r.id = rc.race_id
  JOIN essentials.elections e ON e.id = r.election_id
  WHERE e.name = '2026 San Bernardino County General'
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
  IF n <> 3 THEN
    RAISE EXCEPTION 'CC_0279: expected 3 to create, found % - the cohort moved, re-run the '
                    'dedupe pass with its controls before writing', n;
  END IF;

  PERFORM 1 FROM _new WHERE full_name = 'Jason Agraz' AND first_name = 'Jason' AND last_name = 'Agraz';
  IF NOT FOUND THEN RAISE EXCEPTION 'CC_0279: Jason Agraz is not in the set as expected'; END IF;
  PERFORM 1 FROM _new WHERE full_name = 'Russ Drew' AND first_name = 'Russ' AND last_name = 'Drew';
  IF NOT FOUND THEN RAISE EXCEPTION 'CC_0279: Russ Drew is not in the set as expected'; END IF;
  PERFORM 1 FROM _new WHERE full_name = 'Wes Zuber' AND first_name = 'Wes' AND last_name = 'Zuber';
  IF NOT FOUND THEN RAISE EXCEPTION 'CC_0279: Wes Zuber is not in the set as expected'; END IF;

  SELECT count(*) INTO bad FROM _new
   WHERE coalesce(btrim(first_name),'')='' OR coalesce(btrim(last_name),'')='';
  IF bad > 0 THEN RAISE EXCEPTION 'CC_0279: % split to an empty name part', bad; END IF;

  -- no collisions against the TABLE, active or archived
  SELECT count(*) INTO bad FROM _new nw
   WHERE EXISTS (SELECT 1 FROM essentials.politicians p
                  WHERE (lower(p.first_name)=lower(nw.first_name)
                     AND lower(p.last_name)=lower(nw.last_name))
                     OR lower(p.full_name)=lower(nw.full_name));
  IF bad > 0 THEN
    RAISE EXCEPTION 'CC_0279: % of the 3 collide with an existing person - the pass measured '
                    'ZERO against a control that fired, so the data moved. REFUSING', bad;
  END IF;

  -- 🔴 and against the BATCH ITSELF. CC_0278 shipped this check after the pre-flight missed
  -- Julia Payne: comparing a batch with the table cannot see a name repeated inside the batch,
  -- because the first insert is what creates the collision for the second.
  SELECT count(*) INTO bad FROM (
    SELECT full_name FROM _new GROUP BY full_name HAVING count(*) > 1) q;
  IF bad > 0 THEN
    RAISE EXCEPTION 'CC_0279: % name(s) repeated within the batch - read them before inserting', bad;
  END IF;
END $$;

DO $$
DECLARE r record; v_id uuid;
BEGIN
  FOR r IN SELECT * FROM _new ORDER BY full_name LOOP
    INSERT INTO essentials.politicians (full_name, first_name, last_name,
                                        is_active, is_incumbent, source)
    VALUES (r.full_name, r.first_name, r.last_name, true, false,
            'san-bernardino-2026-general CC_0279 (certified candidate list; no office asserted)')
    RETURNING id INTO v_id;
    UPDATE _new SET new_id = v_id WHERE rc_id = r.rc_id;
  END LOOP;
END $$;

UPDATE essentials.race_candidates rc
SET politician_id = nw.new_id
FROM _new nw
WHERE rc.id = nw.rc_id AND nw.new_id IS NOT NULL AND rc.politician_id IS NULL;

DO $$
DECLARE n_make int; n_left int; n_bad int; n_terms int; n_seats int;
BEGIN
  SELECT count(*) INTO n_make FROM essentials.race_candidates rc
    JOIN _new nw ON nw.rc_id = rc.id WHERE rc.politician_id = nw.new_id;
  IF n_make <> 3 THEN RAISE EXCEPTION 'CC_0279: expected 3 created+linked, found %', n_make; END IF;

  SELECT count(*) INTO n_bad FROM _new nw JOIN essentials.politicians p ON p.id = nw.new_id
   WHERE p.is_incumbent IS DISTINCT FROM false OR p.is_active IS DISTINCT FROM true
      OR p.external_id IS NOT NULL OR p.party IS NOT NULL;
  IF n_bad <> 0 THEN RAISE EXCEPTION 'CC_0279: % new row(s) assert more than existence', n_bad; END IF;

  SELECT count(*) INTO n_terms FROM essentials.office_terms ot
    JOIN _new nw ON nw.new_id = ot.politician_id;
  IF n_terms <> 0 THEN RAISE EXCEPTION 'CC_0279: % new person(s) hold an office term', n_terms; END IF;

  -- 🔴 the Wrightwood board must be untouched: five Director seats, five sitting holders, none
  -- of them created here. Creating a challenger must never disturb an occupied seat.
  SELECT count(*) INTO n_seats
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.geo_id = 'ca-spd-wrightwood-csd' AND d.mtfcc = 'X-CA-SPD'
     AND och.politician_id IS NOT NULL;
  IF n_seats <> 5 THEN
    RAISE EXCEPTION 'CC_0279: Wrightwood CSD should still have 5 seated Directors, found %', n_seats;
  END IF;

  SELECT count(*) INTO n_left FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.name = '2026 San Bernardino County General' AND rc.politician_id IS NULL;
  IF n_left <> 0 THEN RAISE EXCEPTION 'CC_0279: % rows still unlinked, expected 0', n_left; END IF;

  RAISE NOTICE 'CC_0279 OK - 3 created and linked; San Bernardino fully linked';
END $$;

DROP TABLE _new;
COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE THIS LAST COHORT ADDS: COUNT THE INSTRUMENT, NOT THE FIELD.
-- This cohort was scoped as "100% designated -- an hour with instrument A", and it is 100%
-- designated. Not one designation names an office, so instrument A yields nothing and all three
-- rows are creations. "Has a designation" and "the designation names a seat we record" are
-- different measurements, and only the second is a lead worth an hour.
-- 🟢 THE CONSOLATION IS THAT THE DESIGNATION STILL EARNED ITS KEEP -- as a DISCONFIRMATION.
-- "Retired / Community Volunteer" is a candidate saying they hold no office, which is why
-- creating all three is the evidenced answer rather than the fallback.
-- ───────────────────────────────────────────────────────────────────────────────────────────
