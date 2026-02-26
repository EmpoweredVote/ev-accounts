# Empowered Vote Platform

## What This Is

A civic engagement platform helping voters make informed decisions through an interactive political compass quiz (CompassV2), politician discovery by address (Essentials), and feature prototypes (Read & Rank, Treasury Tracker, Data Entry, Empowered Badges). The platform is run by a nonprofit with a 2-3 person dev team, currently deployed across Netlify, Supabase, and Render. The compass works without login (guest-first) with guided onboarding and write-in stances in calibration, renders cleanly across devices, and Essentials uses Google Maps address autocomplete with PostGIS geofence matching to surface the full representative hierarchy — federal, state, county, city, and school board — for LA County addresses, with headshot photos (Supabase CDN), city hall building photographs, contact info sections, chamber/district subtitles, initials avatars, and contextual term dates on profile pages. A repeatable TIGER + ArcGIS import pipeline and config-driven enrichment scripts support expansion to additional regions.

## Core Value

Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.

## Requirements

### Validated

- ✓ Session-based authentication with login/register/logout — existing
- ✓ Political compass quiz with topic selection and radar chart visualization — existing
- ✓ Politician comparison on radar chart (user vs. politician stances) — existing
- ✓ Spoke inversion toggle on compass — existing
- ✓ Library page showing issue cards with stance selection — existing
- ✓ Politician discovery by ZIP code with progressive loading — existing
- ✓ Address search with BallotReady geocoding for precise district results — existing
- ✓ 3-tier caching: federal, state, local with 90-day TTL — existing
- ✓ Politician profiles with images, bio, education, experience, endorsements, stances, elections — existing
- ✓ Federal/State/Local tier classification with sorting options — existing
- ✓ Shared RadarChartCore component library (ev-ui) — existing
- ✓ Data entry tool with review workflow (staging module) — existing
- ✓ Treasury tracker with budget visualization — existing
- ✓ Read & Rank candidate quote evaluation — existing
- ✓ Go backend with modular architecture (auth, compass, essentials, treasury, staging) — existing
- ✓ Guest-first compass — full quiz without login, localStorage persistence, server-wins merge on register — v1.0
- ✓ Admin-only clear compass in profile dropdown — v1.0
- ✓ Question prompts on issue cards and compare page — v1.0
- ✓ Interactive Library drawer — click issue card, see stances, edit in-place with write-in support — v1.0
- ✓ Compass viewport sizing — fits on page without scrolling — v1.0
- ✓ Label overflow fix — long titles no longer clip or push chart — v1.0
- ✓ Spoke visual uniformity — dashed/solid distinction removed — v1.0
- ✓ Help box updated — no dashed/solid references — v1.0
- ✓ Federal/state/local level badges on issue cards — v1.0
- ✓ Seeded stance randomization — per user, permanent per issue, spectrum preserved — v1.0
- ✓ Candidate support in Essentials — opt-in toggle, visual differentiation, election dates — v1.0
- ✓ Building images for federal/state/local sections — v1.0
- ✓ Federal reorder — Senate and House before executive branch — v1.0
- ✓ Position start/end dates on politician cards — v1.0
- ✓ Auth safety audit — middleware tests, integration tests, 62-route manifest — v1.0

- ✓ Sticky sidebar with independently scrolling representatives panel — v1.1
- ✓ Real building photographs for federal/state/local tiers (Wikimedia Commons, CC-licensed) — v1.1
- ✓ Scroll-spy building image swap in "All" mode — v1.1
- ✓ Term dates relocated from dashboard cards to profile pages with en-dash formatting — v1.1
- ✓ ev-ui 0.1.19 with formatTermDate/getTermLine helpers — v1.1

