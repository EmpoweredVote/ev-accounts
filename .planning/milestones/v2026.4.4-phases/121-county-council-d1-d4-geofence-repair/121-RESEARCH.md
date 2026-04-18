# Phase 121: County Council D1→D4 Geofence Repair — Research

**Researched:** 2026-04-16
**Domain:** PostGIS geofence data repair — Monroe County Council (MCC) district polygon import
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01 (Ground Truth):** The correct MCC district for 200 W Kirkwood Ave is **currently
  unverified**. Research must consult authoritative source before any data is written. (NOW
  RESOLVED — see Ground Truth Resolution section below.)
- **D-02 (Diagnose first):** Confirm at live-DB level whether sub-district MCC polygons exist
  in `essentials.geofence_boundaries` and what the four district offices currently link to.
  Scout evidence suggests all four link to shared county-wide `geo_id='18105'`.
- **D-03 (Planner picks fix approach after diagnosis):** Structural import (source 4 polygons,
  insert, re-link) if sub-district polygons are missing; targeted repair if mis-coordinated.
  All 4 MCC District races must resolve to their own distinct geofence.
- **D-04 (Polygon source):** Monroe County GIS / ArcGIS is the authoritative source. Do not
  fall back to TIGER VTDs or state redistricting datasets.
- **D-05 (Schema proposal):** Researcher proposes the minimal schema-consistent approach for
  4 MCC sub-districts in `essentials.districts` + `essentials.geofence_boundaries`.
- **D-06 (Verification):** Use the Kirkwood Ave address from Phase 119. Final verification on
  production (api.empowered.vote) after Render deploy.
- **D-07 (Exclusivity):** Verification must prove exactly one MCC District race returned for
  Kirkwood, not all four.

### Claude's Discretion

- Exact diagnostic SQL to run against live DB.
- Whether to extend `audit-112-geofence.ts` or add a new MCC-specific smoke test.
- Whether to add coverage for representative D2/D3/D4 addresses as well.
- Whether SQL repair lives in a new migration, a one-off script, or an edit to the existing
  `link-monroe-county-races-to-geofences.sql`.

### Deferred Ideas (OUT OF SCOPE)

- Mt Tabor Rd geocoding failure (AUDIT-08) and rural address geocoding — Phase 126.
- Township polygon fallbacks (`link-monroe-county-races-to-geofences.sql` §1c COALESCE) — Phase 126.
- MCC-style sub-district coverage for other counties — not in Tier 1 scope.
- Frontend display of "your council district: D-N".
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GEO-01 | Kirkwood Ave Bloomington address resolves to the correct Monroe County Council district (not D1 when D4 expected) | Ground truth confirmed: D4 is correct. Fix strategy: import 4 per-district polygons from Monroe County GIS FeatureServer, re-link offices to per-district geofences. |
| GEO-02 | Geofence fix validated against the Kirkwood test address from MATRIX.md Dim 1 | `audit-112-geofence.ts` already has Kirkwood pre-geocoded at lat=39.166646, lng=-86.534947. Extend to assert exactly 1 MCC Council race returned. |
</phase_requirements>

---

## Summary

The root cause of Phase 121 is structural, not a polygon coordinate error: all four Monroe
County Council (MCC) district races are currently linked (via `essentials.offices`) to a
single shared COUNTY-level district in `essentials.districts` which references `geo_id='18105'`
— the county-wide boundary polygon. Because all four offices point to the same geofence, any
address inside Monroe County matches all four MCC District races at once.

**Ground truth is now resolved.** The authoritative Monroe County GIS FeatureServer confirms:
200 W Kirkwood Ave, Bloomington IN 47404 (lat=39.166646, lng=-86.534947) is in **Council
District 4** (represented by Jennifer Crossley). This validates ROADMAP.md's "D4 not D1"
assertion. The GAP-REPORT PATTERN-004 description that says "should be D1" has the direction
wrong — D1 is the description from Ballotpedia's superset display (Ballotpedia shows all 4
council districts for every address; its "District 1" is not a ground-truth district
assignment but rather a superset listing). The ROADMAP.md call of D4 is correct.

The fix is a structural import: source 4 per-district polygon features from the Monroe County
GIS FeatureServer (`gis.co.monroe.in.us`), insert them into `essentials.geofence_boundaries`
with distinct `geo_id` values (`18105-mcc-d1` through `18105-mcc-d4`), create 4 matching rows
in `essentials.districts` with `district_type='COUNTY'` and an appropriate MTFCC
(`X-MCC-DISTRICT` for the custom local-gov slot), then re-link each of the 4 MCC office rows
to its own district record. Update `link-monroe-county-races-to-geofences.sql` to reflect the
correct wiring for idempotent re-runs.

