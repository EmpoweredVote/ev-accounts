-- 1846_el_paso_county.sql
-- El Paso County, Colorado: government, two chambers, 5 commissioner districts,
-- 11 offices, and all 11 officeholders.
--
-- Colorado Springs deep seed. Depends on
-- scripts/load-elpaso-commissioner-boundaries.ts, which already wrote the five
-- X0033 geofences. The COUNTY district row (geo_id '08041', mtfcc G4020) already
-- exists from the TIGER county load and is REUSED, not recreated -- county-wide
-- row offices hang off it.
--
-- 🔴 geo_id '08041' IS NOT UNIQUE. It is El Paso County (COUNTY / G4020) AND
-- State House District 41 (STATE_LOWER / G5220) simultaneously. Every join below
-- keys on (geo_id, district_type, mtfcc). Keying on geo_id alone attaches the
-- Sheriff to a state house district.
--
-- ─── COMMISSIONER DISTRICTS ARE MAP 6 V2, NOT THE 2022 MAP ───────────────────
-- The county adopted "Map 6 V2" on 2023-08-15 by a 5-0 vote. The X0033 geofences
-- came from Commissioner_Districts_PIO, not from the plainly-named
-- Commissioner_Districts layer, which is the SUPERSEDED 2022 map -- see the
-- loader header for the four measurements that settle it.
--
-- ─── THE DISTRICT ATTORNEY IS A TWO-COUNTY OFFICE ON A ONE-COUNTY SHAPE ──────
-- Michael Allen is District Attorney for the FOURTH JUDICIAL DISTRICT, which is
-- El Paso County plus Teller County. There is no Teller geometry and no Teller
-- office in this database, so the seat is attached to the El Paso County
-- district: an El Paso address returns the correct DA, and a Teller address
-- returns nothing at all rather than something wrong. The two-county scope is
-- recorded in offices.description so the read path can say what the seat
-- actually covers. Seeding Teller County later must MOVE this seat to a shared
-- district, not add a second DA office.
--
-- ─── THE COUNTY SURVEYOR IS DELIBERATELY NOT CREATED ─────────────────────────
-- elpasoco.com/elected-officials lists a Surveyor with NO name, and no name was
-- found elsewhere. An office with no term row is INVISIBLE -- no holder, and
-- nothing errors -- which is exactly the failure mode this repo cannot detect,
-- and offices.is_vacant would assert a vacancy whose start date is unknown.
-- Creating nothing is the honest option. Revisit when the holder is established.
--
-- SOURCES (retrieved 2026-08-21)
--   Roster   elpasoco.com/elected-officials -- names and office titles
--   Party    ballotpedia.org officeholder pages -- all eleven are Republican;
--            read per person, NOT inferred from the county's partisan lean
--   Dates    ballotpedia.org "assumed office"; Wysong and Applegate corroborated
--            by the county's own oath-of-office release naming 2025-01-14
--
-- ⚠ Stan VanderWerf is NOT the District 3 commissioner. He is Bill Wysong's
-- predecessor and still appears as the incumbent in stale sources.
--
-- term_start IS THE ASSUMED-OFFICE DATE, not the start of the current term.
-- Geitner and Allen were both re-elected and took the oath again on 2025-01-14,
-- but have held their seats continuously since 2021-01-12, so that is the date
-- recorded.
--
-- DATE PRECISION is recorded, never fabricated:
--   9 seats  day precision.
--   Lauren Nelson (D5)          MONTH -- bocc.elpasoco.com says "appointed in
--                               June 2025" and gives no day. 2025-06-01/'month'.
--   Chuck Broerman (Treasurer)  MONTH -- Ballotpedia says 2023-01-01, but his
--                               three peers elected on the same day all show
--                               2023-01-10, and Colorado county officers' terms
--                               begin the second Tuesday of January, which in
--                               2023 was the 10th. January is certain; the day
--                               is not, so the day is not claimed.
--   Emily Russell-Kinsley       YEAR -- Ballotpedia has only "2025"; she is not
--                               named in the county's oath release.
--
-- how_started is NULL throughout: Nelson is known to be an appointee and the
-- rest are presumed elected, but that was not confirmed per person and
-- seat_officeholder's default of 'elected' would assert it for all eleven.
--
-- EXTERNAL IDS: -(840000 + n), n = 1..11. Verified free 2026-08-21.

BEGIN;

-- ─── Government + chambers ───────────────────────────────────────────────────

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'El Paso County, Colorado, US', 'County', 'CO', NULL, '08041'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'El Paso County, Colorado, US'
);

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, term_length, staggered_term, policy_engagement_level)
SELECT g.id, v.name, v.formal, v.cnt, 4, true, 'full'
FROM essentials.governments g
CROSS JOIN (VALUES
  ('Board of County Commissioners', 'El Paso County Board of County Commissioners', 5),
  ('Countywide Elected Officials',  'El Paso County Elected Officials',             6)
) AS v(name, formal, cnt)
WHERE g.name = 'El Paso County, Colorado, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name
  );

