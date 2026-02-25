# Project Research Summary

**Project:** v1.7 LA County Data Enrichment
**Domain:** Civic tech — offline Python scraping pipeline enriching ~389 LA County politician records with headshots, building photos, contact info, and term data
**Researched:** 2026-02-24
**Confidence:** HIGH

## Executive Summary

v1.7 is a data enrichment milestone, not a new feature build. The existing system already has 791 LA County politician records in the database, all the schema columns that v1.7 needs to populate (photo_origin_url, valid_from, valid_to, bio_text, politician_images, politician_contacts, degrees, experiences), and a working Go API + React frontend that renders those fields automatically. The entire v1.7 effort lives in the Python scraping pipeline — roughly 4-6 new Python scripts that write enrichment data into existing tables. The read path (Go API + essentials app) requires only minor additions: one new endpoint for building photos, contacts added to the profile response, and a ContactSection in the ev-ui component library.

The recommended approach is to build the enrichment pipeline in dependency order: schema preparation first (adds only one new table, `building_photos`, and two new columns for photo licensing and term date precision), then run headshot scraping, building photo collection, contact enrichment, and term data enrichment as independent parallel-capable scripts, then land the small Go API changes, then the frontend additions. The 80% headshot coverage target is achievable — supervisors and LA City council have professional photos at predictable URLs (100% expected); the 369 remaining city council members require per-city scraping with ~68-80% combined coverage from city websites plus hardcoded fallbacks. Wikimedia Commons is the correct source for building photos (free, CC-licensed, permanent URLs); Google Places API must not be used.

The highest-risk decisions all require design choices before any code is written: (1) photo hosting — hotlinking government URLs will break silently within 2-4 years when city websites redesign; downloading and uploading to Supabase Storage during the pipeline run is the correct fix and must not be deferred again as it was in v1.6; (2) image licensing — California government works are not automatically public domain, so Wikimedia Commons must be checked before scraping city websites; (3) term date precision — storing year-only data as "YYYY-01-01" will display as "Jan YYYY" in the frontend, requiring a term_date_precision column and a frontend ev-ui update before any term dates are stored.

## Key Findings

### Recommended Stack

The existing Python scraper stack requires only two changes: upgrade Playwright from 1.44.0 to 1.58.0 for better JS-rendered government site support, and add Pillow 12.1.1 for image validation before database insertion. Every other dependency (requests, BeautifulSoup, psycopg2-binary, rapidfuzz, pdfplumber) is already in requirements.txt and works as-is. The Go backend requires no new packages — a single GORM model addition handles the one new table. The React frontend requires no new npm packages — building photos go to `essentials/public/images/` as static assets via a code-only change to `buildingImages.js`.

**Core technologies:**
- Python 3.13 + requests + BeautifulSoup: scraping pipeline runtime — already proven across all v1.6 scripts
- psycopg2-binary 2.9.11: direct PostgreSQL writes — already in use; upsert pattern with ON CONFLICT established
- Playwright 1.58.0 (upgrade from 1.44.0): JS-rendered government site fallback — already integrated via fetch_html_with_fallback(); upgrade adds Chromium 133 support
- Pillow 12.1.1 (new): image validation before DB insert — replaces deprecated imghdr (removed in Python 3.13); validates minimum 80x80px, JPEG/PNG only
- Wikimedia Commons API via plain requests: building photo acquisition — free, CC-licensed, no auth required; raw requests is simpler than any Wikimedia SDK

**What NOT to add:** SPARQLWrapper (unmaintained since March 2022), pyWikiCommons (thin wrapper, no benefit), Google Places API (billing complexity, non-permanent URLs), asyncio/aiohttp (serial requests required for polite government site scraping), Scrapy (heavy framework overkill for 389 records), any new Go packages (existing GORM models and API patterns sufficient).

### Expected Features

The feature set is scoped and well-defined by the existing DB schema and data source inventory. Research confirms data availability is highest for high-profile officials (supervisors, LA City council) and degrades across 89 independent city websites, which sets realistic expectations for the 80% coverage target.

**Must have (table stakes):**
- Headshots for all 5 LA County supervisors — professional photos at predictable bos.lacounty.gov URLs; 100% expected coverage
- Headshots for all 15 LA City council members — lacity.gov council-district pages; 100% expected with hardcoded fallback
- City hall building photo for LA City section — extensive Wikimedia Commons coverage; mechanism already exists from v1.1
- Term dates for 5 county supervisors — lavote.gov scraper already captured year_elected and term_length; only a DB write script needed
- Contact website URL for all 89 cities — derivable from existing city_sources.json url field; 100% coverage with no scraping required
- Enrichment coverage report — SQL/Python confirming 80%+ headshot and contact targets met before milestone sign-off

