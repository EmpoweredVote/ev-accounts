# Phase 32: Schema Fixes and Lookup Bug Correction - Research

**Researched:** 2026-02-23
**Domain:** PostgreSQL schema constraints, PostGIS spatial predicates, Go geofence lookup
**Confidence:** HIGH

## Summary

Phase 32 makes three targeted fixes to the geofence infrastructure before any LA County import work begins. All three changes are surgical: one SQL DDL statement for the schema constraint, one keyword swap in a Go SQL query, and a handful of map entries in a Go file. No new dependencies, no structural changes, no data migration.

The critical driver is SCHEMA-01: without a composite unique constraint on `(geo_id, mtfcc)`, running the same import script twice — or importing two different layer types that happen to share a `geo_id` — silently creates duplicate rows. PostgreSQL's `ON CONFLICT DO NOTHING` / `ON CONFLICT DO UPDATE` patterns require a named unique constraint to target, and `to_postgis(..., if_exists='append')` in geopandas has no dedup at all without one. The constraint must exist before Phases 34-35 import multiple MTFCC layers.

SCHEMA-02 (ST_Contains → ST_Covers) and SCHEMA-03 (missing MTFCC map entries) are correctness bugs that will cause silent failures for addresses on boundary edges and for city/school boundaries after Phases 34-35. Neither requires database schema changes — both are Go source edits with immediate effect on deploy.

**Primary recommendation:** Apply the migration SQL first (SCHEMA-01), then edit the Go file for SCHEMA-02 and SCHEMA-03 in a single commit. The migration runs idempotently on server start via `setup.go`. No data needs to be re-imported.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SCHEMA-01 | `geofence_boundaries` has a composite unique constraint on `(geo_id, mtfcc)` | PostgreSQL `CREATE UNIQUE INDEX IF NOT EXISTS` on `(geo_id, mtfcc)` added to `setup.go`; enables `ON CONFLICT` patterns in import scripts |
| SCHEMA-02 | Address lookup uses `ST_Covers` instead of `ST_Contains` for boundary matching | One keyword swap in `FindGeoIDsByPoint` SQL; ST_Covers returns TRUE for boundary-coincident points, ST_Contains returns FALSE |
| SCHEMA-03 | `mtfccToDistrictTypes` includes G4110, G4120, G5400, G5410 | G4110 already present; add G4120 (Consolidated City → LOCAL/LOCAL_EXEC) and G5400/G5410 (Elementary/Secondary School Districts → SCHOOL) |
</phase_requirements>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| PostgreSQL / PostGIS | 15+ / 3.x (Supabase) | Spatial database and point-in-polygon | Already in use; all geofence queries run against this |
| Go standard library | 1.24.3 | Source edits in `geofence_lookup.go` | No new dependencies needed |
| GORM | v2 | `db.DB.Exec()` for DDL migration in `setup.go` | Existing pattern — all constraints are created this way |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| geopandas | 1.x | Import scripts use `to_postgis()` | Phase 33+ import scripts benefit from the constraint this phase creates |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `CREATE UNIQUE INDEX` in `setup.go` | A raw SQL migration file | Both work; `setup.go` is the established pattern for all other indexes in this repo |
| `ST_Covers` | `ST_Intersects` | Intersects is broader (returns true for edge touches AND overlaps); Covers is the correct semantic for "point falls within or on border of district" |

## Architecture Patterns

### Recommended Project Structure

No structural changes. All three fixes live in existing files:

```
EV-Backend/
├── internal/essentials/
│   ├── setup.go           # Add SCHEMA-01: CREATE UNIQUE INDEX on (geo_id, mtfcc)
│   └── geofence_lookup.go # SCHEMA-02: ST_Contains → ST_Covers
│                          # SCHEMA-03: add G4120, G5400, G5410 to mtfccToDistrictTypes
```

### Pattern 1: Idempotent Index Creation in setup.go

**What:** All constraint/index DDL in this repo is added to `Init()` using `CREATE INDEX IF NOT EXISTS` so it applies on first deploy and is a no-op on all subsequent restarts.

