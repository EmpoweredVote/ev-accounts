---
gsd_state_version: 1.0
milestone: v2026.3.7
milestone_name: Treasury Tracker Expansion
status: planning
stopped_at: Roadmap created — ready to plan Phase 92
last_updated: "2026-03-22"
last_activity: "2026-03-22 — Roadmap created for v2026.3.7 Treasury Tracker Expansion"
progress:
  total_phases: 5
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-22)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** Phase 92 — Schema Foundation & Bloomington Migration

## Current Position

Phase: 92 of 96 (Schema Foundation & Bloomington Migration)
Plan: 0 of TBD in current phase
Status: Ready to plan
Last activity: 2026-03-22 — Roadmap created for v2026.3.7 Treasury Tracker Expansion

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity (v2026.3.6):** 7 phases, 15 plans, 3 days
**Velocity (v2026.3.5):** 3 phases, 5 plans, 1 day
**Velocity (v2026.3.4):** 6 phases, 13 plans, 1 day

*Updated after each plan completion*

## Accumulated Context

### Decisions

- Schema gate: Three-column unique index on treasury.budgets (city_id, fiscal_year, dataset_type) must deploy before any import — missing dataset_type causes silent duplicates or constraint violations
- Schema gate: fiscal_year_start_month added to treasury.budgets before CA data; Indiana = 1 (Jan), California = 7 (Jul)
- Go backend kept for this milestone; Express port deferred to separate future milestone
- Visual refresh: EV tokens apply to UI chrome only; chart segment fills use separate --data-* namespace to preserve 30-color perceptual distinctiveness
- LA data source: Use data.lacounty.gov expenditure transactions — not CEO PDF (PDF parsing produces 10-40% amount errors from merged cells)
- Checkbook transactions (282K rows) deferred to v2+; not imported this milestone

### Pending Todos

- 12 politicians have no Read & Rank quotes (carried from v1.8)

### Blockers/Concerns

- Phase 93 start: Download and inspect Indiana Gateway sample files for Ellettsville and Monroe County before writing transforms — column schema confirmed at medium confidence only
- Phase 94 start: Verify data.lacounty.gov Socrata dataset IDs for department-level expenditures (30-minute investigation) before writing LA County import script

## Session Continuity

Last session: 2026-03-22
Stopped at: Roadmap created, ready to plan Phase 92
Resume file: None