**Primary recommendation:** Write a new TypeScript import script
(`scripts/import-mcc-district-polygons.ts`) that fetches the 4 polygon features from the
Monroe County FeatureServer in GeoJSON format, inserts them, and re-links the MCC offices —
then modify `link-monroe-county-races-to-geofences.sql` §2a to point to per-district offices
instead of the shared county office, and verify with the extended `audit-112-geofence.ts`.

---

## Ground Truth Resolution (D-01)

**Status: RESOLVED — D4 is correct.**

| Source | Method | Result |
|--------|--------|--------|
| Monroe County GIS FeatureServer (`gis.co.monroe.in.us`) | Spatial point-in-polygon query against `MoCo_Council_Districts/FeatureServer/0` for point (-86.534947, 39.166646) | **Council 4** (Jennifer Crossley) [VERIFIED] |
| Indiana Statewide Admin Boundaries FeatureServer (`gisdata.in.gov`) | Same spatial query against County Council Polygons layer 4 | **Council 4** [VERIFIED: gisdata.in.gov] |
| Ballotpedia benchmark (`research/benchmark/ballotpedia.md`) | Sample ballot tool for 200 W Kirkwood Ave | Shows all 4 council districts (superset — does NOT indicate district of voter) |
| GAP-REPORT PATTERN-004 | Text description: "should resolve to D1, returns D4" | **INCORRECT framing.** The bug description in GAP-REPORT has the correct-district reversed. D4 is correct; D1 is not the voter's district. |
| ROADMAP.md Phase 121 success criteria | Text: "correct Monroe County Council district — the D1→D4 binding bug" | **CORRECT.** ROADMAP means the current system incorrectly maps all addresses to show D1 (the first district when they all link to the same county-wide record), and D4 is the correct result for Kirkwood. |

**Documentation update required:** GAP-REPORT.md PATTERN-004 text "should resolve to D1,
returns D4" must be corrected to "should resolve to D4 for Kirkwood, but currently returns all
four districts (D1/D2/D3/D4) because all four race offices link to the same county-wide
geofence." The confusion arose because GAP-REPORT was comparing the EV result against the
Ballotpedia superset; Ballotpedia listed D1 first, which was incorrectly treated as the
authoritative correct district.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Polygon import (fetch 4 features from ArcGIS FeatureServer) | Database / Storage | — | One-time data import; no user-facing layer needed |
| geofence_boundaries row insertion | Database / Storage | — | PostGIS data; INSERT into essentials schema |
| districts row creation | Database / Storage | — | Schema data wiring; 4 new rows |
| offices re-linking | Database / Storage | — | UPDATE existing offices to point to per-district districts |
| Race → office → district → geofence query | API / Backend | — | electionService Part A already implements this; no code changes needed once data is correct |
| Smoke test / verification | API / Backend | — | `audit-112-geofence.ts` extends existing integration test pattern |

---

## Live DB Diagnosis (D-02) — What Research Confirmed

The seed script analysis and SQL inspection confirm (with HIGH confidence based on reading the
code; live-DB confirmation is a Wave 0 diagnostic task for the planner):

**Current state in DB:**
- `essentials.geofence_boundaries`: Contains `geo_id='18105'` (the county-wide Monroe County
  polygon, MTFCC `G4020`). NO sub-district MCC polygons exist. This is the missing-polygon
  scenario from D-03.
- `essentials.districts`: Contains one `district_type='COUNTY'` row with `geo_id='18105'`
  (created by `link-monroe-county-races-to-geofences.sql` §1a).
- `essentials.offices`: Has four rows titled `'Monroe County Council District 1'` through
  `'Monroe County Council District 4'` — all linked (`district_id`) to the **same** COUNTY
  district record (see §2a of the link script, which uses `WHERE d.geo_id = '18105' AND
  d.district_type = 'COUNTY'` for all four council district offices).
- Result: `ST_Covers` for ANY Monroe County address matches all four MCC Council District
  offices, because one polygon (the county boundary) covers the entire county.

**Diagnostic SQL to confirm current state (run against dev DB):**
```sql
-- Check: do sub-district MCC polygons exist?
SELECT geo_id, name, mtfcc, state
FROM essentials.geofence_boundaries
WHERE geo_id LIKE '18105%'
ORDER BY geo_id;

-- Check: which district do the 4 council offices point to?
SELECT o.title, d.geo_id, d.district_type, d.label
FROM essentials.offices o
JOIN essentials.districts d ON d.id = o.district_id
WHERE o.title LIKE 'Monroe County Council District%'
ORDER BY o.title;

-- Check: does the Kirkwood point match 1 or 4 council races?
SELECT r.position_name, r.primary_party, d.geo_id, d.district_type
FROM essentials.elections e
JOIN essentials.races r ON r.election_id = e.id
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
WHERE e.name = '2026 Indiana Primary'
  AND r.position_name LIKE 'Monroe County Council%'
  AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-86.534947, 39.166646), 4326))
ORDER BY r.position_name;
```

