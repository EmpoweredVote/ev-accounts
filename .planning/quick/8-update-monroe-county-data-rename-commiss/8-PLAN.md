---
phase: quick-8
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - EV-Backend/internal/essentials/setup.go
autonomous: false
requirements: [QUICK-8]

must_haves:
  truths:
    - "Chamber name shows 'Monroe County Board of Commissioners' in frontend"
    - "Liz Feitl appears as Monroe County Council at-large member"
    - "Cheryl Munson is inactive/removed from Monroe County Council"
    - "District council members (Iversen, Wiltz, Hawk, Crossley) exist as politicians in the DB"
    - "District council members surface for users in their respective Monroe County Council districts"
  artifacts:
    - path: "EV-Backend/internal/essentials/setup.go"
      provides: "Idempotent SQL to rename chamber, update government_bodies, and seed politicians"
  key_links:
    - from: "essentials.chambers.name_formal"
      to: "essentials.government_bodies.body_key"
      via: "COALESCE(name_formal, name) JOIN"
      pattern: "Monroe County Board of Commissioners"
    - from: "essentials.offices.district_id"
      to: "essentials.geofence_boundaries.geo_id"
      via: "PostGIS ST_Covers point lookup"
      pattern: "1810500001-1810500004"
---

<objective>
Update Monroe County data in EV-Backend: rename the Commission chamber, replace Cheryl Munson with Liz Feitl on the Council, seed district council members (Districts 1-4), and verify district geofences exist so district members surface correctly.

Purpose: Reflect current 2025 Monroe County officials and correct the Commission chamber name to its formal legal name.
Output: Updated setup.go with idempotent SQL, politicians + offices seeded via psql migration, photos uploaded to Supabase.
</objective>

<execution_context>
@/Users/chrisandrews/.claude/get-shit-done/workflows/execute-plan.md
@/Users/chrisandrews/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md

<!-- Key data model facts the executor needs — no codebase exploration required. -->

**Chamber rename target:**
- Current `name_formal`: `'Monroe County Commission'`
- Target `name_formal`: `'Monroe County Board of Commissioners'`
- Matched by: `WHERE name LIKE 'Monroe County Commission%'`
- setup.go line 79 sets name_formal for this chamber (idempotent guard: `WHERE name_formal = '' OR name_formal IS NULL`)
- `government_bodies` table has a row with `body_key = 'Monroe County Commission'` (line 126 in setup.go) — this key must also be renamed since the JOIN uses `COALESCE(name_formal, name)` as the body_key lookup

**Government bodies insert (setup.go ~line 122):**
- Uses `ON CONFLICT (state, geo_id, body_key) DO NOTHING` — so changing the body_key requires deleting the old row and inserting the new one (or a separate UPDATE)
- Commission geo_id: `'18105'`, state: `'IN'`

**Monroe County Council geo_ids in government_bodies:**
- At-large: `'18105'` (same as county-wide)
- District 1: `'1810500001'`
- District 2: `'1810500002'`
- District 3: `'1810500003'`
- District 4: `'1810500004'`

**Politician add/deactivate pattern:**
The system does NOT have a built-in "deactivate" CLI. Politician and office records are managed directly via psql or a migration SQL file. Pattern from existing data (from previous phases): insert into `essentials.politicians`, then insert into `essentials.offices` linking politician to the district's chamber.

**Geofence boundary lookup flow:**
1. `FindGeoIDsByPoint` → ST_Covers query against `essentials.geofence_boundaries`
2. Returns `(geo_id, mtfcc)` pairs
3. `FindPoliticiansByGeoMatches` → JOINs `essentials.offices → essentials.districts` on `geo_id`
4. District members for `1810500001`-`1810500004` will only surface if matching `geofence_boundaries` rows exist

**MTFCC for county council sub-districts:**
Use `'X0001'` — the custom MTFCC for city/county council sub-districts (see geofence_lookup.go line 34). The `mtfccToDistrictTypes` map routes `X0001` to `["LOCAL"]`, so districts must have `district_type = 'LOCAL'` or `'COUNTY'`.

**District records for Monroe County Council districts:**
These districts likely exist in `essentials.districts` already (from BallotReady import) with geo_ids `1810500001`-`1810500004`. What may be MISSING is the corresponding `geofence_boundaries` geometry rows.
</context>

<tasks>

<task type="auto">
  <name>Task 1: Rename Commission chamber and update government_bodies in setup.go</name>
  <files>EV-Backend/internal/essentials/setup.go</files>
  <action>
Make two targeted edits to setup.go:

**Edit 1 — Chamber name_formal rename (line ~79):**
Change:
```go
db.DB.Exec(`UPDATE essentials.chambers SET name_formal = 'Monroe County Commission' WHERE name LIKE 'Monroe County Commission%' AND (name_formal = '' OR name_formal IS NULL)`)
```
To:
```go
db.DB.Exec(`UPDATE essentials.chambers SET name_formal = 'Monroe County Board of Commissioners' WHERE name LIKE 'Monroe County Commission%'`)
```
Note: Remove the `AND (name_formal = '' OR name_formal IS NULL)` guard so it also updates rows where name_formal was already set to the old value. This makes it an unconditional rename that is safe to run repeatedly.

**Edit 2 — government_bodies Commission row (line ~126):**
The `ON CONFLICT DO NOTHING` means the old `body_key = 'Monroe County Commission'` row will persist. Add an explicit UPDATE before the INSERT block to rename the existing row and update the display name:
```go
// Quick-8: Rename Commission body_key to match new name_formal
db.DB.Exec(`UPDATE essentials.government_bodies
  SET body_key = 'Monroe County Board of Commissioners',
      display_name = 'Monroe County Board of Commissioners',
      website_url = 'https://www.in.gov/counties/monroe/government/commissioners/'
  WHERE state = 'IN' AND geo_id = '18105' AND body_key = 'Monroe County Commission'`)
```
Place this UPDATE immediately before the large INSERT block (around line 122). This is idempotent — if the body_key is already renamed, the WHERE clause finds no rows.

**Also update the INSERT block value** (line ~126) so future clean installs use the new name:
Change:
```
('IN', '18105', 'Monroe County Commission', 'Monroe County Commission', 'https://www.in.gov/counties/monroe/government/commissioners/'),
```
To:
```
('IN', '18105', 'Monroe County Board of Commissioners', 'Monroe County Board of Commissioners', 'https://www.in.gov/counties/monroe/government/commissioners/'),
```

After editing, run `cd EV-Backend && go build -o server . && echo "BUILD OK"` to confirm no syntax errors.
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub/EV-Backend && go build -o server . && echo "BUILD OK"</automated>
  </verify>
  <done>Build passes. setup.go contains `Monroe County Board of Commissioners` in both the UPDATE and INSERT locations. The old `Monroe County Commission` string no longer appears as a target value (only as a legacy cleanup WHERE condition).</done>
</task>

<task type="auto">
  <name>Task 2: Seed council member changes via migration SQL file</name>
  <files>EV-Backend/internal/essentials/data/migrate_quick8_council.sql</files>
  <action>
Create a one-time SQL migration file at `EV-Backend/internal/essentials/data/migrate_quick8_council.sql`.

This file is run manually via `psql $DATABASE_URL -f migrate_quick8_council.sql` — it is NOT added to setup.go's AutoMigrate (one-time data, not structural).

The SQL must:

**1. Deactivate Cheryl Munson:**
Find her office record linked to Monroe County Council and mark it vacant (or find her politician record and mark inactive). Use a safe approach that doesn't break foreign keys:
```sql
-- Deactivate Cheryl Munson's Monroe County Council office
UPDATE essentials.offices o
SET is_vacant = true, vacant_since = CURRENT_DATE
WHERE o.politician_id = (
  SELECT p.id FROM essentials.politicians p
  WHERE lower(p.first_name) = 'cheryl' AND lower(p.last_name) = 'munson'
  LIMIT 1
)
AND o.chamber_id IN (
  SELECT id FROM essentials.chambers WHERE name LIKE 'Monroe County Council%'
);
```

**2. Add Liz Feitl as at-large Monroe County Council member:**
```sql
-- Insert Liz Feitl as Monroe County Council at-large member
-- Step 1: Create politician record (idempotent via ON CONFLICT DO NOTHING on slug)
INSERT INTO essentials.politicians (first_name, last_name, full_name, slug, party, is_appointed)
VALUES ('Liz', 'Feitl', 'Liz Feitl', 'liz-feitl-monroe-county-council', '', false)
ON CONFLICT (slug) DO NOTHING;

-- Step 2: Create office linking Feitl to at-large Monroe County Council district (geo_id '18105', district_type COUNTY)
INSERT INTO essentials.offices (politician_id, chamber_id, district_id, title, normalized_position_name, seats, is_vacant)
SELECT
  p.id,
  c.id,
  d.id,
  'Monroe County Council Member',
  'County Council Member',
  1,
  false
FROM essentials.politicians p
CROSS JOIN essentials.chambers c
CROSS JOIN essentials.districts d
WHERE p.slug = 'liz-feitl-monroe-county-council'
  AND c.name LIKE 'Monroe County Council%'
  AND d.geo_id = '18105'
  AND d.district_type IN ('COUNTY', 'LOCAL')
  AND c.id IN (SELECT chamber_id FROM essentials.offices WHERE district_id = d.id LIMIT 1)
LIMIT 1
ON CONFLICT DO NOTHING;
```

