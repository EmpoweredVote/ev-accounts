---
phase: quick
plan: 008
type: execute
wave: 1
depends_on: []
files_modified:
  - backend/migrations/045_fix_resolve_user_jurisdiction.sql
  - backend/src/routes/essentials.ts
autonomous: true

must_haves:
  truths:
    - "resolve_user_jurisdiction returns non-null geo_ids for users inside loaded geofence boundaries"
    - "GET /representatives/me returns precise politicians (Karen Bass, Traci Park) for user 4e6dde8f"
    - "X-Formatted-Address contains street-level address, not city/state"
    - "connected_profiles has populated geo_id fields after set-location"
  artifacts:
    - path: "backend/migrations/045_fix_resolve_user_jurisdiction.sql"
      provides: "Rewritten RPC querying essentials schema"
      contains: "essentials.geofence_boundaries"
  key_links:
    - from: "connect.resolve_user_jurisdiction"
      to: "essentials.geofence_boundaries + essentials.districts"
      via: "ST_Covers point-in-polygon join"
      pattern: "ST_Covers.*geometry.*v_point"
---

<objective>
Fix `connect.resolve_user_jurisdiction` to query live geometry data in `essentials.geofence_boundaries` + `essentials.districts` instead of the empty `inform.district_boundaries` table. Fix the `X-Formatted-Address` header in Path 1 to use `homeAddress`. Backfill existing users who have coordinates but null geo_ids.

Purpose: Connected users get precise representative results based on actual geofence data.
Output: Working RPC, fixed route header, backfilled user geo_ids.
</objective>

<execution_context>
@C:\Users\Chris\.claude/get-shit-done/workflows/execute-plan.md
@C:\Users\Chris\.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@backend/migrations/032_location_rpcs.sql
@backend/src/routes/essentials.ts (lines 309-388)
@backend/src/routes/connect.ts (lines 560-634)
@backend/src/lib/essentialsService.ts (lines 516-547 for MTFCC mapping reference)
</context>

<tasks>

<task type="auto">
  <name>Task 1: Rewrite resolve_user_jurisdiction RPC to query essentials schema</name>
  <files>backend/migrations/045_fix_resolve_user_jurisdiction.sql</files>
  <action>
Create a new migration that replaces `connect.resolve_user_jurisdiction` with `CREATE OR REPLACE FUNCTION`. Keep the existing vault decryption and coordinate decryption logic identical (lines 97-137 of 032). Replace the query portion (lines 144-153) with:

1. Build the point the same way: `v_point := extensions.ST_SetSRID(extensions.ST_MakePoint(v_lng, v_lat), 4326);`

2. Replace the `inform.district_boundaries` query with a join of `essentials.geofence_boundaries gb` to `essentials.districts d` using the same MTFCC-to-district_type mapping that `essentialsService.ts` uses (lines 518-531). The ST_Covers call: `extensions.ST_Covers(gb.geometry, v_point)` — note `gb.geometry` not `gb.geom`, and use `extensions.` prefix (not `public.`) because this is a SECURITY DEFINER function with `SET search_path = ''`.

3. The SELECT must build a jsonb with 10 keys (geo_ids + names for the set-location consumer):
   - `congressional` / `congressional_name` — from district_type `NATIONAL_LOWER`
   - `state_senate` / `state_senate_name` — from `STATE_UPPER`
   - `state_house` / `state_house_name` — from `STATE_LOWER`
   - `county` / `county_name` — from `COUNTY`
   - `school_district` / `school_district_name` — from `SCHOOL`

   Use the pattern:
   ```sql
   SELECT jsonb_build_object(
     'congressional',        MAX(d.geo_id)  FILTER (WHERE d.district_type = 'NATIONAL_LOWER'),
     'congressional_name',   MAX(d.label)   FILTER (WHERE d.district_type = 'NATIONAL_LOWER'),
     'state_senate',         MAX(d.geo_id)  FILTER (WHERE d.district_type = 'STATE_UPPER'),
     'state_senate_name',    MAX(d.label)   FILTER (WHERE d.district_type = 'STATE_UPPER'),
     'state_house',          MAX(d.geo_id)  FILTER (WHERE d.district_type = 'STATE_LOWER'),
     'state_house_name',     MAX(d.label)   FILTER (WHERE d.district_type = 'STATE_LOWER'),
     'county',               MAX(d.geo_id)  FILTER (WHERE d.district_type = 'COUNTY'),
     'county_name',          MAX(d.label)   FILTER (WHERE d.district_type = 'COUNTY'),
     'school_district',      MAX(d.geo_id)  FILTER (WHERE d.district_type = 'SCHOOL'),
     'school_district_name', MAX(d.label)   FILTER (WHERE d.district_type = 'SCHOOL')
   )
   INTO v_result
   FROM essentials.geofence_boundaries gb
   JOIN essentials.districts d ON d.geo_id = gb.geo_id
     AND (
       (gb.mtfcc = 'G5210' AND d.district_type = 'STATE_UPPER')
       OR (gb.mtfcc = 'G5220' AND d.district_type = 'STATE_LOWER')
       OR (gb.mtfcc = 'G5200' AND d.district_type = 'NATIONAL_LOWER')
       OR (gb.mtfcc = 'G4020' AND d.district_type = 'COUNTY')
       OR (gb.mtfcc IN ('G5400', 'G5410', 'G5420') AND d.district_type = 'SCHOOL')
     )
   WHERE extensions.ST_Covers(gb.geometry, v_point);
   ```

   Note: the MTFCC mapping here is deliberately narrower than essentialsService.ts — only include the 5 district types that the RPC returns (no LOCAL, LOCAL_EXEC, JUDICIAL). Do NOT include the fallback clause.

