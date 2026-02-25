# Feature Research — v1.7 LA County Data Enrichment

**Domain:** Civic engagement — politician data enrichment via scraping pipeline
**Researched:** 2026-02-24
**Confidence:** HIGH (existing codebase directly inspected; SOS PDF confirmed; lavote.gov scraper output examined; Wikidata SPARQL docs verified; DB schema reviewed)

---

## Scope Note

This file covers only NEW features for v1.7. The existing infrastructure already built:
- 791 LA County politician records in `essentials.politicians` (county supervisors, all 89 city councils, school boards via SOS PDF extraction + config-driven scraper)
- `photo_origin_url` and `photo_custom_url` columns on `essentials.politicians` (already in schema)
- `PoliticianImage` model for multiple photo variants (type: "default"/"thumb")
- `PoliticianContact` model with email, phone, fax, contact_type fields
- `PoliticianProfile` component in ev-ui displaying images, bio, education, experience with initials avatar fallback
- `scrape_la_officials.py` config-driven scraper with seat-first dedup and hardcoded fallbacks
- `lavote_scraper.py` that already captures phone, office_address, term_length, year_elected for ~75 state/federal/county officials
- `city_sources.json` with 89 cities × ~4-5 council members each (382 total roster entries, name/party/role only — no photos or contact)

The enrichment pipeline must populate these existing schema fields for the ~389 LA County local officials (supervisors + city council, excluding school board).

---

## Data Availability Reality Check

Before defining features, the actual data availability for each enrichment type:

| Data Type | Source | LA County Coverage Expectation | Effort |
|-----------|--------|-------------------------------|--------|
| Headshots | Individual city council websites | ~60-75% of cities publish photos; anti-bot protection common on larger cities; many smaller cities use simple HTML | MEDIUM |
| City hall building photos | Wikidata SPARQL (P18 image, P31=city hall) + Wikimedia Commons | ~40-60% of 89 LA County cities have Wikidata entries with photos; major cities (>50K pop) likely covered | LOW-MEDIUM |
| Contact info (email, phone, website) | California SOS Roster PDF (2026 edition) | SOS PDF includes city-level phone/address/website; individual council member emails rare in SOS data | LOW for city-level, MEDIUM for member-level |
| Term/election data (elected year, term end) | lavote.gov (already scraped for 75 state/federal/county); individual city websites for city council | lavote.gov has term_length and year_elected for county supervisors; city council term data requires per-city scraping | MEDIUM |
| Biographical text | Per-city website "About" or profile pages | ~30-50% of cities have bio text per council member; inconsistent format | HIGH |
| Education/experience | Per-city profiles | Rare at city council level; more common for supervisors | HIGH |

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features voters assume exist when viewing a local politician profile. Missing these = profile feels like a stub and undermines platform credibility.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Headshot photo for county supervisors (5) | High-profile officials; photos universally available on bos.lacounty.gov | LOW | LA County BOS page has individual supervisor pages with professional headshots at predictable URLs (e.g., `bos.lacounty.gov/supervisors/supervisor-X/`). Direct img tag scraping with BeautifulSoup. Falls back to initials avatar (already built). |
| Headshot photos for LA City council members (15) | LA City is the largest jurisdiction; council members have dedicated pages on lacity.gov | LOW-MEDIUM | lacity.gov council member pages have photos. Parse council-district pages. Note: lacity.gov has historically used Cloudflare; hardcoded roster fallback pattern already established. |
| City hall building photo for LA City section | Dashboard already shows building photos for federal/state tiers. Local tier shows nothing for most cities. | LOW | LA City Hall (200 N Spring St) has extensive Wikimedia Commons coverage. Wikidata Q item for LA City Hall has P18 image. Already have Wikimedia CC photo approach from v1.1. |
| Contact website URL for each council member | Voters want to contact their representative; missing a link to the official page feels like an oversight | LOW | City council member websites exist on every city's official site. SOS PDF provides city-level website. Individual member pages discoverable from city council index URL already in `city_sources.json`. Store in `politicians.urls[]` (already a `pq.StringArray` field). |
| Term dates visible on profile page | Users want to know when a representative was elected and when their term ends | MEDIUM | `valid_from`/`valid_to` on `essentials.politicians` already exist and render via `getTermLine()` in ev-ui. lavote.gov scraper already captures `year_elected` and `term_length` for county supervisors. City council term dates require per-city scraping or SOS data extraction. |

