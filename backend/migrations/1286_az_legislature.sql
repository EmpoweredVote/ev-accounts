-- 1286_az_legislature.sql
-- Phase 192 (AZ-LEG-01): Seed the full 90-member 57th Arizona Legislature (2025-26 biennium,
-- the CURRENT sitting session as of the 2026-07-08 research date — see 192-RESEARCH.md Pitfall 2
-- re: the stale "56th" label elsewhere in this phase's planning docs; the roster below IS the 57th).
-- STRUCTURAL migration (registers in supabase_migrations.schema_migrations). Idempotent.
-- State of Arizona government: id=15436f29-38d2-4cc0-8958-9e74ba60fabf, geo_id='04'
--
-- Greenfield: 0 legislative chambers/offices/politicians exist under geo_id='04' today
-- (AZ 191 seeded only the 7 STATE_EXEC chambers). This migration creates:
--   - 2 chambers: State Senate (name_formal 'Arizona State Senate'),
--                 House of Representatives (name_formal 'Arizona House of Representatives')
--   - 30 Senate offices, 1 per SLDU district (LD 1-30), external_id -4005001..-4005030
--   - 60 House offices, 2 per SLDL district (LD 1-30), external_id -4006001..-4006060
--   - office_id back-fill for all 90 new politicians
--   - post-verify DO gate (6 assertions) that rolls back the whole transaction on any failure
--
-- CRITICAL: the chambers generated-identifier (path) column is GENERATED ALWAYS — never
--   include it in the INSERT column list.
-- CRITICAL: legislative districts use LOWERCASE state='az' (TIGER convention for this tier) —
--   this DIVERGES from 1282's STATE_EXEC-tier uppercase 'AZ'. Do not copy that casing here.
-- CRITICAL: SLDU and SLDL SHARE the geo_id space (both 04001..04030) — district_type is
--   MANDATORY in every office<->district WHERE, or a join will double-match and silently
--   mislink senators onto house districts (and vice versa).
-- CRITICAL (D-01 / House 2-per-district guard divergence): each of the 60 House office INSERTs
--   MUST guard the collegial (district_id, politician_id) pair — NOT the (district_id,
--   chamber_id) pair — because both reps of a district legitimately share the same district_id AND
--   chamber_id. A (district_id, chamber_id) guard would silently no-op the 2nd rep's INSERT.
--   This mirrors the collegial-body guard AZ 191 already established for the 5-seat Corporation
--   Commission (1282_az_state_exec_gap.sql, BLOCK 1-5). Senate offices are 1-per-district, so the
--   simpler (district_id, chamber_id) guard is correct and sufficient there.
-- CRITICAL (mid-term successors, D-02): 3 seats had a resignation this session, each already
--   filled by a sitting successor (0 genuine vacancies) — seed ONLY the successor, never the
--   departed member:
--     - SD-9:  Kiana Sears (-4005009)   replaces Eva Burch (NOT seeded)
--     - HD-3:  Cody Reim   (-4006006)   replaces Joseph Chaplik (NOT seeded)
--     - HD-7:  Sylvia Allen(-4006013)   replaces David Marshall Sr. (NOT seeded)
--   Each successor's POLITICIAN row gets is_appointed=true (their personal path to the seat);
--   the OFFICE row keeps is_appointed_position=false (the seat itself remains directly elected);
--   is_incumbent=true, is_active=true — mirrors Les Presmyk's flag combination in 1282.
-- CRITICAL (ext_id range): -4005001..-4005030 (Senate) and -4006001..-4006060 (House) were
--   verified FREE via live psql immediately before this migration was authored (192-RESEARCH.md
--   "ext_id range" — full sweep -4006999..-4005001 returned 0 rows). Do not reuse NV's own
--   -3203xxx/-3204xxx literals (those are NV's own legislators, not a transplantable template).
-- CRITICAL (accented surnames): Márquez, Gabaldón, Peña, Luna-Nájera, Quantá are UTF-8 literals
--   in this file (not percent-encoded — percent-encoding only matters for the headshot fetch
--   URLs in Plan 02, not for SQL string literals here).
-- CRITICAL (D-01 no seat labels): both House offices per district use the identical title
--   'State Representative' — no Seat A/B, no post number, no normalized_position_name value
--   invented for disambiguation (role_canonical + normalized_position_name left NULL, matching
--   NV 160 precedent).

BEGIN;

-- =============================================================================
-- Pre-flight assertions
-- =============================================================================
DO $$
DECLARE
  v_gov_count INTEGER;
  v_chamber_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_gov_count
  FROM essentials.governments
  WHERE geo_id = '04';

  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected exactly 1 State of Arizona government row (geo_id=04); found %', v_gov_count;
  END IF;

  SELECT COUNT(*) INTO v_chamber_count
  FROM essentials.chambers c
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.geo_id = '04'
    AND (c.name ILIKE '%senate%' OR c.name ILIKE '%house%' OR c.name ILIKE '%representative%');

  IF v_chamber_count <> 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected greenfield (0 legislative chambers) under geo_id=04; found %. Investigate before proceeding.', v_chamber_count;
  END IF;
END $$;

-- =============================================================================
-- Chambers: State Senate + House of Representatives (idempotent)
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'State Senate',
       'Arizona State Senate',
       (SELECT id FROM essentials.governments WHERE geo_id = '04')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'State Senate'
    AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'House of Representatives',
       'Arizona House of Representatives',
       (SELECT id FROM essentials.governments WHERE geo_id = '04')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'House of Representatives'
    AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')
);

-- =============================================================================
-- SENATE: 30 offices, 1 per SLDU district (LD 1-30), external_id -4005001..-4005030
-- Guard on (district_id, chamber_id) is correct here (1 officeholder per district).
-- =============================================================================

-- LD-1 (04001): Mark Finchem (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mark Finchem', 'Mark', 'Finchem', 'Republican',
          true, false, false, true, -4005001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04001' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-2 (04002): Shawnna Bolick (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Shawnna Bolick', 'Shawnna', 'Bolick', 'Republican',
          true, false, false, true, -4005002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04002' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-3 (04003): John Kavanagh (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Kavanagh', 'John', 'Kavanagh', 'Republican',
          true, false, false, true, -4005003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04003' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-4 (04004): Carine Werner (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Carine Werner', 'Carine', 'Werner', 'Republican',
          true, false, false, true, -4005004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04004' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-5 (04005): Lela Alston (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lela Alston', 'Lela', 'Alston', 'Democratic',
          true, false, false, true, -4005005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04005' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-6 (04006): Theresa Hatathlie (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Theresa Hatathlie', 'Theresa', 'Hatathlie', 'Democratic',
          true, false, false, true, -4005006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04006' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-7 (04007): Wendy Rogers (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Wendy Rogers', 'Wendy', 'Rogers', 'Republican',
          true, false, false, true, -4005007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04007' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-8 (04008): Lauren Kuby (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lauren Kuby', 'Lauren', 'Kuby', 'Democratic',
          true, false, false, true, -4005008)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04008' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-9 (04009): Kiana Sears (Democratic) — MID-TERM APPOINTEE (Maricopa Co. Bd. of Supervisors,
-- ~Mar 2025), replacing Eva Burch (resigned, NOT seeded). is_appointed=true on politician;
-- office is_appointed_position stays false (the seat is directly elected).
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kiana Sears', 'Kiana', 'Sears', 'Democratic',
          true, true, false, true, -4005009)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04009' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-10 (04010): David C. Farnsworth (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David C. Farnsworth', 'David C.', 'Farnsworth', 'Republican',
          true, false, false, true, -4005010)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04010' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-11 (04011): Catherine Miranda (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Catherine Miranda', 'Catherine', 'Miranda', 'Democratic',
          true, false, false, true, -4005011)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04011' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-12 (04012): Denise "Mitzi" Epstein (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Denise "Mitzi" Epstein', 'Denise "Mitzi"', 'Epstein', 'Democratic',
          true, false, false, true, -4005012)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04012' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-13 (04013): J.D. Mesnard (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'J.D. Mesnard', 'J.D.', 'Mesnard', 'Republican',
          true, false, false, true, -4005013)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04013' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-14 (04014): Warren Petersen (Republican) — President
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Warren Petersen', 'Warren', 'Petersen', 'Republican',
          true, false, false, true, -4005014)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04014' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-15 (04015): Jake Hoffman (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jake Hoffman', 'Jake', 'Hoffman', 'Republican',
          true, false, false, true, -4005015)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04015' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-16 (04016): Thomas "T.J." Shope (Republican) — President Pro Tempore
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Thomas "T.J." Shope', 'Thomas "T.J."', 'Shope', 'Republican',
          true, false, false, true, -4005016)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04016' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-17 (04017): Venden "Vince" Leach (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Venden "Vince" Leach', 'Venden "Vince"', 'Leach', 'Republican',
          true, false, false, true, -4005017)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04017' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-18 (04018): Priya Sundareshan (Democratic) — Minority Leader
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Priya Sundareshan', 'Priya', 'Sundareshan', 'Democratic',
          true, false, false, true, -4005018)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04018' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-19 (04019): David Gowan (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David Gowan', 'David', 'Gowan', 'Republican',
          true, false, false, true, -4005019)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04019' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-20 (04020): Sally Ann Gonzales (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sally Ann Gonzales', 'Sally Ann', 'Gonzales', 'Democratic',
          true, false, false, true, -4005020)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04020' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-21 (04021): Rosanna Gabaldón (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rosanna Gabaldón', 'Rosanna', 'Gabaldón', 'Democratic',
          true, false, false, true, -4005021)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04021' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-22 (04022): Eva Diaz (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Eva Diaz', 'Eva', 'Diaz', 'Democratic',
          true, false, false, true, -4005022)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04022' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-23 (04023): Brian Fernandez (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brian Fernandez', 'Brian', 'Fernandez', 'Democratic',
          true, false, false, true, -4005023)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04023' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-24 (04024): Analise Ortiz (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Analise Ortiz', 'Analise', 'Ortiz', 'Democratic',
          true, false, false, true, -4005024)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04024' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-25 (04025): Timothy "Tim" Dunn (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Timothy "Tim" Dunn', 'Timothy "Tim"', 'Dunn', 'Republican',
          true, false, false, true, -4005025)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04025' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-26 (04026): Flavio Bravo (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Flavio Bravo', 'Flavio', 'Bravo', 'Democratic',
          true, false, false, true, -4005026)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04026' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-27 (04027): Kevin Payne (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kevin Payne', 'Kevin', 'Payne', 'Republican',
          true, false, false, true, -4005027)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04027' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-28 (04028): Frank Carroll (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Frank Carroll', 'Frank', 'Carroll', 'Republican',
          true, false, false, true, -4005028)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04028' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-29 (04029): Janae Shamp (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Janae Shamp', 'Janae', 'Shamp', 'Republican',
          true, false, false, true, -4005029)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04029' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- LD-30 (04030): Hildy Angius (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Hildy Angius', 'Hildy', 'Angius', 'Republican',
          true, false, false, true, -4005030)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Senate'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Senator', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04030' AND d.district_type = 'STATE_UPPER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                           WHERE name = 'State Senate'
                             AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- =============================================================================
