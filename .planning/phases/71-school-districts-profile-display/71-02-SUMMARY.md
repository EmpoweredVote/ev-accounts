---
phase: 71-school-districts-profile-display
plan: 02
subsystem: ui
tags: [react, typescript, profile, geofencing, school-districts, location, tabs, city-council]

# Dependency graph
requires:
  - phase: 71-school-districts-profile-display (plan 71-01)
    provides: GET /api/account/school-district endpoint, TIGER school polygon import, cache_user_districts with school layers
  - phase: 70-geofencing-backend-integration
    provides: GET /api/account/districts endpoint, connect.user_districts table
provides:
  - Location tab on ProfilePage (login.empowered.vote/profile) visible for all Connected/Empowered users
  - SchoolDistrictSection component — unified/elem+sec/zero-match display variants
  - Legislative districts display (CA Assembly, CA Senate, US House)
  - City Council district display (independent of TIGER cache, sourced from /account/me)
  - School district Google search links with correct TIGER name
  - Location recalibration form (Connected only) in Location tab with force:true
  - Tier-aware tab visibility and active indicator (yellow=Inform, teal-light=Connected)
affects:
  - Future school board ingestion phase (will add school board members to /representatives/me)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - ".catch(() => {}) on all apiFetch calls that may return 204 — SyntaxError from res.json() on empty body is silently swallowed"
    - "SchoolDistrictSection component with explicit unified-takes-precedence logic and null-guard returns"
    - "Re-use of existing location state (address, handleSetLocation, locationLoading, locationSuccess, locationError) in new Location tab panel"
    - "force:true required in POST /api/account/set-location body for existing users — omitting it causes 409 Conflict"
    - "City Council district sourced from /account/me (city_council_district_name) independently of TIGER cache to avoid districts-block guard dependency"

key-files:
  created: []
  modified:
    - admin/src/pages/ProfilePage.tsx
    - backend/migrations/094_drop_ambiguous_cache_user_districts_overload.sql

key-decisions:
  - "Location tab re-uses existing handleSetLocation form handler and address/locationLoading/locationSuccess/locationError state — no duplication"
  - "Recalibration form is inline in Location tab (not lifted out of CivicSpacesTile) — CivicSpacesTile remains intact in Profile tab; Location tab has its own simpler inline form bound to the same state"
  - "Fetches (/account/districts and /account/school-district) fire unconditionally for all authenticated users — both tiers may have cached districts"
  - "school_unified takes precedence over elementary+secondary per CONTEXT spec"
  - "Tab visibility changed from location_consent-gated to all Connected users (matching product intent — the tab is useful even before the user has set a location, as a prompt to do so)"
  - "City Council rendered outside the districts block guard so it shows independently (sources from /account/me, not the TIGER user_districts cache)"
  - "Migration 094 pattern: DROP old function signature before adding new one — CREATE OR REPLACE only works when signature is identical; changing parameter count requires explicit DROP first"

patterns-established:
  - "Tab visibility guard pattern: check domain condition (hasLocation / tier) before connected-only guard in tab bar map"
  - "SchoolDistrictSection: returns null when data is null OR when all three keys are null — section entirely absent, no placeholders"
  - "When changing a PostgreSQL function's parameter count via migration: always DROP the old overload explicitly; CREATE OR REPLACE cannot change arity"

# Metrics
duration: ~60min (including post-UAT fixes)
completed: 2026-05-10
---

# Phase 71 Plan 02: Location Tab + School District Display Summary

**Location tab added to ProfilePage with school districts (Google search links), legislative districts, City Council district, recalibration form, and tier-aware visibility — GEO-14 complete; Phase 71 fully shipped**

## Performance

- **Duration:** ~60 min (Tasks 1–2 fast; 4 post-UAT deviation fixes required)
- **Started:** 2026-05-10
- **Completed:** 2026-05-10 (UAT approved after fixes)
- **Tasks:** 3 of 3 complete (Task 3 = checkpoint:human-verify, UAT APPROVED)
- **Files modified:** 2

## Accomplishments

- Added `'location'` to ProfilePage tab bar with tier-aware visibility (all Connected users, yellow=Inform active indicator, teal-light=Connected) and active indicator color
- Built `SchoolDistrictSection` component handling all three display variants: unified district (single labeled entry), elementary+secondary (two labeled entries), no school rows (returns null — section entirely absent)
- Populated Location tab panel with legislative districts, City Council district, school district, saved location summary, and Connected-only recalibration form
- Both new API fetches use `.catch(() => {})` to silently swallow 204 SyntaxErrors
- Applied migration 094 to drop ambiguous 3-arg `cache_user_districts` overload that caused "function is not unique" errors on every district cache call
- UAT passed on login.empowered.vote/profile — all tests approved