**Should have (competitive differentiators):**
- Headshots for 369 remaining city council members — per-city scraping; 60-80% expected; no competitor covers this at city council level
- City hall building photos for top 20 LA County cities — Wikidata SPARQL batch query; 40-60% estimated Wikidata coverage
- Contact phone for 5 county supervisors — data already in lavote.gov output; DB write only
- Bio text for supervisors and LA City council — available on official pages; 20 high-profile officials, low-medium effort

**Defer to v1.7.x or later:**
- City hall photos for remaining 69 cities — SVG fallback already handles gaps
- Bio/education/experience for smaller city council members — ~30% availability, high per-city parsing effort
- Photo re-hosting to Supabase Storage — NOTE: PITFALLS.md argues this must NOT be deferred (see Critical Pitfalls); the PROJECT.md "out of scope" designation conflicts with the hotlinking risk identified in research
- Automated nightly enrichment re-run — manual re-runs sufficient for now; complex orchestration not justified

### Architecture Approach

The architecture is a clean three-layer separation: offline Python pipeline writes into the database; existing Go API serves the data with minor additions; existing React frontend renders it with minor additions. One new database table (`essentials.building_photos`, keyed by Census place_geoid) is the only structural addition. The entire enrichment pipeline writes into existing columns on existing tables.

**Major components:**
1. **Enrichment pipeline (new Python scripts)** — scrape_headshots.py, scrape_building_photos.py, enrich_contacts.py, enrich_term_data.py (and optional enrich_bio_edu_exp.py); all read from politician_sources.json and city_sources.json configs; all use seat-first dedup logic extracted to utils.py
2. **Config layer (modified)** — politician_sources.json gains photo_selector and contact_fields per source; city_sources.json gains building_photo_url and building_photo_attribution per city
3. **Database layer (existing tables + one new)** — enrichment data writes to photo_origin_url, valid_from, valid_to, bio_text on politicians; politician_images (DELETE+INSERT per scrape); politician_contacts (DELETE+INSERT where source='scraped'); building_photos is the only new table
4. **Go API (minor additions)** — contacts added to GetPoliticianByID response (~15 lines); GetBuildingPhoto handler (~20 lines); one new route line
5. **ev-ui component library (minor addition)** — ContactSection render block (~30 lines); requires version bump and publish to GitHub npm registry; essentials and CompassV2 must update their ev-ui version dependency

**Key patterns to follow:**
- Politician-ID-keyed upsert: always resolve politician_id via seat-first dedup before writing any enrichment data
- DELETE + INSERT (not ON CONFLICT UPDATE) for child tables — same pattern as BallotReady upsert in handlers.go
- Per-source commit (not global transaction) — one city failure does not roll back the other 88
- Conditional UPDATE: only fill gaps, never overwrite existing non-empty data (prevents degrading BallotReady photos with lower-quality scraped photos)
- time.sleep(random.uniform(1.5, 3.5)) between city requests — mandatory for rate limiting

### Critical Pitfalls

Eight pitfalls identified; three require schema design decisions before any pipeline code is written:

1. **Photo hotlinking breaks silently within 2-4 years** — Storing government website image URLs as the displayed photo source creates dependencies on 89 different city websites staying structurally stable. Government sites redesign frequently; hotlink blocking via Cloudflare policy can break all photos overnight with no monitoring alert. Prevention: download every scraped headshot at scrape time and upload to Supabase Storage "politician-photos" bucket; store the Supabase CDN URL in politician_images.photo_url; keep photo_origin_url as audit metadata only, never render it directly. This must be implemented in the first scraper — the v1.6 deferral in scrape_la_officials.py (lines 29-33) must be resolved before any v1.7 headshot scraping merges.

2. **California government photos are not automatically public domain** — Unlike federal works (17 U.S.C. § 105), CA state and local governments can assert copyright (Government Code § 6254.9). Professional headshots on city websites may be taken by contracted photographers with the copyright held by the city. Scraping and re-hosting at scale without license assessment creates legal exposure. Prevention: check Wikimedia Commons first for each official batch (60-70% coverage for prominent officials); check city media kits and press rooms second; only scrape city websites as last resort; add photo_license field to politician_images ("cc_by_sa", "press_use", "scraped_no_license"); never serve "scraped_no_license" in production until reviewed.

