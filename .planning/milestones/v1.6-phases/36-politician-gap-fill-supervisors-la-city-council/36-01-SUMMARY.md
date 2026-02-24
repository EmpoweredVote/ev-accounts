---
phase: 36-politician-gap-fill-supervisors-la-city-council
plan: 01
subsystem: database
tags: [go, gorm, postgresql, python, psycopg2, geofence, schema-migration]

# Dependency graph
requires:
  - phase: 35-la-county-arcgis-geofences-supervisor-districts-and-city-council-wards
    provides: "X0001 geofences for supervisor districts and city council wards with ocd_id as geo_id"
  - phase: 34-tiger-place-boundaries
    provides: "G4110 LA city boundary with geo_id='0644000' for mayor district match"
provides:
  - "is_active and data_source columns on essentials.politicians (via AutoMigrate + explicit ALTER TABLE script)"
  - "gap_fill_geo_ids.py script: idempotent schema migration + geo_id population for all CA LOCAL/LOCAL_EXEC districts"
  - "beautifulsoup4 and python-Levenshtein pinned in requirements.txt for Plan 02 scraper"
  - "Go build fixed: ProviderBallotReady constant and BallotReadyKey/Endpoint config fields added to provider package"
affects:
  - "36-02 — gap_fill_geo_ids.py must run before scraper inserts politicians"
  - "37 — politician gap-fill for remaining cities"

# Tech tracking
tech-stack:
  added:
    - "beautifulsoup4==4.12.3 (HTML parsing for government sites)"
    - "python-Levenshtein==0.25.1 (fuzzy name matching for dedup)"
  patterns:
    - "psycopg2 direct connection via keyword args — handles special chars in passwords without URL-encoding"
    - "register_uuid() at module level — consistent with promote_scraped_officials.py"
    - "from utils import load_env — shared .env.local loading across all scripts"
    - "RETURNING clause on UPDATE for progress logging without separate SELECT"

key-files:
  created:
    - "EV-Backend/scripts/gap_fill_geo_ids.py"
  modified:
    - "EV-Backend/internal/essentials/models.go"
    - "EV-Backend/scripts/requirements.txt"
    - "EV-Backend/internal/essentials/provider/config.go"
    - "EV-Backend/internal/essentials/provider/provider.go"

key-decisions:
  - "IsActive on Politician means currently serving in primary seat — distinct from ElectionRecord.IsActive which tracks active race candidacy"
  - "gap_fill_geo_ids.py uses geo_id = ocd_id for LOCAL districts (all CA cities), geo_id = '0644000' for LOCAL_EXEC mayor (Census GEOID to match Phase 34 G4110 import)"
  - "Rule 1 auto-fix: ProviderBallotReady and BallotReadyKey/BallotReadyEndpoint added to provider/config.go — pre-existing omission that broke go build ./..."

patterns-established:
  - "gap_fill_geo_ids.py: two-part script pattern (schema migration then data fix) with idempotent WHERE clauses"
  - "LOCAL geo_id = ocd_id: direct assignment for all CA LOCAL district geofence matching"
  - "LOCAL_EXEC geo_id = Census GEOID: mayor uses place GEOID, not OCD-ID, to match TIGER G4110 import"

requirements-completed: [POL-01, POL-02, POL-05]

# Metrics
duration: 2min
completed: 2026-02-24
---

# Phase 36 Plan 01: Schema Migration and Geo-ID Fix Summary

**is_active/data_source added to politicians table via Go model + idempotent Python migration script; geo_id populated for all CA LOCAL/LOCAL_EXEC districts enabling Phase 35 geofence-politician join chain**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-24T17:49:37Z
- **Completed:** 2026-02-24T17:51:55Z
- **Tasks:** 2
- **Files modified:** 5 (4 modified, 1 created)

## Accomplishments
- Politician Go struct extended with `IsActive` (bool, GORM default:true) and `DataSource` (string) for inactive-officeholder tracking and provenance
- `gap_fill_geo_ids.py` created: idempotent schema migration + geo_id population for all CA LOCAL districts (supervisors + all Phase 35 city council wards) in a single UPDATE pass
- LA City mayor (LOCAL_EXEC) geo_id set to `'0644000'` (Census GEOID) to match Phase 34 G4110 geofence boundary
- `beautifulsoup4==4.12.3` and `python-Levenshtein==0.25.1` pinned in requirements.txt for Plan 02 scraper

