# Phase 121: County Council D1→D4 Geofence Repair - Pattern Map

**Mapped:** 2026-04-16
**Files analyzed:** 3 new/modified scripts
**Analogs found:** 3 / 3

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `ev-accounts/backend/scripts/import-mcc-district-polygons.ts` | utility/import | file-I/O + CRUD | `ev-accounts/backend/scripts/load-ca-state-boundaries.ts` | exact (same: fetch geometry → geofence_boundaries INSERT → districts INSERT) |
| `ev-accounts/backend/scripts/link-monroe-county-races-to-geofences.sql` | utility/migration | CRUD | self (edit existing) | self-analog |
| `ev-accounts/backend/scripts/audit-112-geofence.ts` | utility/smoke-test | request-response | self (extend existing) | self-analog |

---

## Pattern Assignments

### `ev-accounts/backend/scripts/import-mcc-district-polygons.ts` (NEW — utility/import, CRUD)

**Primary analog:** `ev-accounts/backend/scripts/load-ca-state-boundaries.ts`
**Secondary analog (HTTP fetch pattern):** `ev-accounts/backend/scripts/load-us-congressional-boundaries.ts`

---

#### Imports pattern (`load-ca-state-boundaries.ts` lines 28-32, `load-us-congressional-boundaries.ts` lines 19-26):

```typescript
import 'dotenv/config';
import * as https from 'https';
import { Pool } from 'pg';
```

Note: `load-ca-state-boundaries.ts` uses `import 'dotenv/config'` (ESM top-level). `audit-112-geofence.ts` uses `dotenv.config({ path: path.resolve(__dirname, '..', '.env') })` with `fileURLToPath` — use whichever matches the package.json `"type"` field. All other scripts in the `scripts/` directory use the `fileURLToPath` + explicit `.env` path form (see `audit-112-geofence.ts` lines 26-33).

**Recommended imports for `import-mcc-district-polygons.ts`** (copy from `audit-112-geofence.ts` lines 26-36):

```typescript
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import * as https from 'https';
import pg from 'pg';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const DRY_RUN = process.argv.includes('--dry-run');
```

---

#### ENV guard pattern (`load-ca-state-boundaries.ts` lines 92-95, `load-us-congressional-boundaries.ts` lines 64-67):

```typescript
if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}
```

---

#### DB pool with SSL (`load-ca-state-boundaries.ts` lines 98-102, `load-us-congressional-boundaries.ts` lines 72-75):

```typescript
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});
```

---

#### HTTP fetch pattern for ArcGIS REST FeatureServer (`load-us-congressional-boundaries.ts` lines 79-102):

```typescript
function downloadFile(url: string, dest: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(dest);
    https.get(url, (response) => {
      if (response.statusCode === 301 || response.statusCode === 302) {
        file.close();
        fs.unlinkSync(dest);
        return downloadFile(response.headers.location!, dest).then(resolve).catch(reject);
      }
      if (response.statusCode !== 200) {
        file.close();
        fs.unlinkSync(dest);
        return reject(new Error(`HTTP ${response.statusCode} for ${url}`));
      }
      response.pipe(file);
      file.on('finish', () => { file.close(); resolve(); });
    }).on('error', (err) => {
      if (fs.existsSync(dest)) fs.unlinkSync(dest);
      reject(err);
    });
  });
}
```

For `import-mcc-district-polygons.ts`, the FeatureServer returns GeoJSON directly (no file save needed). Use an in-memory buffer version:

```typescript
function fetchJson(url: string): Promise<unknown> {
  return new Promise((resolve, reject) => {
    https.get(url, (response) => {
      if (response.statusCode !== 200) {
        return reject(new Error(`HTTP ${response.statusCode} for ${url}`));
      }
      const chunks: Buffer[] = [];
      response.on('data', (chunk: Buffer) => chunks.push(chunk));
      response.on('end', () => {
        try {
          resolve(JSON.parse(Buffer.concat(chunks).toString('utf-8')));
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}
```

---

#### PostGIS insert pattern — `geofence_boundaries` (`load-ca-state-boundaries.ts` lines 175-185):

```typescript
const gbResult = await pool.query(`
  INSERT INTO essentials.geofence_boundaries
    (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
  VALUES (
    $1, $2, $3, $4, $5,
    public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($6)), 4326),
    'census_tiger_2024',
    now()
  )
  ON CONFLICT (geo_id, mtfcc) DO NOTHING
`, [geoid, ocdId, name, 'CA', def.mtfcc, geojson]);
```

For MCC districts, substitute:
- `$4` → `'IN'`
- `$5` → `'X-MCC-DISTRICT'`
- `'census_tiger_2024'` → `'monroe_county_gis'`
- `geojson` = `JSON.stringify(feature.geometry)` where `feature` is a GeoJSON Feature from the FeatureServer response

