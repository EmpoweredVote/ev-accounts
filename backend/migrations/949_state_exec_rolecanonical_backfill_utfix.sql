-- 949_state_exec_rolecanonical_backfill_utfix.sql
-- Phase 141 (v2.18 State Leaders), plan 141-01.
-- PART A: Fix Utah's 5 NULL external_ids (D-08, Pitfall 3 — NULL breaks ON CONFLICT idempotency).
-- PART B: Backfill role_canonical on the pre-existing in-scope Big-5 offices in 8 already-seeded states
--         (CA, MA, MD, ME, OR, TX, UT, VA). Indiana is owned by plan 141-02 (migration 950) — EXCLUDED here.
--
-- Idempotent: every UPDATE is guarded (UT by `external_id IS NULL`; role_canonical by `role_canonical IS NULL`).
-- No INSERTs — this migration creates NO district/politician/office row (D-09 no-reseed).
-- Display titles left untouched (D-07). Non-Big-5 offices (CA Controller/Auditor, MA Auditor, MD Comptroller +
-- State Treasurer, OR Labor Commissioner, TX Land/Ag Commissioner, UT State Auditor) intentionally stay NULL.
-- Run: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/migrations/949_state_exec_rolecanonical_backfill_utfix.sql

BEGIN;

-- ============================ PART A — UT external_id fix (D-08) ============================
-- Preflight (D-04): assert no id in -4900001..-4900005 is held by a politician OTHER than UT's own
-- STATE_EXEC execs. On first run nobody holds them (UT ids are NULL); on re-run only the UT execs hold
-- them — so this guard is idempotent (a clean re-apply is a no-op, not a collision).
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM essentials.politicians p
    WHERE p.external_id BETWEEN -4900005 AND -4900001
      AND NOT EXISTS (
        SELECT 1 FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
        WHERE o.politician_id = p.id AND d.district_type='STATE_EXEC' AND d.state='UT'
      )
  ) THEN
    RAISE EXCEPTION 'PART A preflight FAILED: a UT external_id in -4900001..-4900005 is held by a non-UT-exec politician';
  END IF;
END $$;

-- Assign deterministic seq by office (match on full_name + the UT STATE_EXEC district join; external_id is NULL).
-- Cox (Gov)->1, Henderson (LtGov)->2, Brown (AG)->3, Cannon (State Auditor, NOT Big-5)->4, Oaks (Treasurer)->5.
UPDATE essentials.politicians p SET external_id = -4900001
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE o.politician_id = p.id AND d.district_type='STATE_EXEC' AND d.state='UT'
    AND d.label='Utah Governor' AND p.external_id IS NULL;
UPDATE essentials.politicians p SET external_id = -4900002
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE o.politician_id = p.id AND d.district_type='STATE_EXEC' AND d.state='UT'
    AND d.label='Utah Lieutenant Governor' AND p.external_id IS NULL;
UPDATE essentials.politicians p SET external_id = -4900003
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE o.politician_id = p.id AND d.district_type='STATE_EXEC' AND d.state='UT'
    AND d.label='Utah Attorney General' AND p.external_id IS NULL;
UPDATE essentials.politicians p SET external_id = -4900004
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE o.politician_id = p.id AND d.district_type='STATE_EXEC' AND d.state='UT'
    AND d.label='Utah State Auditor' AND p.external_id IS NULL;
UPDATE essentials.politicians p SET external_id = -4900005
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE o.politician_id = p.id AND d.district_type='STATE_EXEC' AND d.state='UT'
    AND d.label='Utah State Treasurer' AND p.external_id IS NULL;

