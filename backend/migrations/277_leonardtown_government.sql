-- Migration 277: Town of Leonardtown government + Town Council chamber + LOCAL_EXEC + LOCAL districts + 6 officials + offices
--
-- Purpose: Seeds Town of Leonardtown government and Town Council under geo_id='2446475'.
--   - 1 government row: 'Town of Leonardtown, Maryland, US' (type='LOCAL', state='MD', city='Leonardtown', geo_id='2446475')
--   - 1 chamber row: 'Town Council' (name_formal='Leonardtown Town Council'; no slug — GENERATED ALWAYS)
--   - 1 LOCAL_EXEC district row: geo_id='2446475', mtfcc=NULL, state='md', district_type='LOCAL_EXEC' (Mayor)
--   - 1 LOCAL district row: geo_id='2446475', mtfcc=NULL, state='md', district_type='LOCAL' (at-large council)
--   - 6 politicians: Mayor Burris (-2446475001) + 5 Council Members (-2446475002..-2446475006)
--   - 6 offices: Mayor links to LOCAL_EXEC; 5 Council Members link to LOCAL district
--   - office_id back-fill on all 6 politicians
--
-- Geofence boundary (G4110, geo_id='2446475', state='24') was loaded in Phase 91 — do NOT re-insert.
-- Analog: migration 246 (Multnomah smaller cities — LOCAL/LOCAL_EXEC pattern).
-- Applied to production Supabase via Supabase MCP.
--
-- 2026 election confirmed (May 5, 2026): Earhart, Hollander, Slade all won re-election.
-- Roster is current as of 2026-06-05.
--
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include in INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state must be 'md' (lowercase) for LOCAL/LOCAL_EXEC to match routing queries.
-- CRITICAL: governments.state = 'MD' (uppercase) — government table convention.
-- CRITICAL: governments.type = 'LOCAL' (not 'County') for incorporated town.
-- CRITICAL: mtfcc=NULL on LOCAL and LOCAL_EXEC district rows (migration 246 pattern for incorporated places).
-- PITFALL 5: Mattingly's title is 'Council Member' — do NOT use 'Vice President' (council-chosen role, not elected).
-- PITFALL 6: Christy Hollander uses short form (not 'Christy Sterling Hollander' from 2026 ballot).

BEGIN;

-- =============================================================================
-- Pre-flight: RAISE NOTICE if government row already exists (idempotency guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'Town of Leonardtown, Maryland, US') > 0 THEN
    RAISE NOTICE 'Town of Leonardtown government row already exists — skipping government INSERT (idempotent re-run)';
  END IF;
END $$;

-- =============================================================================
-- Step 1: Government row (Town of Leonardtown, Maryland, US)
-- type='LOCAL' — incorporated town (NOT 'County')
-- state='MD' uppercase (governments table convention).
-- city='Leonardtown' (populated for LOCAL governments)
-- WHERE NOT EXISTS guard — governments has no unique constraint on (name, geo_id).
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Town of Leonardtown, Maryland, US',
       'LOCAL', 'MD', 'Leonardtown', '2446475'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Town of Leonardtown, Maryland, US'
);

-- =============================================================================
-- Step 2: Town Council chamber
-- CRITICAL: slug is GENERATED ALWAYS — never include in INSERT column list.
-- Idempotency guard: WHERE NOT EXISTS on (name, government_id).
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Town Council',
       'Leonardtown Town Council',
       (SELECT id FROM essentials.governments
        WHERE name = 'Town of Leonardtown, Maryland, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Town Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Town of Leonardtown, Maryland, US')
);

-- =============================================================================
-- Step 3a: LOCAL_EXEC district (Mayor — townwide)
-- geo_id='2446475' matches the existing G4110 geofence_boundary loaded in Phase 91.
-- state='md' LOWERCASE — matches routing query convention.
-- mtfcc=NULL — no TIGER mtfcc code for LOCAL_EXEC districts (migration 246 pattern).
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'md', '2446475', 'Leonardtown (Townwide)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2446475' AND district_type = 'LOCAL_EXEC' AND state = 'md'
);

-- =============================================================================
-- Step 3b: LOCAL district (all 5 council members share this — at-large)
-- mtfcc=NULL — no TIGER mtfcc code for LOCAL districts (migration 246 pattern).
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'md', '2446475', 'Leonardtown (At-Large)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2446475' AND district_type = 'LOCAL' AND state = 'md'
);

-- =============================================================================
-- Step 4: Politicians + offices (6 blocks — Mayor + 5 Council Members)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (antipartisan design)
-- is_appointed=false, is_appointed_position=false (all popularly elected)
-- representing_state='MD' uppercase (offices table convention)
-- Mayor office links to LOCAL_EXEC district; all council offices link to LOCAL district.
-- Idempotency: ON CONFLICT (external_id) DO NOTHING on politicians
--             WHERE NOT EXISTS (district_id, politician_id) on offices
-- =============================================================================