3. **Term date precision must be tracked before any dates are stored** — lavote.gov provides year_elected as a bare year string ("2024"). Storing this as "2024-01-01" causes the frontend's formatTermDate() to display "Jan 2024" when the official was elected in November — factually wrong. Prevention: add term_date_precision column ("year"/"month"/"day") before any term dates are inserted; update formatTermDate() in ev-ui to suppress month/day when precision is "year"; requires ev-ui version bump and publish before term data pipeline runs.

4. **JS-rendered city pages fail silently with wrong Playwright threshold** — ~20-30% of CA city websites use React/Vue/CMS platforms (Granicus, CivicPlus, Municode) that render content client-side. The existing fetch_html_with_fallback() Playwright trigger uses a byte-count threshold (500 chars) that misses pages with full HTML shells but no rendered content. Prevention: replace byte-count threshold with name-pattern detection — require at least 2 matches of `r'\b[A-Z][a-z]+\s+[A-Z][a-z]+\b'` before accepting the requests result as valid.

5. **Cloudflare blocks cause transient failures to be marked permanent** — Sequential requests to 89 city websites without rate limiting trigger bot detection; cities marked status:"failed" are skipped on reruns. Prevention: add random delay between city requests; distinguish "blocked" (429/403) from "failed" (scraper logic error) with separate status values and retry_after timestamps; accept SOS PDF names-only coverage for persistently blocked sites rather than attempting bypasses.

## Implications for Roadmap

The dependency chain is clear: schema and infrastructure decisions must be locked before any scraping begins. High-value targets (supervisors, LA City) validate the pipeline before mass city scraping. API and frontend changes are genuinely last because they depend on data existing in the database to be useful.

### Phase 1: Schema and Infrastructure Preparation
**Rationale:** Three blocking dependencies must be resolved before any enrichment data is written: the Supabase Storage bucket must exist, the photo_license column must be in the schema, and term_date_precision must be in the schema. If these are missing when the first script runs, the entire pipeline produces data that requires a retroactive migration. These are small changes (one new table, two new columns, one Storage bucket) but they are hard blockers.
**Delivers:** building_photos table created via Go AutoMigrate; photo_license column added to politician_images; term_date_precision column added to politicians; Supabase Storage "politician-photos" bucket created with public CDN access and service-role-only upload policy; seat-first dedup logic extracted from scrape_la_officials.py to utils.py; composite unique constraint on politician_contacts verified or added
**Addresses:** Pitfalls 1, 2, 3, 6 — all require schema decisions before first inserts
**Avoids:** The v1.6 deferral pattern for Supabase Storage; building pipeline code before the destination schema is finalized

### Phase 2: High-Value Headshots (Supervisors + LA City Council)
**Rationale:** 20 officials (5 supervisors + 15 LA City) yield near-100% coverage with well-structured, non-Cloudflare source pages. These are the most-viewed profiles. Completing these first proves the full Supabase Storage upload flow and photo_license population before scaling to 89 cities. The fetch_html_with_fallback() name-pattern fix (Pitfall 4) must be in place before this phase — even though these pages are mostly static, the fix should be validated here on a small batch.
**Delivers:** Headshots for 5 county supervisors (bos.lacounty.gov); headshots for 15 LA City council members (lacity.gov); Supabase Storage upload pipeline proven end-to-end; photo_license populated for each image; Wikimedia Commons checked first for each official before city website fallback; scrape_headshots.py script with rate limiting and per-source commit pattern
**Addresses:** P1 features: headshots for high-profile officials; Pitfall 1 (Supabase Storage upload proven), Pitfall 2 (Wikimedia Commons first)
**Avoids:** Pitfall 3 (rate limiting — small set, easy to validate behavior), Pitfall 5 (overwriting existing photos — conditional UPDATE in place)

