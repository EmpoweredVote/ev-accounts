---
phase: 37-politician-gap-fill-city-councils-and-school-boards
plan: 01
subsystem: database
tags: [python, postgresql, scraping, pdfplumber, playwright, psycopg2, geofences, politicians]

# Dependency graph
requires:
  - phase: 36-politician-gap-fill-supervisors-la-city-council
    provides: scraper framework (scrape_la_officials.py, utils.py, dedup patterns), is_active/data_source schema
  - phase: 35-geofence-la-county-cities-wards
    provides: G4110 place boundaries (place_geoid) and X0001 ward boundaries for geo_id joins
  - phase: 34-geofence-tigris-import
    provides: geofence_boundaries table with ST_Covers spatial index
provides:
  - "city_sources.json: config mapping 89 LA County cities to election_type, place_geoid, ocd_id, and pre-populated SOS PDF roster"
  - "scrape_city_councils.py: batch scraper for 89 cities with SOS PDF primary source, per-city transactions, is_multi_seat dedup, LOCAL/LOCAL_EXEC district_type awareness"
  - "368 active city council politicians in essentials DB (89 mayors + 279 council members) for all LA County incorporated cities excluding LA City"
  - "176 district records (89 LOCAL_EXEC for mayors, 87 LOCAL for at-large councils)"
affects:
  - phase-38-vacuum-analyze
  - essentials frontend zip search for any LA County city address

# Tech tracking
tech-stack:
  added:
    - "pdfplumber==0.11.4 — two-column PDF extraction with page.crop() for SOS roster"
    - "playwright==1.44.0 — headless browser fallback for JS-heavy city sites"
  patterns:
    - "Two-column PDF parsing: page.crop((0,0,mid,h)) left column + page.crop((mid,0,w,h)) right column"
    - "is_multi_seat dedup: at-large council members share ocd_id — name-match only, no seat replacement for mismatches"
    - "District_type-aware lookup: query districts WHERE ocd_id=X AND district_type=Y to prevent mayor LOCAL_EXEC district reuse for council LOCAL"
    - "init_ext_id_counter(): queries DB min external_id before each run to avoid collision with prior runs"
    - "Per-city autocommit pattern: conn.autocommit=True for init, conn.autocommit=False per city transaction"

key-files:
  created:
    - "EV-Backend/scripts/scrape_city_councils.py"
    - "EV-Backend/scripts/city_sources.json"
  modified:
    - "EV-Backend/scripts/requirements.txt"

key-decisions:
  - "5 district-election cities (Long Beach, Torrance, Pasadena, Inglewood, West Covina) treated as at-large — SOS PDF provides district=0 for all members; per-ward assignment deferred"
  - "At-large council members use election_type=at-large with is_multi_seat=True in dedup — same ocd_id for all members requires name-match-only logic (no seat replacement)"
  - "District lookup must filter by district_type to avoid at-large council reusing LOCAL_EXEC mayor district (both share same ocd_id_base)"
  - "verify_no_duplicates() groups by (ocd_id, title, name) not just (ocd_id, name) — rotating mayors hold both Mayor and Council Member offices legitimately"
  - "Inglewood: duplicate 'James T. Butts Jr.' Mayor+CouncilMember entry in SOS PDF removed from roster (rotating mayor pattern in PDF)"
  - "SOS PDF 2025 URL used (admin.cdn.sos.ca.gov/ca-roster/2025/cities-towns.pdf) — 2026 URL returned 404"
  - "City councils are nonpartisan — all party fields set to 'Nonpartisan' / 'N'"

patterns-established:
  - "SOS PDF two-column extraction pattern: usable for any two-column CA government roster PDF"
  - "Config-driven at-large batch scraper: city_sources.json pre-populated from PDF, scraper processes in one pass with per-city commits"
  - "is_multi_seat dedup: reusable pattern for any multi-seat at-large body where all members share one ocd_id"

requirements-completed: [POL-03]

# Metrics
duration: ~120min
completed: 2026-02-24
---

# Phase 37 Plan 01: City Councils Summary

**CA SOS PDF bulk extraction + config-driven batch scraper populates 89 LA County city councils: 368 active politicians (89 mayors + 279 council members), 100% city coverage, 0 duplicate violations**

## Performance