### Differentiators (Competitive Advantage)

Features that make Empowered Vote profiles richer than a basic who-represents-me lookup.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| City hall building photos for all 89 LA County cities | Contextual visual grounding — users see the building where their council meets. No competitor covers this at city council level. | MEDIUM | Wikidata SPARQL query using P31 (instance of) = city hall, P131 (located in) = California cities. Query returns P18 (image) URLs hosted on Wikimedia Commons (CC-licensed). Store as a new `city_hall_photos` config or a separate table keyed by `place_geoid`. Map to `CategorySection` building image props in essentials frontend. ~40-60% expected coverage from Wikidata; remainder falls back to existing SVG fallback. |
| Enrichment coverage tracking (per-field completeness) | Pipeline must know what it has and what it's missing. A coverage report drives prioritization. | LOW | Add `enrichment_flags` JSONB column to `essentials.politicians` OR a separate `enrichment_status` table. Track: `has_photo`, `has_contact_email`, `has_contact_phone`, `has_term_dates`, `has_bio`. Query produces a coverage dashboard showing 389 officials × 5 fields. This is internal tooling — no UI needed, SQL view is sufficient. |
| Contact info for all 5 county supervisors | Supervisors are high-profile; voters actively seek to contact them on policy issues | LOW | LA County BOS page has phone numbers, district office addresses, and web forms per supervisor. Already captured for 2 supervisors via lavote.gov output. Extend to all 5. Populate `PoliticianContact` table (email, phone, contact_type="district"). |
| Reproducible enrichment pipeline (idempotent, config-driven) | Same approach from v1.6: scripts that can re-run without creating duplicates, parameterized by source config | MEDIUM | Extend `politician_sources.json` or a new `enrichment_sources.json` config. Each record has: `politician_id` (or name+seat matcher), `photo_url`, `contact_email`, `contact_phone`, `website`, `term_start`, `term_end`, `bio_text`. Script upserts fields that are non-empty, preserves existing data if new value is empty. |
| Headshot photos for city council members via per-city website scraping | Voters expect to recognize their council member | HIGH | Requires per-city scraper strategy. ~89 cities × varying HTML structure. Approach: (1) try img tag near politician name on known council page URL from `city_sources.json`; (2) hardcoded photo URLs for cities with anti-bot protection; (3) initials fallback already exists. 80% coverage target requires ~70+ cities to yield photos. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Automated nightly headshot re-scrape | "Keep photos fresh as officials change" | City council websites have unpredictable HTML, rate limits, and anti-bot protection. A nightly scraper would generate 89 HTTP requests per night with high failure rates. Photos don't change frequently enough to justify this. | Re-run enrichment scripts manually when a politician changes (seat-first dedup already handles this). Script is idempotent — re-run anytime. |
| Re-hosting all scraped photos to Supabase Storage | "Avoid hotlinking from city websites" | Valid concern but out of scope for v1.7 (PROJECT.md explicitly defers photo re-hosting). Adds a Supabase Storage dependency, per-image upload logic, and CDN URL management. | Store `photo_origin_url` pointing to source URL (current pattern). `photo_custom_url` column exists for when re-hosting is implemented. |
| Scraping individual council member bio text from all 89 cities | "Give voters more context about each official" | City council bio pages have radically inconsistent HTML. Many have no bio at all. ~50+ hours of custom parsing for ~30% coverage. High maintenance burden. | Populate bio only for high-profile officials (supervisors, LA City council) where bio text is consistently available. For smaller cities, leave `bio_text` empty — profile still renders cleanly with initials avatar and term dates. |
| Pulling term/election data from LAVote.gov for city council | lavote.gov already used for county/state officials | lavote.gov only covers county-wide and state offices, not individual city councils. City council term data is not on lavote.gov. | For city council: derive term_end from `year_elected + term_length` (4 years is standard in CA). Store derived `valid_to` without false precision. |
| Wikipedia/Ballotpedia scraping for politician bios | "Comprehensive bio text for all officials" | Wikipedia has inconsistent coverage for city council members. Ballotpedia has no public API; scraping is ToS violation. Both sources have outdated or missing local council data. | Use official city council bio pages as primary source. Accept partial coverage. |
| Geocoding office addresses to lat/lng | "Show district office on a map" | Adds Google Maps Geocoding API dependency (billing). Not needed for profile display. The `Address` model already stores street-level data without coordinates. | Store office addresses as text in `PoliticianContact.office_address` field. Frontend can deep-link to Google Maps with the address string if needed. |

