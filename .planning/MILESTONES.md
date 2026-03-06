# Milestones

## v2026.4 State Data Completion & Image Coverage (Shipped: 2026-03-06)

**Phases completed:** 7 phases, 21 plans
**Timeline:** 2 days (2026-03-05 — 2026-03-06)
**Requirements:** 23/23 satisfied
**Repos:** EV-Backend, CompassV2, essentials

**Delivered:** State legislative data completed for Indiana and California (committee memberships verified and documented), headshot coverage expanded from 21.5% to 66.8% (503 CDN records), Compass page refresh persistence fixed, and guided onboarding coach mark system added.

**Key accomplishments:**
1. Indiana committee import — IGA direct API integration importing 46 standing committees and 61 memberships with 88.9% legislator coverage; state_legislative_config.json as shared session config
2. California committee import — Open States API importing 1,900 committees and 213 memberships with 83.8% legislator coverage; DB reconnect fix for Supabase idle timeout during 15-min CA pagination
3. State data verification — Comprehensive audit confirming IN (935 bills, 6,069 votes, 94.4% bridge) and CA (4,746 bills, 92,492 votes, 94.6% bridge) with documented gaps and new-session playbook
4. Headshot research sprint — 304/304 politicians manually researched (100% coverage), 246 found (80% hit rate) using HTTP scraping + Wayback Machine for Cloudflare/CivicPlus-blocked city sites
5. Headshot CDN pipeline — 180 new headshots uploaded to Supabase Storage CDN via upload_manifest_headshots.py, total 503 CDN records, 100% URL health validation
6. Compass page refresh fix — CalibrationOverlay, resume-mode, and quiz page state all persist across F5 via localStorage; topics-loading race condition eliminated with branded spinner gate
7. Onboarding coach mark system — Reusable CoachMark component with SVG mask spotlight, post-calibration 3-step guided tour, Library 2-step tour, Compare deep-dive tour, write-in awareness hint, simplified welcome screen

**Tech debt carried forward:**
- Dead `ballotready/` package preserved for historical reference (carried from v1.5)
- Orphaned `checkCacheStatus` in essentials `api.jsx` (carried from v1.5)
- 5 district-election cities treated as at-large (carried from v1.6)
- `fetchPoliticiansOnce` and `fetchPoliticiansProgressive` deprecated but not deleted in essentials `api.jsx` (carried from v1.9)
- `leg_data_fetched_at` column unused (carried from v2026.3)
- Topic tags placeholder div in LegislativeInlineSummary (carried from v2026.3)
- 12 politicians have no Read & Rank quotes (carried from v1.8)

---

## v2026.3 Legislative Profile Data (Shipped: 2026-03-05)

**Phases completed:** 6 phases, 19 plans
**Timeline:** 4 days (2026-03-01 — 2026-03-04)
**Requirements:** 34/34 satisfied
**Repos:** EV-Backend, ev-ui, essentials

**Delivered:** Politician profiles enriched with legislative activity — committees, leadership roles, voting records, and sponsored legislation — across federal, state (Indiana + California), and local (Bloomington + LA County) government levels with session filtering and graceful empty states.

**Key accomplishments:**
1. Legislative data model — 8 new tables (sessions, committees, memberships, leadership roles, bills, cosponsors, votes, ID bridge) with AutoMigrate and bioguide/legiscan/openstates cross-reference bridge
2. Federal import pipeline — Go CLI subcommands importing committees and leadership from congress-legislators YAML, bills and votes via Congress.gov API + LegiScan with rate limiting and exhaustive pagination
3. State legislative pipeline — Python import scripts for Indiana (2,424 bills, 15,223 votes) and California (5,310 bills, 105,151 votes) via LegiScan Dataset API, plus IGA/Open States committee matching
4. Local data pipeline — Bloomington Common Council (committees + legislation via OnBoard HTML scraping) and LA County BOS (legislation via Legistar OData); feasibility-gated with documented limitations
5. Five legislative API endpoints — committees, leadership, bills, votes, and legislative-summary with session filtering, significance defaults, and bounded overview for profile render
6. Frontend components — LegislativeInlineSummary and LegislativeRecord in ev-ui with session year filters, role badges, graceful empty states, and essentials profile integration

