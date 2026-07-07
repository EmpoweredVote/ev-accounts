-- Migration 1196: City of Cornelius government + chamber + districts + officials + offices
--
-- Purpose: Seeds the City of Cornelius, Oregon (Washington County, west-metro):
--   Cornelius (geo_id='4115550' -- CORRECTED against essentials.geofence_boundaries at Wave-0;
--   the ROADMAP/CONTEXT-stated '4115350' resolves to a different real city, Coquille, and must
--   NEVER be used) -- 1 gov + 1 chamber + 2 districts + 5 offices (4 filled + 1 vacant).
--
-- Form of government (RESEARCH-confirmed, re-verified fresh at Wave-0 2026-07-03 via
-- corneliusor.gov/267/City-Council, no WAF): Cornelius Charter Section 7 is PURE AT-LARGE,
-- PLAIN titles ('Mayor' / 'Councilor', NO numbered positions, NO wards) -- the same shape class
-- as Sherwood (1187) / Tigard (1159) / Forest Grove (1178). Mayor Jeffrey C. Dalin is directly
-- elected citywide on a 2-YEAR term (Charter Section 25 -- Sherwood shape, not the 4-year norm
-- elsewhere this milestone). Charter Section 24 "by position" is staggering only -- it does NOT
-- create numbered council positions or wards; do not model it as such.
--
-- Appointed seats: Councilor Edgar Baker and Councilor Eden Lopez are BOTH APPOINTED (Tigard
-- 1159 Hu/Anderson shape: is_appointed=true on the politician AND is_appointed_position=true on
-- the office). Mayor Dalin and Councilor Angeles Godinez Valencia are ELECTED (false/false) --
-- the highest appointed-seat density (2 of 4 filled seats) of the milestone.
--
-- VACANT SEAT (new wrinkle this phase): the 5th councilor seat is genuinely vacant (city's own
-- "vacant City Council position" notice, application period open as of Wave-0). Modeled per the
-- TX-23 precedent (migration 105): an office-ONLY row with politician_id=NULL, is_vacant=true,
-- is_appointed_position=false, and NO politician row created. external_id -4115555 is
-- intentionally UNUSED -- do NOT create a politician row for it, and do NOT invent a name.
-- official_count=5 reflects the Charter's designed seat count (Mayor + 4 councilors, one
-- currently vacant) -- the Wave-0-recorded vacant-seat decision, option (a).
--
-- PITFALL GUARD: Citlalli Nunez-Barragan is stale alt-text on a leftover city-site image and is
-- NOT a current or former council member per the live roster re-fetch at Wave-0. She must NEVER
-- be seated on the vacant seat or anywhere else in this migration.
--
-- CRITICAL: the generated identifier column on essentials.chambers is NEVER included in an INSERT.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id -- use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state must be 'or' (lowercase) to match routing queries.
-- CRITICAL: governments.state = 'OR' (uppercase). offices.representing_state = 'OR' (uppercase).
-- CRITICAL: district_type='LOCAL_EXEC' for Mayor; district_type='LOCAL' for council (NOT 'COUNTY').
-- CRITICAL: titles are PLAIN 'Mayor' / 'Councilor' only -- NO position numbers, NO ward suffixes.
--           All 4 councilor seats (3 filled + 1 vacant) share the ONE LOCAL district; create NO
--           per-seat/per-position districts and NO ward/X00xx geofences of any kind (pure
--           at-large model).
-- CRITICAL: representing_city='Cornelius' is set INLINE on every office INSERT (D-11 convention)
--           so the community banner derives correctly at first browse -- no backfill migration
--           needed.
-- CRITICAL: politicians.party is ALWAYS NULL (antipartisan mission).
-- CRITICAL: D-16 / IN-01 -- the repeated chamber-lookup subquery is hoisted into a `WITH chamber
--           AS (...)` CTE referenced via `(SELECT id FROM chamber)` in every office INSERT's
--           chamber_id column, replacing the doubly-nested inline subquery the Sherwood template
--           repeats in every block.
-- CRITICAL: this migration's post-verification identity gate uses the pairwise (external_id,
--           full_name) form (D-15 WR-B pattern) -- stronger than a set-membership two-independent-
--           IN-lists gate, which would pass a name/id transposition. It also STRENGTHENS the
--           geofence assertion past mere existence to an exact name match ('Cornelius city'),
--           this phase's Pitfall 1 (the Coquille trap).
-- CRITICAL: 'Eden Lopez' is the milestone's first accented officeholder name (Eden Lopez) -- this
--           file is saved as UTF-8 WITHOUT a byte-order mark so the accented literals insert
--           cleanly.

BEGIN;

