# Empowered Vote Platform

## What This Is

A civic engagement platform helping voters make informed decisions through an interactive political compass quiz (CompassV2), politician discovery by address (Essentials), and feature prototypes (Read & Rank, Treasury Tracker, Data Entry, Empowered Badges). The platform is run by a nonprofit with a 2-3 person dev team, currently deployed across Netlify, Supabase, and Render. The compass works without login (guest-first) with guided onboarding and write-in stances in calibration, renders cleanly across devices, and features an inline politician picker on the compare page with level/state filters across both picker surfaces. Essentials uses Google Maps address autocomplete with PostGIS geofence matching — including ST_Intersects area-boundary search for city/ZIP queries — to surface the full representative hierarchy for LA County addresses, with headshot photos (Supabase CDN), city hall building photographs, contact info sections, chamber/district subtitles, initials avatars, and contextual term dates on profile pages. A repeatable TIGER + ArcGIS import pipeline and config-driven enrichment scripts support expansion to additional regions.

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
- ✓ Library → Compass transition auto-enters calibration for unanswered topics — v1.3
- ✓ Double comparison overlay bug on compare page fixed — v1.3
- ✓ Topic titles standardized server-side — v1.3
- ✓ "Where do you stand on..." prefix removed from card display for scannability — v1.3
- ✓ Compass renders correctly with mixed answered/unanswered topics — v1.3
- ✓ BuildCompass guest support — v1.4
- ✓ Radar chart label clipping fixed — v1.4
- ✓ Radar chart label minimum size — v1.4
- ✓ "Edit Topics" button removed from compass page — v1.4
- ✓ "Clear" button removed from Library page — v1.4
- ✓ Library stat cards fill full width on mobile — v1.4
- ✓ QuestionText more prominent on LibraryDrawer and stance selection — v1.4
- ✓ Tech debt: compassimport/seed CLI StartPhrase references cleaned up — v1.4
- ✓ Tech debt: Admin TopicEditor vestigial short_name field removed — v1.4
- ✓ Onboarding-to-calibration redirect — v1.4
- ✓ Compare page question-text-first display — v1.4
- ✓ Address search uses PostGIS geofence-only matching — v1.5
- ✓ Federal/state officials from cache when local geofence data unavailable — v1.5
- ✓ All BallotReady cache warmers and provider infrastructure removed — v1.5
- ✓ Google Maps Places autocomplete as sole search input — v1.5
- ✓ Validated/confirmed address displayed in search results — v1.5
- ✓ Clear no-geofence-data coverage message for unsupported areas — v1.5
- ✓ BALLOTREADY_API_KEY decommissioned from all environments — v1.5
- ✓ CalibrationOverlay 50/50 layout with write-in drag-and-drop — v1.5
- ✓ Chamber/district subtitles on politician cards — v1.5
- ✓ Initials avatar for missing profile images — v1.5
- ✓ Labeled term dates and years in office on profiles — v1.5
- ✓ Bloomington city council district boundaries imported — v1.5
- ✓ ev-ui 0.1.27 with updated PoliticianProfile and PoliticianCard — v1.5
- ✓ Geofence schema: composite unique constraint on (geo_id, mtfcc) — v1.6
- ✓ ST_Covers spatial predicate for boundary-inclusive address matching — v1.6
- ✓ TIGER 2024 geofences: congressional, state senate/assembly, school districts, 482 CA city boundaries — v1.6
- ✓ LA County ArcGIS geofences: supervisor districts, city council wards — v1.6
- ✓ Politician gap-fill: 791 LA County officials — v1.6
- ✓ Deduplication: seat-first dedup with rapidfuzz matching — v1.6
- ✓ Point-in-polygon validation: 16/16 test addresses pass — v1.6
- ✓ Import pipeline runbook — v1.6
- ✓ Headshot photos for LA County supervisors and LA City council in Supabase CDN — v1.7
- ✓ City hall building photos from Wikimedia Commons — v1.7
- ✓ Contact website URLs for all 89 LA County cities — v1.7
- ✓ Term date precision with UTC-safe frontend formatting — v1.7
- ✓ All scraped photos re-hosted to Supabase Storage CDN — v1.7
- ✓ Batch headshot scraper with 5-strategy extraction — v1.7
- ✓ Coverage validation script — v1.7
- ✓ Contacts API endpoint and frontend contact section — v1.7
- ✓ Building photo API endpoint — v1.7
- ✓ Config-driven pipeline_config.json — v1.7
- ✓ Legacy 50-topic seed code removed; compass_csv_seeder.go sole source of truth — v1.8
- ✓ Stance research CSV with 455 sourced data rows across 23 politicians — v1.8
- ✓ Source URL integrity: 700+ hallucinated URLs cleared — v1.8
- ✓ 61 verbatim sourced politician quotes for Read & Rank — v1.8
- ✓ Go CLI import subcommands (import-stances, import-quotes) — v1.8
- ✓ GET /essentials/quotes API endpoint with LATERAL JOIN — v1.8
- ✓ Inline politician picker on compare page — searchable dropdown with keyboard nav, morph switching — v1.9
- ✓ Level pills (Federal/State/Local) and state dropdown filters on both picker surfaces — v1.9
- ✓ Area-intersection search — ST_Intersects boundary overlap for city/ZIP/county queries — v1.9
- ✓ Unified search path — single POST endpoint, no ZIP vs address branching — v1.9
- ✓ Re-search bug fix — searchKey counter forces hook re-fetch on results page — v1.9