---

## Feature Dependencies

```
City hall building photos (Wikidata SPARQL)
    └──requires──> place_geoid → city name mapping (already in city_sources.json)
    └──outputs──> Photo URLs keyed by place_geoid
    └──feeds──> essentials frontend CategorySection building image config
    └──independent of──> Headshot scraping (separate data source)

Headshot scraping (per-city websites)
    └──requires──> city council page URLs (already in city_sources.json url field)
    └──outputs──> photo_origin_url per politician_id
    └──feeds──> PoliticianImage table (existing) OR photo_origin_url on politicians
    └──hardcoded fallback──> city_sources.json roster can include photo_url field

Contact info enrichment
    └──SOS PDF (city-level)──> website, city_hall_phone per city
    └──Per-city council page (member-level)──> individual email, direct phone
    └──lavote.gov (already captured)──> county supervisors phone/address
    └──outputs──> PoliticianContact records (existing model)

Term dates enrichment
    └──lavote.gov data (year_elected, term_length)──> county supervisors → valid_from/valid_to
    └──City council: derive──> valid_to = year_elected + 4 years (CA standard)
    └──feeds──> valid_from, valid_to on essentials.politicians
    └──renders via──> getTermLine() in ev-ui@0.1.27 (already built)

Enrichment coverage tracking
    └──requires──> Enrichment scripts complete (know what populated)
    └──outputs──> SQL view or JSONB flags per politician
    └──independent of──> frontend (internal ops tool only)

Reproducible pipeline
    └──requires──> All enrichment scripts parameterized by politician_id or seat matcher
    └──enables──> Future region enrichment (e.g., Orange County) with same scripts
```

### Dependency Notes

