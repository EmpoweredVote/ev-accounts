BEGIN;

-- LA City Attorney office id='5a873c59-72ac-488f-8b2c-44dfd04d065c' INTENTIONALLY LEFT VACANT.
-- Hydee Feldstein Soto lost the June 2026 primary. Office is in runoff (Roy vs. McKinney, Nov 2026).
-- Per CONTEXT.md D-08 + 108-RESEARCH.md Critical Finding 1: no politician seeded for this office in Wave 2.
-- NOTE: Feldstein Soto was already in the DB (inserted prior to this phase); her record is NOT touched here.

-- =============================================================================
-- Migration 303: LA City Controller backfill + City Clerk (Patrice Lattimore)
-- Phase 108-la-county-city-officials, Plan 02 (Wave 2), Task 4
-- =============================================================================
-- Pre-flight (migration 300) confirmed:
--   city_controller_office_politician_id: 590fd6ec-3194-43af-97fc-25490490c565
--     → Kenneth Mejia already in DB (external_id=NULL, office_id=NULL)
--     → Controller office (e5435b0e) already has politician_id=590fd6ec set
--     → Action: UPDATE Mejia's external_id and office_id; no new insert needed
--   city_attorney_office_politician_id: 3f90952e (Hydee Feldstein Soto — DO NOT TOUCH)
--   city_clerk_office_exists: TRUE
--     → Office id=cc009928-ff2a-467f-8c90-7d42e397ee70, politician_id=NULL, chamber_id=NULL
--     → No City Clerk chamber exists for LA govt — must create one
--     → Action: Create chamber, INSERT Lattimore, UPDATE office with politician_id + chamber_id
--   LA City govt: 'Los Angeles, California, US' (id=dcc0355c-a8f5-4b21-8936-43543b4a3f83)
-- =============================================================================

-- =============================================================================
-- Step A — Kenneth Mejia, City Controller (external_id=-700001)
-- He is already in DB and already linked to the City Controller office.
-- We only need to:
--   1. Set external_id=-700001 on his politician row (was NULL)
--   2. Backfill office_id on his politician row (was NULL)
-- This UPDATE is idempotent — second run is a no-op.
-- =============================================================================
UPDATE essentials.politicians
SET external_id = -700001
WHERE id = '590fd6ec-3194-43af-97fc-25490490c565'
  AND external_id IS DISTINCT FROM -700001;

-- Backfill office_id on Mejia's politician row
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.id = '590fd6ec-3194-43af-97fc-25490490c565'
  AND p.office_id IS NULL;

-- =============================================================================
-- Step B — Patrice Lattimore, City Clerk (external_id=-700002, is_appointed=true)
-- Appointed by City Council in September 2025 per RESEARCH.md Critical Finding 2.
-- city_clerk_office_exists = TRUE (pre-flight confirmed office cc009928 exists with
-- politician_id=NULL and chamber_id=NULL).
-- =============================================================================

-- B1: Create City Clerk chamber for LA government (does not exist yet)
-- CRITICAL: slug is GENERATED ALWAYS AS — never include in INSERT column list (Pitfall 4)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Clerk', 'Los Angeles City Clerk',
       'dcc0355c-a8f5-4b21-8936-43543b4a3f83'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Clerk'
    AND government_id = 'dcc0355c-a8f5-4b21-8936-43543b4a3f83'
);

-- B2: Insert Patrice Lattimore as politician
-- is_appointed=true (she was appointed by City Council, not popularly elected)
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, party, is_active, is_appointed,
   is_vacant, is_incumbent, external_id, photo_origin_url)
VALUES (
  gen_random_uuid(),
  'Patrice Lattimore',
  'Patrice',
  'Lattimore',
  NULL,
  true,
  true,
  false,
  true,
  -700002,
  'https://clerk.lacity.gov/about-the-office'
)
ON CONFLICT (external_id) DO NOTHING;

-- B3: Link Lattimore to the existing City Clerk office AND set the chamber_id + is_appointed_position
-- The existing office (cc009928) has chamber_id=NULL and politician_id=NULL.
-- Guard with politician_id IS NULL for idempotency — second run does nothing if already linked.
-- Also set is_appointed_position=true since the Clerk is an appointed (not elected) position.
UPDATE essentials.offices
SET politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -700002),
    chamber_id = (SELECT id FROM essentials.chambers
                  WHERE name = 'City Clerk'
                    AND government_id = 'dcc0355c-a8f5-4b21-8936-43543b4a3f83'),
    is_appointed_position = true
WHERE id = 'cc009928-ff2a-467f-8c90-7d42e397ee70'
  AND politician_id IS NULL;

-- =============================================================================
-- Step C — office_id back-fill for both Mejia (already handled above) and Lattimore
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id IN (-700001, -700002)
  AND p.office_id IS NULL;

COMMIT;
