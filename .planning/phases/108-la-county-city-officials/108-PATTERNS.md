# Phase 108: LA County City Officials - Pattern Map

**Mapped:** 2026-06-08
**Files analyzed:** 4 migration tiers (Wave 1 gap-fill, Wave 2 structure-exists, Wave 3 new cities, Wave 4 geo_id backfill)
**Analogs found:** 5 / 5

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `backend/migrations/293_la_wave1_gap_fill.sql` (Wave 1, one per city group) | migration | batch | `backend/migrations/218_sj_officials.sql` | exact |
| `backend/migrations/29X_la_wave2_bh_sm_la_offices.sql` (Wave 2) | migration | batch | `backend/migrations/199_sf_officials.sql` | exact |
| `backend/migrations/29Y_la_wave3_new_city_structure.sql` (Wave 3, government structure) | migration | batch | `backend/migrations/217_sj_government_structure.sql` | exact |
| `backend/migrations/29Z_la_wave3_new_city_officials.sql` (Wave 3, politicians) | migration | batch | `backend/migrations/218_sj_officials.sql` + `199_sf_officials.sql` | exact |
| `backend/migrations/2WW_la_geo_id_backfill.sql` (geo_id UPDATE) | migration | transform | `backend/migrations/115_la_city_attorney_controller_district.sql` | role-match |

**Note on migration numbers:** Last applied migration is `292_md_delegates_batch_g.sql`. Next available number is **293**. Always run `ls backend/migrations/ | sort -V | tail -5` before assigning numbers.

---

## Pattern Assignments

### Wave 1: Gap-Fill Existing Partial Cities

**Analog:** `backend/migrations/218_sj_officials.sql` (lines 29–416)

These cities already have `essentials.governments`, `essentials.chambers`, and `essentials.districts` rows. The migration only needs to INSERT missing politicians + their office rows, plus UPDATE `geo_id` on any districts where it is NULL.

**Pre-flight pattern** — run this before writing each city's migration:
```sql
SELECT p.full_name, p.is_incumbent, o.title, d.geo_id, d.district_type
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '<CITY_FIPS>'
ORDER BY d.geo_id, o.title;
```

**geo_id backfill for existing districts** (lines from `115_la_city_attorney_controller_district.sql`):
```sql
-- Update geo_id on existing district rows that are missing it.
-- Use IS DISTINCT FROM to make the UPDATE idempotent.
UPDATE essentials.districts
SET geo_id = '<CITY_FIPS>'
WHERE label LIKE '<City Name>%'
  AND state = 'CA'
  AND district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND geo_id IS DISTINCT FROM '<CITY_FIPS>';
```

**Core politician + office INSERT** (analog: `218_sj_officials.sql` lines 35–66 for by-district; `199_sf_officials.sql` lines 261–278 for citywide/at-large mayor):
```sql
BEGIN;
-- One block per missing politician. No government/chamber/district creation needed.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Rex Richardson', 'Rex', 'Richardson', NULL,
          true, false, false, true, -700050,
          'https://www.longbeach.gov/mayor/about/')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Mayor'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Long Beach' AND state = 'CA')),
       p.id,
       'Mayor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0643000'
  AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Back-fill office_id on all newly inserted politicians
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -700099 AND -700050
  AND p.office_id IS NULL;

COMMIT;
```

