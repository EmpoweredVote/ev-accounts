-- Migration 270: MD State Executives (Moore, Miller, Brown, Lierman, Davis)
--
-- Seeds 5 STATE_EXEC districts, 5 politicians, 5 offices, and back-fills
-- office_id on all 5 politicians.
--
-- Decision context:
--   D-01: LG Aruna Miller gets a standalone chamber ("Lieutenant Governor")
--         and a standalone STATE_EXEC district ("Maryland Lieutenant Governor").
--         She is NOT modeled under the Governor's chamber. 5 separate chambers
--         and 5 separate STATE_EXEC districts.
--   D-02: Dereck Davis (State Treasurer) is seeded in this phase — not deferred.
--         Consistent with ME migration 169 and OR migration 223 pattern (all
--         appointed officials seeded at chamber-creation time).
--   D-03: Dereck Davis is_appointed=true on his politician row and
--         is_appointed_position=true on his office row. He is elected by the
--         General Assembly, not by voters — same as ME Treasurer/AG/SoS.
--         He is the ONLY one of the 5 with is_appointed=true.
--
-- STATE_EXEC casing requirement:
--   All STATE_EXEC districts must use state='MD' (uppercase postal abbreviation).
--   OR migration 223 initially used 'or' (lowercase) and required migration 223a
--   to fix it — lowercase STATE_EXEC state silently breaks backend routing because
--   the backend queries districts with WHERE state='MD', not 'md'.
--   CONFIRMED: All 28 existing STATE_EXEC rows in production use uppercase.
--
-- MD FIPS = 24; geo_id='24'; geo_id applies to all 5 STATE_EXEC districts.
-- external_id range: -240005..-240001 (FIPS-prefix pattern: -24XXXX)
--
-- Chamber names are created by migration 269 (Plan 01):
--   'Governor', 'Lieutenant Governor', 'Attorney General', 'Comptroller', 'State Treasurer'
--   All under government_id = (State of Maryland, state='MD').
--
-- role_canonical is set NULL for all 5 (cross-state mapping deferred).
--
-- All inserts are idempotent (WHERE NOT EXISTS / ON CONFLICT DO NOTHING).

BEGIN;

-- ===== Pre-flight: assert State of Maryland government row exists =====
-- Migration 174 seeded the MD government row as a bulk 50-state stub.
-- This migration must NOT insert it — assert exactly 1 row exists.
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'State of Maryland' AND state = 'MD') <> 1 THEN
    RAISE EXCEPTION
      'Pre-flight failed: expected exactly 1 State of Maryland government row; found %',
      (SELECT COUNT(*) FROM essentials.governments
       WHERE name = 'State of Maryland' AND state = 'MD');
  END IF;
END $$;

-- ===== STEP 1: Create 5 STATE_EXEC districts (one per executive office) =====
-- CRITICAL: state='MD' uppercase — lowercase 'md' breaks routing (OR 223a lesson).
-- district_id='' (empty string) — OR 223a confirmed the OR pattern of using
--   a descriptive district_id was wrong; '' is the correct multi-position district value.
-- mtfcc='' — no TIGER MTFCC applies to executive office districts.

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'MD', '24', 'Maryland Governor', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'MD' AND label = 'Maryland Governor'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'MD', '24', 'Maryland Lieutenant Governor', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'MD' AND label = 'Maryland Lieutenant Governor'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'MD', '24', 'Maryland Attorney General', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'MD' AND label = 'Maryland Attorney General'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'MD', '24', 'Maryland Comptroller', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'MD' AND label = 'Maryland Comptroller'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'MD', '24', 'Maryland State Treasurer', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'MD' AND label = 'Maryland State Treasurer'
);

-- ===== STEP 2: Politicians + Offices (one CTE block per executive) =====
-- Pattern: WITH ins_p AS (INSERT ... ON CONFLICT DO NOTHING RETURNING id)
--          INSERT INTO offices ... SELECT ... FROM districts CROSS JOIN ins_p
--          WHERE p.id IS NOT NULL (guards against DO NOTHING returning nothing)
--          AND NOT EXISTS (SELECT 1 FROM offices WHERE district_id=... AND chamber_id=...)
--
-- Chamber name lookup: use short name ('Governor', 'Lieutenant Governor', etc.) +
-- government_id subquery for 'State of Maryland' AND state='MD'. This is the OR convention.
--
-- representing_state='MD' for all 5 offices.

-- ----- Governor: Wes Moore (-240001) — VOTER-ELECTED -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Wes Moore', 'Wes', 'Moore', 'Democrat',
          true, false, false, true, -240001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Governor'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Maryland' AND state = 'MD')),
       p.id,
       'Governor', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'MD' AND d.label = 'Maryland Governor'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'Governor'
                            AND government_id = (SELECT id FROM essentials.governments
                                                 WHERE name = 'State of Maryland' AND state = 'MD'))
  );

-- ----- Lieutenant Governor: Aruna Miller (-240002) — VOTER-ELECTED (D-01: standalone) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Aruna Miller', 'Aruna', 'Miller', 'Democrat',
          true, false, false, true, -240002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Lieutenant Governor'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Maryland' AND state = 'MD')),
       p.id,
       'Lieutenant Governor', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'MD' AND d.label = 'Maryland Lieutenant Governor'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'Lieutenant Governor'
                            AND government_id = (SELECT id FROM essentials.governments
                                                 WHERE name = 'State of Maryland' AND state = 'MD'))
  );

-- ----- Attorney General: Anthony G. Brown (-240003) — VOTER-ELECTED -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Anthony G. Brown', 'Anthony', 'Brown', 'Democrat',
          true, false, false, true, -240003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Attorney General'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Maryland' AND state = 'MD')),
       p.id,
       'Attorney General', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'MD' AND d.label = 'Maryland Attorney General'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'Attorney General'
                            AND government_id = (SELECT id FROM essentials.governments
                                                 WHERE name = 'State of Maryland' AND state = 'MD'))
  );

-- ----- Comptroller: Brooke Lierman (-240004) — VOTER-ELECTED -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brooke Lierman', 'Brooke', 'Lierman', 'Democrat',
          true, false, false, true, -240004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Comptroller'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Maryland' AND state = 'MD')),
       p.id,
       'Comptroller', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'MD' AND d.label = 'Maryland Comptroller'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'Comptroller'
                            AND government_id = (SELECT id FROM essentials.governments
                                                 WHERE name = 'State of Maryland' AND state = 'MD'))
  );

-- ----- State Treasurer: Dereck E. Davis (-240005) — LEGISLATURE-ELECTED (D-02 + D-03) -----
-- D-03: is_appointed=true on politician row; is_appointed_position=true on office row.
-- Davis was elected by the Maryland General Assembly in January 2023.
-- He is the ONLY one of the 5 executives with is_appointed=true.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dereck E. Davis', 'Dereck', 'Davis', 'Democrat',
          true, true, false, true, -240005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Treasurer'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Maryland' AND state = 'MD')),
       p.id,
       'State Treasurer', 'MD', true, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'MD' AND d.label = 'Maryland State Treasurer'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'State Treasurer'
                            AND government_id = (SELECT id FROM essentials.governments
                                                 WHERE name = 'State of Maryland' AND state = 'MD'))
  );

-- ===== STEP 3: office_id back-fill =====
-- Scoped to -240010..-240001 to cover any future MD execs in the same range.
-- Guard with p.office_id IS NULL for idempotency (re-run = 0 rows affected).

UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -240010 AND -240001
  AND p.office_id IS NULL;

COMMIT;
