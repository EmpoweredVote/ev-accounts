---
phase: quick-018
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - backend/migrations/065_add_municipality_geo_id.sql
  - backend/migrations/066_update_resolve_user_jurisdiction_municipality.sql
  - backend/migrations/067_backfill_municipality_geo_id.sql
  - backend/src/routes/essentials.ts
  - backend/src/routes/connect.ts
  - backend/scripts/seed-la-citywide-races-2026.sql
autonomous: true

must_haves:
  truths:
    - "LA residents see City Attorney, City Controller, and City Clerk races on the Elections page"
    - "municipality_geo_id is resolved and stored for users whose coordinates fall inside a city boundary"
    - "resolve_user_jurisdiction returns a municipality key for users inside incorporated places"
    - "Existing users with stored coordinates have municipality_geo_id backfilled"
  artifacts:
    - path: "backend/migrations/065_add_municipality_geo_id.sql"
      provides: "New column on connected_profiles"
      contains: "municipality_geo_id"
    - path: "backend/migrations/066_update_resolve_user_jurisdiction_municipality.sql"
      provides: "Updated RPC returning municipality key"
      contains: "municipality"
    - path: "backend/migrations/067_backfill_municipality_geo_id.sql"
      provides: "Backfill for existing users"
      contains: "municipality_geo_id"
    - path: "backend/scripts/seed-la-citywide-races-2026.sql"
      provides: "LA citywide offices, races, and candidates"
      contains: "City Attorney"
  key_links:
    - from: "backend/src/routes/essentials.ts"
      to: "getElectionsByGeoIds"
      via: "municipality_geo_id included in geoIds array"
      pattern: "municipality_geo_id"
    - from: "backend/src/routes/connect.ts"
      to: "connected_profiles"
      via: "municipality_geo_id written on set-location"
      pattern: "municipality_geo_id"
---

<objective>
Add `municipality_geo_id` column to `connected_profiles` so citywide races (LA City Attorney, Controller, Clerk) surface for residents of incorporated cities on the Elections page.

Purpose: LA residents currently see city council district races but NOT citywide elected offices (City Attorney, Controller, Clerk) because the election query has no mechanism to match "user is inside City of Los Angeles" to offices linked to the city-wide LOCAL_EXEC district (geo_id 0644000). Adding a municipality_geo_id column and including it in the geoIds array passed to getElectionsByGeoIds closes this gap.

Output: 3 migrations (schema + RPC + backfill), 1 data seed script, 2 route updates
</objective>

<execution_context>
@C:\Users\Chris\.claude/get-shit-done/workflows/execute-plan.md
@C:\Users\Chris\.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@ACCOUNTS-TEAM-REQUEST-la-citywide-races-2026.md
@backend/migrations/063_fix_resolve_user_jurisdiction_city_council_ordering.sql
@backend/migrations/064_backfill_city_council_geo_id.sql
@backend/migrations/047_add_city_council_district_columns.sql
@backend/src/routes/essentials.ts
@backend/src/routes/connect.ts
@backend/src/lib/electionService.ts
@backend/scripts/seed-la-county-2026-primary-state-federal.sql
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add municipality_geo_id column and update resolve_user_jurisdiction RPC</name>
  <files>
    backend/migrations/065_add_municipality_geo_id.sql
    backend/migrations/066_update_resolve_user_jurisdiction_municipality.sql
    backend/migrations/067_backfill_municipality_geo_id.sql
  </files>
  <action>
**Migration 065 — Add column:**

```sql
ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS municipality_geo_id TEXT DEFAULT NULL;
```

Single column only. No name column needed — the municipality name IS the jurisdiction_city already stored.

**Migration 066 — Update resolve_user_jurisdiction RPC:**

CREATE OR REPLACE the existing `connect.resolve_user_jurisdiction` function. Copy the FULL current definition from migration 063 as the base. Add a NEW separate query block (parallel to the city_council block) that resolves the municipality:

```sql
-- Municipality: city-wide LOCAL_EXEC district (G4110/G4040/G4120)
-- This is the incorporated place boundary — e.g. "City of Los Angeles" (geo_id 0644000)
SELECT d.geo_id
  INTO v_muni_geo_id
  FROM essentials.geofence_boundaries gb
  JOIN essentials.districts d ON d.geo_id = gb.geo_id
    AND d.district_type = 'LOCAL_EXEC'
  WHERE public.ST_Covers(gb.geometry, v_point)
    AND gb.mtfcc IN ('G4110', 'G4040', 'G4120')
  ORDER BY d.geo_id
  LIMIT 1;
```

Add `v_muni_geo_id text;` to the DECLARE block.

Append municipality to the returned jsonb:

