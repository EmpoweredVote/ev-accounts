-- Migration 223: 5 OR Constitutional Officers + 1 STATE_EXEC district
--
-- Purpose: Seeds Oregon's 5 voter-elected constitutional officers as
-- essentials.politicians, creates the shared STATE_EXEC district (geo_id='41',
-- label='Oregon (Statewide)'), and links each politician to a chamber+district
-- via an essentials.offices row.
--
-- CRITICAL CORRECTIONS vs. original phase description:
--   - Secretary of State is Tobias Read (NOT LaVonne Griffin-Valade, who left
--     office January 6, 2025).
--   - Treasurer official name is 'Elizabeth Steiner' (NOT 'Elizabeth Steiner
--     Hayward' — use the government's own name per oregon.gov/treasury).
--
-- Migration number: 223 (follows 222_or_government_chambers.sql; next is 224)
--
-- Idempotency: all INSERTs are guarded:
--   - Politician: ON CONFLICT (external_id) DO NOTHING
--   - District: WHERE NOT EXISTS on (district_type='STATE_EXEC', state='or', geo_id='41')
--   - Office: WHERE NOT EXISTS on (district_id, chamber_id)
--   - office_id back-fill: WHERE office_id IS NULL (safe re-run)
--
-- is_appointed_position=false on ALL 5 offices — all OR constitutional officers
-- are popularly elected by voters (unlike ME where AG/SoS/Treasurer were
-- legislature-elected). Confirmed per Phase 73-01-SUMMARY.md key-decisions (D-03).
--
-- Officials seeded (external_id / full_name / chamber):
--   -4100001 / Tina Kotek          / Governor
--   -4100002 / Dan Rayfield        / Attorney General
--   -4100003 / Tobias Read         / Secretary of State   ← corrected from Griffin-Valade
--   -4100004 / Elizabeth Steiner   / State Treasurer       ← NOT 'Elizabeth Steiner Hayward'
--   -4100005 / Christina Stephenson / Labor Commissioner

BEGIN;

-- ===== STEP 1: Assert State of Oregon government row exists exactly once =====
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'State of Oregon' AND state = 'OR') <> 1 THEN
    RAISE EXCEPTION
      'Pre-flight failed: expected exactly 1 State of Oregon government row; found %',
      (SELECT COUNT(*) FROM essentials.governments
       WHERE name = 'State of Oregon' AND state = 'OR');
  END IF;
END $$;

-- ===== STEP 2: Insert STATE_EXEC district (shared by all 5 executives) =====
-- state='OR' uppercase (matches all other STATE_EXEC rows: CA, IN, MA, ME, TX, UT).
-- district_id='' empty string (matches MA/ME/TX multi-position STATE_EXEC pattern).
-- NOTE: Original migration applied with state='or'/district_id='Oregon (Statewide)';
-- corrected in production via migration 223a_or_executive_district_fix.
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'OR', '41', 'Oregon (Statewide)', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC'
    AND state = 'OR'
    AND geo_id = '41'
);

-- ===== STEP 3: Insert politicians + offices (one CTE block per executive) =====

-- ----- 3a: Governor — Tina Kotek (-4100001) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tina Kotek', 'Tina', 'Kotek', 'Democrat',
          true, false, false, true, -4100001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT c.id FROM essentials.chambers c
        WHERE c.name = 'Governor'
          AND c.government_id = (SELECT id FROM essentials.governments
                                  WHERE name = 'State of Oregon' AND state = 'OR')),
       p.id,
       'Governor', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'or' AND d.geo_id = '41'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT c.id FROM essentials.chambers c
                          WHERE c.name = 'Governor'
                            AND c.government_id = (SELECT id FROM essentials.governments
                                                    WHERE name = 'State of Oregon' AND state = 'OR'))
  );

-- ----- 3b: Attorney General — Dan Rayfield (-4100002) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dan Rayfield', 'Dan', 'Rayfield', 'Democrat',
          true, false, false, true, -4100002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT c.id FROM essentials.chambers c
        WHERE c.name = 'Attorney General'
          AND c.government_id = (SELECT id FROM essentials.governments
                                  WHERE name = 'State of Oregon' AND state = 'OR')),
       p.id,
       'Attorney General', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'or' AND d.geo_id = '41'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT c.id FROM essentials.chambers c
                          WHERE c.name = 'Attorney General'
                            AND c.government_id = (SELECT id FROM essentials.governments
                                                    WHERE name = 'State of Oregon' AND state = 'OR'))
  );

-- ----- 3c: Secretary of State — Tobias Read (-4100003) -----
-- CORRECTED: Griffin-Valade left office 2025-01-06; Tobias Read elected Nov 2024,
-- took office Jan 6 2025. Full_name='Tobias Read' (NOT 'LaVonne Griffin-Valade').
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tobias Read', 'Tobias', 'Read', 'Democrat',
          true, false, false, true, -4100003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT c.id FROM essentials.chambers c
        WHERE c.name = 'Secretary of State'
          AND c.government_id = (SELECT id FROM essentials.governments
                                  WHERE name = 'State of Oregon' AND state = 'OR')),
       p.id,
       'Secretary of State', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'or' AND d.geo_id = '41'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT c.id FROM essentials.chambers c
                          WHERE c.name = 'Secretary of State'
                            AND c.government_id = (SELECT id FROM essentials.governments
                                                    WHERE name = 'State of Oregon' AND state = 'OR'))
  );

-- ----- 3d: State Treasurer — Elizabeth Steiner (-4100004) -----
-- Official name is 'Elizabeth Steiner' per oregon.gov/treasury.
-- Do NOT use 'Elizabeth Steiner Hayward' (Ballotpedia variant).
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Elizabeth Steiner', 'Elizabeth', 'Steiner', 'Democrat',
          true, false, false, true, -4100004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT c.id FROM essentials.chambers c
        WHERE c.name = 'State Treasurer'
          AND c.government_id = (SELECT id FROM essentials.governments
                                  WHERE name = 'State of Oregon' AND state = 'OR')),
       p.id,
       'State Treasurer', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'or' AND d.geo_id = '41'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT c.id FROM essentials.chambers c
                          WHERE c.name = 'State Treasurer'
                            AND c.government_id = (SELECT id FROM essentials.governments
                                                    WHERE name = 'State of Oregon' AND state = 'OR'))
  );

-- ----- 3e: Labor Commissioner — Christina Stephenson (-4100005) -----
-- Chamber name='Labor Commissioner' (as seeded in migration 222).
-- Office title='Labor Commissioner' (consistent with chamber name).
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Christina Stephenson', 'Christina', 'Stephenson', 'Democrat',
          true, false, false, true, -4100005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT c.id FROM essentials.chambers c
        WHERE c.name = 'Labor Commissioner'
          AND c.government_id = (SELECT id FROM essentials.governments
                                  WHERE name = 'State of Oregon' AND state = 'OR')),
       p.id,
       'Labor Commissioner', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'or' AND d.geo_id = '41'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT c.id FROM essentials.chambers c
                          WHERE c.name = 'Labor Commissioner'
                            AND c.government_id = (SELECT id FROM essentials.governments
                                                    WHERE name = 'State of Oregon' AND state = 'OR'))
  );

-- ===== STEP 4: office_id back-fill =====
-- Scoped to external_id BETWEEN -4100099 AND -4100001 (the 5 OR constitutional
-- officers seeded above, with headroom for future additions in this range).
-- Guard with p.office_id IS NULL for idempotency.
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -4100099 AND -4100001
  AND p.office_id IS NULL;

COMMIT;
