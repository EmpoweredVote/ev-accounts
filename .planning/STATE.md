# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-23)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** v1.6 LA County Full Coverage — Phase 38 (VACUUM ANALYZE)

## Current Position

Phase: 37 of 38 (Politician Gap-Fill — City Councils and School Boards)
Plan: 2 of 2 in current phase
Status: Complete (Plan 01 and Plan 02 both complete)
Last activity: 2026-02-24 — Phase 37 Plan 02 complete (79 LA County school districts scraped, 402 school board members, 100% coverage, POL-04 satisfied)

Progress: [████████░░] 85% (v1.6 phases 32-38, 6/7 phases complete, Phase 38 pending)

## Performance Metrics

**Velocity (v1.0):** 7 phases, 21 plans
**Velocity (v1.1):** 3 phases, 3 plans
**Velocity (v1.2):** 6 phases, 12 plans, 27 tasks
**Velocity (v1.3):** 4 phases, 7 plans
**Velocity (v1.4):** 5 phases, 9 plans
**Velocity (v1.5):** 6 phases, 13 plans, 25 tasks
**Velocity (v1.6):** Phase 32 — 1 plan, 2 tasks, 2 files, ~1 min; Phase 33 — 1 plan, 2 tasks, 6 files, ~5 min; Phase 34 — 1 plan, 2 tasks, 1 file, ~2 min; Phase 35 Plan 01 — 2 tasks, 3 files, ~4 min; Phase 35 Plan 02 — 2 tasks, 2 files, ~8 min; Phase 36 Plan 01 — 2 tasks, 5 files, ~2 min; Phase 36 Plan 02 — 2 tasks, 3 files, ~15 min; Phase 37 Plan 01 — 2 tasks, 3 files, ~120 min; Phase 37 Plan 02 — 2 tasks, 2 files, ~90 min

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
All v1.0–v1.5 decisions resolved — see `.planning/milestones/` for full history.

**v1.6 Decisions (Phase 32):**
- [32-01] Use `id DESC` (not `imported_at DESC`) for geofence dedup ordering — imported_at may be NULL for pre-existing rows
- [32-01] Dedup error uses log.Printf warning (not Fatal) — table may not exist on fresh database, expected behavior
- [32-01] ST_Covers replaces ST_Contains — identical argument order, Covers returns TRUE for boundary-coincident points
- [32-01] G4120 maps to LOCAL/LOCAL_EXEC (same as G4110) — consolidated cities use identical BallotReady district types as incorporated places
- [32-01] G5400/G5410 map to SCHOOL — all school district variants use the same BallotReady district type as G5420

**v1.6 Decisions (Phase 33):**
- [33-01] v1.6 synthetic external IDs start at -200001 (not -100001) to avoid collision with v1.5 promote_scraped_officials.py range
- [33-01] urllib.parse imports stay inside get_engine() body in utils.py — matches the existing pattern
- [33-01] promote_scraped_officials.py not refactored — v1.5 one-time script kept isolated from pipeline infrastructure
- [33-01] No __init__.py added to scripts/ — scripts run directly, not imported as package

**v1.6 Decisions (Phase 34):**
- [34-01] NAMELSAD column used for G4110 name field (e.g., "Los Angeles city") — matches legislative script pattern, more descriptive than NAME
- [34-01] ocd_id left NULL for G4110 — consistent with Indiana G4110 records; geofence_lookup.go uses geo_id not ocd_id
- [34-01] No FUNCSTAT filter applied — CA G4110 count of exactly 482 is within expected range (450-520)

**v1.6 Decisions (Phase 35 Plan 01):**
- [35-01] Use X0001 MTFCC (not G4020) for supervisor district geofences — G4020 maps to COUNTY/JUDICIAL, but LA supervisors are district_type=LOCAL; X0001 maps to LOCAL
- [35-01] OCD-ID string used as geo_id for X0001 boundaries — direct match to essentials.districts.ocd_id confirmed by DB query, enables Phase 36 join
- [35-01] Direct ALTER TABLE to widen geo_id to varchar(255) — GORM AutoMigrate does not widen existing varchar columns
**v1.6 Decisions (Phase 35 Plan 02):**
- [35-02] Long Beach council districts sourced from services6.arcgis.com/yCArG7wGXGyWLqav (ArcGIS item c21dc4adc0d344c49a3298e3bc4adeb3) — COUNCIL_NUMBER field (integer 1-9)
- [35-02] Torrance DISTRICTID and West Covina DISTRICT fields contain "District N" strings — added district_field_format config key and parse_district_number() to import script
- [35-02] Inglewood CD=2 appears twice in source (two polygons) — dissolved via unary_union, quality_flag=geometry_dissolved
- [35-02] West Covina service layer is ID 2 (not 0) — inspect /FeatureServer?f=json to confirm layer IDs before hardcoding /0
- [35-02] 5 cities documented as gaps: Santa Clarita, Downey, El Monte, Palmdale, Pomona — no ArcGIS FeatureServer found

