# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Workspace Overview

This is a multi-project workspace for **Empowered Vote**, a civic engagement platform helping voters make informed decisions. The workspace contains the backend API, frontend applications, UI component library, and feature prototypes.

## Projects

### ev-accounts (Express API — Primary Backend)
Unified backend replacing the old Go EV-Backend. Serves all frontend applications with three-tier account system (Inform → Connected → Empowered).

**Tech Stack:** Node.js 20, TypeScript 5.6, Express 4, Supabase PostgreSQL, Zod validation

**Commands:**
```bash
cd ev-accounts/backend
npm run dev        # Dev server with tsx watch (port 3000)
npm run build      # Compile TypeScript to dist/
npm start          # Production server
npm test           # Vitest integration tests
npm run typecheck  # Type check only
```

**Key Services** (`backend/src/lib/`):
- `authService.ts` - Signup, login, logout, JWT revocation
- `essentialsService.ts` - Politician lookup by address (Census Geocoder + PostGIS geofence)
- `essentialsLegislativeService.ts` - Bills, votes, committees
- `compassService.ts` - Political compass topics, answers, comparisons
- `treasuryService.ts` - Municipal budget data
- `stagingService.ts` - Volunteer data entry workflow
- `meetingsService.ts` - Council meeting transcripts (CouncilScribe)
- `connectService.ts` / `empowerService.ts` - Tier promotion/demotion
- `xpService.ts` / `gemService.ts` - XP and gem systems

**Route Prefixes:** All under `/api/` — `auth`, `account`, `compass`, `essentials`, `treasury`, `staging`, `meetings`, `gems`, `xp`, `connect`, `empower`, `candidates`, `roles`, `social`, `admin`, `trivia`, `vq`, `invites`, `referral`

**Essentials Data Flow:**
1. Frontend sends address via Google Maps Places autocomplete
2. Backend geocodes via Census Geocoder, runs ST_Intersects against PostGIS geofences
3. Returns matched politicians from federal → state → local hierarchy
4. Legislative data (committees, bills, votes) fetched via lazy-load on profile view

*Data Sources:*
- **Geofences:** TIGER 2024 shapefiles + ArcGIS (LA County)
- **Federal legislative:** Congress.gov API + LegiScan API
- **State legislative:** LegiScan + Open States (IN, CA)
- **Local:** OnBoard scraping (Bloomington) + Legistar OData (LA County)
- **Photos:** Supabase Storage CDN (scraped + re-hosted)

*Key Tables:*
- `essentials.politicians` - Core politician records with bio_text, bioguide_id, slug, total_years_in_office
- `essentials.offices` - Links politician to chamber/district with title, description, seats
- `essentials.chambers` - Legislative bodies with `election_frequency`
- `essentials.districts` - Electoral districts with `district_type`
- `essentials.geofences` - PostGIS boundaries (TIGER + ArcGIS) with composite unique on (geo_id, mtfcc)
- `essentials.politician_images` - Profile photos (Supabase CDN)
- `essentials.politician_contacts` - Email, phone, fax, website per contact_type (primary, office, campaign, personal, etc.)
- `essentials.degrees` - Educational history (degree, major, school, grad_year)
- `essentials.experiences` - Work/office history (title, organization, type, start, end)
- `essentials.legislative_sessions`, `committees`, `memberships`, `leadership_positions` - Legislative structure
- `essentials.bills`, `bill_cosponsors`, `votes` - Legislative activity

*District Types:*
- `NATIONAL_EXEC`, `NATIONAL_UPPER`, `NATIONAL_LOWER` - Federal level
- `STATE_EXEC`, `STATE_UPPER`, `STATE_LOWER` - State level
- `LOCAL_EXEC`, `LOCAL`, `COUNTY`, `SCHOOL`, `JUDICIAL` - Local level

**Database Schemas:** `public`, `inform`, `connect`, `empower`, `essentials`, `treasury`, `staging`

**Required Env Vars:** `NODE_ENV`, `PORT`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `DATABASE_URL`

---

### EV-Backend (Go API — Legacy, being retired)
Previous REST API. Routes have been migrated to ev-accounts. Keep for reference but do not add new features here.

---

### CompassV2 (React App)
Interactive political compass quiz with radar chart visualization.

**Tech Stack:** React 19, Vite 6, Tailwind CSS 4, Framer Motion, @dnd-kit

**Commands:**
```bash
cd CompassV2
npm run dev      # Dev server
npm run build    # Production build
npm run deploy   # Deploy to GitHub Pages
```

**Key Directories:**
- `src/pages/` - Route components (Quiz, Compass, Library, Login)
- `src/components/` - Reusable components including RadarChart
- `src/components/admin/` - Admin dashboard for managing topics/politicians

