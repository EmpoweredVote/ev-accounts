# Phase 38: Validation and Performance - Research

**Researched:** 2026-02-24
**Domain:** PostgreSQL/PostGIS performance tuning, point-in-polygon validation, pipeline documentation
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Test Address Selection**
- Claude selects all 3 required test addresses (incorporated city, unincorporated area, boundary edge)
- Incorporated city: pick a mid-size city like Pasadena or Long Beach that exercises multiple tiers
- Unincorporated area: pick a community like East LA, Willowbrook, or Altadena
- Boundary edge: address on a district line — must return a result (no empty/null responses on boundaries)
- All test addresses go in a repeatable validation script (not one-time manual checks)

**Gap Remediation**
- Phase 38 fixes all gaps found during validation — the goal is that validation passes, not just that we ran checks
- Fixing can include patching scrapers or re-running importers from previous phases if needed
- Expected gaps are correct behavior: unincorporated areas legitimately have no city council, that's not a failure
- Validation script outputs pass/fail report showing expected vs actual tiers per address, with PASS/FAIL per tier and overall summary

**Pipeline Documentation**
- Step-by-step runbook in `.planning/IMPORT-PIPELINE.md`
- Uses LA County as the concrete example throughout, with notes on what varies per region
- Covers: data sources, import order, dependencies between steps
- Includes a verification section that references the validation script from this phase
- Audience: someone repeating this process for a new county/region

**Validation Breadth**
- 10-20 sample addresses beyond the 3 required test addresses
- Mix of geographic spread (north/south/east/west LA County) and intentional edge cases (small cities, multi-district overlaps)
- Validation script shows tier-level detail per address: which tiers (federal, state, county, city, school) resolved
- For performance: confirming GiST Index Scan via EXPLAIN ANALYZE is sufficient — no specific query time threshold required

### Claude's Discretion
- Specific address selection for all test cases
- Validation script language/format (SQL file, shell script, etc.)
- VACUUM ANALYZE timing and approach
- How to structure the pass/fail report output

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| VAL-01 | Point-in-polygon verification passes for test addresses (incorporated city, unincorporated area, boundary edge) | PIP query pattern from geofence_lookup.go; validation script uses psycopg2 + ST_Covers; tier detection via MTFCC-to-district-type map |
| VAL-02 | VACUUM ANALYZE run on geofence_boundaries after all imports | PostgreSQL VACUUM ANALYZE command; Supabase direct connection (port 5432) required; no special privileges beyond DB owner needed |
| VAL-03 | GiST index confirmed active (EXPLAIN ANALYZE shows Index Scan, not Seq Scan) | PostgreSQL EXPLAIN ANALYZE syntax; GiST index existence checkable via pg_indexes; Index Scan requires statistics to be current (hence VAL-02 ordering) |
| VAL-04 | Any LA County address returns full representative hierarchy (federal, state, county, city, school board) | SearchPoliticians handler in handlers.go shows full lookup chain; geofence_lookup.go shows FindGeoIDsByPoint + FindPoliticiansByGeoMatches; supplemental federal/state fetch via fetchStatewideFromDB |
</phase_requirements>

## Summary

Phase 38 is the validation and sign-off phase for the entire v1.6 LA County data pipeline built across Phases 32-37. The work falls into three distinct tasks: (1) run VACUUM ANALYZE on the geofence_boundaries table to refresh query planner statistics after the bulk imports, (2) write and execute a repeatable validation script that tests 13-23 representative LA County addresses and reports tier-level PASS/FAIL results, and (3) write a step-by-step import pipeline runbook as `.planning/IMPORT-PIPELINE.md`.

The technical substrate is well-understood. The project has established psycopg2-based validation patterns across multiple prior phases — `scrape_la_officials.py` and `scrape_school_boards.py` both contain `verify_pip_tests()` functions that form the exact foundation the validation script extends. The geofence lookup logic in `geofence_lookup.go` (using `ST_Covers` + MTFCC disambiguation) is the ground truth for what "correct" means. The validation script simply needs to run that same SQL against a curated set of representative addresses and report per-tier PASS/FAIL.