### Phase 3: Building Photos, Term Data, and Contact Enrichment
**Rationale:** These three data types are independent of headshot scraping and can be developed in parallel with Phase 4. Term dates for supervisors and contact websites for 89 cities are near-zero-effort — lavote.gov data is already captured, city_sources.json URLs already exist. Building photos require Wikidata SPARQL research but no per-politician parsing complexity. Grouping them here keeps the scope focused: these all write into existing tables or the new building_photos table, and none require the complex per-city HTML parsing that Phase 4 requires.
**Delivers:** building_photos table populated for LA City + top 20 LA County cities (Wikidata SPARQL query results); term dates for 5 supervisors written to valid_from/valid_to with term_date_precision="year"; contact website for 89 cities written from city_sources.json; contact phone for 5 supervisors written from lavote.gov output; enrich_contacts.py and enrich_term_data.py scripts with contact_synced_at timestamps; scrape_building_photos.py populating building_photos table
**Addresses:** P1 features: term dates for supervisors, contact website for all cities; P2 features: building photos for top 20 cities; Pitfall 4 (contact info staleness — contact_synced_at implemented)
**Avoids:** Pitfall 6 (term_date_precision — must be in Phase 1 schema before any date is stored here)

### Phase 4: City Council Headshot Pipeline (89 Cities)
**Rationale:** This is the highest-complexity, highest-risk phase — 369 officials across 89 different city websites with variable HTML structure, anti-bot protection, and JS rendering variability. Phase 2 must complete first to prove the Supabase Storage upload pipeline. The fetch_html_with_fallback() name-pattern fix must be live. A sampling audit of 10 cities (2 known-JS, 8 static) should be performed before writing the full pipeline to identify which cities need playwright fetch_method override in city_sources.json.
**Delivers:** Headshots for 369 city council members; 60-80% combined coverage target; city_sources.json enriched with per-city photo_selector and fetch_method overrides; hardcoded photo_url fallbacks in city_sources.json for Cloudflare-protected cities; coverage validation script reporting verified HEAD request success rate (not just non-null DB rows); all images in Supabase Storage with photo_license populated
**Addresses:** P1 feature: headshots for 89 cities; Pitfall 2 (JS-rendered pages — name-pattern fallback), Pitfall 3 (Cloudflare — rate limiting, blocked/failed status distinction)
**Avoids:** Pitfall 5 (overwriting BallotReady photos — conditional UPDATE); Anti-pattern: duplicating dedup logic (imports from utils.py); Anti-pattern: global transaction (per-source commit)

### Phase 5: Go API Additions and Frontend Updates
**Rationale:** The API and frontend changes are minor in scope but depend on enrichment data existing in the database to be meaningful on deploy. ContactSection should show actual contacts when it ships, not render an empty section. Building photo endpoint is only useful once building_photos table has rows. These changes can be drafted in parallel with Phases 2-4 but should be deployed after data is confirmed in the database.
**Delivers:** contacts[] added to GetPoliticianByID response with Contacts []ContactOut field (omitempty); GetBuildingPhoto handler at GET /essentials/cities/{geo_id}/building-photo; ContactSection in ev-ui PoliticianProfile.jsx showing phone, email, office address with contact_synced_at "as of" display; Dashboard.jsx fetching and displaying building photo for resolved city geo_id; new ev-ui version published to GitHub npm registry; essentials and CompassV2 updated to new ev-ui version
**Addresses:** Architecture additions: Go API contacts fetch, building photo endpoint, ev-ui ContactSection, Dashboard building photo fetch; UX pitfall: contact info freshness indicator visible to users
**Avoids:** Pitfall 4 (contact staleness — "as of [date]" shown in ContactSection); Anti-pattern: fetching external images at request time (store URLs, let browser fetch)

### Phase 6: Bio Enrichment and Coverage Validation
**Rationale:** Bio text is the lowest-priority enrichment (lower availability, highest per-city parsing complexity) and should only run after all higher-priority enrichment is confirmed in production. Coverage validation is the official milestone gate — it must use HEAD request audits, not null-count SQL, to confirm actual display success.
**Delivers:** Bio text for 5 supervisors (bos.lacounty.gov) and 15 LA City council members (lacity.gov); bio quality filter (100-2000 chars, no boilerplate strings, at least one sentence-ending punctuation); bio_source_url stored alongside bio_text; enrichment coverage report showing verified photo HEAD request success rate >= 80%; deduplication integrity check passes (zero duplicate officials in post-enrichment query)
**Addresses:** P2 features: bio text for high-profile officials; Pitfall 7 (bio boilerplate — quality filter in place), Pitfall 8 (coverage metric inflation — HEAD request audit as canonical measure)
**Avoids:** "Looks Done But Isn't" checklist: photo_url must point to Supabase CDN domain (not government domains), photo_license non-null for all scraped images, term_date_precision non-null for all term dates, contact_synced_at non-null for all contact records

### Phase Ordering Rationale

