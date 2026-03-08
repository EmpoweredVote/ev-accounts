---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: completed
stopped_at: Completed 69-01-PLAN.md
last_updated: "2026-03-08T02:19:04.167Z"
last_activity: "2026-03-08 — Phase 69 Plan 01: CompassCard shell with gating, skeleton, and CTA"
progress:
  total_phases: 5
  completed_phases: 3
  total_plans: 6
  completed_plans: 6
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-06)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** Phase 69 — Compass Card Shell

## Current Position

Phase: 69 of 71 (Compass Card Shell) — COMPLETE
Plan: 1 of 1 complete
Status: Phase 69 complete
Last activity: 2026-03-08 — Phase 69 Plan 01: CompassCard shell with gating, skeleton, and CTA

Progress: [██████████] 100%

## Performance Metrics

**Velocity (v2026.4):** 7 phases, 24 plans
**Velocity (v2026.3):** 6 phases, 19 plans
**Velocity (v1.9):** 3 phases, 6 plans

*Updated after each plan completion*

## Accumulated Context

### Architectural Decisions for This Milestone

- CompassV2 and Essentials are SEPARATE React apps on different Netlify origins — cannot share localStorage directly
- RadarChartCore in ev-ui already supports dual dataset overlay (pink user + blue politician) — no new component needed
- Existing compass API endpoints: /compass/topics, /compass/answers, /compass/stances
- 455 politician stance rows in DB across 23 politicians (from v1.8)
- Essentials uses `credentials: "include"` for all API calls — same pattern needed for compass API calls
- Guest compass data problem: CompassV2 writes to its own origin's localStorage; Essentials cannot read it — Phase 68 must solve this
- Cookie Domain branching: PORT env var (empty/5050 = local dev, no Domain; anything else = production, Domain ".empowered.vote") — 67-01
- fetchUserAnswers/fetchSelectedTopics check res.status === 401 explicitly so unauthenticated Essentials users get [] silently — 67-01
- Fixed-position overlay for AuthIndicator (top: 16px, right: 16px) since SiteHeader has no rightSlot prop — only profileMenu dropdown — 67-02
- CompassProvider fetches auth check and public compass data concurrently; user-specific data gated on authRes.ok — 67-02
- politicianIdsWithStances stored as Set for O(1) lookup — ready for profile page badge rendering — 67-02
- CompassPreview uses createPortal(popover, document.body) + position:fixed — avoids overflow:hidden clipping in scrollable panels — 67-03
- renderPoliticianCard moved inside Results component to access politicianIdsWithStances via closure — avoids prop drilling — 67-03
- Click-to-toggle for compass badge (not hover) — PoliticianCard ev-ui doesn't expose onMouseEnter on its internal compass button — 67-03
- data-pol-id attribute on card wrappers + querySelector to resolve badge button element ref after render — 67-03
- Compass badge button shrunk from 36px to 28px in ev-ui PoliticianCard (user-directed at checkpoint) — 67-03
- CompassPreview CTA mode: greyed compass icon + Take the Quiz link when user has no compass answers — 67-03
- RadarChartCore capped at 8 spokes max in CompassPreview to prevent label crowding in 180px mini chart — 67-03
- URL fragment bridge format: #compass=BASE64({"a":{[short_title]:value},"s":[uuid,...]}) — cross-origin guest data transfer — 68-01
- Fragment parsed synchronously BEFORE any async awaits in CompassContext loadAll() — ensures URL is clean before React renders and value captured — 68-01
- CTA same-tab navigation with ?return= param (no target=_blank) — enables return banner flow in Plan 02 — 68-01
- clearGuestCompass() on logged-in path — logged-in users always get API data, stale guest cache cleared on login — 68-01
- ReturnBanner uses sessionStorage (SESSION_KEY) for URL persistence — survives React Router navigations and HelpGuard redirects within session — 68-02
- ReturnBanner is fixed position (z-[60]) above CalibrationOverlay (z-50), with sibling spacer div to prevent content overlap — 68-02
- serializeCompassFragment encodes {a, s, i} (answers, selectedTopics, invertedSpokes) — complete state for Essentials decoder — 68-02
- ComparePanel Essentials link uses same-tab navigation — guest is navigating TO Essentials as destination — 68-02
- CompassCard self-gating pattern: component returns null internally when politician lacks stances — parent passes props, child decides rendering — 69-01
- Fragment wrapper in Profile.jsx ternary to support PoliticianProfile + CompassCard as siblings — 69-01

### Tech Debt Carried Forward (from v2026.4)

- Dead `ballotready/` package preserved for historical reference (from v1.5)
- Orphaned `checkCacheStatus` in essentials `api.jsx` (from v1.5)
- 5 district-election cities treated as at-large (from v1.6)
- `fetchPoliticiansOnce` and `fetchPoliticiansProgressive` deprecated but not deleted in essentials `api.jsx` (from v1.9)
- `leg_data_fetched_at` column unused (from v2026.3)
- Topic tags placeholder div in LegislativeInlineSummary (from v2026.3)

### Pending Todos

- 12 politicians have no Read & Rank quotes (carried from v1.8)
- Future: Census ZCTA-to-Place ZIP mapping for city council politicians

### Blockers/Concerns

None yet.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 5 | Candidate profile system with compass stances and show-candidates filter | 2026-03-08 | 2657f3d | [5-create-candidate-profile-system-with-com](./quick/5-create-candidate-profile-system-with-com/) |

## Session Continuity

Last session: 2026-03-08T02:15:36Z
Stopped at: Completed 69-01-PLAN.md
Resume: Phase 69 complete. CompassCard shell created with gating logic, skeleton layout, and CTA fallback. Integrated into Profile.jsx. Ready for Phase 70 (radar chart) and Phase 71 (stance breakdown).