The primary risk is discovering gaps (missing politicians or geofences) during validation. The CONTEXT.md is explicit: gaps must be fixed, not just logged. Based on prior-phase summaries, two known categories of potential gaps exist: (a) the five "gap cities" (Santa Clarita, Downey, El Monte, Palmdale, Pomona) where no ArcGIS council district boundaries were found, so city council tiers will be missing for those cities' addresses — this is an expected/accepted gap per Phase 35 decisions; and (b) unincorporated communities legitimately have no city council tier (also expected). The validation script's pass/fail criteria must account for these known-acceptable absences.

**Primary recommendation:** Write the validation script as a standalone Python script using psycopg2 + the utils.py pattern, with structured per-address output showing each tier's resolution. Run VACUUM ANALYZE first, confirm GiST Index Scan via EXPLAIN ANALYZE, then run the full address suite. Document anything fixed during validation. Write the IMPORT-PIPELINE.md last, after validation confirms what the complete working pipeline looks like.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| psycopg2-binary | 2.9.11 (pinned in requirements.txt) | Direct PostgreSQL connection for validation queries | Used in all v1.6 scripts; handles Supabase direct connection + special-char passwords |
| Python | 3.13 (venv at scripts/.venv) | Script runtime | Established project standard for all import/validation scripts |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| utils.py (local) | n/a | `load_env()`, `get_engine()`, `next_ext_id()` | Always — shared utilities for all scripts in EV-Backend/scripts/ |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| psycopg2 direct | SQLAlchemy text() | psycopg2 is simpler for validation-only; SQLAlchemy used when geopandas integration needed (import scripts) |
| Python script | SQL file + psql | Python allows structured output, PASS/FAIL logic, and reusability; SQL file is harder to generate a formatted report from |

**Installation:** No new dependencies — all required packages already in `requirements.txt` and `.venv`.

## Architecture Patterns

### Recommended Project Structure
```
EV-Backend/scripts/
├── validate_la_county.py    # New: comprehensive validation + VACUUM + EXPLAIN
└── utils.py                 # Existing: load_env, get_engine, next_ext_id
.planning/
└── IMPORT-PIPELINE.md       # New: step-by-step runbook for future regions
```

### Pattern 1: PIP Validation Script Structure
**What:** A standalone Python script that runs ST_Covers queries for each test address and reports which district tiers resolved, then prints per-address PASS/FAIL.
**When to use:** End-of-pipeline validation gate; also re-runnable as regression test after future imports.
**Example (based on established patterns in scrape_la_officials.py and scrape_school_boards.py):**
```python
#!/usr/bin/env python3
"""
LA County validation script.

Usage:
    cd EV-Backend/scripts
    python3 validate_la_county.py
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from utils import load_env

import psycopg2
import psycopg2.extras

def get_connection():
    """Same pattern as scrape_la_officials.py"""
    import os
    from urllib.parse import urlparse
    raw_url = os.getenv("DATABASE_URL")
    parsed = urlparse(raw_url)
    return psycopg2.connect(
        host=parsed.hostname, port=parsed.port or 5432,
        dbname=parsed.path.lstrip("/"),
        user=parsed.username, password=parsed.password,
    )

# Test addresses: (label, lat, lng, expected_tiers, expected_notes)
TEST_ADDRESSES = [
    # Required VAL-01 addresses
    ("Pasadena City Hall (incorporated city)",  34.1478, -118.1445,
     ["federal", "state_senate", "state_assembly", "county", "city", "school"],
     "All 6 tiers expected"),
    ("East LA Community Center (unincorporated)", 34.0239, -118.1726,
     ["federal", "state_senate", "state_assembly", "county", "school"],
     "No city tier — unincorporated; 5 tiers expected"),
    ("Boundary address (city limit edge TBD)",  34.0000, -118.0000,
     ["federal", "state_senate", "state_assembly", "county", "school"],
     "Must return result, not empty"),
    # ... 10-20 more addresses
]

def check_tiers(cur, lat, lng):
    """Returns dict of tier -> [politician names] for the given point."""
    cur.execute("""
        SELECT p.full_name, d.district_type, d.geo_id, gb.mtfcc
        FROM essentials.politicians p
        JOIN essentials.offices o ON o.politician_id = p.id
        JOIN essentials.districts d ON o.district_id = d.id
        JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
        WHERE ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(%s, %s), 4326))
          AND p.is_active = true
    """, (lng, lat))
    rows = cur.fetchall()
    # Group by tier...
    pass
```

