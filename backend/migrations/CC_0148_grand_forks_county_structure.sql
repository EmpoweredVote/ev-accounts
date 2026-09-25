-- CC_0148_grand_forks_county_structure.sql
-- Knight Foundation program, wave ND-4 (structure half). Slot RESERVED from the allocator.
--
-- Creates Grand Forks County and its SEVEN elected offices:
--
--   1 government   Grand Forks County, North Dakota, US        (geo_id 38035)
--   3 chambers     Grand Forks County Commission (5) · Sheriff (1) · State's Attorney (1)
--   0 districts    ← NONE ARE CREATED. Every seat is countywide on the EXISTING COUNTY district.
--   7 offices      5 Commissioners + Sheriff + State's Attorney
--
-- Creates NO people and NO terms — CC_0149 does that, and the two are applied back to back.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THIS WAVE LOADS NO GEOMETRY, AND THAT IS THE FINDING, NOT AN OMISSION.
--
-- Grand Forks County elects its commission AT LARGE. There are no commission districts to load and
-- none may be invented. Three independent sources agree:
--
--   1. THE CHARTER, art. 6 § 1, in a section titled "Offices to be Elected": "The Board of County
--      Commissioners shall consist of five members who shall be elected on a nonpartisan ballot.
--      All of the candidates seeking the office of county commissioner shall be VOTED UPON BY THE
--      QUALIFIED ELECTORS OF THE ENTIRE COUNTY."
--   2. The state's 2026 precinct layer sets `Commissioner1 = "Districts At-Large"` on all 37 Grand
--      Forks County precinct parts, with `Commissioner2`..`Commissioner5` null on every row.
--   3. The county's own Commissioners page lists five people titled bare "Commissioner", with no
--      district number.
--
-- All seven offices therefore hang on the COUNTY district `38035` (G4020), which has existed in
-- production since before this program and already carries geometry. The pre-flight asserts that.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 SEVEN OFFICES, NOT NINE — AND THE CHARTER SAYS SO POSITIVELY RATHER THAN BY SILENCE.
--
-- North Dakota's Secretary of State lists six elected county offices statewide: Commissioner,
-- Recorder, Sheriff, State's Attorney, Auditor and Treasurer — and warns that "some counties use an
-- appointment process for some contests, depending on their form of government."
--
-- Grand Forks County adopted a HOME RULE CHARTER in November 2022 — by EIGHTEEN VOTES after an
-- automatic recount, 8,386 to 8,368 — effective 2023-01-01. Its art. 6 § 1 "Offices to be Elected"
-- names exactly three things: the five at-large commissioners, and "The Sheriff and State's Attorney
-- [who] shall remain elected offices". Art. 7 then disposes of the rest positively:
--   § 1 "The Board of County Commissioners may, by ordinance, establish county departments, offices,
--       agencies, boards or commissions IN ADDITION TO THOSE OFFICES TO BE FILLED BY ELECTION…"
--   § 2 "The Board of County Commissioners MAY APPOINT DEPARTMENT HEADS and fix their compensation."
--
-- ▶ So the County Recorder (Garlynn Helmoski) and the County Auditor (Colleen Morstad) are appointed
--   department heads and are NOT seated. ⚠ There is no County Treasurer at all — the function sits
--   inside the Finance & Tax department; the only "Treasurer" in the county's staff directory is the
--   Secretary-Treasurer of the Water Resource District, a different body.
-- ⚠ This replaces an earlier reading based on those offices' ABSENCE from the 2022, 2024 and 2026
--   ballots. Absence is not proof — the charter's own section heading is.
--
-- 🔴 THE CHARTER PDF ALSO CONTAINS A MEASURE THE VOTERS REJECTED. Pages 1-7 are the charter, page 8
-- is the ballot question and signatures, and page 9 onward is an ADDENDUM enacting a half-cent county
-- sales tax — which FAILED, 9,013 to 8,984. Both are drafted in enacted voice ("We, the people …
-- hereby enact"); only the vote record distinguishes them. Nothing from the addendum is law.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 FIVE COMMISSIONER OFFICES SHARE ONE DISTRICT, exactly as ND-2's paired House seats do and for
-- the same reason: they are elected at large and the ballot does not number them. The offices are
-- therefore identical rows differing only by id, the count guard below is a COUNT and not a
-- NOT EXISTS, and CC_0149 pairs people to them by a deterministic slot that asserts nothing.
-- ▶ Any gate that reads "one office per district" is wrong here too.
--
-- 🔴 PARTY IS NOT WRITTEN. The charter makes the commission race expressly NONPARTISAN, and the SOS
-- says "all contests at the county level are non-partisan"; party lives on races.primary_party.
--
-- Idempotent: every INSERT is NOT EXISTS/count-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 0. Pre-flight: the county district must exist and must carry geometry ───

DO $$
DECLARE v_d int;
BEGIN
  SELECT count(*) INTO v_d
    FROM essentials.districts d
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc
   WHERE lower(d.state) = 'nd' AND d.geo_id = '38035' AND d.district_type::text = 'COUNTY';
  IF v_d <> 1 THEN
    RAISE EXCEPTION 'ND-4 pre-flight: expected exactly 1 Grand Forks County district (38035) with geometry, found %', v_d;
  END IF;
END $$;

-- ─── 1. Government ───────────────────────────────────────────────────────────

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'Grand Forks County, North Dakota, US', 'County', 'ND', NULL, '38035'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'Grand Forks County, North Dakota, US');

