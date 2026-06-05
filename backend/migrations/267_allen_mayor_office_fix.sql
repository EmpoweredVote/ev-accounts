-- Migration 267: Fix Allen TX Mayor office — re-point offices.politician_id to Chris Schulmeister
-- GAP 3 from Phase 88 UAT: Allen Mayor office (id=684ffdb3) still pointed to former Mayor Baine Brooks
-- (is_active=false). Chris Schulmeister (id=698da6ca) was seeded into politicians but
-- offices.politician_id was never updated. This migration fixes the pointer and fills metadata.

-- Pre-flight: assert Chris Schulmeister exists and is active
DO $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE id = '698da6ca-eadd-46a0-8e27-94ae48d23279'
    AND is_active = true;

  IF v_count = 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Chris Schulmeister (id=698da6ca-eadd-46a0-8e27-94ae48d23279) not found or is_active=false';
  END IF;
END $$;

-- Step 1: Re-point Allen Mayor office to Schulmeister
UPDATE essentials.offices
SET politician_id = '698da6ca-eadd-46a0-8e27-94ae48d23279'
WHERE id = '684ffdb3-4073-4164-86f6-c151334fccb1';

-- Step 2: Populate Schulmeister metadata
UPDATE essentials.politicians
SET valid_from = '2026-05-03',
    data_source = 'collin_county_official'
WHERE id = '698da6ca-eadd-46a0-8e27-94ae48d23279';

-- Post-verification: assert all conditions met
DO $$
DECLARE
  v_politician_id UUID;
  v_valid_from DATE;
  v_data_source TEXT;
  v_is_active BOOLEAN;
BEGIN
  -- (a) Assert offices row now points to Schulmeister
  SELECT politician_id INTO v_politician_id
  FROM essentials.offices
  WHERE id = '684ffdb3-4073-4164-86f6-c151334fccb1';

  IF v_politician_id IS DISTINCT FROM '698da6ca-eadd-46a0-8e27-94ae48d23279'::UUID THEN
    RAISE EXCEPTION 'Post-verify FAILED (a): offices(id=684ffdb3) politician_id=% (expected 698da6ca)', v_politician_id;
  END IF;

  -- (b) Assert politicians row has valid_from and data_source populated
  SELECT valid_from, data_source, is_active
  INTO v_valid_from, v_data_source, v_is_active
  FROM essentials.politicians
  WHERE id = '698da6ca-eadd-46a0-8e27-94ae48d23279';

  IF v_valid_from IS NULL THEN
    RAISE EXCEPTION 'Post-verify FAILED (b): politicians(id=698da6ca) valid_from IS NULL';
  END IF;

  IF v_data_source IS NULL THEN
    RAISE EXCEPTION 'Post-verify FAILED (b): politicians(id=698da6ca) data_source IS NULL';
  END IF;

  -- (c) Assert is_active=true
  IF v_is_active IS NOT TRUE THEN
    RAISE EXCEPTION 'Post-verify FAILED (c): politicians(id=698da6ca) is_active=% (expected true)', v_is_active;
  END IF;
END $$;

-- Migration ledger
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('267')
ON CONFLICT DO NOTHING;