---

## Standard Stack

### Core (already installed — no new dependencies needed)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| pg (node-postgres) | ^8.x | DB queries against Supabase PostgreSQL | Already in use across all scripts |
| PostGIS `ST_GeomFromGeoJSON` | PostGIS 3.x (on Supabase) | Load GeoJSON polygon into geometry column | Established pattern: `load-ca-state-boundaries.ts` line ~180 |
| Node.js `https` | built-in | Fetch GeoJSON from ArcGIS FeatureServer REST API | Used in `load-us-congressional-boundaries.ts` |
| dotenv | ^16.x | Load `DATABASE_URL` from `.env` | Standard across all backend scripts |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| shapefile | ^0.6.6 | Parse TIGER/Line shapefile format | NOT needed here — ArcGIS FeatureServer returns GeoJSON directly via REST |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Direct ArcGIS REST GeoJSON fetch | Download shapefile from county | REST API is simpler, returns GeoJSON directly with `?f=geojson`; no unzip/parse needed |
| Indiana statewide FeatureServer | Monroe County's own FeatureServer | Monroe County GIS is more authoritative; only 2 of 4 districts were initially returned from the statewide service (potential data gap) — use Monroe County's own service |

**Installation:** No new packages required.

---

## Authoritative Polygon Source (D-04)

**Monroe County GIS FeatureServer — VERIFIED:**

```
https://gis.co.monroe.in.us/server/rest/services/MoCo_Council_Districts/FeatureServer/0
```

- Layer name: `MoCo_COUNCIL_Districts`
- Geometry type: `esriGeometryPolygon`
- Fields: `OBJECTID`, `CountyCouncil` (district number string), `Council` (e.g. "Council 4"),
  `Rep` (current representative name), `GlobalID`, `Shape__Area`, `Shape__Length`
- Confirmed 4 features (all 4 MCC districts)
- Coordinates: WGS84 EPSG:4326 (confirmed via `?outSR=4326&f=geojson`)

**All 4 district records confirmed:**

| OBJECTID | CountyCouncil | Council | Rep |
|----------|---------------|---------|-----|
| 1 | 3 | Council 3 | Marty Hawk |
| 2 | 1 | Council 1 | Peter Iversen |
| 3 | 4 | Council 4 | Jennifer Crossley |
| 4 | 2 | Council 2 | Kate Wiltz |

**GeoJSON query URL:**
```
https://gis.co.monroe.in.us/server/rest/services/MoCo_Council_Districts/FeatureServer/0/query?where=1%3D1&outFields=OBJECTID,CountyCouncil,Council,Rep&outSR=4326&f=geojson
```

**Point-in-polygon confirm for Kirkwood:**
```
https://gis.co.monroe.in.us/server/rest/services/MoCo_Council_Districts/FeatureServer/0/query?geometry={"x":-86.534947,"y":39.166646,"spatialReference":{"wkid":4326}}&geometryType=esriGeometryPoint&spatialRel=esriSpatialRelIntersects&outFields=*&f=json&returnGeometry=false
```
Returns: Council 4 (OBJECTID=3, CountyCouncil="4", Rep="Jennifer Crossley") [VERIFIED]