**Known Gaps (from audit):**
- Federal import CLIs not yet run on active database (bridge table empty — human action required)
- LA County BOS committee memberships structurally unavailable from Legistar API (permanent limitation)
- LA County legislation attribution <5% (Legistar data quality)
- Topic tags placeholder in LegislativeInlineSummary (deferred feature)
- leg_data_fetched_at column unused (future lazy-fetch optimization)

**Tech debt carried forward:**
- Dead `ballotready/` package preserved for historical reference (carried from v1.5)
- Orphaned `checkCacheStatus` in essentials `api.jsx` (carried from v1.5)
- 5 district-election cities treated as at-large (carried from v1.6)
- `fetchPoliticiansOnce` and `fetchPoliticiansProgressive` deprecated but not deleted in essentials `api.jsx` (carried from v1.9)
- PHOTO-03 headshot coverage at 21.5% (carried from v1.7)
- 12 politicians have no Read & Rank quotes (carried from v1.8)

---

## v1.0 Quality & Consolidation (Shipped: 2026-02-18)

**Phases completed:** 7 phases, 21 plans
**Timeline:** 9 days (2026-02-10 - 2026-02-18)
**Requirements:** 21/21 satisfied
**Repos:** CompassV2, EV-Backend, ev-ui, essentials

**Delivered:** Platform hardened for demo-ready quality — guest-first compass, visual polish, interactive library, candidate support, and full auth audit.

**Key accomplishments:**
1. Guest-first compass — users take the full quiz without logging in, with localStorage persistence and server-wins merge on registration
2. Compass visual polish — chart fits viewport without scrolling, labels handle overflow gracefully, spoke visual artifacts removed
3. Compass UX enhancements — question prompts on issue cards, seeded stance randomization, interactive Library drawer with write-in support, level badges
4. Essentials candidate support — opt-in candidate toggle alongside officials, election dates, building imagery, federal legislative-first reordering
5. Auth hardening — middleware unit tests, integration test suite, 62-route audit manifest, admin-only clear compass
6. Integration quality — 3 audit gaps closed (guest console noise, register navigation, buildGuestState race condition)

**Tech debt carried forward:**
- RadarChart.jsx: Large commented-out block (dead code)
- ~~Building images: SVG placeholders~~ — resolved in v1.1 (real photographs added)
- CompassV2 pins ev-ui ^0.1.16 (essentials pins ^0.1.17) — functional, not blocking

---


## v1.1 Essentials UX Polish (Shipped: 2026-02-19)

**Phases completed:** 3 phases, 3 plans, 7 tasks
**Timeline:** 1 day (2026-02-18)
**Requirements:** 10/10 satisfied
**Repos:** essentials, ev-ui

**Delivered:** Essentials app polished for demo-ready UX — sticky sidebar layout, real building photographs, and contextual term dates on profile pages.

**Key accomplishments:**
1. Sticky sidebar layout — FilterSidebar stays fixed while representatives panel scrolls independently on desktop, with IntersectionObserver scoped to the scrolling container
2. Real building photographs — 5 government building JPEGs from Wikimedia Commons replace SVG placeholders for Bloomington and LA locations
3. Term dates relocated — removed from dashboard card clutter, now display contextually on politician profile pages with en-dash formatting
4. ev-ui 0.1.19 — shared component library updated with term date helpers (formatTermDate/getTermLine)

**Tech debt carried forward:**
- RadarChart.jsx: Large commented-out block (dead code) — carried from v1.0
- CompassV2 pins ev-ui ^0.1.16 (essentials now ^0.1.19) — functional, not blocking
- BallotReady transform.go doesn't map SubAreaName to RepresentingCity — frontend workaround in Results.jsx

