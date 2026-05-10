---
phase: 71-school-districts-profile-display
plan: 02
subsystem: ui
tags: [react, typescript, profile, geofencing, school-districts, location, tabs]

# Dependency graph
requires:
  - phase: 71-school-districts-profile-display (plan 71-01)
    provides: GET /api/account/school-district endpoint, TIGER school polygon import, cache_user_districts with school layers
  - phase: 70-geofencing-backend-integration
    provides: GET /api/account/districts endpoint, connect.user_districts table
provides:
  - Location tab on ProfilePage (login.empowered.vote/profile) visible when user has location data
  - SchoolDistrictSection component — unified/elem+sec/zero-match display variants
  - Legislative districts display (CA Assembly, CA Senate, US House)
  - School district Google search links with correct TIGER name
  - Location recalibration form (Connected only) in Location tab
  - Tier-aware tab visibility and active indicator (yellow=Inform, teal-light=Connected)
affects:
  - Phase 71 UAT (plan 71-02 checkpoint)
  - Future school board ingestion phase (will add school board members to /representatives/me)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - ".catch(() => {}) on all apiFetch calls that may return 204 — SyntaxError from res.json() on empty body is silently swallowed"
    - "SchoolDistrictSection component with explicit unified-takes-precedence logic and null-guard returns"
    - "Re-use of existing location state (address, handleSetLocation, locationLoading, locationSuccess, locationError) in new Location tab panel"

key-files:
  created: []
  modified:
    - admin/src/pages/ProfilePage.tsx

key-decisions:
  - "Location tab re-uses existing handleSetLocation form handler and address/locationLoading/locationSuccess/locationError state — no duplication"
  - "Recalibration form is inline in Location tab (not lifted out of CivicSpacesTile) — CivicSpacesTile remains intact in Profile tab for Connected UX; Location tab has its own simpler inline form bound to the same state"
  - "Fetches (/account/districts and /account/school-district) fire unconditionally for all authenticated users — both tiers may have cached districts"
  - "school_unified takes precedence over elementary+secondary per CONTEXT spec"

patterns-established:
  - "Tab visibility guard pattern: check domain condition (hasLocation) before connected-only guard in tab bar map"
  - "SchoolDistrictSection: returns null when data is null OR when all three keys are null — section entirely absent, no placeholders"

# Metrics
duration: 3min
completed: 2026-05-10
---

# Phase 71 Plan 02: Location Tab + School District Display Summary

**Location tab added to ProfilePage with SchoolDistrictSection component — school district names surface as Google search links, legislative districts display by layer, tier-aware visibility/styling throughout**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-05-10T16:12:50Z
- **Completed:** 2026-05-10T16:15:34Z
- **Tasks:** 2 of 3 complete (Task 3 = checkpoint:human-verify, awaiting UAT)
- **Files modified:** 1

## Accomplishments

- Added `'location'` to ProfilePage tab bar with tier-aware visibility (location_consent OR last_essentials_location) and active indicator color (yellow=Inform, teal-light=Connected)
- Built `SchoolDistrictSection` component handling all three display variants: unified district (single labeled entry), elementary+secondary (two labeled entries), no school rows (returns null — section entirely absent)
- Populated Location tab panel with legislative districts, school district, saved location summary, and Connected-only recalibration form
- Both new API fetches use `.catch(() => {})` to silently swallow 204 SyntaxErrors

## Tab Bar Final Order

| Position | Tab | Visibility |
|---|---|---|
| 1 | Profile | Always visible when authenticated |
| 2 | Location | `location_consent === true` OR `inform_profile.last_essentials_location != null` |
| 3 | Referrals | Connected+ only |
| 4 | Posts | Connected+ only |
| 5 | Contributor | Connected+ only |

## Recalibration Form Approach

The form is **inline in the Location tab panel** (not the lifted-JSX approach). The `CivicSpacesTile` component in the Profile tab remains entirely unchanged — it's the Connected UX for Civic Spaces. The Location tab has its own simpler `<form>` element that binds to the exact same state variables (`address`, `setAddress`, `handleSetLocation`, `locationLoading`, `locationSuccess`, `locationError`). Both forms share state, so a user who partially types in one tab and switches tabs will see their input preserved.

This was the cleaner approach: the CivicSpacesTile is tightly coupled to the Civic Spaces app link and its own layout. Lifting would have required either extracting a sub-component or duplicating props — unnecessary complexity.

## Task Commits

1. **Task 1: Add Location tab to ProfilePage with tier-aware visibility** — `8387d31` (feat)
2. **Task 2: Build SchoolDistrictSection and populate Location tab panel** — `f914a4f` (feat)

## Files Created/Modified

- `admin/src/pages/ProfilePage.tsx` — Only file modified. Added interfaces (SchoolDistrictEntry, SchoolDistrictData, DistrictsData), state (districts, schoolDistrict), fetches (/account/districts, /account/school-district), SchoolDistrictSection component, Location tab in tab bar, Location tab panel with full content.

## Decisions Made

- Re-use existing recalibration state/handler (inline form approach, not lift-out-of-CivicSpacesTile)
- Fire both district fetches unconditionally for all auth'd users — both tiers may have cached TIGER data
- `district_number` key confirmed from backend source (`byLayer` maps `district_num` → `district_number`)

## Deviations from Plan

None — plan executed exactly as written. The task instructions specified the exact key shape; backend source confirmed `district_number` is the correct key. No ambiguity encountered.

## Issues Encountered

None — TypeScript compiled cleanly on first attempt for both tasks.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Plan 71-02 Tasks 1–2 complete. Task 3 (checkpoint:human-verify) awaiting UAT on live login.empowered.vote/profile.
- After UAT approval, Phase 71 is fully complete (GEO-13 + GEO-14 closed).
- Future "school board ingestion" phase: will populate `essentials.politicians` + `essentials.districts` rows for school board members so they appear in `GET /api/essentials/representatives/me`. That phase is separate from Phase 71.

---
*Phase: 71-school-districts-profile-display*
*Completed: 2026-05-10*
