# Phase 71: School Districts + Profile Display - Research

**Researched:** 2026-05-09
**Domain:** PostGIS TIGER import (ELSD/SCSD/UNSD), Postgres RPC extension, Express route modification, React profile UI
**Confidence:** HIGH — all findings sourced from live codebase inspection and verified TIGER Census Bureau documentation

---

## Summary

Phase 71 has four distinct workstreams: (1) extend `essentials.cache_user_districts` to include school layers, (2) import CA school district TIGER polygons into `essentials.geo_districts`, (3) create a new `GET /api/account/school-district` endpoint that surfaces school district for the profile UI, and (4) add a "Location tab" to ProfilePage and display school district there.

The backend schema (geo_districts + user_districts + cache_user_districts RPC) is already designed to support arbitrary layers — Phase 69's migration 089 explicitly comments "Phase 71 will add school layers." The import pattern (ogr2ogr + idempotent ON CONFLICT) is identical to the assembly/senate/us_house import in Phase 69. No new tables are needed. The only schema work is extending `cache_user_districts`'s default `p_layers` array and updating `resolve_user_districts` to match.

The profile UI work is more significant than it looks: `admin/src/pages/ProfilePage.tsx` currently has tabs for `profile`, `referrals`, `posts`, and `contributor`. The CONTEXT.md refers to "the existing Location tab" — but NO such tab exists in the current ProfilePage. **Phase 71 must create the Location tab** containing district info, address/coordinates, and recalibration controls. This is the majority of the UI work. The school district display (name + Google search link) is added within that new tab.