**When to use:** Any time a new database constraint is needed that GORM AutoMigrate cannot express (composite unique indexes on specific columns).

**Example (existing pattern in setup.go):**
```go
// Create spatial index on geofence_boundaries geometry column
if err := db.DB.Exec(`
    CREATE INDEX IF NOT EXISTS idx_geofence_boundaries_geometry
    ON essentials.geofence_boundaries USING GIST (geometry);
`).Error; err != nil {
    log.Fatal("Failed to create spatial index:", err)
}
```

**New addition follows the same pattern:**
```go
// Composite unique constraint: prevents duplicate rows when importing
// multiple MTFCC layer types that share the same geo_id value.
// Required for ON CONFLICT idempotency in import scripts.
if err := db.DB.Exec(`
    CREATE UNIQUE INDEX IF NOT EXISTS idx_geofence_boundaries_geo_id_mtfcc
    ON essentials.geofence_boundaries (geo_id, mtfcc);
`).Error; err != nil {
    log.Fatal("Failed to create geofence_boundaries unique index:", err)
}
```

### Pattern 2: ST_Covers for Point-in-Polygon

**What:** Replace `ST_Contains` with `ST_Covers` in the geofence lookup query. The semantics differ only for boundary-coincident points: ST_Contains returns FALSE, ST_Covers returns TRUE.

**When to use:** Whenever the intent is "does this district include an address at exactly this coordinate" — which must be TRUE for addresses on boundary lines (street addresses on a district edge are valid residents).

**Current code (line 40 of geofence_lookup.go):**
```go
query := `
    SELECT geo_id, COALESCE(mtfcc, '') as mtfcc
    FROM essentials.geofence_boundaries
    WHERE ST_Contains(
        geometry,
        ST_SetSRID(ST_MakePoint($1, $2), 4326)
    )
`
```

**Fixed code:**
```go
query := `
    SELECT geo_id, COALESCE(mtfcc, '') as mtfcc
    FROM essentials.geofence_boundaries
    WHERE ST_Covers(
        geometry,
        ST_SetSRID(ST_MakePoint($1, $2), 4326)
    )
`
```

Note: argument order is unchanged — `ST_Covers(geometry_A, point_B)` means "A covers B", same as `ST_Contains(A, B)`.

### Pattern 3: mtfccToDistrictTypes Map Entries

**What:** The map governs which BallotReady district types are allowed to match for a given MTFCC code. Missing entries fall through to the `else` branch (line 96), which matches any district type — potentially causing cross-type contamination.

**Current map (geofence_lookup.go lines 22-31):**
```go
var mtfccToDistrictTypes = map[string][]string{
    "G5210": {"STATE_UPPER"},
    "G5220": {"STATE_LOWER"},
    "G5200": {"NATIONAL_LOWER"},
    "G4020": {"COUNTY", "JUDICIAL"},
    "G4040": {"LOCAL", "LOCAL_EXEC"},
    "G4110": {"LOCAL", "LOCAL_EXEC"},   // Incorporated Place — ALREADY PRESENT
    "G5420": {"SCHOOL"},
    "X0001": {"LOCAL"},
}
```

**What is missing:**
- `G4120` — Consolidated City (e.g. Nashville-Davidson Metro): should map to `{"LOCAL", "LOCAL_EXEC"}` same as G4110
- `G5400` — Elementary School District: should map to `{"SCHOOL"}`
- `G5410` — Secondary School District: should map to `{"SCHOOL"}`

**Note on G4110:** The requirement description says "includes G4110, G4120, G5400, G5410" but G4110 is already in the map. The actual gap is G4120, G5400, and G5410 only.

**Fixed map:**
```go
var mtfccToDistrictTypes = map[string][]string{
    "G5210": {"STATE_UPPER"},
    "G5220": {"STATE_LOWER"},
    "G5200": {"NATIONAL_LOWER"},
    "G4020": {"COUNTY", "JUDICIAL"},
    "G4040": {"LOCAL", "LOCAL_EXEC"},
    "G4110": {"LOCAL", "LOCAL_EXEC"},   // Incorporated Place (city/town)
    "G4120": {"LOCAL", "LOCAL_EXEC"},   // Consolidated City (e.g. Nashville-Davidson)
    "G5400": {"SCHOOL"},                // Elementary School District
    "G5410": {"SCHOOL"},                // Secondary School District
    "G5420": {"SCHOOL"},                // Unified School District
    "X0001": {"LOCAL"},
}
```

