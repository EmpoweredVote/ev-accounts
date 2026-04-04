# Empowered Vote Platform

## What This Is

A civic engagement platform helping voters make informed decisions through an interactive political compass quiz (CompassV2), politician discovery by address (Essentials), and a standalone quote evaluation app (Read & Rank at `readrank.empowered.vote`). The platform is run by a nonprofit with a 2-3 person dev team, deployed across Cloudflare Pages (frontends), Render (backend), and Supabase (DB + CDN). The compass works without login (guest-first) with guided onboarding, coach mark tours, write-in stances, and full localStorage persistence; it features an inline politician picker on the compare page with level/state filters. Essentials uses Google Maps address autocomplete with PostGIS geofence matching to surface the full representative hierarchy for LA County addresses, with headshot photos (503 CDN-hosted), city hall building photos, contact info, chamber/district subtitles, and contextual term dates. Politician profiles display legislative activity (committees, leadership, bills, votes) from Congress.gov, LegiScan, Open States, and local scrapers; a compass comparison card with dual-overlay radar chart; and per-quote verdict badges from Read & Rank integrated inline under topic drill-downs in the StanceAccordion. Read & Rank verdicts flow to Essentials via URL fragment for guests (cached to localStorage) and via server-side storage for logged-in users (auto-POSTed from Read & Rank, fetched by Essentials as highest priority). Local government sections display specific body names with official website links, powered by the government_bodies table. State legislative data is verified via automated audit scripts with a documented new-session playbook. All three apps share a unified SiteHeader (from ev-ui) with auth-aware profile menu showing login state and cross-app navigation via production .empowered.vote URLs. Essentials includes an Election Central page showing upcoming races for a user's address grouped by government tier, with candidate profile pages featuring incumbent/challenger branching — incumbents reuse full politician profiles with CompassCard, challengers render minimal views. The representatives page has an elected/appointed filter with retention judge dual-appearance. Election data covers Indiana (SoS Excel) and LA County (HTML incumbent scraper) with antipartisan enforcement at the schema and ingestion layers.

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
- ✓ 8-table legislative data model (sessions, committees, memberships, leadership, bills, cosponsors, votes, ID bridge) — v2026.3
- ✓ Federal committee and leadership import from congress-legislators YAML — v2026.3
- ✓ Congress.gov API client with rate limiting and exhaustive pagination — v2026.3
- ✓ Federal bills and votes batch import (House via Congress.gov, Senate via LegiScan) — v2026.3
- ✓ LegiScan API client with monthly budget tracking — v2026.3
- ✓ State legislative import for Indiana and California (bills, votes, committees) via LegiScan + Open States — v2026.3
- ✓ Local data pipeline for Bloomington (OnBoard scraping) and LA County (Legistar OData) — v2026.3
- ✓ Five legislative API endpoints (committees, leadership, bills, votes, legislative-summary) — v2026.3
- ✓ LegislativeInlineSummary and LegislativeRecord components in ev-ui with session filtering — v2026.3
- ✓ Graceful empty states for legislative sections when data unavailable — v2026.3
- ✓ Indiana committee data imported via IGA direct API with current session memberships — v2026.4
- ✓ California committee data imported via Open States API — v2026.4
- ✓ Indiana and California legislative data verified complete (bills, votes, committees) — v2026.4
- ✓ Import scripts documented and repeatable with state_legislative_config.json and new-session playbook — v2026.4
- ✓ All state legislative data accessible through existing API endpoints — v2026.4
- ✓ 304 politicians researched for headshot availability (100% coverage of manifest) — v2026.4
- ✓ 180 headshots uploaded to Supabase Storage CDN, total 503 CDN records — v2026.4
- ✓ CDN headshot health validation (100% URL health) — v2026.4
- ✓ Compass page refresh persistence — calibration, quiz, resume-mode state survives F5 — v2026.4
- ✓ Topics-loading race condition eliminated with branded spinner gate — v2026.4
- ✓ Reusable CoachMark component with SVG mask spotlight overlay — v2026.4
- ✓ Post-calibration guided tour (spoke inversion, compare, library) — v2026.4
- ✓ Library and Compare deep-dive guided tours — v2026.4
- ✓ Write-in awareness hint on first calibration question — v2026.4
- ✓ Welcome screen simplified with static compass SVG — v2026.4
- ✓ Compass comparison card on Essentials politician profiles (dual-overlay radar chart + stance breakdown) — v2026.3.2
- ✓ Guest compass data bridge via URL fragment encoding (CompassV2 → Essentials cross-origin) — v2026.3.2
- ✓ Politician compass stances fetchable from Essentials profile pages — v2026.3.2
- ✓ CompassPreview mini radar popover on dashboard politician cards with CTA mode — v2026.3.2
- ✓ StanceAccordion with lazy context fetching, reasoning text, and favicon source links — v2026.3.2
- ✓ Cookie domain fix for cross-app session sharing (.empowered.vote) — v2026.3.2
- ✓ Local government sections display specific body names (e.g., "Monroe County Council" instead of "County Council") — v2026.3.3
- ✓ Each government body section links to its official website — v2026.3.3
- ✓ County commissioners, county council, and county officials displayed as distinct sections — v2026.3.3
- ✓ State-specific local government organization (Indiana county structure) — v2026.3.3
- ✓ City-level bodies use specific names and website links — v2026.3.3
- ✓ Township-level bodies use specific names and website links — v2026.3.3
- ✓ Read & Rank extracted to standalone repo at `readrank.empowered.vote` on Cloudflare Pages — v2026.3.4
- ✓ EV brand design applied to Read & Rank (white card pattern, amber/cyan verdict badges, ev-muted-blue accents, Manrope) — v2026.3.4
- ✓ `compass.quote_verdicts` table with bulk-upsert POST and GET endpoints (authenticated) — v2026.3.4
- ✓ `GET /essentials/quotes?politician_id=X` filter for per-politician quote fetch — v2026.3.4
- ✓ ev-ui v0.1.43 with `verdictsByQuote` prop on StanceAccordion, lazy quote fetch cache — v2026.3.4
- ✓ Verdict fragment bridge: Read & Rank encodes verdicts in URL, Essentials parses and caches to localStorage — v2026.3.4
- ✓ CompassContext `verdicts` state with priority chain (API > fragment > localStorage) — v2026.3.4
- ✓ "View on Essentials" CTAs in Read & Rank ResultsPhase and CandidateAlignmentPage with verdict fragment — v2026.3.4
- ✓ Read & Rank auto-POSTs verdicts to backend on results phase completion (logged-in users) — v2026.3.4
- ✓ Essentials fetches logged-in user verdicts from backend as highest-priority source — v2026.3.4
- ✓ SiteHeader nav links updated to production .empowered.vote URLs (ev-ui v0.1.49) — v2026.3.5
- ✓ Auth-aware SiteHeader on every Essentials page (username/logout/sign-in) — v2026.3.5
- ✓ Auth-aware SiteHeader in ReadRank (username/logout/sign-in via useAuthState hook) — v2026.3.5
- ✓ Cross-app login redirect with returnTo query param (Essentials/ReadRank → Compass) — v2026.3.5
- ✓ Unified evaluate+rank flow with head-to-head matchup ranking (no separate ranking screen, no drag-to-rank) — v2026.3.6
- ✓ Practice round onboarding with pizza-topping quotes and emoji character avatars — v2026.3.6
- ✓ Coach mark spotlight tour on first real issue (swipe area + rank panel) — v2026.3.6
- ✓ Location-based filtering via Google Maps Places autocomplete with Essentials cross-app ?address= context — v2026.3.6
- ✓ Results page redesign with particle effects, simplified cards, View on Essentials primary CTA — v2026.3.6
- ✓ Fraunces removed, Manrope throughout, AnimatePresence page transitions, prefers-reduced-motion — v2026.3.6
- ✓ Chrome cleanup: ProgressHeader, AnimationOptionsPage, BadgeIcons, RankingPhase, CollectionPhase deleted — v2026.3.6
- ✓ Zustand store migrated through versions 2-7 with clean-reset for returning users — v2026.3.6
- ✓ Election schema (elections, races, race_candidates) with antipartisan enforcement and faces_retention_vote — v2026.3.8
- ✓ is_appointed data audit with backfill plan for all post-BallotReady officials — v2026.3.8
- ✓ Election data imported for Indiana SoS + LA County (2 elections, 12 races, 18 candidates) — v2026.3.8
- ✓ Election Central page with tier-grouped races, candidate cards, primary ballot labels, countdown — v2026.3.8
- ✓ Elected/Appointed filter with retention judge dual-appearance on Representatives page — v2026.3.8
- ✓ Candidate profile pages with incumbent/challenger branching and CompassCard wiring — v2026.3.8
- ✓ Tier-level hue differentiation (Federal/State/Local) on representatives and election pages — v2026.4.1
- ✓ Icon overlay badges (ballot, branch type) with accessible floating-ui tooltips — v2026.4.1
- ✓ Landing page coverage areas (Monroe County IN, LA County CA) with shortcut navigation — v2026.4.1
- ✓ Election page restructured: position-first grouping with party sub-labels — v2026.4.1
- ✓ Headshot audit script with 4 checks (missing, broken, size, dimensions) and CSV output — v2026.4.1

