---
phase: 73-backend-governmentbody-table
plan: 01
subsystem: database
tags: [go, gorm, postgresql, essentials, geofence, politicians]

# Dependency graph
requires:
  - phase: 72-db-audit
    provides: confirmed chamber_name_formal is empty for Indiana chambers; GovernmentBody design validated
provides:
  - GovernmentBody GORM model with composite unique index on (state, geo_id, body_key)
  - essentials.government_bodies table via AutoMigrate
  - Idempotent chamber_name_formal migration for Monroe County Council, Monroe County Commission, Bloomington Common Council
  - OfficialOut fields: government_body_name, government_body_url
  - LEFT JOIN on government_bodies in fetchOfficialsFromDB and fetchFederalAndStateFromDBFiltered
affects:
  - 74-backend-governmentbody-seed
  - 76-frontend-section-headings

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "GovernmentBody follows PositionDescription enrichment pattern: composite unique index, COALESCE LEFT JOIN in fetch functions"
    - "Idempotent data migrations via db.DB.Exec() in setup.go with WHERE name_formal = '' OR name_formal IS NULL guard"

key-files:
  created: []
  modified:
    - EV-Backend/internal/essentials/models.go
    - EV-Backend/internal/essentials/setup.go
    - EV-Backend/internal/essentials/handlers.go

key-decisions:
  - "GovernmentBody composite unique on (state, geo_id, body_key) — upsert-safe, matches PositionDescription pattern"
  - "body_key derived from COALESCE(NULLIF(c.name_formal, ''), c.name, '') — chamber name_formal takes precedence"
  - "chamber_name_formal migrations scoped with prefix LIKE patterns (e.g., 'Monroe County Council%') to avoid accidental updates to non-Indiana chambers"
  - "government_body_name and government_body_url use omitempty — empty string suppressed from JSON when no matching row"

patterns-established:
  - "Enrichment JOIN pattern: LEFT JOIN essentials.government_bodies gb ON gb.state = d.state AND gb.geo_id = d.geo_id AND gb.body_key = COALESCE(NULLIF(c.name_formal, ''), c.name, '')"
  - "Both fetchOfficialsFromDB and fetchFederalAndStateFromDBFiltered must receive identical enrichment changes"

requirements-completed: [LINK-02]

# Metrics
duration: 2min
completed: 2026-03-11
---

# Phase 73 Plan 01: GovernmentBody Table Summary

**GovernmentBody GORM model + AutoMigrate + idempotent chamber_name_formal migration + LEFT JOIN enrichment in both ZIP and address fetch functions returning government_body_name/url per official**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-11T14:46:57Z
- **Completed:** 2026-03-11T14:48:50Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Added GovernmentBody struct to models.go with composite unique index (state, geo_id, body_key) and TableName() returning essentials.government_bodies
- Wired GovernmentBody into AutoMigrate in setup.go with three idempotent UPDATE statements for Indiana chamber name_formal values
- Added government_body_name and government_body_url to OfficialOut with omitempty; both fetch functions receive identical LEFT JOIN on government_bodies returning COALESCE(empty string) when no row matches

## Task Commits

Each task was committed atomically:

1. **Task 1: GovernmentBody model + AutoMigrate + chamber_name_formal migration** - `3156bf6` (feat)
2. **Task 2: LEFT JOIN enrichment in both fetch functions + OfficialOut fields** - `2d31c9a` (feat)

## Files Created/Modified
- `EV-Backend/internal/essentials/models.go` - Added GovernmentBody struct and TableName()
- `EV-Backend/internal/essentials/setup.go` - Added GovernmentBody to AutoMigrate; added idempotent chamber_name_formal UPDATEs
- `EV-Backend/internal/essentials/handlers.go` - Added GovernmentBodyName/URL to OfficialOut, both row structs, both SQL queries, and both assembly blocks

## Decisions Made
- body_key uses COALESCE(NULLIF(c.name_formal, ''), c.name, '') — after the migration runs, Monroe County chambers will use name_formal as the join key
- chamber_name_formal migrations use narrow LIKE patterns ('Monroe County Council%') to avoid cross-state false matches
- omitempty on government_body_name/url means officials without a matching government_bodies row return clean JSON (no empty string fields)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. EV-Backend is a separate git repository from the workspace root, so commits were made in EV-Backend/ rather than the workspace root.

## User Setup Required

None - no external service configuration required. GovernmentBody table will be created on next server startup via AutoMigrate. The chamber_name_formal UPDATEs will run automatically and are idempotent.

## Next Phase Readiness

- Phase 74 (data seeding): GovernmentBody table exists, upsert-safe via (state, geo_id, body_key) unique index. Seed script can insert rows with display_name and website_url.
- Phase 76 (frontend): API now returns government_body_name and government_body_url for every official. Frontend can use government_body_name as section heading label instead of generic category label.
- After Phase 73 server starts against Supabase, run SELECT * FROM essentials.chambers WHERE name_formal != '' to confirm migration applied.

---
*Phase: 73-backend-governmentbody-table*
*Completed: 2026-03-11*