**Backup source (Indiana statewide — secondary):**
```
https://gisdata.in.gov/server/rest/services/Hosted/Administrative_Boundaries_of_Indiana_2024/FeatureServer/4
```
(County Council Polygons layer 4 — confirmed Monroe County entries but showed only 3/4
districts in initial query; Monroe County's own FeatureServer is preferred.)

---

## Architecture Patterns

### System Architecture Diagram

```
Monroe County GIS FeatureServer
  (gis.co.monroe.in.us/…/MoCo_Council_Districts)
           │
           │  HTTPS GET ?where=1=1&f=geojson&outSR=4326
           ▼
import-mcc-district-polygons.ts
  ├── Fetch 4 GeoJSON polygon features
  ├── For each district (D1, D2, D3, D4):
  │     ├── INSERT essentials.geofence_boundaries (geo_id=18105-mcc-d{N}, mtfcc=X-MCC-DISTRICT)
  │     │     └── ON CONFLICT (geo_id, mtfcc) DO NOTHING
  │     └── INSERT essentials.districts (geo_id=18105-mcc-d{N}, district_type='COUNTY',
  │           district_id='election-mcc-d{N}')
  │           └── WHERE NOT EXISTS guard
  └── Report: 4 inserted, 0 errors
           │
           │  (post-import)
           ▼
link-monroe-county-races-to-geofences.sql  ← UPDATE §2a block
  ├── CREATE 4 new office rows (one per MCC district, pointing to per-district district rows)
  └── UPDATE races to set office_id (match by position_name 'Monroe County Council District N')
           │
           ▼
essentials.geofence_boundaries (4 new rows: geo_id 18105-mcc-d{1..4})
essentials.districts            (4 new rows: district_id election-mcc-d{1..4})
essentials.offices              (4 rows re-linked to per-district districts)
           │
           │  (runtime — no code changes)
           ▼
electionService Part A  (races → offices → districts → geofence_boundaries → ST_Covers)
           │
           ▼
API response: Kirkwood → exactly 1 MCC Council race (District 4 only)
```

### Recommended Project Structure

```
ev-accounts/backend/scripts/
├── import-mcc-district-polygons.ts      ← NEW: fetch & insert 4 polygons
├── link-monroe-county-races-to-geofences.sql  ← EDIT: §2a creates per-district offices
└── audit-112-geofence.ts                ← EDIT: extend Kirkwood assertion for exclusivity
```

### Pattern 1: ArcGIS FeatureServer GeoJSON Import

**What:** Fetch polygon features from an ArcGIS FeatureServer REST endpoint, insert geometry
into `essentials.geofence_boundaries` using PostGIS `ST_GeomFromGeoJSON`, and create
corresponding `essentials.districts` rows.

**When to use:** Any time a local-government boundary layer is available on ArcGIS REST but
not in TIGER/Line shapefiles.

**Example (adapted from `load-ca-state-boundaries.ts` pattern):**
```typescript
// Source: ev-accounts/backend/scripts/load-ca-state-boundaries.ts lines 174-185
const geojson = JSON.stringify(feature.geometry);
await pool.query(`
  INSERT INTO essentials.geofence_boundaries
    (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
  VALUES (
    $1, $2, $3, $4, $5,
    public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($6)), 4326),
    'monroe_county_gis',
    now()
  )
  ON CONFLICT (geo_id, mtfcc) DO NOTHING
`, [geoId, ocdId, name, 'IN', MTFCC, geojson]);
```

### Pattern 2: MTFCC for Custom Local-Government Boundaries

**What:** When a boundary is not from TIGER/Line (no standard MTFCC), use a custom `X`-prefixed
MTFCC code. The `essentialsService.ts` query already handles this:

```typescript
// Source: ev-accounts/backend/src/lib/essentialsService.ts line 574
OR (gb.mtfcc LIKE 'X%' AND d.district_type IN ('LOCAL', 'COUNTY'))
```

**Proposed MTFCC for MCC district polygons:** `X-MCC-DISTRICT`
(matches `LIKE 'X%'` pattern, clearly labeled for maintainability).

**Also acceptable alternatives:** `X-LOCAL-DISTRICT` or simply `XCOUNTY` — the key constraint
is that it starts with `X` and is consistently used across all 4 geofence rows and 4 district
rows.

### Pattern 3: Idempotent District + Office Creation

**What:** The established pattern in `link-monroe-county-races-to-geofences.sql` uses
`INSERT ... WHERE NOT EXISTS` guards with `district_id` as the stable key.

**Proposed district_id values for 4 MCC districts:**
```
election-mcc-d1
election-mcc-d2
election-mcc-d3
election-mcc-d4
```
(Consistent with existing `election-twp-*` and `election-place-*` naming convention.)

**Proposed geo_id values for 4 geofence rows:**
```
18105-mcc-d1
18105-mcc-d2
18105-mcc-d3
18105-mcc-d4
```
(Prefixed with county FIPS `18105`, distinct from each other, satisfying the
`(geo_id, mtfcc)` composite uniqueness constraint together with `X-MCC-DISTRICT`.)

### Anti-Patterns to Avoid

- **Do not reuse `geo_id='18105'` for the per-district rows.** The composite uniqueness
  constraint on `(geo_id, mtfcc)` means you could insert with a different MTFCC, but this
  would cause the `ST_Covers` query to match BOTH the county-wide polygon AND the sub-district
  polygon for addresses inside Monroe County, which defeats the purpose.
- **Do not use `district_type='LOCAL'` for MCC districts.** The council is a county
  subdivision (COUNTY-level body). Using `district_type='COUNTY'` is consistent with the
  existing link script's intent. The `essentialsService.ts` query at line 574 handles
  `X%` MTFCC + `district_type IN ('LOCAL', 'COUNTY')` — COUNTY is already supported.
- **Do not delete the existing county-wide district and re-link it.** Other races (Commissioner,
  Assessor, Clerk, etc.) legitimately use the county-wide geofence and must not be disturbed.

---

## Schema Proposal (D-05)

### Minimal Schema-Consistent Approach

**Step 1: Insert 4 new `essentials.geofence_boundaries` rows**

```sql
-- geo_id: 18105-mcc-d{N} (N = 1, 2, 3, 4)
-- mtfcc:  X-MCC-DISTRICT  (custom, matches LIKE 'X%' in essentialsService.ts)
-- source: 'monroe_county_gis'
-- geometry: from ArcGIS FeatureServer GeoJSON, ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON(...)), 4326)
```

