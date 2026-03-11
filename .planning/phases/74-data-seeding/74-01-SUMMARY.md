---
phase: 74-data-seeding
plan: 01
subsystem: database
tags: [postgresql, gorm, government_bodies, data-seeding, idempotent-sql]

# Dependency graph
requires:
  - phase: 73-backend-governmentbody-table
    provides: government_bodies table with composite unique index (state, geo_id, body_key) + LEFT JOIN wired in both fetch functions
provides:
  - 14 seeded rows in essentials.government_bodies for Monroe County and Bloomington bodies
  - name_formal = 'Monroe County Government' for 9 individual county office chambers
  - All 4 official government website URLs (in.gov + bloomington.in.gov)
affects: [75-ev-ui-government-body-prop, 76-frontend-government-body-display]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Idempotent INSERT via ON CONFLICT (state, geo_id, body_key) DO NOTHING — preserves manually-corrected URLs on restart"
    - "FIPS state code '18' (not ISO 'IN') required for d.state JOIN column match"
    - "geo_id fan-out: multi-district bodies require one row per distinct geo_id used by officials"

key-files:
  created: []
  modified:
    - EV-Backend/internal/essentials/setup.go

key-decisions:
  - "Individual county office chambers (Sheriff, Assessor, Auditor, etc.) share body_key='Monroe County Government' via name_formal UPDATE — one government_bodies row covers all 9 offices"
  - "ON CONFLICT DO NOTHING (not DO UPDATE) — manually-corrected URLs in production DB are preserved on every server restart"
  - "Bloomington City Clerk and Mayor excluded from Phase 74 seeding — not in success criteria; can be added in Phase 76"
  - "JUDICIAL chambers (circuit court judges) excluded — separate district_type, success criteria do not mention them"

patterns-established:
  - "Phase 74 name_formal pattern: db.DB.Exec UPDATE with IN (...) list for individual offices sharing a body_key"
  - "Phase 74 seeding pattern: db.DB.Exec INSERT ... VALUES (...) ON CONFLICT (state, geo_id, body_key) DO NOTHING"

requirements-completed: [LINK-03, LINK-04]

# Metrics
duration: 2min
completed: 2026-03-11
---

# Phase 74 Plan 01: Data Seeding Summary

**Idempotent SQL seeding of 14 government_bodies rows + 9 chamber name_formal updates for Monroe County and Bloomington officials with verified in.gov/bloomington.in.gov URLs**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-11T15:05:49Z
- **Completed:** 2026-03-11T15:07:11Z
- **Tasks:** 1 of 2 (Task 2 is human-verify checkpoint)
- **Files modified:** 1

## Accomplishments

- Added Phase 74 name_formal UPDATE in setup.go for 9 individual Monroe County office chambers — Sheriff, Assessor, Auditor, Coroner, Treasurer, Recorder, Surveyor, Circuit Court Clerk, Prosecuting Attorney — all set to 'Monroe County Government' so they resolve to one government_bodies row via the JOIN
- Added idempotent INSERT for 14 government_bodies rows: 1 Monroe County Commission, 5 Monroe County Council (at-large geo_id 18105 + 4 district geo_ids), 1 Monroe County Government (individual offices), 7 Bloomington Common Council (at-large geo_id 1805860 + 6 district geo_ids)
- All 4 URLs verified against live official government pages (in.gov = Indiana state government, bloomington.in.gov = City of Bloomington)
- Go build passes with no errors

## Task Commits

Each task was committed atomically:

1. **Task 1: Add name_formal migration and government_bodies seed data to setup.go** - `6158056` (feat)
2. **Task 2: human-verify checkpoint** - pending user verification

## Files Created/Modified

- `EV-Backend/internal/essentials/setup.go` - Added Phase 74 chamber name_formal UPDATE (9 individual county offices) and INSERT 14 government_bodies rows with official website URLs

## Decisions Made

- **body_key 'Monroe County Government' for individual offices:** Each individual county office chamber has a unique name (e.g., 'Monroe County Sheriff') but sharing a single body_key via name_formal migration means one government_bodies row covers all 9 officials, which matches the intent of the success criteria ("Monroe County individual elected officials")
- **ON CONFLICT DO NOTHING over DO UPDATE:** Preserves any URL corrections made directly in the production DB; avoids overwriting on every server restart
- **FIPS '18' for state column:** Districts table stores FIPS codes ('18'), not ISO codes ('IN'); confirmed in Phase 72 audit
- **14 rows for geo_id fan-out:** Monroe County Council requires 5 rows (1 at-large + 4 districts); Bloomington Common Council requires 7 rows (1 at-large + 6 districts); each distinct geo_id in the districts table needs its own government_bodies row for the JOIN to match

## Deviations from Plan

None — plan executed exactly as written. The research file (74-RESEARCH.md) provided the exact SQL patterns and geo_id values; no adjustments were required.

## Issues Encountered

EV-Backend is a separate git repository from the workspace root — committed using `cd EV-Backend && git add ...` rather than from the workspace root. This is expected behavior per the project structure.

## User Setup Required

**Task 2 (human-verify):** After starting the backend server (`cd EV-Backend && go run .`), run the following psql queries and curl to verify seeding:

1. Confirm 14 seeded rows:
   ```sql
   SELECT state, geo_id, body_key, display_name, website_url
   FROM essentials.government_bodies WHERE state='18' ORDER BY body_key, geo_id;
   ```
   Expected: 14 rows with non-null website_url.

2. Verify individual office name_formal:
   ```sql
   SELECT name, name_formal FROM essentials.chambers
   WHERE name IN ('Monroe County Assessor', 'Monroe County Sheriff', 'Monroe County Auditor');
   ```
   Expected: name_formal = 'Monroe County Government' for all.

3. API smoke test:
   ```bash
   curl -s "http://localhost:5050/essentials/search?zip=47401" | python3 -m json.tool | grep -A2 government_body
   ```
   Expected: Non-empty government_body_name and government_body_url for Monroe County Council, Commission, Government, and Bloomington Common Council officials.

## Next Phase Readiness

- Code work complete — 14 rows seed on server startup; name_formal migration runs before INSERT so JOIN resolves correctly
- Phase 75 (ev-ui GovernmentBody prop) can proceed in parallel — no dependency on this seeding being verified
- Phase 76 (frontend display) depends on Phase 73 LEFT JOIN (complete) and this seeding being verified

## Self-Check: PASSED

- FOUND: `/Users/chrisandrews/Documents/GitHub/.planning/phases/74-data-seeding/74-01-SUMMARY.md`
- FOUND: commit `6158056` (feat(74-01): seed government_bodies with Monroe County and Bloomington URLs)
- FOUND: `EV-Backend/internal/essentials/setup.go` modified with 47 line insertion
- Build passes: `go build -o server .` exits 0

---
*Phase: 74-data-seeding*
*Completed: 2026-03-11*