**Primary recommendation:** Implement in two plans: Plan 71-01 handles all backend work (migration extending cache_user_districts default p_layers + TIGER import seed script + new GET /api/account/school-district endpoint). Plan 71-02 handles the Location tab creation in ProfilePage plus the school district display component. The ogr2ogr import requires a human-gated checkpoint (same pattern as Phase 69's Plan 02).

---

## Standard Stack

No new npm dependencies. All Phase 71 work uses the established stack.

### Core (already present)

| Component | Version | Purpose |
|-----------|---------|---------|
| `pool.query()` | pg 8.x | All essentials/connect schema reads/writes |
| `ogr2ogr` (local tool) | GDAL 3.x | Shapefile → Postgres import, not a runtime dep |
| `psql` | Postgres client | Apply migrations, verify row counts |
| Express 4.x Router | 4.x | Route modifications in account.ts |
| React + TypeScript | Vite/TSX | ProfilePage Location tab UI |
| Tailwind v4 | 4.x | Styling in admin/src |

### TIGER 2024 School District Download URLs (verified live)

| Layer | File | URL | Size |
|-------|------|-----|------|
| `school_unified` | tl_2024_06_unsd.zip | `https://www2.census.gov/geo/tiger/TIGER2024/UNSD/tl_2024_06_unsd.zip` | 4.1M |
| `school_elementary` | tl_2024_06_elsd.zip | `https://www2.census.gov/geo/tiger/TIGER2024/ELSD/tl_2024_06_elsd.zip` | 3.5M |
| `school_secondary` | tl_2024_06_scsd.zip | `https://www2.census.gov/geo/tiger/TIGER2024/SCSD/tl_2024_06_scsd.zip` | 1.8M |

All files verified to exist on Census Bureau server (2025-06-27 timestamps — current TIGER 2024 vintage).

### TIGER 2024 School District Shapefile Attribute Names (verified)

| Shapefile type | District geoid column | District name column | LEA code column |
|----------------|----------------------|---------------------|-----------------|
| UNSD | `GEOID` (7 chars: STATEFP 2 + UNSDLEA 5) | `NAME` (100 chars) | `UNSDLEA` (5 chars) |
| ELSD | `GEOID` (7 chars: STATEFP 2 + ELSDLEA 5) | `NAME` (100 chars) | `ELSDLEA` (5 chars) |
| SCSD | `GEOID` (7 chars: STATEFP 2 + SCSDLEA 5) | `NAME` (100 chars) | `SCSDLEA` (5 chars) |

**Critical difference from assembly/senate/us_house:** These shapefiles use `NAME` not `NAMELSAD`. The Phase 69 seed script used `NAMELSAD AS name` (e.g. "Assembly District 54"). School district shapefiles use `NAME` (e.g. "Los Angeles Unified School District"). This must be reflected in the `import_layer` SQL query: `SELECT GEOID, <XSDLEA> AS district_num, NAME AS name FROM ...`

**GEOID format:** 7-character string. For CA (FIPS 06): `06` + 5-digit LEA code. Example: `0610710` = Los Angeles USD.

---

## Architecture Patterns

### Existing Pattern: Layer Discriminator in geo_districts

`essentials.geo_districts` already has `UNIQUE(layer, geoid)` and GIST index. Adding three new school layers requires no schema changes — just rows with `layer IN ('school_unified', 'school_elementary', 'school_secondary')`.

### Existing RPC: cache_user_districts default p_layers

`essentials.cache_user_districts` calls `essentials.resolve_user_districts(p_lat, p_lng)` with its default `p_layers` array:

```sql
-- Current default (migration 090):
p_layers text[] DEFAULT ARRAY['ca_assembly', 'ca_senate', 'us_house']
```

Phase 71 needs to include school layers. There are two options (Claude's Discretion per CONTEXT):

**Option A: Update the default `p_layers` array via a new migration**
- Migration: `CREATE OR REPLACE FUNCTION essentials.cache_user_districts(...)` with updated `p_layers DEFAULT ARRAY['ca_assembly', 'ca_senate', 'us_house', 'school_unified', 'school_elementary', 'school_secondary']`
- No changes to call sites in account.ts or connect.ts
- **Recommended** — cleaner, all future location writes automatically include school layers

**Option B: Pass explicit layers at each call site in Node.js**
- Every `pool.query('SELECT essentials.cache_user_districts($1, $2, $3)', ...)` would need a `p_layers` parameter
- Three call sites to update: connect.ts set-location, account.ts location-hint, account.ts set-location
- Also the `essentials.recache_user_districts_for_user` RPC (migration 092) calls `cache_user_districts` internally and would need updating too
- Not recommended — more surface area to update, not DRY

**Research recommendation:** Use Option A (migration to update default). The RPC's `p_layers` default is the single source of truth for which layers are active. Updating it in one migration propagates automatically to all existing call sites including the recache admin RPC.

### Existing Pattern: ogr2ogr Import → ON CONFLICT Upsert

```bash
# From scripts/seed-tiger-districts.sh — replicate for school layers
ogr2ogr \
  -f PostgreSQL "$DB_URL" "$shp" \
  -nln essentials.geo_districts_stage \
  -nlt MULTIPOLYGON \
  -t_srs EPSG:4326 \
  -lco GEOMETRY_NAME=geom \
  -lco SCHEMA=essentials \
  -overwrite \
  -sql "SELECT GEOID, <XSDLEA> AS district_num, NAME AS name FROM <shapefile_basename>"
# Then: INSERT ... ON CONFLICT (layer, geoid) DO UPDATE
```

### New Endpoint: GET /api/account/school-district

The CONTEXT says "`GET /api/account/districts` stays legislative only." School district is surfaced separately. A new endpoint `GET /api/account/school-district` is needed. It follows the exact same pattern as `GET /api/account/districts` (requireAuth, 204 on empty, pool.query with LEFT JOIN geo_districts for name).

### New: School District Display in ProfilePage Location Tab

The CONTEXT says school district appears in the "existing Location tab" — but ProfilePage.tsx currently has no Location tab. The current tab array is `['profile', 'referrals', 'posts', 'contributor']`. Phase 71 must create a new `'location'` tab.

**What the Location tab should contain (from CONTEXT):**
- District info (legislative districts — already fetched via `GET /api/account/districts`)
- School district name + Google search link
- Address/coordinates display
- Location recalibration controls

**apiFetch on 204 responses (RESOLVED — HIGH confidence):**
`admin/src/lib/api.ts` calls `res.json()` unconditionally on any `res.ok` response (status 200-299, which includes 204). A 204 has no body — `res.json()` throws a `SyntaxError`. Therefore:
- `apiFetch('/account/school-district')` on a 204 response throws
- The correct fetch pattern is `.catch(() => {})` — leave state as null, which hides the section
- This is consistent with how other optional data (invitees, roles, compass stats) is fetched in ProfilePage

**Google search link pattern (CONTEXT decision):**
```typescript
const searchUrl = `https://www.google.com/search?q=${encodeURIComponent(name)}`;
```

### ProfilePage Tab Addition Pattern

Current tab bar (ProfilePage.tsx lines 634-652):
```typescript
{(['profile', 'referrals', 'posts', 'contributor'] as const).map((tab) => {
  if ((tab === 'referrals' || tab === 'posts' || tab === 'contributor') && !cp) return null;
  // ...
})}
```

Adding `'location'` tab: visible to ALL tiers (both Connected and Inform see school district when they have a location). Recommended visibility condition: show when `profile.location_consent === true` OR `profile.inform_profile?.last_essentials_location != null`.

Inform tier UI: `border-ev-yellow` active indicator (matches existing inform tab style).
Connected tier UI: `border-ev-teal-light` active indicator.

### Tier-Aware District Fetching

Both tiers use the same `GET /api/account/school-district` endpoint (requireAuth only — matches `GET /api/account/districts` pattern from Phase 70). `connect.user_districts` is populated for both tiers via Phase 70's wiring.

### Path 0 layerTypeMap Extension

The existing Path 0 in `GET /api/essentials/representatives/me` uses a hard-coded `layerTypeMap`. School layers will appear in `connect.user_districts` after Phase 71. Adding school entries to `layerTypeMap` is safe — the join against `essentials.districts` returns zero rows (no school board politicians yet), so it has no effect on the response. The CONTEXT says "wire the join now."

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Point-in-polygon school district resolution | Custom ST_Contains in Node.js | `essentials.cache_user_districts` RPC — just add school layers to default `p_layers` |
| School district polygon import | Manual INSERT with coordinates | `ogr2ogr` + stage table + `ON CONFLICT (layer, geoid) DO UPDATE` (exact pattern from seed-tiger-districts.sh) |
| Shapefile reprojection | Custom coordinate transform | `ogr2ogr -t_srs EPSG:4326` handles NAD83→WGS84 automatically |
| Google search URL encoding | Custom URL builder | `encodeURIComponent(name)` — standard JS, no library needed |
| District name lookup | Direct geoid-to-name lookup table | JOIN `essentials.geo_districts gd ON gd.layer = ud.layer AND gd.geoid = ud.geoid` — same join used in GET /account/districts |

---

## Common Pitfalls

### Pitfall 1: Using NAMELSAD instead of NAME for school district shapefiles

**What goes wrong:** The Phase 69 seed script queries `NAMELSAD AS name` for assembly/senate/us_house layers. School district shapefiles use `NAME` not `NAMELSAD`. If the seed script template is copied verbatim, ogr2ogr fails with "field NAMELSAD not found."

**How to avoid:** School district SQL query: `SELECT GEOID, UNSDLEA AS district_num, NAME AS name FROM ...` (ELSD: ELSDLEA, SCSD: SCSDLEA). Do NOT use NAMELSAD for school layers.

**Warning signs:** ogr2ogr exits with "field not found" error during import.

### Pitfall 2: Not distinguishing unified vs. elementary+secondary in the UI

**What goes wrong:** A user in a unified district has `school_unified` in user_districts but not `school_elementary`/`school_secondary`. A user in a non-unified area has `school_elementary` + `school_secondary` but not `school_unified`. If the UI blindly renders all three possible keys, it will show "School District: null" entries.

**How to avoid:** Display logic (from CONTEXT):
- If `school_unified` is present: render single "School District: [name]" entry
- If `school_unified` is absent and `school_elementary` and/or `school_secondary` present: render labeled sub-entries
- If none: hide the school district section entirely (no placeholder)

### Pitfall 3: Calling cache_user_districts via adminRpc for school layer backfill

**What goes wrong:** Same as Phase 70 Pitfall 1. The `essentials` schema is NOT in PostgREST's exposed schema list. All calls to `essentials.cache_user_districts` MUST use `pool.query()`.

**How to avoid:** Never call `essentials.*` via `adminRpc()`. Use `pool.query('SELECT essentials.cache_user_districts($1, $2, $3)', [userId, lat, lng])`.

### Pitfall 4: GEOID format for school districts differs from assembly/senate

**What goes wrong:** Assembly/senate GEOIDs are 5 chars (e.g., `06054`). School district GEOIDs are 7 chars (STATEFP 2 + LEA 5, e.g., `0610710`). If any code assumes a fixed GEOID length, it breaks for school layers.

**How to avoid:** Store the raw GEOID verbatim in `geo_districts.geoid` and `user_districts.geoid`. The schema already uses `TEXT NOT NULL` — no truncation issues. The `district_num` field stores the 5-char LEA code.

### Pitfall 5: The Location tab doesn't exist yet — must be created

**What goes wrong:** Phase 71 CONTEXT says "school district appears in the existing Location tab" — but ProfilePage.tsx has NO Location tab. If the planner assumes the tab exists and skips its creation, the school district display has nowhere to render.

**How to avoid:** Phase 71 must add `'location'` to the tab array AND build the Location tab content. The Location tab needs: (a) legislative districts from `GET /api/account/districts`, (b) school district from new `GET /api/account/school-district` endpoint, (c) current city/address display, (d) recalibration controls (currently in CivicSpacesTile for Connected users within the Profile tab).

### Pitfall 6: Extending cache_user_districts default p_layers automatically affects recache admin RPC

**What goes wrong:** `essentials.recache_user_districts_for_user(uuid)` (migration 092) calls `essentials.cache_user_districts(p_user_id, lat, lng)` with no explicit `p_layers` — so it uses the default. After Phase 71 updates the default, the admin recache script automatically runs school layer resolution too.

**How to avoid:** This is GOOD behavior — consistent cache. No additional action needed. The planner should not add redundant school-specific recache logic.

### Pitfall 7: Windows PROJ_LIB must be set for ogr2ogr (from Phase 69 experience)

**What goes wrong:** ogr2ogr fails with PROJ errors on Windows if `PROJ_LIB` is not set.

**How to avoid:** Seed script must include: `export PROJ_LIB="C:/Program Files/GDAL/projlib"` before ogr2ogr calls.

### Pitfall 8: Session pooler required for psql/ogr2ogr (from Phase 69 experience)

**What goes wrong:** Direct Supabase host DNS fails due to IPv6 on this machine.

**How to avoid:** Always use `aws-0-<region>.pooler.supabase.com:5432` (session pooler).

### Pitfall 9: apiFetch throws on 204 (no body to parse)

**What goes wrong:** `apiFetch` calls `res.json()` on all `res.ok` responses. 204 No Content has no body — `res.json()` throws a SyntaxError. If the caller does not catch this, it becomes an unhandled rejection and the Location tab crashes.

**How to avoid:** Always wrap the school-district fetch in `.catch(() => {})`:
```typescript
apiFetch<SchoolDistrictData>('/account/school-district')
  .then(setSchoolDistrict)
  .catch(() => {}); // 204 throws (no body) — state stays null, section hidden
```

---

## Code Examples

Verified patterns from official sources:

### Migration: Extend cache_user_districts and resolve_user_districts default p_layers

```sql
-- New migration: NNN_extend_cache_user_districts_school_layers.sql
-- Both RPCs use CREATE OR REPLACE and are SECURITY DEFINER SET search_path = ''
-- Must re-GRANT EXECUTE after CREATE OR REPLACE replaces the function

CREATE OR REPLACE FUNCTION essentials.resolve_user_districts(
  p_lat    float8,
  p_lng    float8,
  p_layers text[] DEFAULT ARRAY[
    'ca_assembly', 'ca_senate', 'us_house',
    'school_unified', 'school_elementary', 'school_secondary'
  ]
)
RETURNS TABLE(layer text, geoid text, district_num text, name text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT gd.layer, gd.geoid, gd.district_num, gd.name
  FROM essentials.geo_districts gd
  WHERE gd.layer = ANY(p_layers)
    AND public.ST_Contains(gd.geom, public.ST_SetSRID(public.ST_MakePoint(p_lng, p_lat), 4326))
$$;

GRANT EXECUTE ON FUNCTION essentials.resolve_user_districts(float8, float8, text[])
  TO authenticated, anon;

CREATE OR REPLACE FUNCTION essentials.cache_user_districts(
  p_user_id UUID,
  p_lat     float8,
  p_lng     float8,
  p_layers  text[] DEFAULT ARRAY[
    'ca_assembly', 'ca_senate', 'us_house',
    'school_unified', 'school_elementary', 'school_secondary'
  ]
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT layer, geoid, district_num
    FROM essentials.resolve_user_districts(p_lat, p_lng, p_layers)
  LOOP
    INSERT INTO connect.user_districts (user_id, layer, geoid, district_num, resolved_at)
    VALUES (p_user_id, r.layer, r.geoid, r.district_num, now())
    ON CONFLICT (user_id, layer) DO UPDATE
      SET geoid        = EXCLUDED.geoid,
          district_num = EXCLUDED.district_num,
          resolved_at  = EXCLUDED.resolved_at;
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION essentials.cache_user_districts(UUID, float8, float8, text[])
  TO authenticated;
```

Note: `p_layers` is added as a 4th parameter to `cache_user_districts`. The existing call sites in Node.js call `cache_user_districts($1, $2, $3)` with only 3 parameters — Postgres uses the default for `p_layers` when the 4th argument is omitted. This is backwards-compatible.

### Seed Script: School District Import (scripts/seed-tiger-school-districts.sh)

```bash
#!/usr/bin/env bash
# seed-tiger-school-districts.sh
# Phase 71: TIGER 2024 California school district import
# Separate from seed-tiger-districts.sh (different field names: NAME not NAMELSAD)

set -euo pipefail

if [[ -z "${DB_URL:-}" ]]; then
  echo "ERROR: DB_URL required. Use session pooler (aws-0-*.pooler.supabase.com:5432)"
  exit 1
fi

# Windows: PROJ_LIB required for ogr2ogr
export PROJ_LIB="${PROJ_LIB:-C:/Program Files/GDAL/projlib}"

WORK_DIR="${WORK_DIR:-/tmp/tiger}"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

download_if_missing() {
  local url="$1"; local zip="$2"
  [[ -f "$zip" ]] && echo "  [skip] $zip" || curl -sSL "$url" -o "$zip"
  unzip -o -q "$zip"
}

echo "[1/3] Downloading TIGER 2024 school district shapefiles..."
download_if_missing "https://www2.census.gov/geo/tiger/TIGER2024/UNSD/tl_2024_06_unsd.zip" "unsd.zip"
download_if_missing "https://www2.census.gov/geo/tiger/TIGER2024/ELSD/tl_2024_06_elsd.zip" "elsd.zip"
download_if_missing "https://www2.census.gov/geo/tiger/TIGER2024/SCSD/tl_2024_06_scsd.zip" "scsd.zip"

# School district shapefiles use NAME (not NAMELSAD) and UNSDLEA/ELSDLEA/SCSDLEA (not SLDLST)
import_school_layer() {
  local shp="$1"; local layer_name="$2"; local lea_col="$3"
  echo "[2/3] Importing $layer_name..."
  psql "$DB_URL" -v ON_ERROR_STOP=1 -c \
    "DROP TABLE IF EXISTS essentials.geo_districts_stage;" >/dev/null
  ogr2ogr \
    -f PostgreSQL "$DB_URL" "$shp" \
    -nln essentials.geo_districts_stage \
    -nlt MULTIPOLYGON \
    -t_srs EPSG:4326 \
    -lco GEOMETRY_NAME=geom \
    -lco SCHEMA=essentials \
    -overwrite \
    -sql "SELECT GEOID, ${lea_col} AS district_num, NAME AS name FROM $(basename "$shp" .shp)"
  psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
    INSERT INTO essentials.geo_districts (layer, geoid, district_num, name, geom)
    SELECT '${layer_name}', geoid, district_num, name, geom
    FROM essentials.geo_districts_stage
    ON CONFLICT (layer, geoid) DO UPDATE
      SET district_num = EXCLUDED.district_num,
          name         = EXCLUDED.name,
          geom         = EXCLUDED.geom;
    DROP TABLE IF EXISTS essentials.geo_districts_stage;
  "
  echo "       $layer_name imported."
}

import_school_layer "$WORK_DIR/tl_2024_06_unsd.shp" "school_unified"     "UNSDLEA"
import_school_layer "$WORK_DIR/tl_2024_06_elsd.shp" "school_elementary"  "ELSDLEA"
import_school_layer "$WORK_DIR/tl_2024_06_scsd.shp" "school_secondary"   "SCSDLEA"

echo "[3/3] Verification"
psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
  SELECT layer, count(*) AS rows
  FROM essentials.geo_districts
  WHERE layer IN ('school_unified', 'school_elementary', 'school_secondary')
  GROUP BY layer ORDER BY layer;
"
echo "Spot-check — LA City Hall (34.0537, -118.2430):"
psql "$DB_URL" -v ON_ERROR_STOP=1 -c "
  SELECT layer, geoid, name
  FROM essentials.resolve_user_districts(34.0537, -118.2430,
    ARRAY['school_unified','school_elementary','school_secondary'])
  ORDER BY layer;
"
echo "=== Done ==="
```

### New Endpoint: GET /api/account/school-district

```typescript
// In backend/src/routes/account.ts — add before export default router
// Auth: requireAuth (both Inform and Connected)
// Returns: { school_unified, school_elementary, school_secondary }
//          each: { name: string | null; geoid: string } | null
// Returns 204 when user has no school district rows

router.get('/school-district', requireAuth, async (req, res: Response) => {
  const authReq = req as AuthenticatedRequest;
  try {
    const { rows } = await pool.query<{
      layer: string;
      geoid: string;
      name: string | null;
    }>(
      `SELECT ud.layer, ud.geoid, gd.name
       FROM connect.user_districts ud
       LEFT JOIN essentials.geo_districts gd
         ON gd.layer = ud.layer AND gd.geoid = ud.geoid
       WHERE ud.user_id = $1
         AND ud.layer IN ('school_unified', 'school_elementary', 'school_secondary')`,
      [authReq.userId]
    );
    if (rows.length === 0) { res.status(204).end(); return; }
    const byLayer = Object.fromEntries(
      rows.map((r) => [r.layer, { name: r.name ?? null, geoid: r.geoid }])
    );
    res.status(200).json({
      school_unified:    byLayer['school_unified']    ?? null,
      school_elementary: byLayer['school_elementary'] ?? null,
      school_secondary:  byLayer['school_secondary']  ?? null,
    });
  } catch (err) {
    console.error('[GET /api/account/school-district] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});
```

### ProfilePage: School District State + Fetch Pattern

```typescript
// Types
interface SchoolDistrictEntry { name: string | null; geoid: string; }
interface SchoolDistrictData {
  school_unified:    SchoolDistrictEntry | null;
  school_elementary: SchoolDistrictEntry | null;
  school_secondary:  SchoolDistrictEntry | null;
}

// State
const [schoolDistrict, setSchoolDistrict] = useState<SchoolDistrictData | null>(null);

// In useEffect, alongside other optional fetches:
apiFetch<SchoolDistrictData>('/account/school-district')
  .then(setSchoolDistrict)
  .catch(() => {}); // 204 throws SyntaxError (no body) — state stays null, section hidden

// Tab visibility guard (show Location tab when user has location)
const hasLocation = profile.location_consent || (profile.inform_profile?.last_essentials_location != null);
```

### ProfilePage: School District Display Component

```typescript
// Display logic from CONTEXT decisions:
// - school_unified present → single "School District: [name]" entry
// - school_unified absent, elementary/secondary present → two labeled sub-entries
// - none present → hide section entirely (no placeholder, no "not available")

function SchoolDistrictSection({ data }: { data: SchoolDistrictData | null }) {
  if (!data) return null;
  const { school_unified, school_elementary, school_secondary } = data;
  if (!school_unified && !school_elementary && !school_secondary) return null;

  const makeLink = (name: string | null, geoid: string) => {
    const label = name ?? geoid;
    return (
      <a
        href={`https://www.google.com/search?q=${encodeURIComponent(label)}`}
        target="_blank"
        rel="noopener noreferrer"
        className="text-ev-teal dark:text-ev-teal-light hover:underline text-sm"
      >
        {label}
      </a>
    );
  };

  if (school_unified) {
    return (
      <div>
        <p className="text-xs font-medium text-gray-500 dark:text-gray-400">School District</p>
        {makeLink(school_unified.name, school_unified.geoid)}
      </div>
    );
  }

  return (
    <div className="space-y-1.5">
      {school_elementary && (
        <div>
          <p className="text-xs font-medium text-gray-500 dark:text-gray-400">Elementary School District</p>
          {makeLink(school_elementary.name, school_elementary.geoid)}
        </div>
      )}
      {school_secondary && (
        <div>
          <p className="text-xs font-medium text-gray-500 dark:text-gray-400">Secondary School District</p>
          {makeLink(school_secondary.name, school_secondary.geoid)}
        </div>
      )}
    </div>
  );
}
```

### Path 0 layerTypeMap Extension (essentials.ts)

```typescript
// In backend/src/routes/essentials.ts — update layerTypeMap in Path 0
const layerTypeMap: Record<string, string> = {
  ca_assembly:       'STATE_LOWER',
  ca_senate:         'STATE_UPPER',
  us_house:          'NATIONAL_LOWER',
  school_unified:    'SCHOOL_UNIFIED',    // no essentials.districts rows yet — join returns empty
  school_elementary: 'SCHOOL_ELEMENTARY', // same — zero politicians until school board ingestion phase
  school_secondary:  'SCHOOL_SECONDARY',  // same
};
```

These district_type values (`SCHOOL_UNIFIED`, `SCHOOL_ELEMENTARY`, `SCHOOL_SECONDARY`) do not yet exist in `essentials.districts`. The join conditions produce zero rows — correct behavior until school board politicians are added in a future phase.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Phase 69 covered 3 legislative layers | Phase 71 adds 3 school layers | Phase 71 | geo_districts grows by ~1,000+ school district rows; user_districts adds up to 3 rows per CA user |
| cache_user_districts default: 3 layers | cache_user_districts default: 6 layers | Phase 71 (migration) | All future location writes include school layer resolution automatically |
| ProfilePage: 4 tabs (profile/referrals/posts/contributor) | ProfilePage: 5 tabs (adds location) | Phase 71 | Location tab is permanent home for geographic/district info |

**Deprecated/outdated:**
- None — Phase 71 is additive only.

---

## Open Questions

1. **District type values for school layers in essentials.districts**
   - What we know: The join in Path 0 uses `essentials.districts.district_type`. Currently only `STATE_LOWER`, `STATE_UPPER`, `NATIONAL_LOWER` exist for CA districts. School board politicians go into `essentials.districts` when ingested in a future phase.
   - What's unclear: Should Phase 71 pre-create the district_type values as a migration, or leave that to the future ingestion phase? If added now, they're empty placeholder types. If deferred, Phase 71's `layerTypeMap` entries will join against zero rows (safe and correct).
   - Recommendation: Do NOT add empty `essentials.districts` rows in Phase 71. Add `SCHOOL_UNIFIED`, `SCHOOL_ELEMENTARY`, `SCHOOL_SECONDARY` to `layerTypeMap` in essentials.ts (join returns zero rows — correct until school board politicians are added). No migration needed for district types in Phase 71.

2. **Location tab visibility condition (Claude's Discretion)**
   - Recommendation: Show the Location tab when `profile.location_consent === true` OR `profile.inform_profile?.last_essentials_location != null`. Hide it otherwise (no tab for users without location). This aligns with "Zero-match: hide the school district section entirely" from CONTEXT.

3. **Placement of school district in Location tab (Claude's Discretion)**
   - Recommendation: Place school district after legislative districts and before the recalibration controls. Legislative districts are more prominent for most users; school district is supplementary context.

---

## Sources

### Primary (HIGH confidence)
- `C:\EV-Accounts\supabase\migrations\20260509000002_090_tiger_resolve_user_districts_rpcs.sql` — resolve_user_districts + cache_user_districts full implementation
- `C:\EV-Accounts\supabase\migrations\20260509000001_089_tiger_geo_districts_schema.sql` — geo_districts + user_districts table schema verbatim
- `C:\EV-Accounts\scripts\seed-tiger-districts.sh` — ogr2ogr import pattern + NAMELSAD vs NAME field distinction
- `C:\EV-Accounts\admin\src\pages\ProfilePage.tsx` — confirmed: 4 tabs, no Location tab exists
- `C:\EV-Accounts\admin\src\lib\api.ts` — confirmed: apiFetch calls res.json() on all res.ok; 204 throws SyntaxError
- `C:\EV-Accounts\backend\src\routes\account.ts` (lines 714-765) — GET /api/account/districts implementation verbatim
- `C:\EV-Accounts\.planning\phases\69-tiger-schema-data-import\69-VERIFICATION.md` — all geo schema facts verified against live DB
- `C:\EV-Accounts\.planning\phases\70-geofencing-backend-integration\70-VERIFICATION.md` — Phase 70 backend wiring verified
- `https://www2.census.gov/geo/tiger/TIGER2024/UNSD/` — CA UNSD file confirmed: tl_2024_06_unsd.zip (4.1M)
- `https://www2.census.gov/geo/tiger/TIGER2024/ELSD/` — CA ELSD file confirmed: tl_2024_06_elsd.zip (3.5M)
- `https://www2.census.gov/geo/tiger/TIGER2024/SCSD/` — CA SCSD file confirmed: tl_2024_06_scsd.zip (1.8M)

### Secondary (MEDIUM confidence)
- NCES EDGE MapServer layer endpoint — GEOID (7 chars), NAME (100 chars), UNSDLEA/ELSDLEA/SCSDLEA (5 chars each) confirmed as standard field names for school district shapefiles

### Tertiary (LOW confidence)
- None — all critical findings have HIGH or MEDIUM sources

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new libraries; existing ogr2ogr/pool.query/Express patterns fully established
- TIGER file URLs + field names: HIGH — verified against live Census Bureau server + NCES documentation
- Architecture (school layers in geo_districts): HIGH — schema explicitly designed for this (migration 089 comment: "Phase 71 will add school layers")
- cache_user_districts extension: HIGH — RPC is `CREATE OR REPLACE`, default `p_layers` update is straightforward and backwards-compatible
- ProfilePage Location tab: HIGH — confirmed from source inspection that no Location tab exists; must be created
- School district endpoint: HIGH — pattern identical to GET /account/districts
- apiFetch 204 behavior: HIGH — confirmed from admin/src/lib/api.ts: res.json() called unconditionally; 204 throws; must catch silently
- District_type for school layers: MEDIUM — recommend not pre-creating, but this is a design decision

**Research date:** 2026-05-09
**Valid until:** 2026-06-09 (schema stable; TIGER file URLs stable; Census Bureau school district boundaries updated every 2 years)
