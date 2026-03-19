---
phase: 33-essentials-integration-guide
plan: 01
subsystem: docs
tags: [jurisdiction, location, typescript, integration-guide, xp, gems, auth]

# Dependency graph
requires:
  - phase: 19-location-schema-rpcs
    provides: Jurisdiction fields on connected_profiles + GET /api/account/me exposure
  - phase: 32-compassv2-integration-guide
    provides: Integration guide voice/format model (COMPASSV2-INTEGRATION.md)
  - phase: 21-xp-gem-endpoints
    provides: POST /api/xp/award and POST /api/gems/award service-to-service endpoints
provides:
  - Canonical Essentials integration reference (docs/ESSENTIALS-INTEGRATION.md)
  - Jurisdiction decision tree pattern for detecting anonymous vs Connected state
  - EDOC requirements addressed: EDOC-01 through EDOC-06
affects:
  - essentials-repo (primary consumer of this guide)
  - any-future-external-app (auth flow and jurisdiction patterns reusable)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Jurisdiction detection via GET /api/account/me — three-branch pattern (no token, 401, 200 with/without jurisdiction)"
    - "never ask a Connected user for their address — jurisdiction pre-populates locality"
    - "Connected enhancements (XP/gems) as opt-in on top of fully functional Inform baseline"
    - "Service-to-service award calls with X-Service-Key header (not user token)"
    - "Deterministic idempotency keys: {app}:{action}:{user_id}:{context}"

key-files:
  created:
    - docs/ESSENTIALS-INTEGRATION.md
  modified: []

key-decisions:
  - "Inform is the baseline: Essentials must work fully for anonymous users — Connected is additive"
  - "Never prompt for location consent in Essentials: accounts app owns that flow exclusively"
  - "Connected-without-jurisdiction treated same as Inform for location UI, but XP/gem awards still apply"
  - "GEOID format is numeric TIGER/Line (e.g. '1807'), not state-abbreviation notation"
  - "XP source and service key must be provisioned by Accounts team before first production award"

patterns-established:
  - "detectUserState() returns typed union: inform | connected_with_jurisdiction | connected_no_jurisdiction"
  - "handleAuthReturn() + detectUserState() called on every app init and route change"

# Metrics
duration: 5min
completed: 2026-03-19
---

# Phase 33 Plan 01: Essentials Integration Guide Summary

**Canonical Essentials integration reference documenting jurisdiction detection pattern, three-branch user state model, auth redirect flow, and opt-in XP/gem award endpoints with TIGER/Line GEOID formats**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-19T18:03:15Z
- **Completed:** 2026-03-19T18:08:19Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Created `docs/ESSENTIALS-INTEGRATION.md` (654 lines) — the canonical integration reference for the Essentials team
- Documented three-branch user state detection (no token / 401 / 200 with or without jurisdiction) with TypeScript canonical example
- Framed Connected enhancements (XP, gems) as opt-in additions on top of a fully functional Inform baseline
- Defined all 10 jurisdiction fields with TIGER/Line GEOID formats and real production examples
- Covered auth redirect flow, token extraction, and token lifecycle matching the CompassV2 guide pattern
- Integrated EDOC-01 through EDOC-06 checklist items throughout and in the final checklist section

## Task Commits

Each task was committed atomically:

1. **Task 1: Write docs/ESSENTIALS-INTEGRATION.md** - `de8ff76` (docs)

**Plan metadata:** (forthcoming — see final commit below)

## Files Created/Modified

- `docs/ESSENTIALS-INTEGRATION.md` — Canonical Essentials integration guide (jurisdiction detection, auth flow, XP/gem awards, integration checklist)

## Decisions Made

- **Inform is the unconditional baseline** — Essentials must be fully functional for anonymous users. Connected enhances, never gates.
- **Connected-without-jurisdiction treated same as Inform for location UI** — but XP/gem awards remain available since the user IS Connected.
- **Never prompt for location consent** — accounts app owns location consent exclusively. Essentials only reads jurisdiction if it exists; shows address input if it does not.
- **Numeric TIGER/Line GEOIDs throughout** — `"1807"` for Indiana's 7th, `"18030"` for Indiana Senate District 30. No state-abbreviation-plus-number format.
- **Service key provisioning is operational, not a code blocker** — implementation documents the pattern; keys provisioned separately before production award calls.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

Minor: `contains: "never ask"` check in the plan required lowercase match. Initial draft had "Never ask" (capitalized heading). Fixed by adding lowercase usage in body prose ("You must never ask a Connected user..."). Also, anti-pattern callouts initially included the exact string the plan forbade ("IN-07"); reworded to convey the same warning without using the prohibited format string.

## User Setup Required

None — this plan produced documentation only.

## Next Phase Readiness

Phase 33 is the final phase of v1.5. All three phases complete:
- Phase 31: Location Trust Flow (quick task 002 — jurisdiction exposure)
- Phase 32: CompassV2 Integration Guide (docs/COMPASSV2-INTEGRATION.md)
- Phase 33: Essentials Integration Guide (docs/ESSENTIALS-INTEGRATION.md)

Both integration guides are ready for their respective consumer teams. No blockers on the Accounts side.

---
*Phase: 33-essentials-integration-guide*
*Completed: 2026-03-19*
