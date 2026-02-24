# Pitfalls Research

**Domain:** TIGER shapefile import pipeline, LA County GIS integration, politician deduplication, PostGIS geofence scaling (civic tech)
**Researched:** 2026-02-23
**Confidence:** HIGH (PostGIS/geometry behaviors — verified against PostGIS docs + GDAL issues), HIGH (Supabase pooler limitation — verified against Supabase docs), HIGH (MTFCC gap — verified against Census docs + BallotReady support), MEDIUM (deduplication patterns — verified against OpenSanctions + Cicero articles), MEDIUM (LA County GIS rate limits — API observed, no official docs)

---

## Critical Pitfalls

### Pitfall 1: `ON CONFLICT (geo_id) DO NOTHING` Silently Drops Valid Boundaries When geo_id Is Not Unique Across MTFCC Types

**What goes wrong:**
The current import script uses `ON CONFLICT (geo_id) DO NOTHING` when moving rows from the staging table into `essentials.geofence_boundaries`. This assumes `geo_id` is globally unique across all district types. It is not. The same Census GEOID can appear in multiple TIGER shapefiles with different MTFCC codes — for example, a county GEOID (`06037`) appears in the county shapefile (G4020) and may also appear as a component of school district or place GEOIDs. More critically, G5400 (Elementary), G5410 (Secondary), and G5420 (Unified) school districts in LA County can produce rows with overlapping spatial coverage even when their geo_ids differ, but SLDU and SLDL districts for the same state leg district number often share the same geo_id prefix structure. When the first import run inserts `geo_id = '0606' + district_number` for State Senate, a second run importing State House districts with the same derived ID key silently drops the House district. The address search returns Senate matches but never House matches for those districts — and no error is thrown.

**Why it happens:**
The staging → production INSERT was designed for the first import run where geo_ids were assumed to be globally unique. As more district types are added (school districts, county subdivisions, places), the uniqueness assumption breaks. The `DO NOTHING` clause means failures are invisible — the row count in the summary query looks correct because it counts all rows in the table, not the rows that were actually inserted in this run.

**How to avoid:**
Change the unique constraint from `geo_id` alone to `(geo_id, mtfcc)` — this is the true unique key for geofence boundaries. Update the import script's conflict clause to match:
```sql
ON CONFLICT (geo_id, mtfcc) DO UPDATE SET
    geometry = EXCLUDED.geometry,
    name = EXCLUDED.name,
    source = EXCLUDED.source,
    imported_at = EXCLUDED.imported_at;
```
This also makes re-imports idempotent: re-running the script updates existing rows rather than silently skipping them. Add a post-import verification query that counts rows per MTFCC and compares against expected counts for the region:
```sql
SELECT mtfcc, COUNT(*) as count FROM essentials.geofence_boundaries
WHERE source = 'census_tiger_2024' GROUP BY mtfcc ORDER BY mtfcc;
```
Cross-reference against expected TIGER counts: CA has ~30 congressional districts, 40 state senate districts, 80 assembly districts, 80+ unified school districts in LA County alone.

**Warning signs:**
- Post-import count per MTFCC shows 0 for a layer you just imported (e.g., `G5210` shows 0 rows after running the state senate import)
- Address lookups in a specific region consistently return Federal + State senators but never State Assembly members
- Running the import script twice produces different row count totals in the summary
- `SELECT COUNT(*) FROM staging` is greater than `SELECT COUNT(*) FROM final WHERE source = 'census_tiger_2024'` — the difference is silently dropped rows

**Phase to address:**
Shapefile pipeline design phase — before importing a single layer for LA County. Fix the unique constraint before the first multi-MTFCC import. This is a schema change, not just a script fix.

---

### Pitfall 2: Invalid Geometries in TIGER Shapefiles Fail Silently with ogr2ogr — No Error, No Row

**What goes wrong:**
TIGER shapefiles occasionally contain geometries that fail PostGIS's validity checks: self-intersecting rings, zero-area slivers, or ring touches that violate OGC geometry rules. When ogr2ogr encounters a geometry that cannot be stored in the PostGIS column constraint, it skips the row and continues — unless you run with `-skipfailures` explicitly, in which case it always skips. Either way, the import appears to succeed but some districts are missing. For coastal congressional districts in California (which have complex coastline polygons with many vertices), invalid geometry failures are especially common. The Bloomington import already used `ST_MakeValid` to patch this for the city council data — LA County will need the same treatment at scale.

**Why it happens:**
TIGER geometric data is generated for cartographic accuracy, not topological validity. Coastal boundaries trace irregular shorelines with thousands of vertices that sometimes produce self-intersections when simplified. The `import_shapefiles.sh` script does not pass `--makevalid` or use `ST_MakeValid` in the post-processing SQL. It also does not validate row counts before and after import.