-- HOUSE: 60 offices, 2 per SLDL district (LD 1-30), external_id -4006001..-4006060
-- CRITICAL: guard the collegial (district_id, politician_id) pair — NOT the
-- (district_id, chamber_id) pair — see file header. Both reps: title 'State Representative',
-- no Seat A/B (D-01).
-- =============================================================================

-- HD-1 Rep A (04001): Selina Bliss (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Selina Bliss', 'Selina', 'Bliss', 'Republican',
          true, false, false, true, -4006001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04001' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-1 Rep B (04001): Quang H Nguyen (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Quang H Nguyen', 'Quang H', 'Nguyen', 'Republican',
          true, false, false, true, -4006002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04001' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-2 Rep A (04002): Stephanie Simacek (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Stephanie Simacek', 'Stephanie', 'Simacek', 'Democratic',
          true, false, false, true, -4006003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04002' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-2 Rep B (04002): Justin Wilmeth (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Justin Wilmeth', 'Justin', 'Wilmeth', 'Republican',
          true, false, false, true, -4006004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04002' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-3 Rep A (04003): Alexander Kolodin (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Alexander Kolodin', 'Alexander', 'Kolodin', 'Republican',
          true, false, false, true, -4006005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04003' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-3 Rep B (04003): Cody Reim (Republican) — MID-TERM APPOINTEE, replaces Joseph Chaplik
-- (resigned 3/2/2026 to run for AZ CD-1, NOT seeded). is_appointed=true on politician;
-- office is_appointed_position stays false.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cody Reim', 'Cody', 'Reim', 'Republican',
          true, true, false, true, -4006006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04003' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-4 Rep A (04004): Pamela Carter (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Pamela Carter', 'Pamela', 'Carter', 'Republican',
          true, false, false, true, -4006007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04004' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-4 Rep B (04004): Matt Gress (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Matt Gress', 'Matt', 'Gress', 'Republican',
          true, false, false, true, -4006008)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04004' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-5 Rep A (04005): Sarah Liguori (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sarah Liguori', 'Sarah', 'Liguori', 'Democratic',
          true, false, false, true, -4006009)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04005' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-5 Rep B (04005): Aaron Márquez (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Aaron Márquez', 'Aaron', 'Márquez', 'Democratic',
          true, false, false, true, -4006010)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04005' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-6 Rep A (04006): Mae Peshlakai (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mae Peshlakai', 'Mae', 'Peshlakai', 'Democratic',
          true, false, false, true, -4006011)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04006' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-6 Rep B (04006): Myron Tsosie (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Myron Tsosie', 'Myron', 'Tsosie', 'Democratic',
          true, false, false, true, -4006012)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04006' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-7 Rep A (04007): Sylvia Allen (Republican) — MID-TERM APPOINTEE, replaces David Marshall Sr.
