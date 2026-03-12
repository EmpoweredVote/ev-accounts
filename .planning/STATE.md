---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: planning
stopped_at: Completed 78-visual-refresh 78-01-PLAN.md
last_updated: "2026-03-12T02:52:47.168Z"
last_activity: 2026-03-11 — Roadmap created for v2026.3.4 (6 phases, 20/20 requirements mapped)
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 5
  completed_plans: 3
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-11)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** Phase 77 — Standalone Extraction

## Current Position

Phase: 77 of 82 (Standalone Extraction)
Plan: 0 of TBD in current phase
Status: Ready to plan
Last activity: 2026-03-11 — Roadmap created for v2026.3.4 (6 phases, 20/20 requirements mapped)

Progress: [░░░░░░░░░░] 0% (milestone v2026.3.4)

## Performance Metrics

**Velocity (v2026.3.3):** 5 phases, 6 plans, 2 days
**Velocity (v2026.3.2):** 5 phases, 8 plans, 3 days
**Velocity (v2026.4):** 7 phases, 24 plans, 2 days
**Velocity (v2026.3):** 6 phases, 19 plans, 4 days

*Updated after each plan completion*

## Accumulated Context

### Decisions

- Phase 77: Extract with zero behavior changes before any visual or feature work — extraction first, verify identical, then layer features
- Phase 79: Verdicts belong in `compass.` schema alongside answers (not a new schema); QuoteVerdict model mirrors CompassAnswer pattern
- Phase 80: ev-ui must publish v0.1.42+ before Phase 81 can consume the new StanceAccordion prop — cross-repo dependency
- Phase 81: URL fragment bridge extended with `v` key for verdicts — reuses proven production mechanism; no iframe relay needed
- Phase 82: Logged-in sync is last — guest path via URL fragment is the MVP delivery; sync is an enhancement
- [Phase 77-01]: Keep src/types/ev-ui.d.ts manual shim — ev-ui 0.1.41 ships no .d.ts files
- [Phase 77-01]: migrate function uses ReadRankState cast to avoid circular init reference in TypeScript
- [Phase 77-02]: CF Pages preview builds (*.pages.dev) do not need CORS entries — only named subdomains (production and dev) require allowlist entries
- [Phase 78-visual-refresh]: Phase 78-01: Tailwind v4 requires @theme block in CSS for utility generation — color tokens defined in tailwind.config.js alone won't generate utilities; added ev-teal/ev-dark-blue aliases to both locations
- [Phase 78-visual-refresh]: Phase 78-01: ev-muted-blue (#00657c) established as primary EV accent for Read & Rank; ev-light-blue and ev-teal deprecated for accent use in IssueHub

### Pending Todos

- 12 politicians have no Read & Rank quotes (carried from v1.8)

### Blockers/Concerns

- Phase 77: `.npmrc` and `NPM_TOKEN` must be configured in Cloudflare Pages env before first CI build
- Phase 78: Document `bind()` prop locations in gesture components before any CSS changes to avoid swipe regression
- Phases 80+81: ev-ui `verdictsByTopic` prop shape and verdict enum values need agreement before either phase begins

### Tech Debt Carried Forward

- Dead `ballotready/` package preserved (from v1.5)
- Orphaned `checkCacheStatus` in essentials `api.jsx` (from v1.5)
- 5 district-election cities treated as at-large (from v1.6)
- `fetchPoliticiansOnce` and `fetchPoliticiansProgressive` deprecated but not deleted (from v1.9)
- `leg_data_fetched_at` column unused (from v2026.3)
- Topic tags placeholder div in LegislativeInlineSummary (from v2026.3)

## Session Continuity

Last session: 2026-03-12T02:52:47.166Z
Stopped at: Completed 78-visual-refresh 78-01-PLAN.md
Resume file: None
