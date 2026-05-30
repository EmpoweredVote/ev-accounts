-- Migration 229: Portland OR council districts (4 LOCAL districts)
--
-- Creates 4 essentials.districts rows matching the 4 Portland OR council
-- district geofences loaded by load-portland-council-boundaries.ts (Phase 76).
--
-- Field values:
--   geo_id        = 'portland-or-council-district-{N}'  (N = 1..4)
--   district_type = 'LOCAL'                              (NOT 'LOCAL_LOWER' — ROADMAP description was wrong;
--                                                         essentialsService.ts X% fallback rule matches
--                                                         district_type IN ('LOCAL','COUNTY') for mtfcc LIKE 'X%'
--                                                         — see RESEARCH.md "Pattern: district_type = 'LOCAL'")
--   label         = 'District N'                         (column is 'label', NOT 'name')
--   state         = 'or'                                 (LOWERCASE — established OR pattern from Phase 72;
--                                                         districts.state for OR rows is lowercase 'or')
--
-- Idempotent via WHERE NOT EXISTS:
--   - essentials.districts has NO unique constraint on (geo_id, district_type)
--   - DO NOT use ON CONFLICT (geo_id, district_type) — that constraint does not exist; will raise runtime error
--   - Use WHERE NOT EXISTS guard on (geo_id, district_type, state)
--
-- Phase 77 will follow up with:
--   - 1 government row: 'City of Portland' (state='OR', geo_id='4159000')
--   - chambers: Mayor + City Council (12 offices across 4 multi-member districts) + City Attorney + City Administrator
--   - 1 LOCAL_EXEC districts row for citywide offices (Mayor + City Attorney + City Administrator)
--   - 14 politicians + offices (Mayor + 12 council members + City Attorney; City Administrator is is_appointed_position=true)
--
-- Verification gate after applying:
--   SELECT COUNT(*) FROM essentials.districts
--   WHERE geo_id LIKE 'portland-or-council-district-%' AND district_type='LOCAL' AND state='or';
--   -- Expected: 4

BEGIN;

INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT v.geo_id, v.district_type, v.label, v.state
FROM (VALUES
  ('portland-or-council-district-1', 'LOCAL', 'District 1', 'or'),
  ('portland-or-council-district-2', 'LOCAL', 'District 2', 'or'),
  ('portland-or-council-district-3', 'LOCAL', 'District 3', 'or'),
  ('portland-or-council-district-4', 'LOCAL', 'District 4', 'or')
) AS v(geo_id, district_type, label, state)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = v.geo_id
    AND d.district_type = v.district_type
    AND d.state = v.state
);

COMMIT;