-- ─── Commissioner districts ──────────────────────────────────────────────────
-- state is LOWERCASE 'co': it is the LOCAL-tier routing join key.

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT 'el-paso-co-commissioner-district-' || n,
       'El Paso County Commissioner District ' || n,
       'LOCAL', 'co', 'X0033'
FROM generate_series(1, 5) AS n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = 'el-paso-co-commissioner-district-' || n AND d.district_type = 'LOCAL'
);

DO $$
DECLARE v_missing int; v_county int;
BEGIN
  SELECT count(*) INTO v_missing
  FROM essentials.districts d
  WHERE d.mtfcc = 'X0033' AND d.district_type = 'LOCAL'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.geofence_boundaries g
      WHERE g.geo_id = d.geo_id AND g.mtfcc = 'X0033'
    );
  IF v_missing <> 0 THEN
    RAISE EXCEPTION 'El Paso commissioner districts with no X0033 geofence: % — run scripts/load-elpaso-commissioner-boundaries.ts first', v_missing;
  END IF;

  -- The county-wide row offices depend on a district row this migration does not create.
  SELECT count(*) INTO v_county
  FROM essentials.districts
  WHERE geo_id = '08041' AND district_type = 'COUNTY' AND mtfcc = 'G4020';
  IF v_county <> 1 THEN
    RAISE EXCEPTION 'expected exactly 1 El Paso COUNTY/G4020 district row, found %', v_county;
  END IF;
END $$;

-- ─── Offices: 5 commissioners ────────────────────────────────────────────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, is_appointed_position, seats)
SELECT c.id, d.id, 'Commissioner, District ' || right(d.geo_id, 1), 'CO', false, 1
FROM essentials.districts d
CROSS JOIN LATERAL (
  SELECT ch.id FROM essentials.chambers ch
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.name = 'El Paso County, Colorado, US' AND ch.name = 'Board of County Commissioners'
) c
WHERE d.district_type = 'LOCAL' AND d.mtfcc = 'X0033'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.title = 'Commissioner, District ' || right(d.geo_id, 1)
  );

-- ─── Offices: 6 county-wide row offices, on the COUNTY district ──────────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, is_appointed_position, seats, description)
SELECT c.id, d.id, v.title, 'CO', false, 1, v.descr
FROM (VALUES
  ('Sheriff',                      NULL::text),
  ('Clerk and Recorder',           NULL::text),
  ('Assessor',                     NULL::text),
  ('Treasurer and Public Trustee', NULL::text),
  ('Coroner',                      NULL::text),
  ('District Attorney',            'District Attorney for Colorado''s Fourth Judicial District, which covers El Paso County AND Teller County. The seat is attached to the El Paso County district because no Teller County geography or office exists in this database; a Teller address therefore returns nothing here rather than something wrong. If Teller is seeded later this seat must MOVE to a shared district, not be duplicated.')
) AS v(title, descr)
CROSS JOIN essentials.districts d
CROSS JOIN LATERAL (
  SELECT ch.id FROM essentials.chambers ch
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.name = 'El Paso County, Colorado, US' AND ch.name = 'Countywide Elected Officials'
) c
WHERE d.geo_id = '08041' AND d.district_type = 'COUNTY' AND d.mtfcc = 'G4020'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.title = v.title
  );

-- ─── People + occupancy ──────────────────────────────────────────────────────

CREATE TEMP TABLE epc_seed (
  ext_id          bigint,
  full_name       text,
  first_name      text,
  last_name       text,
  geo_id          text,
  district_type   text,
  mtfcc           text,
  office_title    text,
  term_start      date,
  start_precision text
) ON COMMIT DROP;