### Anti-Patterns to Avoid

- **Adding the unique constraint via GORM model tags:** GORM's `uniqueIndex` tag creates a single-column unique index. A composite `(geo_id, mtfcc)` unique index cannot be expressed cleanly in GORM struct tags — use raw `db.DB.Exec()` in `Init()` as already done for the spatial index.
- **Adding `GeofenceBoundary{}` back to AutoMigrate:** The comment in `setup.go` line 57 explicitly excludes it (`// Table already exists, managed manually to avoid GORM constraint issues`). Do not re-add it — GORM AutoMigrate will not create composite indexes and may generate conflicting DDL.
- **Using `ST_Within` instead of `ST_Covers`:** ST_Within(B, A) is the converse of ST_Contains(A, B) — both have the same boundary-point quirk. ST_Covers is the correct fix.
- **Omitting the `IF NOT EXISTS` clause:** Without it, the index creation statement will fail on restart if the index already exists, causing `log.Fatal` and crashing the server.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Deduplication in import scripts | Custom SELECT-then-INSERT logic | Composite unique index + `ON CONFLICT` in SQL | Database enforces it atomically; app-level dedup has TOCTOU race conditions |
| Boundary-coincident point detection | Manual coordinate buffer or tolerance | `ST_Covers` | PostGIS handles floating-point geometry edge cases correctly; manual buffering creates false positives |

**Key insight:** All three fixes are database/configuration concerns, not application logic. The correct tools are SQL DDL and PostGIS built-in predicates.

## Common Pitfalls

### Pitfall 1: Duplicate Rows Already in the Table

**What goes wrong:** If the `geofence_boundaries` table already has duplicate `(geo_id, mtfcc)` pairs (e.g., from running an import script twice), `CREATE UNIQUE INDEX` will fail with a uniqueness violation.

**Why it happens:** Import scripts using `to_postgis(..., if_exists='append')` have no dedup. Existing rows may already have duplicates.

**How to avoid:** Before adding the unique index, check for and delete duplicates:
```sql
-- Check for existing duplicates
SELECT geo_id, mtfcc, COUNT(*)
FROM essentials.geofence_boundaries
GROUP BY geo_id, mtfcc
HAVING COUNT(*) > 1;

-- Delete duplicates, keeping one row per (geo_id, mtfcc) pair
DELETE FROM essentials.geofence_boundaries
WHERE id NOT IN (
    SELECT DISTINCT ON (geo_id, mtfcc) id
    FROM essentials.geofence_boundaries
    ORDER BY geo_id, mtfcc, imported_at DESC
);
```

**Warning signs:** `CREATE UNIQUE INDEX` returns an error about "could not create unique index" — this means duplicates exist.

**Implementation note:** The dedup query should run in `setup.go` before the `CREATE UNIQUE INDEX` statement, or should be a one-time manual SQL operation against the database. The `setup.go` approach is safest for automated deploys.

### Pitfall 2: Argument Order in ST_Covers

**What goes wrong:** Swapping to `ST_Covers(point, geometry)` instead of `ST_Covers(geometry, point)` inverts the predicate — asks "does the point cover the polygon" which is never true.

**Why it happens:** ST_Contains and ST_Covers have the same argument order: `ST_Contains(A, B)` = "A contains B", `ST_Covers(A, B)` = "A covers B". The swap is just the function name, not the argument positions.

**How to avoid:** Keep the arguments identical: `ST_Covers(geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))` — same as the current `ST_Contains` call.

**Warning signs:** All point-in-polygon queries return zero results — entire geofence matching broken.

### Pitfall 3: G5400 / G5410 Assignment to SCHOOL