### Pattern 2: VACUUM ANALYZE + EXPLAIN ANALYZE
**What:** PostgreSQL maintenance command to refresh statistics, followed by EXPLAIN ANALYZE to confirm GiST index use.
**When to use:** After all bulk inserts; must run before validating performance (VAL-02 before VAL-03).

```sql
-- VAL-02: Run via psycopg2 with autocommit=True (VACUUM cannot run in transaction)
VACUUM ANALYZE essentials.geofence_boundaries;

-- VAL-03: Confirm GiST Index Scan (not Seq Scan)
-- Use any LA County coordinate known to have geofences
EXPLAIN ANALYZE
  SELECT geo_id, mtfcc
  FROM essentials.geofence_boundaries
  WHERE ST_Covers(geometry, ST_SetSRID(ST_MakePoint(-118.2427, 34.0537), 4326));
-- Expected output contains: "Index Scan using ... on geofence_boundaries"
-- NOT: "Seq Scan on geofence_boundaries"
```

**CRITICAL:** VACUUM cannot execute inside a transaction block. When using psycopg2, set `conn.autocommit = True` before calling `cur.execute("VACUUM ANALYZE ...")`, then restore autocommit behavior afterward.

### Pattern 3: Tier Classification for Pass/Fail Logic
**What:** Map district_type + MTFCC to named tiers for human-readable output.
**Based on:** `mtfccToDistrictTypes` in `geofence_lookup.go` and tier classification in `essentials/src/lib/classify.js`.

```python
# Tier detection from district_type (mirrors geofence_lookup.go mapping)
TIER_FROM_DISTRICT_TYPE = {
    "NATIONAL_LOWER": "federal",     # Congressional seat (from geofence G5200)
    "NATIONAL_UPPER": "federal",     # US Senate (statewide, not from geofence)
    "NATIONAL_EXEC":  "federal",     # President etc (statewide)
    "STATE_LOWER":    "state_assembly",
    "STATE_UPPER":    "state_senate",
    "STATE_EXEC":     "state",
    "COUNTY":         "county",
    "LOCAL_EXEC":     "city",        # Mayor
    "LOCAL":          "city",        # City council OR county supervisor (by MTFCC context)
    "SCHOOL":         "school",
    "JUDICIAL":       "judicial",
}
# Note: LA County supervisors have district_type=LOCAL and MTFCC=X0001 (not G4020)
# This is the [35-01] decision: X0001 maps to LOCAL, not COUNTY
```

**Important nuance for LA County supervisors:** The county supervisor tier has `district_type='LOCAL'` with `mtfcc='X0001'` (not `COUNTY`/`G4020`). This is the Phase 35-01 decision. The validation script must count supervisors as "county" tier via ocd_id matching or explicit supervisor title detection, not via district_type alone.

### Anti-Patterns to Avoid
- **Running VACUUM inside a transaction:** Will raise `psycopg2.errors.ActiveSqlTransaction`. Must use `conn.autocommit = True`.
- **Hardcoding "Index Scan" check in Python:** EXPLAIN output format varies. Check that the output does NOT contain "Seq Scan" rather than asserting exact "Index Scan" string.
- **Treating all at-large city council as failures:** For cities where no ward-level geofences were imported (gap cities: Santa Clarita, Downey, El Monte, Palmdale, Pomona), city council tier will be absent. This is an expected gap per Phase 35 decisions — not a validation failure.
- **Using port 6543 (Supabase pooler):** Breaks VACUUM and some multi-statement operations. Always use direct connection port 5432.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| DB connection with special-char password | Custom URL parser | `utils.py get_engine()` / existing `get_connection()` patterns | Already handles `@`, `/`, `+` edge cases; tested across all v1.6 phases |
| PIP query SQL | Custom spatial function | Exact SQL from `geofence_lookup.go` FindGeoIDsByPoint | Proven correct; uses `ST_Covers` (not `ST_Contains`) — the Phase 32 fix for boundary-coincident points |
| Tier detection logic | Custom rules | Mirror `mtfccToDistrictTypes` map from `geofence_lookup.go` | Ground truth for what tiers return in production |

**Key insight:** The geofence_lookup.go file is the canonical production truth — the validation script must mirror its SQL exactly to test what the API actually does, not a simplified approximation.