- ✓ Guided onboarding — CalibrationOverlay on empty compass with card-by-card topic selection and live radar rendering — v1.2
- ✓ 8-topic cap enforced across all paths (Library, onboarding, quiz) — v1.2
- ✓ 3-topic minimum before compass renders meaningfully — v1.2
- ✓ Library cards show on-compass indicator with add/remove toggle — v1.2
- ✓ Library defaults to showing all topics — v1.2
- ✓ "Start Quiz" button replaced by CalibrationOverlay entry point — v1.2
- ✓ Question framing: "Where do you stand on [topic]?" with content pass on vague titles — v1.2
- ✓ Tech debt cleanup — dead code removed, ev-ui version aligned, getQuestionText consolidated — v1.2
- ✓ Help page updated with 5 walkthrough slides, responsive screenshots, HelpGuard auto-routing — v1.2
- ✓ Compass reset works for all logged-in users (not admin-only) — v1.2
- ✓ help_seen synced from DB completed_onboarding flag for cross-device consistency — v1.2

- ✓ Library → Compass transition auto-enters calibration for unanswered topics (starting at first unanswered, not from scratch) — v1.3
- ✓ Double comparison overlay bug on compare page fixed — v1.3
- ✓ Topic titles standardized server-side: consistent naming across compass labels, Library cards, calibration — v1.3
- ✓ "Where do you stand on..." prefix removed from card display for scannability — v1.3
- ✓ Compass renders correctly with mixed answered/unanswered topics (no empty spokes or dead-end states) — v1.3

- ✓ BuildCompass guest support — "View Full Compass" and quiz completion work without login — v1.4
- ✓ Radar chart label clipping fixed — labels on far left/right edges no longer cut off — v1.4
- ✓ Radar chart label minimum size — short labels (Misinformation, Immigration, Medicare/Medicaid) remain readable — v1.4
- ✓ "Edit Topics" button removed from compass page — Library page handles topic editing — v1.4
- ✓ "Clear" button removed from Library page — v1.4
- ✓ Library stat cards fill full width on mobile — v1.4
- ✓ QuestionText more prominent on LibraryDrawer and stance selection — v1.4
- ✓ Tech debt: compassimport/seed CLI StartPhrase references cleaned up — v1.4
- ✓ Tech debt: Admin TopicEditor vestigial short_name field removed — v1.4
- ✓ Onboarding-to-calibration redirect — fresh users enter calibration, not dead-end — v1.4
- ✓ Compare page question-text-first display — matches LibraryDrawer/Quiz hierarchy — v1.4

- ✓ Address search uses PostGIS geofence-only matching — no BallotReady API fallback — v1.5
- ✓ Federal/state officials from cache when local geofence data unavailable — v1.5
- ✓ All BallotReady cache warmers and provider infrastructure removed — v1.5
- ✓ Google Maps Places autocomplete as sole search input (ZIP code path removed) — v1.5
- ✓ Validated/confirmed address displayed in search results — v1.5
- ✓ Clear no-geofence-data coverage message for unsupported areas — v1.5
- ✓ BALLOTREADY_API_KEY decommissioned from all environments — v1.5
- ✓ Google Maps API billing alert configured — v1.5
- ✓ Cached-only candidate/race data from election_records — v1.5
- ✓ CalibrationOverlay 50/50 layout with write-in drag-and-drop — v1.5
- ✓ Chamber/district subtitles on politician cards (3-line layout) — v1.5
- ✓ Initials avatar for missing profile images — v1.5
- ✓ Labeled term dates and years in office on profiles — v1.5
- ✓ Office description shown, bio_text and Issues section removed from profiles — v1.5
- ✓ Bloomington city council district boundaries imported (Districts 1-6) — v1.5
- ✓ X0001 MTFCC mapped to LOCAL district type — v1.5
- ✓ ev-ui 0.1.27 with updated PoliticianProfile and PoliticianCard — v1.5

