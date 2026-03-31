---
phase: quick
plan: 011
type: execute
wave: 1
depends_on: []
files_modified:
  - backend/migrations/046_resolve_user_local_officials.sql
  - backend/src/lib/essentialsService.ts
  - backend/src/routes/essentials.ts
autonomous: true

must_haves:
  truths:
    - "GET /essentials/representatives/me returns Karen Bass (LOCAL_EXEC) for user at 12048 Culver Blvd LA 90066"
    - "GET /essentials/representatives/me returns Traci Park (LOCAL, City Council District 11) for same user"
    - "Path 1 (geo_id lookup) is used, not Path 2 (Census Geocoder fallback)"
    - "Result count is ~17-20, not ~67 (no duplicate explosion)"
  artifacts:
    - path: "backend/migrations/046_resolve_user_local_officials.sql"
      provides: "RPC to decrypt coords and return LOCAL/LOCAL_EXEC geo_ids"
      contains: "connect.resolve_user_local_officials"
    - path: "backend/src/lib/essentialsService.ts"
      provides: "getLocalOfficialsByUserId function"
    - path: "backend/src/routes/essentials.ts"
      provides: "Path 1 hybrid that merges local officials into response"
  key_links:
    - from: "backend/src/routes/essentials.ts"
      to: "connect.resolve_user_local_officials"
      via: "pool.query RPC call"
      pattern: "resolve_user_local_officials"
    - from: "backend/src/routes/essentials.ts"
      to: "essentialsService.ts"
      via: "getLocalOfficialsByUserId or inline query"
      pattern: "LOCAL.*LOCAL_EXEC"
---

<objective>
Fix BUG-03: city/local officials (mayors, city council members) missing from GET /essentials/representatives/me Path 1.

Purpose: Path 1 uses pre-computed geo_ids for 5 district types but LOCAL/LOCAL_EXEC districts require coordinate-based PostGIS lookup (city council districts are sub-city polygons). After quick-008 populated geo_ids, Path 2 (Census Geocoder fallback) no longer runs, so local officials disappeared entirely.

Output: Hybrid Path 1 that supplements geo_id lookup with a coordinate-based PostGIS query for LOCAL/LOCAL_EXEC types.
</objective>

<execution_context>
@C:\Users\Chris\.claude/get-shit-done/workflows/execute-plan.md
@C:\Users\Chris\.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@backend/migrations/045_fix_resolve_user_jurisdiction.sql (RPC pattern to follow exactly)
@backend/src/routes/essentials.ts (lines 346-414 = representatives/me route)
@backend/src/lib/essentialsService.ts (lines 1290-1467 = getRepresentativesByJurisdiction, lines 470-590 = getRepresentativesByAddress with LOCAL MTFCC mappings)
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create resolve_user_local_officials RPC</name>
  <files>backend/migrations/046_resolve_user_local_officials.sql</files>
  <action>
Create a new Postgres RPC `connect.resolve_user_local_officials(p_user_id uuid)` that returns a table of geo_ids for LOCAL and LOCAL_EXEC district types.

Follow the EXACT same pattern as `connect.resolve_user_jurisdiction` in migration 045:
- `SECURITY DEFINER`, `SET search_path = ''`
- Fetch vault key from `vault.decrypted_secrets WHERE name = 'location_encryption_key'`
- Fetch `encrypted_lat`, `encrypted_lng` from `connect.connected_profiles WHERE user_id = p_user_id AND location_consent = true`
- Decrypt via `extensions.pgp_sym_decrypt_bytea` + `convert_from(..., 'UTF8')::float8`
- Build point: `public.ST_SetSRID(public.ST_MakePoint(v_lng, v_lat), 4326)` (LONGITUDE FIRST)
- Query `essentials.geofence_boundaries gb JOIN essentials.districts d ON d.geo_id = gb.geo_id`
- MTFCC mapping for LOCAL/LOCAL_EXEC (copy from getRepresentativesByAddress):
  - `gb.mtfcc = 'G4040' AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')`
  - `gb.mtfcc IN ('G4110', 'G4120') AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')`
  - `gb.mtfcc LIKE 'X%' AND d.district_type = 'LOCAL'` (X-prefixed custom boundaries)
- Use `WHERE public.ST_Covers(gb.geometry, v_point)`
- Return type: `TABLE(geo_id text, district_type text)` (not jsonb — caller needs to iterate)
- Return empty set (not error) if no encrypted coords found — caller handles gracefully

