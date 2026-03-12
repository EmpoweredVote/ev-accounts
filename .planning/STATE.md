---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: planning
stopped_at: Completed 82-02-PLAN.md
last_updated: "2026-03-12T22:07:36.807Z"
last_activity: 2026-03-12 — Completed quick task 9: Fix organization display names for Ellettsville, Richland Township, Richland-Bean Blossom
progress:
  total_phases: 6
  completed_phases: 6
  total_plans: 13
  completed_plans: 13
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
Last activity: 2026-03-12 — Completed quick task 10: Refactor contact info section (domain-only websites, social icons in websites column, narrower phone column, ev-ui v0.1.48)

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
- [Phase 78-visual-refresh]: Phase 78-02: Amber (#b45309) / cyan (#0e7490) swipe pair established — semantically aligns with Gold/Diamond badge system in ResultsPhase
- [Phase 78-visual-refresh]: Phase 78-02: Stack shadow applied via inline boxShadow in Framer Motion style prop — keeps animation values intact without CSS class conflicts
- [Phase 78-visual-refresh]: Phase 78-03: Solid bg-ev-coral button replaces gradient for Explore More Issues — matches CompassV2 primary button convention
- [Phase 78-visual-refresh]: Phase 78-03: Amber/cyan verdict badge pair (disagreed=amber-700, agreed=cyan-700) mirrors EvaluationPhase swipe pair
- [Phase 79]: QuoteVerdict composite unique index: identical uniqueIndex tag name on both UserID and QuoteID fields is the GORM composite unique constraint pattern
- [Phase 79]: POST /compass/verdicts returns full user verdict set after commit for simpler frontend state replacement
- [Phase 79-02]: Conditional WHERE clause built by string concatenation before db.DB.Raw() call — avoids GORM subquery complexity while keeping all existing query structure intact
- [Phase 80-ev-ui]: StanceAccordion uses inline styles (not Tailwind) for verdict badge spans — no Tailwind dependency in ev-ui library
- [Phase 80-ev-ui]: apiUrl prop with default 'https://api.empowered.vote' replaces VITE_API_URL in StanceAccordion — makes component usable in any consumer without build env dependency
- [Phase 81-profile-integration]: Phase 81-01: verdictsByTopic removed from collapsed-row render; verdictsByQuote prop added for per-topic quote cards with verdict badges in expanded rows
- [Phase 81-profile-integration]: Phase 81-01: ev-ui quotesCache uses null sentinel (not []) to distinguish unfetched from fetched-but-empty; fetched once per politicianId mount
- [Phase 81-02]: buildVerdictFragment encodes ALL session verdicts across all issues — not scoped per candidate link — so one fragment covers the full session
- [Phase 81-02]: EV-readrank is a standalone git repo (separate from workspace root); commits go in EV-readrank/.git, not workspace root
- [Phase 81-profile-integration]: Phase 81-03: parseCompassFragment returns non-null for verdict-only fragments — answers field is nullable
- [Phase 81-profile-integration]: Phase 81-03: fragment.answers null check prevents convertGuestAnswersToApiFormat crash on verdict-only fragments
- [Phase 82-logged-in-sync]: Phase 82-02: fetchUserVerdicts returns {} on error — matches CompassContext.verdicts state shape directly; called only inside authRes.ok guard
- [Phase 82]: useAuthState uses local React state only — auth is server-authoritative, not persisted to Zustand/localStorage
- [Phase 82]: hasSynced ref (not state) guards duplicate POSTs — avoids re-render cycle while still preventing wasteful requests
- [Phase 82]: postVerdicts returns early on empty payload — no POST fired for users who skipped all quotes

### Pending Todos

- 12 politicians have no Read & Rank quotes (carried from v1.8)

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 7 | Remove party mentions from EV-ReadRank results page | 2026-03-12 | bc10639 | [7-remove-party-mentions-from-ev-readrank-r](./quick/7-remove-party-mentions-from-ev-readrank-r/) |
| 8 | Rename Commission, update Council 2025, import district geofences, upload photos | 2026-03-12 | 19131cb | [8-update-monroe-county-data-rename-commiss](./quick/8-update-monroe-county-data-rename-commiss/) |
| 9 | Fix organization display names for Ellettsville, Richland Township, Richland-Bean Blossom | 2026-03-12 | 580b995 | [9-fix-organization-display-names-on-essent](./quick/9-fix-organization-display-names-on-essent/) |
| 10 | Refactor contact info section: domain-only websites, social icons in websites column, narrower phone column | 2026-03-12 | 2a382ed | [10-refactor-contact-info-section-on-politic](./quick/10-refactor-contact-info-section-on-politic/) |

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

Last session: 2026-03-12T23:45:00.000Z
Stopped at: Completed quick-10 (contact section refactor — domain-only websites, social icons moved to websites column, ev-ui v0.1.48)
Resume file: None
