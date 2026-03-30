---
phase: quick
plan: 012
type: execute
wave: 1
depends_on: []
files_modified: []
autonomous: true

must_haves:
  truths:
    - "GET /api/essentials/representatives/me for a CA address returns both Adam Schiff and Alex Padilla as NATIONAL_UPPER senators"
    - "Padilla's office record shows title='Senator' and district_type='NATIONAL_UPPER'"
    - "The CA NATIONAL_UPPER district has geo_id='06' matching a geofence_boundaries row with the CA state polygon"
  artifacts:
    - path: "essentials.geofence_boundaries row with geo_id='06', mtfcc='G4000'"
      provides: "CA state boundary polygon for geofence intersection"
    - path: "essentials.districts row 8f76aeec-fcd4-4010-9a37-7bca1063224b"
      provides: "CA NATIONAL_UPPER district with geo_id='06'"
    - path: "essentials.offices row for Padilla"
      provides: "Senator office linked to NATIONAL_UPPER district"
  key_links:
    - from: "essentials.districts (NATIONAL_UPPER, geo_id='06')"
      to: "essentials.geofence_boundaries (geo_id='06', mtfcc='G4000')"
      via: "geo_id join in getRepresentativesByAddress geofence query"
    - from: "Padilla's office"
      to: "essentials.districts 8f76aeec-..."
      via: "district_id FK"
---

<objective>
Fix two data issues preventing CA US Senators (Schiff + Padilla) from appearing in address-based representative search.

Purpose: CA users searching by address should see both their US Senators. Currently neither appears because (1) the NATIONAL_UPPER district has blank geo_id and no state boundary polygon loaded, and (2) Padilla's office is corrupted (wrong title, wrong district).

Output: Both senators returned for any CA address via GET /api/essentials/representatives/me.
</objective>

<execution_context>
@C:\Users\Chris\.claude/get-shit-done/workflows/execute-plan.md
@C:\Users\Chris\.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@backend/src/lib/essentialsService.ts (getRepresentativesByAddress — lines 500-600 for geofence + statewide queries)

Key architecture notes:
- All `essentials.*` writes via `pool.query()` or Supabase MCP `execute_sql` — NEVER PostgREST
- The geofence query (line 516-547) joins geofence_boundaries on geo_id with MTFCC mapping. G4000 (state boundary) is NOT in the known MTFCC set, so it hits the fallback match (line 529-530) which matches any district_type — this is correct behavior.
- The statewide query (line 570-587) does NOT use geofence_boundaries — it queries `essentials.districts` directly filtered by `d.state`. So fixing Padilla's district_id is sufficient for statewide results. The geofence boundary is needed for the geofence intersection path.
- Schiff's district_id: `8f76aeec-fcd4-4010-9a37-7bca1063224b` (CA NATIONAL_UPPER)
- ogr2ogr with `active_schema=essentials` for geofence_boundaries loads
</context>

<tasks>

<task type="auto">
  <name>Task 1: Load CA state boundary and fix NATIONAL_UPPER district geo_id</name>
  <files>No code files modified — database-only changes via SQL and ogr2ogr</files>
  <action>
  **Step 1: Inspect current state**
  - Query `essentials.geofence_boundaries` schema: `SELECT column_name, data_type FROM information_schema.columns WHERE table_schema='essentials' AND table_name='geofence_boundaries' ORDER BY ordinal_position;`
  - Query the CA NATIONAL_UPPER district: `SELECT id, district_type, geo_id, state, label FROM essentials.districts WHERE id = '8f76aeec-fcd4-4010-9a37-7bca1063224b';`
  - Check if a geofence_boundaries row for geo_id='06' already exists: `SELECT geo_id, mtfcc FROM essentials.geofence_boundaries WHERE geo_id = '06';`

  **Step 2: Download and load CA state boundary**
  - Download: `wget https://www2.census.gov/geo/tiger/TIGER2024/STATE/tl_2024_us_state.zip`
  - Unzip: `unzip tl_2024_us_state.zip -d tl_2024_us_state`
  - Load CA boundary into essentials.geofence_boundaries via ogr2ogr. Use the same connection string format as prior TIGER loads in this project (key=value with `active_schema=essentials`). Filter to CA only: `-where "STATEFP='06'"`. Map fields: geo_id from GEOID (or STATEFP), mtfcc from MTFCC. The geometry column should be `geometry`.
  - Check existing ogr2ogr invocations in the repo (search for `ogr2ogr` in migration scripts or planning docs) to match the exact connection string and flag format used previously.
  - If ogr2ogr is not available or practical, fall back to extracting the geometry as WKT/GeoJSON and inserting via SQL with `ST_GeomFromGeoJSON()` or `ST_GeomFromText()`.

  **Step 3: Fix district geo_id**
  - Update the district: `UPDATE essentials.districts SET geo_id = '06' WHERE id = '8f76aeec-fcd4-4010-9a37-7bca1063224b' AND (geo_id IS NULL OR geo_id = '');`
  - Verify: `SELECT id, geo_id, state, district_type FROM essentials.districts WHERE id = '8f76aeec-fcd4-4010-9a37-7bca1063224b';`

  **Step 4: Verify geofence intersection**
  - Test point-in-polygon for a known CA address (e.g., Los Angeles City Hall: lng=-118.2437, lat=34.0522):
    ```sql
    SELECT gb.geo_id, gb.mtfcc, d.district_type, d.state
    FROM essentials.geofence_boundaries gb
    JOIN essentials.districts d ON d.geo_id = gb.geo_id
    WHERE ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-118.2437, 34.0522), 4326))
    AND d.district_type = 'NATIONAL_UPPER';
    ```
  - This should return 1 row with geo_id='06', district_type='NATIONAL_UPPER', state='CA'.
  </action>
  <verify>
  - `SELECT geo_id FROM essentials.districts WHERE id = '8f76aeec-fcd4-4010-9a37-7bca1063224b';` returns `'06'`
  - `SELECT COUNT(*) FROM essentials.geofence_boundaries WHERE geo_id = '06' AND mtfcc = 'G4000';` returns 1
  - Point-in-polygon query for LA coords returns NATIONAL_UPPER match
  </verify>
  <done>CA state boundary loaded into geofence_boundaries, NATIONAL_UPPER district geo_id set to '06', geofence intersection confirmed for CA coordinates.</done>
