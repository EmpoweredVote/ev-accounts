---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: planning
stopped_at: Completed 85-01-PLAN.md — Phase 85 ReadRank header auth integration complete
last_updated: "2026-03-13T02:21:25.889Z"
last_activity: "2026-03-13 - Completed quick task 12: Extract treasury-tracker, empowered-badges, fallacy-finders to standalone GitHub repos"
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 5
  completed_plans: 5
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-12)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** Milestone v2026.3.5 — Unified Navigation Header

## Current Position

Phase: 83 of 85 (ev-ui SiteHeader URL Update)
Plan: —
Status: Ready to plan Phase 83
Last activity: 2026-03-13 - Completed quick task 12: Extract treasury-tracker, empowered-badges, fallacy-finders to standalone GitHub repos

Progress: [░░░░░░░░░░] 0% (milestone v2026.3.5)

## Performance Metrics

**Velocity (v2026.3.4):** 6 phases, 13 plans, 1 day
**Velocity (v2026.3.3):** 5 phases, 6 plans, 2 days
**Velocity (v2026.3.2):** 5 phases, 8 plans, 3 days
**Velocity (v2026.4):** 7 phases, 24 plans, 2 days

*Updated after each plan completion*

## Accumulated Context

### Decisions

- Phase 83 must publish before Phase 84 or 85 can install the updated ev-ui package
- Phase 84 and Phase 85 are independent of each other — can plan/execute in either order after Phase 83 ships
- Sign in links in both Essentials and ReadRank point to compass.empowered.vote/login (no local login page)
- Logout in Essentials resets local app state; no redirect to Compass (each app stays on its own page)
- [Phase 83-01]: Treasury Tracker and Empowered Badges hrefs left on Netlify — no standalone domain assigned yet
- [Phase 83-01]: ev-ui is its own git repo; task commits go to the ev-ui sub-repo, not workspace root
- [Phase 84-01]: Layout always passes profileMenu so profile button always appears; logged-out users see Sign In link to compass.empowered.vote/login
- [Phase 84-01]: logout() resets userAnswers, selectedTopics, verdicts in addition to auth state
- [Phase 84-02]: Layout uses named export (export function Layout), imported with { Layout } destructuring in all pages
- [Phase 84-02]: returnTo query param passed to compass.empowered.vote/login so user lands back in Essentials after auth
- [Phase 85-01]: ev-ui 0.1.49 ships no .d.ts files — profileMenu prop passed via spread cast to satisfy TypeScript without patching the library
- [Phase 85-01]: profileMenu is undefined during loading state to prevent Sign in flash for logged-in users in ReadRank

### Pending Todos

- 12 politicians have no Read & Rank quotes (carried from v1.8)

### Blockers/Concerns

- Phase 83 must be published to GitHub npm registry before Phase 84/85 can consume updated SiteHeader URLs
- Phase 84: Essentials CompassContext already has isLoggedIn and userName — no new auth plumbing needed, just wire to Layout

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 11 | Fix Monroe County Council data: Liz Feitl at-large seat and missing district members | 2026-03-13 | 75045fd | [11-fix-monroe-county-council-data-liz-feitl](./quick/11-fix-monroe-county-council-data-liz-feitl/) |
| 12 | Extract treasury-tracker, empowered-badges, fallacy-finders to standalone GitHub repos; clean EV-prototypes | 2026-03-13 | aa5202c | [12-move-treasury-tracker-empowered-badges-a](./quick/12-move-treasury-tracker-empowered-badges-a/) |

### Tech Debt Carried Forward

- Dead `ballotready/` package preserved (from v1.5)
- Orphaned `checkCacheStatus` in essentials `api.jsx` (from v1.5)
- 5 district-election cities treated as at-large (from v1.6)
- `fetchPoliticiansOnce` and `fetchPoliticiansProgressive` deprecated but not deleted (from v1.9)
- `leg_data_fetched_at` column unused (from v2026.3)
- Topic tags placeholder div in LegislativeInlineSummary (from v2026.3)

## Session Continuity

Last session: 2026-03-13T02:30:00.000Z
Stopped at: Completed quick task 12 — awaiting human verification of standalone repos
Resume file: None