## Task Commits

Each task was committed atomically:

1. **Task 1: Schema migration and Go model update** - `e343ab2` (feat)
2. **Task 2: Create gap_fill_geo_ids.py** - `3120489` (feat)

**Plan metadata:** `[docs commit]` (docs: complete plan)

## Files Created/Modified
- `EV-Backend/internal/essentials/models.go` - Added IsActive and DataSource fields to Politician struct in Provenance/Syncing section
- `EV-Backend/scripts/requirements.txt` - Added beautifulsoup4==4.12.3 and python-Levenshtein==0.25.1
- `EV-Backend/scripts/gap_fill_geo_ids.py` - New script: schema migration + CA LOCAL geo_id fix + LA City mayor geo_id fix + verification queries
- `EV-Backend/internal/essentials/provider/config.go` - Rule 1 auto-fix: added ProviderBallotReady const, BallotReadyKey, BallotReadyEndpoint fields
- `EV-Backend/internal/essentials/provider/provider.go` - Rule 1 auto-fix: added ErrMissingBallotReadyKey error var

## Decisions Made
- `IsActive` on `Politician` means "currently serving in their primary seat" — distinct from `ElectionRecord.IsActive` which means "active in a race"
- `gap_fill_geo_ids.py` uses `geo_id = ocd_id` for all LOCAL districts (works for Phase 35 geofences where ocd_id was stored as geo_id in X0001 records)
- LA City mayor uses `geo_id = '0644000'` (Census GEOID) not OCD-ID — must match the G4110 boundary imported in Phase 34
- `DataSource` field added alongside `Source` and `LastSynced` for data provenance tracking (values: "ballotready", "scraped", "manual")

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed missing BallotReady provider constants in provider/config.go**
- **Found during:** Task 1 (Go build verification)
- **Issue:** `ballotready/provider.go` references `provider.ProviderBallotReady`, `cfg.BallotReadyKey`, and `cfg.BallotReadyEndpoint` — none of which existed in `provider/config.go`. Build was broken before my changes and remained broken after (pre-existing omission from BallotReady migration work)
- **Fix:** Added `ProviderBallotReady ProviderType = "ballotready"` constant; added `BallotReadyKey string` and `BallotReadyEndpoint string` fields to Config struct; updated `LoadFromEnv()` to read `BALLOTREADY_API_KEY` and `BALLOTREADY_ENDPOINT`; added `ErrMissingBallotReadyKey` error; updated `Validate()` to check BallotReady key; updated `LoadFromEnv()` default to `ProviderBallotReady` (consistent with completed BallotReady migration)
- **Files modified:** `EV-Backend/internal/essentials/provider/config.go`, `EV-Backend/internal/essentials/provider/provider.go`
- **Verification:** `go build ./...` passes cleanly
- **Committed in:** `e343ab2` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — pre-existing build breakage)
**Impact on plan:** Fix was required for plan verification step (`go build ./...`). Correctly wires the BallotReady provider into the registry pattern that was already in place. No scope creep.

## Issues Encountered
- `go build ./...` failed before any changes due to `ballotready/provider.go` referencing undefined symbols in `provider/config.go` — fixed inline per Rule 1 since it blocked plan verification

## User Setup Required
None - no external service configuration required. `gap_fill_geo_ids.py` must be executed against the DB in Plan 02 (not yet run).

## Next Phase Readiness
- `gap_fill_geo_ids.py` is ready to run; Plan 02 executes it against the DB before scraping
- Go model will AutoMigrate `is_active` and `data_source` columns on next server start
- All CA LOCAL district geo_id fix covers all Phase 35 geofences in a single pass
- `beautifulsoup4` and `python-Levenshtein` ready for Plan 02 scraper work

## Self-Check: PASSED

All files confirmed present. Commits verified in EV-Backend repository.

| Item | Status |
|------|--------|
| EV-Backend/scripts/gap_fill_geo_ids.py | FOUND |
| EV-Backend/internal/essentials/models.go | FOUND |
| EV-Backend/scripts/requirements.txt | FOUND |
| 36-01-SUMMARY.md | FOUND |
| Commit e343ab2 (Task 1) | FOUND (in EV-Backend) |
| Commit 3120489 (Task 2) | FOUND (in EV-Backend) |

---
*Phase: 36-politician-gap-fill-supervisors-la-city-council*
*Completed: 2026-02-24*
