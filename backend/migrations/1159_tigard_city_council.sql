-- Migration 1159: City of Tigard government + chamber + districts + officials + offices
--
-- Purpose: Seeds the City of Tigard, Oregon (Washington County, west-metro):
--   Tigard (geo_id='4173650') — 1 gov + 1 chamber + 2 districts + 7 officials + 7 offices
--
-- Form of government (RESEARCH-confirmed, primary-source charter text via ecode360.com Ch.3,
-- re-verified at Wave-0 2026-07-02):
--   Council-manager. PURE AT-LARGE — Mayor and all 6 Councilors are "nominated and elected from
--   the City at-large" (Charter §3.1). NO wards, NO numbered positions, NO seat differentiation
--   of any kind — the simplest at-large shape in this milestone (closer to Boulder City NV's
--   plain 'Council Member' convention than to Hillsboro's ward+position scheme). Office titles
--   are simply 'Mayor' and 'Councilor'.
--
-- Appointed seats (NEW pattern for this milestone, not present in Hillsboro mig 1150 — see
-- Las Vegas mig 1075 Kara Kelley block for the precedent): Mayor Heidi Lueb resigned Sept 2025;
-- Council appointed sitting Councilor Yi-Kang Hu as Mayor (5-1 vote, Oct 7, 2025) to serve the
-- remainder of Lueb's term through Dec 31, 2026. Hu's own vacated council seat was then filled by
-- appointing Tom Anderson (unanimous, Dec 2025), interim through Dec 31, 2026 — Anderson has
-- publicly stated he will NOT run in the Nov 2026 election. Both Hu and Anderson carry
-- is_appointed=true (politician) + is_appointed_position=true (office); the other 5 officials
-- carry false/false (elected Nov 2024).
--
-- CRITICAL: the generated identifier column on essentials.chambers is NEVER included in an INSERT.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state must be 'or' (lowercase) to match routing queries.
-- CRITICAL: governments.state = 'OR' (uppercase). offices.representing_state = 'OR' (uppercase).
-- CRITICAL: district_type='LOCAL_EXEC' for Mayor; district_type='LOCAL' for council (NOT 'COUNTY').
-- CRITICAL: at-large councilors — NO ward geofences, NO ward/position districts of any kind.
-- CRITICAL: representing_city='Tigard' is set INLINE on every office INSERT (same improvement as
--           Hillsboro's D-09 fix) so the community banner derives correctly at first browse — no
--           follow-up backfill migration needed.
-- CRITICAL: Maureen Wolf holds the annually-elected Council President title (Mayor Pro Tempore
--           during any Mayor vacancy/absence, per Charter §3.4) — this is a title on her seat,
--           NOT a separate office row. ONE office row only, title stays plain 'Councilor'.
-- CRITICAL: Do NOT seed the Youth Councilor — non-voting, mayor-appointed civic-education role,
--           not a governing office (Charter 2024 reform). Exactly 7 offices, official_count=7.
-- CRITICAL: post-verification below applies the WR-01 fix (independent geofence-presence
--           assertion + canonical section-split query), not the dead same-transaction gate
--           inherited from the Beaverton/Hillsboro template (which cannot ever fail by
--           construction, since the same transaction both creates and checks for the districts).

BEGIN;

-- =============================================================================
-- Pre-flight: RAISE EXCEPTION if the Tigard government row already exists (hard abort guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'City of Tigard, Oregon, US') > 0 THEN
    RAISE EXCEPTION 'Migration 1159 already applied — aborting re-run';
  END IF;
END $$;


-- =============================================================================
-- TIGARD (geo_id='4173650')
-- 7 officials: Mayor Yi-Kang Hu (appointed) + 6 councilors (plain, at-large; 1 appointed interim)
-- =============================================================================

-- Step 1: Government row
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Tigard, Oregon, US',
       'LOCAL', 'OR', 'Tigard', '4173650'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Tigard, Oregon, US'
);

-- Step 2: City Council chamber (generated identifier column omitted intentionally)
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'City Council',
       'Tigard City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Tigard, Oregon, US'),
       7
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Tigard, Oregon, US')
);

-- Step 3: LOCAL_EXEC district (Mayor — citywide)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'or', '4173650', 'Tigard (Mayor, Citywide)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4173650' AND district_type = 'LOCAL_EXEC' AND state = 'or'
);

-- Step 4: LOCAL at-large district (all 6 councilors share this — pure at-large, no wards)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'or', '4173650', 'Tigard (At-Large)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4173650' AND district_type = 'LOCAL' AND state = 'or'
);

-- Step 5: Mayor Yi-Kang Hu (-4173651) — APPOINTED Oct 7, 2025 (5-1 council vote), filling
-- Heidi Lueb's unexpired term (Lueb resigned Sept 2025). Term through Dec 31, 2026 — the
-- remainder of the term goes to the Nov 2026 general election. is_appointed=true on the
-- politician row AND is_appointed_position=true on the office row (LV mig 1075 Kelley pattern).
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Yi-Kang Hu', 'Yi-Kang', 'Hu', NULL,
          true, true, false, true, -4173651)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Tigard, Oregon, US')),
       p.id,
       'Mayor', 'OR', 'Tigard', true, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4173650'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 6: Councilor Tom Anderson (-4173652) — APPOINTED unanimously Dec 2025, interim through
-- Dec 31, 2026, filling Hu's vacated council seat. Publicly stated he will NOT run in the Nov
-- 2026 election — a placeholder appointment by design. is_appointed=true / is_appointed_position=true.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tom Anderson', 'Tom', 'Anderson', NULL,
          true, true, false, true, -4173652)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Tigard, Oregon, US')),
       p.id,
       'Councilor', 'OR', 'Tigard', true, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4173650'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 7: Councilor Faraz Ghoddusi (-4173653) — elected Nov 2024 to one of the two NEW