- ✓ Geofence schema: composite unique constraint on (geo_id, mtfcc) for idempotent multi-layer imports — v1.6
- ✓ ST_Covers spatial predicate for boundary-inclusive address matching — v1.6
- ✓ MTFCC map expanded: G4110, G4120, G5400, G5410 for city/school district boundaries — v1.6
- ✓ Shared Python import utilities (utils.py + requirements.txt) for consistent pipeline scripts — v1.6
- ✓ TIGER 2024 geofences: congressional (G5200), state senate (G5210), state assembly (G5220), school districts (G5420), 482 CA city boundaries (G4110) — v1.6
- ✓ LA County ArcGIS geofences: 5 supervisor districts, 15 LA City council wards, 31 other city council ward boundaries — v1.6
- ✓ Politician gap-fill: 21 LA County officials (supervisors + city council + mayor) with config-driven scraper — v1.6
- ✓ City council gap-fill: 368 politicians across 89 LA County cities via SOS PDF extraction — v1.6
- ✓ School board gap-fill: 402 board members across 79 LA County unified school districts — v1.6
- ✓ Deduplication: seat-first dedup with rapidfuzz matching, zero duplicate violations — v1.6
- ✓ Point-in-polygon validation: 16/16 test addresses pass full tier verification — v1.6
- ✓ PostGIS performance: VACUUM ANALYZE + GiST index confirmed active after bulk imports — v1.6
- ✓ Import pipeline runbook: 545-line step-by-step documentation for future regional expansion — v1.6

- ✓ Headshot photos for LA County supervisors and LA City council (20 officials) in Supabase CDN — v1.7
- ✓ City hall building photos from Wikimedia Commons for 11 LA County cities in Supabase CDN — v1.7
- ✓ Contact website URLs for all 89 LA County cities + supervisor phone numbers — v1.7
- ✓ Term date precision (year/month/day) with UTC-safe frontend formatting — v1.7
- ✓ All scraped photos re-hosted to Supabase Storage CDN (zero government hotlinks) — v1.7
- ✓ Photo licensing tracked per image (photo_license column) — v1.7
- ✓ Batch headshot scraper (1,247 lines, 5-strategy extraction) for city councils — v1.7
- ✓ Coverage validation script (CDN HEAD audit, contact presence, hotlink scan) — v1.7
- ✓ Contacts API endpoint and frontend contact section in ev-ui PoliticianProfile — v1.7
- ✓ Building photo API endpoint (GET /essentials/cities/{geo_id}/building-photo) — v1.7
- ✓ Config-driven pipeline_config.json for enrichment scripts — v1.7

### Active

(No active milestone — run `/gsd:new-milestone` to plan next)

### Out of Scope

- Infrastructure migration — research only, migrate in future milestone
- Mobile app — web-first
- Real-time chat — high complexity, not core
- Data import automation — manual processes acceptable for now
- Full state/local issue coverage for compass — indicators shipped, content later
- Monorepo migration — deferred to v2, current multi-repo structure works
- OAuth login (Google, GitHub) — email/password sufficient for current user base
- Building images for all US locations — only Bloomington IN and Los Angeles CA covered, SVG fallback for others
- Full quiz mode redesign — onboarding flow sufficient, full quiz stays as-is
- ZIP code fallback for privacy — address-only; geographic filters in future
- TIGER shapefile expansion beyond Monroe County IN + LA County CA — pipeline reusable, next county is future milestone
- Real-time candidate data — cached-only; live data requires new provider
- PlaceAutocompleteElement migration — legacy Autocomplete class works for existing key
- Per-ward council assignment for 5 district-election cities — at-large treatment acceptable for now
- City council headshot coverage beyond 21.5% — requires ~4-6 hours manual browser research per Plan 42-06; pipeline infrastructure ready
- School board data enrichment — 402 members, low data availability, high anti-bot protections
- Bio/education/experience for city council members — ~30% availability, high per-city effort

## Context

Shipped v1.7 with ~38K LOC across 4 repos + Python enrichment/import scripts:
- **CompassV2** (React 19): ~12K LOC — compass quiz, Library, guided onboarding, calibration with write-in support, guest auth, help walkthrough
- **EV-Backend** (Go 1.24): ~16K LOC — auth, compass, essentials (geofence-only + PostGIS, contacts API, building photo endpoint), treasury, staging modules
- **EV-Backend/scripts** (Python): ~5K LOC — TIGER/ArcGIS importers, headshot scrapers (scrape_headshots.py, scrape_city_headshots.py), building photo fetcher, contact/term importers, coverage_report.py, shared utils with Supabase Storage upload
- **ev-ui** (React/tsup): ~3K LOC — RadarChartCore, PoliticianProfile (contact section, subtitles, initials avatars), PoliticianCard (3-line layout)
- **essentials** (React 19): ~3K LOC — address autocomplete, geofence results, building photos, local filter sidebar