## Common Pitfalls

### Pitfall 1: VACUUM in a Transaction Block
**What goes wrong:** `psycopg2.errors.ActiveSqlTransaction: VACUUM cannot run inside a transaction block`
**Why it happens:** psycopg2 opens a transaction automatically on first execute; VACUUM is a maintenance command that must run outside transactions.
**How to avoid:** Set `conn.autocommit = True` before the VACUUM execute call. After VACUUM completes, set `conn.autocommit = False` to re-enable transaction semantics for subsequent queries.
**Warning signs:** Error message mentions "transaction block" during VACUUM execute.

### Pitfall 2: LA County Supervisors Show as "city" Tier (not "county")
**What goes wrong:** Validation script reports "county" tier missing for all addresses, even when a supervisor is returned.
**Why it happens:** Phase 35-01 decision: supervisor district geofences use MTFCC=X0001 (not G4020) because BallotReady assigns `district_type='LOCAL'` (not `COUNTY`/`JUDICIAL`) to supervisors. So the DB record has district_type='LOCAL', not 'COUNTY'.
**How to avoid:** Detect supervisors by their office title (`LIKE '%Supervisor%'`) or by filtering `ocd_id LIKE '%county:los_angeles/council_district%'`, not by `district_type='COUNTY'`.
**Warning signs:** Tier detection counts supervisor as "city" or misses the "county" tier entirely.

### Pitfall 3: Unincorporated Areas Trigger False Failures
**What goes wrong:** Validation script flags East LA / Willowbrook / Altadena as FAIL because "city" tier is absent.
**Why it happens:** Unincorporated communities have no incorporated city boundary (no G4110 or X0001 record), so no city council tier is correct.
**How to avoid:** Define per-address `expected_tiers` lists in the test address config. Mark known-unincorporated addresses as not expecting "city" or "city_council" tiers.
**Warning signs:** Test definitions don't distinguish incorporated vs unincorporated addresses.

### Pitfall 4: Gap Cities Trigger False Failures
**What goes wrong:** Addresses in Santa Clarita, Downey, El Monte, Palmdale, or Pomona fail the "city council" tier check.
**Why it happens:** Phase 35 documented these 5 cities as gaps — no ArcGIS FeatureServer URL found for council district boundaries. City council tier is legitimately absent.
**How to avoid:** Don't include these 5 cities as test addresses requiring city council tier. If included for geographic spread, mark them as not requiring council tier.
**Warning signs:** Test addresses chosen from gap cities with city-council tier in expected list.

### Pitfall 5: EXPLAIN ANALYZE Shows Index Scan Before VACUUM
**What goes wrong:** EXPLAIN ANALYZE shows Seq Scan even though GiST index exists on the geometry column.
**Why it happens:** PostgreSQL query planner uses table statistics to decide whether to use an index. After bulk inserts, statistics are stale — planner may estimate sequential scan is faster. VACUUM ANALYZE updates statistics so the planner sees accurate row counts and geometry distribution.
**How to avoid:** Always run VACUUM ANALYZE (VAL-02) before checking EXPLAIN ANALYZE (VAL-03). This is the ordering constraint documented in STATE.md: "VACUUM ANALYZE (Phase 38) must be last step after all bulk inserts."
**Warning signs:** VAL-03 check run before VAL-02 completes.

### Pitfall 6: LAUSD Returns All 7 Board Members for Any LAUSD Address
**What goes wrong:** The school tier appears to return excess members (7) for any LAUSD address.
**Why it happens:** Phase 37-02 decision: LAUSD trustee area sub-boundaries were not found in public ArcGIS as of 2026-02-24. All 7 LAUSD board members share the whole-district geo_id='0622710'. This is correct behavior, not a bug.
**How to avoid:** Validation script for LAUSD addresses should check "at least 1 school board member" (or specifically "7 for LAUSD addresses"), not "exactly 1".
**Warning signs:** Validation fails because it expects exactly 1 school board member per address.

