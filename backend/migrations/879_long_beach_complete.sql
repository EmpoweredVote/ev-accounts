-- Migration 879: Long Beach roster completion
-- Phase 142 (v17.0 LA County City Coverage — Wave 2). Applied: 2026-06-19
--
-- Completes the Long Beach elected roster on top of the reconciled structure (878):
--   Part A — seat the missing 9th council seat: District 8 = Tunua Thrash-Ntuk
--            (elected Mar 2024, sworn Dec 17 2024). Fills the existing empty LOCAL
--            district ef56be18 in council chamber 2109e716. external_id -700050.
--   Part B — add the 3 directly-elected citywide officers, each in its OWN chamber
--            (D-02, Open Q1 → separate chambers):
--              City Attorney   Dawn McIntosh  -700051  chamber 'City Attorney of Long Beach'
--              City Prosecutor Doug Haubert   -700052  chamber 'City Prosecutor of Long Beach'
--              City Auditor    Laura Doud     -700053  chamber 'City Auditor of Long Beach'
--
-- All elected (is_appointed=false). Appointed City Manager / City Clerk are OUT of scope.
-- New external_ids use reserved range -700050..-700099 (DB-verified empty 2026-06-19).
-- chambers.slug is GENERATED — never written. districts guarded by WHERE NOT EXISTS
-- (no unique constraint on geo_id). Fully idempotent.

BEGIN;

-- ── Part A: District 8 — Tunua Thrash-Ntuk ──────────────────────────────────────
UPDATE essentials.districts SET label = 'District 8'
WHERE id = 'ef56be18-e3f9-482e-a28b-d6a3f9dd3b51' AND label <> 'District 8';

INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, party, is_active, is_appointed, is_incumbent, is_vacant, is_off_cycle, source)
VALUES
  (-700050, 'Tunua Thrash-Ntuk', 'Tunua', 'Thrash-Ntuk', '', true, false, true, false, false, 'longbeach.gov')
ON CONFLICT (external_id) DO NOTHING;

INSERT INTO essentials.offices
  (politician_id, chamber_id, district_id, title, representing_state, representing_city, is_appointed_position, is_vacant, seats, partisan_type, normalized_position_name)
SELECT p.id, '2109e716-127f-4d0d-8ec5-7bf77d503e03', 'ef56be18-e3f9-482e-a28b-d6a3f9dd3b51',
       'Councilmember', 'CA', 'Long Beach', false, false, 0, '', 'Council Member'
FROM essentials.politicians p
WHERE p.external_id = -700050
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
                  WHERE o.district_id = 'ef56be18-e3f9-482e-a28b-d6a3f9dd3b51' AND o.politician_id = p.id);

-- ── Part B: 3 citywide elected officers ─────────────────────────────────────────
-- Chambers (guard on government_id + name; slug GENERATED, never written)
INSERT INTO essentials.chambers (government_id, name, name_formal)
SELECT '5e5c3e0b-5479-4759-ac7e-2ea0aecabd38', v.name, v.name
FROM (VALUES
  ('City Attorney of Long Beach'),
  ('City Prosecutor of Long Beach'),
  ('City Auditor of Long Beach')
) AS v(name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers c
  WHERE c.government_id = '5e5c3e0b-5479-4759-ac7e-2ea0aecabd38' AND c.name = v.name
);

-- LOCAL_EXEC districts (one per officer; guard on label+geo_id; mirror the Mayor district)
INSERT INTO essentials.districts
  (external_id, label, mtfcc, state, geo_id, ocd_id, district_id, district_type, num_officials, is_judicial, retention, has_unknown_boundaries)
SELECT v.ext, v.label, 'G4110', 'CA', '0643000',
       'ocd-division/country:us/state:ca/place:long_beach', '0', 'LOCAL_EXEC', 1, false, false, false
FROM (VALUES
  (-700061, 'Long Beach City Attorney'),
  (-700062, 'Long Beach City Prosecutor'),
  (-700063, 'Long Beach City Auditor')
) AS v(ext, label)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d WHERE d.label = v.label AND d.geo_id = '0643000'
);

-- Politicians (3 officers)
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, middle_initial, party, is_active, is_appointed, is_incumbent, is_vacant, is_off_cycle, source)
VALUES
  (-700051, 'Dawn McIntosh', 'Dawn', 'McIntosh', '',  '', true, false, true, false, false, 'longbeach.gov'),
  (-700052, 'Doug Haubert',  'Doug', 'Haubert',  '',  '', true, false, true, false, false, 'longbeach.gov'),
  (-700053, 'Laura Doud',    'Laura','Doud',     'L.', '', true, false, true, false, false, 'longbeach.gov')
ON CONFLICT (external_id) DO NOTHING;

-- Offices (3 officers) — match politician↔chamber↔district by stable keys
INSERT INTO essentials.offices
  (politician_id, chamber_id, district_id, title, representing_state, representing_city, is_appointed_position, is_vacant, seats, partisan_type, normalized_position_name)
SELECT p.id, c.id, d.id, v.title, 'CA', 'Long Beach', false, false, 0, '', v.title
FROM (VALUES
  (-700051, 'City Attorney of Long Beach',   'Long Beach City Attorney',   'City Attorney'),
  (-700052, 'City Prosecutor of Long Beach', 'Long Beach City Prosecutor', 'City Prosecutor'),
  (-700053, 'City Auditor of Long Beach',    'Long Beach City Auditor',    'City Auditor')
) AS v(ext, chamber_name, district_label, title)
JOIN essentials.politicians p ON p.external_id = v.ext
JOIN essentials.chambers c ON c.government_id = '5e5c3e0b-5479-4759-ac7e-2ea0aecabd38' AND c.name = v.chamber_name
JOIN essentials.districts d ON d.label = v.district_label AND d.geo_id = '0643000'
WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.politician_id = p.id);

-- Back-fill office_id for all 4 new officials (idempotent)
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -700053 AND -700050
  AND p.office_id IS NULL;

COMMIT;

-- ── Post-verification ───────────────────────────────────────────────────────────
-- 1. 4 rows in -700053..-700050, all office_id non-NULL
-- 2. council chamber 2109e716 holds 9 offices
-- 3. 3 new citywide chambers present with distinct names
-- 4. full roster = 13 office-linked officials under gov 5e5c3e0b
-- 5. duplicate name_formal within government = 0
