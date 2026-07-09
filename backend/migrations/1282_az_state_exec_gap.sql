-- 1282_az_state_exec_gap.sql
-- Phase 191 (AZ-STATE-01): Close the Arizona STATE_EXEC gap.
-- STRUCTURAL migration (registers in supabase_migrations.schema_migrations). Idempotent.
-- State of Arizona government: id=15436f29-38d2-4cc0-8958-9e74ba60fabf, geo_id='04'
--
-- DB-verified 2026-07-08: 4 of 11 STATE_EXEC officials exist (Governor Katie Hobbs -400091,
--   Attorney General Kris Mayes -400092, Secretary of State Adrian Fontes -400093, Treasurer
--   Kimberly Yee -400094) — these 4 politicians/chambers/districts/offices MUST NOT be
--   re-created or modified by this migration.
--
-- This migration creates the remaining 7 statewide elected officials:
--   STEP 1 — Superintendent of Public Instruction: Tom Horne (-4004001)
--   STEP 2 — State Mine Inspector: Les Presmyk (-4004002) [see Pitfall 3 note below]
--   STEP 3 — Arizona Corporation Commission (5-member collegial body, ONE shared
--            STATE_EXEC district + ONE shared chamber): Nick Myers (-4004003, Chair),
--            Rachel Walden (-4004004, Vice Chair), Lea Márquez Peterson (-4004005),
--            Kevin Thompson (-4004006), René Lopez (-4004007)
--   STEP 4 — office_id back-fill for all 7 new politicians
--
-- CRITICAL: the chambers generated-identifier (path) column is GENERATED ALWAYS — never
--   include it in the INSERT column list.
-- CRITICAL: districts.state = 'AZ' UPPERCASE for STATE_EXEC tier — lowercase silently
--   breaks backend routing (the OR-223a / NV lesson). geo_id='04' always.
-- CRITICAL (Pitfall 1): external_id range -4004001..-4004007 was verified FREE via live
--   psql immediately before this migration was written — do NOT continue the naive
--   "-400095" AZ pool (collides with an actively-growing shared national candidate pool).
-- CRITICAL (Pitfall 3 — Mine Inspector): Arizona's mine inspector office is the only
--   directly-elected mine-inspector post in the US — offices.is_appointed_position=false
--   (the OFFICE TYPE is elected). The CURRENT HOLDER, Les Presmyk, personally arrived via
--   a mid-term gubernatorial appointment (filling a vacancy left by Paul Marsh) — so
--   politicians.is_appointed=true on HIS row only. Do NOT flip is_appointed_position to
--   true (that would incorrectly recategorize the office itself as legislature/governor
--   appointed, unlike MD's Dereck Davis Treasurer case where the OFFICE is
--   legislature-elected). A future audit must not "fix" either flag in either direction.
-- CRITICAL (Corporation Commission office guard): the 5 commissioner offices all share
--   the SAME district_id AND the SAME chamber_id — a guard on (district_id, chamber_id)
--   alone would suppress inserts for commissioners #2-5 after #1 succeeds. Each Corp
--   Commission office block below guards on (district_id, politician_id), mirroring
--   1055_clark_county_commission.sql's per-commissioner guard shape.

BEGIN;

-- =============================================================================
-- Pre-flight assertions
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE geo_id = '04') <> 1 THEN
    RAISE EXCEPTION
      'Pre-flight failed: expected exactly 1 State of Arizona government row (geo_id=04); found %',
      (SELECT COUNT(*) FROM essentials.governments WHERE geo_id = '04');
  END IF;

  IF (SELECT COUNT(*) FROM essentials.politicians
      WHERE external_id IN (-400091, -400092, -400093, -400094)) <> 4 THEN
    RAISE EXCEPTION
      'Pre-flight failed: expected 4 pre-existing AZ STATE_EXEC officials (Hobbs/Mayes/Fontes/Yee); found %. These MUST NOT be re-created — investigate before proceeding.',
      (SELECT COUNT(*) FROM essentials.politicians WHERE external_id IN (-400091, -400092, -400093, -400094));
  END IF;
END $$;

-- =============================================================================
-- STEP 1: Superintendent of Public Instruction — Tom Horne (-4004001), VOTER-ELECTED
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'AZ', '04', 'Arizona Superintendent of Public Instruction', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'AZ' AND label = 'Arizona Superintendent of Public Instruction'
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Superintendent of Public Instruction',
       'Arizona Superintendent of Public Instruction',
       (SELECT id FROM essentials.governments WHERE geo_id = '04')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Superintendent of Public Instruction'
    AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')
);

WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tom Horne', 'Tom', 'Horne', 'Republican',
          true, false, false, true, -4004001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Superintendent of Public Instruction'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'Superintendent of Public Instruction', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'AZ' AND d.label = 'Arizona Superintendent of Public Instruction'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'Superintendent of Public Instruction'
                            AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- =============================================================================
-- STEP 2: State Mine Inspector — Les Presmyk (-4004002)
-- OFFICE is voter-elected (is_appointed_position=false) — Arizona's only directly-elected
-- mine-inspector post nationally. HOLDER Les Presmyk arrived via a mid-term gubernatorial
-- appointment filling a vacancy (predecessor Paul Marsh departed) — politicians.is_appointed=true
-- reflects ONLY his personal path to office, not the office's type. See file-header Pitfall 3.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'AZ', '04', 'Arizona State Mine Inspector', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'AZ' AND label = 'Arizona State Mine Inspector'
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'State Mine Inspector',
       'Arizona State Mine Inspector',
       (SELECT id FROM essentials.governments WHERE geo_id = '04')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'State Mine Inspector'
    AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')
);

WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Les Presmyk', 'Les', 'Presmyk', 'Republican',
          true, true, false, true, -4004002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'State Mine Inspector'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'State Mine Inspector', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'AZ' AND d.label = 'Arizona State Mine Inspector'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'State Mine Inspector'
                            AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04'))
  );

-- =============================================================================
-- STEP 3: Arizona Corporation Commission — 5-member collegial body (D-02)
-- ONE shared STATE_EXEC district + ONE shared chamber (official_count=5), all 5
-- commissioners elected statewide at-large (not by district). Office guard uses
-- (district_id, politician_id) — NOT (district_id, chamber_id) alone — so all 5
-- commissioners insert onto the same district/chamber pair (see file header note).
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'AZ', '04', 'Arizona Corporation Commission', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'AZ' AND label = 'Arizona Corporation Commission'
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'Corporation Commission',
       'Arizona Corporation Commission',
       (SELECT id FROM essentials.governments WHERE geo_id = '04'),
       5
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Corporation Commission'
    AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')
);

-- BLOCK 1: Nick Myers (-4004003) [Chair — title-on-seat, no role_canonical]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nick Myers', 'Nick', 'Myers', 'Republican',
          true, false, false, true, -4004003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Corporation Commission'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'Commissioner', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'AZ' AND d.label = 'Arizona Corporation Commission'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Rachel Walden (-4004004) [Vice Chair — title-on-seat, no role_canonical]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rachel Walden', 'Rachel', 'Walden', 'Republican',
          true, false, false, true, -4004004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Corporation Commission'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'Commissioner', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'AZ' AND d.label = 'Arizona Corporation Commission'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Lea Márquez Peterson (-4004005)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lea Márquez Peterson', 'Lea', 'Márquez Peterson', 'Republican',
          true, false, false, true, -4004005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Corporation Commission'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'Commissioner', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'AZ' AND d.label = 'Arizona Corporation Commission'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Kevin Thompson (-4004006)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kevin Thompson', 'Kevin', 'Thompson', 'Republican',
          true, false, false, true, -4004006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Corporation Commission'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'Commissioner', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'AZ' AND d.label = 'Arizona Corporation Commission'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: René Lopez (-4004007)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'René Lopez', 'René', 'Lopez', 'Republican',
          true, false, false, true, -4004007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Corporation Commission'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '04')),
       p.id,
       'Commissioner', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'AZ' AND d.label = 'Arizona Corporation Commission'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- STEP 4: office_id back-fill for the 7 net-new AZ STATE_EXEC officials
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -4004007 AND -4004001
  AND p.office_id IS NULL;

-- =============================================================================
-- Post-verification gates — roll back the whole transaction on any failure.
-- =============================================================================
DO $$
DECLARE
  v_new_pol_count INTEGER;
  v_cc_office_count INTEGER;
  v_state_exec_total INTEGER;
  v_presmyk_appointed BOOLEAN;
  v_presmyk_office_appointed BOOLEAN;
  v_split_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_new_pol_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -4004007 AND -4004001;

  IF v_new_pol_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 7 new AZ politicians (-4004001..-4004007), found %', v_new_pol_count;
  END IF;

  SELECT COUNT(*) INTO v_cc_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type = 'STATE_EXEC' AND d.state = 'AZ' AND d.label = 'Arizona Corporation Commission';

  IF v_cc_office_count <> 5 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 5 offices on the Arizona Corporation Commission district, found %', v_cc_office_count;
  END IF;

  SELECT COUNT(*) INTO v_state_exec_total
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE g.geo_id = '04' AND d.district_type = 'STATE_EXEC';

  IF v_state_exec_total <> 11 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 11 total AZ STATE_EXEC offices (4 existing + 7 new), found %', v_state_exec_total;
  END IF;

  SELECT is_appointed INTO v_presmyk_appointed
  FROM essentials.politicians WHERE external_id = -4004002;

  SELECT o.is_appointed_position INTO v_presmyk_office_appointed
  FROM essentials.offices o
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id = -4004002;

  IF v_presmyk_appointed IS DISTINCT FROM true OR v_presmyk_office_appointed IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'Post-verification FAILED: Presmyk flags incorrect — is_appointed=% (expect true), office.is_appointed_position=% (expect false)',
      v_presmyk_appointed, v_presmyk_office_appointed;
  END IF;

  SELECT COUNT(*) INTO v_split_count
  FROM (
    SELECT p.full_name, count(DISTINCT ch.government_id) as gov_count
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.state = 'AZ'
    GROUP BY p.full_name
    HAVING count(DISTINCT ch.government_id) > 1
  ) sub;

  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % rows for AZ', v_split_count;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: new_pol_count=%, cc_office_count=%, state_exec_total=%, presmyk_ok=true, split_orphans=%',
    v_new_pol_count, v_cc_office_count, v_state_exec_total, v_split_count;
END $$;

COMMIT;

-- =============================================================================
-- Structural registration (OUTSIDE the transaction block)
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1282', 'az_state_exec_gap')
ON CONFLICT (version) DO NOTHING;
