---
phase: 31-essentials-profile-and-district-data-fixes
plan: "03"
subsystem: ui
tags: [react, ev-ui, essentials, geofence, postgresql, postgis]

# Dependency graph
requires:
  - phase: 31-essentials-profile-and-district-data-fixes/31-01
    provides: district_id field in all API query paths
  - phase: 31-essentials-profile-and-district-data-fixes/31-02
    provides: ev-ui@0.1.27 with PoliticianCard subtitle prop and updated PoliticianProfile

provides:
  - essentials app wired to ev-ui@0.1.27 with subtitle on politician cards
  - 3-line card layout (name, office title, chamber + district) via subtitle prop
  - Profile page stripped of Issues section, compass imports, and radar chart logic
  - Bloomington city council district boundaries (Districts 1-6) in geofence_boundaries table
affects: essentials-frontend, bloomington-council-visibility, profile-display

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Subtitle computation in renderPoliticianCard: LOCAL edge case where chamber_name === office_title falls back to district_label"
    - "undefined subtitle = 2-line fallback (PoliticianCard shows no empty 3rd line)"
    - "Bloomington council district geo_ids: 18058600000X format matching BallotReady district geo_id"

key-files:
  created: []
  modified:
    - essentials/src/pages/Results.jsx
    - essentials/src/pages/Profile.jsx
    - essentials/package.json
    - essentials/package-lock.json

key-decisions:
  - "geo_id format for Bloomington council districts: 18058600000X (12 chars) matching existing BallotReady districts table entries, not the 13-char variant in plan spec"
  - "District 2 geometry fixed with ST_MakeValid after nested shells topology warning from ArcGIS source"
  - "Boundary data sourced from Bloomington ArcGIS FeatureServer (City_Council_Districts) discovered via arcgis.com/experience/cff893f3 — official city GIS, published 2024"

patterns-established:
  - "Use district_id field (not district_type) to build subtitle; district_label as LOCAL fallback"

requirements-completed: [PROF-06, CARD-01, CARD-02, CARD-03, DIST-01, DIST-02]

# Metrics
duration: 4min
completed: 2026-02-23
---

# Phase 31 Plan 03: Essentials Frontend Integration and Bloomington District Import Summary

**3-line politician cards with chamber+district subtitles, clean profile pages without Issues section, and Bloomington city council district boundaries (Districts 1-6) imported from official city ArcGIS into geofence_boundaries**

## Performance

- **Duration:** 4 min
- **Started:** 2026-02-23T03:43:23Z
- **Completed:** 2026-02-23T03:47:35Z
- **Tasks:** 2
- **Files modified:** 4 (essentials) + 6 database rows inserted

## Accomplishments
- Updated `renderPoliticianCard` in Results.jsx to compute and pass subtitle to PoliticianCard, enabling 3-line cards (name, office title, chamber + district) with graceful 2-line fallback when no data
- Stripped Profile.jsx down to a clean fetch-and-render pattern: removed Issues and Prioritization section, RadarChartCore, IssueTags, all compass data fetching, inversion state, and useIsMobile hook
- Bumped ev-ui dependency from `^0.1.19` to `^0.1.27` in essentials/package.json
- Imported all 6 Bloomington city council district boundaries from the official Bloomington ArcGIS City_Council_Districts FeatureServer into `essentials.geofence_boundaries` with mtfcc='X0001', enabling district-level council member visibility in address search results

## Task Commits

Each task was committed atomically:

1. **Task 1: Update essentials ev-ui dependency, add subtitle to cards, remove Issues section** - `4f212d0` (feat) — in `essentials/` repo
2. **Task 2: Import Bloomington city council district boundaries** - database-only (no code commit; 6 rows inserted via psql)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `essentials/src/pages/Results.jsx` - Added `subtitle` computation in `renderPoliticianCard`: handles standard case (chamber + ", District " + id) and LOCAL edge case (chamber_name === office_title → use district_label); passes `subtitle={subtitle}` (undefined when no data → 2-line fallback)
- `essentials/src/pages/Profile.jsx` - Stripped from 271 lines to 83 lines: removed Issues and Prioritization div, RadarChartCore, IssueTags, fetchTopics, fetchPoliticianAnswers, buildAnswerMapByShortTitle, useIsMobile, topics/answersByShort/loadingCompass/invertedSpokes/showUserComparison/userAnswers state, inversionKey, all compass useEffects, toggleInversion, issueTags, hasUserData
- `essentials/package.json` - Bumped `@chrisandrewsedu/ev-ui` from `^0.1.19` to `^0.1.27`
- `essentials/package-lock.json` - Updated lock file after `npm update`

