---
phase: quick
plan: 003
subsystem: api
tags: [jurisdiction, location, connected-profiles, resolve_user_jurisdiction, account-me]

# Dependency graph
requires:
  - phase: 19-location-schema-rpcs
    provides: resolve_user_jurisdiction RPC and location consent fields
provides:
  - jurisdiction object embedded on GET /api/account/me and PATCH /api/account/me responses
  - null jurisdiction signal when location_consent is false or Inform tier
affects: [validation-quests, compass, any consumer of /api/account/me]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Graceful jurisdiction degradation: RPC failure logs and returns null, never fails /me"
    - "Jurisdiction field is null (not omitted) when unavailable — clear signal vs. undefined"

key-files:
  created: []
  modified:
    - backend/src/routes/account.ts
    - tests/integration/account.test.ts
    - docs/ONBOARDING-VQ.md

key-decisions:
  - "jurisdiction: null (not omitted) when location_consent is false — explicit signal for consumers"
  - "/me/jurisdiction endpoint left untouched — backward compat preserved"
  - "RPC failure is non-fatal: console.error + null, never 500 on /me"

patterns-established:
  - "Additive embedding pattern: enrich /me with sub-resource data to eliminate round-trips"

# Metrics
duration: 4min
completed: 2026-03-18
---

# Quick Task 003: Expose Jurisdiction Location Fields on /me Summary

**jurisdiction object embedded directly on GET/PATCH /api/account/me, eliminating the separate /me/jurisdiction round-trip for VQ and other consumers**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-03-18T17:20:00Z
- **Completed:** 2026-03-18T17:24:50Z
- **Tasks:** 2 of 2
- **Files modified:** 3

## Accomplishments

- GET /api/account/me now returns `jurisdiction: { congressional_district, congressional_district_name, state_senate_district, state_senate_district_name, state_house_district, state_house_district_name, county, county_name, school_district, school_district_name }` at root level when `location_consent` is true
- GET /api/account/me returns `jurisdiction: null` when `location_consent` is false or user is Inform tier — explicit null is intentional
- PATCH /api/account/me mirrors identical jurisdiction behavior using the updated connected profile's consent flag
- RPC failure is gracefully handled (console.error + null) — /me never fails due to a jurisdiction lookup error
- Test whitelist (ALLOWED_ME_KEYS) updated to include 'jurisdiction' — privacy contract test still passes
- ONBOARDING-VQ.md updated with TypeScript type, usage example, and note that /me/jurisdiction remains for backward compat

## Task Commits

1. **Task 1: Add jurisdiction to GET /me and PATCH /me responses** - `541e995` (feat)
2. **Task 2: Update test whitelist and docs** - `6932815` (feat)

**Plan metadata:** (pending docs commit)

## Files Created/Modified

- `backend/src/routes/account.ts` - Added jurisdiction resolution (step 5b in GET, equivalent block in PATCH) and `jurisdiction` field to both meResponse objects
- `tests/integration/account.test.ts` - Added `'jurisdiction'` to ALLOWED_ME_KEYS Set
- `docs/ONBOARDING-VQ.md` - Updated response shape TypeScript block, rewrote Jurisdiction section with /me-first approach, updated capabilities table

## Decisions Made

- **`jurisdiction: null` not omitted** — using explicit null gives consumers a clear "no location" signal vs. undefined (which could mean the field doesn't exist). VQ can check `if (meData.jurisdiction)` cleanly.
- **/me/jurisdiction endpoint preserved** — additive change only; existing callers not broken.
- **RPC errors non-fatal** — jurisdiction is a convenience field, not required for /me to function. Failure logged and jurisdiction set to null.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- VQ can now read `meData.jurisdiction` directly from the existing /me call — no extra fetch needed
- Both district codes (e.g., `congressional_district`) and human-readable names (e.g., `congressional_district_name`) are available
- Inform-tier users and users without location consent get `jurisdiction: null` — VQ can gate district-scoped quests on this cleanly

---
*Phase: quick-003*
*Completed: 2026-03-18*