| geo_id | name | state | mtfcc | source |
|--------|------|-------|-------|--------|
| 18105-mcc-d1 | Monroe County Council District 1 | IN | X-MCC-DISTRICT | monroe_county_gis |
| 18105-mcc-d2 | Monroe County Council District 2 | IN | X-MCC-DISTRICT | monroe_county_gis |
| 18105-mcc-d3 | Monroe County Council District 3 | IN | X-MCC-DISTRICT | monroe_county_gis |
| 18105-mcc-d4 | Monroe County Council District 4 | IN | X-MCC-DISTRICT | monroe_county_gis |

No schema migration required — these are data inserts into an existing table.

**Step 2: Insert 4 new `essentials.districts` rows**

```sql
-- district_type: COUNTY (council is a county-level body)
-- mtfcc: X-MCC-DISTRICT (must match the geofence row for the join to work)
```

| geo_id | district_type | label | state | mtfcc | district_id |
|--------|--------------|-------|-------|-------|-------------|
| 18105-mcc-d1 | COUNTY | Monroe County Council District 1 | IN | X-MCC-DISTRICT | election-mcc-d1 |
| 18105-mcc-d2 | COUNTY | Monroe County Council District 2 | IN | X-MCC-DISTRICT | election-mcc-d2 |
| 18105-mcc-d3 | COUNTY | Monroe County Council District 3 | IN | X-MCC-DISTRICT | election-mcc-d3 |
| 18105-mcc-d4 | COUNTY | Monroe County Council District 4 | IN | X-MCC-DISTRICT | election-mcc-d4 |

**Step 3: Create 4 new `essentials.offices` rows (one per district)**

```sql
-- Each office: title = 'Monroe County Council District {N}', district_id = election-mcc-d{N}
-- politician_id = NULL (contested seat, not current holder)
```

**Step 4: UPDATE `essentials.races`**

Re-link each `Monroe County Council District N` race to the new per-district office (not the
shared county office). Match by `position_name`.

**Step 5: Update `link-monroe-county-races-to-geofences.sql` §2a**

Remove `Monroe County Council District 1/2/3/4` from the shared VALUES block (§2a currently
creates offices linked to the county-wide COUNTY district). Add a new §2e block that creates
per-district offices using the `election-mcc-d{N}` district_ids.

### What Does NOT Change

- `geo_id='18105'` county-wide geofence row — untouched
- The county-wide COUNTY district row — untouched
- Offices for Commissioner, Assessor, Clerk, Sheriff, etc. — untouched
- `essentialsService.ts` — no code changes needed
- `electionService.ts` — no code changes needed
- All frontend code — no changes needed

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Fetching GeoJSON polygon from ArcGIS REST | Custom scraper | HTTPS GET `?f=geojson` to FeatureServer REST endpoint | Standard ArcGIS REST API — returns valid GeoJSON directly |
| PostGIS geometry insertion | Manual coordinate manipulation | `ST_SetSRID(ST_Force2D(ST_GeomFromGeoJSON($1)), 4326)` | Established pattern from `load-ca-state-boundaries.ts` |
| Conflict handling on re-run | Delete + re-insert | `ON CONFLICT (geo_id, mtfcc) DO NOTHING` | Idempotency contract already established in the codebase |
| Point-in-polygon verification | Custom spatial math | `ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(lng, lat), 4326))` | Exact pattern already in `audit-112-geofence.ts` line ~215 |

---

## Common Pitfalls

### Pitfall 1: Leaving §2a Council Offices Linked to County-Wide District

**What goes wrong:** The import script adds the 4 new per-district offices, but the old offices
from §2a (still pointing to `geo_id='18105'`) remain in the DB. All council races now have
TWO office rows — the old one (county-wide) and the new one (per-district). The Kirkwood
address matches both, returning 4 races again (through the old offices).

**Why it happens:** Forgetting to null-out or delete the old council offices in step 4.

**How to avoid:** After the new offices are created and races re-linked, run a cleanup to
remove the 4 old council offices that still reference the county-wide district (or use
`WHERE r.office_id IS NULL` guard to prevent double-linking).

**Warning signs:** Diagnostic SQL returns >1 row for Kirkwood council query.

### Pitfall 2: MTFCC Mismatch Between geofence_boundaries and districts

**What goes wrong:** The `electionService.ts` join uses:
```sql
AND (d.mtfcc IS NULL OR d.mtfcc = '' OR gb.mtfcc = d.mtfcc)
```
If the `districts.mtfcc` value differs from `geofence_boundaries.mtfcc`, the join fails
silently and zero council races are returned.

**How to avoid:** Ensure both the `geofence_boundaries` row and the `districts` row use the
exact same MTFCC string (e.g., both `X-MCC-DISTRICT`). Confirm with the diagnostic query in
the Wave 0 task.