</task>

<task type="auto">
  <name>Task 2: Fix Padilla's corrupted office record</name>
  <files>No code files modified — database-only changes via SQL</files>
  <action>
  **Step 1: Find Padilla's records**
  - Find Padilla's politician record: `SELECT id, full_name, is_active FROM essentials.politicians WHERE last_name = 'Padilla' AND first_name ILIKE '%Alex%';`
  - Find his corrupted office: `SELECT o.id, o.title, o.district_id, o.representing_state, d.district_type, d.geo_id FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id WHERE o.politician_id = (SELECT id FROM essentials.politicians WHERE last_name = 'Padilla' AND first_name ILIKE '%Alex%' LIMIT 1);`
  - Confirm the corruption: title should be 'Councilman' and district_type should be 'LOCAL'.

  **Step 2: Update Padilla's office**
  - Update to correct district and title:
    ```sql
    UPDATE essentials.offices
    SET title = 'Senator',
        district_id = '8f76aeec-fcd4-4010-9a37-7bca1063224b',
        representing_state = 'CA'
    WHERE politician_id = (
      SELECT id FROM essentials.politicians
      WHERE last_name = 'Padilla' AND first_name ILIKE '%Alex%'
      LIMIT 1
    )
    AND title = 'Councilman';
    ```
  - If Padilla has MULTIPLE office records (e.g., the Councilman one plus others), only update the Councilman one. If he has no other office record that is already NATIONAL_UPPER, this single update is correct.

  **Step 3: Verify both senators appear**
  - Check both senators are on the same district:
    ```sql
    SELECT p.full_name, o.title, d.district_type, d.state, d.geo_id
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.politicians p ON p.id = o.politician_id
    WHERE d.id = '8f76aeec-fcd4-4010-9a37-7bca1063224b';
    ```
  - Should return 2 rows: Schiff (Senator) and Padilla (Senator), both NATIONAL_UPPER, state=CA, geo_id=06.

  - Run the full statewide query simulation for CA:
    ```sql
    SELECT p.full_name, o.title, d.district_type
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.politicians p ON o.politician_id = p.id
    WHERE d.district_type = 'NATIONAL_UPPER'
    AND d.state = 'CA'
    AND p.is_active = true;
    ```
  - Should return both Schiff and Padilla.
  </action>
  <verify>
  - Padilla's office title = 'Senator', district_id = '8f76aeec-fcd4-4010-9a37-7bca1063224b'
  - Both Schiff and Padilla returned for CA NATIONAL_UPPER district query
  - No orphaned Padilla office records pointing to wrong districts
  </verify>
  <done>Padilla's office corrected to Senator on NATIONAL_UPPER district. Both CA US Senators appear in representative queries for CA addresses.</done>
</task>

</tasks>

<verification>
1. Query the statewide path: both Schiff and Padilla returned for `d.state = 'CA' AND d.district_type = 'NATIONAL_UPPER'`
2. Query the geofence path: point-in-polygon for LA coords returns NATIONAL_UPPER district with geo_id='06'
3. Hit the live API endpoint if available: `GET /api/essentials/representatives/me` with a CA address should include both senators in the response
</verification>

<success_criteria>
- Both Adam Schiff and Alex Padilla appear as NATIONAL_UPPER senators for any CA address search
- Padilla's office shows title='Senator' (not 'Councilman')
- CA state boundary polygon exists in geofence_boundaries with geo_id='06', mtfcc='G4000'
- CA NATIONAL_UPPER district has geo_id='06'
</success_criteria>

<output>
After completion, create `.planning/quick/012-fix-ca-national-upper-senators-padilla-geofence/012-SUMMARY.md`
</output>