**What goes wrong:** If G5400 (Elementary) and G5410 (Secondary) are not in the map and the database contains rows with those MTFCC values, they fall through to the `else` branch in `FindPoliticiansByGeoMatches` which matches any district type — potentially returning school board members for the wrong address.

**Why it happens:** The requirement says LA County imports will include only UNSD (G5420). However, the TIGER shapefiles for CA PLACE data do include G5400/G5410 rows in some counties. Future imports (Phase 34) specifically exclude them (per STATE.md constraint: "Import UNSD (G5420) only"), but the map should be correct anyway.

**How to avoid:** Add G5400/G5410 → SCHOOL mapping now. The fix is benign even if those rows never exist in the database.

### Pitfall 4: Existing geofence_boundaries Table Out of Sync with GORM

**What goes wrong:** `GeofenceBoundary` model is excluded from AutoMigrate. If the `setup.go` index creation is the only DDL managing the table, and the unique index is added mid-development, servers that never ran the new `Init()` code won't have the constraint.

**Why it happens:** The table was created via `to_postgis()` in Python scripts, not via GORM AutoMigrate. The Go code assumes the table exists.

**How to avoid:** The `CREATE UNIQUE INDEX IF NOT EXISTS` statement in `setup.go` runs on every server start — so the constraint is applied automatically when the updated code deploys. No manual migration step needed after the code is merged.

## Code Examples

Verified patterns from codebase inspection:

### Current State of setup.go — Index Creation Pattern

```go
// Source: EV-Backend/internal/essentials/setup.go lines 62-66
if err := db.DB.Exec(`
    CREATE INDEX IF NOT EXISTS idx_geofence_boundaries_geometry
    ON essentials.geofence_boundaries USING GIST (geometry);
`).Error; err != nil {
    log.Fatal("Failed to create spatial index:", err)
}
```

### SCHEMA-01: Add After Spatial Index Block

```go
// Composite unique constraint to prevent duplicate rows across MTFCC layers.
// Without this, running the same import twice creates silent duplicates.
// Also required for ON CONFLICT targeting in import scripts.
if err := db.DB.Exec(`
    CREATE UNIQUE INDEX IF NOT EXISTS idx_geofence_boundaries_geo_id_mtfcc
    ON essentials.geofence_boundaries (geo_id, mtfcc);
`).Error; err != nil {
    log.Fatal("Failed to create geofence_boundaries unique constraint:", err)
}
```

### Dedup Guard Before Index Creation (if duplicates may exist)

```go
// Remove duplicate (geo_id, mtfcc) rows, keeping the most recently imported one.
// Required before CREATE UNIQUE INDEX if import scripts have run without the constraint.
if err := db.DB.Exec(`
    DELETE FROM essentials.geofence_boundaries
    WHERE id NOT IN (
        SELECT DISTINCT ON (geo_id, mtfcc) id
        FROM essentials.geofence_boundaries
        ORDER BY geo_id, mtfcc, imported_at DESC
    )
`).Error; err != nil {
    log.Printf("[essentials] WARNING: Dedup cleanup failed: %v", err)
}
```

### SCHEMA-02: ST_Covers in FindGeoIDsByPoint

```go
// Source: EV-Backend/internal/essentials/geofence_lookup.go line 37-44 (modified)
query := `
    SELECT geo_id, COALESCE(mtfcc, '') as mtfcc
    FROM essentials.geofence_boundaries
    WHERE ST_Covers(
        geometry,
        ST_SetSRID(ST_MakePoint($1, $2), 4326)
    )
`
```

### SCHEMA-03: Complete mtfccToDistrictTypes Map

