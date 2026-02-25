# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-24)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** v1.7 — Phase 40: High-Value Headshots — Supervisors and LA City Council

## Current Position

Phase: 40 of 44 (High-Value Headshots — Supervisors and LA City Council)
Plan: 1 of 3 in current phase
Status: Active
Last activity: 2026-02-25 — Completed 40-01 headshot config registry and scrape_headshots.py script

Progress: [███░░░░░░░] 30% (v1.7 — 3/3 plans complete in phases 39+40-01)

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

Key v1.7 decisions from 40-01 execution:
- Wikipedia Commons chosen as primary source for 10 council members lacking government site portraits — CC-licensed (cc_by_sa_4.0), stable URLs, proper portrait orientation
- Monica Rodriguez (CD7) assigned null photo_url — no portrait available (only landscape action photos; no Wikipedia article)
- Storage filenames use human-readable name slugs (e.g., hilda-l-solis.jpg) not UUIDs — readable in Supabase bucket browser
- Content-type detected from HTTP response header not URL extension — government CDNs sometimes serve .jpg URLs as image/webp

### Pending Todos

None.

### Blockers/Concerns

- Phase 39 (pre-planning): Verify Supabase Storage Python upload pattern against current docs before writing upload function — RESOLVED in 39-02
- Phase 39 (pre-planning): Run Wikidata SPARQL query for LA County city hall P18 images before Phase 41 to size building photo scope correctly
- Phase 39 (pre-planning): Confirm composite unique constraint exists on politician_contacts in models.go before Phase 41 contact upserts run
- Phase 40 (pre-planning): photo_license review workflow decision needed — RESOLVED: serve "scraped_no_license" images immediately (no gating), track license type for compliance
- Phase 40 ongoing: Monica Rodriguez (CD7) has no available headshot portrait — only landscape action photos on district site; no Wikipedia article. May need manual research in a future pass.

## Session Continuity

Last session: 2026-02-25
Stopped at: Completed 40-01-PLAN.md — Tasks 1-2 committed (5a729d9, a321e54 in EV-Backend repo).
Resume file: None