---


## v1.2 Compass Onboarding & UX (Shipped: 2026-02-20)

**Phases completed:** 6 phases, 12 plans, 27 tasks
**Timeline:** 2 days (2026-02-18 - 2026-02-20)
**Requirements:** 15/15 satisfied
**Repos:** CompassV2, EV-Backend

**Delivered:** Compass quiz made intuitive for first-time users with guided card-by-card onboarding, topic selection enforcement, and a complete question framing overhaul.

**Key accomplishments:**
1. Guided onboarding flow — CalibrationOverlay on empty compass walks new users through topic selection card-by-card with live radar rendering
2. Topic selection enforcement — 8-topic cap and 3-topic minimum enforced across all paths (Library, onboarding, quiz)
3. Library UX improvements — default "All" filter, on-compass card indicators with add/remove toggle, X/8 counter badge
4. Question framing overhaul — rebranded to "Where do you stand on [topic]?" with 7 vague topic titles rewritten in database
5. Help page & auto-routing — 5-slide walkthrough with responsive screenshots, HelpGuard routes new users through /help first
6. Audit gap closure — fixed non-admin compass reset (403 bug), synced help_seen from DB completed_onboarding flag, removed unused imports

**Tech debt carried forward:**
- BallotReady transform.go doesn't map SubAreaName to RepresentingCity — frontend workaround in Results.jsx
- Settings gear placement and spoke inversion persistence across views — cosmetic, deferred
- QFRM-02 topic title rewrites are database-only (needs live server to verify display)

---


## v1.3 Compass Bug Fixes & Title Standardization (Shipped: 2026-02-22)

**Phases completed:** 4 phases, 7 plans
**Timeline:** 2 days (2026-02-20 - 2026-02-21)
**Requirements:** 7/7 satisfied
**Repos:** CompassV2, EV-Backend, ev-ui

**Delivered:** Compass topic naming standardized server-side, calibration flow fixed for all mixed-state edge cases, and double-overlay compare bug eliminated.

**Key accomplishments:**
1. Title standardization — all 21 compass topics use tension title format (Topic: Pole A — Pole B) as server-side canonical source of truth, with deprecated ShortName/StartPhrase columns dropped
2. Unified topic display — parseTensionTitle helper renders consistent two-line layout across Library cards, calibration cards, compass spoke labels, quiz, and compare panel
3. Calibration auto-routing — users with unanswered topics auto-enter calibration starting at first unanswered topic, with resume flow that skips pick step and exit gating until 3+ answered
4. Mixed-state radar chart — gray dashed unanswered spokes in RadarChartCore, below-3 threshold shows grayed chart overlay with calibration CTA instead of dead end
5. Compare bug fix — single polygon rendering with spoke-order iteration and immediate spring reset, published as ev-ui@0.1.21
6. Anti-partisan design — pole order randomized per topic (10 right-first, 11 left-first) to prevent visual bias

**Tech debt carried forward:**
- compassimport/models.go and cmd/seed/compass_csv_seeder.go still reference dropped StartPhrase column — standalone CLI tools, would fail at runtime
- Admin TopicEditor sends short_name in PATCH body (silently ignored) and initializes vestigial editedFields.short_name
- BallotReady transform.go SubAreaName → RepresentingCity mapping fix — frontend workaround in Results.jsx (carried from v1.1)

---


## v1.4 Compass Polish & Tech Debt (Shipped: 2026-02-22)

**Phases completed:** 5 phases, 9 plans
**Timeline:** 1 day (2026-02-22)
**Requirements:** 17/17 satisfied
**Repos:** CompassV2, EV-Backend, ev-ui

**Delivered:** Compass polished for demo-ready quality — guest flow fixed, radar labels readable, stale UI removed, question-text hierarchy unified, dead code cleaned up, and onboarding-to-calibration redirect working.