## Tab Bar Final Order

| Position | Tab | Visibility |
|---|---|---|
| 1 | Profile | Always visible when authenticated |
| 2 | Location | All Connected/Empowered users (regardless of whether location is set) |
| 3 | Referrals | Connected+ only |
| 4 | Posts | Connected+ only |
| 5 | Contributor | Connected+ only |

## Recalibration Form Approach

The form is **inline in the Location tab panel** (not the lifted-JSX approach). The `CivicSpacesTile` component in the Profile tab remains entirely unchanged. The Location tab has its own simpler `<form>` element that binds to the exact same state variables (`address`, `setAddress`, `handleSetLocation`, `locationLoading`, `locationSuccess`, `locationError`). Both forms share state.

This was the cleaner approach: the CivicSpacesTile is tightly coupled to the Civic Spaces app link and its own layout. Lifting would have required either extracting a sub-component or duplicating props — unnecessary complexity.

## Task Commits

1. **Task 1: Add Location tab to ProfilePage with tier-aware visibility** — `8387d31` (feat)
2. **Task 2: Build SchoolDistrictSection and populate Location tab panel** — `f914a4f` (feat)
3. **Task 3: UAT — checkpoint commit (pre-UAT)** — `cc18db9` (docs)

**Post-UAT deviation fixes:**
- `cb2c1f4` — fix: force:true on location update, refetch districts after success, tab shown for all Connected users
- `88a8784` — fix: migration 094 drop ambiguous 3-arg cache_user_districts overload
- `729b474` — feat: City Council district added to Location tab
- `a891010` — fix: City Council moved outside districts guard so it renders independently

**Plan metadata:** (this commit) — docs(71-02): complete Location tab plan

## Files Created/Modified

- `admin/src/pages/ProfilePage.tsx` — Primary file. Added interfaces (SchoolDistrictEntry, SchoolDistrictData, DistrictsData), MeResponse extended with city_council_district_name, state (districts, schoolDistrict), fetches (/account/districts, /account/school-district), SchoolDistrictSection component, Location tab in tab bar with tier-aware visibility, Location tab panel with full content including City Council.
- `backend/migrations/094_drop_ambiguous_cache_user_districts_overload.sql` — Drops the old 3-arg `cache_user_districts(uuid, numeric, numeric)` overload that was created by migration 093 alongside the new 4-arg version, causing Postgres "function is not unique" errors on every district cache call.

## Decisions Made

- Re-use existing recalibration state/handler (inline form approach, not lift-out-of-CivicSpacesTile)
- Fire both district fetches unconditionally for all auth'd users — both tiers may have cached TIGER data
- `district_number` key confirmed from backend source (`byLayer` maps `district_num` → `district_number`)
- City Council district sourced independently from `/account/me` response (not TIGER cache) so it always shows for Connected users regardless of whether TIGER district rows exist

## Deviations from Plan

### Post-UAT Issues (handled as auto-fixes)

**1. [Rule 1 - Bug] API 409 error when updating location**
- **Found during:** UAT Test 1 (recalibration form)
- **Issue:** The Location tab recalibration form posted to `POST /api/account/set-location` without `force: true` in the request body. Existing Connected users have a location already set, so the server returned 409 Conflict. New users could set location, but returning users couldn't update it.
- **Fix:** Added `force: true` to the POST body in the `handleSetLocation` call wired into the Location tab form.
- **Files modified:** `admin/src/pages/ProfilePage.tsx`
- **Committed in:** `cb2c1f4`

**2. [Rule 1 - Bug] Districts not showing after location update**
- **Found during:** UAT Test 1 (after recalibration)
- **Issue:** After a successful location update, the `districts` state was not refreshed — the user had to hard-reload the page to see their updated legislative districts in the Location tab.
- **Fix:** Added a `refetch` call for `/account/districts` in the `locationSuccess` effect / after the POST succeeds, so the panel updates inline without a page reload.
- **Files modified:** `admin/src/pages/ProfilePage.tsx`
- **Committed in:** `cb2c1f4`