- Schema and infrastructure must precede all pipeline phases because photo_license, term_date_precision, and the Supabase Storage bucket are needed from the first scraper run — adding them retroactively requires a migration and data backfill
- High-value headshots before mass city scraping validates the full pipeline (Storage upload, photo_license, dedup) on a manageable 20-record batch before scaling to 369 records across 89 sites
- Building photos, term data, and contacts are independent of headshot complexity and can be developed in parallel with Phase 4, but are grouped as Phase 3 because they share simpler, well-understood source patterns
- Go API and frontend are genuinely last — they serve data that must already exist in the database to be useful on deploy; ContactSection with no contacts is noise
- Bio enrichment is last because it is optional, has lowest source availability, and its quality filter must be right before production data is affected

### Research Flags

Phases that may need targeted research before implementation:
- **Phase 4 (City Council Headshots — per-city audit):** A 10-city sampling pass is required before building the full pipeline. Identify which cities use Granicus/CivicPlus/Municode (mark fetch_method:"playwright" in city_sources.json), which have Cloudflare protection, and which HTML structure is used for headshot placement. This is a pre-planning audit step, not a full research phase.
- **Phase 1 (Supabase Storage Python upload):** The supabase-py Python client upload API has documented pitfalls: base64 encoding corrupts image files; content-type must be explicitly passed in file_options; bucket must be pre-created manually. Verify the exact upload pattern against current Supabase Python docs before writing the first upload function.

Phases with standard, well-documented patterns (skip research phase):
- **Phase 2 (Supervisor/LA City headshots):** bos.lacounty.gov and lacity.gov are public, well-structured; hardcoded fallback pattern already established; Wikimedia Commons search pattern documented in STACK.md
- **Phase 3 (Building photos, term/contact data):** Wikimedia Commons API query pattern documented in STACK.md; lavote.gov data already captured in known format; city_sources.json URL field already populated
- **Phase 5 (Go API + frontend):** All changes are additive with clear scope (15-30 lines each); ContactSection follows existing ev-ui component patterns; building photo endpoint follows existing handler structure
- **Phase 6 (Bio + coverage validation):** Bio quality filter pattern and HEAD request audit code both fully documented in PITFALLS.md

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Direct codebase inspection of all existing scripts and requirements.txt; Playwright 1.58.0 and Pillow 12.1.1 versions verified against PyPI; Wikimedia Commons API pattern confirmed via MediaWiki docs |
| Features | HIGH | Existing DB schema directly inspected (models.go confirms all target columns exist); data sources verified (bos.lacounty.gov, lacity.gov, lavote.gov, SOS PDF URLs confirmed live); coverage estimates based on CA government website norms and lavote.gov scraper output structure |
| Architecture | HIGH | All source files directly inspected; schema columns, handler structure (GetPoliticianByID steps 1-7), ev-ui component logic (getImageURL, getTermLine), and config file formats all verified against actual code in repository |
| Pitfalls | HIGH (hotlinking, Cloudflare, JS pages) / MEDIUM (contact staleness, coverage metric, bio boilerplate) | Hotlinking behavior: verified against mySociety PopIt tracker + Pixsy. CA copyright: verified against EFF records + Wikipedia copyright status article. Cloudflare patterns: verified against City-Bureau/city-scrapers patterns + Scrapfly docs. Supabase Storage: verified against Supabase Python docs + community issue tracker. Contact staleness and coverage inflation: pattern reasoning from v1.6 codebase history |

**Overall confidence:** HIGH

### Gaps to Address

- **Photo re-hosting scope decision:** PROJECT.md marks Supabase Storage re-hosting as "out of scope for v1.7." PITFALLS.md argues this must not be deferred because hotlinking at scale is a production reliability problem. This conflict requires an explicit decision before Phase 1 begins. Recommendation from research: implement Supabase Storage upload in v1.7 because deferring it again means scraping 389 government URLs that will require re-scraping when sites redesign.

- **Composite unique constraint on politician_contacts:** STACK.md notes "The politician_contacts table currently lacks a composite unique constraint in the Go model definition — verify one exists or add it before running enrichment scripts." This must be checked in models.go and the database schema before Phase 3 contact upserts run.

- **Wikimedia Commons actual coverage for 89 LA County cities:** Research estimates 40-60% coverage from Wikidata SPARQL. The actual query output (which cities have P18 images) is not known until the query runs. SVG fallback handles gaps, but Phase 3 building photo scope depends on actual results. Run the SPARQL query during Phase 1 planning to size Phase 3 correctly.