4. Apply the migration via Supabase MCP `apply_migration` with name `fix_resolve_user_jurisdiction`.

IMPORTANT: Keep `SECURITY DEFINER` and `SET search_path = ''`. All table refs fully schema-qualified. All PostGIS/pgcrypto functions prefixed with `extensions.`. Do NOT reference `inform.district_boundaries` at all.
  </action>
  <verify>
After applying migration, test via Supabase MCP execute_sql:
```sql
SELECT connect.resolve_user_jurisdiction('4e6dde8f-2bd0-4054-824f-4164744165ea');
```
Should return jsonb with non-null `congressional`, `state_senate`, `state_house`, `county` keys (school_district may be null if no school boundary loaded for that location).
  </verify>
  <done>RPC returns geo_ids from essentials schema for users with stored coordinates inside loaded geofence boundaries.</done>
</task>

<task type="auto">
  <name>Task 2: Fix X-Formatted-Address header and backfill existing users</name>
  <files>backend/src/routes/essentials.ts</files>
  <action>
**Part A — Fix X-Formatted-Address in Path 1:**

In `backend/src/routes/essentials.ts` around line 354, change the Path 1 `formattedAddress` logic from:
```ts
const formattedAddress = [j.jurisdiction_city, j.jurisdiction_state]
  .filter(Boolean).join(', ');
res.setHeader('X-Formatted-Address', formattedAddress || homeAddress);
```
to simply:
```ts
res.setHeader('X-Formatted-Address', homeAddress || [j.jurisdiction_city, j.jurisdiction_state].filter(Boolean).join(', '));
```
This prefers `homeAddress` (street-level) and falls back to city/state only if home_address is empty.

**Part B — Backfill existing users:**

Run a backfill SQL via Supabase MCP `execute_sql` that calls `resolve_user_jurisdiction` for each user who has encrypted_lat set but null congressional_geo_id:

```sql
DO $$
DECLARE
  r RECORD;
  j jsonb;
BEGIN
  FOR r IN
    SELECT user_id FROM connect.connected_profiles
    WHERE encrypted_lat IS NOT NULL
      AND location_consent = true
      AND congressional_geo_id IS NULL
  LOOP
    BEGIN
      j := connect.resolve_user_jurisdiction(r.user_id);
      UPDATE connect.connected_profiles
      SET congressional_geo_id = j->>'congressional',
          congressional_district_name = j->>'congressional_name',
          state_senate_geo_id = j->>'state_senate',
          state_senate_district_name = j->>'state_senate_name',
          state_house_geo_id = j->>'state_house',
          state_house_district_name = j->>'state_house_name',
          county_geo_id = j->>'county',
          county_name = j->>'county_name',
          school_district_geo_id = j->>'school_district',
          school_district_name = j->>'school_district_name',
          updated_at = now()
      WHERE user_id = r.user_id;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Failed for user %: %', r.user_id, SQLERRM;
    END;
  END LOOP;
END;
$$;
```

After backfill, verify user 4e6dde8f has populated geo_ids:
```sql
SELECT congressional_geo_id, state_senate_geo_id, state_house_geo_id, county_geo_id, school_district_geo_id
FROM connect.connected_profiles
WHERE user_id = '4e6dde8f-2bd0-4054-824f-4164744165ea';
```
  </action>
  <verify>
1. Verify the route change: `grep -n 'X-Formatted-Address' backend/src/routes/essentials.ts` shows homeAddress is preferred over city/state.
2. Verify backfill: execute_sql query on connected_profiles for user 4e6dde8f shows non-null geo_ids.
3. End-to-end: call GET /essentials/representatives/me as user 4e6dde8f (via curl or test) — response should include Karen Bass and Traci Park, X-Formatted-Address should contain a street address.
  </verify>
  <done>X-Formatted-Address returns street-level address. All existing users with coordinates have populated geo_ids. Representatives/me returns precise results.</done>
</task>

</tasks>

<verification>
1. `connect.resolve_user_jurisdiction('4e6dde8f-...')` returns jsonb with non-null geo_ids
2. `connected_profiles` for user 4e6dde8f has populated `congressional_geo_id`, `state_senate_geo_id`, etc.
3. GET /essentials/representatives/me returns Karen Bass (mayor) and Traci Park (council member)
4. X-Formatted-Address header contains street-level address, not just "Los Angeles, CA"
</verification>

<success_criteria>
- RPC queries essentials.geofence_boundaries + essentials.districts (not inform.district_boundaries)
- User 4e6dde8f gets precise representative results including Karen Bass and Traci Park
- X-Formatted-Address contains street-level home address
- All users with stored coordinates have backfilled geo_ids
</success_criteria>

<output>
After completion, create `.planning/quick/008-fix-representatives-me-to-return-precise/008-SUMMARY.md`
</output>
