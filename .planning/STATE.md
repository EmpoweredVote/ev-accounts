# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-24)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** v1.7 — Phase 39: Schema and Infrastructure Preparation

## Current Position

Phase: 39 of 44 (Schema and Infrastructure Preparation)
Plan: 2 of 2 in current phase
Status: Checkpoint — awaiting human verify (Supabase bucket creation + credential test)
Last activity: 2026-02-25 — Completed 39-02 Python Supabase upload utilities and pipeline_config.json (checkpoint at Task 3: bucket setup)

Progress: [██░░░░░░░░] 20% (v1.7 — 2/2 plans complete in phase 39, pending bucket verify)

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

Key v1.7 decisions from 39-01 execution:
- BuildingPhoto uses PlaceGeoid (Census GEOID string, size:20) as primary key — GEOIDs are stable, globally unique government identifiers that serve as natural PKs without needing surrogate keys
- New fields (PhotoLicense, TermDatePrecision) use omitempty JSON tags for backward-compatible API responses

Key v1.7 decisions from 39-02 execution:
- Supabase import is lazy (inside get_supabase_client) to avoid requiring the package for DB-only scripts
- upload_photo_to_storage() uses explicit content-type — SDK defaults to text/plain which corrupts image serving
- upsert=true on upload so re-running scripts is idempotent — same CDN URL on overwrite
- pipeline_config.json is separate from city_sources.json — v1.7 enrichment master config vs v1.6 scraper config
- Ext ID counter advanced to -300001 for v1.7 to avoid collisions with v1.6 IDs

### Pending Todos

None.

### Blockers/Concerns

- Phase 39 (pre-planning): Verify Supabase Storage Python upload pattern against current docs before writing upload function — base64 encoding corrupts image files; content-type must be explicit
- Phase 39 (pre-planning): Run Wikidata SPARQL query for LA County city hall P18 images before Phase 41 to size building photo scope correctly
- Phase 39 (pre-planning): Confirm composite unique constraint exists on politician_contacts in models.go before Phase 41 contact upserts run
- Phase 40 (pre-planning): photo_license review workflow decision needed — serve "scraped_no_license" images immediately or gate on manual review per city batch

## Session Continuity

Last session: 2026-02-25
Stopped at: 39-02-PLAN.md checkpoint — Task 3 (human-verify: Supabase bucket creation and credential test). Tasks 1-2 committed (570cc9c, 1944124 in EV-Backend repo).
Resume file: None