- **External ID range for v1.7:** ARCHITECTURE.md notes "v1.6 = -200001 range, v1.7 should use -300001 range" for synthetic external IDs on scraped records. The exact range initialization must be set in utils.py before any v1.7 script assigns new external IDs.

- **photo_license legal review workflow:** Research identifies the licensing risk but does not define the review process for "scraped_no_license" images. A decision is needed: either accept "scraped_no_license" images with a tag (serving them with a disclaimer) or gate production serving on a manual review pass per city batch. This determines whether Phase 4 headshots are immediately live in production or staged behind a review gate.

## Sources

### Primary (HIGH confidence)
- `EV-Backend/scripts/requirements.txt` — current pinned dependencies; scraper infrastructure baseline
- `EV-Backend/scripts/scrape_la_officials.py` — seat-first dedup, upsert logic, photo_origin_url precedent, v1.6 Supabase Storage deferral TODO (lines 29-33)
- `EV-Backend/scripts/scrape_city_councils.py` — fetch_html_with_fallback(), byte-count threshold limitation, per-city commit pattern, city_sources.json structure
- `EV-Backend/scripts/city_sources.json` — 89 city configs, place_geoid values, council page URLs, 382 roster entries
- `EV-Backend/scripts/politician_sources.json` — 3 existing source configs
- `EV-Backend/internal/essentials/models.go` — PoliticianImage, PoliticianContact, Degree, Experience, Politician structs; all target columns confirmed present
- `EV-Backend/internal/essentials/handlers.go` — GetPoliticianByID steps 1-7; OfficialOut struct; PoliticianProfileOut structure; contacts not yet in response
- `ev-ui/src/PoliticianProfile.jsx` — getImageURL() (images[]/photo_origin_url fallback chain), getTermLine() (valid_from/valid_to), initials avatar fallback
- `essentials/src/lib/buildingImages.js` — CURATED_LOCAL static asset pattern, getBuildingImages() function, SVG fallback
- [Playwright Python PyPI](https://pypi.org/project/playwright/) — v1.58.0 current stable January 2026
- [Pillow PyPI](https://pypi.org/project/pillow/) — v12.1.1 current stable February 2026
- [Supabase Python Storage docs](https://supabase.com/docs/reference/python/storage-from-upload) — MIME type requirement, file_options format, upload pattern
- [Wikimedia Commons API:Etiquette](https://www.mediawiki.org/wiki/API:Etiquette) — no auth needed for reads, User-Agent required

### Secondary (MEDIUM confidence)
- [Wikimedia Rate Limits](https://api.wikimedia.org/wiki/Rate_limits) — no hard limit on read requests; serial requests recommended
- [Wikidata SPARQL service](https://query.wikidata.org/) — P18 (image), P31 (instance of city hall, Q16560), P131 (located in LA County, Q816459) query patterns
- [California SOS Roster 2026](https://admin.cdn.sos.ca.gov/ca-roster/2026/complete-roster.pdf) — city-level contact data availability
- mySociety PopIt issue #461 — hotlink blocking behavior from government websites returning 403
- [City-Bureau/city-scrapers](https://github.com/City-Bureau/city-scrapers) — community patterns for JS-rendered government page handling
- [Supabase community: PNG corruption on upload](https://github.com/orgs/supabase/discussions/26257) — base64 encoding pitfall with Python upload
- `scrapers/lavote_scraper.py` — year_elected as bare year string; term_length output format; ~75 officials captured

### Tertiary (informational)
- EFF: [California Legislature Drops Proposal to Copyright All Government Works](https://www.eff.org/deeplinks/2016/06/california-legislature-drops-proposal-copyright-all-government-works) — AB 2880 history; CA governments can assert copyright unlike federal
- Wikipedia: [Copyright status of works by subnational governments of the United States](https://en.wikipedia.org/wiki/Copyright_status_of_works_by_subnational_governments_of_the_United_States) — state/local government copyright rules differ from 17 U.S.C. § 105
- Scrapfly: [How to Bypass Cloudflare When Web Scraping](https://scrapfly.io/blog/posts/how-to-bypass-cloudflare-anti-scraping) — Cloudflare bot detection mechanisms; headless browser fingerprinting
- [SPARQLWrapper PyPI](https://pypi.org/project/SPARQLWrapper/) — last release March 2022; confirming it must NOT be added as a dependency

---
*Research completed: 2026-02-24*
*Ready for roadmap: yes*