**How to avoid:**
Add `-makevalid` to every `ogr2ogr` call as a baseline safeguard:
```bash
ogr2ogr -f PostgreSQL "PG:$DB_CONNECTION" "$shp_file" \
    -nln essentials.geofence_boundaries_staging \
    -append \
    -t_srs EPSG:4326 \
    -makevalid \
    ...
```
Note: ogr2ogr's `-makevalid` can produce `GeometryCollection` types when a repair results in mixed geometry types (known GDAL issue #6340, fixed in GDAL 3.5+). Verify your GDAL version with `ogr2ogr --version`. If you are on GDAL < 3.5, apply `ST_MakeValid` in the post-processing SQL instead and use `ST_CollectionExtract` to extract only polygon geometries:
```sql
INSERT INTO essentials.geofence_boundaries (geo_id, mtfcc, name, geometry, source, imported_at)
SELECT
    geo_id, mtfcc, name,
    ST_Multi(ST_CollectionExtract(ST_MakeValid(geometry), 3)) as geometry,
    'census_tiger_2024',
    NOW()
FROM essentials.geofence_boundaries_staging
WHERE ST_GeometryType(ST_MakeValid(geometry)) NOT IN ('GEOMETRYCOLLECTION', 'POINT', 'LINESTRING')
   OR ST_GeometryType(ST_MakeValid(ST_CollectionExtract(geometry, 3))) IS NOT NULL
ON CONFLICT (geo_id, mtfcc) DO UPDATE SET geometry = EXCLUDED.geometry;
```
Run a pre-insert validity check to quantify the problem before fixing it:
```sql
SELECT COUNT(*) as invalid_count, mtfcc
FROM essentials.geofence_boundaries_staging
WHERE NOT ST_IsValid(geometry)
GROUP BY mtfcc;
```

**Warning signs:**
- `SELECT COUNT(*) FROM essentials.geofence_boundaries_staging` differs from `SELECT COUNT(*) FROM essentials.geofence_boundaries WHERE source = 'census_tiger_2024'` — the gap is missing rows due to import failures
- ogr2ogr output shows `Features without geometry skipped: N` where N > 0
- Congressional districts in the import cover all of California but a specific coastal district (e.g., CA-36 or CA-47) never returns results for any address
- `ST_IsValid(geometry)` returns false for some rows: `SELECT geo_id, ST_IsValidReason(geometry) FROM essentials.geofence_boundaries WHERE NOT ST_IsValid(geometry)`

**Phase to address:**
Shapefile import execution phase — before moving data from staging to production. The pre-insert validity check must run before the final `INSERT ... ON CONFLICT` statement. Never promote staging data to production without verifying zero invalid geometries.

---

### Pitfall 3: Supabase Pooler (Port 6543) Breaks ogr2ogr and psql COPY — Use Direct Connection for All Imports

**What goes wrong:**
The Supabase connection string available from the dashboard defaults to the Supavisor connection pooler on port 6543, which runs in transaction mode. ogr2ogr, shp2pgsql-piped-to-psql, and multi-statement psql scripts all fail or behave incorrectly through the pooler because:
1. Transaction-mode poolers do not support prepared statements, which ogr2ogr uses internally
2. The pooler may route different statements in a multi-statement transaction to different backend connections, breaking transactional guarantees
3. Long-running bulk inserts (thousands of rows from a national TIGER file) time out at the pooler's connection limit before completing

The import appears to run but silently commits partial data, leaving the table in an inconsistent mid-import state with no error returned to the shell script.

**Why it happens:**
Developers copy the connection string from the Supabase dashboard "Connection String" tab, which presents the pooler URL by default. The direct connection URL requires explicitly selecting "Direct connection" in the dashboard. The error message from ogr2ogr is not always clear that prepared statements are the cause — it may fail with a generic "connection error" or "server closed the connection unexpectedly" after partial import.

**How to avoid:**
Always use the direct connection URL (port 5432) for all shapefile imports, psql scripts, and any bulk data operation. From the Supabase dashboard: Project Settings > Database > Connection string — switch to the "Direct connection" tab, not "Connection pooling". Verify the port in your `DATABASE_URL`:
```bash
# Correct for imports (direct connection)
DATABASE_URL=postgresql://postgres:PASSWORD@db.PROJECTID.supabase.co:5432/postgres

# Wrong for imports (pooler — will fail for ogr2ogr)
DATABASE_URL=postgresql://postgres.PROJECTID:PASSWORD@aws-0-REGION.pooler.supabase.com:6543/postgres
```
Add a connection validation step at the start of every import script:
```bash
psql "$DATABASE_URL" -c "SELECT 1" || { echo "ERROR: Cannot connect to database"; exit 1; }
```

**Warning signs:**
- ogr2ogr exits with "ERROR 1: Error executing: PQexec() -- server closed the connection unexpectedly"
- `psql "$DATABASE_URL" -c "\d essentials.geofence_boundaries"` returns `prepared statement "..." does not exist`
- Import appears to complete but row counts are lower than expected
- DATABASE_URL in `.env` or CI script contains port 6543 or the `pooler.supabase.com` hostname