### Pitfall 7: Federal/State Tiers from Statewide Fetch, Not Geofences
**What goes wrong:** NATIONAL_UPPER (US Senate) and NATIONAL_EXEC (President/VP/Cabinet) are missing from geofence-based results, but validation expects them.
**Why it happens:** The production `SearchPoliticians` handler returns geofence results supplemented by `fetchStatewideFromDB()` for NATIONAL_UPPER, NATIONAL_EXEC, STATE_EXEC. These officials are NOT stored in geofence_boundaries — they're returned directly from the `essentials.politicians` table filtered by state.
**How to avoid:** The validation script's full-hierarchy check must either call the actual API endpoint (most accurate) OR run the statewide supplement query separately and combine with geofence results. The simplest correct approach is to test via the HTTP API (`/politicians/search` POST with address JSON), which exercises the full production code path.
**Warning signs:** Validation checks only geofence-matched results and flags federal/state officials as missing.

## Code Examples

Verified patterns from the codebase:

### VACUUM ANALYZE via psycopg2
```python
# Source: PostgreSQL docs + established project patterns
import psycopg2

load_env()
conn = get_connection()
try:
    conn.autocommit = True   # CRITICAL: VACUUM cannot run in transaction
    cur = conn.cursor()
    print("Running VACUUM ANALYZE essentials.geofence_boundaries...")
    cur.execute("VACUUM ANALYZE essentials.geofence_boundaries;")
    print("VACUUM ANALYZE complete.")
finally:
    conn.autocommit = False
    conn.close()
```

### EXPLAIN ANALYZE Index Scan Check
```python
# Source: based on patterns in import scripts; EXPLAIN ANALYZE output parsing
cur.execute("""
    EXPLAIN ANALYZE
    SELECT geo_id, mtfcc
    FROM essentials.geofence_boundaries
    WHERE ST_Covers(
        geometry,
        ST_SetSRID(ST_MakePoint(-118.2427, 34.0537), 4326)
    )
""")
rows = cur.fetchall()
plan_text = "\n".join(row[0] for row in rows)
if "Seq Scan" in plan_text:
    print("FAIL: Sequential scan detected — GiST index not being used")
    print(plan_text)
else:
    print("PASS: No sequential scan detected (Index Scan confirmed)")
```

### Full-Hierarchy PIP Query (based on geofence_lookup.go FindGeoIDsByPoint)
```python
# Source: geofence_lookup.go FindGeoIDsByPoint + FindPoliticiansByGeoMatches
cur.execute("""
    SELECT DISTINCT
        p.full_name,
        p.party,
        o.title as office_title,
        d.district_type,
        d.geo_id,
        gb.mtfcc,
        d.ocd_id
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.districts d ON o.district_id = d.id
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
    WHERE ST_Covers(
        gb.geometry,
        ST_SetSRID(ST_MakePoint(%s, %s), 4326)
    )
    AND p.is_active = true
    ORDER BY d.district_type, p.full_name
""", (lng, lat))
```
**Note:** The MTFCC disambiguation logic in `FindPoliticiansByGeoMatches` (preventing G5210/G5220 cross-match) is needed for production correctness but may be simplified in validation since LA County addresses won't have SLDU/SLDL geo_id conflicts. Use the simplified form above for the validation script.