### Pitfall 3: MTFCC Not Matching `X%` Pattern in essentialsService.ts

**What goes wrong:** `essentialsService.ts` line 574 has `gb.mtfcc LIKE 'X%'`. If the MTFCC
chosen doesn't start with `X`, the representatives-by-address query (used by the Essentials
frontend) won't match the council district offices even though the election query works.

**How to avoid:** Use `X-MCC-DISTRICT` (starts with `X`). Verify the essentialsService query
path returns council members for the Kirkwood address post-fix.

### Pitfall 4: Geometry SRS Mismatch

**What goes wrong:** The ArcGIS FeatureServer returns geometry in Indiana State Plane or a
non-4326 SRS unless `outSR=4326` is specified in the query. Inserting non-4326 coordinates
produces geometries that fail PostGIS `ST_Covers` for a 4326 input point.

**How to avoid:** Always include `outSR=4326` (or `outFields=*&outSR=4326`) in the
FeatureServer query. The `ST_SetSRID(..., 4326)` in the insert sets the SRID but does NOT
reproject — coordinates must already be in 4326 before insertion.

### Pitfall 5: Race Already Linked to Old Office (Non-NULL office_id)

**What goes wrong:** The `link-monroe-county-races-to-geofences.sql` §3a UPDATE has
`AND r.office_id IS NULL`. If the council races are already linked to the old county-wide
offices, the re-link step won't fire.

**How to avoid:** In the repair script, set `r.office_id = NULL` for the 4 council district
races before running the re-link UPDATE (or remove the `AND r.office_id IS NULL` guard for the
council-district block specifically).

### Pitfall 6: ArcGIS FeatureServer URL Changes

**What goes wrong:** Monroe County GIS URL (`gis.co.monroe.in.us`) is a county-operated server
that may require authentication, change endpoints, or be down during import.

**How to avoid:** Confirm the URL is accessible before writing the import script. The import
should fail-fast with a clear error message if the FeatureServer returns HTTP 401, 403, or 404.
Document the URL in a comment in the script so future maintainers can find the source.

---

## Code Examples

### Verified PostGIS Insert Pattern (from existing codebase)

```typescript
// Source: ev-accounts/backend/scripts/load-ca-state-boundaries.ts lines 175-185
const gbResult = await pool.query(`
  INSERT INTO essentials.geofence_boundaries
    (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
  VALUES (
    $1, $2, $3, $4, $5,
    public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($6)), 4326),
    'census_tiger_2024',   -- replace with 'monroe_county_gis' for MCC
    now()
  )
  ON CONFLICT (geo_id, mtfcc) DO NOTHING
`, [geoid, ocdId, name, 'IN', 'X-MCC-DISTRICT', geojson]);
```

### Verified ST_Covers Query Pattern (from existing codebase)

```typescript
// Source: ev-accounts/backend/scripts/audit-112-geofence.ts lines 213-218
const geofenceResult = await pool.query(
  `SELECT r.position_name, r.primary_party, rc.full_name
   FROM essentials.elections e
   JOIN essentials.races r ON r.election_id = e.id
   LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
   JOIN essentials.offices o ON o.id = r.office_id
   JOIN essentials.districts d ON d.id = o.district_id
   JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
   WHERE e.election_date = '2026-05-05' AND e.state = 'IN'
     AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))
   ORDER BY r.position_name`,
  [addr.lng, addr.lat],  // NOTE: longitude first in ST_MakePoint
);
```

### Proposed Verification Extension for audit-112-geofence.ts

```typescript
// Add assertion after collecting rows for Bloomington City Center address:
const councilRaces = rows.filter(r =>
  r.position_name?.startsWith('Monroe County Council District')
);
if (councilRaces.length !== 1) {
  console.error(`FAIL: Expected exactly 1 MCC Council race for Kirkwood, got ${councilRaces.length}`);
  console.error(`  Races: ${councilRaces.map(r => r.position_name).join(', ')}`);
} else {
  console.error(`PASS: Kirkwood returns exactly 1 MCC Council race: ${councilRaces[0].position_name}`);
}
```

### ArcGIS FeatureServer Fetch Pattern (new pattern for this phase)

