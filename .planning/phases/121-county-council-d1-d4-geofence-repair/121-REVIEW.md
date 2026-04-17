---
phase: 121-county-council-d1-d4-geofence-repair
reviewed: 2026-04-16T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - ev-accounts/backend/scripts/audit-112-geofence.ts
  - ev-accounts/backend/scripts/diagnose-121-mcc-state.ts
  - ev-accounts/backend/scripts/fetch-mcc-district-polygons.ts
  - ev-accounts/backend/scripts/import-mcc-district-polygons.ts
  - ev-accounts/backend/scripts/link-monroe-county-races-to-geofences.sql
findings:
  critical: 0
  warning: 4
  info: 4
  total: 8
status: issues_found
---

# Phase 121: Code Review Report

**Reviewed:** 2026-04-16
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

These five files implement a three-wave geofence repair for Monroe County Council district races: a read-only diagnostic, a GIS fetch script, an idempotent polygon importer, an audit smoke test, and the SQL wiring script. The overall architecture is solid — idempotency guards are present, pitfalls are explicitly documented, and error paths exit with clear messages.

No critical (security or crash-causing) issues were found. The warnings are correctness risks: an incomplete idempotency guard in the SQL script that could silently leave MCC council races wired to the wrong (county-wide) district after re-runs, a pool that is not closed on errors in `import-mcc-district-polygons.ts`, a non-atomic two-table insert loop that leaves the DB in a partially-imported state if interrupted, and an audit assertion that only fires for one of six test addresses. The info items cover dead variable assignment, a redirect loop risk, and minor code clarity notes.

## Warnings

### WR-01: SQL Step 2a links MCC Council district offices to the county-wide geo_id, not the per-district geo_ids

**File:** `ev-accounts/backend/scripts/link-monroe-county-races-to-geofences.sql:167-186`
**Issue:** Step 2a (`INSERT INTO essentials.offices`) creates all four "Monroe County Council District N" offices linked to the single county-wide district (`d.geo_id = '18105' AND d.district_type = 'COUNTY'`). This is the pre-existing bug this phase is meant to fix. However, `import-mcc-district-polygons.ts` (Wave 1) inserts four new per-district rows into `essentials.districts` with `geo_id = '18105-mcc-d{N}'`. The SQL script (Wave 2) does not have a corresponding `INSERT INTO essentials.offices` block that links each council seat to its per-district `districts.id`. Without that block the offices remain anchored to the county polygon, and the audit's GEO-01/GEO-02 assertion will still fail after Wave 2 runs. The `NOT EXISTS` guard on Step 2a means it also silently skips on re-run, so the missing per-district offices are never created.

**Fix:** Add a Step 2e block that inserts four office rows — one per MCC council district — linked to the per-district districts created by `import-mcc-district-polygons.ts`:
```sql
-- 2e: Per-district MCC Council offices (linked to per-district geofences from Wave 1)
INSERT INTO essentials.offices (district_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT d.id, NULL, 'Monroe County Council District ' || d.label[last char], 'IN', false, false
FROM essentials.districts d
WHERE d.district_id IN ('election-mcc-d1','election-mcc-d2','election-mcc-d3','election-mcc-d4')
AND NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.district_id = d.id
    AND o.title = 'Monroe County Council District ' || ...
);
```
Concretely, using the label stored in the district row:
```sql
INSERT INTO essentials.offices (district_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT d.id, NULL, d.label, 'IN', false, false
FROM essentials.districts d
WHERE d.district_id LIKE 'election-mcc-d%'
AND NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.district_id = d.id AND o.title = d.label
);
```
Then add a Step 3f block that updates the four MCC council races to link to these per-district offices (matching `o.title = r.position_name`), and remove "Monroe County Council District 1–4" from the Step 2a VALUES list so they are not re-created on the county-wide district.

---

### WR-02: Pool is not closed on errors in `import-mcc-district-polygons.ts` main function

**File:** `ev-accounts/backend/scripts/import-mcc-district-polygons.ts:313-315`
**Issue:** The top-level `.catch` handler calls `process.exit(1)` without first calling `pool.end()`. The pool is created inside `main()` (line 121) and is therefore not accessible from the module-level catch. This means any uncaught exception (e.g., a DB connection failure before `runChecks`) will leave open connections dangling. The pool is a local variable and is not closed via the catch path.

**Fix:** Hoist the pool declaration to module scope (before `main`) so the catch handler can close it:
```typescript
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });

async function main(): Promise<void> {
  // ... same body, pool already accessible ...
}

main().catch(async (err) => {
  console.error(`[121-import] Fatal error: ${(err as Error).message}`);
  await pool.end().catch(() => {});
  process.exit(1);
});
```

---

### WR-03: Per-district insert loop is non-atomic — partial imports leave DB in inconsistent state

**File:** `ev-accounts/backend/scripts/import-mcc-district-polygons.ts:184-237`
**Issue:** Each of the four districts is inserted sequentially inside a `try/catch` that increments `counters.errors` on failure but continues to the next district. If district 2 fails (e.g., constraint violation or transient DB error), districts 1, 3, and 4 may be committed while district 2 is absent. On re-run, the `ON CONFLICT DO NOTHING` and `WHERE NOT EXISTS` guards skip the already-inserted rows, so the partial state persists. The verification step at the end will report `final_boundary_count != 4` and set `exitCode = 2`, but the committed rows are not rolled back.