**3. [Rule 1 - Bug] Postgres "function is not unique" on district cache calls**
- **Found during:** UAT Test 1 (network inspection — school-district returned 204 unexpectedly for CA user)
- **Issue:** Migration 093 (Plan 71-01) added a new 4-arg `cache_user_districts(uuid, numeric, numeric, text[])` overload using `CREATE OR REPLACE` without dropping the old 3-arg signature `cache_user_districts(uuid, numeric, numeric)`. Postgres now had two overloads. Any caller using the 3-arg form hit "function is not unique" and Postgres refused to resolve the call — all district cache writes failed silently (error was swallowed in the Node `catch`).
- **Fix:** Migration 094 applied — `DROP FUNCTION IF EXISTS essentials.cache_user_districts(uuid, numeric, numeric)` to remove the ambiguous overload.
- **Files modified:** `backend/migrations/094_drop_ambiguous_cache_user_districts_overload.sql`
- **Committed in:** `88a8784`

**4. [Rule 2 - Missing Critical] City Council district not displayed**
- **Found during:** UAT (user feedback — City Council is a key civic district)
- **Issue:** The original plan only specified CA Assembly, CA Senate, and US House in the legislative districts block. City Council district (`city_council_district_name`) is already present on the `/account/me` response (added in Quick Task 014) but was not surfaced in the Location tab.
- **Fix:** Added `city_council_district_name` to the `MeResponse` type, read it from the `/account/me` response, and rendered it as a labeled entry in the Location tab — outside the `districts` block guard (so it shows even when TIGER cache is empty), since it comes from a different source.
- **Files modified:** `admin/src/pages/ProfilePage.tsx`
- **Committed in:** `729b474` + `a891010` (second commit moved it outside the districts guard to fix a rendering dependency)

---

**Total deviations:** 4 auto-fixed (2 bugs, 1 missing critical, 1 infrastructure fix)
**Impact on plan:** All fixes necessary for correct operation. The migration 094 fix (duplicate overload) was a cascading consequence of migration 093's approach — important pattern to document. No unintended scope creep.

## Key Pattern for Future Migrations

**When changing a PostgreSQL function's parameter count:** `CREATE OR REPLACE FUNCTION` cannot change a function's arity or parameter types — it only replaces a function with the EXACT SAME signature. If you add or remove parameters, you must:

1. `DROP FUNCTION IF EXISTS schema.function_name(old, arg, types);`
2. Then `CREATE OR REPLACE FUNCTION schema.function_name(new, arg, types)` (or just `CREATE FUNCTION`).

Failing to drop the old overload creates two overloads with different arities. Postgres will refuse to resolve calls that are ambiguous between them ("function is not unique"), and since the Node backend swallows district-cache errors, this failure is silent and hard to diagnose.

## UAT Results

All 5 test cases passed after post-UAT fixes were applied:

1. **Connected user in unified school district (LA Unified)** — PASS: Location tab visible, CA Assembly/Senate/US House/City Council all display, LAUSD school district link opens Google search in new tab, recalibration form works with `force: true`.
2. **Connected user in non-unified area (elem + secondary)** — PASS: Two labeled entries (Elementary School District / Secondary School District) with separate links.
3. **Connected user outside CA** — PASS: School district section entirely hidden; no console errors; `/account/school-district` returns 204 silently.
4. **Inform user with last_essentials_location** — PASS: Location tab visible with yellow active indicator; LAUSD link shown; recalibration form hidden (Inform tier).
5. **User without location data** — PASS: Location tab visible for all Connected users (tab visibility changed from location-data-gated to tier-gated during UAT fix `cb2c1f4`).

## Issues Encountered

The Postgres "function is not unique" bug (deviation 3 above) was the most significant issue — it caused the school district section to show empty for all CA users even after location was set, because the district cache writes were silently failing. Discovery required inspecting the network tab and noticing that `/account/school-district` returned 204 for a user known to be in LA. Root cause was traced to the migration 093 approach.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Phase 71 is fully complete. GEO-13 and GEO-14 are both shipped.
- The `GET /api/essentials/representatives/me` response shape is unchanged — no school board members appear yet (school boards are not in `essentials.politicians`). This is expected and confirmed.
- Future "school board ingestion" phase: will populate `essentials.politicians` + `essentials.districts` rows for school board members so they appear in `/representatives/me`. That phase is a separate roadmap entry.
- No blockers for v2.2 close-out. Phases 64–65 (InformLanding, Dashboard) remain pending from v2.0.

---
*Phase: 71-school-districts-profile-display*
*Completed: 2026-05-10*
