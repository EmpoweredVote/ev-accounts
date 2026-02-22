# Empowered Vote Platform

## What This Is

A civic engagement platform helping voters make informed decisions through an interactive political compass quiz (CompassV2), politician discovery by location (Essentials), and feature prototypes (Read & Rank, Treasury Tracker, Data Entry, Empowered Badges). The platform is run by a nonprofit with a 2-3 person dev team, currently deployed across Netlify, Supabase, Render, and AWS App Runner. The compass works without login (guest-first) with guided onboarding for first-time users, renders cleanly across devices, and Essentials surfaces both officials and candidates with real building photographs, sticky sidebar layout, and contextual term dates on profile pages.

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

### Active

- [ ] BuildCompass guest support — "View Full Compass" and quiz completion work without login — v1.4
- [ ] Radar chart label clipping fixed — labels on far left/right edges no longer cut off — v1.4
- [ ] Radar chart label minimum size — short labels (Misinformation, Immigration, Medicare/Medicaid) remain readable — v1.4
- [ ] "Edit Topics" button removed from compass page — Library page handles topic editing — v1.4
- [ ] "Clear" button removed from Library page — v1.4
- [ ] Library stat cards fill full width on mobile — v1.4
- [ ] QuestionText more prominent on LibraryDrawer and stance selection — v1.4
- [ ] Tech debt: compassimport/seed CLI StartPhrase references cleaned up — v1.4
- [ ] Tech debt: Admin TopicEditor vestigial short_name field removed — v1.4

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

## Context

Shipped v1.3 with ~34K LOC across 4 repos:
- **CompassV2** (React 19): ~12K LOC — compass quiz, Library, guided onboarding, calibration auto-routing, guest auth flow, help walkthrough
- **EV-Backend** (Go 1.24): 15.4K LOC — auth, compass, essentials, treasury, staging modules
- **ev-ui** (React/tsup): 2.8K LOC — RadarChartCore with unanswered spokes and compare fix, PoliticianProfile, FilterSidebar
- **essentials** (React 19): 3K LOC — politician discovery, candidate toggle, real building photos, sticky layout

Tech stack: Go/Chi/GORM/PostgreSQL backend + React 19/Vite/Tailwind frontends + Supabase DB.
BallotReady API is the primary data source for politicians and candidates.
ev-ui published to GitHub npm registry (v0.1.21), consumed by CompassV2 and essentials.

Known tech debt: BallotReady transform.go doesn't map SubAreaName to RepresentingCity (frontend workaround in Results.jsx). Settings gear placement and spoke inversion persistence across views deferred. compassimport/models.go and seed CLI reference dropped StartPhrase column. Admin TopicEditor sends vestigial short_name field.

## Constraints

- **Tech stack**: Existing Go backend + React frontends — no framework migrations
- **Data source**: BallotReady API for politician data (until manual tool is ready)
- **Hosting**: Keep current hosting for now (Netlify, Supabase, Render/AWS App Runner)
- **Budget**: Nonprofit — prefer solutions that use existing AWS credits or free tiers
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
| Candidate endpoint is live-fetch (no caching) | Election data changes frequently near elections | ✓ Good — freshness more important than speed for candidates |
| Sticky two-panel layout with overflow:hidden | Sidebar must stay visible while scrolling long representative lists | ✓ Good — position:sticky + overflow-y:auto pattern works cleanly |
| IntersectionObserver root scoped to scroll container | Scroll-spy must detect tier boundaries within the panel, not viewport | ✓ Good — tier-swap works correctly in two-panel layout |
| Wikimedia Commons photos (public domain/CC) | Civic app needs license-safe building images | ✓ Good — 5 buildings covered, SVG fallback for unsupported locations |
| Chamber_name regex for city extraction | BallotReady transform doesn't populate representing_city | ⚠️ Revisit — frontend workaround; backend fix deferred |
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

---
*Last updated: 2026-02-22 after v1.4 milestone started*