-- BLOCK 1: Mayor Daniel W. Burris (-2446475001) — links to LOCAL_EXEC district
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Daniel W. Burris', 'Daniel', 'Burris', NULL,
          true, false, false, true, -2446475001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Town Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Town of Leonardtown, Maryland, US')),
       p.id,
       'Mayor', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2446475'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'md'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Council Member J. Maguire Mattingly IV (-2446475002) — links to LOCAL district
-- Note: first_name='Jay' (goes by Jay Mattingly IV); title='Council Member' (NOT 'Vice President' per Pitfall 5)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'J. Maguire Mattingly IV', 'Jay', 'Mattingly', NULL,
          true, false, false, true, -2446475002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Town Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Town of Leonardtown, Maryland, US')),
       p.id,
       'Council Member', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2446475'
  AND d.district_type = 'LOCAL'
  AND d.state = 'md'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Council Member Nick B. Colvin (-2446475003) — links to LOCAL district
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nick B. Colvin', 'Nick', 'Colvin', NULL,
          true, false, false, true, -2446475003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Town Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Town of Leonardtown, Maryland, US')),
       p.id,
       'Council Member', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2446475'
  AND d.district_type = 'LOCAL'
  AND d.state = 'md'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Council Member Heather M. Earhart (-2446475004) — links to LOCAL district
-- Won re-election May 5, 2026 (188 votes)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Heather M. Earhart', 'Heather', 'Earhart', NULL,
          true, false, false, true, -2446475004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Town Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Town of Leonardtown, Maryland, US')),
       p.id,
       'Council Member', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2446475'
  AND d.district_type = 'LOCAL'
  AND d.state = 'md'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Council Member Christy Hollander (-2446475005) — links to LOCAL district
-- Per Pitfall 6: use 'Christy Hollander' (official gov website display name, not ballot name 'Christy Sterling Hollander')
-- Won re-election May 5, 2026 (202 votes)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Christy Hollander', 'Christy', 'Hollander', NULL,
          true, false, false, true, -2446475005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Town Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Town of Leonardtown, Maryland, US')),
       p.id,
       'Council Member', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2446475'
  AND d.district_type = 'LOCAL'
  AND d.state = 'md'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: Council Member Mary Maday Slade (-2446475006) — links to LOCAL district
-- Won re-election May 5, 2026 (244 votes — highest vote-getter)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mary Maday Slade', 'Mary', 'Slade', NULL,
          true, false, false, true, -2446475006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Town Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Town of Leonardtown, Maryland, US')),
       p.id,
       'Council Member', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2446475'
  AND d.district_type = 'LOCAL'
  AND d.state = 'md'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Updates politicians.office_id for all 6 Leonardtown officials.
-- WHERE p.office_id IS NULL for idempotency.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -2446475006 AND -2446475001
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block
-- Raises EXCEPTION on any failure — rolls back the transaction.
-- Gate (a): government row count must be exactly 1
-- Gate (b): offices linked to ANY district with geo_id='2446475' AND state='md' must be exactly 6
--   (covers both LOCAL_EXEC Mayor office + 5 LOCAL council offices)
-- Gate (c): section-split detector must return 0 orphan rows
-- =============================================================================
DO $$
DECLARE
  v_gov_count INTEGER;
  v_office_count INTEGER;
  v_split_count INTEGER;
BEGIN
  -- Gate (a): government row
  SELECT COUNT(*) INTO v_gov_count
  FROM essentials.governments
  WHERE name = 'Town of Leonardtown, Maryland, US';

  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 Leonardtown government row, found %', v_gov_count;
  END IF;

  -- Gate (b): ALL offices linked to Leonardtown districts (LOCAL_EXEC + LOCAL combined)
  -- Do NOT filter on district_type — must count both Mayor (LOCAL_EXEC) and 5 council (LOCAL)
  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '2446475'
    AND d.state = 'md';

  IF v_office_count <> 6 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 6 offices linked to geo_id=2446475 districts, found %', v_office_count;
  END IF;

  -- Gate (c): section-split detector
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id = '2446475'
    AND gb.mtfcc = 'G4110'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id
        AND d.state = 'md'
    );

  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % orphan rows for geo_id=2446475', v_split_count;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: gov_count=%, office_count=%, split_orphans=%',
    v_gov_count, v_office_count, v_split_count;
END $$;

-- =============================================================================
-- Step 7: Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('277')
ON CONFLICT (version) DO NOTHING;

COMMIT;
