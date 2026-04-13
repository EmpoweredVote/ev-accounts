---
phase: quick-014
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - backend/migrations/047_add_city_council_district_columns.sql
  - backend/src/routes/account.ts
  - backend/src/routes/connect.ts
  - app/src/pages/DashboardPage.tsx
autonomous: true

must_haves:
  truths:
    - "User's city council district is stored when location is set"
    - "GET /api/account/me returns city_council_district and city_council_district_name in jurisdiction block"
    - "GET /api/account/me/jurisdiction returns city_council_district and city_council_district_name"
    - "DashboardPage Connected Spaces section shows City Council row when city_council_district_name is populated"
    - "Existing users with location_consent get backfilled city council data"
  artifacts:
    - path: "backend/migrations/047_add_city_council_district_columns.sql"
      provides: "Schema columns + RPC update + backfill"
    - path: "backend/src/routes/account.ts"
      provides: "city_council in jurisdiction reads"
    - path: "backend/src/routes/connect.ts"
      provides: "city_council write in set-location handler"
    - path: "app/src/pages/DashboardPage.tsx"
      provides: "City Council row in Connected Spaces"
  key_links:
    - from: "resolve_user_jurisdiction RPC"
      to: "essentials.districts WHERE district_type = 'LOCAL'"
      via: "new MAX(d.geo_id) FILTER + MAX(d.label) FILTER aggregation"
      pattern: "city_council.*LOCAL"
    - from: "connect.ts set-location"
      to: "connected_profiles.city_council_geo_id"
      via: "pool.query UPDATE adding $14, $15 params"
      pattern: "city_council_geo_id"
    - from: "DashboardPage.tsx DISTRICT_LABELS"
      to: "Jurisdiction interface"
      via: "new entry { key: 'city_council_district_name', label: 'City Council' }"
      pattern: "city_council_district_name.*City Council"
---

<objective>
Add city council district to stored jurisdiction data on `connect.connected_profiles`, expose it through the API, and surface it in the dashboard.

Purpose: City council is the most local elected race most users vote in. Without it, "Your Connected Spaces" can't show the user's most proximate representative identity (e.g., "Los Angeles, City Council District 11"). This also enables Civic Spaces integration at the ward/district level.

Output: Two new columns on connected_profiles, updated RPC, updated API responses, updated dashboard UI.
</objective>

<execution_context>
@C:\Users\Chris\.claude/get-shit-done/workflows/execute-plan.md
@C:\Users\Chris\.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@backend/src/routes/account.ts
@backend/src/routes/connect.ts
@backend/migrations/045_fix_resolve_user_jurisdiction.sql
@backend/migrations/046_resolve_user_local_officials.sql
@app/src/pages/DashboardPage.tsx
</context>

<tasks>

<task type="auto">
  <name>Task 1: Migration — add columns, extend RPC, backfill</name>
  <files>backend/migrations/047_add_city_council_district_columns.sql</files>
  <action>
Create migration `backend/migrations/047_add_city_council_district_columns.sql` with three sections:

**Section 1 — Add columns:**
```sql
ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS city_council_geo_id TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS city_council_district_name TEXT DEFAULT NULL;
```

**Section 2 — Extend `connect.resolve_user_jurisdiction` RPC:**
`CREATE OR REPLACE` the existing function (migration 045 pattern). Add two new keys to the returned jsonb:
- `city_council` — the geo_id of the most specific LOCAL district
- `city_council_name` — the label of that district

Selection logic for LOCAL districts (a user can be in multiple LOCAL boundaries simultaneously):
- Prefer `X%` MTFCC (sub-city council ward/district boundaries) over `G4040`/`G4110`/`G4120` (city-wide boundaries)
- If multiple `X%` matches exist, pick the one with alphabetically-first geo_id (deterministic)
- If no `X%` match, use the city-wide LOCAL match from `G4040`/`G4110`/`G4120`