- **Duration:** ~120 min
- **Started:** 2026-02-24T14:00:00Z
- **Completed:** 2026-02-24
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Extracted 89 cities and 383 pre-seeded roster entries from CA SOS Incorporated Cities PDF using two-column pdfplumber parsing
- Created city_sources.json config mapping all 89 LA County incorporated cities (excluding LA City) with place_geoid, election_type, ocd_id_base, and pre-populated roster
- Built and executed scrape_city_councils.py: 100% city coverage (89/89), 368 active politicians, 0 duplicate violations, PIP tests pass for Burbank/Long Beach/Pasadena

## Task Commits

Each task was committed atomically (EV-Backend repo):

1. **Task 1: Create city_sources.json config and update requirements.txt** - `9656beb` (feat)
2. **Task 2: Create scrape_city_councils.py and execute against database** - `8b63713` (feat)

## Files Created/Modified

- `EV-Backend/scripts/city_sources.json` - 89 LA County city configs with place_geoid, election_type, ocd_id_base, pre-populated SOS PDF roster, and run status
- `EV-Backend/scripts/scrape_city_councils.py` - Batch scraper: SOS PDF roster → per-city upsert with is_multi_seat dedup, district_type-aware lookup, PIP verification
- `EV-Backend/scripts/requirements.txt` - Added pdfplumber==0.11.4 and playwright==1.44.0

## Decisions Made

- **5 district-election cities as at-large:** Long Beach, Torrance, Pasadena, Inglewood, West Covina all have district elections but the SOS PDF only lists members without ward numbers (district=0 for all). Treated as at-large for this import so all council members get the city-level G4110 geoid. Per-ward assignments deferred to future work when ward-level roster data is available.
- **District_type-aware district lookup:** Critical fix — at-large council and mayor share the same ocd_id_base. Without filtering by district_type, council members would be inserted into the LOCAL_EXEC mayor district. Fix: `WHERE ocd_id = %s AND district_type = %s`.
- **is_multi_seat dedup for at-large:** All at-large council members share one ocd_id. Standard seat-first dedup would deactivate each prior member when the next is inserted. Fixed with `is_multi_seat=True`: name-match only, no seat replacement for mismatches.
- **verify_no_duplicates includes title:** Rotating-mayor cities legitimately have one person in both Mayor (LOCAL_EXEC) and Council Member (LOCAL) offices sharing the same ocd_id. The duplicate check must group by (ocd_id, title, name) not just (ocd_id, name).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] PDF two-column layout merging text — switched to page.crop() extraction**
- **Found during:** Task 1 (SOS PDF parsing)
- **Issue:** `page.extract_text()` merges both columns, producing garbled lines
- **Fix:** Used `page.crop((0,0,mid,h))` and `page.crop((mid,0,w,h))` to extract each column independently
- **Files modified:** PDF extraction script (inline during city_sources.json creation)
- **Verification:** All 89 LA County cities extracted with correct roster entries
- **Committed in:** `9656beb` (Task 1 commit)

**2. [Rule 1 - Bug] La Cañada Flintridge special-character city name not matching**
- **Found during:** Task 1 (SOS PDF city extraction)
- **Issue:** `ñ` character failed string comparison against city list
- **Fix:** Added `norm()` helper: `ñ→n`, `é→e`, `á→a`, `ó→o` for comparison only
- **Files modified:** PDF extraction script (inline)
- **Verification:** La Canada Flintridge found and included in city_sources.json
- **Committed in:** `9656beb` (Task 1 commit)

**3. [Rule 1 - Bug] El Monte OCD-IDs had state:nv instead of state:ca**
- **Found during:** Task 1 (pre-scraping DB check)
- **Issue:** 2 El Monte district rows had `state:nv` in ocd_id (malformed BallotReady data)
- **Fix:** `UPDATE essentials.districts SET ocd_id = REPLACE(ocd_id, '/state:nv/', '/state:ca/') WHERE ...` — 2 rows updated
- **Files modified:** DB (essentials.districts)
- **Verification:** Both rows confirmed corrected
- **Committed in:** `9656beb` (Task 1 commit)

**4. [Rule 1 - Bug] external_id collision on re-run — init_ext_id_counter() added**
- **Found during:** Task 2 (first scraper run)
- **Issue:** `idx_chambers_external_id` UNIQUE violation — utils.py counter resets to -200001 each Python process, but that ID was already used
- **Fix:** Added `init_ext_id_counter(conn)` that queries DB min across politicians/chambers/districts and sets counter one below current minimum
- **Files modified:** `EV-Backend/scripts/scrape_city_councils.py`
- **Verification:** No further external_id collisions on subsequent runs
- **Committed in:** `8b63713` (Task 2 commit)