-- Pre-flight hard-abort guard.
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'City of Cornelius, Oregon, US') > 0 THEN
    RAISE EXCEPTION 'Migration 1196 already applied — aborting re-run';
  END IF;
END $$;

-- Government row.
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Cornelius, Oregon, US',
       'LOCAL', 'OR', 'Cornelius', '4115550'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Cornelius, Oregon, US'
);

-- Chamber row. NOTE: chambers has a GENERATED ALWAYS column — never insert it.
-- official_count=5 per the Wave-0-recorded vacant-seat decision option (a): the Charter's
-- designed seat count (Mayor + 4 councilors, one currently vacant).
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'City Council',
       'Cornelius City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Cornelius, Oregon, US'),
       5
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Cornelius, Oregon, US')
);

-- LOCAL_EXEC district — Mayor is directly elected citywide on a 2-YEAR term (Charter Section 25;
-- the Sherwood shape, not the 4-year norm elsewhere this milestone). Structural shape is
-- unchanged: same LOCAL_EXEC + shared LOCAL split as Beaverton/Tualatin/Forest Grove/Sherwood.
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'or', '4115550', 'Cornelius (Mayor, Citywide, 2-Year Term)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4115550' AND district_type = 'LOCAL_EXEC' AND state = 'or'
);

-- LOCAL at-large district — all 4 councilor seats (3 filled + 1 vacant) share ONE row. Do NOT
-- create per-seat/per-position districts; Charter Section 7 is pure at-large, Section 24 "by
-- position" is staggering only, not wards or numbered seats.
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'or', '4115550', 'Cornelius (At-Large)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4115550' AND district_type = 'LOCAL' AND state = 'or'
);

-- Mayor Jeffrey C. Dalin (-4115551) — directly elected citywide, 2-year term expiring Dec 2026
-- (Charter Section 25). Not appointed: false/false.
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Cornelius, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jeffrey C. Dalin', 'Jeffrey', 'Dalin', NULL,
          true, false, false, true, -4115551)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Mayor', 'OR', 'Cornelius', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4115550'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Councilor Angeles Godinez Valencia (-4115552) — elected 2021, re-elected 2025, term through
-- Dec 2028. Holds the Council President title-on-seat (confirmed via the live city council
-- page) — this is a note on her seat, NOT a separate office row. ONE office row only, title
-- stays plain 'Councilor' — same treatment class as Sherwood's Young, Tigard's Wolf, Tualatin's
-- Pratt, Forest Grove's Valenzuela. Not appointed: false/false.
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Cornelius, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Angeles Godinez Valencia', 'Angeles', 'Godinez Valencia', NULL,
          true, false, false, true, -4115552)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Councilor', 'OR', 'Cornelius', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4115550'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Councilor Edgar Baker (-4115553) — APPOINTED June 2026, term through Dec 2026 (Tigard 1159
-- Hu/Anderson shape: is_appointed=true on the politician AND is_appointed_position=true on the
-- office).
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Cornelius, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Edgar Baker', 'Edgar', 'Baker', NULL,
          true, true, false, true, -4115553)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Councilor', 'OR', 'Cornelius', true, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4115550'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Councilor Edén López (-4115554) — APPOINTED April 2023, term through Dec 2026 (Tigard 1159
-- appointed-seat shape: is_appointed=true on the politician AND is_appointed_position=true on
-- the office). First accented officeholder name in the Washington County chain — accented
-- literals below, file saved UTF-8 without a byte-order mark.
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Cornelius, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Edén López', 'Edén', 'López', NULL,
          true, true, false, true, -4115554)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Councilor', 'OR', 'Cornelius', true, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4115550'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- VACANT 5th councilor seat (TX-23 precedent, migration 105) — office-ONLY row, politician_id
-- NULL, is_vacant=true, is_appointed_position=false. NO politician row is created. external_id
-- -4115555 is intentionally UNUSED (mirrors the TX-23 unused-external_id convention) — do NOT
-- assign it to any politician row.
-- PITFALL GUARD: Citlalli Nunez-Barragan is stale alt-text on a leftover city-site image and is
-- NOT a current or former member per the Wave-0 live roster re-fetch. She must NEVER be seated
-- here or anywhere else in this migration — a fabricated name on this seat would violate D-13.
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Cornelius, Oregon, US')
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       NULL,
       'Councilor', 'OR', 'Cornelius', false, true, NULL
FROM essentials.districts d
WHERE d.geo_id = '4115550'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM chamber)
      AND o.title = 'Councilor'
      AND o.is_vacant = true
  );

-- office_id back-fill — explicit IN list of the 4 FILLED seats only (the vacant seat has no
-- politician to back-fill), idempotent.
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id IN (-4115551,-4115552,-4115553,-4115554)
  AND p.office_id IS NULL;

