# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-24)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** v1.7 — Phase 39: Schema and Infrastructure Preparation

## Current Position

Phase: 39 of 44 (Schema and Infrastructure Preparation)
Plan: 0 of TBD in current phase
Status: Ready to plan
Last activity: 2026-02-24 — Roadmap created for v1.7 LA County Data Enrichment (6 phases, 21 requirements mapped)

Progress: [░░░░░░░░░░] 0% (v1.7)

## Performance Metrics

**Velocity (v1.0):** 7 phases, 21 plans
**Velocity (v1.1):** 3 phases, 3 plans
**Velocity (v1.2):** 6 phases, 12 plans, 27 tasks
**Velocity (v1.3):** 4 phases, 7 plans
**Velocity (v1.4):** 5 phases, 9 plans
**Velocity (v1.5):** 6 phases, 13 plans, 25 tasks
**Velocity (v1.6):** 7 phases, 11 plans, 23 tasks

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Key v1.7 decisions locked during research:
- Photo re-hosting to Supabase Storage is IN SCOPE (not deferred) — hotlinking 89 government URLs will break silently within 2-4 years
- photo_license column required before any headshot is stored — CA government photos are not automatically public domain
- term_date_precision column required before any term dates are stored — "2024-01-01" displays as "Jan 2024" without it

### Pending Todos

None.

### Blockers/Concerns

- Phase 39 (pre-planning): Verify Supabase Storage Python upload pattern against current docs before writing upload function — base64 encoding corrupts image files; content-type must be explicit
- Phase 39 (pre-planning): Run Wikidata SPARQL query for LA County city hall P18 images before Phase 41 to size building photo scope correctly
- Phase 39 (pre-planning): Confirm composite unique constraint exists on politician_contacts in models.go before Phase 41 contact upserts run
- Phase 40 (pre-planning): photo_license review workflow decision needed — serve "scraped_no_license" images immediately or gate on manual review per city batch

## Session Continuity

Last session: 2026-02-24
Stopped at: Roadmap created, ready to plan Phase 39
Resume file: None