**Fix:** Wrap the entire loop in a transaction so all four inserts succeed or none do:
```typescript
const client = await pool.connect();
try {
  await client.query('BEGIN');
  for (const feature of features) {
    // ... same INSERT queries using client.query() instead of pool.query() ...
  }
  await client.query('COMMIT');
} catch (err) {
  await client.query('ROLLBACK');
  throw err;
} finally {
  client.release();
}
```

---

### WR-04: Kirkwood exclusivity assertion only fires for one address label — other addresses get no council-district check

**File:** `ev-accounts/backend/scripts/audit-112-geofence.ts:244-264`
**Issue:** The Phase 121 GEO-01/GEO-02 assertion (that exactly one MCC Council district race is returned) is gated on `addr.label === 'Bloomington City Center'`. The other five addresses, including IU Campus which is also in Bloomington and would likely match a council district, receive no similar assertion. If the geofence repair leaves an overlap (e.g., a point in D4 matches both D3 and D4), only the Kirkwood address would catch it. A point like IU Campus could still return multiple district races silently.

**Fix:** Apply the council-district exclusivity assertion to all six addresses, parametrizing the expected district label per address:
```typescript
// Add expectedCouncilDistrict to TestAddress interface, e.g. 'D4' | null
// Then after collecting rows for any address:
if (addr.expectedCouncilDistrict !== null) {
  const councilRaces = rows.filter((r) =>
    typeof r.position_name === 'string' &&
    r.position_name.startsWith('Monroe County Council District'),
  );
  if (councilRaces.length !== 1) {
    console.error(`[121-geo] FAIL: ${addr.label} expected 1 MCC Council race, got ${councilRaces.length}`);
    process.exitCode = 2;
  }
}
```

---

## Info

### IN-01: Dead assignment — `mtfccMatch` is always `true` and never read

**File:** `ev-accounts/backend/scripts/import-mcc-district-polygons.ts:241-242`
**Issue:** `const mtfccMatch = true;` is assigned and immediately logged but carries no runtime meaning — both INSERT statements always use the same `MTFCC` constant. If they were ever to diverge, this check would not catch it. The variable gives a false sense of verification.

**Fix:** Remove the variable and its log line. The comment "Pitfall 2" is already present above the constant declaration. If active verification is desired, assert at startup that the MTFCC constant is the same string used in both queries (but since they reference the same constant, this is trivially true and doesn't need a runtime check).

---

### IN-02: `fetchUrl` follows only one redirect — a second redirect silently returns a non-200 status

**File:** `ev-accounts/backend/scripts/fetch-mcc-district-polygons.ts:87-99`
**Issue:** `fetchUrl` recurses once for a 3xx response but does not track redirect depth. If the GIS server issues two consecutive redirects (uncommon for ArcGIS REST but possible during maintenance), the second redirect response is returned as-is with its 3xx status code. The caller then hits the `statusCode !== 200` guard and exits with code 2, which is the correct behavior, but the error message will say "HTTP 302" rather than explaining a redirect chain exceeded limit. This is a minor clarity issue rather than a crash risk.

**Fix:** Add a `redirectCount` parameter (default 0) and fail explicitly if exceeded:
```typescript
function fetchUrl(url: string, redirectCount = 0): Promise<HttpResponse> {
  if (redirectCount > 2) {
    return Promise.reject(new Error(`Too many redirects fetching ${url}`));
  }
  // ... existing body, pass redirectCount + 1 in recursive call ...
}
```

---

### IN-03: `geofence_boundaries` insert uses string interpolation for `SOURCE` constant inside SQL

**File:** `ev-accounts/backend/scripts/import-mcc-district-polygons.ts:194-200`
**Issue:** The SQL string uses `'${SOURCE}'` (template literal interpolation) to embed the source constant directly into the SQL text, while all other values use parameterized `$N` placeholders. `SOURCE` is a module-level constant set to `'monroe_county_gis'` and is not user-controlled, so there is no injection risk here. However, the pattern is inconsistent with the rest of the query and could be cargo-culted into a future query where the value is user-supplied.

**Fix:** Add `SOURCE` as a query parameter for consistency:
```typescript
const gbResult = await pool.query(
  `INSERT INTO essentials.geofence_boundaries
     (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
   VALUES ($1, $2, $3, $4, $5,
     public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($6)), 4326),
     $7, now())
   ON CONFLICT (geo_id, mtfcc) DO NOTHING`,
  [geoId, ocdId, name, STATE, MTFCC, geojsonStr, SOURCE],
);
```

---

### IN-04: `diagnose-121-mcc-state.ts` logs to `console.log` (stdout) for diagnostic tokens but `console.error` (stderr) for summary — mixing output streams

**File:** `ev-accounts/backend/scripts/diagnose-121-mcc-state.ts:131-133, 213-242`
**Issue:** The grep-able `[121-diag]` tokens (e.g., `boundaries_18105_count=N`) are written to stdout via `console.log`, while the human-readable summary block is also written to stdout. The CSV is written to a file. This means piping stdout to a grep filter works, but piping to a file would capture both the tokens and the summary block together. Other scripts in this codebase (audit-112, fetch, import) consistently use `console.error` for all progress/summary output and reserve stdout for machine-readable CSV data. This script is inconsistent with that convention.

**Fix:** Change all `console.log` calls in `diagnose-121-mcc-state.ts` to `console.error` so progress output goes to stderr and stdout is clean (or write the tokens to the CSV file alongside the tabular data).

---

_Reviewed: 2026-04-16_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
