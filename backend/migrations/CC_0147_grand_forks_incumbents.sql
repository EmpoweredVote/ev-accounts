-- CC_0147_grand_forks_incumbents.sql
-- Knight Foundation program, wave ND-3 (occupancy half). Slot RESERVED from the allocator.
-- Applies immediately after CC_0146, which created the government, chambers, districts and offices.
--
-- Seats all nine elected City of Grand Forks officials: the Mayor, seven ward council members and
-- the elected Municipal Judge. Creates 9 people and 9 terms. NO office is left vacant.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 GRAND FORKS PUBLISHES NO TERM DATES AT ALL, SO THE DATES BELOW COME FROM THE COUNCIL'S OWN
-- MINUTES. Each ward page carries a name, a ward, an email and a phone and nothing else — no
-- "Term Expires" line and no departure banner, so the city offers NEITHER of the two change-check
-- signals this program has used (MN-2's banner, MN-3's expired date). The minutes supply both the
-- arrival dates and the change-check.
--
-- 🟢 THE OATH IS A DATED EVENT IN THE MINUTES, AND GRAND FORKS HOLDS IT AT A NAMED MEETING.
-- The outgoing council adjourns SINE DIE and the incoming one holds an ORGANIZATIONAL meeting,
-- at which the oaths are administered. Four of those meetings are established:
--
--   2020-06-23  "City Council (Sine Die)"          — Mayor Brown's last, Bochenski sworn that night
--   2022-06-28  "City Council (Sine Die) and City Council (Organizational) Meetings"
--   2024-07-01  announced in the 2024-06-17 minutes: "July 1 is also the date that the current
--               City Council will adjourn Sine Die and the newly elected City Council will hold
--               their organizational meeting and be sworn into office"
--   2026-07-06  "ORGANIZATIONAL MEETING ... ADMINISTRATION OF OATHS OF OFFICE"
--
-- ⚠ THE DATE IS NOT A FIXED RULE AND MUST NOT BE COMPUTED. It is not "the first Monday in July"
-- and not "two weeks after the election": 2022 was a TUESDAY, 2020 was a Tuesday in JUNE, 2024
-- was Monday 1 July and 2026 was Monday 6 July. Each was read from the record for that year.
--
-- 🔴 A RE-ELECTION DOES NOT RESTART AN OCCUPANCY (the SC-3 rule), so the date written is each
-- person's FIRST arrival in this seat, not the start of their current term. Osowski, Sande, Vein,
-- Weigel, Bochenski and Rosenquist have all been re-elected at least once; none of them gets the
-- 2024 or 2026 oath date.
--
-- ── WHAT EACH DATE RESTS ON ──────────────────────────────────────────────────────────────────
--
-- DAY precision, six of nine:
--   · Brandon Bochenski  Mayor      2020-06-23  elected 2020-06-09, sworn that evening; the city's
--                                               own minutes for 2020-06-23 are the sine die meeting
--                                               at which Mayor Brown was recognised for 20 years.
--   · Rebecca Osowski    Ward 2     2022-06-28  "Incoming Grand Forks City Council members Rebecca
--                                               Osowski, Ward 2 ... were sworn in on Tuesday night";
--                                               the city's calendar names that meeting "City Council
--                                               (Sine Die) and City Council (Organizational)".
--   · Kerry Rosenquist   Judge      2022-06-28  sworn the same night as "newly elected Grand Forks
--                                               Municipal Judge". The 2026-07-06 minutes call him
--                                               "reelected" and refer to "his first term", which is
--                                               the second source that his tenure starts in 2022.
--   · Tricia Berg        Ward 3     2024-07-01  new at the 2024 changeover: the 2024-06-17 roll call
--                                               is "Weigel, Osowski, WEBER, Lunski, KVAMME, Sande and
--                                               Vein" and the 2024-07-01 roll call is "Weigel,
--                                               Osowski, BERG, Lunski, FRIDOLFS, Sande and Vein".
--   · Mike Fridolfs      Ward 5     2024-07-01  same pair of roll calls; he replaced Kvamme.
--   · Angela Salentiny   Ward 4     2026-07-06  "Judge Rosenquist then administered the oaths of
--                                               office to Council Members Rebecca Osowski (Ward 2),
--                                               Angela Salentiny (Ward 4) and Dana Sande (Ward 6)."
--                                               Ward 4 was Tricia Lunski's through 2026, so
--                                               Salentiny is the only one of those three arriving.
--
-- YEAR precision, three of nine — and this is a deliberate downgrade, not a lapse:
--   · Danny Weigel       Ward 1     2016   "has been on the council since 2016"
--   · Ken Vein           Ward 7     2012   "has served on the Grand Forks City Council since 2012"
--   · Dana Sande         Ward 6     2010   "In 2010 Dana was elected to the Grand Forks City
--                                           Council, representing Ward 6"
--   Each is a YEAR from contemporaneous reporting, and CLAUDE.md's rule for a year-only source is
--   YYYY-01-01 at start_precision 'year'. The oath dates for 2010, 2012 and 2016 were not read, so
--   the day is not written. ⚠ Note that 1 January is EARLIER than the real arrival, which is in
--   June — that is what 'year' precision means here and it must not be read as a day.
--   🟢 THE THREE YEARS CARRY AN INTERNAL CROSS-CHECK. The same article that dates Weigel to 2016
--   says "only Sande and council member Ken Vein have served longer" — and 2010 < 2012 < 2016
--   reproduces that ordering exactly, from three separate statements. That is not a proof of any
--   one year, but a transcription error in any of them would have broken it.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 THE CHANGE-CHECK IS THE ROLL CALL, AND AN ABSENCE IS WHAT MAKES IT ONE. The minutes of
-- 2026-08-17 — five weeks before this wave — record "Present at roll call were Council Members
-- Weigel, Osowski, Berg, Salentiny, Sande and Vein - 6; absent: Fridolfs - 1", with Mayor
-- Bochenski presiding. All seven wards and the Mayor are accounted for BY NAME.
-- ⚠ "absent: Fridolfs" is the load-bearing half. A roster that simply omitted him would be
-- indistinguishable from a vacancy; naming him absent positively asserts he still holds Ward 5.
-- An ABSENCE IS NOT A VACANCY, and here the minutes say which one it is.
-- ⚠ THE JUDGE'S CHANGE-CHECK IS WEAKER AND THAT IS STATED RATHER THAN PAPERED OVER. He does not
-- appear in any roll call. The most recent record of him in office is the 2026-07-06 oath
-- administration — eleven weeks before this wave, against five for the council.
--
-- 🔴 PARTY IS NOT WRITTEN. Grand Forks city elections are non-partisan; party lives on
-- races.primary_party in any case.
--
-- 🟢 NO NAME COLLIDES. Swept on the guard's own key (first_name, last_name) against production:
-- 0 of 9 hit. Controlled — the same query reports 40 active rows with last_name 'Anderson', so the
-- zero is a true zero and not an empty detector.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded on a stable key. Ends with a post-verify gate.