**State:** CompassContext manages topics, answers, and selected quiz items with localStorage persistence.

**API:** Connects to `https://api.empowered.vote`

---

### essentials (React App)
Politician discovery by ZIP code with profile pages.

**Tech Stack:** React 19, Vite 7, Tailwind CSS 4, React Spring

**Commands:**
```bash
cd essentials
npm run dev      # Dev server
npm run build    # Production build
```

**Key Files:**
- `src/pages/Results.jsx` - Address search with progressive loading, politician cards
- `src/pages/Profile.jsx` - Politician profile (uses PoliticianProfile from ev-ui)
- `src/lib/classify.js` - Categorizes politicians by tier (Federal/State/Local)
- `src/utils/sorters.js` - Sorting options per category (role, name, party, district)

**Politician Classification Tiers:**

| Tier | District Types | Categories |
|------|----------------|------------|
| Federal | `NATIONAL_EXEC`, `NATIONAL_UPPER`, `NATIONAL_LOWER` | President/VP, Cabinet, U.S. Senate, U.S. House, Agencies |
| State | `STATE_EXEC`, `STATE_UPPER`, `STATE_LOWER`, `JUDICIAL` (appellate) | Governor, Constitutional Officers, State Senate/House, Judiciary, Boards |
| Local | `LOCAL_EXEC`, `LOCAL`, `COUNTY`, `SCHOOL`, `JUDICIAL` | Mayor, Council, County Officials, School Board, Local Courts |

**Environment:** `VITE_API_URL` for backend endpoint

---

### ev-ui (Component Library)
Shared React component library published to public npm.

**Package:** `@empoweredvote/ev-ui`

**Tech Stack:** React, @react-spring/web, tsup

**Commands:**
```bash
cd ev-ui
npm run build    # Builds ESM + CJS bundles to dist/
```

**Publishing (automated auto-bump pipeline):**
```bash
cd ev-ui
npm version patch    # or minor / major
git push origin main --follow-tags
```