```sql
v_result := v_result || jsonb_build_object(
  'city_council',      v_cc_geo_id,
  'city_council_name', v_cc_label,
  'municipality',      v_muni_geo_id
);
```

IMPORTANT constraints:
- Keep `SET search_path TO ''` — all table refs fully qualified
- Keep `SECURITY DEFINER`
- Keep all existing keys (congressional, state_senate, state_house, county, school_district, city_council, city_council_name) unchanged
- The new key name is `municipality` (matches the column name pattern: `municipality_geo_id` on the profile, `municipality` in the RPC result)

**Migration 067 — Backfill:**

Follow the exact pattern from migration 064. Loop over all connected_profiles where `encrypted_lat IS NOT NULL AND location_consent = true`, call `connect.resolve_user_jurisdiction(rec.user_id)`, write back ONLY `municipality_geo_id = v_result->>'municipality'`. Do NOT touch any other columns. Use EXCEPTION WHEN OTHERS with RAISE WARNING for resilience.
  </action>
  <verify>
    Read all three migration files and verify:
    1. 065 adds exactly one column
    2. 066 has the full RPC with municipality block added, all existing keys preserved
    3. 067 follows the 064 backfill pattern exactly, writing only municipality_geo_id
    Run `npx tsc --noEmit` from backend/ to confirm no TypeScript breakage (migrations are SQL-only, but verify no accidental TS issues)
  </verify>
  <done>
    Three migration files exist. The RPC returns a `municipality` key. Backfill migration targets all users with coordinates.
  </done>
</task>

<task type="auto">
  <name>Task 2: Wire municipality_geo_id into elections/me and set-location routes</name>
  <files>
    backend/src/routes/essentials.ts
    backend/src/routes/connect.ts
  </files>
  <action>
**essentials.ts — GET /elections/me (lines 547-635):**

1. Add `municipality_geo_id` to the TypeScript interface (line 550-559):
   ```typescript
   municipality_geo_id: string | null;
   ```

2. Add `municipality_geo_id` to the SELECT query (line 561-562):
   ```sql
   SELECT congressional_geo_id, state_senate_geo_id, state_house_geo_id,
          county_geo_id, school_district_geo_id, city_council_geo_id,
          municipality_geo_id,
          jurisdiction_state, jurisdiction_city,
          (encrypted_lat IS NOT NULL) AS has_coords
   ```

3. Path 1 — Add `j.municipality_geo_id` to the geoIds array (line 574):
   ```typescript
   const elections = await getElectionsByGeoIds(
     [j.congressional_geo_id, j.state_senate_geo_id, j.state_house_geo_id,
      j.county_geo_id, j.school_district_geo_id, j.city_council_geo_id,
      j.municipality_geo_id],
     j.jurisdiction_state
   );
   ```

4. Path 1.5 — Add `municipality_geo_id` to the fire-and-forget write-back UPDATE (lines 597-616). Add it as a new SET clause and include `jd.municipality ?? null` in the params array. Update parameter numbering accordingly ($12 becomes $13, etc — be careful with the numbering shift).

5. Path 1.5 — Add `jd.municipality` to the geoIds array in the getElectionsByGeoIds call (line 620):
   ```typescript
   const elections = await getElectionsByGeoIds(
     [jd.congressional, jd.state_senate, jd.state_house,
      jd.county, jd.school_district, jd.city_council,
      jd.municipality],
     j.jurisdiction_state
   );
   ```

**connect.ts — POST /set-location (around line 598-633):**

Add `municipality_geo_id` to the jurisdiction write-back UPDATE query. Add it as a new SET clause after `city_council_district_name`:
```sql
municipality_geo_id = $16,
```
And add `jData.municipality ?? null` to the params array. Update parameter numbering ($12-$15 shift to accommodate the new column, or add at the end as $16).

IMPORTANT: The parameter numbering must be exact. Count carefully. The current query has 15 params ($1=userId through $15=city_council_name). Adding municipality_geo_id makes it $16.
  </action>
  <verify>
    Run `npx tsc --noEmit` from backend/ — must pass with no errors.
    Grep for `municipality_geo_id` in essentials.ts and connect.ts — should appear in:
    - essentials.ts: TypeScript interface, SELECT query, Path 1 geoIds array, Path 1.5 write-back UPDATE, Path 1.5 geoIds array
    - connect.ts: jurisdiction write-back UPDATE + params array
  </verify>
  <done>
    municipality_geo_id flows through all three code paths: initial set-location write, Path 1 cached read, and Path 1.5 resolve-and-write-back.
  </done>
</task>

<task type="auto">
  <name>Task 3: Seed LA citywide races and candidates for 2026 Primary</name>
  <files>
    backend/scripts/seed-la-citywide-races-2026.sql
  </files>
  <action>