Implementation approach — add a second query after the existing SELECT...INTO v_result block:
```sql
-- Resolve city council: prefer sub-city (X%) over city-wide (G4040/G4110/G4120)
SELECT d.geo_id, d.label
  INTO v_cc_geo_id, v_cc_label
  FROM essentials.geofence_boundaries gb
  JOIN essentials.districts d ON d.geo_id = gb.geo_id
    AND d.district_type = 'LOCAL'
  WHERE public.ST_Covers(gb.geometry, v_point)
  ORDER BY
    CASE WHEN gb.mtfcc LIKE 'X%' THEN 0 ELSE 1 END,  -- prefer sub-city
    d.geo_id                                            -- deterministic tiebreak
  LIMIT 1;
```

Then append to v_result:
```sql
v_result := v_result || jsonb_build_object(
  'city_council', v_cc_geo_id,
  'city_council_name', v_cc_label
);
```

Add `v_cc_geo_id text; v_cc_label text;` to the DECLARE block.

CRITICAL: Keep ALL existing logic unchanged. The existing 10 keys in v_result must remain exactly as they are. Only ADD the city_council keys. Keep `SET search_path = ''`, keep `SECURITY DEFINER`, keep all fully-qualified table refs.

**Section 3 — Backfill existing users:**
Same pattern as Phase 49 migration backfill:
```sql
UPDATE connect.connected_profiles cp
SET
  city_council_geo_id = (j->>'city_council'),
  city_council_district_name = (j->>'city_council_name')
FROM (
  SELECT user_id, connect.resolve_user_jurisdiction(user_id) AS j
  FROM connect.connected_profiles
  WHERE location_consent = true
    AND city_council_geo_id IS NULL
) sub
WHERE cp.user_id = sub.user_id;
```

Apply the migration via Supabase MCP `apply_migration` tool (this is production). If MCP is unavailable, use `psql` with DATABASE_URL from backend/.env.

Verify by running:
```sql
SELECT city_council_geo_id, city_council_district_name
FROM connect.connected_profiles
WHERE location_consent = true
LIMIT 5;
```
  </action>
  <verify>
    1. Columns exist: `SELECT column_name FROM information_schema.columns WHERE table_schema='connect' AND table_name='connected_profiles' AND column_name LIKE 'city_council%';` returns 2 rows
    2. RPC returns new keys: `SELECT connect.resolve_user_jurisdiction('4e6dde8f-73e7-43fe-b581-9fca07b0c81a')` includes city_council and city_council_name keys
    3. Backfill populated: At least some users with location_consent=true have non-null city_council_geo_id
  </verify>
  <done>Two new columns exist on connected_profiles, RPC returns city_council + city_council_name, existing users backfilled</done>
</task>

<task type="auto">
  <name>Task 2: Backend routes — add city_council to jurisdiction reads and writes</name>
  <files>backend/src/routes/account.ts, backend/src/routes/connect.ts</files>
  <action>
**File: `backend/src/routes/connect.ts` — set-location handler (around line 571-605):**

The jurisdiction write query currently writes 13 params ($1-$13). Extend to include city_council:

1. Add to the UPDATE SET clause:
   ```
   city_council_geo_id = $14,
   city_council_district_name = $15,
   ```
2. Add to the params array (after the existing school_district_name, state, city entries):
   ```typescript
   jData.city_council ?? null,
   jData.city_council_name ?? null,
   ```

3. Add to the response JSON object (around line 612-628), after school_district entries:
   ```typescript
   city_council_district: j.city_council ?? null,
   city_council_district_name: j.city_council_name ?? null,
   ```

**File: `backend/src/routes/account.ts` — THREE places to update:**

Each of the three `pool.query` calls that SELECT jurisdiction columns needs updating. They are in:
1. GET /me handler (around line 109-131)
2. GET /me/jurisdiction handler (around line 260-282)
3. PATCH /me handler (around line 454-476)

For ALL THREE:
- Add to the TypeScript type annotation:
  ```typescript
  city_council_geo_id: string | null;
  city_council_district_name: string | null;
  ```
- Add to the SQL SELECT:
  ```sql
  city_council_geo_id, city_council_district_name,
  ```
- Add to the response object mapping:
  ```typescript
  city_council_district: j.city_council_geo_id,
  city_council_district_name: j.city_council_district_name,
  ```
  (or `j?.city_council_geo_id ?? null` / `j?.city_council_district_name ?? null` for the /me/jurisdiction route)