**3. Add district council members (Districts 1-4) — idempotent:**
For each of the 4 district members (Peter Iversen D1, Kate Wiltz D2, Marty Hawk D3, Jennifer Crossley D4):

```sql
-- District 1: Peter Iversen
INSERT INTO essentials.politicians (first_name, last_name, full_name, slug, party, is_appointed)
VALUES ('Peter', 'Iversen', 'Peter Iversen', 'peter-iversen-monroe-county-council-d1', '', false)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO essentials.offices (politician_id, chamber_id, district_id, title, normalized_position_name, seats, is_vacant)
SELECT p.id, c.id, d.id, 'Monroe County Council Member - District 1', 'County Council Member', 1, false
FROM essentials.politicians p, essentials.chambers c, essentials.districts d
WHERE p.slug = 'peter-iversen-monroe-county-council-d1'
  AND c.name LIKE 'Monroe County Council%'
  AND d.geo_id = '1810500001'
LIMIT 1
ON CONFLICT DO NOTHING;

-- District 2: Kate Wiltz
INSERT INTO essentials.politicians (first_name, last_name, full_name, slug, party, is_appointed)
VALUES ('Kate', 'Wiltz', 'Kate Wiltz', 'kate-wiltz-monroe-county-council-d2', '', false)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO essentials.offices (politician_id, chamber_id, district_id, title, normalized_position_name, seats, is_vacant)
SELECT p.id, c.id, d.id, 'Monroe County Council Member - District 2', 'County Council Member', 1, false
FROM essentials.politicians p, essentials.chambers c, essentials.districts d
WHERE p.slug = 'kate-wiltz-monroe-county-council-d2'
  AND c.name LIKE 'Monroe County Council%'
  AND d.geo_id = '1810500002'
LIMIT 1
ON CONFLICT DO NOTHING;

-- District 3: Marty Hawk
INSERT INTO essentials.politicians (first_name, last_name, full_name, slug, party, is_appointed)
VALUES ('Marty', 'Hawk', 'Marty Hawk', 'marty-hawk-monroe-county-council-d3', '', false)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO essentials.offices (politician_id, chamber_id, district_id, title, normalized_position_name, seats, is_vacant)
SELECT p.id, c.id, d.id, 'Monroe County Council Member - District 3', 'County Council Member', 1, false
FROM essentials.politicians p, essentials.chambers c, essentials.districts d
WHERE p.slug = 'marty-hawk-monroe-county-council-d3'
  AND c.name LIKE 'Monroe County Council%'
  AND d.geo_id = '1810500003'
LIMIT 1
ON CONFLICT DO NOTHING;

-- District 4: Jennifer Crossley
INSERT INTO essentials.politicians (first_name, last_name, full_name, slug, party, is_appointed)
VALUES ('Jennifer', 'Crossley', 'Jennifer Crossley', 'jennifer-crossley-monroe-county-council-d4', '', false)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO essentials.offices (politician_id, chamber_id, district_id, title, normalized_position_name, seats, is_vacant)
SELECT p.id, c.id, d.id, 'Monroe County Council Member - District 4', 'County Council Member', 1, false
FROM essentials.politicians p, essentials.chambers c, essentials.districts d
WHERE p.slug = 'jennifer-crossley-monroe-county-council-d4'
  AND c.name LIKE 'Monroe County Council%'
  AND d.geo_id = '1810500004'
LIMIT 1
ON CONFLICT DO NOTHING;
```

After writing the file, do a dry-run check:
```bash
cd EV-Backend && psql "$DATABASE_URL" -f internal/essentials/data/migrate_quick8_council.sql
```

If `essentials.districts` rows for geo_ids `1810500001`-`1810500004` do NOT exist, the CROSS JOIN WHERE clauses return zero rows (the INSERT selects nothing). In that case, note in the summary that district records must be created — this is handled in Task 3.