---

#### PostGIS insert pattern — `districts` (`load-ca-state-boundaries.ts` lines 187-195):

```typescript
const dResult = await pool.query(`
  INSERT INTO essentials.districts
    (geo_id, ocd_id, label, district_type, state, mtfcc)
  SELECT $1, $2, $3, $4, 'CA', $5
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE geo_id = $1 AND district_type = $4
  )
`, [geoid, ocdId, name, def.districtType, def.mtfcc]);
```

For MCC districts, substitute:
- `'CA'` → `'IN'`
- `$4` → `'COUNTY'`
- `$5` → `'X-MCC-DISTRICT'`
- Add `district_id` column: the existing `districts` schema (seen in `link-monroe-county-races-to-geofences.sql` line 29) uses `district_id` as a stable key — include it: `election-mcc-d{N}`

The `WHERE NOT EXISTS` guard must check both `geo_id` and `district_type` to be idempotent (same pattern as `load-ca-state-boundaries.ts` line 192).

---

#### Offices INSERT + races UPDATE pattern (`link-monroe-county-races-to-geofences.sql` lines 167-274):

The import script must also create per-district offices and re-link races. Copy the §2a and §3a patterns from the link SQL:

```sql
-- Create per-district office (one per MCC district)
INSERT INTO essentials.offices (district_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT d.id, NULL, 'Monroe County Council District N', 'IN', false, false
FROM essentials.districts d
WHERE d.district_id = 'election-mcc-dN'
AND NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.district_id = d.id AND o.title = 'Monroe County Council District N'
);

-- Re-link the race to the new per-district office
-- First: null out the old office_id (clears stale county-wide link)
UPDATE essentials.races r
SET office_id = NULL, updated_at = now()
FROM essentials.elections e
WHERE r.election_id = e.id
  AND e.name = '2026 Indiana Primary'
  AND r.position_name = 'Monroe County Council District N';

-- Then: set new per-district office_id
UPDATE essentials.races r
SET office_id = o.id, updated_at = now()
FROM essentials.offices o
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections e ON r.election_id = e.id
WHERE d.district_id = 'election-mcc-dN'
  AND o.title = r.position_name
  AND e.name = '2026 Indiana Primary';
```

The explicit `SET office_id = NULL` before re-linking is required to work around the `AND r.office_id IS NULL` guard used in §3a (see RESEARCH.md Pitfall 5).

---

#### Totals/summary pattern (`load-ca-state-boundaries.ts` lines 225-252):

```typescript
const totals = {
  inserted_boundary: 0,
  inserted_district: 0,
  already_exists: 0,
  errors: 0,
};

// ... after loop ...

console.log('\n=== Summary ===');
if (isDryRun) {
  console.log(`  Would insert: ${totals.inserted_boundary} boundaries`);
} else {
  console.log(`  Inserted (boundaries): ${totals.inserted_boundary}`);
  console.log(`  Inserted (districts):  ${totals.inserted_district}`);
  console.log(`  Already existed:       ${totals.already_exists}`);
}
console.log(`  Errors:                ${totals.errors}`);
```

---

#### Dry-run guard (`load-ca-state-boundaries.ts` lines 165-169, `audit-112-geofence.ts` lines 184-196):

```typescript
if (isDryRun) {
  console.log(`  [dry-run] Would insert geo_id=${geoId} — ${name}`);
  totals.inserted_boundary++;
  continue;
}
```

---

#### Main + error handler pattern (`load-ca-state-boundaries.ts` lines 255-260):

```typescript
main()
  .catch((err) => {
    console.error('[import-mcc-district-polygons] Fatal error:', err);
    process.exit(1);
  })
  .finally(() => void pool.end());
```

---

### `ev-accounts/backend/scripts/link-monroe-county-races-to-geofences.sql` (EDIT — §2a and new §2e block)

**Analog:** self — preserve all existing patterns exactly; only modify §2a and add §2e.

---

#### Existing §2a VALUES block to modify (lines 167-186):

```sql
-- 2a: County-wide offices (linked to COUNTY district)
INSERT INTO essentials.offices (district_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT d.id, NULL, v.title, 'IN', false, false
FROM essentials.districts d,
(VALUES
  ('Monroe County Commissioner District 1'),
  ('Monroe County Council District 1'),   -- REMOVE these 4 lines
  ('Monroe County Council District 2'),   -- REMOVE
  ('Monroe County Council District 3'),   -- REMOVE
  ('Monroe County Council District 4'),   -- REMOVE
  ('Monroe County Assessor'),
  ('Monroe County Clerk'),
  ('Monroe County Recorder'),
  ('Monroe County Sheriff'),
  ('Monroe County Prosecuting Attorney')
) AS v(title)
WHERE d.geo_id = '18105' AND d.district_type = 'COUNTY'
AND NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.district_id = d.id AND o.title = v.title
);
```