### Active

- [ ] "My reps" surfacing on compare page (Essentials address → Compass compare)
- [ ] Cross-app integration (compass overlay on Essentials profiles, Read & Rank quotes)
- [ ] Multi-politician comparison (2-3 overlays at once)

### Out of Scope

- Infrastructure migration — research only, migrate in future milestone
- Mobile app — web-first
- Real-time chat — high complexity, not core
- Data import automation — manual processes acceptable for now
- Monorepo migration — deferred to v2
- OAuth login — email/password sufficient
- Building images for all US locations — only Bloomington IN and LA County CA covered
- ZIP code fallback for privacy — address-only
- TIGER shapefile expansion beyond Monroe County IN + LA County CA — pipeline reusable
- PlaceAutocompleteElement migration — legacy Autocomplete class works
- Per-ward council assignment for 5 district-election cities — at-large treatment acceptable
- City council headshot coverage beyond 21.5% — needs manual curation
- School board data enrichment — low data availability
- Bio/education/experience for city council members — high per-city effort

## Context

Shipped v1.9 with ~41K LOC across 4 repos + Python/CSV data pipeline:
- **CompassV2** (React 19): ~13K LOC — compass quiz, Library, guided onboarding, calibration, guest auth, inline politician picker with level/state filters
- **EV-Backend** (Go 1.24): ~19K LOC — auth, compass, essentials (geofence-only + PostGIS with area-intersection search, contacts API, building photo endpoint, quotes API), treasury, staging; CLI import subcommands
- **ev-ui** (React/tsup): ~3K LOC — RadarChartCore, PoliticianProfile, PoliticianCard
- **essentials** (React 19): ~3K LOC — address autocomplete, unified search path, area labels, building photos

Tech stack: Go/Chi/GORM/PostgreSQL + React 19/Vite/Tailwind + Supabase DB + PostGIS + Supabase Storage CDN.
ev-ui published to GitHub npm registry, consumed by CompassV2 and essentials.

## Constraints

- **Tech stack**: Existing Go backend + React frontends — no framework migrations
- **Data source**: Cached politician data from database; Google Maps for geocoding
- **Hosting**: Netlify (frontends), Supabase (DB), Render (backend)
- **Budget**: Nonprofit — prefer free tiers; Google Maps free tier (28K requests/month)
- **Team**: 2-3 devs

---
*Last updated: 2026-02-28 after v1.9 milestone*