```typescript
// Fetch all 4 MCC council district polygons as GeoJSON
const url = 'https://gis.co.monroe.in.us/server/rest/services/MoCo_Council_Districts/FeatureServer/0/query' +
  '?where=1%3D1&outFields=OBJECTID,CountyCouncil,Council&outSR=4326&f=geojson';
// Use https.get() (built-in) or node-fetch — same pattern as load-us-congressional-boundaries.ts
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| All MCC district offices → county-wide geofence | Each MCC district → its own sub-district polygon | This phase | Kirkwood returns D4 only instead of D1-D4 |
| TIGER VTD aggregation for sub-county districts | Monroe County GIS FeatureServer directly | This phase | Authoritative source, no aggregation needed |

**Deprecated/outdated:**
- The §2a VALUES block entry for `Monroe County Council District 1/2/3/4` pointing to the
  county-wide COUNTY district: these 4 lines will be superseded by the new §2e block.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | All 4 MCC Council offices currently link to the shared `geo_id='18105'` COUNTY district (inferred from reading `link-monroe-county-races-to-geofences.sql` §2a) | Live DB Diagnosis | If some offices already have sub-district geo_ids, Wave 0 diagnostic will reveal it and the fix scope narrows |
| A2 | The `electionService.ts` join `AND (d.mtfcc IS NULL OR d.mtfcc = '' OR gb.mtfcc = d.mtfcc)` will accept `X-MCC-DISTRICT` | Schema Proposal | If there is a strict allowlist on mtfcc values in a DB constraint, import will fail; check with diagnostic query |
| A3 | No schema migration is required — the fix is data-only | Architecture | If `essentials.districts` has a CHECK constraint on `district_type` values that rejects 'COUNTY' for sub-county bodies, a migration would be needed; LOW risk given existing COUNTY usage |
| A4 | Monroe County GIS FeatureServer is publicly accessible without authentication | Data Source | County GIS servers sometimes require auth; confirmed accessible via WebFetch in this session but may rate-limit script runs [VERIFIED: accessible] |
| A5 | GAP-REPORT PATTERN-004 text "should be D1" was derived from Ballotpedia superset, not ground truth | Ground Truth Resolution | If another authoritative source contradicts D4, the documentation update direction reverses — LOW risk given two independent GIS sources agree on D4 |

---

## Open Questions (RESOLVED)

1. **Does the `electionService.ts` `districts → geofence` MTFCC join need an update?**
   - What we know: The join is `gb.mtfcc = d.mtfcc`, and line 574 in `essentialsService.ts`
     has explicit `X%` handling. The `electionService.ts` join at line 378 has a slightly
     different guard: `(d.mtfcc IS NULL OR d.mtfcc = '' OR gb.mtfcc = d.mtfcc)`.
   - What's unclear: Whether `electionService.ts` line 378 (used by elections-by-address)
     will correctly join `X-MCC-DISTRICT` districts — but it should, since `d.mtfcc =
     'X-MCC-DISTRICT'` and `gb.mtfcc = 'X-MCC-DISTRICT'` satisfies `gb.mtfcc = d.mtfcc`.
   - Recommendation: Verify with diagnostic query post-import; no code change likely needed.

2. **Should the import script also cover D2/D3 verification addresses?**
   - What we know: D-07 requires exclusivity for Kirkwood. Other districts are not in
     GEO-01/GEO-02 scope.
   - What's unclear: Whether it's worth a 30-minute effort to find representative addresses
     for D1/D2/D3 and add them to `audit-112-geofence.ts`.
   - Recommendation: At planner's discretion. The minimum viable verification is Kirkwood = D4
     exactly. Adding D1/D2/D3 addresses increases confidence but is not required for success
     criteria.

3. **Where does the repair SQL live — new migration, one-off script, or edit to existing SQL?**
   - What we know: All three options are valid. The import script needs DB access anyway; the
     re-link SQL could be appended to the import script or kept separate.
   - Recommendation: Two files — (1) `import-mcc-district-polygons.ts` handles polygon import
     and creates per-district offices; (2) update `link-monroe-county-races-to-geofences.sql`
     to reflect the correct idempotent wiring for future re-runs (so a fresh DB can be seeded
     correctly from scratch without needing to re-run the import script separately).

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Monroe County GIS FeatureServer | Polygon import | ✓ | Current (verified 2026-04-16) | Indiana statewide FeatureServer (layer 4) — only has 3/4 districts, use as emergency backup only |
| `pg` (node-postgres) | Import script | ✓ | In package.json | — |
| `DATABASE_URL` | Import script | ✓ (local .env) | — | — |
| PostGIS `ST_GeomFromGeoJSON` | Insert geometry | ✓ (Supabase includes PostGIS) | PostGIS 3.x | — |
| Supabase dev DB | Wave 0 diagnostics | ✓ | EV-Backend-Dev | — |

**Missing dependencies with no fallback:** None.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Vitest 2.1.0 |
| Config file | `ev-accounts/backend/vitest.config.ts` (includes `../tests/**/*.{test,spec}.{ts,js}`) |
| Quick run command | `cd ev-accounts && npm test` |
| Full suite command | `cd ev-accounts && npm test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| GEO-01 | Kirkwood address returns exactly 1 MCC Council race (D4 only) | smoke/integration | `cd ev-accounts/backend && npx tsx scripts/audit-112-geofence.ts` | ✅ (extend existing) |
| GEO-02 | Geofence smoke test validates Kirkwood canonical address | smoke | `cd ev-accounts/backend && npx tsx scripts/audit-112-geofence.ts` | ✅ (extend existing) |