```go
// Source: EV-Backend/internal/essentials/geofence_lookup.go lines 22-31 (modified)
var mtfccToDistrictTypes = map[string][]string{
    "G5210": {"STATE_UPPER"},                  // State Legislative District (Upper/Senate)
    "G5220": {"STATE_LOWER"},                  // State Legislative District (Lower/House)
    "G5200": {"NATIONAL_LOWER"},               // Congressional District
    "G4020": {"COUNTY", "JUDICIAL"},           // County — also county-level judicial
    "G4040": {"LOCAL", "LOCAL_EXEC"},          // County Subdivision (township)
    "G4110": {"LOCAL", "LOCAL_EXEC"},          // Incorporated Place (city/town)
    "G4120": {"LOCAL", "LOCAL_EXEC"},          // Consolidated City (e.g. Nashville-Davidson)
    "G5400": {"SCHOOL"},                       // Elementary School District
    "G5410": {"SCHOOL"},                       // Secondary School District
    "G5420": {"SCHOOL"},                       // Unified School District
    "X0001": {"LOCAL"},                        // City council sub-districts (BallotReady custom)
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `geo_id` only unique | `(geo_id, mtfcc)` composite unique | Phase 32 | Enables multi-layer imports without silent duplicates |
| `ST_Contains` | `ST_Covers` | Phase 32 | Addresses on boundary lines now match correctly |
| Missing G4120/G5400/G5410 entries | All relevant MTFCC codes mapped | Phase 32 | Correct district type filtering after Phase 34 imports |

## Open Questions

1. **Are there existing duplicate (geo_id, mtfcc) rows in the current database?**
   - What we know: Import scripts ran without a unique constraint; some scripts (like `import_shapefiles_fixed.py`) use plain `to_postgis(..., if_exists='append')` with no dedup
   - What's unclear: Whether any MTFCC layer was imported twice in practice
   - Recommendation: The plan should include a dedup step before the unique index creation — either as a `db.DB.Exec()` in `setup.go` before the `CREATE UNIQUE INDEX` call, or as a manual SQL step documented in the plan. Query the DB first to check.

2. **Does the `imported_at` column reliably have a non-NULL value for all rows?**
   - What we know: All import scripts set `imported_at = datetime.now()`, but the column in `GeofenceBoundary` model is `string` type without a NOT NULL constraint
   - What's unclear: Whether any rows were inserted without `imported_at` (e.g., via early import scripts)
   - Recommendation: Use `id` for dedup ordering if `imported_at` may be null — or add a fallback: `ORDER BY geo_id, mtfcc, COALESCE(imported_at, '') DESC`

3. **Is G4120 (Consolidated City) present in any LA County TIGER data?**
   - What we know: G4120 is a valid MTFCC code in Census data; LA County has no consolidated city-county government
   - What's unclear: Whether the PLACE shapefile for CA includes any G4120 rows for LA County
   - Recommendation: Add the map entry regardless — it's a one-line fix and correct for completeness; no harm if no G4120 rows exist

## Sources

### Primary (HIGH confidence)

- Codebase inspection: `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/geofence_lookup.go` — confirmed current `ST_Contains` usage and exact map state
- Codebase inspection: `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/setup.go` — confirmed `CREATE INDEX IF NOT EXISTS` pattern and `GeofenceBoundary` excluded from AutoMigrate
- Codebase inspection: `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/geofence_models.go` — confirmed `GeofenceBoundary` model schema (no unique constraint tag)
- [PostGIS ST_Covers documentation](https://postgis.net/docs/ST_Covers.html) — confirmed: "Returns true if every point in Geometry B lies inside Geometry A" — includes boundary points
- [PostGIS ST_Contains documentation](https://postgis.net/docs/ST_Contains.html) — confirmed: "The interiors must have at least one common point" — boundary-coincident points return FALSE
- [Census TIGER MTFCC codes](https://www.census.gov/library/reference/code-lists/mt-feature-class-codes.html) — confirmed G4110 = Incorporated Place, G4120 = Consolidated City, G5400 = Elementary School District, G5410 = Secondary School District, G5420 = Unified School District

### Secondary (MEDIUM confidence)

- WebSearch verified with PostGIS official docs: ST_Covers is recommended over ST_Contains for "point falls within or on border" semantics — multiple sources agree

### Tertiary (LOW confidence)

- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already in use, verified in codebase
- Architecture: HIGH — existing patterns fully documented, changes are targeted line-level edits
- Pitfalls: HIGH — duplicate row risk confirmed by import script inspection (no dedup mechanism present before this phase)

**Research date:** 2026-02-23
**Valid until:** 2026-04-23 (stable domain — PostGIS/PostgreSQL APIs do not change)
