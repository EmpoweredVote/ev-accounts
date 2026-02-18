# Empowered Vote Platform

## What This Is

A civic engagement platform helping voters make informed decisions through an interactive political compass quiz (CompassV2), politician discovery by location (Essentials), and feature prototypes (Read & Rank, Treasury Tracker, Data Entry, Empowered Badges). The platform is run by a nonprofit with a 2-3 person dev team, currently deployed across Netlify, Supabase, Render, and AWS App Runner. The compass works without login (guest-first), renders cleanly across devices, and Essentials surfaces both officials and candidates with building imagery and term dates.

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

### Active

(None — define in next milestone via `/gsd:new-milestone`)

### Out of Scope

- Infrastructure migration — research only, migrate in future milestone
- Mobile app — web-first
- Real-time chat — high complexity, not core
- New prototype features — focus on polishing existing ones
- Data import automation — manual processes acceptable for now
- Full state/local issue coverage for compass — indicators shipped, content later
- Monorepo migration — deferred to v2, current multi-repo structure works
- OAuth login (Google, GitHub) — email/password sufficient for current user base

## Context

Shipped v1.0 with ~28K LOC across 4 repos:
- **CompassV2** (React 19): 6.8K LOC — compass quiz, Library, guest auth flow
- **EV-Backend** (Go 1.24): 15.4K LOC — auth, compass, essentials, treasury, staging modules
- **ev-ui** (React/tsup): 2.7K LOC — RadarChartCore, PoliticianCard with badge prop
- **essentials** (React 19): 3K LOC — politician discovery, candidate toggle, building imagery

Tech stack: Go/Chi/GORM/PostgreSQL backend + React 19/Vite/Tailwind frontends + Supabase DB.
BallotReady API is the primary data source for politicians and candidates.
ev-ui published to GitHub npm registry (v0.1.17), consumed by CompassV2 and essentials.

Known tech debt: RadarChart.jsx dead code block, SVG placeholder building images, ev-ui version pin mismatch between CompassV2 (^0.1.16) and essentials (^0.1.17).

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
| Infrastructure: defer migration | Nonprofit needs cost-effective hosting | — Pending — research only, no action taken in v1.0 |
| Integration tests use real Supabase DB | Postgres schema namespacing requires real DB for accuracy | ✓ Good — caught real issues mock DB would miss |
| Circular import fix via GORM Table() | auth->compass->auth cycle in Go packages | ✓ Good — anonymous structs, no behavioral change |
| CompassContext owns auth state | Single source of truth for isLoggedIn/username | ✓ Good — eliminated duplicate auth fetches |
| Inline modal registration (custom form) | AuthForm is full-page, unsuitable for modal | ✓ Good — clean save prompt UX |
| Level stored as pq.StringArray (text[]) | Topics can have multiple governance levels | ✓ Good — flexible, backward compatible |
| LibraryDrawer write-in support | Users need to add custom stances from Library | ✓ Good — full drag-to-position UX with persistence |
| Candidate endpoint is live-fetch (no caching) | Election data changes frequently near elections | ✓ Good — freshness more important than speed for candidates |

---
*Last updated: 2026-02-18 after v1.0 milestone*
