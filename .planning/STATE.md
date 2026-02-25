---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: LA County Data Enrichment
status: unknown
last_updated: "2026-02-25T18:11:45.186Z"
progress:
  total_phases: 4
  completed_phases: 3
  total_plans: 9
  completed_plans: 8
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-24)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** v1.7 — Phase 42: City Council Headshot Pipeline

## Current Position

Phase: 42 of 44 (City Council Headshot Pipeline)
Plan: 1 of 2 in current phase — COMPLETE
Status: Active
Last activity: 2026-02-25 — Completed 42-01 scrape_city_headshots.py batch scraper

Progress: [█████░░░░░] 50% (v1.7 — 8/8 plans complete in phases 39+40-01+40-02+41-01+41-02+41-03+42-01)

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

Key v1.7 decisions from 40-02 execution:
- scrape_headshots.py ran cleanly on first attempt — all 20 officials processed (19 uploaded, 1 skipped Monica Rodriguez), idempotent re-run confirmed no duplicates
- Human checkpoint approved: headshots visible on essentials app profile pages, loading from *.supabase.co CDN URLs verified via DevTools

Key v1.7 decisions from 41-01 execution:
- buildingImages.js CURATED_LOCAL uses hardcoded CDN URLs (not new Go API endpoint) — simpler for fixed 11 cities, avoids architectural complexity
- LA City (0644000) now served from Supabase CDN instead of static /images/la-city-hall.jpg — CDN is re-scrape-safe
- All 11 Wikimedia Commons city hall photos confirmed available and uploaded with 0 errors on first run

Key v1.7 decisions from 41-02 execution:
- import_term_dates.py uses urlparse pattern (not psycopg2.connect(url)) — pooler URL with @ in password fails direct connect; urlparse extracts components as kwargs
- TermDatePrecision wired through all 3 DB query paths (fetchOfficialsFromDB, fetchFederalAndStateFromDBFiltered, GetPoliticianByID); Cicero legacy path left without precision
- formatTermDate uses parseInt(dateStr, 10) for year precision — avoids UTC timezone bug where new Date('2024') shows 'Dec 2023' in US local timezone
- City council term dates deferred — city_sources.json has no election_year field; requires per-city research in future phase
- [Phase 41]: Name-based matching used for city roster politicians instead of OCD-ID join — scraped roster politicians have office_id=null so district join returns 0 results; name matching achieves 97% hit rate
- [Phase 42-city-council-headshot-pipeline]: extract_headshot_url uses 3-strategy cascade (name proximity, alt-text, Wikipedia) — returns None over wrong image; false negatives preferred over false positives
- [Phase 42-city-council-headshot-pipeline]: Cloudflare detection requires BOTH status code AND cf-ray/server header — plain 403 from nginx is marked failed (retries), not blocked (skipped forever)

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
Stopped at: Completed 42-01-PLAN.md — Task 1 committed (07ea1bc in EV-Backend repo); Task 2 validation passed (no code changes needed); Plan 42-01 complete
Resume file: None