Tag push triggers `.github/workflows/publish.yml`:
1. Publishes to npm via **OIDC trusted publishing** (no `NPM_TOKEN` needed — uses GitHub's OIDC identity, automatic provenance attestations)
2. Fires `repository_dispatch` to all 4 consumer repos (`CompassV2`, `essentials`, `read-rank`, `civic-spaces`) via `DISPATCH_TOKEN` (fine-grained GitHub PAT)
3. Each consumer's `.github/workflows/ev-ui-bump.yml` receives the dispatch, opens a PR, and auto-merges if `bump_type` is patch or minor (build-check.yml gates the merge)
4. Render auto-deploys each consumer on merge to main

See `ev-ui/README-AUTOBUMP.md` for full pipeline docs, secret setup, and how to add new consumers.

**Main Component:** `RadarChartCore` - Interactive radar/spider chart with:
- Animated transitions via react-spring
- Dual dataset comparison (pink/blue overlays)
- Clickable spokes for inversion toggle
- Dynamic label wrapping

---

### EV-prototypes (Monorepo — Legacy)
Most projects extracted to standalone repos. Only `read-rank/` and `data-entry/` remain.

**Commands:**
```bash
cd EV-prototypes
npm run build:all         # Build all projects
npm run build:read-rank   # Build specific project
npm run build:treasury    # Build specific project
```

**Sub-projects:**

| Project | Purpose | Stack |
|---------|---------|-------|
| `read-rank/` | Candidate quote evaluation with swipe gestures | React 19, Zustand, @dnd-kit, Framer Motion |
| `treasury-tracker/` | Budget visualization with D3 charts | React 19, D3.js, Recharts, EV-Backend API |
| `empowered-badges/` | Learning modules on political issues | React 19, Framer Motion |
| `data-entry/` | Volunteer data entry with review workflow | React 19, EV-Backend API (`/staging/*`) |

**Deployment:** Render (auto-deploys on merge to main)

---

### read-rank (Standalone App)
Read & Rank candidate quote evaluation — deployed at `readrank.empowered.vote`.

**Commands:**
```bash
cd read-rank
npm run dev      # Dev server on localhost:5173
npm run build
```

---

### Standalone Apps (Render)

| Repo | URL | Purpose |
|------|-----|---------|
| `CompassV2/` | compass.empowered.vote | Political compass quiz |
| `essentials/` | essentials.empowered.vote | Politician discovery by address |
| `read-rank/` | readrank.empowered.vote | Candidate quote evaluation |
| `treasury-tracker/` | treasurytracker.empowered.vote | Municipal budget visualization |
| `empowered-badges/` | badges.empowered.vote | Learning modules on political issues |
| `fallacy-finders/` | (TBD) | Logical fallacy identification game |

---

## Infrastructure

- **Domain:** GoDaddy (empowered.vote), managed via AWS Route 53
- **Frontends:** Render (all apps above auto-deploy on merge to main)
- **Backend:** Render (ev-accounts Express server at accounts.empowered.vote)
- **Database:** Supabase PostgreSQL with PostGIS
  - **Production:** "E.V Backend" (project ID: `kxsdzaojfaibhuzmclfq`)
  - **Dev/Isolated:** "EV-Backend-Dev" (project ID: `mzuppdqbibqjedmesbmp`)
- **CDN:** Supabase Storage (politician headshots, building photos)
- **DNS/Redirects:** AWS Route 53 (subdomain routing, redirects)
- **npm Registry:** Public npm (@empoweredvote/ev-ui) — no auth needed to install

## Common Patterns

### Duplicated Display Logic
- `ev-ui/src/PoliticianProfile.jsx` and `essentials/src/pages/Results.jsx` both have `buildTitleAndSubtitle()` — changes to district/title display must be applied in both places

### Contact Data (`essentials.politician_contacts`)
- `contact_type` values: `primary` (official .gov), `office`, `campaign`, `personal`, `central`, `district`, `city_website`, `office_website`, `other`
- Contact types display capitalized on frontend via `capitalize()` in PoliticianProfile.jsx

### Design System
- **Colors:** `ev-coral` (#ff5740), `ev-muted-blue` (#00657c), `ev-light-blue` (#59b0c4), `ev-yellow` (#fed12e)
- **Font:** Manrope (Google Fonts)
- **Styling:** Tailwind CSS 4 across all React projects

### Authentication
- Supabase Auth with JWT Bearer tokens
- `requireAuth` middleware verifies JWT (HS256 or ES256/RS256) and checks account standing
- `optionalAuth` for routes with guest mode (e.g., public compass topics)
- Three-tier access: Inform (base) → Connected (verified) → Empowered (public identity)

### State Management
- **CompassV2:** React Context (CompassContext)
- **read-rank:** Zustand with localStorage persistence
- **essentials:** Local component state

### API Endpoints
All frontends connect to `https://accounts.empowered.vote` (ev-accounts):
- `/api/auth/*` - Authentication (signup, login, logout, onboarding)
- `/api/compass/*` - Topics, answers, stances, politician comparisons
- `/api/essentials/*` - Politician data by address (geofence matching)
- `/api/treasury/*` - Municipal budget data (cities, budgets, categories)
- `/api/staging/*` - Data entry workflow (stances, politicians, review/approval)
- `/api/connect/*` - Connected tier enrollment & verification
- `/api/empower/*` - Empowered tier promotion
- `/api/gems/*`, `/api/xp/*` - Gamification (gems, experience points)
- `/api/meetings/*` - Council meeting transcripts

---

## Development Environment Setup

**Running the backend locally:**

```bash
cd ev-accounts/backend
cp .env.example .env   # Fill in Supabase credentials
npm install
npm run dev            # Runs on localhost:3000
```

Get Supabase credentials from dashboard: **Project Settings > API** (URL, anon key, service role key) and **Connection > Connection string (URI)** for `DATABASE_URL`.

**Dev Supabase project** (`EV-Backend-Dev`) is available for isolated testing — see Infrastructure section for project IDs.

---

## Adding New Backend Features

When building new ev-accounts features, follow these established patterns:

1. **Create service** at `backend/src/lib/<feature>Service.ts` — business logic, DB queries
2. **Create route** at `backend/src/routes/<feature>.ts` — Express router with Zod validation
3. **Wire into index.ts** — `app.use('/api/<feature>', featureRouter)`
4. **Add migration** in `backend/migrations/` — SQL for new tables/columns
5. **Add middleware** as needed — use `requireAuth`, `optionalAuth`, or tier guards
6. **Secrets** — Add to `.env` locally; Render environment variables for production

---

## Current Workstreams

### Completed
Treasury backend, data entry tool, PostGIS geofence migration, legislative data model, Go → Express migration — all done. See git history for details.

### Known Issues
- None currently tracked

### Pending

**Empowered Badges & Fallacy Finders — Standalone Repo Setup**
- Extracted to standalone repos; need Render deployment configured

**Data Import**
- Import existing Bloomington budget data into treasury schema
- Import existing politician stances into staging for review workflow testing

**Performance Monitoring**
- Address search uses PostGIS ST_Intersects — responses should be fast (DB-only, no external API)