IMPORTANT: The GET /me handler has a guard `if (j && (j.congressional_geo_id || j.state_senate_geo_id))` at line 133. Do NOT change this guard — city_council alone should not trigger jurisdiction display if the core districts are missing.

After editing, run `cd backend && npx tsc --noEmit` to verify TypeScript compiles.
  </action>
  <verify>
    1. `cd backend && npx tsc --noEmit` passes with no errors
    2. Start server, call GET /api/account/me with a valid token — jurisdiction block includes city_council_district and city_council_district_name fields
    3. Call GET /api/account/me/jurisdiction — response includes city_council_district and city_council_district_name
  </verify>
  <done>All three account.ts jurisdiction reads and the connect.ts set-location write include city_council fields, TypeScript compiles clean</done>
</task>

<task type="auto">
  <name>Task 3: Frontend — add City Council row to Connected Spaces</name>
  <files>app/src/pages/DashboardPage.tsx</files>
  <action>
**File: `app/src/pages/DashboardPage.tsx`:**

1. Update the `Jurisdiction` interface (around line 20-28) — add:
   ```typescript
   city_council_district_name: string | null;
   ```

2. Update the `DISTRICT_LABELS` array (around line 130-136) — add a new entry AFTER the existing school_district entry and BEFORE the array closing bracket. Place it as the FIRST entry to put city council at the top (most local = most prominent):
   ```typescript
   const DISTRICT_LABELS: { key: keyof Jurisdiction; label: string }[] = [
     { key: 'city_council_district_name', label: 'City Council' },
     { key: 'congressional_district_name', label: 'U.S. Congress' },
     { key: 'state_senate_district_name', label: 'State Senate' },
     { key: 'state_house_district_name', label: 'State House' },
     { key: 'county_name', label: 'County' },
     { key: 'school_district_name', label: 'School District' },
   ];
   ```

   Rationale: City council is the most local level — placing it first in the list makes it the most prominent in "Your Connected Spaces", matching the product goal of emphasizing the user's most proximate representative identity.

No other changes needed. The existing rendering logic at line 584 (`DISTRICT_LABELS.filter((d) => jurisdiction[d.key]).map(...)`) will automatically pick up the new entry and render it when the value is non-null, and skip it when null.

After editing, verify the app builds: `cd app && npx vite build`
  </action>
  <verify>
    1. `cd app && npx vite build` succeeds with no errors
    2. Visual check: the Jurisdiction interface has city_council_district_name, DISTRICT_LABELS has City Council entry at position 0
  </verify>
  <done>DashboardPage shows "City Council" row in Connected Spaces when city_council_district_name is populated, placed first (most local = most prominent)</done>
</task>

</tasks>

<verification>
1. Database: `SELECT city_council_geo_id, city_council_district_name FROM connect.connected_profiles WHERE location_consent = true AND city_council_geo_id IS NOT NULL LIMIT 3;` returns populated rows
2. RPC: `SELECT connect.resolve_user_jurisdiction('4e6dde8f-73e7-43fe-b581-9fca07b0c81a');` jsonb includes city_council + city_council_name keys
3. Backend compiles: `cd backend && npx tsc --noEmit` passes
4. Frontend builds: `cd app && npx vite build` passes
5. API response: GET /api/account/me jurisdiction block includes city_council_district and city_council_district_name
</verification>

<success_criteria>
- Two new columns (city_council_geo_id, city_council_district_name) on connect.connected_profiles
- resolve_user_jurisdiction RPC returns city_council + city_council_name keys (prefers sub-city X% MTFCC over city-wide)
- Existing users with location_consent backfilled
- GET /api/account/me, GET /api/account/me/jurisdiction, PATCH /api/account/me all include city_council fields in jurisdiction
- POST /api/connect/set-location writes city_council fields
- DashboardPage "Your Connected Spaces" shows City Council as the first (most prominent) district row
- Backend TypeScript compiles, frontend Vite builds
</success_criteria>

<output>
After completion, create `.planning/quick/014-add-city-council-district-to-jurisdicti/014-SUMMARY.md`
</output>