Create a SQL seed script following the exact pattern from `seed-la-county-2026-primary-state-federal.sql`.

**Structure:**
1. BEGIN transaction
2. Verify `2026 LA County Primary` election exists (DO $$ block, RAISE EXCEPTION if not found)
3. Insert races linked to offices in the `0644000` (City of Los Angeles) district
4. Insert candidates with idempotent WHERE NOT EXISTS guards
5. Verification query
6. COMMIT

**Races to create (all linked to office_id via the 0644000 LOCAL_EXEC district):**

For each race, look up the office_id from `essentials.offices` where the office is linked to a district with `geo_id = '0644000'`. The Mayor office already exists there (office_id `b8c4bd9d-05ba-4751-b947-7a3d2645d3ef`). The City Attorney, City Controller, and City Clerk offices may or may not exist yet.

**IMPORTANT: The script must handle the case where offices don't exist yet.** Use a CTE or DO block to:
1. First, look up the LA city district internal ID: `SELECT id FROM essentials.districts WHERE geo_id = '0644000'`
2. For each citywide office (City Attorney, City Controller, City Clerk), INSERT INTO essentials.offices IF NOT EXISTS, linked to that district_id. Use descriptive office_title values: `City Attorney`, `City Controller`, `City Clerk`.
3. Then create races linking to those office_ids.

Use ON CONFLICT for idempotency on races: `ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING`

**Candidates — VERIFIED SOURCES ONLY:**

Per the task context and team request:

- **LA City Attorney:**
  - Hydee Feldstein Soto — INCUMBENT (current LA City Attorney, elected 2022). Create politician record if not exists: first_name='Hydee', last_name='Feldstein Soto', full_name='Hydee Feldstein Soto'. Mark is_incumbent=true.
  - Marissa Roy — CHALLENGER. Create politician record if not exists: first_name='Marissa', last_name='Roy', full_name='Marissa Roy'. Mark is_incumbent=false. Source: cal_access_discovery committee filings confirm active candidacy.

- **LA City Controller and LA City Clerk:** Create the race records (so they appear when candidates are added later), but do NOT fabricate candidates. Add a comment: `-- Candidates TBD — verify against lavote.gov candidate filing list before adding`

Use `source = 'lavote_gov_2026'` for candidates. For politician records, use INSERT ... ON CONFLICT (this requires checking what unique constraints exist on essentials.politicians — if none, use WHERE NOT EXISTS on full_name).

**Script header comment** should include:
- Source references (lavote.gov, cal_access_discovery)
- Date verified
- ANTIPARTISAN NOTE (primary_party = NULL for all CA races)
- Idempotency guarantees

**Do NOT run this script automatically.** It is a seed script for manual execution against production via `psql $DATABASE_URL -f scripts/seed-la-citywide-races-2026.sql`.
  </action>
  <verify>
    Read the seed script and verify:
    1. It references the correct election name ('2026 LA County Primary')
    2. Office creation uses the 0644000 district
    3. Race creation uses ON CONFLICT for idempotency
    4. Candidate inserts use WHERE NOT EXISTS guards
    5. Only verified candidates are included (Feldstein Soto and Marissa Roy for City Attorney)
    6. Controller and Clerk races exist but have no fabricated candidates
    7. Script is wrapped in BEGIN/COMMIT
  </verify>
  <done>
    Seed script creates 3 citywide race records (City Attorney, Controller, Clerk) linked to the LA city district, seeds 2 verified City Attorney candidates, and leaves Controller/Clerk candidate slots open for future sourcing. Script is ready for manual execution.
  </done>
</task>

</tasks>

<verification>
After all tasks complete:
1. `npx tsc --noEmit` passes from backend/
2. `grep -n municipality_geo_id backend/src/routes/essentials.ts` shows hits in: interface, SELECT, Path 1 array, Path 1.5 UPDATE, Path 1.5 array
3. `grep -n municipality_geo_id backend/src/routes/connect.ts` shows hit in: jurisdiction write-back UPDATE
4. All 3 migration files exist with correct numbering (065, 066, 067)
5. Seed script exists and is syntactically valid SQL
6. The RPC in migration 066 returns all original keys PLUS `municipality`
</verification>

<success_criteria>
- municipality_geo_id column added to connected_profiles (migration 065)
- resolve_user_jurisdiction returns municipality key (migration 066)
- Existing users backfilled (migration 067)
- elections/me includes municipality_geo_id in geo lookup for both Path 1 and Path 1.5
- set-location writes municipality_geo_id on initial location store
- LA citywide races seeded with verified candidates only
- TypeScript compiles cleanly
</success_criteria>

<output>
After completion, create `.planning/quick/018-add-municipality-geo-id-support-so-la-ci/018-SUMMARY.md`
</output>