### Confirming GiST Index Exists
```sql
-- Check index exists before running VACUUM/EXPLAIN
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'geofence_boundaries'
  AND schemaname = 'essentials'
  AND indexdef LIKE '%gist%';
-- Expected: at least one row with USING gist (geometry)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| ST_Contains for boundary matching | ST_Covers | Phase 32 | Points exactly on boundary now match (ST_Contains returns FALSE for boundary-coincident points) |
| G4020 for supervisor geofences | X0001 MTFCC | Phase 35-01 | Supervisors join as district_type=LOCAL, not COUNTY |
| Individual ZIP-by-ZIP queries | Address search via SearchPoliticians → FindGeoIDsByPoint | Post v1.5 | Address search hits geofence_boundaries directly, bypassing BallotReady API for pre-populated regions |

## Address Selection Recommendations

### Required VAL-01 Addresses (3)

**1. Incorporated City Address — Pasadena City Hall**
- Coordinates: 34.1478, -118.1445
- Address: 100 N Garfield Ave, Pasadena, CA 91101
- Expected tiers: federal (US Rep CD28), state_senate (SD25), state_assembly (AD41), county (Supervisor D5 Barger), city (Pasadena council ward), school (Pasadena USD)
- Why chosen: Mid-size city with ward-level boundaries imported (7 wards), distinct from LA City, clear 6-tier hierarchy

**2. Unincorporated Area — East LA**
- Coordinates: 34.0239, -118.1726
- Address: 4801 E 3rd St, Los Angeles, CA 90022 (East LA — unincorporated)
- Expected tiers: federal, state_senate, state_assembly, county (Supervisor D1 Solis), school (LAUSD)
- NOT expected: city_council (unincorporated — no incorporated city boundary)
- Why chosen: Already used as PIP test in scrape_la_officials.py; confirmed to return supervisor correctly

**3. Boundary Edge — City Limit of Pasadena/Unincorporated San Marino Area**
- Coordinates: 34.1161, -118.1003
- Address: Near Pasadena/Arcadia city limit boundary
- Key requirement: Must return at least federal + state + county — must not return empty
- Why chosen: Tests ST_Covers behavior at boundary; PostGIS ST_Covers returns TRUE for boundary-coincident points (Phase 32 fix confirmed correct)

### Additional Addresses for VAL-04 (10-20 total)
Recommended selection to cover geographic spread and edge cases:

| Address | Lat | Lng | Key Test |
|---------|-----|-----|----------|
| LA City Hall (Downtown) | 34.0537 | -118.2427 | LA City council + mayor + LAUSD (already in PIP tests) |
| Long Beach City Hall | 33.7701 | -118.1937 | Long Beach council wards (imported Phase 35) |
| Glendale City Hall | 34.1425 | -118.2551 | Glendale USD school board check |
| Compton City Hall | 33.8958 | -118.2201 | South county: Supervisor D2 (Mitchell) |
| Lancaster City Hall | 34.6987 | -118.1365 | North county: Supervisor D5 (Barger) |
| Malibu City Hall | 34.0319 | -118.6896 | West county: small city |
| Inglewood City Hall | 33.9617 | -118.3531 | Inglewood council (imported with geometry_dissolved) |
| Torrance City Hall | 33.8361 | -118.3406 | Torrance council wards (imported Phase 35) |
| West Covina City Hall | 34.0686 | -117.9390 | East county: West Covina council |
| Willowbrook (unincorporated) | 33.9158 | -118.2226 | Unincorporated: county + school, no city council |
| Santa Clarita City Hall | 34.3917 | -118.5426 | Gap city: city council ABSENT (expected — no boundaries) |
| Altadena (unincorporated) | 34.1900 | -118.1320 | Unincorporated near Pasadena |
| Marina del Rey | 33.9804 | -118.4517 | Unincorporated coastal area |

**Notes on gap cities in the address list:**
- Santa Clarita is included as a geographic-spread address but must NOT require city council tier (gap city per Phase 35)
- Downey, El Monte, Palmdale, Pomona — can be omitted from address list to avoid false failures, OR included with explicit "no city council expected" flag

## IMPORT-PIPELINE.md Runbook Structure

The runbook should cover these sections to serve as a future-region guide:

```
# LA County Data Import Pipeline Runbook

## Overview
## Prerequisites
  - Python 3.10+, virtual environment setup
  - Supabase direct connection (port 5432 — NOT pooler port 6543)
  - TIGER shapefile downloads (sources and vintage)
  - Required Python packages (requirements.txt)

## Phase 1: Schema Setup
  - Run Go backend with AutoMigrate to create tables
  - Verify geofence_boundaries has (geo_id, mtfcc) unique constraint
  - Verify ST_Covers is used in geofence_lookup.go

## Phase 2: TIGER Shapefile Import (Federal, State, School, City Boundaries)
  - Download sources (Census TIGER FTP URLs)
  - Run import_ca_legislative_geofences.py (G5200, G5210, G5220)
  - Run import_ca_place_boundaries.py (G4110)
  - Run import scripts for G5420 (school districts)
  - Verification queries

## Phase 3: Local Geofence Import (County Supervisor + City Council Wards)
  - LA County supervisor districts (ArcGIS, X0001 MTFCC)
  - LA City council wards (ArcGIS, X0001 MTFCC)
  - Other city council wards (arcgis_sources.json driven)
  - Gap documentation when ArcGIS sources unavailable

## Phase 4: Politician Data Gap-Fill
  - geo_id population (gap_fill_geo_ids.py)
  - Scrape county supervisors + city officials (scrape_la_officials.py)
  - City councils for remaining cities (scrape_city_councils.py)
  - School board members (scrape_school_boards.py)