## Database Changes
- `essentials.geofence_boundaries` — 6 rows inserted for Bloomington City Common Council Districts 1-6:
  - geo_ids: `180586000001` through `180586000006` (matching BallotReady district table format)
  - mtfcc: `X0001` (the custom MTFCC added in Plan 01 for city council ward boundaries)
  - state: `18` (Indiana FIPS)
  - geometry: Real MultiPolygon/Polygon boundaries from official Bloomington ArcGIS (2024 data)
  - source: `bloomington_arcgis_city_council_districts_2024`
  - District 2 geometry fixed with ST_MakeValid (nested shells topology issue from source)

## Decisions Made
- **geo_id format:** Plan spec suggested `18058600000X` (12 chars). Confirmed against existing `essentials.districts` table where BallotReady already stores Bloomington council districts with geo_ids `180586000001`-`180586000006`. Used matching format.
- **Data source:** City of Bloomington's ArcGIS FeatureServer (services9.arcgis.com/47GwVXZ9a8thrviM) discovered via the city's arcgis.com experience viewer. Official city-published GIS data, established 2024.
- **ST_MakeValid on District 2:** District 2 had a "nested shells" topology warning from the ArcGIS source — applied ST_MakeValid to ensure the geometry is valid for all PostGIS spatial operations.
- **Point-in-polygon test result:** Bloomington City Hall (-86.5264, 39.1653) correctly falls within District 6 (downtown/city center area).

## Deviations from Plan

**1. [Rule 1 - Bug] Corrected geo_id format from plan spec**

- **Found during:** Task 2 (geofence import)
- **Issue:** Plan spec said geo_ids would be `180586000001`-`180586000006`. Querying `essentials.districts` showed BallotReady uses exactly that format — the plan spec was correct; no deviation needed.
- **Fix:** N/A — plan spec matched database reality. Used as specified.

**2. [Rule 1 - Bug] Applied ST_MakeValid to District 2**

- **Found during:** Task 2 verification query
- **Issue:** District 2 returned `valid=false` after insert due to nested shells topology issue from ArcGIS source data
- **Fix:** `UPDATE essentials.geofence_boundaries SET geometry = ST_MakeValid(geometry) WHERE geo_id = '180586000002'`
- **Verification:** Re-queried ST_IsValid returned `t` after fix
- **Committed in:** Database-only fix (no code commit)

## Issues Encountered

- DATABASE_URL in EV-Backend/.env.local contains `@` in the password, causing standard psql URL parsing to fail (interprets part of password as username). Resolved by URL-encoding the `@` to `%40` in the connection string.
- City of Bloomington Open Data SODA API (data.bloomington.in.gov) catalog listed council district datasets but all returned "Not found" on access. Found actual data via the ArcGIS FeatureServer discovered in the city's ArcGIS experience viewer config.

## User Setup Required

None - all changes are either frontend code (in essentials repo) or database-only (already applied to Supabase).

## Next Phase Readiness
- Phase 31 is now complete. All 3 plans executed:
  - Plan 01: district_id in all API paths + X0001 MTFCC mapping
  - Plan 02: ev-ui@0.1.27 with updated PoliticianProfile and PoliticianCard
  - Plan 03: essentials wired to new ev-ui, Bloomington districts imported
- Bloomington address searches will now show council district members as the X0001 geofences match the district geo_ids in BallotReady data
- No blockers; phase complete

---
*Phase: 31-essentials-profile-and-district-data-fixes*
*Completed: 2026-02-23*

## Self-Check: PASSED

- SUMMARY.md at `.planning/phases/31-essentials-profile-and-district-data-fixes/31-03-SUMMARY.md`: FOUND
- Commit 4f212d0 (Task 1: subtitle cards + remove Issues section): FOUND (essentials repo)
- essentials/src/pages/Results.jsx contains `subtitle={subtitle}`: VERIFIED
- essentials/src/pages/Profile.jsx has NO "Issues and Prioritization": VERIFIED
- essentials/src/pages/Profile.jsx has NO RadarChartCore or IssueTags imports: VERIFIED
- `SELECT COUNT(*) FROM essentials.geofence_boundaries WHERE mtfcc = 'X0001'` returns 6: VERIFIED
- Point-in-polygon test: City Hall (-86.5264, 39.1653) hits District 6: VERIFIED
- essentials build: 60 modules transformed, no errors: VERIFIED