-- (resigned 4/17/2026, appointed Navajo Co. Recorder, NOT seeded). is_appointed=true on
-- politician; office is_appointed_position stays false.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sylvia Allen', 'Sylvia', 'Allen', 'Republican',
          true, true, false, true, -4006013)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04007' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-7 Rep B (04007): Walt Blackman (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Walt Blackman', 'Walt', 'Blackman', 'Republican',
          true, false, false, true, -4006014)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04007' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-8 Rep A (04008): Janeen Connolly (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Janeen Connolly', 'Janeen', 'Connolly', 'Democratic',
          true, false, false, true, -4006015)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04008' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-8 Rep B (04008): Brian Garcia (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brian Garcia', 'Brian', 'Garcia', 'Democratic',
          true, false, false, true, -4006016)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04008' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-9 Rep A (04009): Lorena Austin (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lorena Austin', 'Lorena', 'Austin', 'Democratic',
          true, false, false, true, -4006017)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04009' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-9 Rep B (04009): Seth Blattman (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Seth Blattman', 'Seth', 'Blattman', 'Democratic',
          true, false, false, true, -4006018)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04009' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-10 Rep A (04010): Ralph Heap (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ralph Heap', 'Ralph', 'Heap', 'Republican',
          true, false, false, true, -4006019)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04010' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-10 Rep B (04010): Justin Olson (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Justin Olson', 'Justin', 'Olson', 'Republican',
          true, false, false, true, -4006020)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04010' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-11 Rep A (04011): Junelle Cavero (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Junelle Cavero', 'Junelle', 'Cavero', 'Democratic',
          true, false, false, true, -4006021)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04011' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-11 Rep B (04011): Oscar De Los Santos (Democratic) — Minority Leader
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Oscar De Los Santos', 'Oscar', 'De Los Santos', 'Democratic',
          true, false, false, true, -4006022)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04011' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-12 Rep A (04012): Patty Contreras (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Patty Contreras', 'Patty', 'Contreras', 'Democratic',
          true, false, false, true, -4006023)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04012' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-12 Rep B (04012): Stacey Travers (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Stacey Travers', 'Stacey', 'Travers', 'Democratic',
          true, false, false, true, -4006024)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04012' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-13 Rep A (04013): Jeff Weninger (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jeff Weninger', 'Jeff', 'Weninger', 'Republican',
          true, false, false, true, -4006025)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04013' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-13 Rep B (04013): Julie Willoughby (Republican) — Majority Whip
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Julie Willoughby', 'Julie', 'Willoughby', 'Republican',
          true, false, false, true, -4006026)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04013' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-14 Rep A (04014): Laurin Hendrix (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Laurin Hendrix', 'Laurin', 'Hendrix', 'Republican',
          true, false, false, true, -4006027)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04014' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-14 Rep B (04014): Khyl Powell (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Khyl Powell', 'Khyl', 'Powell', 'Republican',
          true, false, false, true, -4006028)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04014' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-15 Rep A (04015): Neal Carter (Republican) — Speaker Pro Tempore
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Neal Carter', 'Neal', 'Carter', 'Republican',
          true, false, false, true, -4006029)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04015' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-15 Rep B (04015): Michael Way (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michael Way', 'Michael', 'Way', 'Republican',
          true, false, false, true, -4006030)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04015' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-16 Rep A (04016): Teresa Martinez (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Teresa Martinez', 'Teresa', 'Martinez', 'Republican',
          true, false, false, true, -4006031)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04016' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-16 Rep B (04016): Chris Lopez (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Chris Lopez', 'Chris', 'Lopez', 'Republican',
          true, false, false, true, -4006032)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04016' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-17 Rep A (04017): Rachel Keshel (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rachel Keshel', 'Rachel', 'Keshel', 'Republican',
          true, false, false, true, -4006033)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04017' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-17 Rep B (04017): Kevin Volk (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kevin Volk', 'Kevin', 'Volk', 'Democratic',
          true, false, false, true, -4006034)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04017' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-18 Rep A (04018): Nancy Gutierrez (Democratic) — Assistant Minority Leader
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nancy Gutierrez', 'Nancy', 'Gutierrez', 'Democratic',
          true, false, false, true, -4006035)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04018' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-18 Rep B (04018): Christopher Mathis (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Christopher Mathis', 'Christopher', 'Mathis', 'Democratic',
          true, false, false, true, -4006036)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04018' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-19 Rep A (04019): Lupe Diaz (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lupe Diaz', 'Lupe', 'Diaz', 'Republican',
          true, false, false, true, -4006037)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04019' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-19 Rep B (04019): Gail Griffin (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Gail Griffin', 'Gail', 'Griffin', 'Republican',
          true, false, false, true, -4006038)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04019' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-20 Rep A (04020): Alma Hernandez (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Alma Hernandez', 'Alma', 'Hernandez', 'Democratic',
          true, false, false, true, -4006039)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04020' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-20 Rep B (04020): Betty J Villegas (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Betty J Villegas', 'Betty J', 'Villegas', 'Democratic',
          true, false, false, true, -4006040)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04020' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-21 Rep A (04021): Consuelo Hernandez (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Consuelo Hernandez', 'Consuelo', 'Hernandez', 'Democratic',
          true, false, false, true, -4006041)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04021' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-21 Rep B (04021): Stephanie Stahl Hamilton (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Stephanie Stahl Hamilton', 'Stephanie', 'Stahl Hamilton', 'Democratic',
          true, false, false, true, -4006042)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04021' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-22 Rep A (04022): Lupe Contreras (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lupe Contreras', 'Lupe', 'Contreras', 'Democratic',
          true, false, false, true, -4006043)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04022' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-22 Rep B (04022): Elda Luna-Nájera (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Elda Luna-Nájera', 'Elda', 'Luna-Nájera', 'Democratic',
          true, false, false, true, -4006044)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04022' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-23 Rep A (04023): Michele Peña (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michele Peña', 'Michele', 'Peña', 'Republican',
          true, false, false, true, -4006045)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04023' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-23 Rep B (04023): Mariana Sandoval (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mariana Sandoval', 'Mariana', 'Sandoval', 'Democratic',
          true, false, false, true, -4006046)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04023' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-24 Rep A (04024): Anna Abeytia (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Anna Abeytia', 'Anna', 'Abeytia', 'Democratic',
          true, false, false, true, -4006047)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04024' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-24 Rep B (04024): Lydia Hernandez (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lydia Hernandez', 'Lydia', 'Hernandez', 'Democratic',
          true, false, false, true, -4006048)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04024' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-25 Rep A (04025): Michael Carbone (Republican) — Majority Leader
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michael Carbone', 'Michael', 'Carbone', 'Republican',
          true, false, false, true, -4006049)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04025' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-25 Rep B (04025): Nick Kupper (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nick Kupper', 'Nick', 'Kupper', 'Republican',
          true, false, false, true, -4006050)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04025' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-26 Rep A (04026): Cesar Aguilar (Democratic)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cesar Aguilar', 'Cesar', 'Aguilar', 'Democratic',
          true, false, false, true, -4006051)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04026' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-26 Rep B (04026): Quantá Crews (Democratic) — Minority Whip
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Quantá Crews', 'Quantá', 'Crews', 'Democratic',
          true, false, false, true, -4006052)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04026' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-27 Rep A (04027): Lisa Fink (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lisa Fink', 'Lisa', 'Fink', 'Republican',
          true, false, false, true, -4006053)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04027' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-27 Rep B (04027): Tony Rivero (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tony Rivero', 'Tony', 'Rivero', 'Republican',
          true, false, false, true, -4006054)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04027' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-28 Rep A (04028): David Livingston (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David Livingston', 'David', 'Livingston', 'Republican',
          true, false, false, true, -4006055)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04028' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-28 Rep B (04028): Beverly Pingerelli (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Beverly Pingerelli', 'Beverly', 'Pingerelli', 'Republican',
          true, false, false, true, -4006056)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04028' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-29 Rep A (04029): Steve Montenegro (Republican) — Speaker
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Steve Montenegro', 'Steve', 'Montenegro', 'Republican',
          true, false, false, true, -4006057)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04029' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-29 Rep B (04029): James Taylor (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'James Taylor', 'James', 'Taylor', 'Republican',
          true, false, false, true, -4006058)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04029' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-30 Rep A (04030): Leo Biasiucci (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Leo Biasiucci', 'Leo', 'Biasiucci', 'Republican',
          true, false, false, true, -4006059)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04030' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HD-30 Rep B (04030): John Gillette (Republican)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Gillette', 'John', 'Gillette', 'Republican',
          true, false, false, true, -4006060)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'House of Representatives'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Representative', 'AZ', false, false
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '04030' AND d.district_type = 'STATE_LOWER' AND d.state = 'az'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- office_id back-fill for the 90 net-new AZ legislature politicians
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -4005030 AND -4005001
  AND p.office_id IS NULL;

UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -4006060 AND -4006001
  AND p.office_id IS NULL;

-- =============================================================================
-- Post-verification gates — roll back the whole transaction on any failure.
-- =============================================================================
DO $$
DECLARE
  v_new_pol_count INTEGER;
  v_senate_office_count INTEGER;
  v_house_office_count INTEGER;
  v_house_split_count INTEGER;
  v_upper_link_count INTEGER;
  v_lower_link_count INTEGER;
  v_split_count INTEGER;
BEGIN
  -- Assertion 1: 90 new politicians in the AZ legislature ext_id block
  SELECT COUNT(*) INTO v_new_pol_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -4006060 AND -4005001;

  IF v_new_pol_count <> 90 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 90 new AZ legislature politicians (-4005001..-4006060), found %', v_new_pol_count;
  END IF;

  -- Assertion 2: 30 Senate offices
  SELECT COUNT(*) INTO v_senate_office_count
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.geo_id = '04' AND c.name = 'State Senate';

  IF v_senate_office_count <> 30 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 30 State Senate offices, found %', v_senate_office_count;
  END IF;

  -- Assertion 3: 60 House offices
  SELECT COUNT(*) INTO v_house_office_count
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.geo_id = '04' AND c.name = 'House of Representatives';

  IF v_house_office_count <> 60 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 60 House of Representatives offices, found %', v_house_office_count;
  END IF;

  -- Assertion 4: every SLDL district has exactly 2 House offices (the D-01 guard payoff)
  SELECT COUNT(*) INTO v_house_split_count
  FROM (
    SELECT o.district_id, COUNT(*) AS n
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    WHERE g.geo_id = '04' AND c.name = 'House of Representatives'
    GROUP BY o.district_id
    HAVING COUNT(*) <> 2
  ) sub;

  IF v_house_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % SLDL districts do not have exactly 2 House offices', v_house_split_count;
  END IF;

  -- Assertion 5: STATE_UPPER linkage = 30, STATE_LOWER linkage = 60, both at lowercase state='az'
  SELECT COUNT(*) INTO v_upper_link_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.state = 'az' AND d.district_type = 'STATE_UPPER';

  IF v_upper_link_count <> 30 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 30 STATE_UPPER office links at state=az, found %', v_upper_link_count;
  END IF;

  SELECT COUNT(*) INTO v_lower_link_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.state = 'az' AND d.district_type = 'STATE_LOWER';

  IF v_lower_link_count <> 60 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 60 STATE_LOWER office links at state=az, found %', v_lower_link_count;
  END IF;

  -- Assertion 6: section-split detector (no politician split across governments) = 0 rows
  SELECT COUNT(*) INTO v_split_count
  FROM (
    SELECT p.full_name, count(DISTINCT ch.government_id) as gov_count
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.state = 'az' AND d.district_type IN ('STATE_UPPER', 'STATE_LOWER')
    GROUP BY p.full_name
    HAVING count(DISTINCT ch.government_id) > 1
  ) sub;

  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % rows for AZ legislature', v_split_count;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: new_pol_count=%, senate_offices=%, house_offices=%, house_split_violations=%, upper_links=%, lower_links=%, section_split=%',
    v_new_pol_count, v_senate_office_count, v_house_office_count, v_house_split_count, v_upper_link_count, v_lower_link_count, v_split_count;
END $$;

COMMIT;

-- =============================================================================
-- Structural registration (OUTSIDE the transaction block)
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1286', 'az_legislature')
ON CONFLICT (version) DO NOTHING;
