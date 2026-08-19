-- 1828_austin_travis_seating.sql
--
-- Austin TX / Travis County deep seed, wave 1, PART B — the 23 people and their occupancy.
-- Requires 1827_austin_travis_offices.sql (Part A) to have run: it creates the seats.
--
-- Roster, per-seat sourcing, and the source defects found are in
-- backend/data/seed-austin-2026/ROSTERS.md. Two independent official sources agree 12-for-12
-- on the county slate (the county's own org chart dated 2026-06-15, and the Travis County
-- Clerk's office-holder list — the Clerk being the election authority). The city roster comes
-- from austintexas.gov's own council page, read as district-href -> member-name link text.
--
-- 🔴 BALLOTPEDIA IS STALE ON PRECINCT 4 and was NOT followed. It still lists Margaret Gómez,
--    assumed 1995. Gómez retired EARLY on 2026-06-11 after losing the ability to walk, and
--    George Morales III — who had already won the 2026-05-26 Democratic primary runoff — was
--    APPOINTED the same day. Both official county sources show Morales. Ballotpedia is a
--    detector, not an oracle.
--
-- 🔴 THE alt TEXT ON THE CITY COUNCIL PAGE IS UNUSABLE — it has no entry at all for D4 or
--    D10, and it strips diacritics ("Jose Velasquez" for "José Velásquez"). The names below
--    come from the `member-name` anchor text, which is keyed to each district's href and is
--    therefore a structural mapping rather than a positional one. Same defect class as the
--    Kitsap alt-off-by-one that would have filed one sheriff's face under another's name.
--
-- WHAT term_start MEANS HERE, AND WHY
-- It is the start of CONTINUOUS OCCUPANCY OF THIS SEAT BY THIS PERSON — not the start of the
-- current four-year term. Re-election does not end an occupancy. CLAUDE.md's stated purpose
-- for essentials.office_holders_as_of(date) is answering "who represented me in 2019", and
-- that only works if Natasha Harper-Madison's D1 row starts 2019-01-07 rather than at her
-- most recent swearing-in of 2023-01-06. Recording the latter would make the function report
-- no holder for a seat she demonstrably held.
--
-- Kirk Watson was also Mayor of Austin 1997-2001. That span is NON-CONTINUOUS with the
-- current one and is deliberately not written; omitting history is not the same as asserting
-- the seat was empty.
--
-- HONESTY ON DATES (CLAUDE.md: don't invent dates)
-- Five county rows carry start_precision => 'year' because the source gave only a year.
-- Texas county terms do in fact begin January 1, so 1 January is very probably the exact day
-- — but the SOURCE said "2017", so the record says year. The rest are day-precision from a
-- source that printed a day.
--
-- TERM ENDS ARE DELIBERATELY NOT WRITTEN. seat_officeholder writes an open-ended term, which
-- is the documented lifecycle: a term is closed when a successor is seated (the helper closes
-- the predecessor the day before) or by vacate_office. Writing the known future term_end
-- values would make all 23 seats silently SELF-VACATE in January 2027 or 2029 if nobody
-- updates them — trading a visible staleness problem for an invisible disappearance.
-- The known end dates are recorded in ROSTERS.md instead. Recheck January 2027.
--
-- 🔴 NO PARTY IS SET on any of these rows. Party affiliation is antipartisan by design here —
--    it lives on races.primary_party (which ballot a voter requests), never on the person.
--    Austin's council is formally nonpartisan; the Travis County executives are partisan-
--    elected, and it is still not this table's business.
--
-- DEDUPE, run against prod before writing this (read-only), NFD-normalised because `unaccent`
-- is not installed:
--   * No exact normalised full_name match for any of the 23.
--   * Two first+last near-misses, both REFUSED: `HERNANDEZ, SALLY` and
--     `VELASQUEZ, JOSE ANGEL`. Both are source='cal_access_discovery' — CALIFORNIA campaign
--     finance records — with first_name='', the whole string dumped into last_name, and
--     is_active=false. Cross-state homonyms, not our Travis County Sheriff or our D3 council
--     member. They each carry one placeholder-occupancy seat, which is the known 77k-row
--     discovered-candidate pattern. They are NOT touched and MUST NOT be deleted.
--
-- 🔴 TWO-SURNAME / SUFFIX TRAP. Per the Puerto Rico wave (5-for-5 failures), this migration
--    does NOT gate on any name rule. It gates on a SQL SEAT GUARD: 23 offices, each resolving
--    to exactly one holder with politician_id IS NOT NULL. Name-part splits below are a
--    display convenience and are explicitly allowed to be imperfect:
--      * 'Dolores Ortega Carter' is stored with last_name 'Ortega Carter'. Whether Ortega is
--        a middle name or half of a double surname is NOT established by our sources, so the
--        searchable variant 'Dolores Carter' goes in alternate_names rather than the split
--        being asserted one way.
--      * 'Jeffrey W. Travillion, Sr.' and 'George Morales III' keep suffixes in name_suffix,
--        with the shorter published forms ('Jeff Travillion', 'George Morales') in
--        alternate_names — both forms appear across the county's own publications.
--      * The quoted nicknames on D4 and D9 follow existing corpus precedent
--        (`Abusana "Micky" Bondo`, `Adam "Ditch" Kurtz`), with preferred_name set.
--
-- Idempotent. People are NOT EXISTS-guarded on full_name; seat_officeholder is idempotent by
-- design. Re-running changes nothing.

BEGIN;

-- ---------------------------------------------------------------------------
-- 0. Staging
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE _people (
  full_name       text NOT NULL,
  first_name      text NOT NULL,
  last_name       text NOT NULL,
  middle_initial  text,
  name_suffix     text,
  preferred_name  text,
  alternate_names text[] NOT NULL DEFAULT '{}',
  district_geo    text NOT NULL,
  district_kind   text NOT NULL,
  office_title    text NOT NULL,
  term_start      date NOT NULL,
  start_precision text NOT NULL,
  how_started     text NOT NULL
) ON COMMIT DROP;

INSERT INTO _people
 (full_name, first_name, last_name, middle_initial, name_suffix, preferred_name, alternate_names,
  district_geo, district_kind, office_title, term_start, start_precision, how_started) VALUES
-- ---- City of Austin (11) -------------------------------------------------
-- Sworn in 2023-01-06: Mayor, D1(2019), D3, D5, D8(2019), D9
-- Sworn in 2025-01-06: D6, D7, D10.  D2 2021-01-06.  D4 2022-02-04 (special election).
('Kirk Watson','Kirk','Watson',NULL,NULL,NULL,'{}',
  '4805000','LOCAL','Mayor',DATE '2023-01-06','day','elected'),
('Natasha Harper-Madison','Natasha','Harper-Madison',NULL,NULL,NULL,'{}',
  '4805000','LOCAL','Council Member District 1',DATE '2019-01-07','day','elected'),
('Vanessa Fuentes','Vanessa','Fuentes',NULL,NULL,NULL,'{}',
  '4805000','LOCAL','Council Member District 2',DATE '2021-01-06','day','elected'),
('José Velásquez','José','Velásquez',NULL,NULL,NULL,'{"Jose Velasquez"}',
  '4805000','LOCAL','Council Member District 3',DATE '2023-01-06','day','elected'),
('José "Chito" Vela','José','Vela',NULL,NULL,'Chito','{"Chito Vela","Jose Vela","José Vela"}',
  '4805000','LOCAL','Council Member District 4',DATE '2022-02-04','day','elected'),
('Ryan Alter','Ryan','Alter',NULL,NULL,NULL,'{}',
  '4805000','LOCAL','Council Member District 5',DATE '2023-01-06','day','elected'),
('Krista Laine','Krista','Laine',NULL,NULL,NULL,'{}',
  '4805000','LOCAL','Council Member District 6',DATE '2025-01-06','day','elected'),
('Mike Siegel','Mike','Siegel',NULL,NULL,NULL,'{"Michael Siegel"}',
  '4805000','LOCAL','Council Member District 7',DATE '2025-01-06','day','elected'),
('Paige Ellis','Paige','Ellis',NULL,NULL,NULL,'{}',
  '4805000','LOCAL','Council Member District 8',DATE '2019-01-07','day','elected'),
('Zohaib "Zo" Qadri','Zohaib','Qadri',NULL,NULL,'Zo','{"Zo Qadri","Zohaib Qadri"}',
  '4805000','LOCAL','Council Member District 9',DATE '2023-01-06','day','elected'),
('Marc Duchen','Marc','Duchen',NULL,NULL,NULL,'{}',
  '4805000','LOCAL','Council Member District 10',DATE '2025-01-06','day','elected'),
-- ---- Travis County Commissioners Court (5) -------------------------------
-- Andy Brown took office 2020-11-17, filling the vacancy left when Sarah Eckhardt resigned;
-- that is why his start is mid-November and not a 1 January.
('Andy Brown','Andy','Brown',NULL,NULL,NULL,'{"Andrew Brown"}',
  '48453','COUNTY','County Judge',DATE '2020-11-17','day','elected'),
('Jeffrey W. Travillion, Sr.','Jeffrey','Travillion','W','Sr.',NULL,'{"Jeff Travillion","Jeffrey Travillion"}',
  '48453','COUNTY','Commissioner, Precinct 1',DATE '2017-01-01','year','elected'),
('Brigid Shea','Brigid','Shea',NULL,NULL,NULL,'{}',
  '48453','COUNTY','Commissioner, Precinct 2',DATE '2015-01-01','year','elected'),
('Ann Howard','Ann','Howard',NULL,NULL,NULL,'{}',
  '48453','COUNTY','Commissioner, Precinct 3',DATE '2021-01-01','day','elected'),
-- APPOINTED, not elected — 2026-06-11, the day Gómez stepped down. He is unopposed in the
-- 2026-11-03 general, after which a fresh ELECTED term begins 2027-01-01. Recheck Jan 2027.
('George Morales III','George','Morales',NULL,'III',NULL,'{"George Morales"}',
  '48453','COUNTY','Commissioner, Precinct 4',DATE '2026-06-11','day','appointed'),
-- ---- Travis County countywide elected executives (7) ---------------------
-- José Garza (DA) and Delia Garza (County Attorney) are DIFFERENT PEOPLE who share a surname
-- and took office the same day. Two rows, deliberately.
('José Garza','José','Garza',NULL,NULL,NULL,'{"Jose Garza"}',
  '48453','COUNTY','District Attorney',DATE '2021-01-01','day','elected'),
('Delia Garza','Delia','Garza',NULL,NULL,NULL,'{}',
  '48453','COUNTY','County Attorney',DATE '2021-01-01','day','elected'),
('Sally Hernandez','Sally','Hernandez',NULL,NULL,NULL,'{}',
  '48453','COUNTY','Sheriff',DATE '2017-01-01','year','elected'),
('Celia Israel','Celia','Israel',NULL,NULL,NULL,'{}',
  '48453','COUNTY','Tax Assessor-Collector',DATE '2025-01-01','day','elected'),
('Dyana Limon-Mercado','Dyana','Limon-Mercado',NULL,NULL,NULL,'{}',
  '48453','COUNTY','County Clerk',DATE '2023-01-01','day','elected'),
('Velva L. Price','Velva','Price','L',NULL,NULL,'{"Velva Price"}',
  '48453','COUNTY','District Clerk',DATE '2015-01-01','year','elected'),
-- Surname split NOT asserted; see the two-surname note in the header.
('Dolores Ortega Carter','Dolores','Ortega Carter',NULL,NULL,NULL,'{"Dolores Carter"}',
  '48453','COUNTY','County Treasurer',DATE '1987-01-01','year','elected');

-- ---------------------------------------------------------------------------
-- 1. Pre-flight: every seat named above must already exist, exactly once.
--    Runs BEFORE any write so a missing Part A fails loudly instead of half-seeding.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  missing text;
  n int;
BEGIN
  SELECT count(*) INTO n FROM _people;
  IF n <> 23 THEN
    RAISE EXCEPTION 'staging holds % rows, expected 23', n;
  END IF;

  SELECT string_agg(pp.district_kind || ' ' || pp.district_geo || ' / ' || pp.office_title, '; ')
    INTO missing
  FROM _people pp
  WHERE NOT EXISTS (
    SELECT 1
      FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.geo_id = pp.district_geo
       AND d.district_type = pp.district_kind
       AND o.title = pp.office_title
  );
  IF missing IS NOT NULL THEN
    RAISE EXCEPTION 'Part A has not run, or titles drifted. Missing seats: %', missing;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2. People
-- ---------------------------------------------------------------------------
INSERT INTO essentials.politicians
  (full_name, first_name, last_name, middle_initial, name_suffix, preferred_name,
   alternate_names, is_active, is_incumbent, source)
SELECT pp.full_name, pp.first_name, pp.last_name, pp.middle_initial, pp.name_suffix,
       pp.preferred_name, pp.alternate_names, true, true,
       'Austin/Travis wave 1 2026-08-18; see backend/data/seed-austin-2026/ROSTERS.md'
FROM _people pp
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politicians p WHERE p.full_name = pp.full_name
);

-- 1:1 assertion before anything is seated. If a name resolved to two rows we would seat an
-- arbitrary one of them, so refuse instead. This is the guard that replaces a name rule.
DO $$
DECLARE dupes text;
BEGIN
  SELECT string_agg(pp.full_name || ' -> ' || cnt::text, '; ') INTO dupes
  FROM (
    SELECT pp.full_name, (SELECT count(*) FROM essentials.politicians p WHERE p.full_name = pp.full_name) AS cnt
    FROM _people pp
  ) pp
  WHERE pp.cnt <> 1;
  IF dupes IS NOT NULL THEN
    RAISE EXCEPTION 'these names do not resolve 1:1 in essentials.politicians: %', dupes;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 3. Occupancy, via the helper. Never hand-roll the two-step.
-- ---------------------------------------------------------------------------
SELECT essentials.seat_officeholder(
         o.id,
         p.id,
         pp.term_start,
         'Austin/Travis wave 1 2026-08-18; see backend/data/seed-austin-2026/ROSTERS.md',
         pp.how_started,
         pp.start_precision
       )
FROM _people pp
JOIN essentials.politicians p ON p.full_name = pp.full_name
JOIN essentials.districts d
  ON d.geo_id = pp.district_geo AND d.district_type = pp.district_kind
JOIN essentials.offices o
  ON o.district_id = d.id AND o.title = pp.office_title;

-- ---------------------------------------------------------------------------
-- 4. Post-verify gate
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  seated_city   int;
  seated_county int;
  precision_ct  int;
  appointed_ct  int;
  morales_ok    int;
  unseated      text;
  cal_access    int;
BEGIN
  -- 🔴 politician_id IS NOT NULL is load-bearing. office_current_holder LEFT JOINs from
  --    offices, so a vacancy is a NULL politician_id on a row that still exists. A bare
  --    count(*) would count all 23 seats whether anyone occupies them or not, and pass
  --    vacuously — which is exactly the failure this whole migration exists to avoid.
  SELECT count(*) INTO seated_city
    FROM essentials.office_current_holder och
    JOIN essentials.offices o   ON o.id = och.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '4805000' AND d.district_type = 'LOCAL'
     AND och.politician_id IS NOT NULL;
  IF seated_city <> 11 THEN
    RAISE EXCEPTION 'expected 11 seated City of Austin offices, found %', seated_city;
  END IF;

  SELECT count(*) INTO seated_county
    FROM essentials.office_current_holder och
    JOIN essentials.offices o   ON o.id = och.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '48453' AND d.district_type = 'COUNTY'
     AND och.politician_id IS NOT NULL;
  IF seated_county <> 12 THEN
    RAISE EXCEPTION 'expected 12 seated Travis County offices, found %', seated_county;
  END IF;

  -- Name every unseated seat rather than just counting, so a failure is actionable.
  SELECT string_agg(d.label || ' / ' || o.title, '; ') INTO unseated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE ((d.geo_id = '4805000' AND d.district_type = 'LOCAL')
       OR (d.geo_id = '48453'   AND d.district_type = 'COUNTY'))
     AND och.politician_id IS NULL;
  IF unseated IS NOT NULL THEN
    RAISE EXCEPTION 'unseated Austin/Travis seats remain: %', unseated;
  END IF;

  -- The five year-precision rows must be recorded as year-precision, not silently upgraded
  -- to 'day' by the helper's default.
  SELECT count(*) INTO precision_ct
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '48453' AND d.district_type = 'COUNTY'
     AND t.start_precision = 'year';
  IF precision_ct <> 5 THEN
    RAISE EXCEPTION 'expected 5 year-precision Travis County terms, found %', precision_ct;
  END IF;

  -- Morales is APPOINTED. If this reads 'elected' the how_started argument was dropped.
  SELECT count(*) INTO morales_ok
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE p.full_name = 'George Morales III'
     AND t.term_start = DATE '2026-06-11'
     AND t.how_started = 'appointed';
  IF morales_ok <> 1 THEN
    RAISE EXCEPTION 'expected exactly 1 Morales term appointed 2026-06-11, found %', morales_ok;
  END IF;

  SELECT count(*) INTO appointed_ct
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '48453' AND d.district_type = 'COUNTY'
     AND t.how_started = 'appointed';
  IF appointed_ct <> 1 THEN
    RAISE EXCEPTION 'expected exactly 1 appointed Travis County term, found %', appointed_ct;
  END IF;

  -- The two refused CAL-ACCESS homonyms must still be present and untouched. Their survival
  -- is the assertion: this migration must not have "cleaned up" a real person's record.
  SELECT count(*) INTO cal_access
    FROM essentials.politicians p
   WHERE p.id IN ('2da3643e-7c51-49ff-a6a9-7a70c8b58117',
                  '5bf351da-fa81-45aa-8ee6-2c786072d566')
     AND p.source = 'cal_access_discovery';
  IF cal_access <> 2 THEN
    RAISE EXCEPTION 'the 2 refused cal_access homonym rows are no longer intact (found %)', cal_access;
  END IF;

  RAISE NOTICE 'OK: Austin/Travis wave 1 Part B — 23 seats seated (11 city + 12 county), 5 year-precision, 1 appointed (Morales), 2 cal_access homonyms refused and intact.';
END $$;

COMMIT;