**Phase to address:**
Import tooling setup phase — verify the connection string before writing a single line of import logic. The direct connection URL must be documented in the project's import runbook and enforced by the import script's preflight checks.

---

### Pitfall 4: MTFCC Mapping Table Is Incomplete — Unknown Codes Return All District Types and Match Wrong Politicians

**What goes wrong:**
The `mtfccToDistrictTypes` map in `geofence_lookup.go` currently handles 8 MTFCC codes. LA County imports will introduce codes not yet in the map. When `FindPoliticiansByGeoMatches` encounters an unknown MTFCC, it falls through to the else branch: `d.geo_id = $N` with no district type filter. This means any politician in any district that shares that geo_id — regardless of district type — gets returned. A user in an unincorporated LA County area might receive city council members from an adjacent incorporated city as if they represent them, simply because the geo_id is present in the districts table.

Known MTFCC codes that will appear in LA County imports but are not yet in the map:
- `G5400` — Elementary School District (separate from G5420 Unified)
- `G5410` — Secondary School District (separate from G5420 Unified)
- `G4110` — Incorporated Place (city boundary — distinct from county subdivision G4040)
- `G4120` — Consolidated City (not common, but present in some CA data)
- `G5200` is already mapped as `NATIONAL_LOWER`, but the current script imports congressional districts for Indiana only — re-importing CA congressional data may introduce duplicate MTFCC rows with same geo_id structure

**Why it happens:**
The MTFCC map was built incrementally for Bloomington (Monroe County) requirements. Each new region adds new district types. The code path for unknown MTFCCs is intentionally permissive to avoid dropping data, but this permissiveness becomes a correctness bug at scale.

**How to avoid:**
Audit all MTFCC codes that will appear in LA County imports before writing import scripts. Cross-reference the TIGER 2024 Technical Documentation Appendix E with the current `mtfccToDistrictTypes` map and add all missing codes before the first import. For codes without a clear district type mapping (e.g., G4120 Consolidated City), add them as LOCAL:
```go
var mtfccToDistrictTypes = map[string][]string{
    "G5210": {"STATE_UPPER"},
    "G5220": {"STATE_LOWER"},
    "G5200": {"NATIONAL_LOWER"},
    "G4020": {"COUNTY", "JUDICIAL"},
    "G4040": {"LOCAL", "LOCAL_EXEC"},          // County Subdivision (township/unincorporated)
    "G4110": {"LOCAL", "LOCAL_EXEC"},           // Incorporated Place (city)
    "G4120": {"LOCAL", "LOCAL_EXEC"},           // Consolidated City
    "G5400": {"SCHOOL"},                        // Elementary School District
    "G5410": {"SCHOOL"},                        // Secondary School District
    "G5420": {"SCHOOL"},                        // Unified School District (existing)
    "X0001": {"LOCAL"},                         // BallotReady city council sub-districts
}
```
After each import, run a query to identify unmapped MTFCCs in the database:
```sql
SELECT DISTINCT mtfcc FROM essentials.geofence_boundaries
WHERE mtfcc NOT IN ('G5210','G5220','G5200','G4020','G4040','G4110','G4120','G5400','G5410','G5420','X0001');
```
Any row returned from this query represents a coverage gap that will cause the permissive fallback to fire.

**Warning signs:**
- Post-import query for unknown MTFCCs returns non-zero rows
- Address search in an unincorporated LA County area (like Altadena or East LA) returns city council members from the adjacent incorporated city
- `SELECT DISTINCT mtfcc FROM essentials.geofence_boundaries` shows codes not in the Go map
- A politician with `district_type = 'LOCAL'` appears in search results for an address outside their geographic area

**Phase to address:**
MTFCC mapping audit must happen before the first LA County import run. It is a prerequisite for correct search results, not a polish step.

---

### Pitfall 5: Politician Deduplication Fails When Manual Records and Automated Records Share the Same Person