**Note:** The `audit-112-geofence.ts` smoke test script is the primary validation harness. It
is NOT a Vitest test (no `.test.ts`) — it is a standalone script that runs PostGIS queries
directly. The existing CI-safe Vitest integration test (`essentials-elections.test.ts`) only
validates route wiring, not live geofence data. GEO-01 and GEO-02 require live-DB smoke test
verification (as established in Phase 118/119 precedent).

### Sampling Rate

- **Per task commit:** `cd ev-accounts/backend && npx tsx scripts/audit-112-geofence.ts --dry-run`
  (verifies script runs and reports addresses without hitting DB — 0 external deps)
- **Post-import wave:** `cd ev-accounts/backend && npx tsx scripts/audit-112-geofence.ts`
  (full run against dev DB — requires `DATABASE_URL`)
- **Phase gate:** Live smoke test green on DEV DB, then verify on production (api.empowered.vote)
  after Render deploy per D-06.

### Wave 0 Gaps

- [ ] Extend `scripts/audit-112-geofence.ts` with MCC exclusivity assertion (add
  `councilRaces.length === 1` check for Bloomington City Center address)
- [ ] Run diagnostic SQL against dev DB to confirm current state before any writes
  (documents live-DB reality vs code-read inference)

---

## Security Domain

> Phase is data-only (no new API endpoints, no authentication changes). Only V5 (Input
> Validation) applies minimally.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | minimal | GeoJSON geometry from ArcGIS FeatureServer is trusted source; `ST_Force2D` strips Z coordinates to prevent malformed geometry |
| V6 Cryptography | no | — |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed GeoJSON polygon causing PostGIS exception | Tampering | `ST_Force2D(ST_GeomFromGeoJSON(...))` will throw on invalid GeoJSON; wrap in try/catch per existing pattern |

---

## Sources

### Primary (HIGH confidence)

- Monroe County GIS FeatureServer `gis.co.monroe.in.us/server/rest/services/MoCo_Council_Districts/FeatureServer/0` — confirmed all 4 district polygons, confirmed Kirkwood = Council 4 via spatial query [VERIFIED: gis.co.monroe.in.us]
- Indiana Admin Boundaries FeatureServer `gisdata.in.gov/server/rest/services/Hosted/Administrative_Boundaries_of_Indiana_2024/FeatureServer/4` — confirmed Kirkwood = Council 4 independently [VERIFIED: gisdata.in.gov]
- `ev-accounts/backend/scripts/link-monroe-county-races-to-geofences.sql` — root cause surface area confirmed via code read [VERIFIED: codebase grep]
- `ev-accounts/backend/src/lib/essentialsService.ts` lines 563-594 — MTFCC join logic confirmed, `X%` pattern at line 574 [VERIFIED: codebase read]
- `ev-accounts/backend/src/lib/electionService.ts` lines 341-386 — `geofence_boundaries → districts → offices → races` join chain confirmed [VERIFIED: codebase read]
- `ev-accounts/backend/scripts/load-ca-state-boundaries.ts` lines 172-196 — PostGIS insert pattern confirmed [VERIFIED: codebase read]
- `ev-accounts/backend/scripts/audit-112-geofence.ts` lines 74-79 — Kirkwood pre-geocoded coordinates confirmed [VERIFIED: codebase read]

### Secondary (MEDIUM confidence)

- Bloomington ArcGIS MapServer `bloomington.in.gov/arcgis-server/rest/services/DataPortal/DataPortal_PoliticalBoundaries/MapServer` — confirmed city has City Council Districts layer but NOT county council districts layer [VERIFIED: WebFetch]
- Chamberbloomington.org Monroe County Council Candidates 2024 — confirmed council district reps (Crossley=D4, Iversen=D1, Wiltz=D2, Hawk=D3) [CITED: chamberbloomington.org]

### Tertiary (LOW confidence)

- GAP-REPORT PATTERN-004 text "should be D1" — assessed as incorrectly framed based on Ballotpedia superset; contradicted by two authoritative GIS sources [ASSUMED incorrect — now overridden by VERIFIED GIS data]

---

## Metadata

**Confidence breakdown:**
- Ground truth (D4 correct): HIGH — two independent authoritative GIS sources agree
- Polygon source URL: HIGH — confirmed accessible, returns 4 features in correct SRS
- Root cause (all 4 offices → single county geofence): HIGH — confirmed by reading link SQL
- Fix approach (structural import): HIGH — matches established codebase patterns exactly
- MTFCC choice (`X-MCC-DISTRICT`): MEDIUM — based on `X%` pattern in essentialsService.ts; needs live-DB validation

**Research date:** 2026-04-16
**Valid until:** 2026-06-01 (polygon boundaries are post-redistricting; the 2020 redistricting data is stable through at least 2030)