The 4 `Monroe County Council District N` entries must be removed from §2a and moved to a new §2e block that joins on per-district `district_id` values instead.

---

#### New §2e block pattern (copy structure from §2d, lines 245-257):

```sql
-- 2e: MCC per-district offices (linked to per-district COUNTY districts)
INSERT INTO essentials.offices (district_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT d.id, NULL, v.title, 'IN', false, false
FROM essentials.districts d
JOIN (VALUES
  ('Monroe County Council District 1', 'election-mcc-d1'),
  ('Monroe County Council District 2', 'election-mcc-d2'),
  ('Monroe County Council District 3', 'election-mcc-d3'),
  ('Monroe County Council District 4', 'election-mcc-d4')
) AS v(title, did) ON d.district_id = v.did
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.district_id = d.id AND o.title = v.title
);
```

This pattern is copied directly from §2c (lines 203-222) which uses the same `JOIN ... ON d.district_id = v.did` shape for township offices.

---

#### §3a re-link guard to be aware of (lines 267-274):

```sql
UPDATE essentials.races r
SET office_id = o.id, updated_at = now()
FROM essentials.offices o
JOIN essentials.districts d ON d.id = o.district_id
WHERE d.geo_id = '18105' AND d.district_type = 'COUNTY'
  AND o.title = r.position_name
  AND r.election_id = (SELECT election_id FROM election_ref)
  AND r.office_id IS NULL;   -- ← this guard skips already-linked races
```

After the import script nulls out the old county-wide links, this §3a block will NOT re-link the council races (they no longer match `d.geo_id = '18105' AND d.district_type = 'COUNTY'` for the per-district offices). A new §3e block (analogous to §3c/§3d at lines 287-305) is needed for MCC:

```sql
-- 3f: MCC per-district races → per-district offices
UPDATE essentials.races r
SET office_id = o.id, updated_at = now()
FROM essentials.offices o
JOIN essentials.districts d ON d.id = o.district_id
WHERE d.district_id LIKE 'election-mcc-d%'
  AND o.title = r.position_name
  AND r.election_id = (SELECT election_id FROM election_ref)
  AND r.office_id IS NULL;
```

---

#### Idempotency contract (enforced throughout the file):

All INSERTs use `WHERE NOT EXISTS` guards keyed on `district_id` (stable string key, not auto-generated PK). All UPDATEs use `AND r.office_id IS NULL` — which means the import script must clear stale office links before this SQL runs on a re-seed. The `BEGIN` / `COMMIT` transaction wraps the entire file (lines 17, 362).

---

### `ev-accounts/backend/scripts/audit-112-geofence.ts` (EDIT — extend Kirkwood assertion)

**Analog:** self — preserve entire file structure; add assertion after the existing per-address loop.

---

#### Existing test address block (lines 74-82) — Kirkwood is already at index 0:

```typescript
const TEST_ADDRESSES: TestAddress[] = [
  {
    label: 'Bloomington City Center',
    address: '200 W Kirkwood Ave, Bloomington IN 47404',
    lat: 39.166646,
    lng: -86.534947,
    expectedTownship: 'Bloomington',
    expectedStateDistrict: 'D-61',
  },
  // ... 5 more addresses
];
```

---

#### Existing per-address query (lines 205-219) — ST_Covers shape to preserve:

```typescript
const geofenceResult = await pool.query<GeofenceRow>(
  `
  SELECT r.position_name, r.primary_party, rc.full_name
  FROM essentials.elections e
  JOIN essentials.races r ON r.election_id = e.id
  LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.candidate_status = 'active'
  JOIN essentials.offices o ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
  WHERE e.election_date = '2026-05-05' AND e.state = 'IN'
    AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))
  ORDER BY r.position_name, r.primary_party
  `,
  [addr.lng, addr.lat],  // NOTE: longitude first in ST_MakePoint
);
```

---

#### MCC exclusivity assertion to insert (lines 240-241 region — after the per-address CSV output loop, before `console.error` progress line):

```typescript
// MCC exclusivity check for Kirkwood (GEO-01 / GEO-02 requirement)
if (addr.label === 'Bloomington City Center') {
  const councilRaces = rows.filter(r =>
    r.position_name?.startsWith('Monroe County Council District')
  );
  if (councilRaces.length !== 1) {
    console.error(
      `FAIL GEO-01: Expected exactly 1 MCC Council race for ${addr.label}, got ${councilRaces.length}`
    );
    if (councilRaces.length > 0) {
      console.error(`  Races: ${councilRaces.map(r => r.position_name).join(', ')}`);
    }
  } else {
    console.error(
      `PASS GEO-01: ${addr.label} → exactly 1 MCC Council race: ${councilRaces[0].position_name}`
    );
  }
}
```