BEGIN;

-- ─── 1. The nine people ──────────────────────────────────────────────────────

CREATE TEMP TABLE gf_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO gf_people(external_id, full_name, first_name, last_name) VALUES
  (-2762259, 'Brandon Bochenski', 'Brandon', 'Bochenski'),
  (-2762258, 'Danny Weigel',      'Danny',   'Weigel'),
  (-2762257, 'Rebecca Osowski',   'Rebecca', 'Osowski'),
  (-2762256, 'Tricia Berg',       'Tricia',  'Berg'),
  (-2762255, 'Angela Salentiny',  'Angela',  'Salentiny'),
  (-2762254, 'Mike Fridolfs',     'Mike',    'Fridolfs'),
  (-2762253, 'Dana Sande',        'Dana',    'Sande'),
  (-2762252, 'Ken Vein',          'Ken',     'Vein'),
  (-2762251, 'Kerry Rosenquist',  'Kerry',   'Rosenquist');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       'City of Grand Forks, grandforksgov.com city council and municipal court pages; arrival dates from the council''s own PROCEEDINGS OF THE CITY COUNCIL minutes (organizational/sine die meetings of 2020-06-23, 2022-06-28, 2024-07-01 and 2026-07-06); change-checked against the roll call of the 2026-08-17 regular meeting, which names all seven ward members present or absent and the Mayor presiding; read 2026-09-25 (ND-3) (CC_0147, ND-3)',
       true, true
FROM gf_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. The nine terms ───────────────────────────────────────────────────────
-- Keyed on (geo_id, office title): the citywide row 3832060 carries TWO offices, the Mayor and the
-- Municipal Judge, so geo_id alone is not a key here either.

CREATE TEMP TABLE gf_terms(geo_id text, title text, external_id bigint, term_start date, start_precision text)
  ON COMMIT DROP;

INSERT INTO gf_terms(geo_id, title, external_id, term_start, start_precision) VALUES
  ('3832060',               'Mayor',                  -2762259, DATE '2020-06-23', 'day'),
  ('grand-forks-nd-ward-1', 'Council Member, Ward 1', -2762258, DATE '2016-01-01', 'year'),
  ('grand-forks-nd-ward-2', 'Council Member, Ward 2', -2762257, DATE '2022-06-28', 'day'),
  ('grand-forks-nd-ward-3', 'Council Member, Ward 3', -2762256, DATE '2024-07-01', 'day'),
  ('grand-forks-nd-ward-4', 'Council Member, Ward 4', -2762255, DATE '2026-07-06', 'day'),
  ('grand-forks-nd-ward-5', 'Council Member, Ward 5', -2762254, DATE '2024-07-01', 'day'),
  ('grand-forks-nd-ward-6', 'Council Member, Ward 6', -2762253, DATE '2010-01-01', 'year'),
  ('grand-forks-nd-ward-7', 'Council Member, Ward 7', -2762252, DATE '2012-01-01', 'year'),
  ('3832060',               'Municipal Judge',        -2762251, DATE '2022-06-28', 'day');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, 'elected',
       'City of Grand Forks council minutes (PROCEEDINGS OF THE CITY COUNCIL), organizational and sine die meetings of 2020-06-23, 2022-06-28, 2024-07-01 and 2026-07-06, plus contemporaneous reporting for the three year-precision arrivals; read 2026-09-25 (ND-3) (CC_0147, ND-3)'
