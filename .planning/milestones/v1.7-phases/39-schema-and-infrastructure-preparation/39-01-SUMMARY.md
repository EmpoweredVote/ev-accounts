---
phase: 39-schema-and-infrastructure-preparation
plan: 01
subsystem: database
tags: [gorm, postgresql, essentials, schema, migration, building-photos, politician-images]

# Dependency graph
requires: []
provides:
  - BuildingPhoto GORM model with PlaceGeoid primary key and essentials.building_photos TableName
  - PhotoLicense string field on PoliticianImage (backward-compatible, omitempty JSON tag)
  - TermDatePrecision string field on Politician (backward-compatible, omitempty JSON tag)
  - BuildingPhoto registered in AutoMigrate — table created on next server start
affects:
  - 40-headshot-enrichment
  - 41-building-photo-enrichment
  - 42-term-dates-enrichment
  - 43-contact-enrichment
  - 44-data-validation

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Additive-only GORM schema changes: new struct appended after existing models, TableName follows all other TableName functions at file bottom"
    - "omitempty JSON tags on all new string fields for backward-compatible API responses"
    - "Phase comment in AutoMigrate list to track when each model was added"

key-files:
  created: []
  modified:
    - EV-Backend/internal/essentials/models.go
    - EV-Backend/internal/essentials/setup.go

key-decisions:
  - "BuildingPhoto uses PlaceGeoid (Census GEOID string, size:20) as primary key — no UUID needed since GEOIDs are globally unique stable identifiers"
  - "PhotoLicense and TermDatePrecision use omitempty JSON tags so existing API consumers receive no change unless fields are populated"
  - "BuildingPhoto placed at end of models.go struct definitions, before TableName block — maintains file organization pattern"

patterns-established:
  - "Phase comment pattern in AutoMigrate: // Phase NN: description above each phase's entries"

requirements-completed: [PIPE-01]

# Metrics
duration: 2min
completed: 2026-02-25
---

# Phase 39 Plan 01: Schema Prerequisites Summary

**Added BuildingPhoto table, photo_license column on politician_images, and term_date_precision column on politicians — all three schema prerequisites for v1.7 enrichment phases 40-44**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-25T01:01:53Z
- **Completed:** 2026-02-25T01:03:02Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added BuildingPhoto GORM model keyed by PlaceGeoid (Census GEOID) targeting essentials.building_photos table
- Added PhotoLicense field to PoliticianImage with omitempty JSON tag for backward-compatible headshot license tracking
- Added TermDatePrecision field to Politician with omitempty JSON tag enabling "year"/"month"/"day" display precision
- Registered BuildingPhoto in AutoMigrate so the table is created on next server start
- Go build verified passing with all changes

## Task Commits

Each task was committed atomically:

1. **Task 1: Add BuildingPhoto model, PhotoLicense column, and TermDatePrecision column to GORM models** - `6264f71` (feat)
2. **Task 2: Register BuildingPhoto in AutoMigrate** - `f0d6049` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `EV-Backend/internal/essentials/models.go` - Added BuildingPhoto struct, PhotoLicense on PoliticianImage, TermDatePrecision on Politician, BuildingPhoto TableName function
- `EV-Backend/internal/essentials/setup.go` - Added &BuildingPhoto{} to AutoMigrate list with phase comment

## Decisions Made

- BuildingPhoto uses PlaceGeoid (Census GEOID string, size:20) as primary key rather than a UUID — GEOIDs are stable, globally unique government identifiers that serve as natural PKs without needing surrogate keys
- New fields use omitempty JSON tags so the API remains backward-compatible — consumers that don't know about the fields receive no change when fields are empty
- BuildingPhoto struct placed after PositionDescription (last existing struct) and before the TableName block — consistent with existing file organization

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

EV-Backend is its own separate git repository (not tracked by the workspace root repo). Commits were made using `git -C /Users/chrisandrews/Documents/GitHub/EV-Backend` targeting the correct repo. No functional issues.

## User Setup Required

None - no external service configuration required. New columns and table will be created automatically by GORM AutoMigrate on next server start against the configured DATABASE_URL.

## Next Phase Readiness

- Schema prerequisites complete — all three columns/tables exist before any enrichment script runs
- Phase 40 (headshot enrichment) can now store photo_license values on politician_images
- Phase 41 (building photo enrichment) can now write to essentials.building_photos
- Phase 42 (term dates) can now store term_date_precision on politicians
- No blockers

---
*Phase: 39-schema-and-infrastructure-preparation*
*Completed: 2026-02-25*

## Self-Check: PASSED

- FOUND: EV-Backend/internal/essentials/models.go
- FOUND: EV-Backend/internal/essentials/setup.go
- FOUND: .planning/phases/39-schema-and-infrastructure-preparation/39-01-SUMMARY.md
- FOUND commit: 6264f71 (Task 1)
- FOUND commit: f0d6049 (Task 2)