**5. [Rule 1 - Bug] Council members in LOCAL_EXEC district — district_type-aware lookup**
- **Found during:** Task 2 (verification after first run)
- **Issue:** At-large council members were inserted into the mayor's LOCAL_EXEC district because `find_or_create_city_district()` only filtered by ocd_id, finding the mayor's district first
- **Fix:** Added `AND district_type = %s` to the district lookup query
- **Files modified:** `EV-Backend/scripts/scrape_city_councils.py`
- **Verification:** All 279 council members now have `LOCAL` district_type; PIP tests pass
- **Committed in:** `8b63713` (Task 2 commit)

**6. [Rule 1 - Bug] District cities seat-replacement churn — is_multi_seat dedup**
- **Found during:** Task 2 (first run, district cities had only 1 active council member each)
- **Issue:** All at-large council members share the same ocd_id; standard `new_person_in_seat` logic deactivated each member as the next was inserted, leaving only the last member
- **Fix:** Added `is_multi_seat=True` for at-large council: returns `(None, None)` on name mismatch instead of `(old_id, "new_person_in_seat")`
- **Files modified:** `EV-Backend/scripts/scrape_city_councils.py`
- **Verification:** All at-large cities now have full council member count
- **Committed in:** `8b63713` (Task 2 commit)

**7. [Rule 1 - Bug] verify_no_duplicates false positives for rotating-mayor cities**
- **Found during:** Task 2 (verification reported 8 duplicates)
- **Issue:** `GROUP BY ocd_id, name` flagged rotating mayors who hold both Mayor and Council Member offices at same ocd_id as duplicates
- **Fix:** Added `o.title` to GROUP BY so only true same-title duplicates are flagged
- **Files modified:** `EV-Backend/scripts/scrape_city_councils.py`
- **Verification:** 0 true duplicate violations
- **Committed in:** `8b63713` (Task 2 commit)

**8. [Rule 1 - Bug] PIP test crash — % in SQL LIKE inside f-string**
- **Found during:** Task 2 (verification crash after duplicate check)
- **Issue:** `f"""... LIKE 'place:burbank%' ..."""` — the `%` in LIKE is treated as psycopg2 parameter placeholder
- **Fix:** Escaped `%` to `%%` in the filter strings inside f-strings
- **Files modified:** `EV-Backend/scripts/scrape_city_councils.py`
- **Verification:** PIP tests run successfully
- **Committed in:** `8b63713` (Task 2 commit)

---

**Total deviations:** 8 auto-fixed (all Rule 1 bugs)
**Impact on plan:** All fixes necessary for correctness. Core deliverables met: 89/89 cities, 368 active politicians, 0 duplicates, PIP tests pass.

## Issues Encountered

- SOS PDF 2026 URL (admin.cdn.sos.ca.gov/ca-roster/2026/cities-towns.pdf) returned 404 — used 2025 URL successfully
- `set_session cannot be used inside a transaction` error: init query required `autocommit=True` before first city transaction. Fixed by starting connection with autocommit=True and switching to autocommit=False per city
- 5 cities with district elections (Long Beach, Torrance, Pasadena, Inglewood, West Covina) were initially configured as `election_type="district"` with `ocd_id_template`. Since SOS PDF provides district=0 for all members (no per-ward assignment), changed to `election_type="at-large"` so all members use city-level G4110 geoid

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 368 city council politicians in DB covering all 89 LA County incorporated cities (excluding LA City)
- POL-03 satisfied: any incorporated city address in LA County returns city council representatives via PIP query
- Schema unchanged — no Go migration needed for Phase 38
- City council geo_ids link to G4110 geofence_boundaries (place_geoid); all 175/176 districts have geofence coverage
- Phase 38 (VACUUM ANALYZE) can proceed; Phase 37 Plan 02 (school boards) is the next scraping task

## Self-Check: PASSED

- `EV-Backend/scripts/scrape_city_councils.py` - FOUND
- `EV-Backend/scripts/city_sources.json` - FOUND
- `.planning/phases/37-.../37-01-SUMMARY.md` - FOUND
- Commit `9656beb` (Task 1) - FOUND
- Commit `8b63713` (Task 2) - FOUND

---
*Phase: 37-politician-gap-fill-city-councils-and-school-boards*
*Completed: 2026-02-24*
