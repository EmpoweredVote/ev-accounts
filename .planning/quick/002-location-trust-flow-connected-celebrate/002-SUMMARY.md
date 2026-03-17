---
phase: quick
plan: 002
subsystem: api
tags: [location, framer, connected-tier, geocoding, jurisdiction, trust-flow]

requires:
  - phase: 19-location-schema-rpcs
    provides: upsert_user_location RPC, location_consent on connected_profiles, getLocationConsent service helper

provides:
  - first_location boolean flag in POST /connect/set-location response
  - FRAMER-LOCATION-TRUST-FLOW.md — complete UX contract for Framer frontend team

affects:
  - Framer frontend — location input UI, Connected celebration flow, pseudonym creation step

tech-stack:
  added: []
  patterns:
    - "Read-before-write for first-time detection: check existing state before mutation to derive first_location flag"

key-files:
  created:
    - docs/FRAMER-LOCATION-TRUST-FLOW.md
  modified:
    - backend/src/routes/connect.ts

key-decisions:
  - "first_location derived at route layer via read-before-write — no RPC or schema change needed"
  - "getLocationConsent imported from connectService (already existed) — zero new code, just wired up"

patterns-established:
  - "Read-before-write first-time detection: call getLocationConsent(userId) before upsert to detect first vs update"

duration: 10min
completed: 2026-03-17
---

# Quick Task 002: Location Trust Flow + Connected Celebrate Summary

**`first_location` flag added to set-location response and complete Framer trust-flow contract written covering Connected celebration, pseudonym creation, and the 'I moved' update path**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-03-17T21:50:00Z
- **Completed:** 2026-03-17T22:00:19Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `first_location: boolean` to `POST /connect/set-location` response — `true` on first call, `false` on updates — using read-before-write with the existing `getLocationConsent` helper
- Created `docs/FRAMER-LOCATION-TRUST-FLOW.md`: 7-section contract covering philosophy, Connected celebration flow, "I moved" update flow, full API reference, Framer signal table, error UX, and privacy copy guidance
- Zero breaking changes — `first_location` is additive to the existing response

## Task Commits

1. **Task 1: Add first_location flag to set-location response** - `12fd970` (feat)
2. **Task 2: Write Framer location trust flow contract doc** - `82ec0dd` (docs)

## Files Created/Modified

- `backend/src/routes/connect.ts` — imported `getLocationConsent`, added pre-upsert read, added `first_location` to 200 response
- `docs/FRAMER-LOCATION-TRUST-FLOW.md` — new document: full Framer integration contract

## Decisions Made

- **first_location computed at route layer, not in RPC** — `getLocationConsent` was already in `connectService.ts` with proper service-role semantics. No SQL change needed — the flag is purely a read-before-write signal at the route level.
- **`getLocationConsent` added to connect.ts import** — it was only imported in `account.ts` before; connect.ts needed it for the pre-upsert check.

## Deviations from Plan

None — plan executed exactly as written. The plan's instruction to "confirm getLocationConsent is already imported" was slightly off (it wasn't in connect.ts), but adding it to the import list was a trivial mechanical step, not a deviation.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Framer team can now build the trust-first location flow and Connected celebration using `docs/FRAMER-LOCATION-TRUST-FLOW.md`
- `first_location` signal is live on the backend — Framer can begin integration immediately
- No blockers

---
*Phase: quick-002*
*Completed: 2026-03-17*