INSERT INTO epc_seed VALUES
  (-840001, 'Holly Williams',        'Holly',  'Williams',       'el-paso-co-commissioner-district-1', 'LOCAL',  'X0033', 'Commissioner, District 1',     DATE '2019-01-08', 'day'),
  (-840002, 'Carrie Geitner',        'Carrie', 'Geitner',        'el-paso-co-commissioner-district-2', 'LOCAL',  'X0033', 'Commissioner, District 2',     DATE '2021-01-12', 'day'),
  (-840003, 'Bill Wysong',           'Bill',   'Wysong',         'el-paso-co-commissioner-district-3', 'LOCAL',  'X0033', 'Commissioner, District 3',     DATE '2025-01-14', 'day'),
  (-840004, 'Cory Applegate',        'Cory',   'Applegate',      'el-paso-co-commissioner-district-4', 'LOCAL',  'X0033', 'Commissioner, District 4',     DATE '2025-01-14', 'day'),
  (-840005, 'Lauren Nelson',         'Lauren', 'Nelson',         'el-paso-co-commissioner-district-5', 'LOCAL',  'X0033', 'Commissioner, District 5',     DATE '2025-06-01', 'month'),
  (-840006, 'Joe Roybal',            'Joe',    'Roybal',         '08041',                              'COUNTY', 'G4020', 'Sheriff',                      DATE '2023-01-10', 'day'),
  (-840007, 'Steve Schleiker',       'Steve',  'Schleiker',      '08041',                              'COUNTY', 'G4020', 'Clerk and Recorder',           DATE '2023-01-10', 'day'),
  (-840008, 'Mark Flutcher',         'Mark',   'Flutcher',       '08041',                              'COUNTY', 'G4020', 'Assessor',                     DATE '2023-01-10', 'day'),
  (-840009, 'Chuck Broerman',        'Chuck',  'Broerman',       '08041',                              'COUNTY', 'G4020', 'Treasurer and Public Trustee', DATE '2023-01-01', 'month'),
  (-840010, 'Emily Russell-Kinsley', 'Emily',  'Russell-Kinsley','08041',                              'COUNTY', 'G4020', 'Coroner',                      DATE '2025-01-01', 'year'),
  (-840011, 'Michael Allen',         'Michael','Allen',          '08041',                              'COUNTY', 'G4020', 'District Attorney',            DATE '2021-01-12', 'day');

DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM epc_seed;
  IF v_n <> 11 THEN RAISE EXCEPTION 'county seed payload: expected 11 rows, got %', v_n; END IF;
END $$;

-- Every one of the eleven is Republican, read per person from their own
-- Ballotpedia page rather than inferred from the county's partisan lean.
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, party, party_short_name, is_incumbent, is_active, data_source)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, 'Republican', 'R', true, true,
       'elpasoco.com/elected-officials for the roster; ballotpedia.org officeholder pages for party and assumed-office dates (Wysong and Applegate corroborated by the county oath-of-office release naming 2025-01-14). Retrieved 2026-08-21.'
FROM epc_seed s
ON CONFLICT (external_id) DO NOTHING;

DO $$
DECLARE r record; v_seated int := 0;
BEGIN
  FOR r IN
    SELECT s.term_start, s.start_precision, o.id AS office_id, p.id AS politician_id
    FROM epc_seed s
    JOIN essentials.politicians p ON p.external_id = s.ext_id
    JOIN essentials.districts d
      ON d.geo_id = s.geo_id AND d.district_type = s.district_type AND d.mtfcc = s.mtfcc
    JOIN essentials.offices o ON o.district_id = d.id AND o.title = s.office_title
    WHERE NOT EXISTS (
      SELECT 1 FROM essentials.office_terms t
      WHERE t.office_id = o.id AND t.politician_id = p.id
    )
  LOOP
    PERFORM essentials.seat_officeholder(
      r.office_id, r.politician_id, r.term_start,
      'elpasoco.com/elected-officials + ballotpedia.org assumed-office dates. Retrieved 2026-08-21.',
      NULL,               -- how_started: Nelson is an appointee, the rest presumed elected but unconfirmed
      r.start_precision
    );
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'seated % El Paso County official(s)', v_seated;
END $$;

-- ─── Post-verify gate ────────────────────────────────────────────────────────
DO $$
DECLARE v_comm int; v_row int; v_held int; v_orphan int;
BEGIN
  SELECT count(*) INTO v_comm
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.mtfcc = 'X0033' AND d.district_type = 'LOCAL';

  SELECT count(*) INTO v_row
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '08041' AND d.district_type = 'COUNTY' AND d.mtfcc = 'G4020';

  -- IS NOT NULL is load-bearing: office_current_holder LEFT JOINs from offices,
  -- so a vacancy is a NULL politician_id and this would otherwise pass vacuously.
  SELECT count(*) INTO v_held
  FROM essentials.office_current_holder och
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE ((d.mtfcc = 'X0033' AND d.district_type = 'LOCAL')
      OR (d.geo_id = '08041' AND d.district_type = 'COUNTY' AND d.mtfcc = 'G4020'))
    AND och.politician_id IS NOT NULL;

  SELECT count(*) INTO v_orphan
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE ((d.mtfcc = 'X0033' AND d.district_type = 'LOCAL')
      OR (d.geo_id = '08041' AND d.district_type = 'COUNTY' AND d.mtfcc = 'G4020'))
    AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id);

  IF v_comm <> 5 THEN RAISE EXCEPTION 'El Paso commissioner offices: expected 5, got %', v_comm; END IF;
  IF v_row <> 6 THEN RAISE EXCEPTION 'El Paso county-wide offices: expected 6, got %', v_row; END IF;
  IF v_held <> 11 THEN RAISE EXCEPTION 'El Paso seats with a current holder: expected 11, got %', v_held; END IF;
  IF v_orphan <> 0 THEN RAISE EXCEPTION 'El Paso offices with NO term row (invisible seats): %', v_orphan; END IF;
END $$;

COMMIT;
