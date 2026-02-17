# Empowered Vote Platform — Quality & Consolidation

## What This Is

A civic engagement platform helping voters make informed decisions through an interactive political compass quiz (CompassV2), politician discovery by location (Essentials), and feature prototypes (Read & Rank, Treasury Tracker, Data Entry, Empowered Badges). The platform is run by a nonprofit with a 2-3 person dev team, currently deployed across Netlify, Supabase, Render, and AWS App Runner. This milestone focuses on shipping quality — fixing bugs, improving UX, and making everything demo-ready for stakeholders.

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

### Active

- [ ] Remove login requirement from Compass — guest-first with optional save
- [ ] Move "clear compass" to admin-only feature in profile dropdown
- [ ] Replace category titles with question/prompt on issue cards and compare page
- [ ] Clickable issue cards on library page — popup showing question, stances, user's selection, editable
- [ ] Fix compass sizing — always fit on page without scrolling (except very small screens)
- [ ] Fix compass title cutoff — long titles pushing chart left, getting clipped
- [ ] Remove dashed/solid line visual distinction for inverted spokes (keep inversion logic)
- [ ] Update compass help box to remove dashed/solid line references
- [ ] Add federal/state/local level indicators to issues
- [ ] Random stance order inversion — per user, permanent per issue, spectrum preserved
- [ ] Add candidate support to Essentials — toggle to show candidates, visual differentiation from elected
- [ ] Add building images for federal/state/local sections (Capitol, state capitols, courthouses for LA and Bloomington)
- [ ] Reorder federal level — Senate and House before executive branch
- [ ] Add position start/end dates to politician profile card
- [ ] Research and decide on project structure (monorepo vs unified app vs current)
- [ ] Research infrastructure options (AWS credits vs Netlify vs Render) — research only, no migration

### Out of Scope

- Infrastructure migration — research only this round, migrate later
- Mobile app — web-first
- Real-time chat — high complexity, not core
- New prototype features — focus on polishing existing ones
- Data import automation — manual processes acceptable for now
- Full state/local issue coverage for compass — add indicators now, content later

## Context

- **Existing codebase** with 5 backend modules (Go/Chi/GORM/PostgreSQL) and 4+ React frontends
- **BallotReady API** is the primary data source for politician data, with plans to transition to manual entry via a game-like tool
- **ev-ui** component library published to GitHub npm registry, consumed by multiple apps
- **Compass currently requires login** — biggest UX change is making it guest-first with localStorage persistence until account creation
- **Issue data model** currently has shortTitle, title, and stances — no explicit question/prompt field exists yet. This is a data model change that needs careful thought
- **2-3 person dev team** — structure decisions should support parallel work without conflicts
- **Nonprofit with AWS credits** — cost is a factor in infrastructure decisions
- **Demo-ready is the bar** — this isn't about perfection, it's about confidence when showing to stakeholders

## Constraints

- **Tech stack**: Existing Go backend + React frontends — no framework migrations
- **Data source**: BallotReady API for politician data (until manual tool is ready)
- **Hosting**: Keep current hosting for now (Netlify, Supabase, Render/AWS App Runner)
- **Budget**: Nonprofit — prefer solutions that use existing AWS credits or free tiers
- **Team**: 2-3 devs — changes should be parallelizable and not create merge conflicts

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Guest-first compass with optional login | Remove friction for new users exploring the tool | — Pending |
| Convert issue titles to questions/prompts | Users need context for what each issue is asking | — Pending |
| Per-user permanent stance randomization | Prevent positional bias without confusing returning users | — Pending |
| Project structure (monorepo/unified/current) | Team needs clear boundaries for parallel work | — Pending |
| Infrastructure direction (AWS/Netlify/Render) | Nonprofit needs cost-effective hosting | — Pending |

---
*Last updated: 2026-02-17 after initialization*
