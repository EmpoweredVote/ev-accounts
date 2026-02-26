---
phase: 43-go-api-and-frontend-updates
plan: 01
subsystem: api
tags: [go, gorm, chi, rest-api, contacts, building-photo]

# Dependency graph
requires:
  - phase: 41-candidacy-and-contacts
    provides: PoliticianContact table populated with phone/email/website data from BallotReady
  - phase: 39-city-hall-building-photos
    provides: BuildingPhoto table populated with city hall photos

provides:
  - GET /essentials/politician/{id} response now includes contacts array (phone, email, fax, website_url, synced_at)
  - GET /essentials/cities/{geo_id}/building-photo endpoint returning photo JSON by Census GEOID
  - ContactOut DTO for frontend consumption
  - ContactSyncedAt *time.Time field on PoliticianContact model for tracking scraper sync time

affects:
  - 43-02 (frontend contact section — consumes the contacts array from this plan)
  - essentials frontend Profile page

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Empty contact row filtering: skip rows where all of phone/email/fax/website_url are blank"
    - "Pointer type *time.Time for nullable timestamps: GORM distinguishes nil (never set) from zero time"

key-files:
  created: []
  modified:
    - EV-Backend/internal/essentials/models.go
    - EV-Backend/internal/essentials/handlers.go
    - EV-Backend/internal/essentials/routes.go

key-decisions:
  - "ContactSyncedAt uses *time.Time pointer so GORM treats nil (NULL in DB) as never-set, distinct from zero time; omitempty on pointer omits nil from JSON"
  - "Empty contact rows filtered server-side (all of phone/email/fax/website_url blank) to avoid frontend needing to handle degenerate rows"
  - "GetBuildingPhoto returns map[string]interface{} directly rather than a named DTO — simple enough that a DTO adds no value"

patterns-established:
  - "7b step numbering: inserted new fetch steps between existing numbered steps use letter suffixes (7b) to avoid renumbering"

requirements-completed: [CONT-04]

# Metrics
duration: 2min
completed: 2026-02-26
---

# Phase 43 Plan 01: Go API Contacts + Building Photo Summary

**Contacts array wired into GET /essentials/politician/{id} response and new GET /essentials/cities/{geo_id}/building-photo endpoint added — all data from existing DB tables, zero new dependencies**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-26T01:21:49Z
- **Completed:** 2026-02-26T01:23:48Z
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments
- Added `ContactSyncedAt *time.Time` field to `PoliticianContact` model — AutoMigrate will add the nullable column; all existing rows default to NULL
- Created `ContactOut` DTO and wired contacts fetch into `GetPoliticianByID` with empty-row filtering (skips rows where all of phone/email/fax/website_url are blank)
- Added `GetBuildingPhoto` handler and registered `GET /cities/{geo_id}/building-photo` route — returns 404 for unknown geo_ids

## Task Commits

Each task was committed atomically:

1. **Task 1: Add ContactSyncedAt to model, ContactOut DTO, contacts fetch in GetPoliticianByID, and building photo endpoint** - `2c7c3e1` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `EV-Backend/internal/essentials/models.go` - Added `ContactSyncedAt *time.Time` to `PoliticianContact` struct
- `EV-Backend/internal/essentials/handlers.go` - Added `ContactOut` DTO, updated `PoliticianProfileOut` with `Contacts []ContactOut`, added contacts fetch step 7b in `GetPoliticianByID`, added `GetBuildingPhoto` handler
- `EV-Backend/internal/essentials/routes.go` - Registered `GET /cities/{geo_id}/building-photo` route

## Decisions Made
- `ContactSyncedAt` uses `*time.Time` pointer type so GORM maps NULL DB values to nil Go value, cleanly distinguishing "never set" from zero time. The `omitempty` JSON tag on a pointer omits nil from responses.
- Empty contact rows are filtered server-side: if all of `phone`, `email`, `fax`, `website_url` are blank strings, the row is skipped and not included in the `contacts` array. This ensures the frontend never receives degenerate rows.
- `GetBuildingPhoto` returns a `map[string]interface{}` directly (not a named DTO) — the response shape is simple and fixed, no downstream code needs to reference the DTO type.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - Go build succeeded on first attempt with zero errors.

## User Setup Required

None - no external service configuration required. AutoMigrate will add the `contact_synced_at` nullable column to the `essentials.politician_contacts` table on next server start.

## Next Phase Readiness

- Backend API is ready for frontend integration: contacts array is present in all `/essentials/politician/{id}` responses (empty array `[]` for politicians with no contact data, populated for those with data)
- Building photo endpoint is ready for frontend city hall photo display
- Plan 43-02 (frontend contact section) can now consume `contacts` from the profile API response

## Self-Check: PASSED

All created/modified files verified present on disk. Task commit `2c7c3e1` verified in git log.

---
*Phase: 43-go-api-and-frontend-updates*
*Completed: 2026-02-26*