-- Post-verification DO block: gov/office counts, a STRENGTHENED independent geofence-name-match
-- assertion (this phase's Pitfall 1 — the Coquille trap), the canonical section-split query, the
-- office_id back-fill check, representing_city coverage, the vacant-office assertion, the
-- appointed-seat assertion, and the D-15 WR-B pairwise (external_id, full_name) identity gate.
DO $$
DECLARE
  v_gov_count       INTEGER;
  v_office_count    INTEGER;
  v_split_count     INTEGER;
  v_null_count      INTEGER;
  v_repcity_count   INTEGER;
  v_geofence_count  INTEGER;
  v_pair_count      INTEGER;
  v_vacant_count    INTEGER;
  v_appointed_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_gov_count FROM essentials.governments
  WHERE name = 'City of Cornelius, Oregon, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Cornelius gov_count=%, expected 1', v_gov_count;
  END IF;

  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '4115550' AND d.district_type IN ('LOCAL','LOCAL_EXEC') AND d.state = 'or';
  IF v_office_count <> 5 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Cornelius office_count=%, expected 5', v_office_count;
  END IF;

  -- STRENGTHENED independent geofence assertion — checks the NAME matches 'Cornelius city',
  -- not just presence, to catch the 4115350/Coquille trap (this phase's Pitfall 1).
  SELECT COUNT(*) INTO v_geofence_count
  FROM essentials.geofence_boundaries
  WHERE geo_id = '4115550' AND mtfcc = 'G4110' AND name = 'Cornelius city';
  IF v_geofence_count < 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: no G4110 geofence row named ''Cornelius city'' found for geo_id 4115550 — check for the 4115350/Coquille trap';
  END IF;

  -- Canonical section-split query (GROUP BY / HAVING), independent of the INSERTs above.
  SELECT COUNT(*) INTO v_split_count
  FROM (
    SELECT o.district_id
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.geo_id = '4115550'
    GROUP BY o.district_id
    HAVING COUNT(DISTINCT o.chamber_id) > 1
  ) x;
  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % rows', v_split_count;
  END IF;

  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id IN (-4115551,-4115552,-4115553,-4115554)
    AND office_id IS NULL;
  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians still have NULL office_id after back-fill', v_null_count;
  END IF;

  SELECT COUNT(*) INTO v_repcity_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '4115550' AND d.district_type IN ('LOCAL','LOCAL_EXEC') AND d.state = 'or'
    AND o.representing_city = 'Cornelius';
  IF v_repcity_count <> 5 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % of 5 Cornelius offices have representing_city=Cornelius', v_repcity_count;
  END IF;

  -- Vacant-office assertion (TX-23 precedent) — exactly 1 office row with is_vacant=true AND
  -- politician_id IS NULL for the Cornelius chamber.
  SELECT COUNT(*) INTO v_vacant_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '4115550' AND d.district_type IN ('LOCAL','LOCAL_EXEC') AND d.state = 'or'
    AND o.is_vacant = true AND o.politician_id IS NULL;
  IF v_vacant_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: vacant_office=%, expected exactly 1', v_vacant_count;
  END IF;

  -- Appointed-seat assertion — exactly 2 offices with is_appointed_position=true (Baker + Lopez).
  SELECT COUNT(*) INTO v_appointed_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '4115550' AND d.district_type IN ('LOCAL','LOCAL_EXEC') AND d.state = 'or'
    AND o.is_appointed_position = true;
  IF v_appointed_count <> 2 THEN
    RAISE EXCEPTION 'Post-verification FAILED: appointed_positions=%, expected exactly 2', v_appointed_count;
  END IF;

  -- D-15 WR-B pairwise (external_id, full_name) identity gate — a name/id transposition on an
  -- ON CONFLICT (external_id) DO UPDATE re-run path cannot silently pass this assertion.
  SELECT COUNT(*) INTO v_pair_count
  FROM essentials.politicians
  WHERE (external_id, full_name) IN (
    (-4115551, 'Jeffrey C. Dalin'), (-4115552, 'Angeles Godinez Valencia'),
    (-4115553, 'Edgar Baker'), (-4115554, 'Edén López')
  );
  IF v_pair_count <> 4 THEN
    RAISE EXCEPTION 'Post-verification FAILED: pairwise identity gate — expected 4 exact (external_id, full_name) matches, found %', v_pair_count;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: Cornelius gov=1, offices=5, geofence_name_match>=1, section-split=0, office_id nulls=0, representing_city=5, vacant_office=1, appointed_positions=2, pairwise_identity=4';
END $$;

-- Ledger entry — structural migrations register.
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('1196')
ON CONFLICT (version) DO NOTHING;

COMMIT;
