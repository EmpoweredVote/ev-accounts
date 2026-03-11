---
gsd_state_version: 1.0
milestone: v2026.3.3
milestone_name: Local Government Organization
status: ready_to_plan
stopped_at: null
last_updated: "2026-03-10"
last_activity: "2026-03-10 — Roadmap created, 5 phases defined (72-76)"
progress:
  total_phases: 5
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-10)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** v2026.3.3 Local Government Organization — Phase 72: DB Audit

## Current Position

Phase: 72 of 76 (DB Audit)
Plan: Not started
Status: Ready to plan
Last activity: 2026-03-10 — Roadmap created with 5 phases (72-76), 12/12 requirements mapped

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity (v2026.3.2):** 5 phases, 8 plans
**Velocity (v2026.4):** 7 phases, 24 plans
**Velocity (v2026.3):** 6 phases, 19 plans

*Updated after each plan completion*

## Accumulated Context

### Key Decisions for This Milestone

- Phase 72 (DB audit) gates all classification code — must confirm chamber_name_formal values before writing any body_key logic
- GovernmentBody table uses composite unique (state, geo_id, body_key) — upsert-safe, follows PositionDescription enrichment pattern
- body_key derived by classify.go (Go mirror of classify.js) — ensures JOIN keys match frontend classification
- Phase 75 (ev-ui) can run in parallel with Phases 73-74 — no backend dependency for the prop addition
- Use government_body_name from API directly for section headers — never pass through qualifyLocalTitle() (causes double-prefix)
- classify.js LOCAL_ORDER, CATEGORY_DISPLAY_NAMES, GROUP_SORT_OPTIONS must always update atomically in the same commit

### Tech Debt Carried Forward (from v2026.3.2)

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

- Phase 72 critical branch: if chamber_name_formal is unpopulated for Indiana chambers, Phase 73 becomes a data migration before a feature phase — plan for both outcomes

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 5 | Candidate profile system with compass stances and show-candidates filter | 2026-03-08 | 2657f3d | [5-create-candidate-profile-system-with-com](./quick/5-create-candidate-profile-system-with-com/) |
| 6 | Column-per-category contact info layout in PoliticianProfile | 2026-03-08 | 1b91b91 | [6-improve-contact-info-section-on-profile-](./quick/6-improve-contact-info-section-on-profile-/) |

## Session Continuity

Last session: 2026-03-10
Stopped at: Roadmap created for v2026.3.3, ready to plan Phase 72
Resume: Start with `/gsd:plan-phase 72`
