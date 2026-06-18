-- Migration 358: MA 2026 Legislative Race Scaffold - Phase 110 Plan 02
-- 40 MA State Senate + 160 MA House of Representatives = 200 race rows, general election only
--
-- APPROACH: Single-statement CTE-JOIN INSERT (NOT per-DO-$$ blocks like MD migration 280).
-- MA has named districts (e.g., "Senator, Berkshire-Hampden-Franklin-Hampshire District")
-- so position_names are derived from office titles at query time, not hardcoded.
--
-- ON CONFLICT guard makes this idempotent over the 5 pre-existing MA legislative race rows:
--   MA State Senate 2nd Middlesex District (general)
--   MA State Senate Middlesex and Suffolk District (general)
--   MA State Senate Suffolk and Middlesex District (general)
--   MA House 25th Middlesex District (general)
--   MA House 26th Middlesex District (general)
--
-- Chamber name guard: ch.name IN ('Massachusetts Senate', 'Massachusetts House of Representatives')
-- Do NOT use g.geo_id='25' alone — two governments share that geo_id in this DB.

-- SECTION 0: Fix pre-existing race name mismatch (Rule 1 - auto-fix)
-- The pre-existing "MA State Senate 2nd Middlesex District" race was seeded with "2nd"
-- but the offices.title uses "Second" (e.g., "Senator, Second Middlesex District").
-- The CTE-JOIN will produce "MA State Senate Second Middlesex District". Rename the
-- pre-existing row so the ON CONFLICT guard fires correctly for all 5 pre-existing races.
UPDATE essentials.races
SET position_name = 'MA State Senate Second Middlesex District'
WHERE position_name = 'MA State Senate 2nd Middlesex District'
  AND election_id IN (
    SELECT id FROM essentials.elections
    WHERE name = '2026 Massachusetts General Election' AND state = 'MA'
  );

-- Also fix the Primary election row for the same district
UPDATE essentials.races
SET position_name = 'MA State Senate Second Middlesex District'
WHERE position_name = 'MA State Senate 2nd Middlesex District'
  AND election_id IN (
    SELECT id FROM essentials.elections
    WHERE name = '2026 Massachusetts State Primary' AND state = 'MA'
  );

-- SECTION 1: Single-statement CTE-JOIN INSERT for 200 MA legislative races
WITH gen_elec AS (
  SELECT id FROM essentials.elections
  WHERE name = '2026 Massachusetts General Election' AND state = 'MA'
), leg_offices AS (
  SELECT
    o.id AS office_id,
    d.district_type,
    CASE WHEN d.district_type = 'STATE_UPPER'
         THEN 'MA State Senate ' || regexp_replace(o.title, '^Senator, ', '')
         ELSE 'MA House ' || regexp_replace(o.title, '^Representative, ', '')
    END AS position_name
  FROM essentials.offices o
  JOIN essentials.chambers ch ON o.chamber_id = ch.id
  JOIN essentials.governments g ON ch.government_id = g.id
  JOIN essentials.districts d ON o.district_id = d.id
  WHERE ch.name IN ('Massachusetts Senate', 'Massachusetts House of Representatives')
    AND d.district_type IN ('STATE_UPPER', 'STATE_LOWER')
)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT gen_elec.id, leg_offices.office_id, leg_offices.position_name, NULL, 1
FROM gen_elec, leg_offices
ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

-- SECTION 2: Ledger INSERT
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('358')
ON CONFLICT (version) DO NOTHING;

-- SECTION 3: Post-verify DO $$ block
DO $$
DECLARE
  v_leg_count INT;
  v_null_count INT;
BEGIN
  -- Check 1: Exactly 200 MA legislative race rows in general election
  SELECT COUNT(*) INTO v_leg_count
  FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.state = 'MA'
    AND e.name = '2026 Massachusetts General Election'
    AND (r.position_name LIKE 'MA State Senate%' OR r.position_name LIKE 'MA House%');

  IF v_leg_count <> 200 THEN
    RAISE EXCEPTION 'Expected 200 MA legislative races in general election, found %', v_leg_count;
  END IF;

  -- Check 2: Zero MA races with NULL office_id (across all MA elections)
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.state = 'MA'
    AND r.office_id IS NULL;

  IF v_null_count > 0 THEN
    RAISE EXCEPTION 'MA races with NULL office_id found: %', v_null_count;
  END IF;

  RAISE NOTICE 'Migration 358 verified: % MA legislative races, 0 NULL office_ids', v_leg_count;
END $$;