**Key accomplishments:**
1. Guest flow fix — BuildCompass uses localStorage answers for guests, gracefully handles 401 for logged-in users, no more infinite spinner
2. Radar label fixes — dynamic horizontal padding, minimum font size, word wrap in ev-ui RadarChartCore, published as ev-ui@0.1.26
3. UX cleanup — Edit Topics and Clear buttons removed, mobile stat card layout fixed, question-text-first hierarchy across all 4 compass views (Library, LibraryDrawer, Quiz, CalibrationOverlay)
4. Tech debt cleanup — StartPhrase references removed from compassimport/seed CLI, short_name removed from admin TopicEditor/TopicAccordion
5. Onboarding-to-calibration redirect — fresh users from onboarding enter calibration via ?calibrate=1 URL param, returning uncalibrated users trigger CalibrationOverlay via selectedTopics.length === 0 condition
6. Compare page text fix — ComparePanel now uses question-text-first hierarchy matching all other views

**Tech debt carried forward:**
- BallotReady transform.go SubAreaName → RepresentingCity mapping fix — frontend workaround in Results.jsx (carried from v1.1)

---


## v1.5 Address Verification & BallotReady Independence (Shipped: 2026-02-23)

**Phases completed:** 6 phases, 13 plans, 25 tasks
**Timeline:** 14 days (2026-02-09 - 2026-02-23)
**Requirements:** 23/23 satisfied (12 v1.5 core + 11 Phase 31 profile/district)
**Repos:** EV-Backend, essentials, ev-ui, CompassV2

**Delivered:** Platform made self-sufficient by removing BallotReady API dependency — address search uses Google Maps autocomplete with PostGIS geofence matching, plus Compass calibration layout polished and Essentials profiles enhanced with district data.

**Key accomplishments:**
1. BallotReady independence — address search uses PostGIS geofence-only matching; all cache warmers, provider infrastructure, and API keys fully removed from codebase and production environments
2. Google Maps Places autocomplete — replaces ZIP code input as sole search method with address validation, formatted address display, and graceful degradation
3. Federal/state cache fallback — addresses outside geofence coverage return federal and state officials from DB cache with clear coverage limitation messaging
4. CalibrationOverlay layout fix — 50/50 chart/stances split with write-in drag-and-drop support matching Quiz.jsx pattern
5. Essentials profile enhancements — chamber/district subtitles on cards, initials avatars, labeled term dates, office descriptions; bio_text and Issues section removed
6. Bloomington district visibility — city council Districts 1-6 boundaries imported from ArcGIS into geofence_boundaries; X0001 MTFCC mapped to LOCAL district type

**Tech debt carried forward:**
- Dead `ballotready/` package preserved for historical reference (intentional — cannot compile, isolated)
- Orphaned `checkCacheStatus` function in essentials `api.jsx` calls deleted `/cache-status/{zip}` route
- Stale comment in handlers.go lines 1757-1758 mentions BallotReady (comment-only)
- `Home.jsx` entirely commented-out dead code in essentials
- Candidates toggle returns empty array for address queries (no `/candidates/search-by-address` endpoint)
- Deprecated `cmd/bulk-import/main.go` and `runBulkImport` placeholder in admin.go

---


## v1.6 LA County Full Coverage (Shipped: 2026-02-24)

**Phases completed:** 7 phases, 11 plans, 23 tasks
**Timeline:** 1 day (2026-02-24)
**Requirements:** 23/23 satisfied
**Repos:** EV-Backend (schema, scripts, Go models)

**Delivered:** Full LA County geofence coverage — any LA County address returns the complete representative hierarchy (federal, state, county, city, school board) with a repeatable import pipeline for future regional expansion.

