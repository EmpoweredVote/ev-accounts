-- CC_0160 — KS-3 occupancy: seat Wichita's mayor and six council members.
--
-- SEVEN INSERTS, ZERO REUSES. The duplicate-name check was run with the guard's OWN predicate —
-- `is_active`, and the lower(btrim(first_name)) / lower(btrim(last_name)) PAIR — and all seven
-- return zero active matches. 🟢 The predicate was proved able to find people BEFORE the zeros were
-- believed: `Daniel Elliott` returns 2 (the namesake KY-2 recorded), `Patrick Schmidt` 1,
-- `Ty Masterson` 1, an impossible name 0. ▶ This is the opposite of KS-2, where 4 of 165 already
-- existed and needed the UPDATE path.
-- ⚠ `J.V. Johnston` was checked BOTH ways — `JV` and `J.V.` — because the guard lowercases and trims
-- but does NOT strip punctuation, and the city's own sources disagree: the minutes write "JV
-- Johnston", the member page and the GIS MEMBER field write "J.V. Johnston". Both returned 0. The
-- names inserted below come from ONE source, the member pages, never mixed with the other two.
--
-- 🔴 EVERY TERM START IS READ FROM A RECORD, NEVER COMPUTED. Three states have paid for a computed
-- oath date. Wichita held council meetings on January 6, 12, 13 AND 14 of 2026, so the calendar
-- alone picks the wrong one as easily as the right one.
--
-- 🔴🔴 AND THE PUBLISHED DATE FOR TUTTLE IS THE VOTE, NOT THE TERM — WRONG BY A WEEK. Every
-- secondary source says she was "appointed January 8, 2019". January 8 is the day the Council voted.
-- The motion itself appoints her "for a term commencing January 15, 2019", and the minutes of
-- January 15 record Judge Jones administering the oath to "new District II Council Member Becky
-- Tuttle", who appears in that meeting's attendance line and not the previous one. Two independent
-- confirmations. That is the Knight rule about certified results in its appointment form: a
-- SELECTION VOTE IS NOT A TERM START EITHER.
--
-- 🔴 THREE OF THE SEVEN HAVE BEEN SWORN MORE THAN ONCE, AND office_terms CARRIES CONTINUOUS
-- OCCUPANCY, so none of the later oaths is a term start:
--   * Tuttle, 2024-01-08 — "this is the THIRD time she has been sworn in"; Mayor Whipple the same
--     evening: "welcome BACK Council Member Tuttle", against "two NEW Council Members … JV Johnston
--     and Dalton Glasscock".
--   * Hoheisel and Ballard, 2026-01-12 — Mayor Wu: "our RE-SWORN-IN council members, Hoheisel and
--     Ballard and NEW council member, Shepard".
--   ⚠ The city marks incumbency differently at each ceremony — a parenthetical "(Incumbent)" beside
--   Brandon Johnson in 2022, a sentence from the chair in 2024, an adjective in 2026. There is no
--   field to read; it has to be read as prose, per ceremony.
--
-- PARTY IS LEFT NULL, DELIBERATELY. Wichita's council is elected "on a nonpartisan basis" (the
-- city's own council page), and this repo is antipartisan by design — party lives on
-- races.primary_party, never on a person.
--
-- 🔴 is_incumbent IS SET EXPLICITLY ON EVERY INSERT. It defaults to false, and a seated person
-- inserted without it is HIDDEN from address search while nothing errors. check:occupancy fails an
-- INSERT that omits it.
--
-- Idempotent: the inserts are guarded by NOT EXISTS and essentials.seat_officeholder is idempotent
-- by contract, so a second run writes nothing.

BEGIN;

-- ── Guard: the offices must exist ──────────────────────────────────────────────────────────────
DO $$
DECLARE v_offices int;
BEGIN
  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.city = 'Wichita' AND lower(d.state) = 'ks';
  IF v_offices <> 7 THEN
    RAISE EXCEPTION 'CC_0160: expected 7 Wichita offices, found %. Apply CC_0159 first.', v_offices;
  END IF;
END $$;

CREATE TEMP TABLE _ks3_roster (
  office_title    text PRIMARY KEY,
  first_name      text NOT NULL,
  last_name       text NOT NULL,
  term_start      date NOT NULL,
  how_started     text NOT NULL,
  source          text NOT NULL
) ON COMMIT DROP;