FROM gf_terms t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.district_type = 'LOCAL' AND lower(d.state) = 'nd'
JOIN essentials.offices o ON o.district_id = d.id AND o.title = t.title
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people   int;
  v_offices  int;
  v_terms    int;
  v_seated   int;
  v_day      int;
  v_year     int;
  v_ended    int;
  v_dup      int;
  v_probe    int;
  v_judge    int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2762259 AND -2762251;
  IF v_people <> 9 THEN
    RAISE EXCEPTION 'ND-3 occupancy: expected 9 people in the reserved band, got %', v_people;
  END IF;

  SELECT count(*) INTO v_offices
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Grand Forks, North Dakota, US';
  IF v_offices <> 9 THEN
    RAISE EXCEPTION 'ND-3 occupancy: expected 9 Grand Forks offices from CC_0146, got %', v_offices;
  END IF;

  SELECT count(*) INTO v_terms
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Grand Forks, North Dakota, US';
  IF v_terms <> 9 THEN
    RAISE EXCEPTION 'ND-3 occupancy: expected 9 terms, got %', v_terms;
  END IF;

  -- 🔴 Count och.politician_id, never rows: office_current_holder LEFT JOINs from offices.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'City of Grand Forks, North Dakota, US';
  IF v_seated <> 9 THEN
    RAISE EXCEPTION 'ND-3 occupancy: expected 9 seated Grand Forks offices, got %', v_seated;
  END IF;

  -- 🟢 Every term is DATED. This is the whole point of the dated route, and it is asserted rather
  -- than assumed: six at day precision from the minutes, three at year from reporting, none unknown.
  SELECT count(*) FILTER (WHERE ot.start_precision = 'day'),
         count(*) FILTER (WHERE ot.start_precision = 'year'),
         count(*) FILTER (WHERE ot.term_end IS NOT NULL)
    INTO v_day, v_year, v_ended
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Grand Forks, North Dakota, US';
  IF v_day <> 6 THEN
    RAISE EXCEPTION 'ND-3 occupancy: expected 6 day-precision terms (the four oath dates), got %', v_day;
  END IF;
  IF v_year <> 3 THEN
    RAISE EXCEPTION 'ND-3 occupancy: expected 3 year-precision terms (Weigel 2016, Vein 2012, Sande 2010), got %', v_year;
  END IF;
  IF (v_day + v_year) <> 9 THEN
    RAISE EXCEPTION 'ND-3 occupancy: % Grand Forks term(s) are neither day nor year precision — nothing here may be unknown', 9 - v_day - v_year;
  END IF;
  IF v_ended <> 0 THEN
    RAISE EXCEPTION 'ND-3 occupancy: % term(s) carry a term_end — a future end self-vacates a seat', v_ended;
  END IF;

  -- Nobody holds two Grand Forks offices.
  SELECT count(*) INTO v_dup
  FROM (SELECT och.politician_id
          FROM essentials.office_current_holder och
          JOIN essentials.offices o ON o.id = och.office_id
          JOIN essentials.chambers c ON c.id = o.chamber_id
          JOIN essentials.governments g ON g.id = c.government_id
         WHERE g.name = 'City of Grand Forks, North Dakota, US' AND och.politician_id IS NOT NULL
         GROUP BY och.politician_id HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN
    RAISE EXCEPTION 'ND-3 occupancy: % person/people hold more than one Grand Forks office', v_dup;
  END IF;

  -- 🔴 The Municipal Judge must be SEATED, not merely created. This is the office the whole stage
  -- turns on and it is the one an ordinary roster would have left empty.
  SELECT count(och.politician_id) INTO v_judge
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'City of Grand Forks, North Dakota, US' AND o.title = 'Municipal Judge';
  IF v_judge <> 1 THEN
    RAISE EXCEPTION 'ND-3 occupancy: the elected Municipal Judge is not seated (% holders)', v_judge;
  END IF;

  -- 🟢 END TO END. Grand Forks City Hall, 255 N 4th St (47.926125, -97.034585) must now reach the
  -- Mayor, the Municipal Judge and its own ward member — three city answers from one point.
  SELECT count(och.politician_id) INTO v_probe
    FROM essentials.geofence_boundaries gb
    JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc AND d.district_type = 'LOCAL'
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE gb.state = '38' AND (gb.mtfcc = 'X0067' OR gb.geo_id = '3832060')
     AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-97.034585, 47.926125), 4326));
  IF v_probe <> 3 THEN
    RAISE EXCEPTION 'ND-3 occupancy: Grand Forks City Hall reaches % city officials, expected 3 (Mayor, Municipal Judge, ward member)', v_probe;
  END IF;

  RAISE NOTICE 'ND-3 occupancy gate PASSED: 9 people, 9 offices, 9 terms, 9 seated, 6 day + 3 year precision, 0 unknown, 0 ended, the Municipal Judge is seated, and City Hall reaches 3 city officials.';
END $$;

COMMIT;