- **Headshot scraping depends on city_sources.json URLs:** The per-city council page URLs already exist. The enrichment scraper can use them directly as entry points. No new config needed for URLs — only photo_url needs to be added to roster entries.
- **Term dates are partially solved already:** lavote.gov scraper captures `year_elected` and `term_length` for county supervisors. The `valid_from`/`valid_to` fields on politicians and the `getTermLine()` renderer are both built. The gap is a script that writes these scraped values into the DB.
- **Building photos are independent of headshots:** Wikidata query returns a batch of city hall URLs by city name. These feed a separate config (not per-politician) — keyed by `place_geoid` or city name, used by the frontend's building image system.
- **Contact info has two levels:** City-level data (city hall phone, website) comes from SOS PDF (already partially extracted in `scrape_city_councils.py`'s data_source field). Member-level data (individual email, direct line) requires per-member page scraping and has lower coverage expectations.

---

## MVP Definition

### Launch With (v1.7)

Minimum viable enrichment set targeting 80%+ coverage for headshots and contact info for ~389 officials.

- [ ] Headshot URLs for all 5 LA County supervisors — scrape from bos.lacounty.gov individual pages; store in `photo_origin_url` via enrichment upsert script
- [ ] Headshot URLs for all 15 LA City council members — scrape from lacity.gov council-district pages with hardcoded fallback
- [ ] Headshot URLs for remaining 89 LA County cities (368 council members) — config-driven per-city scraper using `city_sources.json` URLs; add `photo_url` field to roster entries in JSON; 60-80% coverage target
- [ ] City hall building photo for LA City section in frontend — Wikimedia Commons CC-licensed photo (already have approach from v1.1); wire into CategorySection building image config
- [ ] City hall building photos for top 20 LA County cities by population — Wikidata SPARQL query; store results in a new `city_hall_photos.json` config keyed by place_geoid
- [ ] Term dates for all 5 county supervisors — use lavote.gov scraper output (already captured `year_elected`, `term_length`); write upsert script to populate `valid_from`/`valid_to` on politician records
- [ ] Contact website for all 89 cities — derive from `city_sources.json` `url` field (already populated); store in `politicians.urls[]`
- [ ] Contact phone for county supervisors — already in lavote.gov output; write upsert to `PoliticianContact`
- [ ] Enrichment coverage report — SQL query or Python script reporting `has_photo`, `has_contact`, `has_term_dates` per politician; run after pipeline to confirm 80%+ targets met
- [ ] Idempotent enrichment upsert script — extend `scrape_la_officials.py` pattern; never clobbers non-empty fields with empty scraped value

### Add After Validation (v1.7.x)

- [ ] City hall building photos for remaining 69 cities — Wikidata expansion or manual curation; when coverage < 40%, SVG fallback already exists
- [ ] Bio text for county supervisors — available on individual supervisor pages; 5 records, low effort
- [ ] Bio text for LA City council members — available on lacity.gov council pages; 15 records
- [ ] Contact email for county supervisors and LA City council — email addresses on official pages; ~20 records
- [ ] Term dates for city council members — derive from election records or per-city website; CA 4-year standard allows derivation if `year_elected` known

### Future Consideration (v2+)

- [ ] Photo re-hosting to Supabase Storage — deferred per PROJECT.md out-of-scope; implement when CDN stability becomes a concern
- [ ] Automated enrichment re-run on politician change events — complex; scraper pipeline sufficient for manual re-runs
- [ ] Bio/education/experience for smaller city council members — low coverage, high per-city effort; acceptable gap for v1.7
- [ ] Scraping Ballotpedia for structured term dates — requires ToS review; better addressed by dedicated data provider

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Headshots: 5 supervisors | HIGH — high-profile, profile feels broken without photo | LOW — 5 known URLs, predictable page structure | P1 |
| Headshots: 15 LA City council | HIGH — most-visited local profiles | LOW-MEDIUM — lacity.gov pages accessible, hardcoded fallback ready | P1 |
| Building photo: LA City section | HIGH — dashboard currently shows nothing for local tier | LOW — single Wikimedia photo, existing mechanism | P1 |
| Term dates: 5 county supervisors | MEDIUM — lavote.gov already captured data; just needs DB write | LOW — upsert script using existing lavote output | P1 |
| Contact website: 89 cities | MEDIUM — minimal but expected | LOW — derive from existing city_sources.json url field | P1 |
| Enrichment coverage report | MEDIUM — ops visibility, confirms 80% target | LOW — SQL query or Python output | P1 |
| Headshots: 89 cities (368 members) | HIGH — 80% coverage target requires this | HIGH — per-city scraper, inconsistent HTML, fallback management | P1 |
| Building photos: top 20 cities | MEDIUM — polish for high-traffic city sections | LOW-MEDIUM — Wikidata SPARQL batch query | P2 |
| Contact phone: county supervisors | LOW-MEDIUM — nice to have, rarely used | LOW — data already in lavote output | P2 |
| Bio text: 5 supervisors | MEDIUM — users expect context for senior officials | LOW — 5 bos.lacounty.gov pages | P2 |
| Bio text: 15 LA City council | MEDIUM — context enrichment | LOW-MEDIUM — 15 pages, vary in structure | P2 |
| Building photos: remaining 69 cities | LOW — SVG fallback works | MEDIUM — Wikidata partial coverage | P3 |
| Education/experience: local officials | LOW — rarely available at this level | HIGH — inconsistent sourcing | P3 |

**Priority key:**
- P1: Required to hit 80% headshot/contact coverage target — core v1.7 deliverable
- P2: Significant quality improvement, ship when P1 complete
- P3: Nice to have, defer to v1.7.x or later

---

## Data Source Inventory

### Already In Use (Extend for Enrichment)

| Source | What It Has | How Already Used | Enrichment Use |
|--------|------------|-----------------|----------------|
| `lavote.gov` | phone, office_address, year_elected, term_length for ~75 state/federal/county officials | `scrapers/lavote_scraper.py` produces JSON output | Write upsert script to load lavote output → `valid_from`/`valid_to` + `PoliticianContact` |
| California SOS PDF (cities-towns.pdf 2026) | Name, title, city, city hall address for all CA incorporated cities | `scrape_city_councils.py` reads name/role from PDF | Extract city-level phone and website from PDF; store as city-scoped contact |
| `city_sources.json` council page URLs | Per-city HTML page with council member listing | Entry point for roster name scraping | Entry point for headshot img tag scraping |

### New Sources (First Use in v1.7)

| Source | What It Has | Access Method | License |
|--------|------------|--------------|---------|
| bos.lacounty.gov supervisor pages | Professional headshots, phone numbers, office addresses, bio text | HTTP GET + BeautifulSoup; no anti-bot protection observed | Public domain (government content) |
| lacity.gov council district pages | Council member headshots, bio text, committee assignments | HTTP GET; may require User-Agent header; hardcoded fallback pattern established | Public domain |
| Individual city council pages (89 cities) | Council member headshots (img tag near name); contact links | HTTP GET + BeautifulSoup; anti-bot protection varies; ~20% of cities expected to require hardcoded fallback | Public domain (government websites) |
| Wikidata SPARQL endpoint | City hall building images via P18 property; P31=city_hall + P131=California | SPARQL query via `https://query.wikidata.org/sparql`; free, no auth required | CC0 (Wikidata data), Wikimedia Commons images (CC-BY-SA or public domain) |
| Wikimedia Commons Media API | Direct image URL resolution for Wikidata P18 references | REST API: `https://commons.wikimedia.org/w/api.php?action=query&titles=File:X&prop=imageinfo` | CC-licensed (must attribute) |

---

## Scraping Strategy Notes

### Headshot Scraping Pattern

Government websites publish headshots in three common patterns:

1. **Dedicated profile page per member** (most common for supervisors and large city councils): img tag with person's name in alt text or nearby heading. Example: `bos.lacounty.gov/supervisors/supervisor-1/` contains `<img alt="Hilda L. Solis" src="/photos/solis.jpg">`.

2. **Council directory grid** (common for smaller cities): A single page lists all members with thumbnails. Locate the grid, iterate cards, extract img `src` nearest to matching name text. BeautifulSoup `find_all` + rapidfuzz name match (existing pattern from v1.6 dedup).

3. **Anti-bot or no photos** (~20-30% of LA County cities): Cloudflare blocks scraping, or city website has no photos. Hardcoded roster fallback with manually verified photo URLs — extend existing fallback pattern in `scrape_la_officials.py`.

### Wikidata City Hall Photos

Query pattern (confirmed working via Wikidata docs):

```sparql
SELECT ?city ?cityLabel ?hallImage WHERE {
  ?city wdt:P31 wd:Q515 .          # instance of: city
  ?city wdt:P131 wd:Q816459 .      # located in: Los Angeles County
  ?city wdt:P6 ?hall .             # head of government links to city
  OPTIONAL { ?city wdt:P18 ?hallImage }  # city photo fallback
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en" }
}
```

Better pattern: query city hall entities directly, linked to their municipality:

```sparql
SELECT ?hall ?hallLabel ?image ?cityLabel WHERE {
  ?hall wdt:P31 wd:Q16560 .        # instance of: city hall
  ?hall wdt:P131/wdt:P131* wd:Q816459 .  # in LA County
  OPTIONAL { ?hall wdt:P18 ?image }
  ?city wdt:P6 ?hall .
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en" }
}
```

Results map city name → Wikimedia Commons image URL. Store in `city_hall_photos.json` config (same pattern as `building_images` in essentials frontend). Expected coverage: ~40-60% of 89 LA County cities.

### SOS PDF Contact Extraction

The 2026 California Roster cities-towns.pdf (URL available: `https://admin.cdn.sos.ca.gov/ca-roster/2026/complete-roster.pdf`) includes per-city sections with address and phone. Existing `scrape_city_councils.py` already uses pdfplumber for name extraction. Extend the same parsing pass to capture:
- City hall phone number → store as city-level `PoliticianContact` with `contact_type="city_hall"`
- City official website URL → store in `politicians.urls[]` for mayor/council members

---

## Coverage Target Justification

The milestone targets 80%+ coverage for headshots and contact info across ~389 officials.

**Headshot coverage breakdown:**
- 5 county supervisors: 5/5 expected (100%) — professional photos on dedicated pages
- 15 LA City council members: 15/15 expected (100%) — professional photos on lacity.gov
- 369 other city council members: estimate 250-295/369 (68-80%) — varies by city website quality

**Combined headshot coverage: ~270-315/389 = 69-81%**

For city council members, the 80% target requires ~295/369 city council members to have scrapable photos. This is achievable if ~72 of 89 cities have photos on their council pages (which is conservative based on CA government website norms).

**Contact info coverage breakdown:**
- Website URL: 89/89 cities (100%) — derive from existing `city_sources.json` url field
- City hall phone: ~60-70% expected from SOS PDF + lavote output for supervisors
- Individual member email: ~20-30% (most LA County cities do not publish council email; web forms are more common)

Contact "coverage" at the 80% target level is achievable with website URLs and city-level phones — individual member emails are a stretch goal.

---

## Competitor Reference

| Platform | Local official photos | Building photos | Contact info | Term dates |
|----------|----------------------|-----------------|--------------|------------|
| Google "Who represents me" | No local council | No | No | No |
| Ballotpedia | Inconsistent at city level | No | Links only | Yes (for covered offices) |
| OpenStates | State only | No | No | Yes |
| LA Forward "Who Represents Me" | No photos | No | Links only | No |
| Vote.gov | Redirect-only | No | No | No |
| EV Essentials v1.7 (target) | Yes — headshots for supervisors + city councils | Yes — city hall photos for major cities | Yes — city hall phone + website | Yes — term start/end for supervisors, derived for city council |

---

## Sources

- California SOS Roster 2025 (cities-towns.pdf): https://admin.cdn.sos.ca.gov/ca-roster/2025/cities-towns.pdf
- California SOS Roster 2026 (complete): https://admin.cdn.sos.ca.gov/ca-roster/2026/complete-roster.pdf
- LA County Board of Supervisors: https://bos.lacounty.gov/
- LA City Clerk current elected officials: https://clerk.lacity.gov/articles/current-elected-officials
- lavote.gov public officials pages: https://www.lavote.gov/home/voting-elections/candidate-measure-information/current-public-officials/
- Wikidata SPARQL query service: https://query.wikidata.org/
- Wikidata property P18 (image): https://www.wikidata.org/wiki/Property_talk:P18
- Wikidata property Q16560 (city hall): https://www.wikidata.org/wiki/Q16560
- Wikimedia Commons SPARQL docs: https://commons.wikimedia.org/wiki/Commons:SPARQL_query_service
- EV Codebase: `EV-Backend/internal/essentials/models.go` (PoliticianImage, PoliticianContact, photo_origin_url, valid_from/valid_to schema), `EV-Backend/scripts/scrape_la_officials.py` (existing scraper pattern), `EV-Backend/scripts/city_sources.json` (89 city configs with 382 roster entries), `scrapers/lavote_scraper.py` (year_elected, term_length output), `ev-ui/src/PoliticianProfile.jsx` (getTermLine, initials avatar, profileImageUrl logic)

---

*Feature research for: v1.7 LA County Data Enrichment — headshots, building photos, contact info, term data*
*Researched: 2026-02-24*
