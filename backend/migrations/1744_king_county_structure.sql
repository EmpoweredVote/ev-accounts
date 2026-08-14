-- 1744_king_county_structure.sql
-- King County, Washington: standalone government + 6 chambers + 14 offices.
--
-- STANDALONE GOVERNMENT. King County gets its own essentials.governments row at
-- geo_id 53033 and is NOT nested under State of Washington — the same pattern as
-- Clark County NV (32003) and Washington County OR (41067).
--
-- DISTRICTS
--   Countywide offices (Executive, Prosecuting Attorney, Assessor, Elections
--   Director, Sheriff) attach to the EXISTING COUNTY district row at geo_id
--   53033 / mtfcc G4020 — created by the TIGER county load, not here.
--
--   !! geo_id 53033 is NOT unique. It is simultaneously King County (COUNTY,
--   G4020), Legislative Senate District 33 (STATE_UPPER, G5210) and Legislative
--   House District 33 (STATE_LOWER, G5220). Every district lookup below keys on
--   (geo_id, district_type, mtfcc). A geo_id-only join returns three rows and
--   silently attaches countywide offices to legislative districts.
--
--   The 9 council districts get new LOCAL district rows on the X0026 geofences
--   loaded by scripts/load-kingcounty-council-boundaries.ts.
--
-- SHERIFF IS APPOINTED. King County made the Sheriff an appointed position under
-- the 2020 charter amendment; Patti Cole-Tindall was appointed in 2022 and
-- re-appointed by Executive Zahilay in November 2025. The chamber therefore gets
-- policy_engagement_level='none' — the administrative treatment prior cities gave
-- appointed clerks and auditors. It appears in the roster without drawing a
-- compass it has no electoral record to support. (Setting this on the chamber is
-- the supported mechanism; src/lib/classify.js computeVariant is dead code.)
--
-- COUNCIL CHAIR is a title on a seat, not a separate office — there is no tenth
-- council row.
--
-- chambers.slug is a GENERATED column derived from name_formal and must not be
-- inserted directly.
--
-- Idempotency: governments/chambers/districts/offices have no usable unique
-- index for these keys, so every insert uses NOT EXISTS, never ON CONFLICT.

-- ─── Government ──────────────────────────────────────────────────────────────

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'King County, Washington, US', 'County', 'WA', NULL, '53033'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE geo_id = '53033' AND type = 'County'
);

-- ─── Council district rows (LOCAL, on the X0026 geofences) ───────────────────

INSERT INTO essentials.districts (id, geo_id, label, district_type, state, mtfcc)
SELECT gen_random_uuid(),
       gb.geo_id,
       'King County Council District ' || right(gb.geo_id, 1),
       'LOCAL',
       'wa',           -- lowercase: LOCAL-tier routing join key
       'X0026'
FROM essentials.geofence_boundaries gb
WHERE gb.mtfcc = 'X0026'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.districts d
    WHERE d.geo_id = gb.geo_id AND d.mtfcc = 'X0026'
  );

-- ─── Chambers ────────────────────────────────────────────────────────────────

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, term_length, staggered_term, policy_engagement_level)
SELECT g.id, v.name, v.name_formal, v.official_count, v.term_length, v.staggered, v.pel::essentials.policy_engagement_level
FROM essentials.governments g
CROSS JOIN (VALUES
  ('County Executive',      'King County Executive',                1, 4, false, 'full'),
  ('County Council',        'Metropolitan King County Council',     9, 4, true,  'full'),
  ('Prosecuting Attorney',  'King County Prosecuting Attorney',     1, 4, false, 'full'),
  ('Assessor',              'King County Assessor',                 1, 4, false, 'full'),
  ('Director of Elections', 'King County Director of Elections',    1, 4, false, 'full'),
  -- Appointed under the 2020 charter amendment — administrative, no compass.
  ('Sheriff',               'King County Sheriff',                  1, NULL, false, 'none')
) AS v(name, name_formal, official_count, term_length, staggered, pel)
WHERE g.geo_id = '53033' AND g.type = 'County'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = v.name
  );

-- ─── Countywide offices (5) on the COUNTY district ───────────────────────────
-- Keyed on (geo_id, district_type, mtfcc) — 53033 alone matches 3 districts.

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, is_appointed_position)
SELECT c.id, d.id, v.title, 'WA', v.appointed
FROM essentials.governments g
JOIN essentials.chambers c ON c.government_id = g.id
JOIN (VALUES
  ('County Executive',      'County Executive',      false),
  ('Prosecuting Attorney',  'Prosecuting Attorney',  false),
  ('Assessor',              'Assessor',              false),
  ('Director of Elections', 'Director of Elections', false),
  ('Sheriff',               'Sheriff',               true)
) AS v(chamber_name, title, appointed) ON c.name = v.chamber_name
CROSS JOIN essentials.districts d
WHERE g.geo_id = '53033' AND g.type = 'County'
  AND d.geo_id = '53033' AND d.district_type = 'COUNTY' AND d.mtfcc = 'G4020'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.chamber_id = c.id AND o.title = v.title
  );

-- ─── Council offices (9) on the LOCAL district rows ──────────────────────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, is_appointed_position)
SELECT c.id, d.id,
       'Councilmember, District ' || right(d.geo_id, 1),
       'WA', false
FROM essentials.governments g
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'County Council'
JOIN essentials.districts d ON d.mtfcc = 'X0026' AND d.district_type = 'LOCAL'
WHERE g.geo_id = '53033' AND g.type = 'County'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.title = 'Councilmember, District ' || right(d.geo_id, 1)
  );
