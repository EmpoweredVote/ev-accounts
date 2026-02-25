---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: LA County Data Enrichment
status: unknown
last_updated: "2026-02-25T21:01:44.844Z"
progress:
  total_phases: 4
  completed_phases: 3
  total_plans: 11
  completed_plans: 10
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-24)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** v1.7 — Phase 42: City Council Headshot Pipeline

## Current Position

Phase: 42 of 44 (City Council Headshot Pipeline)
Plan: 3 of 4 in current phase — plan 03 complete, plan 04 pending
Status: Active
Last activity: 2026-02-25 — 42-03 plan complete; enhanced scraper with CSS bg-image extraction, 61 cities reset for re-processing, 17 URLs fixed

Progress: [██████░░░░] 58% (v1.7 — 10/11 plans complete: 39+40-01+40-02+41-01+41-02+41-03+42-01+42-02+42-03)

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
- [Phase 42-02]: Wikipedia Strategy 3 has false positive risk for common names — "Ray Pearl" matched historical Dr. Raymond Pearl (1879-1940), "Octavio Martinez" matched Mexican general's flag; deleted before checkpoint
- [Phase 42-02]: Name-proximity extraction covers ~16% of city council politicians (64/391) — CSS card gallery layouts with background-image CSS are invisible to BeautifulSoup/Playwright img-tag scanning; reaching 80% requires manual headshot_url curation per roster member
- [Phase 42-city-council-headshot-pipeline]: fetch_council_page uses start/stop Playwright pattern (not context manager) when keep_page=True — allows caller to keep page open for CSS extraction before closing
- [Phase 42-city-council-headshot-pipeline]: Wikipedia guard checks first paragraph for California/council/mayor terms — prevents false positives for common names matching historical figures

### Pending Todos

- **Future phase idea: Census ZCTA-to-Place ZIP mapping for city council politicians** — All 89 cities in city_sources.json have `place_geoid` (Census FIPS) and `ocd_id_base` that match 381 LOCAL/LOCAL_EXEC politicians in the districts table. A script could download the Census ZCTA-to-Place relationship file and batch-insert `zip_politicians` rows, mapping every ZIP in a city to its council members. Works perfectly for the 72 at-large cities (every ZIP → all council members). Districted cities (LA, Long Beach) would over-show council members from other districts but that's better than showing nothing. Would immediately make city council headshots visible in the essentials app without needing the BallotReady warmer. Self-contained task: one Census CSV + one Python script.

### Blockers/Concerns

- Phase 39 (pre-planning): Verify Supabase Storage Python upload pattern against current docs before writing upload function — RESOLVED in 39-02
- Phase 39 (pre-planning): Run Wikidata SPARQL query for LA County city hall P18 images before Phase 41 to size building photo scope correctly
- Phase 39 (pre-planning): Confirm composite unique constraint exists on politician_contacts in models.go before Phase 41 contact upserts run
- Phase 40 (pre-planning): photo_license review workflow decision needed — RESOLVED: serve "scraped_no_license" images immediately (no gating), track license type for compliance
- Phase 40 ongoing: Monica Rodriguez (CD7) has no available headshot portrait — only landscape action photos on district site; no Wikipedia article. May need manual research in a future pass.

## Session Continuity

Last session: 2026-02-25
Stopped at: 42-03-PLAN.md fully complete — enhanced scraper with CSS bg-image extraction (Strategies 1b/2b), Playwright CSS extraction, manual override support, Wikipedia false-positive guard, --force-retry flag; 61 cities reset for re-processing; ready for 42-04
Resume file: None