Tech stack: Go/Chi/GORM/PostgreSQL backend + React 19/Vite/Tailwind frontends + Supabase DB + PostGIS + Supabase Storage CDN.
Politician data: cached database records + 791 gap-filled LA County politicians. 84 headshots + 11 building photos in Supabase Storage. 381 contact records. Google Maps Places API for address autocomplete.
Geofence coverage: Bloomington IN (6 council districts) + full LA County (federal, state, county, city, school board boundaries).
ev-ui published to GitHub npm registry, consumed by CompassV2 and essentials.

Known tech debt: dead `ballotready/` package preserved as historical reference; orphaned `checkCacheStatus` in essentials; deprecated `cmd/bulk-import` CLI; IMPORT-PIPELINE.md references `--source` flag not implemented; 5 district-election cities treated as at-large; city council headshot coverage at 21.5% (pipeline ready, needs manual curation).

## Constraints

- **Tech stack**: Existing Go backend + React frontends — no framework migrations
- **Data source**: Cached politician data from database (no live API provider); Google Maps for geocoding
- **Hosting**: Netlify (frontends), Supabase (DB), Render (backend)
- **Budget**: Nonprofit — prefer solutions that use existing AWS credits or free tiers; Google Maps free tier (28K requests/month)
- **Team**: 2-3 devs — changes should be parallelizable and not create merge conflicts

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Guest-first compass with optional login | Remove friction for new users exploring the tool | ✓ Good — localStorage persistence + server-wins merge works cleanly |
| Convert issue titles to questions/prompts | Users need context for what each issue is asking | ✓ Good — question_text column added, rendered on cards and compare page |
| Per-user permanent stance randomization | Prevent positional bias without confusing returning users | ✓ Good — hash-based seed from guestId+topicId, direction-flip only |
| Project structure: keep multi-repo | Team needs clear boundaries for parallel work | ✓ Good — monorepo deferred to v2, current structure supports independent deploys |
| Infrastructure: defer migration | Nonprofit needs cost-effective hosting | — Pending — research only, no action taken |
| Integration tests use real Supabase DB | Postgres schema namespacing requires real DB for accuracy | ✓ Good — caught real issues mock DB would miss |
| Circular import fix via GORM Table() | auth->compass->auth cycle in Go packages | ✓ Good — anonymous structs, no behavioral change |
| CompassContext owns auth state | Single source of truth for isLoggedIn/username | ✓ Good — eliminated duplicate auth fetches |
| Inline modal registration (custom form) | AuthForm is full-page, unsuitable for modal | ✓ Good — clean save prompt UX |
| Level stored as pq.StringArray (text[]) | Topics can have multiple governance levels | ✓ Good — flexible, backward compatible |
| LibraryDrawer write-in support | Users need to add custom stances from Library | ✓ Good — full drag-to-position UX with persistence |
| Candidate endpoint is live-fetch (no caching) | Election data changes frequently near elections | ⚠️ Revisit — replaced by DB-only in v1.5 |
| Sticky two-panel layout with overflow:hidden | Sidebar must stay visible while scrolling long representative lists | ✓ Good — position:sticky + overflow-y:auto pattern works cleanly |
| IntersectionObserver root scoped to scroll container | Scroll-spy must detect tier boundaries within the panel, not viewport | ✓ Good — tier-swap works correctly in two-panel layout |
| Wikimedia Commons photos (public domain/CC) | Civic app needs license-safe building images | ✓ Good — 5 buildings covered, SVG fallback for unsupported locations |
| Chamber_name regex for city extraction | BallotReady transform doesn't populate representing_city | ✓ Good — buildSubtitle() in v1.5 provides proper chamber/district display |
| En-dash for date ranges | Typographically correct for date spans | ✓ Good — consistent formatting on profile pages |
| Hide term dates when both null | Avoid empty space or confusing placeholder text | ✓ Good — clean profile display |
| CalibrationOverlay with localStorage persistence | Mid-flow resume for interrupted onboarding | ✓ Good — calibration_progress, calibration_completed, calibration_skipped flags |
| Rebrand "quiz" to "calibrate" in user-facing text only | Keep route paths and variable names stable | ✓ Good — avoids churn while improving UX language |
| 8-topic cap enforced at 4 points | Library add, drawer add, onboarding, AddTopicModal | ✓ Good — comprehensive, no bypass path |
| Library defaults to showAll=true | Users should see all topics, not just unanswered | ✓ Good — inverted from previous hideAnswered=true default |
| short_name field for radar labels | Compass needs shorter labels than full topic titles | ✓ Good — no uniqueIndex constraint, acceptable for radar display |
| HelpGuard wraps each route individually | Simpler than layout wrapper pattern | ✓ Good — clear, explicit routing |
| help_seen seeded one-way from DB | DB wins for cross-device; localStorage-only for guests | ✓ Good — preserves guest flow while fixing logged-in cross-device gap |
| DELETE /compass/answers/me for all users | Any logged-in user should reset their own compass | ✓ Good — moved from admin group to session group |
| Tension title format with em dash (Topic: Pole A — Pole B) | Clear separation of topic name and policy poles, anti-partisan | ✓ Good — parseTensionTitle splits at colon, consistent across all surfaces |
| Backend-first title standardization | Server data must be canonical before frontend display | ✓ Good — Phase 17 before 18, eliminated hardcoded fallbacks |
| ShortName/StartPhrase columns dropped from DB | Clean break from deprecated naming fields | ✓ Good — standalone CLI tools still reference (tech debt) |
| Anti-partisan pole order randomization | Prevent visual bias (10 right-first, 11 left-first) | ✓ Good — verified across all 21 topics |
| Calibration resumeMode via useRef lazy-init | Wait for async context data before initializing state | ✓ Good — prevents race condition with topic loading |
| Exit gating replaces X button in calibration | Force users to reach 3+ topics before viewing compass | ✓ Good — hidden spacer below-3, View Compass text button at 3+ |
| Gray dashed spokes for unanswered topics | Visual differentiation without removing spoke positions | ✓ Good — opacity-25 + dashed stroke, clickable to route to calibration |
| Compare polygon iterates spokes not compareData keys | Guarantees correct angle alignment regardless of topic coverage | ✓ Good — fixed double-overlay bug in ev-ui@0.1.21 |
| answersRef pattern in BuildCompass | Read context inside effect without dep array churn | ✓ Good — matches Library.jsx convention |
| Dynamic label padding via char-width estimation | No DOM measurement needed for SVG label sizing | ✓ Good — charCount * fontSize * 0.6 ratio |
| Question-text-first across all views | Users scan by question, not tension title | ✓ Good — consistent across Library, Quiz, Calibration, Compare |
| ?calibrate=1 URL param for onboarding redirect | Cleaner than localStorage flag for one-time signal | ✓ Good — cleared with replace:true, preserves back button |
| needsCalibration OR selectedTopics.length === 0 | Returning uncalibrated users also get CalibrationOverlay | ✓ Good — covers both onboarding and direct-nav paths |
| Geofence-only search (remove BallotReady fallback) | Platform self-sufficiency with cached data | ✓ Good — PostGIS point-in-polygon matching, federal/state cache fallback |
| Keep ballotready/ package as dead code | Preserve admin import pipeline for historical reference | ✓ Good — isolated, cannot compile, no active imports |
| Legacy Google Maps Autocomplete class (not PlaceAutocompleteElement) | Existing API key predates March 2025 cutoff | ✓ Good — works reliably; migration deferred to Out of Scope |
| hasValidSelection guard on search | Prevent raw text submission to address search | ✓ Good — user must select from Google suggestions |
| LocalFilterSidebar created locally in essentials | Avoid ev-ui publish cycle for one-off component | ✓ Good — clean migration path if needed later |
| DROP TABLE for cache tables in Init() | Idempotent cleanup of deprecated federal/state/zip caches | ✓ Good — safe to run on every server start |
| Candidate endpoint is DB-only (no live fetch) | BallotReady removed; candidates from election_records | ✓ Good — replaces previous live-fetch decision |
| 50/50 CalibrationOverlay layout | Give stances more breathing room vs 60/40 split | ✓ Good — question text anchored above stances |
| buildSubtitle() for chamber+district | LOCAL edge case: chamber_name === office_title falls back to district_label | ✓ Good — clean 3-line card layout |
| Circle photo/avatar shape on profiles | Visual consistency between actual photos and initials placeholder | ✓ Good — borderRadius 50% on both |
| X0001 MTFCC → LOCAL district type | BallotReady custom code for city council ward sub-district boundaries | ✓ Good — Bloomington council districts visible in search |
| Bloomington districts from ArcGIS FeatureServer | Official city data source for council district boundaries | ✓ Good — 6 districts imported with ST_MakeValid for geometry fixes |
| Composite unique (geo_id, mtfcc) on geofence_boundaries | Idempotent upserts across boundary types without row loss | ✓ Good — multi-layer TIGER + ArcGIS imports coexist safely |
| ST_Covers replaces ST_Contains | Addresses on boundary lines must return results | ✓ Good — identical API, covers boundary-coincident points |
| Shared utils.py for import scripts | Prevent get_engine() duplication across 6+ scripts | ✓ Good — consistent patterns, synthetic ID allocation |
| Synthetic external IDs start at -200001 | Avoid collision with v1.5 -100001 range | ✓ Good — clear ID namespace separation per milestone |
| OCD-ID as geo_id for X0001 boundaries | Direct match to essentials.districts.ocd_id enables join chain | ✓ Good — supervisor and council ward lookup works end-to-end |
| Config-driven scraper with seat-first dedup | Reusable across cities; dedup by seat not just name | ✓ Good — 89 cities, 0 duplicate violations |
| rapidfuzz replaces python-Levenshtein | Same API, builds cleanly on macOS without C extension | ✓ Good — tight threshold (1) prevents false matches on short names |
| SOS PDF bulk extraction for city councils | Authoritative statewide source; avoids per-city website scraping | ✓ Good — 368 politicians from single data source |
| Hardcoded roster for school boards | District websites universally blocked by Cloudflare | ✓ Good — 402 board members verified from public records |
| UNSD (G5420) only, no G5400/G5410 | Prevent school board triple-match in overlapping district areas | ✓ Good — clean single-match per address |
| 5 district-election cities treated as at-large | SOS PDF provides district=0; per-ward assignment deferred | ⚠️ Revisit — works but loses ward-level precision |
| Supabase Storage for all scraped photos | Government URLs break silently; CDN re-hosting is durable | ✓ Good — 84 headshots + 11 building photos in CDN, zero hotlinks |
| Wikipedia Commons as primary headshot source | CC-licensed, stable URLs, proper portrait orientation | ✓ Good — 14/20 high-value headshots from Commons |
| Photo_license column required before storing | CA government photos not automatically public domain | ✓ Good — every image has license tracked |
| 5-strategy headshot extraction cascade | Name proximity → alt-text → CSS background → Playwright → Wikipedia | ✓ Good — maximizes automated coverage before manual fallback |
| Cloudflare detection: status + cf-ray header | Plain 403 from nginx is "failed" (retries), not "blocked" (skipped) | ✓ Good — prevents false permanent skips |
| Manual headshot_url override in city_sources.json | ~55 cities block automated scraping; manual research is only path | ✓ Good — pipeline supports overrides; manifest CSV ready |
| BuildingImages CURATED_LOCAL hardcoded CDN URLs | Simpler than Go API endpoint for fixed 11 cities | ✓ Good — no architectural complexity for static data |
| Contact section below profile photo (left column) | Icons identify contact type; narrow column optimized | ✓ Good — phone/globe/envelope SVG icons |
| Coverage validation as standalone Python script | Reproducible, CI-integrable, no Go dependency | ✓ Good — exit code 0/1 for pass/fail gating |

---
*Last updated: 2026-02-26 after v1.7 milestone*