## Phase 5: Validation and Performance
  - Run VACUUM ANALYZE
  - Confirm GiST index scan
  - Run validation script (validate_la_county.py)
  - Interpret pass/fail report

## What Varies by Region
  - State FIPS code (06 for CA)
  - TIGER vintage year (2024 for v1.6 — update annually)
  - ArcGIS source URLs (county-specific)
  - Known gaps (document in sources config)
  - External ID range (avoid collision with existing ranges)
```

## Open Questions

1. **GiST index name on geofence_boundaries**
   - What we know: GeofenceBoundary model has `gorm:"type:geometry(Geometry,4326)"` — GORM AutoMigrate creates a GiST index automatically for PostGIS geometry columns in most configurations.
   - What's unclear: Whether GORM actually created the GiST index, or if it was created manually. Need to verify via `pg_indexes` query against the actual database.
   - Recommendation: The validation script should query `pg_indexes` first and print the index name before running EXPLAIN ANALYZE. If no GiST index found, alert and create one: `CREATE INDEX ON essentials.geofence_boundaries USING gist (geometry);`

2. **Federal tier for district-specific officials (US House)**
   - What we know: `fetchStatewideFromDB` returns NATIONAL_EXEC and NATIONAL_UPPER but NOT NATIONAL_LOWER (US House). NATIONAL_LOWER comes from geofence match (G5200, Congressional districts).
   - What's unclear: Whether Congressional district (G5200) boundaries are correctly imported and linked to active US House members for LA County districts (CA CDs 25-44 cover LA County).
   - Recommendation: Include an explicit check for NATIONAL_LOWER in the federal tier validation; if absent, this points to a gap in the BallotReady cache for CA US House seats.

3. **Supabase session timeout during VACUUM ANALYZE**
   - What we know: VACUUM ANALYZE on a large table can take 30-120 seconds. Supabase direct connections should stay alive.
   - What's unclear: Whether geofence_boundaries is large enough for timeout risk (estimated ~2000-3000 rows after all LA County imports — probably fast).
   - Recommendation: Low risk given row counts. Proceed normally.

## Sources

### Primary (HIGH confidence)
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/geofence_lookup.go` — FindGeoIDsByPoint and FindPoliticiansByGeoMatches: exact production PIP query + MTFCC disambiguation logic
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/scrape_la_officials.py` — verify_point_in_polygon() pattern: established PIP test structure
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/scrape_school_boards.py` — verify_pip_tests() pattern: school-board-specific PIP test structure
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/utils.py` — load_env, get_connection pattern
- `/Users/chrisandrews/Documents/GitHub/.planning/STATE.md` — v1.6 decisions, constraints, gap city documentation
- `/Users/chrisandrews/Documents/GitHub/.planning/phases/35-.../35-02-SUMMARY.md` — gap cities confirmed: Santa Clarita, Downey, El Monte, Palmdale, Pomona
- `/Users/chrisandrews/Documents/GitHub/.planning/phases/37-.../37-02-SUMMARY.md` — LAUSD whole-district behavior (all 7 members for any LAUSD address)
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/handlers.go` — SearchPoliticians: production lookup chain including statewide supplement

### Secondary (MEDIUM confidence)
- PostgreSQL documentation on VACUUM ANALYZE: cannot run inside transaction, requires autocommit=True in psycopg2
- PostGIS documentation on ST_Covers vs ST_Contains: ST_Covers returns TRUE for boundary-coincident points; ST_Contains does not

### Tertiary (LOW confidence)
- GORM AutoMigrate GiST index creation behavior: not verified against actual DB; recommend checking pg_indexes at validation time

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — uses exact tools and patterns established in Phases 33-37
- Architecture: HIGH — builds directly on verified patterns from prior phase scripts
- Pitfalls: HIGH — specific to confirmed decisions in STATE.md and SUMMARY files from prior phases
- Address selection: MEDIUM — coordinates verified via known city hall locations; boundary edge address needs coordinate verification at runtime

**Research date:** 2026-02-24
**Valid until:** 2026-04-24 (stable — no fast-moving dependencies; gap city list based on 2026-02-24 ArcGIS survey)