IMPORTANT: Do NOT include the COUNTY match from X-prefixed MTFCCs (that is already handled by pre-computed county_geo_id). Only return LOCAL and LOCAL_EXEC types.

Apply this migration via Supabase MCP `apply_migration` (this is production).
  </action>
  <verify>
Run via Supabase MCP execute_sql:
```sql
SELECT * FROM connect.resolve_user_local_officials('4e6dde8f-2bd0-4054-824f-4164744165ea');
```
Should return 2+ rows with LOCAL/LOCAL_EXEC geo_ids (the geo_ids for Karen Bass's city-wide district and Traci Park's CD11 district).
  </verify>
  <done>RPC exists in production, returns LOCAL/LOCAL_EXEC geo_ids for test user.</done>
</task>

<task type="auto">
  <name>Task 2: Wire local officials into Path 1 of representatives/me</name>
  <files>backend/src/lib/essentialsService.ts, backend/src/routes/essentials.ts</files>
  <action>
**In essentialsService.ts**, add a new exported function `getLocalOfficialsByUserId(userId: string): Promise<PoliticianFlatRecord[]>`:

1. Call `pool.query('SELECT * FROM connect.resolve_user_local_officials($1)', [userId])`
2. If no rows returned, return empty array
3. Collect the returned `geo_id` values into an array
4. Run a query against `essentials.districts d` + the same JOINs as `getRepresentativesByJurisdiction` (offices, politicians, chambers, governments, government_bodies)
5. WHERE clause: `d.district_type IN ('LOCAL', 'LOCAL_EXEC') AND d.geo_id = ANY($1::text[])` — pass the geo_id array as a single parameter
6. Filter: `AND (p.is_active = true OR o.is_vacant = true) AND COALESCE(p.is_incumbent, true) = true`
7. Use the same SELECT_FIELDS and row-to-PoliticianFlatRecord mapping as getRepresentativesByJurisdiction (extract shared helpers if clean, or duplicate the mapping — do NOT refactor getRepresentativesByJurisdiction's structure)
8. Call `batchFetchImages` and `batchFetchCommittees` on the result before returning

**In essentials.ts**, update the Path 1 block (lines ~375-387):

After `const politicians = await getRepresentativesByJurisdiction({...})` succeeds:
1. Call `const localOfficials = await getLocalOfficialsByUserId(userId)`
2. Merge: build a `Set` of politician IDs from `politicians`, then append only `localOfficials` whose ID is not already in the set
3. Return the merged array

The merge must handle deduplication — if a politician somehow appears in both queries, keep only one copy.

Do NOT change the Path 2 fallback or the `getRepresentativesByJurisdiction` function signature.
  </action>
  <verify>
1. `npx tsc --noEmit` passes (no type errors)
2. Deploy to Render or test locally: `curl -H "Authorization: Bearer $TOKEN" https://accounts-api.empowered.vote/api/essentials/representatives/me`
   - Response includes politicians with `district_type: "LOCAL"` (Traci Park) and `district_type: "LOCAL_EXEC"` (Karen Bass)
   - Total count is ~17-20, not ~67
   - X-Data-Status header is "fresh" (Path 1 used)
  </verify>
  <done>
GET /essentials/representatives/me for user 4e6dde8f returns Karen Bass (LOCAL_EXEC) and Traci Park (LOCAL) alongside all other representatives. Path 1 is used (no Census Geocoder call). No duplicate politicians in response.
  </done>
</task>

</tasks>

<verification>
1. `npx tsc --noEmit` — no type errors
2. RPC returns LOCAL/LOCAL_EXEC geo_ids for test user
3. API response includes Karen Bass and Traci Park
4. Total result count is reasonable (~17-20, not 67+)
5. No Census Geocoder call made (Path 1 only)
</verification>

<success_criteria>
- GET /essentials/representatives/me returns LOCAL_EXEC (Karen Bass) and LOCAL (Traci Park) for user at 12048 Culver Blvd, LA 90066
- Path 1 (fast geo_id path) handles this without falling through to Path 2
- Result count is ~17-20 total representatives, not ~67
- No regression to other district types (congressional, state, county, school still present)
</success_criteria>

<output>
After completion, create `.planning/quick/011-fix-bug-03-city-officials-in-representatives/011-SUMMARY.md`
</output>