**What goes wrong:**
The system will have three sources of politician records for LA County: (1) the dead BallotReady import pipeline data already in the database, (2) new manual records entered via the staging module, and (3) potentially future automated imports. When these sources describe the same official, they create duplicate rows in `essentials.politicians`. The current unique key is `external_id` (an integer, set from BallotReady's numeric ID). Manual staging records have `external_id = 0` or a made-up value, so `ON CONFLICT (external_id) DO UPDATE` does not deduplicate them — it silently creates a second record for the same person. The address search query uses `DISTINCT ON (p.id)`, so both records appear in results. Users see the same supervisor or council member twice.

The problem is compounded by name variations: "Karen Bass" vs. "Karen L. Bass", "Bob García" vs. "Robert Garcia", or records where `full_name` differs but `first_name` + `last_name` + `district_id` uniquely identify the same person.

**Why it happens:**
Manual records entered via the staging module have no external_id from BallotReady. The staging workflow was designed for new stances on existing politicians, not for creating new politician records. When it is repurposed to add gap-fill LA County officials, the uniqueness infrastructure (based on `external_id`) does not apply.

**How to avoid:**
Before inserting any new politician record (whether manual or scripted), run an existence check using the `essentials.districts` geo_id and normalized name:
```sql
SELECT p.id FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = $1
  AND LOWER(TRIM(p.last_name)) = LOWER(TRIM($2))
  AND LOWER(TRIM(p.first_name)) = LOWER(TRIM($3));
```
If a match is found, update the existing record rather than inserting a new one. Use OCD-IDs as a secondary deduplication key when available — the `essentials.districts.ocd_id` field already stores these and they are stable identifiers intended for cross-source matching.

For politician names specifically: normalize to lowercase, strip accents (García → garcia), strip Jr/Sr/III suffixes before comparison. Full name fuzzy matching (trigram similarity) is over-engineering for a 2-3 person team at this scale — exact normalized match on last_name + first_name + district geo_id is sufficient for a single-county import.

Add a post-import duplicate detection query to the import runbook:
```sql
SELECT p.last_name, p.first_name, d.geo_id, COUNT(DISTINCT p.id) as duplicate_count
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
GROUP BY p.last_name, p.first_name, d.geo_id
HAVING COUNT(DISTINCT p.id) > 1;
```

**Warning signs:**
- The post-import duplicate detection query returns any rows
- Address search result list shows the same person's name twice with different UUIDs in the response
- Two politicians share the same `first_name`, `last_name`, and district label in the admin data entry UI
- Manual staging entries have `source = ''` or `source = 'manual'` while the DB also has `source = 'ballotready'` entries with the same name

**Phase to address:**
Politician gap-fill phase — deduplification check must run before inserting any manual record and again as a post-import validation step. The staging module workflow should surface the existence check result before allowing a new record to be created.

---

### Pitfall 6: School District Overlap in LA County — Three Parallel Shapefiles Return Three Matches for One Address

**What goes wrong:**
LA County has three separate TIGER school district types: Unified (G5420), Elementary (G5400), and Secondary (G5410). An address in Los Angeles Unified School District (LAUSD) will match all three layers — LAUSD covers both elementary and secondary grades as a unified district. If all three shapefiles are imported and no deduplication logic exists, the geofence query returns three school district geo_id matches for one address. `FindPoliticiansByGeoMatches` builds a WHERE clause with three separate conditions, each potentially matching the same school board member's district record. The result: school board members appear three times in the API response. On the frontend, the school board section lists the same person three times.

The same issue affects LA County's 5 supervisorial districts: if both the COUSUB (G4040) shapefile and a separate LA County GIS supervisor district import produce overlapping boundaries for unincorporated areas, a supervisor appears twice.

**Why it happens:**
Importing all three school district shapefiles (UNSD + ELSD + SCSD) without a layer-selection strategy is a natural mistake — the script downloads all three by default. The Go lookup code does not deduplicate by politician ID beyond `DISTINCT ON (p.id)`, but that deduplication only works if the politician is matched once. Three separate WHERE conditions can each independently match the same politician row.

**How to avoid:**
For any given address, only import the school district layer that corresponds to the district type in the database. Since the politicians table uses `district_type = 'SCHOOL'` without distinguishing elementary/secondary/unified, choose one canonical shapefile — import only UNSD (G5420, Unified) for LA County, which covers the overwhelming majority of LA County students. Elementary-only and Secondary-only districts are edge cases that exist in a few rural California counties, not in metro LA County.

If multiple school district layers must coexist, add deduplication logic in `FindPoliticiansByGeoMatches` before building the WHERE clause:
```go
// Deduplicate matches by MTFCC priority: prefer G5420 if any school district matches
seenSchoolDistrict := false
for _, m := range matches {
    if m.MTFCC == "G5420" || m.MTFCC == "G5400" || m.MTFCC == "G5410" {
        if seenSchoolDistrict && m.MTFCC != "G5420" {
            continue // Skip elementary/secondary if unified already matched
        }
        seenSchoolDistrict = true
    }
    // ... add to conditions
}
```

**Warning signs:**
- An address in LAUSD returns the same school board member 2-3 times in the API response
- `SELECT COUNT(*) FROM essentials.geofence_boundaries WHERE mtfcc IN ('G5400','G5410','G5420')` shows rows for all three types in the same geographic area
- The frontend school board section renders duplicated cards for the same person
- The API response JSON contains the same `id` UUID appearing in multiple entries in the officials array

**Phase to address:**
Shapefile layer selection phase — before running import scripts, explicitly decide which school district layers to import for each county. Document the decision. For LA County: import UNSD only. For Indiana (Monroe County): UNSD only (already the current behavior).

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| `ON CONFLICT (geo_id) DO NOTHING` in import script | Idempotent re-runs without error | Silently drops valid boundaries when geo_id collides across MTFCC types; second import of a new layer appears to succeed but inserts zero rows | Never — fix to `ON CONFLICT (geo_id, mtfcc)` before first multi-layer LA County import |
| Importing all three school district shapefiles (UNSD + ELSD + SCSD) for completeness | Appears more thorough | Same person appears 2-3x in results; deduplication requires additional query-layer logic; frontend renders duplicate cards | Never for a single-county display use case — pick one canonical layer (UNSD) |
| Using Supabase pooler URL (port 6543) for import scripts | Only one connection string to manage | ogr2ogr fails silently via prepared statement errors; partial imports create inconsistent table state | Never for bulk data imports — always use direct connection (port 5432) |
| Adding LA County politicians by hand without a dedup check | Fast gap-fill for a demo | Creates duplicate records that survive future automated imports and appear as doubled cards in search | Acceptable only if post-insert dedup validation query is run immediately after and confirmed zero results |
| Skipping `ST_IsValid` check before staging → production migration | Saves 2 minutes per import run | Invalid geometries fail spatial queries silently; district exists in DB but never matches any address | Never — validity check is a 5-second query that prevents hours of debugging |
| Leaving unknown MTFCC codes as permissive fallback in `geofence_lookup.go` | No code change required when new layer is imported | Wrong politicians returned for users in areas covered by unmapped district types | Never for production — audit and map every MTFCC before importing its shapefile layer |

---

## Integration Gotchas

Common mistakes when connecting to external services.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| LA County GIS Hub (ArcGIS FeatureServer) | Downloading data as JSON via the REST API page, which paginates at 1000 features and silently truncates results | Use `&resultOffset=0&resultRecordCount=2000&f=geojson` with explicit pagination, or download the full dataset as a Shapefile via the "Download" button on the Hub page — always verify feature count against the metadata `count` field |
| LA County GIS Hub (ArcGIS FeatureServer) | Importing the raw GeoJSON response without projection checking — ArcGIS data may be in EPSG:3857 (Web Mercator) or a California State Plane projection rather than WGS84 | Run `ogrinfo -al -so layer.geojson` before any import to verify the CRS; reproject with `-t_srs EPSG:4326` in ogr2ogr if needed |
| Census TIGER FTP downloads | Using stale 2022 or 2023 files when 2024 files are available — congressional districts changed after 2022 redistricting | Always download from `www2.census.gov/geo/tiger/TIGER2024/` or `TIGER2025/` and confirm the year in the filename; verify congressional district count matches the expected 52 for California (post-2022 redistricting) |
| Supabase direct connection | Forgetting that Supabase direct connections require IPv4 Add-on or session-mode pooler for IPv4-only CI/CD environments | For CI pipelines running in IPv4-only environments (most GitHub Actions runners), use the session-mode pooler (port 5432 on pooler.supabase.com) or enable the IPv4 add-on; session mode supports prepared statements unlike transaction mode |
| ogr2ogr + PostGIS schema-qualified table names | Using `-nln essentials.geofence_boundaries` without creating the schema first — ogr2ogr cannot create schemas, only tables | Always run `CREATE SCHEMA IF NOT EXISTS essentials;` via psql before any ogr2ogr import that targets a non-public schema |
| ogr2ogr geometry column naming | ogr2ogr defaults to `wkb_geometry` as the geometry column name; the existing `essentials.geofence_boundaries` table uses `geometry` | Always pass `-lco GEOMETRY_NAME=geometry` to match the existing column name; without this flag, ogr2ogr creates a second geometry column or fails with a column-not-found error |

---

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Importing all California congressional districts (52 districts) + all state assembly (80) + all state senate (40) + all school districts (80+ in LA County) without GiST index in place | First address lookup after import takes 15-30 seconds; pgAdmin shows Seq Scan on geofence_boundaries | Create GiST index before loading any data: `CREATE INDEX IF NOT EXISTS idx_geofence_boundaries_geometry ON essentials.geofence_boundaries USING GIST (geometry)` — then load data — then VACUUM ANALYZE | Immediately at first query, even in development |
| Using `ST_Contains` instead of `ST_Covers` for point-in-polygon on newly imported data | Addresses on district border streets (very common in urban LA County grids) return zero results; no error | Use `ST_Covers` everywhere in `FindGeoIDsByPoint`; the function currently uses `ST_Contains` (line 42 of `geofence_lookup.go`) — this is a pre-existing bug that becomes more visible at LA County scale where grid streets often sit exactly on district boundaries | Always — but will appear more often with 50+ imported layers than with 6 Bloomington districts |
| Not running `VACUUM ANALYZE` after each shapefile import | Query planner ignores GiST index despite it existing; `EXPLAIN ANALYZE` shows Seq Scan even with index present | Always run `VACUUM ANALYZE essentials.geofence_boundaries;` at the end of each import script's post-processing SQL block | After any bulk load of 1,000+ rows |
| Complex multipolygon geometries (coastal California congressional districts) stored at full TIGER resolution | Each spatial query loads 50KB+ geometry blobs from disk per candidate polygon; query time grows linearly with polygon complexity | After import, apply selective simplification for large polygons: `UPDATE essentials.geofence_boundaries SET geometry = ST_SimplifyPreserveTopology(geometry, 0.0001) WHERE ST_NPoints(geometry) > 5000 AND mtfcc IN ('G5200', 'G5210', 'G5220')` — tolerance of 0.0001 degrees preserves accuracy to ~11m at latitude 34° | When geofence_boundaries table contains coastal districts with 10,000+ polygon vertices — measurable at >500 concurrent users |
| Building the `FindPoliticiansByGeoMatches` WHERE clause with 15+ OR conditions (one per geo_id match) | Query plan shows nested loop join instead of index scan as condition count grows; response time climbs from 50ms to 400ms | Refactor to use a temporary values table with a JOIN rather than a long OR chain when match count exceeds 10: pass geo_ids as a `pq.Array` with `d.geo_id = ANY($1)` and handle MTFCC filtering in application code | When an LA County address matches 12+ district layers simultaneously (congressional + state senate + state assembly + county + 5+ city + 3+ school layers) |

---

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Storing `DATABASE_URL` with direct Supabase connection credentials in the import shell script | Credentials committed to git; anyone with repo access can directly connect to the production database | Source DATABASE_URL from environment variable only; import scripts must never hardcode or echo the connection string; add `DATABASE_URL` to `.gitignore` for any `.env` file in `EV-Backend/scripts/` |
| Using the same Supabase connection string for import scripts and the running Go backend | A compromised import script or misconfigured CI job can drop/truncate production tables that the backend relies on | Use a separate PostgreSQL role for imports that has INSERT/UPDATE on `essentials.geofence_boundaries` and `essentials.politicians` but NOT DROP TABLE or TRUNCATE; the Go backend role needs only SELECT/INSERT/UPDATE on its own tables |
| Including raw addresses or geocoded lat/lng in import script logs | Shell script `set -x` debug mode will print DATABASE_URL and query parameters to stdout; if logged to a file, these constitute PII | Never run import scripts with `set -x`; redirect output to a log file that excludes sensitive parameters; treat geocoded coordinates as PII under California CCPA |
| Publishing the import runbook (with example DATABASE_URL) in a public-facing document | Direct connection to Supabase exposes the database | Keep the import runbook in `.planning/` (already gitignored for secrets) or a private Notion/Confluence page; never include actual connection strings in documentation |

---

## UX Pitfalls

Common user experience mistakes when expanding geofence coverage for the first time.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Expanding to LA County without updating `buildSubtitle()` for new district label patterns | LA County GIS data uses different label conventions than Bloomington data — "5th District" vs. "District 5", "Supervisorial District 3" vs. "County Board District 3"; the `buildSubtitle()` function parses chamber_name and district_label string patterns that are tied to Bloomington data | Review all district labels from LA County before releasing; add a manual QA step that inspects subtitle rendering for all 5 supervisorial districts, all LA City Council districts, and all LAUSD board members |
| Showing imported districts with no politician data as empty sections | If shapefile import succeeds but politician gap-fill for a district is incomplete, the frontend receives a district match but zero officials — the section header renders with no cards beneath it | The API `SearchPoliticians` handler must not return a district match that has zero associated politicians; filter out empty district hits at the SQL layer before responding |
| Not updating `building_images` config for LA County sections | The essentials frontend shows a building image for each tier; LA County additions need a new building photo source; the current mapping covers only Bloomington IN and Los Angeles CA federal sections | Verify building image config covers all new sections (county, school board, city council) before launch; use existing SVG fallback rather than a broken image |
| Importing LA County data without testing an address in an unincorporated area | Unincorporated areas (East LA, West Hollywood pre-incorporation, Altadena) are served by county supervisors but not city councils — test with an Altadena address to confirm only county officials appear and no incorporated-city officials bleed through | Add at least 3 test addresses to the QA checklist: one incorporated city (e.g., Pasadena), one unincorporated area (e.g., Altadena), one area with contested city/county boundary (e.g., East LA) |

---

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Unique constraint updated:** Verify `(geo_id, mtfcc)` composite unique constraint exists on `essentials.geofence_boundaries` — not just `geo_id` — before running any multi-layer import: `SELECT conname, pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid = 'essentials.geofence_boundaries'::regclass`
- [ ] **Geometry validity verified:** Run `SELECT COUNT(*), mtfcc FROM essentials.geofence_boundaries WHERE NOT ST_IsValid(geometry) GROUP BY mtfcc` after every import — expected result: zero rows
- [ ] **GiST index active:** Confirm `EXPLAIN ANALYZE SELECT geo_id, mtfcc FROM essentials.geofence_boundaries WHERE ST_Covers(geometry, ST_SetSRID(ST_MakePoint(-118.25, 34.05), 4326))` shows "Index Scan" not "Seq Scan"
- [ ] **ST_Contains replaced with ST_Covers:** Verify `geofence_lookup.go` line 42 uses `ST_Covers` not `ST_Contains` — the current code uses `ST_Contains`, which silently fails for addresses exactly on district boundaries
- [ ] **MTFCC map complete:** Run `SELECT DISTINCT mtfcc FROM essentials.geofence_boundaries WHERE mtfcc NOT IN ('G5210','G5220','G5200','G4020','G4040','G4110','G4120','G5400','G5410','G5420','X0001')` — expected result: zero rows
- [ ] **No duplicate politicians:** Run the duplicate detection query after every gap-fill import: `SELECT last_name, first_name, COUNT(DISTINCT id) FROM essentials.politicians GROUP BY last_name, first_name HAVING COUNT(DISTINCT id) > 1` — cross-reference with district geo_ids to confirm true duplicates vs. same-named different people
- [ ] **Direct connection used for import:** Verify `DATABASE_URL` used in import scripts contains port 5432 and `db.*.supabase.co` hostname, not port 6543 or `pooler.supabase.com`
- [ ] **School district layer single-type:** Confirm `SELECT mtfcc, COUNT(*) FROM essentials.geofence_boundaries WHERE mtfcc IN ('G5400','G5410','G5420') GROUP BY mtfcc` shows only one MTFCC type with rows for any given geographic area
- [ ] **Row count matches expected:** Post-import, verify congressional district count = 52 for California, State Senate = 40, State Assembly = 80 — cross-reference against known TIGER feature counts
- [ ] **Import pipeline idempotent:** Re-run the import script for a previously imported layer and verify row counts do not change (ON CONFLICT updates existing rows rather than inserting or ignoring)
- [ ] **Unincorporated area test passes:** Search an Altadena address — result must include county supervisor but must NOT include any incorporated city council member
- [ ] **VACUUM ANALYZE run:** Verify `SELECT last_analyze FROM pg_stat_user_tables WHERE relname = 'geofence_boundaries'` shows a timestamp within the last hour of completing each import

---

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| `ON CONFLICT (geo_id) DO NOTHING` drops valid boundaries | MEDIUM | (1) Drop and recreate the unique constraint as `(geo_id, mtfcc)`. (2) Re-run the import script — all previously skipped rows now insert. (3) Run VACUUM ANALYZE. (4) Re-verify row counts per MTFCC. Recovery time: 30-60 minutes depending on shapefile size |
| Invalid geometries silently omitted from import | MEDIUM | (1) Run `ST_IsValid` audit on staging table before promotion. (2) Apply `ST_MakeValid` + `ST_CollectionExtract` to fix broken geometries in staging. (3) Re-insert from staging with repaired geometries. (4) No production data is lost — staging is a separate table. Recovery time: 1-2 hours |
| Supabase pooler used for import — partial data committed | MEDIUM-HIGH | (1) Identify which rows were imported by checking `imported_at` timestamp and source tag. (2) Delete the partial import: `DELETE FROM essentials.geofence_boundaries WHERE source = 'census_tiger_2024' AND imported_at > '[partial_start_time]'`. (3) Re-run import with direct connection (port 5432). No data corruption — only partial data that needs replacement. Recovery time: 1 hour |
| Duplicate politician records in production | MEDIUM | (1) Run duplicate detection query to identify duplicate UUID pairs. (2) Identify the authoritative record (prefer source = 'ballotready' over 'manual'; prefer record with more non-null fields). (3) UPDATE all referencing tables (offices, images, degrees, endorsements, stances, election_records) to point to the authoritative UUID. (4) DELETE the duplicate record. (5) Test address search to confirm single result. Recovery time: 2-4 hours depending on number of duplicates |
| Unknown MTFCC returns wrong politicians | LOW | (1) Add the unknown MTFCC code to `mtfccToDistrictTypes` in `geofence_lookup.go`. (2) Deploy backend. No data changes required. Recovery time: under 1 hour including deploy |
| Duplicate school board entries from multiple shapefile layers | MEDIUM | (1) Identify which MTFCC codes to retire: `SELECT mtfcc, COUNT(*) FROM essentials.geofence_boundaries WHERE mtfcc IN ('G5400','G5410','G5420') GROUP BY mtfcc`. (2) Delete the redundant layers: `DELETE FROM essentials.geofence_boundaries WHERE mtfcc IN ('G5400','G5410') AND state = '06'`. (3) VACUUM ANALYZE. Recovery time: 30 minutes |
| `ST_Contains` vs `ST_Covers` — addresses on boundaries return zero districts | LOW | (1) Update `geofence_lookup.go` line 42: replace `ST_Contains` with `ST_Covers`. (2) Deploy backend. No data changes required. Recovery time: under 1 hour including deploy. This is a pre-existing bug in the current codebase; the v1.5 PITFALLS.md flagged it but it was not fixed in v1.5 |

---

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| `ON CONFLICT (geo_id) DO NOTHING` drops layers (Pitfall 1) | Shapefile pipeline design — first phase of v1.6 | Query `SELECT conname FROM pg_constraint WHERE conrelid = 'essentials.geofence_boundaries'::regclass` shows `(geo_id, mtfcc)` composite constraint |
| Invalid geometry silent drops (Pitfall 2) | Shapefile import execution | `SELECT COUNT(*) FROM essentials.geofence_boundaries WHERE NOT ST_IsValid(geometry)` returns 0 |
| Supabase pooler breaks ogr2ogr (Pitfall 3) | Import tooling setup — first phase | Import script validation step passes: `psql "$DATABASE_URL" -c "SELECT 1"` on port 5432 |
| Incomplete MTFCC map (Pitfall 4) | MTFCC audit before first LA import | `SELECT DISTINCT mtfcc FROM essentials.geofence_boundaries WHERE mtfcc NOT IN (...)` returns 0 rows |
| Politician deduplication failure (Pitfall 5) | Politician gap-fill phase | Duplicate detection query returns 0 rows after each import batch |
| School district triple-match (Pitfall 6) | Shapefile layer selection — documented decision before import | Only G5420 (or exactly one school district MTFCC) present per geographic area in geofence_boundaries |
| ST_Contains vs ST_Covers boundary bug (Performance Traps) | Geofence query correctness phase | Test address on known district boundary returns at least one result |
| Missing VACUUM ANALYZE (Performance Traps) | Each import execution | `EXPLAIN ANALYZE` on a live geofence query shows Index Scan; `pg_stat_user_tables.last_analyze` is recent |

---

## Sources

- PostGIS official documentation: [ST_MakeValid](https://postgis.net/docs/ST_MakeValid.html), [ST_IsValid](https://postgis.net/docs/ST_IsValid.html), [Validity chapter](https://postgis.net/workshops/postgis-intro/validity.html), [Spatial Indexing](http://postgis.net/workshops/postgis-intro/indexing.html)
- GDAL issue #6340: [ogr2ogr -makevalid GeometryCollection behavior](https://github.com/OSGeo/gdal/issues/6340) — documents how -makevalid can produce GeometryCollection types that break typed PostGIS columns
- Crunchy Data: [PostGIS Performance — Indexing and EXPLAIN](https://www.crunchydata.com/blog/postgis-performance-indexing-and-explain), [Waiting for PostGIS 3.2: ST_MakeValid](https://www.crunchydata.com/blog/waiting-for-postgis-3.2-st_makevalid), [Loading Data into PostGIS](https://www.crunchydata.com/blog/loading-data-into-postgis-an-overview)
- Supabase docs: [Connecting to Postgres](https://supabase.com/docs/guides/database/connecting-to-postgres) — direct connection vs pooler guidance; [Connection management](https://supabase.com/docs/guides/database/connection-management)
- Supabase: [Session Mode Deprecation Discussion](https://github.com/orgs/supabase/discussions/32755) — Supavisor transaction mode limitations with prepared statements
- Census Bureau: [TIGER/Line Shapefiles 2024 Technical Documentation](https://www2.census.gov/geo/pdfs/maps-data/data/tiger/tgrshp2024/TGRSHP2024_TechDoc.pdf) — MTFCC codes in Appendix E; [MAF/TIGER Feature Class Code Definitions](https://www.census.gov/library/reference/code-lists/mt-feature-class-codes.html); [2022 MTFCC codes PDF](https://www2.census.gov/geo/pdfs/reference/mtfccs2022.pdf)
- BallotReady Support: [Interpreting MTFCC and geo_id](https://support.ballotready.org/interpreting-mtfcc-and-geoid) — documents X0001 custom code and geo_id structure for city council sub-districts
- Cicero Data: [OCD-IDs for cross-source politician matching](https://medium.com/cicero-data/how-to-use-open-civic-data-identifiers-to-organize-political-data-c27755702509)
- OpenSanctions: [Deduplication across data sources](https://www.opensanctions.org/articles/2021-11-11-deduplication/) — multi-source record deduplication patterns
- LA County GIS Hub: [Supervisorial Districts (Current)](https://egis-lacounty.hub.arcgis.com/datasets/lacounty::supervisorial-districts-current/about), [Enterprise GIS ArcGIS REST services](https://egis-lacounty.hub.arcgis.com/ArcGIS/rest/services)
- GDAL documentation: [ogr2ogr options reference](https://gdal.org/en/stable/programs/ogr2ogr.html) — `-makevalid`, `-nlt`, `-lco GEOMETRY_NAME`, `-t_srs` flags
- Codebase: `EV-Backend/scripts/import_shapefiles.sh`, `EV-Backend/internal/essentials/geofence_lookup.go`, `EV-Backend/internal/essentials/geofence_models.go` — project-specific behaviors documented from direct code review

---
*Pitfalls research for: v1.6 LA County Full Coverage — TIGER shapefile import pipeline, geofence scaling, politician deduplication*
*Researched: 2026-02-23*
