---
phase: 76-frontend-results-integration
plan: 01
subsystem: ui
tags: [react, government-body, results, categorysection, bloomington, split-by-body]

# Dependency graph
requires:
  - phase: 75-ev-ui-categorysection-update
    provides: CategorySection websiteUrl prop
  - phase: 74-data-seeding
    provides: government_bodies seed data with name_formal and URLs
  - phase: 73-backend-governmentbody-table
    provides: government_body_name/url fields in API response

provides:
  - splitByBodyName helper in Results.jsx sub-groups politicians by government_body_name
  - Distinct section headings per government body (Monroe County Council, Bloomington Common Council, etc.)
  - Website link icons per body section
  - Backend SearchPoliticians endpoint also returns government_body_name (deviation fix)

affects: [essentials, ev-backend]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "splitByBodyName: render-time sub-grouping of polList by government_body_name; named groups first alphabetically, unnamed falls back to getDisplayName(category)"
    - "Composite React key: category-title-idx prevents collisions when multiple bodies share same classify group"

key-files:
  created: []
  modified:
    - essentials/src/pages/Results.jsx
    - EV-Backend/internal/essentials/geofence_lookup.go

key-decisions:
  - "splitByBodyName is a standalone helper above the Results component — not inside useMemo or any state chain"
  - "Named sub-groups sorted alphabetically by body name for stable render order"
  - "Unnamed politicians (no government_body_name) always rendered last using getDisplayName(category) as fallback title"
  - "government_body_name never passed through qualifyLocalTitle() — prevents double-prefix bug"
  - "SearchPoliticians endpoint required same LEFT JOIN as FindPoliticiansByGeoMatches (Rule 3 auto-fix)"

patterns-established:
  - "Body-name sub-grouping: apply splitByBodyName at render time in JSX map blocks, never in data layer"

requirements-completed: [BODY-01, BODY-02, BODY-03, BODY-04, BODY-05]

# Metrics
duration: ~45min
completed: 2026-03-11
---

# Phase 76 Plan 01: Frontend Results Integration Summary

**splitByBodyName helper sub-groups local politicians by government_body_name, surfacing specific body headings (Monroe County Council, Bloomington Common Council) with website link icons across all three tier render blocks**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-03-11
- **Completed:** 2026-03-11
- **Tasks:** 2
- **Files modified:** 2 (across 2 repos)

## Accomplishments

- Added `splitByBodyName` helper to Results.jsx — renders one CategorySection per distinct `government_body_name` within each classify group
- All three tier render blocks (Local, State, Federal) updated to use the new sub-grouping pattern
- Monroe County address correctly shows "Monroe County Council" and "Monroe County Commissioners" as distinct sections
- Bloomington address shows "Bloomington Common Council" as a dedicated section heading
- Website link icons appear per sub-group section using the body's seeded URL
- LA County regression verified clean — generic fallback labels render correctly with no blank sections
- Backend `SearchPoliticians` endpoint fixed to include `government_body_name` (was missing the LEFT JOIN)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add splitByBodyName helper and update all three tier render blocks** - `87b40c8` (feat) in essentials repo
2. **Task 1 (deviation): Add government_body_name to search endpoint and seed missing bodies** - `32628b0` (feat) in EV-Backend repo
3. **Task 2: Verify body name section headings and LA County regression** - Playwright browser automation verification, user approved visually

## Files Created/Modified

- `essentials/src/pages/Results.jsx` - Added splitByBodyName helper; updated Local, State, Federal render blocks to sub-group by body name
- `EV-Backend/internal/essentials/geofence_lookup.go` - Added missing government_bodies LEFT JOIN to SearchPoliticians endpoint; seeded 6 chamber name_formal groupings and 14 government_bodies records for full Bloomington coverage

## Decisions Made

- `splitByBodyName` is placed above the Results component as a standalone function — not inside any useMemo chain — to keep data transformation strictly at render time per STATE.md guidelines
- Named sub-groups are sorted alphabetically by body name for stable, deterministic ordering
- Composite React key format `${category}-${title}-${idx}` prevents collisions when multiple bodies share a classify group
- `government_body_name` is used directly as the section title — never routed through `qualifyLocalTitle()` (avoids double-prefix bug documented in STATE.md)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added missing government_bodies LEFT JOIN to SearchPoliticians endpoint**
- **Found during:** Task 1 (after implementing splitByBodyName, testing search path showed no body names)
- **Issue:** `FindPoliticiansByGeoMatches` had the government_bodies LEFT JOIN added in Phase 73, but `SearchPoliticians` in `geofence_lookup.go` did not — the search endpoint returned officials without `government_body_name`/`government_body_url`
- **Fix:** Added government_bodies LEFT JOIN to SearchPoliticians; also seeded 6 additional chamber name_formal groupings and 14 government_bodies records covering Bloomington Common Council, Monroe County Council (with district fan-out), MCCSC, Township, Circuit Court, state appellate courts
- **Files modified:** `EV-Backend/internal/essentials/geofence_lookup.go`
- **Verification:** Playwright automation confirmed body names appear in all Bloomington sections
- **Committed in:** `32628b0` (EV-Backend repo)

---

**Total deviations:** 1 auto-fixed (Rule 3 - blocking)
**Impact on plan:** The LEFT JOIN fix was required for the feature to work at all on the search path. Seeding additional government_bodies records was necessary for full Bloomington coverage. No scope creep — all work directly enabled the plan's BODY-01 through BODY-05 requirements.

## Issues Encountered

None beyond the deviation documented above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 76 plan 01 complete — body name sub-grouping ships and is verified
- All BODY-01 through BODY-05 requirements met
- No blockers for subsequent phases

---
*Phase: 76-frontend-results-integration*
*Completed: 2026-03-11*
