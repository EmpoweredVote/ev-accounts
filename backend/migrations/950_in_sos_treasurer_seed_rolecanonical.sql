-- 950_in_sos_treasurer_seed_rolecanonical.sql
-- Phase 141 (v2.18 State Leaders), plan 141-02.  (Renumbered from planned 947 — see migration 949 header.)
-- Close Indiana's two Big-5 record gaps (Secretary of State, Treasurer) and backfill role_canonical on all 5
-- IN in-scope Big-5 offices.
--
-- IN-SPECIFIC TRAPS handled:
--   * Pitfall 4 — 22 duplicate "State of Indiana" government rows, ALL referenced by chambers; the 5 existing IN
--     Big-5 offices each use a DIFFERENT government_id. There is NO single canonical government. We therefore do
--     NOT create new chambers/governments at all — we REUSE the existing "Secretary of State" / "Treasurer"
--     chambers that Morales/Elliott's current offices already use (resolved via their existing office row).
--   * Pitfall 2 — Morales (ext 642977) + Elliott (ext 688298) already exist as politicians under the shared
--     "Indiana" district (geo_id=''). We create NEW labeled districts ('Indiana Secretary of State' /
--     'Indiana Treasurer', geo_id='18') and NEW offices linking the EXISTING politicians, leaving the legacy
--     shared-"Indiana" offices untouched (D-09, Open Question 1 RESOLVED). No politician rows are duplicated.
--     The feed de-dupes by politician id (essentialsService SELECT DISTINCT ON (COALESCE(p.id,o.id))), so the
--     second office does not double-display.
-- Idempotent: districts guarded NOT EXISTS (type,state,label); offices guarded NOT EXISTS (new district,
-- politician); role_canonical guarded WHERE role_canonical IS NULL.
-- Run: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/migrations/950_in_sos_treasurer_seed_rolecanonical.sql

BEGIN;

-- Preflight (IN-safe): assert the two existing politicians + their existing shared-"Indiana" offices exist.
DO $$
DECLARE v_p INT; v_o INT;
BEGIN
  SELECT COUNT(*) INTO v_p FROM essentials.politicians WHERE external_id IN (642977, 688298);
  IF v_p <> 2 THEN RAISE EXCEPTION 'Preflight FAILED: expected Morales(642977)+Elliott(688298), found % politicians', v_p; END IF;
  SELECT COUNT(*) INTO v_o
  FROM essentials.offices o
  JOIN essentials.politicians p ON p.id=o.politician_id
  JOIN essentials.districts d ON d.id=o.district_id
  WHERE p.external_id IN (642977,688298) AND d.district_type='STATE_EXEC' AND d.state='IN' AND d.label='Indiana';
  IF v_o < 2 THEN RAISE EXCEPTION 'Preflight FAILED: expected >=2 existing IN shared-district offices for Morales/Elliott, found %', v_o; END IF;
END $$;

-- 1) New labeled STATE_EXEC districts for SoS + Treasurer (geo_id='18', uppercase state).
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'IN', '18', 'Indiana Secretary of State', '', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type='STATE_EXEC' AND state='IN' AND label='Indiana Secretary of State');
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'IN', '18', 'Indiana Treasurer', '', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type='STATE_EXEC' AND state='IN' AND label='Indiana Treasurer');

-- 2) New offices linking the EXISTING politicians to the new labeled districts, reusing the chamber their
--    existing shared-"Indiana" office already uses. role_canonical set; title kept (D-07).
INSERT INTO essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), nd.id, eo.chamber_id, p.id, 'Secretary of State', 'IN', false, false, 'secretary_of_state'
FROM essentials.politicians p
JOIN essentials.offices eo ON eo.politician_id = p.id
JOIN essentials.districts ed ON ed.id = eo.district_id AND ed.district_type='STATE_EXEC' AND ed.state='IN' AND ed.label='Indiana'
CROSS JOIN essentials.districts nd
WHERE p.external_id = 642977
  AND nd.district_type='STATE_EXEC' AND nd.state='IN' AND nd.label='Indiana Secretary of State'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o2 WHERE o2.district_id=nd.id AND o2.politician_id=p.id);