**IMPORTANT:** Also check if the `offices` table has a unique constraint that would cause the `ON CONFLICT DO NOTHING` to work correctly. If offices has no unique constraint on (politician_id, chamber_id), use a `WHERE NOT EXISTS` guard instead.
  </action>
  <verify>
    <automated>psql "$DATABASE_URL" -c "SELECT p.full_name, d.geo_id, o.title FROM essentials.politicians p JOIN essentials.offices o ON o.politician_id = p.id JOIN essentials.districts d ON d.id = o.district_id WHERE p.slug LIKE '%monroe-county-council%' ORDER BY d.geo_id;"</automated>
  </verify>
  <done>Query returns rows for Liz Feitl (geo_id 18105), Peter Iversen (1810500001), Kate Wiltz (1810500002), Marty Hawk (1810500003), Jennifer Crossley (1810500004). Cheryl Munson's office shows is_vacant=true.</done>
</task>

<task type="checkpoint:human-verify">
  <what-built>
    Task 1 renamed the Commission chamber to "Monroe County Board of Commissioners" in setup.go (chambers + government_bodies).
    Task 2 created migrate_quick8_council.sql with deactivation of Munson, insertion of Feitl + 4 district members.
    Migration was run against the database.
    Still needed (human steps before approving):
    - Upload photos for Feitl, Iversen, Wiltz, Hawk, Crossley to Supabase `politician-photos` storage bucket
    - Update `politicians.photo_custom_url` for each new politician with their Supabase CDN URL
    - Verify district geofence boundaries exist for geo_ids 1810500001-1810500004 — if missing, the district members will NOT surface on address search
  </what-built>
  <how-to-verify>
    **Step 1 — Verify chamber rename:**
    ```
    psql "$DATABASE_URL" -c "SELECT name, name_formal FROM essentials.chambers WHERE name LIKE 'Monroe County Commission%';"
    ```
    Expected: name_formal = 'Monroe County Board of Commissioners'

    **Step 2 — Verify government_bodies rename:**
    ```
    psql "$DATABASE_URL" -c "SELECT body_key, display_name FROM essentials.government_bodies WHERE state='IN' AND geo_id='18105';"
    ```
    Expected: 'Monroe County Board of Commissioners' row exists, no 'Monroe County Commission' row

    **Step 3 — Verify council members:**
    ```
    psql "$DATABASE_URL" -c "SELECT p.full_name, d.geo_id, o.is_vacant FROM essentials.politicians p JOIN essentials.offices o ON o.politician_id=p.id JOIN essentials.districts d ON d.id=o.district_id WHERE p.full_name ILIKE '%munson%' OR p.slug ILIKE '%monroe-county-council%' ORDER BY d.geo_id;"
    ```

    **Step 4 — Check if district geofences exist:**
    ```
    psql "$DATABASE_URL" -c "SELECT geo_id, name, mtfcc FROM essentials.geofence_boundaries WHERE geo_id IN ('1810500001','1810500002','1810500003','1810500004');"
    ```
    If this returns 0 rows: district members exist in the DB but will NOT appear on address search. You need to import Monroe County Council district boundary shapefiles. Source: https://www.in.gov/gis/ (Indiana GIS data), or request from Monroe County GIS. Import using the same TIGER import pattern as other custom districts, with mtfcc='X0001'.

    **Step 5 — Upload politician photos:**
    - Source photos from: https://www.in.gov/counties/monroe/government/council/
    - Upload each to Supabase Storage bucket `politician-photos`
    - Run: `psql "$DATABASE_URL" -c "UPDATE essentials.politicians SET photo_custom_url = 'https://[supabase-url]/storage/v1/object/public/politician-photos/[filename]' WHERE slug = '[slug]';"`

    **Step 6 — Functional test:**
    Enter a Bloomington, IN address in the essentials frontend (e.g. a Monroe County address outside city limits) and confirm "Monroe County Board of Commissioners" appears in the Local section.
  </how-to-verify>
  <resume-signal>Type "approved" once chamber rename + council members are verified. Note any geofence or photo gaps in your response.</resume-signal>
</task>

</tasks>

<verification>
- `go build` passes on EV-Backend after setup.go edits
- psql migration runs without errors
- Chamber name_formal = 'Monroe County Board of Commissioners' in DB
- government_bodies body_key updated to 'Monroe County Board of Commissioners'
- 5 new/updated politician+office rows for Monroe County Council
- Cheryl Munson office marked vacant
- District geofence status noted (may require follow-up import)
</verification>

<success_criteria>
- "Monroe County Board of Commissioners" appears in frontend for Monroe County addresses
- Liz Feitl appears as at-large council member
- 4 district council members in DB with correct district linkage
- Cheryl Munson no longer shows as active council member
- Photos uploaded and linked (or explicitly deferred with note)
</success_criteria>

<output>
After completion, create `.planning/quick/8-update-monroe-county-data-rename-commiss/8-SUMMARY.md`
</output>