Placement: insert after `process.stdout.write(line + '\n')` inner loop (line ~236) and before `console.error(\`Address ${i + 1}...\`)` (line 240). This preserves the existing CSV output structure and just adds stderr assertion messages.

---

#### Existing CSV output pattern to preserve (lines 222-238):

```typescript
if (rows.length === 0) {
  process.stdout.write(
    [escapeCsv(addr.label), 'NO_RACES_RESOLVED', '', ''].join(',') + '\n',
  );
} else {
  for (const row of rows) {
    const line = [
      escapeCsv(addr.label),
      escapeCsv(row.position_name),
      escapeCsv(row.primary_party),
      escapeCsv(row.full_name),
    ].join(',');
    process.stdout.write(line + '\n');
  }
}
```

Do not change the CSV structure. Assertion output goes to `stderr` only (matching existing `console.error` progress pattern at line 240).

---

## Shared Patterns

### PostGIS Geometry Insert
**Source:** `ev-accounts/backend/scripts/load-ca-state-boundaries.ts` lines 175-185
**Apply to:** `import-mcc-district-polygons.ts`

```typescript
public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($6)), 4326)
```

The `ST_Force2D` call strips Z coordinates (handles ArcGIS FeatureServer responses that include elevation). The `ST_SetSRID(..., 4326)` labels the geometry as WGS84 — this does NOT reproject; coordinates must already arrive as 4326 (enforced by `outSR=4326` in the FeatureServer URL).

### Idempotent Conflict Handling
**Source:** `ev-accounts/backend/scripts/load-ca-state-boundaries.ts` line 184, `link-monroe-county-races-to-geofences.sql` lines 31-37
**Apply to:** all INSERT statements in `import-mcc-district-polygons.ts` and the updated `link-monroe-county-races-to-geofences.sql`

For `geofence_boundaries`: `ON CONFLICT (geo_id, mtfcc) DO NOTHING`
For `districts`: `WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE geo_id = $1 AND district_type = $4)`
For `offices`: `AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.title = v.title)`

### MTFCC Join — `essentialsService.ts`
**Source:** `ev-accounts/backend/src/lib/essentialsService.ts` line 574
**Apply to:** MTFCC value selection for all 4 MCC geofence + district rows

```sql
OR (gb.mtfcc LIKE 'X%' AND d.district_type IN ('LOCAL', 'COUNTY'))
```

The custom MTFCC `X-MCC-DISTRICT` starts with `X` and pairs with `district_type = 'COUNTY'`, satisfying this condition. Both `geofence_boundaries.mtfcc` and `districts.mtfcc` must be exactly `'X-MCC-DISTRICT'` to satisfy the `electionService.ts` join at line 378: `AND (d.mtfcc IS NULL OR d.mtfcc = '' OR gb.mtfcc = d.mtfcc)`.

### ST_MakePoint Coordinate Order
**Source:** `ev-accounts/backend/scripts/audit-112-geofence.ts` line 218, `ev-accounts/backend/src/lib/electionService.ts` line 335
**Apply to:** any diagnostic SQL and the extended audit assertion

```typescript
ST_MakePoint($1, $2)  // $1 = longitude (x), $2 = latitude (y)
// For Kirkwood: ST_MakePoint(-86.534947, 39.166646)
```

### Dry-Run Flag Convention
**Source:** `ev-accounts/backend/scripts/load-ca-state-boundaries.ts` line 36, `ev-accounts/backend/scripts/audit-112-geofence.ts` line 36
**Apply to:** `import-mcc-district-polygons.ts`

```typescript
const DRY_RUN = process.argv.includes('--dry-run');
// or:
const isDryRun = process.argv.includes('--dry-run');
```

All scripts in `scripts/` use `--dry-run` (not `--dryRun` or `--dry_run`).

### Script File Header Comment
**Source:** `ev-accounts/backend/scripts/audit-112-geofence.ts` lines 1-24, `load-ca-state-boundaries.ts` lines 1-27
**Apply to:** `import-mcc-district-polygons.ts`

Every script begins with a JSDoc block documenting: purpose, data source URL, safe-to-re-run status, usage examples, and key references. Include the FeatureServer URL as a source comment.

---

## No Analog Found

None — all files have close analogs in the codebase.

---

## Metadata

**Analog search scope:** `ev-accounts/backend/scripts/`, `ev-accounts/backend/src/lib/`
**Files scanned:** `load-ca-state-boundaries.ts`, `load-us-congressional-boundaries.ts`, `audit-112-geofence.ts`, `link-monroe-county-races-to-geofences.sql`, `essentialsService.ts` (lines 560-595), `electionService.ts` (lines 335-386)
**Pattern extraction date:** 2026-04-16