**Key accomplishments:**
1. Complete 5-layer geofence hierarchy — 482 CA city boundaries (G4110), 51 LA County local district boundaries (X0001), plus federal/state/school boundaries from TIGER + ArcGIS sources
2. 791 politicians gap-filled — 21 LA County officials (supervisors + city council + mayor), 368 city council members across 89 cities, 402 school board members across 79 districts
3. Reusable import pipeline — config-driven scrapers with seat-first dedup, shared Python utils (utils.py + requirements.txt), hardcoded roster fallback for anti-bot-protected sites
4. Point-in-polygon validation — 16/16 test addresses pass full tier verification, GiST index confirmed active after VACUUM ANALYZE
5. 545-line import runbook — step-by-step repeatable pipeline documentation for future county/region expansion

**Known Gaps (from audit):**
- MISS-01 (low): IMPORT-PIPELINE.md documents `--source` flag that import_arcgis_geofences.py doesn't implement — script always runs import_all()
- FLOW-01 (low): Runbook selective import commands would silently fail — no argparse in script

**Tech debt carried forward:**
- Photo re-hosting to Supabase Storage deferred — photo_origin_url stores scraped URL
- 5 district-election cities (Long Beach, Torrance, Pasadena, Inglewood, West Covina) treated as at-large — per-ward council assignment deferred
- Dead `ballotready/` package preserved for historical reference (carried from v1.5)
- Orphaned `checkCacheStatus` in essentials (carried from v1.5)

---


## v1.7 LA County Data Enrichment (Shipped: 2026-02-26)

**Phases completed:** 6 phases, 15 plans executed (1 deferred), 36 tasks
**Timeline:** 3 days (2026-02-24 - 2026-02-26)
**Requirements:** 18/19 satisfied (CONT-03 shipped but checkbox missed; PHOTO-03 at 21.5% vs 80% target)
**Repos:** EV-Backend (Go models, Python scripts), ev-ui, essentials

**Delivered:** LA County officials enriched with headshots, building photos, contact info, and term data via a reproducible scraping pipeline — 84 headshots in Supabase CDN, 11 city hall photos, 381 contact records, and coverage validation tooling.

**Key accomplishments:**
1. City council headshot pipeline — 1,247-line batch scraper with 5-strategy extraction cascade, Cloudflare detection, Supabase Storage CDN upload, and manual headshot_url override support; 84 headshots across 34 cities
2. High-value headshots — All 20 LA County supervisors and LA City council members have CC-licensed headshots from Wikipedia Commons, re-hosted to Supabase Storage
3. Building photos — 11 Wikimedia Commons city hall photos uploaded to Supabase CDN, served via buildingImages.js CURATED_LOCAL
4. Contact enrichment — 381 contact records imported (376 city website URLs for 89 cities + 5 supervisor phones), contacts API endpoint and frontend contact section in ev-ui PoliticianProfile
5. Term date precision — Supervisor term dates with UTC-safe year-precision formatting wired through Go API to frontend
6. Coverage validation — Standalone coverage_report.py confirms 84/84 CDN URLs pass, 89/89 cities have contacts, 0 government hotlinks

**Known Gaps:**
- PHOTO-03: Headshot coverage at 84/391 (21.5%) vs 80% target — automated pipeline hit ceiling at ~55 Cloudflare/CivicPlus-blocked cities; Plan 42-06 (manual browser curation sprint, ~4-6 hours) deferred
- Research manifest ready: `headshot_research_manifest.csv` (300 politicians, 82 cities) for future manual sprint

**Tech debt carried forward:**
- Dead `ballotready/` package preserved for historical reference (carried from v1.5)
- Orphaned `checkCacheStatus` in essentials (carried from v1.5)
- 5 district-election cities treated as at-large (carried from v1.6)
- PHOTO-03 coverage gap — pipeline infrastructure complete, data gap requires human research
- REQUIREMENTS.md had PHOTO-03 marked [x] despite 21.5% actual coverage

---


## v1.8 Compass Data & Politician Research (Shipped: 2026-02-27)