### Active

## Current Milestone: v2026.4.1 Essentials Visual Polish & Election Improvements

**Goal:** Improve visual clarity and information hierarchy of representatives and election pages, fix data issues, and add location-aware browsing.

**Target features:**
- Visual redesign of election + representatives pages (reduce information overload, improve tier readability)
- Tier-level hue differentiation (local vs state vs federal, city vs township vs county)
- Small subtle icons replacing badges (on ballot, compass available, branch type) with hover details
- Icon set research fitting EV design system
- Remove "incumbent" marker from candidate cards
- Fix Ruben Marte name mismatch to link candidate to politician profile
- Headshot cropping audit and fix
- Main page: explicit coverage messaging (Monroe County IN / LA County CA) with prominent location buttons
- Lightweight compass-first card prototype (real reps, explore removing photos from results)

### Future

- [ ] Compass stance data imports for candidates (PROF-04 — deferred from v2026.3.8)
- [ ] Sourced quote imports for candidates (PROF-05 — deferred from v2026.3.8)
- [ ] County council at-large vs district members distinguished in display (carried from v2026.3.3)
- [ ] State-configurable body structure for California Board of Supervisors (carried from v2026.3.3)
- [ ] LA County bodies seeded with official website URLs (carried from v2026.3.3)
- [ ] "My reps" surfacing on compare page (Essentials address → Compass compare)
- [ ] Politician self-calibrated compass with toggle view on profiles
- [ ] Multi-politician comparison (2-3 overlays at once)