**v1.6 Decisions (Phase 36 Plan 01):**
- [36-01] IsActive on Politician means currently serving in primary seat — distinct from ElectionRecord.IsActive which tracks active race candidacy
- [36-01] gap_fill_geo_ids.py uses geo_id = ocd_id for LOCAL districts; geo_id = '0644000' (Census GEOID) for LA City mayor LOCAL_EXEC to match Phase 34 G4110 geofence
- [36-01] Rule 1 auto-fix: ProviderBallotReady const and BallotReadyKey/Endpoint fields added to provider/config.go — pre-existing omission that blocked go build ./...

**v1.6 Decisions (Phase 36 Plan 02):**
- [36-02] rapidfuzz replaces python-Levenshtein — same Levenshtein API surface, builds cleanly on macOS without C extension compilation issues
- [36-02] Fuzzy last-name threshold = 1 (not 2) — short names like "Hahn" are too collision-prone at threshold 2; tight threshold confirmed by RESEARCH.md Pitfall 5
- [36-02] Curren D. Price Jr. treated as new person in D9 seat — name-with-suffix differs from "Curren D. Price"; old record deactivated, new record inserted per seat-first dedup logic
- [36-02] Photo re-hosting to Supabase Storage deferred — photo_origin_url stores scraped URL; download+re-host is a distinct infrastructure concern

**v1.6 Decisions (Phase 37 Plan 01):**
- [37-01] 5 district-election cities (Long Beach, Torrance, Pasadena, Inglewood, West Covina) treated as at-large — SOS PDF provides district=0 for all members; per-ward assignment deferred
- [37-01] District lookup must filter by district_type to avoid at-large council reusing LOCAL_EXEC mayor district (both share same ocd_id_base)
- [37-01] is_multi_seat dedup for at-large council: name-match only, no seat replacement for mismatches — all members share one ocd_id
- [37-01] verify_no_duplicates groups by (ocd_id, title, name) — rotating mayors legitimately hold both Mayor and Council Member offices

**v1.6 Decisions (Phase 37 Plan 02):**
- [37-02] Hardcoded roster strategy used — school district websites universally blocked by Cloudflare/CDN; verified Feb 2026 board member names from public records
- [37-02] LAUSD whole-district boundary — all 7 board members share geo_id='0622710'; trustee area sub-boundaries not found in public ArcGIS as of 2026-02-24
- [37-02] Duplicate district IDs fixed: el_monte_city/el_monte_union_high and whittier_city/whittier_union_high — original CDE ArcGIS slugs were non-unique
- [37-02] OCD-ID LIKE pattern uses ':' not '/' before slug: 'ocd-division/country:us/state:ca/school_district:%'

### Key v1.6 Constraints

- Phase 32 (schema) must complete before any import work — wrong unique constraint silently destroys multi-layer imports
- Phase 33 (utils) must complete before new import scripts — prevents sixth copy of `get_engine()` duplication
- Geofences (Phases 34-35) must complete before politicians (Phases 36-37) — geo_id join dependency
- TIGER sources (Phase 34) before ArcGIS sources (Phase 35) — different integration patterns, TIGER is lower risk
- VACUUM ANALYZE (Phase 38) must be last step after all bulk inserts
- Supabase direct connection only (port 5432) — pooler breaks bulk imports
- Import UNSD (G5420) only, never G5400/G5410 — prevents school board triple-match in LAUSD areas
- Synthetic external IDs start at -200001 — avoids collision with v1.5 -100001-range IDs

### Pending Todos

None.

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-02-24
Stopped at: Completed 37-02-PLAN.md — hardcoded roster batch importer executed; 79/79 LA County school districts scraped, 402 active board members, 0 duplicates, PIP tests pass (LAUSD: 7, Glendale: 5); POL-04 satisfied; ready for Phase 38 (VACUUM ANALYZE)
Resume file: None