**Key differences from prior migrations (Long Beach Mayor is LOCAL_EXEC, not a named slug district):**
- Long Beach has a separately elected Mayor → attach to citywide district using `district_type IN ('LOCAL', 'LOCAL_EXEC')` filter on the FIPS geo_id
- By-district council members → filter on the district-specific slug geo_id (e.g., `'lb-council-district-1'` if that's what's in the DB, or the FIPS if that's what was used)
- At-large councils (Glendale) → all members filter on the single at-large LOCAL district geo_id

---

### Wave 2: Beverly Hills + Santa Monica + LA City Citywide Offices

**Analog A (at-large council members):** `backend/migrations/199_sf_officials.sql` lines 25–43 (Board of Supervisors per-district) adapted for at-large: all members point to the same single LOCAL district.

**Analog B (citywide elected officials):** `backend/migrations/199_sf_officials.sql` lines 260–278 (Mayor linked to LOCAL_EXEC district via FIPS geo_id).

**Analog C (LA City office link):** `backend/migrations/115_la_city_attorney_controller_district.sql` — the City Controller office UUID `e5435b0e-c7a7-4c93-9b4f-cc647db0b9f6` is already known; just INSERT the politician and the office row FK.

**At-large council pattern** (Beverly Hills, Santa Monica) — all members FK to the same LOCAL district:
```sql
BEGIN;
-- All 5 Beverly Hills council members point to geo_id='0606308' LOCAL district.
-- Pre-flight: verify how many office rows exist for BH in essentials.offices.
-- If < 5, create additional office rows before inserting politicians.

WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Lester Friedman', 'Lester', 'Friedman', NULL,
          true, false, false, true, -700010,
          'https://www.beverlyhills.org/cbhfiles/storage/files/...')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Beverly Hills' AND state = 'CA')),
       p.id,
       'Councilmember', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0606308'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );
-- Repeat for each additional council member with the same district filter.

-- LA City Controller (office row already exists at known UUID)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Kenneth Mejia', 'Kenneth', 'Mejia', NULL,
          true, false, false, true, -700001,
          'https://controller.lacity.gov/about')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Controller'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Los Angeles' AND state = 'CA')),
       p.id,
       'City Controller', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0644000'
  AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );
-- NOTE: City Attorney office (5a873c59-72ac-488f-8b2c-44dfd04d065c) — DO NOT INSERT
-- politician. Seat is vacant (runoff Nov 2026). Add comment only.

COMMIT;
```

---

### Wave 3: 10 New Cities (Government Structure + Officials)

**Analog A (government structure — by-district city):** `backend/migrations/217_sj_government_structure.sql` (entire file, 98 lines)

**Analog B (government structure — at-large city):** `backend/migrations/210_fremont_government_structure.sql` adapted: for an at-large city, instead of N named slug districts, create ONE LOCAL district with `geo_id = CITY_FIPS` and label `'[City Name] (At-Large)'`.

**Analog C (officials — by-district):** `backend/migrations/218_sj_officials.sql`

**Analog D (officials — citywide elected: Mayor, Treasurer, Clerk):** `backend/migrations/199_sf_officials.sql` lines 260–320

**Government structure — at-large city pattern** (South Gate, Compton Mayor, Hawthorne, Culver City, West Hollywood, El Segundo, Gardena Mayor, Glendale-style):
```sql
BEGIN;

-- Step 1: Government stub
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of South Gate', 'LOCAL', 'CA', 'South Gate', '0673080'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of South Gate' AND state = 'CA'
);

-- Step 2: Chambers (slug is GENERATED ALWAYS AS — NEVER include in INSERT column list)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Council', 'South Gate City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of South Gate' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of South Gate' AND state = 'CA')
);

-- Step 3: Single LOCAL district for at-large council (geo_id = FIPS, NOT named slug)
-- CRITICAL: NO ON CONFLICT — constraint (geo_id, district_type) does not exist
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0673080', 'LOCAL', 'South Gate (At-Large)', 'CA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0673080' AND district_type = 'LOCAL' AND state = 'CA'
);
-- NOTE: South Gate has no separately elected Mayor (rotates) — NO LOCAL_EXEC district.

COMMIT;
```

**Government structure — by-district city with separately elected Mayor** (Compton, Carson, Whittier):
```sql
BEGIN;

-- Step 1: Government stub
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of Compton', 'LOCAL', 'CA', 'Compton', '0615044'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of Compton' AND state = 'CA'
);

-- Step 2: Chambers
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Council', 'Compton City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Compton' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Compton' AND state = 'CA')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'Mayor', 'Mayor of Compton',
       (SELECT id FROM essentials.governments WHERE name = 'City of Compton' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers WHERE name = 'Mayor'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Compton' AND state = 'CA')
);

-- Step 3: 4 LOCAL district rows (one per council district)
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT v.geo_id, v.district_type, v.label, v.state
FROM (VALUES
  ('compton-council-district-1', 'LOCAL', 'District 1', 'CA'),
  ('compton-council-district-2', 'LOCAL', 'District 2', 'CA'),
  ('compton-council-district-3', 'LOCAL', 'District 3', 'CA'),
  ('compton-council-district-4', 'LOCAL', 'District 4', 'CA')
) AS v(geo_id, district_type, label, state)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = v.geo_id AND d.district_type = v.district_type AND d.state = v.state
);

-- Step 4: LOCAL_EXEC district for Mayor (citywide)
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0615044', 'LOCAL_EXEC', 'Compton (Citywide)', 'CA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0615044' AND state = 'CA' AND district_type IN ('LOCAL', 'LOCAL_EXEC')
);

COMMIT;
```

**Alhambra — 5 by-district seats, no separately elected Mayor** (no LOCAL_EXEC needed):
```sql
-- 5 district rows, no LOCAL_EXEC, no Mayor chamber.
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT v.geo_id, v.district_type, v.label, v.state
FROM (VALUES
  ('alhambra-council-district-1', 'LOCAL', 'District 1', 'CA'),
  ('alhambra-council-district-2', 'LOCAL', 'District 2', 'CA'),
  ('alhambra-council-district-3', 'LOCAL', 'District 3', 'CA'),
  ('alhambra-council-district-4', 'LOCAL', 'District 4', 'CA'),
  ('alhambra-council-district-5', 'LOCAL', 'District 5', 'CA')
) AS v(geo_id, district_type, label, state)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = v.geo_id AND d.district_type = v.district_type AND d.state = v.state
);
-- DO NOT create a Mayor chamber or LOCAL_EXEC district — Alhambra Mayor is a rotational title.
```

**Officials — appointed position** (Patrice Lattimore, LA City Clerk):
```sql
-- Analog: 199_sf_officials.sql lines 410-429 (appointed officials use is_appointed_position=true on office)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Patrice Lattimore', 'Patrice', 'Lattimore', NULL,
          true, true, false, true, -700002,
          'https://clerk.lacity.gov/about-the-office')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Clerk'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Los Angeles' AND state = 'CA')),
       p.id,
       'City Clerk', 'CA', true, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0644000'
  AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );
-- Note: is_appointed_position = true on office; is_appointed = true on politician
-- because Lattimore was appointed by City Council (not popularly elected).
```

---

## Shared Patterns

### BEGIN / COMMIT Wrapper
**Source:** All migrations 199, 207, 210, 214, 217, 218 (first and last line of every file)
**Apply to:** Every Wave 1, 2, 3 migration file
```sql
BEGIN;
-- ... migration content ...
COMMIT;
```

### politician + office CTE Pattern (idempotent)
**Source:** `backend/migrations/218_sj_officials.sql` lines 35–66 and `199_sf_officials.sql` lines 25–43
**Apply to:** Every politician insert in every wave
```sql
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), '[Full Name]', '[First]', '[Last]', NULL,
          true, false, false, true, -7XXXXX, '[photo_url]')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='[Chamber Name]'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of [Name]' AND state='CA')),
       p.id,
       '[Title]', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '[FIPS_OR_SLUG]'
  AND d.district_type [= 'LOCAL' OR IN ('LOCAL','LOCAL_EXEC')]
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );
```

### office_id Back-fill Pattern
**Source:** `backend/migrations/218_sj_officials.sql` lines 410–415, `199_sf_officials.sql` lines 456–461
**Apply to:** End of every migration file that inserts politicians
```sql
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -7XXXXX AND -7YYYYY
  AND p.office_id IS NULL;
```

### Government Stub — WHERE NOT EXISTS Guard
**Source:** `backend/migrations/217_sj_government_structure.sql` lines 28–33
**Apply to:** Every Wave 3 government row insert
```sql
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of [Name]', 'LOCAL', 'CA', '[Name]', '[FIPS]'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of [Name]' AND state = 'CA'
);
```

### Chamber Insert — slug is GENERATED, Never Included
**Source:** `backend/migrations/217_sj_government_structure.sql` lines 43–50, comments lines 13–14
**Apply to:** Every chamber INSERT in Wave 3
```sql
-- CRITICAL: slug is a GENERATED ALWAYS AS column — never include in INSERT column list
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), '[Name]', '[Formal Name]',
       (SELECT id FROM essentials.governments WHERE name = 'City of [Name]' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = '[Name]'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of [Name]' AND state = 'CA')
);
```

### District Insert — NO ON CONFLICT, Use WHERE NOT EXISTS
**Source:** `backend/migrations/217_sj_government_structure.sql` lines 68–85, comment lines 15–16
**Apply to:** Every district INSERT in Waves 2 and 3
```sql
-- CRITICAL: NO ON CONFLICT (geo_id, district_type) — that constraint does not exist.
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '[geo_id]', 'LOCAL', '[Label]', 'CA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '[geo_id]' AND district_type = 'LOCAL' AND state = 'CA'
);
```

### party = NULL — Antipartisan Design
**Source:** `backend/migrations/218_sj_officials.sql` lines 18–19, all city official migrations
**Apply to:** Every `INSERT INTO essentials.politicians` — party column must always be `NULL`

### photo_origin_url — Required on Every Politician Insert
**Source:** `backend/migrations/215_berkeley_headshots.sql` lines 49–51 (UPDATE pattern); D-spec in CONTEXT.md
**Apply to:** Every INSERT into essentials.politicians in this phase

The `photo_origin_url` can be set directly in the INSERT (preferred for new cities) or via a subsequent UPDATE (headshot audit pattern). For this phase, include it in the INSERT:
```sql
-- In the INSERT VALUES list:
photo_origin_url = 'https://[source_url_for_this_politicians_photo]'
-- Acceptable sources: Official city portrait page, Wikipedia portrait thumbnail URL.
-- Never NULL for any record in this phase.
```

---

## Pre-Flight Verification Pattern

Before writing any migration for a city, confirm the live DB state:
```sql
-- Count existing politicians by city FIPS
SELECT COUNT(*), d.geo_id, d.district_type
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id IN ('<CITY_FIPS>')
GROUP BY d.geo_id, d.district_type;

-- Confirm external_id range is clean
SELECT COUNT(*) FROM essentials.politicians
WHERE external_id BETWEEN -700699 AND -700001;
-- Expected: 0 before first Wave migration is applied
```

---

## Known Pitfalls from Analog Analysis

| Pitfall | Analog Evidence | Prevention |
|---------|----------------|------------|
| Including `slug` in chamber INSERT | Migration 217 comment lines 13-14 | Never list `slug` in INSERT column list |
| `ON CONFLICT (geo_id, district_type)` on districts | Migration 217 comment line 15 | Always use `WHERE NOT EXISTS` guard |
| `district_type = 'LOCAL'` for Mayor of at-large city | Migration 199 lines 274-276 | Use `IN ('LOCAL','LOCAL_EXEC')` for FIPS district lookup |
| Omitting `photo_origin_url` | D-spec, migration 215 | Include in every VALUES row |
| `party` set to non-NULL | All city migrations | Always set `party = NULL` |
| Missing `office_id` back-fill | Migrations 199 Section 4, 218 Section 3 | Always add UPDATE at end of file |
| Alhambra Mayor as separate office | RESEARCH.md Pitfall 7 | No LOCAL_EXEC district, no Mayor chamber |
| Beverly Hills needing 5 offices (DB may only have 3) | RESEARCH.md Pitfall 10 | Pre-flight query before Wave 2 |
| LA City Attorney office vacant | RESEARCH.md Critical Finding 1 | Skip politician insert; comment only |
| Holly Wolcott as City Clerk | RESEARCH.md Critical Finding 2 | Insert Patrice Lattimore (appointed) |

---

## LA City Known UUIDs (from migration 115)

| Entity | UUID |
|--------|------|
| LA City Attorney office | `5a873c59-72ac-488f-8b2c-44dfd04d065c` |
| LA City Controller office | `e5435b0e-c7a7-4c93-9b4f-cc647db0b9f6` |
| LA City LOCAL_EXEC district (geo_id=0644000) | `feeb6b8c-f099-47b8-80eb-f984560d3d6e` |

---

## No Analog Found

All migration patterns required for this phase have direct analogs in the codebase. No new patterns need to be invented.

The RESEARCH.md canonical pattern (government → chambers → districts → politicians/offices → office_id back-fill) is fully realized in `217_sj_government_structure.sql` + `218_sj_officials.sql` as a pair, and in `199_sf_officials.sql` for citywide/at-large officials.

---

## Metadata

**Analog search scope:** `backend/migrations/` — migrations 075, 077, 115, 199, 207, 208, 210, 214, 215, 217, 218, 219, 220
**Files scanned:** 13
**Pattern extraction date:** 2026-06-08