## Last Milestone: v2026.3.8 Essentials Election Central (Shipped 2026-03-31)

**Delivered:** Election Central page added to Essentials with tier-grouped races, candidate profile pages (incumbent/challenger branching), elected/appointed filter on representatives page. Election data imported for Indiana and LA County. 5 phases, 12 plans. 19/19 active requirements satisfied, 2 deferred (PROF-04/05).

## Previous Milestones

- **v2026.3.7 Treasury Tracker Expansion** (Shipped 2026-03-23) — 5 phases, 11 plans
- **v2026.3.6 Read & Rank Redesign** (Shipped 2026-03-16) — 7 phases, 15 plans

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
- City council headshot coverage beyond 66.8% — remaining 33.2% blocked by Cloudflare/CivicPlus/unarchived sites
- School board data enrichment — low data availability
- Bio/education/experience for city council members — high per-city effort
- Real-time vote syncing — ops complexity too high; weekly batch sufficient
- Full bill text display — link to Congress.gov/state sites instead
- Interest group ratings / ideology scores / vote alignment % — antipartisan mission
- AI-generated bill summaries — CRS federal summaries only for now

## Context

Shipped v2026.3.8 across 2 repos:
- **ev-accounts** (Node.js/Express/TypeScript): election schema (migrations 042-044), electionService, candidateService, importElectionData CLI
- **essentials** (React 19): Election Central tab, SegmentedControl filter, CandidateProfile page
- **CompassV2** (React 19): ~14.5K LOC — unchanged this milestone
- **ev-ui** (React/tsup): ~4K LOC — unchanged this milestone
- **EV-readrank** (React 19 + TypeScript): ~5,990 LOC — unchanged this milestone
- **Python scripts**: ~17K LOC — unchanged

Tech stack: Node.js 20/Express 4/TypeScript 5.6/Supabase PostgreSQL + React 19/Vite/Tailwind + PostGIS + Supabase Storage CDN + Cloudflare Pages.
ev-ui published to GitHub npm registry, consumed by CompassV2, essentials, and EV-readrank.

## Constraints

- **Tech stack**: Existing Go backend + React frontends — no framework migrations
- **Data source**: Cached politician data from database; Google Maps for geocoding
- **Hosting**: Cloudflare Pages (frontends), Supabase (DB), Render (backend)
- **Budget**: Nonprofit — prefer free tiers; Google Maps free tier (28K requests/month)
- **Team**: 2-3 devs

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-04 after Phase 105 complete — seed SQL verified clean, SUMMARY traceability backfilled*