-- charter-expansion seats, 2-year term through Dec 31, 2026. Not appointed: false/false.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Faraz Ghoddusi', 'Faraz', 'Ghoddusi', NULL,
          true, false, false, true, -4173653)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Tigard, Oregon, US')),
       p.id,
       'Councilor', 'OR', 'Tigard', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4173650'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 8: Councilor Heather Robbins (-4173654) — elected Nov 2024 to the other NEW
-- charter-expansion seat, 2-year term through Dec 31, 2026. Not appointed: false/false.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Heather Robbins', 'Heather', 'Robbins', NULL,
          true, false, false, true, -4173654)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Tigard, Oregon, US')),
       p.id,
       'Councilor', 'OR', 'Tigard', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4173650'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 9: Councilor Jake Schlack (-4173655) — elected Nov 2024, 4-year term through Dec 31, 2028.
-- Not appointed: false/false.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jake Schlack', 'Jake', 'Schlack', NULL,
          true, false, false, true, -4173655)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Tigard, Oregon, US')),
       p.id,
       'Councilor', 'OR', 'Tigard', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4173650'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 10: Councilor Jeanette Shaw (-4173656) — elected Nov 2024, 4-year term through Dec 31, 2028.
-- Not appointed: false/false.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jeanette Shaw', 'Jeanette', 'Shaw', NULL,
          true, false, false, true, -4173656)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Tigard, Oregon, US')),
       p.id,
       'Councilor', 'OR', 'Tigard', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4173650'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 11: Councilor Maureen Wolf (-4173657) — elected Nov 2024, 4-year term through Dec 31, 2028.
-- Holds the annually-elected Council President title (Mayor Pro Tempore during any Mayor
-- vacancy/absence, per Charter §3.4) — this is a title on her seat, NOT a separate office row.
-- ONE office row only, title stays plain 'Councilor'. Not appointed: false/false.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Maureen Wolf', 'Maureen', 'Wolf', NULL,
          true, false, false, true, -4173657)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Tigard, Oregon, US')),
       p.id,
       'Councilor', 'OR', 'Tigard', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4173650'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- office_id back-fill (all 7 Tigard officials)
-- Explicit IN list; WHERE p.office_id IS NULL for idempotency
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id IN (
    -4173651,-4173652,-4173653,-4173654,-4173655,-4173656,-4173657
  )
  AND p.office_id IS NULL;


-- =============================================================================
-- Post-verification DO block — WR-01 FIX applied
-- Raises EXCEPTION on any failure — rolls back the transaction
-- Gates: (a) gov=1  (b) office=7 (not 8 — no Youth Councilor)
--        (c) INDEPENDENT geofence-presence assertion (not the dead same-transaction gate)
--        (d) canonical section-split query (GROUP BY / HAVING) = 0
--        (e) office_id back-fill nulls=0
--        (f) representing_city='Tigard' set inline on all 7 offices
-- =============================================================================
DO $$
DECLARE
  v_gov_count      INTEGER;
  v_office_count   INTEGER;
  v_split_count    INTEGER;
  v_null_count     INTEGER;
  v_repcity_count  INTEGER;
  v_geofence_count INTEGER;
BEGIN

  -- Gate (a): Tigard government row
  SELECT COUNT(*) INTO v_gov_count FROM essentials.governments
  WHERE name = 'City of Tigard, Oregon, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Tigard gov_count=%, expected 1', v_gov_count;
  END IF;

  -- Gate (b): Tigard offices linked to LOCAL/LOCAL_EXEC districts
  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '4173650' AND d.district_type IN ('LOCAL','LOCAL_EXEC') AND d.state = 'or';
  IF v_office_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Tigard office_count=%, expected 7 (not 8 — no Youth Councilor)', v_office_count;
  END IF;

  -- Gate (c): WR-01 FIX — independent geofence-presence assertion (not the same-transaction
  -- "created it then checked for its absence" dead gate inherited from the Beaverton/Hillsboro template)
  SELECT COUNT(*) INTO v_geofence_count
  FROM essentials.geofence_boundaries
  WHERE geo_id = '4173650' AND mtfcc = 'G4110';
  IF v_geofence_count < 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: no G4110 geofence row found for geo_id 4173650';
  END IF;

  -- Gate (d): WR-01 FIX — canonical section-split query (GROUP BY / HAVING), independent of the
  -- INSERTs above
  SELECT COUNT(*) INTO v_split_count
  FROM (
    SELECT o.district_id
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.geo_id = '4173650'
    GROUP BY o.district_id
    HAVING COUNT(DISTINCT o.chamber_id) > 1
  ) x;
  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % rows', v_split_count;
  END IF;

  -- Gate (e): office_id back-fill — all 7 politicians must have non-null office_id
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id IN (
    -4173651,-4173652,-4173653,-4173654,-4173655,-4173656,-4173657
  )
  AND office_id IS NULL;
  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians still have NULL office_id after back-fill', v_null_count;
  END IF;

  -- Gate (f), Tigard-specific: representing_city set inline (no backfill mig needed)
  SELECT COUNT(*) INTO v_repcity_count
  FROM essentials.offices o
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id BETWEEN -4173657 AND -4173651
    AND o.representing_city = 'Tigard';
  IF v_repcity_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % of 7 Tigard offices have representing_city=Tigard', v_repcity_count;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: Tigard gov=1, offices=7, geofence>=1, section-split=0, office_id nulls=0, representing_city=7';
END $$;


-- =============================================================================
-- Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('1159')
ON CONFLICT (version) DO NOTHING;

COMMIT;