INSERT INTO essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), nd.id, eo.chamber_id, p.id, 'Treasurer', 'IN', false, false, 'treasurer'
FROM essentials.politicians p
JOIN essentials.offices eo ON eo.politician_id = p.id
JOIN essentials.districts ed ON ed.id = eo.district_id AND ed.district_type='STATE_EXEC' AND ed.state='IN' AND ed.label='Indiana'
CROSS JOIN essentials.districts nd
WHERE p.external_id = 688298
  AND nd.district_type='STATE_EXEC' AND nd.state='IN' AND nd.label='Indiana Treasurer'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o2 WHERE o2.district_id=nd.id AND o2.politician_id=p.id);

-- 3) Backfill office_id on the politicians (mirror migration 270 STEP 3) for the new labeled offices, if NULL.
UPDATE essentials.politicians p SET office_id = o.id
FROM essentials.offices o
JOIN essentials.districts d ON d.id=o.district_id
WHERE o.politician_id=p.id AND d.district_type='STATE_EXEC' AND d.state='IN'
  AND d.label IN ('Indiana Secretary of State','Indiana Treasurer') AND p.office_id IS NULL;

-- 4) role_canonical backfill on existing IN Gov / LtGov / AG offices.
UPDATE essentials.offices o SET role_canonical='governor'
  FROM essentials.politicians p WHERE o.politician_id=p.id AND o.role_canonical IS NULL AND p.external_id=499460;
UPDATE essentials.offices o SET role_canonical='lt_governor'
  FROM essentials.politicians p WHERE o.politician_id=p.id AND o.role_canonical IS NULL AND p.external_id=499415;
UPDATE essentials.offices o SET role_canonical='attorney_general'
  FROM essentials.politicians p WHERE o.politician_id=p.id AND o.role_canonical IS NULL AND p.external_id=499453;

-- ============================ POST ASSERTIONS ============================
DO $$
DECLARE v_pairs INT; v_dist INT; v_sos INT; v_tre INT; v_pol INT;
BEGIN
  -- (a) all 5 IN Big-5 (state,role) pairs present
  SELECT COUNT(DISTINCT o.role_canonical) INTO v_pairs
  FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
  WHERE d.district_type='STATE_EXEC' AND d.state='IN'
    AND o.role_canonical IN ('governor','lt_governor','attorney_general','secretary_of_state','treasurer');
  IF v_pairs <> 5 THEN RAISE EXCEPTION 'POST FAILED: expected 5 IN Big-5 roles, found %', v_pairs; END IF;

  -- (b) 2 new labeled districts geo_id='18' uppercase
  SELECT COUNT(*) INTO v_dist FROM essentials.districts
  WHERE district_type='STATE_EXEC' AND state='IN' AND label IN ('Indiana Secretary of State','Indiana Treasurer')
    AND geo_id='18' AND state=upper(state);
  IF v_dist <> 2 THEN RAISE EXCEPTION 'POST FAILED: expected 2 labeled geo_id=18 IN districts, found %', v_dist; END IF;

  -- (c) exactly one office per (IN, secretary_of_state)/(IN, treasurer) on a geo_id='18' labeled district
  SELECT COUNT(*) INTO v_sos FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
    WHERE d.district_type='STATE_EXEC' AND d.state='IN' AND d.geo_id='18' AND o.role_canonical='secretary_of_state';
  SELECT COUNT(*) INTO v_tre FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
    WHERE d.district_type='STATE_EXEC' AND d.state='IN' AND d.geo_id='18' AND o.role_canonical='treasurer';
  IF v_sos <> 1 OR v_tre <> 1 THEN RAISE EXCEPTION 'POST FAILED: labeled SoS=% treasurer=% (expected 1 each)', v_sos, v_tre; END IF;

  -- (d) no duplicate politician rows for Morales/Elliott
  SELECT COUNT(*) INTO v_pol FROM essentials.politicians WHERE external_id IN (642977,688298);
  IF v_pol <> 2 THEN RAISE EXCEPTION 'POST FAILED: Morales/Elliott politician count=% (expected 2 — no duplicates)', v_pol; END IF;

  RAISE NOTICE 'Migration 950 OK: IN SoS+Treasurer on labeled geo_id=18 districts; all 5 IN Big-5 role-tagged; no duplicate politicians';
END $$;

COMMIT;