INSERT INTO _ks3_roster VALUES
 ('Mayor', 'Lily', 'Wu', DATE '2024-01-08', 'elected',
  'City of Wichita, CITY COUNCIL PROCEEDINGS January 8, 2024, item VI "Oath of Office Administered by Judge Roush for Mayor-Elect Lily Wu". Read 2026-09-27 (KS-3)'),
 ('Council Member, District 1', 'Joseph', 'Shepard', DATE '2026-01-12', 'elected',
  'City of Wichita, CITY COUNCIL PROCEEDINGS January 12, 2026 (Monday special meeting), item IV.1 "Oath of Office for District I Council Member Joseph Shepard", administered by Judge Jones. Succeeded Brandon Johnson. Read 2026-09-27 (KS-3)'),
 ('Council Member, District 2', 'Becky', 'Tuttle', DATE '2019-01-15', 'appointed',
  'City of Wichita, minutes of January 8, 2019: Council motion under Sec. 2.04.040 appointing Becky Tuttle "for a term commencing January 15, 2019", filling the unexpired term of Pete Meitzner; and minutes of January 15, 2019 recording Judge Jones administering the oath to "new District II Council Member Becky Tuttle". The widely published "January 8" is the VOTE date. Read 2026-09-27 (KS-3)'),
 ('Council Member, District 3', 'Mike', 'Hoheisel', DATE '2022-01-10', 'elected',
  'City of Wichita, minutes of January 10, 2022 (special session), "Oath of Office administered by Judge Jennifer Jones for newly elected Council Members: … Mike Hoheisel, District III". Read 2026-09-27 (KS-3)'),
 ('Council Member, District 4', 'Dalton', 'Glasscock', DATE '2024-01-08', 'elected',
  'City of Wichita, CITY COUNCIL PROCEEDINGS January 8, 2024, item VII.2 "Oath of Office for District IV Council Member Dalton Glasscock", administered by Judge Kehr. Read 2026-09-27 (KS-3)'),
 ('Council Member, District 5', 'J.V.', 'Johnston', DATE '2024-01-08', 'elected',
  'City of Wichita, CITY COUNCIL PROCEEDINGS January 8, 2024, item VII.3 "Oath of Office for District V Council Member JV Johnston", administered by Judge Kehr. Read 2026-09-27 (KS-3)'),
 ('Council Member, District 6', 'Maggie', 'Ballard', DATE '2022-01-10', 'elected',
  'City of Wichita, minutes of January 10, 2022 (special session), "Oath of Office administered by Judge Jennifer Jones for newly elected Council Members: … Maggie Ballard, District VI". Read 2026-09-27 (KS-3)');

-- ── The seven people ───────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.politicians (id, full_name, first_name, last_name, is_active, is_incumbent)
SELECT gen_random_uuid(), r.first_name || ' ' || r.last_name, r.first_name, r.last_name,
       true,   -- is_active
       true    -- 🔴 is_incumbent, explicit: they hold the seat
  FROM _ks3_roster r
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.politicians p
    WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
      AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
      AND p.is_active);

-- ── Seat them ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE r record; v_office uuid; v_pol uuid;
BEGIN
  FOR r IN SELECT * FROM _ks3_roster LOOP
    SELECT o.id INTO v_office
      FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.city = 'Wichita' AND lower(d.state) = 'ks' AND o.title = r.office_title;
    IF v_office IS NULL THEN RAISE EXCEPTION 'CC_0160: office "%" not found', r.office_title; END IF;

    SELECT p.id INTO v_pol FROM essentials.politicians p
     WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
       AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
       AND p.is_active;
    IF v_pol IS NULL THEN RAISE EXCEPTION 'CC_0160: politician % % not found', r.first_name, r.last_name; END IF;

    PERFORM essentials.seat_officeholder(v_office, v_pol, r.term_start, r.source, r.how_started, 'day');
  END LOOP;
END $$;

-- ── Post-verify. Asserts the END STATE, so a re-run that writes nothing still passes. ──────────
DO $$
DECLARE v_terms int; v_seated int; v_inc int; v_prec int; v_multi int; v_party int;
BEGIN
  SELECT count(*) INTO v_terms
    FROM essentials.office_terms t JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.city = 'Wichita' AND lower(d.state) = 'ks';
  IF v_terms <> 7 THEN RAISE EXCEPTION 'CC_0160: expected 7 office_terms, found %', v_terms; END IF;

  -- 🔴 COUNT och.politician_id, NEVER count(*). office_current_holder LEFT JOINs from offices, so a
  -- vacancy is a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.city = 'Wichita' AND lower(d.state) = 'ks';
  IF v_seated <> 7 THEN RAISE EXCEPTION 'CC_0160: expected 7 seated, found %', v_seated; END IF;

  SELECT count(*) INTO v_inc
    FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE d.city = 'Wichita' AND lower(d.state) = 'ks' AND (NOT p.is_incumbent OR NOT p.is_active);
  IF v_inc <> 0 THEN
    RAISE EXCEPTION 'CC_0160: % seated Wichita official(s) are not is_incumbent/is_active — they '
                    'would be hidden from address search', v_inc;
  END IF;

  SELECT count(*) INTO v_prec
    FROM essentials.office_terms t JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.city = 'Wichita' AND lower(d.state) = 'ks' AND t.start_precision <> 'day';
  IF v_prec <> 0 THEN RAISE EXCEPTION 'CC_0160: % term(s) are not day precision', v_prec; END IF;

  SELECT count(*) INTO v_multi FROM (
    SELECT och.politician_id
      FROM essentials.office_current_holder och
      JOIN essentials.offices o ON o.id = och.office_id
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.city = 'Wichita' AND lower(d.state) = 'ks' AND och.politician_id IS NOT NULL
     GROUP BY och.politician_id HAVING count(*) > 1) t;
  IF v_multi <> 0 THEN
    RAISE EXCEPTION 'CC_0160: % person(s) hold more than one Wichita seat. The Vice Mayor is a '
                    'rotation among the six, not a seat.', v_multi;
  END IF;

  -- Nonpartisan by charter, antipartisan by design: nobody here carries a party.
  SELECT count(*) INTO v_party
    FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE d.city = 'Wichita' AND lower(d.state) = 'ks' AND p.party IS NOT NULL;
  IF v_party <> 0 THEN RAISE EXCEPTION 'CC_0160: % Wichita official(s) carry a party', v_party; END IF;

  RAISE NOTICE 'CC_0160 OK — 7 Wichita officials seated, 7 terms, all day precision, none holding two seats.';
END $$;

COMMIT;