-- ============================ PART B — role_canonical backfill (8 states) ============================
-- Scope each UPDATE by the office's politician external_id (precise; one external_id -> one office in these
-- STATE_EXEC contexts). Guarded WHERE role_canonical IS NULL so re-runs (and MA's already-set SoS/Treasurer)
-- are no-ops. UT is matched by its NOW-assigned ids from Part A.

-- governor (8): CA MA MD ME OR TX UT VA
UPDATE essentials.offices o SET role_canonical='governor'
  FROM essentials.politicians p
  WHERE o.politician_id = p.id AND o.role_canonical IS NULL
    AND p.external_id IN (-6000101, -200001, -240001, -230001, -4100001, -100202, -4900001, -510001);

-- lt_governor (6): CA MA MD TX UT VA  (ME/OR have no LtGov)
UPDATE essentials.offices o SET role_canonical='lt_governor'
  FROM essentials.politicians p
  WHERE o.politician_id = p.id AND o.role_canonical IS NULL
    AND p.external_id IN (-6000102, -200003, -240002, -100203, -4900002, -510002);

-- attorney_general (7): CA MA MD OR TX UT VA  (ME AG is legislature-elected → out)
UPDATE essentials.offices o SET role_canonical='attorney_general'
  FROM essentials.politicians p
  WHERE o.politician_id = p.id AND o.role_canonical IS NULL
    AND p.external_id IN (-6000103, -200004, -240003, -4100002, -100204, -4900003, -510003);

-- secretary_of_state (3): CA MA OR  (MA -200007 already set → guard no-ops it)
UPDATE essentials.offices o SET role_canonical='secretary_of_state'
  FROM essentials.politicians p
  WHERE o.politician_id = p.id AND o.role_canonical IS NULL
    AND p.external_id IN (-6000104, -200007, -4100003);

-- treasurer (5): CA MA OR TX(Comptroller, D-01) UT  (MA -200005 already set → guard no-ops it)
UPDATE essentials.offices o SET role_canonical='treasurer'
  FROM essentials.politicians p
  WHERE o.politician_id = p.id AND o.role_canonical IS NULL
    AND p.external_id IN (-6000106, -200005, -4100004, -100205, -4900005);

-- ============================ POST ASSERTIONS (before COMMIT) ============================
DO $$
DECLARE v_in_scope INT; v_ut_null INT; v_tx_comp TEXT;
BEGIN
  -- (a) all 29 in-scope Big-5 offices across the 8 states now have role_canonical set
  SELECT COUNT(*) INTO v_in_scope
  FROM (SELECT DISTINCT d.state, o.role_canonical
        FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
        WHERE d.district_type='STATE_EXEC' AND d.state IN ('CA','MA','MD','ME','OR','TX','UT','VA')
          AND o.role_canonical IN ('governor','lt_governor','attorney_general','secretary_of_state','treasurer')) x;
  IF v_in_scope <> 29 THEN
    RAISE EXCEPTION 'POST FAILED: expected 29 in-scope Big-5 (state,role) pairs across the 8 states, found %', v_in_scope;
  END IF;

  -- (b) UT politicians all have non-null external_id
  SELECT COUNT(*) INTO v_ut_null
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.politician_id=p.id
  JOIN essentials.districts d ON d.id=o.district_id
  WHERE d.district_type='STATE_EXEC' AND d.state='UT' AND p.external_id IS NULL;
  IF v_ut_null <> 0 THEN
    RAISE EXCEPTION 'POST FAILED: % UT STATE_EXEC politicians still have NULL external_id', v_ut_null;
  END IF;

  -- (c) TX Comptroller mapped to treasurer (D-01)
  SELECT o.role_canonical INTO v_tx_comp
  FROM essentials.offices o JOIN essentials.politicians p ON p.id=o.politician_id
  WHERE p.external_id = -100205;
  IF v_tx_comp IS DISTINCT FROM 'treasurer' THEN
    RAISE EXCEPTION 'POST FAILED: TX Comptroller (ext -100205) role_canonical=% (expected treasurer)', v_tx_comp;
  END IF;

  RAISE NOTICE 'Migration 949 OK: 29 in-scope Big-5 offices backfilled across 8 states; UT external_ids fixed; TX Comptroller=treasurer';
END $$;

COMMIT;