**Phases completed:** 6 phases, 28 plans
**Timeline:** 2 days (2026-02-26 — 2026-02-27)
**Requirements:** 21/21 satisfied
**Repos:** EV-Backend, EV-prototypes

**Delivered:** Compass populated with real politician stance data and sourced quotes — 23 politicians across CA and IN researched on 21 compass topics, with import scripts and a quotes API endpoint feeding Read & Rank.

**Key accomplishments:**
1. Legacy cleanup — removed 2,584 lines of deprecated 50-topic seed code (internal/seeds/, topics.json, cmd/seed/main.go stub), leaving compass_csv_seeder.go as sole source of truth
2. Stance research CSV — 455 sourced data rows across 23 politicians (CA/IN governors, lt. governors, US senators, 12 LA County House reps, Monroe County rep, 2 mayors) with integer 1-5 values on all 21 compass topics
3. Source URL integrity — cleared 700+ hallucinated/fabricated URLs across 6 cleanup plans (AP year-suffix patterns, house.gov/senate.gov slug-only press releases), retaining only verified congress.gov, news, and government sources
4. Quote collection — 61 verbatim sourced politician quotes for Read & Rank from 11 politicians, with strict verification removing 118 non-compliant rows citing generic index pages
5. Data import CLI — Go subcommands (import-stances, import-quotes) with CSV parsing, fuzzy name matching, two-pass ambiguous name detection, and GORM upsert logic
6. Quotes API endpoint — GET /essentials/quotes with LATERAL JOIN for office dedup; Read & Rank frontend updated with API client and graceful mockData.ts fallback

**Tech debt carried forward:**
- Dead `ballotready/` package preserved for historical reference (carried from v1.5)
- Orphaned `checkCacheStatus` in essentials (carried from v1.5)
- 5 district-election cities treated as at-large (carried from v1.6)
- PHOTO-03 headshot coverage at 21.5% (carried from v1.7)
- 12 politicians have no Read & Rank quotes (only verified verbatim quotes from specific sources retained)
- BallotReady external_ids left blank for all 23 researched politicians — import uses full_name matching

---


## v1.9 Compare UX & Search Fixes (Shipped: 2026-02-28)

**Phases completed:** 3 phases, 6 plans
**Timeline:** 2 days (2026-02-27 — 2026-02-28)
**Requirements:** 5/5 satisfied
**Repos:** CompassV2, EV-Backend, essentials

**Delivered:** Compare page enhanced with inline politician switching and level/state filters, and Essentials search fixed to return all representatives for area-level queries with unified search path.

**Key accomplishments:**
1. Inline politician picker — searchable dropdown with keyboard nav replaces header on compare page, switch politicians without leaving view; react-spring morphs radar polygon smoothly during data fetch
2. Politician list filters — level pills (Federal/State/Local) and state dropdown reused across both InlinePoliticianPicker and CompareModal via shared useFilteredPoliticians hook with zero code duplication
3. Area-intersection search — ST_Intersects boundary overlap replaces point-only matching for city/ZIP/county queries, returning all representatives whose districts overlap the searched area
4. Unified search path — removed ZIP vs address branching in frontend; all queries route through single POST search endpoint
5. Re-search bug fix — searchKey counter pattern forces hook re-fetch even for identical query text, fixing double-entry issue on results page
6. Area label display — results page shows "Showing representatives for {formattedAddress}" for area queries

**Tech debt carried forward:**
- Dead `ballotready/` package preserved for historical reference (carried from v1.5)
- Orphaned `checkCacheStatus` in essentials (carried from v1.5)
- 5 district-election cities treated as at-large (carried from v1.6)
- PHOTO-03 headshot coverage at 21.5% (carried from v1.7)
- 12 politicians have no Read & Rank quotes (carried from v1.8)
- fetchPoliticiansOnce and fetchPoliticiansProgressive deprecated but not deleted in essentials api.jsx

---