-- ─── 2. Three chambers ───────────────────────────────────────────────────────

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT g.id, v.name, v.name, v.official_count, '4'
FROM essentials.governments g
JOIN (VALUES
  ('Grand Forks County Commission', 5),
  ('Grand Forks County Sheriff', 1),
  ('Grand Forks County State''s Attorney', 1)
) AS v(name, official_count) ON true
WHERE g.name = 'Grand Forks County, North Dakota, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. The two single-member offices ────────────────────────────────────────

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, v.title, 'ND', 1, false, 'full'
FROM essentials.governments g
JOIN essentials.chambers c ON c.government_id = g.id
JOIN (VALUES
  ('Grand Forks County Sheriff',            'Sheriff'),
  ('Grand Forks County State''s Attorney',  'State''s Attorney')
) AS v(chamber_name, title) ON v.chamber_name = c.name
JOIN essentials.districts d
  ON lower(d.state) = 'nd' AND d.geo_id = '38035' AND d.district_type::text = 'COUNTY'
WHERE g.name = 'Grand Forks County, North Dakota, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = v.title);

-- ─── 4. The five at-large commissioner offices ───────────────────────────────
-- 🔴 A COUNT guard, not a NOT EXISTS: five identical rows on one district. A NOT EXISTS guard could
-- only ever create ONE and would silently seat a fifth of the board. The subquery is evaluated
-- against the statement-start snapshot, so a first run inserts 5 and a re-run inserts 0.

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, 'Commissioner', 'ND', 1, false, 'full'
FROM essentials.governments g
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'Grand Forks County Commission'
JOIN essentials.districts d
  ON lower(d.state) = 'nd' AND d.geo_id = '38035' AND d.district_type::text = 'COUNTY'
CROSS JOIN (VALUES (1), (2), (3), (4), (5)) AS seat(n)
WHERE g.name = 'Grand Forks County, North Dakota, US'
  AND (SELECT count(*) FROM essentials.offices o
        WHERE o.chamber_id = c.id AND o.district_id = d.id) < seat.n;

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov      int;
  v_chambers int;
  v_offices  int;
  v_comm     int;
  v_sheriff  int;
  v_atty     int;
  v_vacant   int;
  v_newdist  int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE name = 'Grand Forks County, North Dakota, US';
  IF v_gov <> 1 THEN
    RAISE EXCEPTION 'ND-4 gate: expected exactly 1 Grand Forks County government row, found %', v_gov;
  END IF;

  SELECT count(*) INTO v_chambers FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Grand Forks County, North Dakota, US';
  IF v_chambers <> 3 THEN
    RAISE EXCEPTION 'ND-4 gate: expected 3 chambers, found %', v_chambers;
  END IF;

  SELECT count(*) FILTER (WHERE true),
         count(*) FILTER (WHERE o.title = 'Commissioner'),
         count(*) FILTER (WHERE o.title = 'Sheriff'),
         count(*) FILTER (WHERE o.title = 'State''s Attorney')
    INTO v_offices, v_comm, v_sheriff, v_atty
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Grand Forks County, North Dakota, US';
  IF v_offices <> 7 THEN
    RAISE EXCEPTION 'ND-4 gate: expected 7 Grand Forks County offices, found %', v_offices;
  END IF;
  IF v_comm <> 5 THEN
    RAISE EXCEPTION 'ND-4 gate: expected 5 at-large Commissioner offices (charter art. 6 s 1), found %', v_comm;
  END IF;
  IF v_sheriff <> 1 OR v_atty <> 1 THEN
    RAISE EXCEPTION 'ND-4 gate: expected 1 Sheriff and 1 State''s Attorney — the two offices the charter says "shall remain elected" — found % and %', v_sheriff, v_atty;
  END IF;

  -- 🔴 NO COMMISSION DISTRICT MAY HAVE BEEN CREATED. The commission is elected at large; a district
  -- row for it would be an invention, and it is the defect this wave is most likely to produce.
  SELECT count(*) INTO v_newdist
    FROM essentials.districts d
   WHERE lower(d.state) = 'nd' AND d.district_type::text = 'LOCAL'
     AND (d.label ILIKE '%commission%' OR d.geo_id ILIKE '%commission%');
  IF v_newdist <> 0 THEN
    RAISE EXCEPTION 'ND-4 gate: % commission district(s) exist — Grand Forks County elects AT LARGE and has none', v_newdist;
  END IF;

  -- All seven must sit on the one county district.
  IF (SELECT count(DISTINCT o.district_id)
        FROM essentials.offices o
        JOIN essentials.chambers c ON c.id = o.chamber_id
        JOIN essentials.governments g ON g.id = c.government_id
       WHERE g.name = 'Grand Forks County, North Dakota, US') <> 1 THEN
    RAISE EXCEPTION 'ND-4 gate: Grand Forks County offices are spread over more than one district';
  END IF;

  SELECT count(*) INTO v_vacant
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Grand Forks County, North Dakota, US' AND o.is_vacant IS true;
  IF v_vacant <> 0 THEN
    RAISE EXCEPTION 'ND-4 gate: expected 0 vacant Grand Forks County offices, found %', v_vacant;
  END IF;

  RAISE NOTICE 'ND-4 structure gate PASSED: 1 government, 3 chambers, 7 offices (5 at-large Commissioners + Sheriff + State''s Attorney) all on county district 38035, 0 commission districts invented, 0 vacant.';
END $$;

COMMIT;
