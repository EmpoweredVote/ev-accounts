---
phase: 32-compassv2-integration-guide
plan: 01
subsystem: docs
tags: [compass, auth, jwt, supabase, jurisdiction, typescript, integration]

# Dependency graph
requires:
  - phase: 18-compassv2-accounts-backend
    provides: All compass API endpoints this guide documents
  - phase: 19-location-schema-rpcs
    provides: Jurisdiction fields on /api/account/me
  - phase: 24-auth-hub
    provides: Auth Hub redirect flow and hash-fragment token delivery
provides:
  - Canonical CompassV2 integration reference replacing COMPASS_CONTRACT.md
  - Auth redirect flow documented with TypeScript code examples (CDOC-01)
  - All 16 endpoints with request/response shapes (CDOC-02)
  - Tier access rules (Inform / Connected / Empowered) documented (CDOC-03)
  - Jurisdiction "never ask for address" principle documented (CDOC-04)
  - Platform context and tier model documented (CDOC-05)
  - Sole canonical reference established, old contract deleted (CDOC-06)
affects:
  - CompassV2 frontend repo (primary consumer)
  - Any future external app integrating with Empowered Accounts API

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Hash fragment token delivery: tokens returned as #access_token= never in query params"
    - "Redirect-only auth for external apps: external apps never call /auth/login directly"
    - "Tier = child record presence: connected_profiles/empowered_profiles rows, never a flag"

key-files:
  created:
    - docs/COMPASSV2-INTEGRATION.md
  modified:
    - docs/COMPASS_CONTRACT.md (deleted)

key-decisions:
  - "COMPASS_CONTRACT.md deleted without symlink/redirect — it described the wrong auth pattern (direct login). The replacement is structurally different, not an update."
  - "Hash fragment explanation included verbatim — this is not obvious to frontend devs and is frequently implemented wrong"
  - "Jurisdiction given first-class section status, not footnote — it is a platform design principle, not an API detail"
  - "Anti-patterns written as blockquotes at point of relevance (not consolidated) — so an AI consuming this doc encounters the warning exactly where the mistake would be made"

patterns-established:
  - "Integration guides: 10-section structure (quick ref → context → auth → reads → writes → profile → jurisdiction → migration → errors → checklist)"
  - "Anti-patterns: inline at point of relevance, not consolidated at bottom"

# Metrics
duration: 15min
completed: 2026-03-19
---

# Phase 32 Plan 01: CompassV2 Integration Guide Summary

**745-line ground-up integration guide replacing COMPASS_CONTRACT.md: covers Auth Hub redirect flow, all 16 endpoints with TypeScript shapes, three-tier access rules, jurisdiction personalization principle, and 8 anti-patterns at point of relevance**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-03-19T15:31:36Z
- **Completed:** 2026-03-19T15:46:00Z
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 deleted)

## Accomplishments

- Wrote 745-line `docs/COMPASSV2-INTEGRATION.md` covering all 6 CDOC requirements
- Deleted outdated `docs/COMPASS_CONTRACT.md` (described direct login, wrong auth pattern for external apps)
- All 14 verification checks pass: file existence, content coverage across CDOC-01 through CDOC-05, 400+ line threshold

## Task Commits

Each task was committed atomically:

1. **Task 1: Write docs/COMPASSV2-INTEGRATION.md** - `af463d7` (docs)
2. **Task 2: Delete docs/COMPASS_CONTRACT.md** - `d7bb11b` (fix)

**Plan metadata:** `(pending — created after this summary)`

## Files Created/Modified

- `docs/COMPASSV2-INTEGRATION.md` — 745-line canonical CompassV2 integration reference with 10 sections
- `docs/COMPASS_CONTRACT.md` — deleted (superseded)

## Decisions Made

- **No symlink/redirect from COMPASS_CONTRACT.md:** The old file documented the wrong auth pattern (direct POST /auth/login). Keeping any pointer to it would cause confusion. Hard delete only.
- **Hash fragment rationale included:** Frontend devs frequently implement this wrong (storing in URL, logging tokens). The "why" is load-bearing — included verbatim.
- **Jurisdiction as Section 7 (first-class):** Not a footnote. This is a platform design principle — "never ask for address" — that CompassV2 could easily violate. Elevated to named section with anti-pattern blockquote.
- **Anti-patterns at point of relevance:** 8 blockquotes placed at the exact endpoint or pattern where the mistake would occur. An AI consuming this document will encounter the warning exactly when it's making the relevant implementation decision.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `docs/COMPASSV2-INTEGRATION.md` is ready to share with CompassV2 repo as the integration reference
- CompassV2 team can implement the full auth redirect flow, all compass endpoints, and jurisdiction personalization without reading accounts source code
- Phase 33 (if any) can proceed — Phase 32 blocker resolved: CompassV2 unblocked

---
*Phase: 32-compassv2-integration-guide*
*Completed: 2026-03-19*
