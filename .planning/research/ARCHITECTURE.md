# Architecture Research

**Research Date:** 2026-02-17
**Research Type:** Project Research — Architecture dimension
**Question:** How do multi-app civic engagement platforms structure their codebase, handle guest-to-user auth transitions, and manage image assets?

---

## Scope

This document covers six architectural decisions relevant to the next milestone:

1. Guest-first auth with localStorage → server sync on account creation
2. Data model evolution: adding question/prompt to compass topics
3. Per-user stance randomization (seed-based or stored)
4. Candidate data alongside elected officials in Essentials
5. Image storage (Supabase Storage vs S3 vs CDN)
6. Multi-app consolidation (monorepo vs unified SPA vs micro-frontends)

---

## 1. Guest-First Auth with localStorage → Server Sync

### Pattern

Guest-first auth means the app works fully without a login, persisting state locally, then migrates that state to the server when the user creates an account. This is the pattern used by Google Docs (anonymous → signed-in merge), Notion, and most quiz/survey tools.

### How It Works in This Codebase

**Current state:** CompassV2 requires login. Topics load from the server. Answers are stored server-side via `POST /compass/answers`. Selected topics and spoke inversions persist to localStorage.

**Target state:** Guest can take the quiz, get results, compare politicians — all without login. When they optionally create an account, their local state syncs to the server.

### Data to Persist Locally (Guest)

| Data | localStorage Key | Server Table on Sync |
|------|-----------------|----------------------|
| Quiz answers | `ev_guest_answers` | `compass.answers` |
| Selected compass topics | existing `selectedTopics` key | `compass.user_compass` |
| Spoke inversions | existing `inverted` key | `compass.user_compass` |
| Randomization seed | `ev_guest_seed` | `app_auth.users` (new column) |

### Sync Strategy

On account creation (`POST /auth/register`):
1. Frontend reads all `ev_guest_*` keys from localStorage
2. Includes them as `guest_state` in the register request body
3. Backend handler unpacks and writes to appropriate tables in a single transaction
4. Frontend clears `ev_guest_*` keys

On login (existing user returning):
- If localStorage has guest data AND the user already has server answers: merge strategy needed
- Simplest approach: **server wins** — local data discarded if server already has answers for this user
- If server has no answers: treat like new registration (sync local → server)

### Backend Changes Required

- `/auth/register` handler: accept optional `guest_state` body field
- Write guest answers inside the registration transaction
- `/auth/login` handler: optionally accept and sync guest state (only if server has no existing answers)
- No schema changes needed — existing `compass.answers`, `compass.user_compass` tables handle this

### Frontend Changes Required

- `CompassContext`: always persist answers to localStorage, regardless of auth state
- Remove auth gate on quiz load (allow unauthenticated)
- Register/login flow: pass localStorage guest state in request body
- After successful auth: clear guest localStorage keys

### Component Boundaries

```
[CompassContext] → reads/writes localStorage (always)
                → writes server (if logged in)

[RegisterForm]  → reads localStorage guest state
                → includes in POST /auth/register
                → clears localStorage on success

[LoginForm]     → reads localStorage guest state
                → includes in POST /auth/login (optional sync)
                → clears localStorage on success

[ProtectedRoute] → remove from Quiz, Compass, Library pages
                 → keep on Profile, Admin pages
```

### Build Order

1. Remove `ProtectedRoute` from quiz-related routes
2. Update `CompassContext` to always write to localStorage (guest mode)
3. Expose guest state via context or hook
4. Update register/login forms to pass guest state
5. Update backend `/auth/register` and `/auth/login` to handle `guest_state`
6. Test merge edge case (logged-in user with existing answers)

---

## 2. Data Model Evolution: Question/Prompt on Compass Topics

### Current Schema

The `compass.topics` table has: `id`, `title`, `short_title`, `stances[]`, and related fields. There is no `question` or `prompt` field.

### What the Feature Needs

Issue cards and the compare page should display a question (e.g., "How should the federal government approach healthcare?") instead of or alongside the category title (e.g., "Healthcare"). This is a content-level change, not a structural redesign.

### Schema Change

Add a `question` column to `compass.topics`:

```sql
ALTER TABLE compass.topics ADD COLUMN question TEXT;
```

This is backward-compatible — existing topics have `question = NULL`, which the frontend handles by falling back to `title`. GORM AutoMigrate handles this without downtime.

### Migration Strategy

- **Phase 1:** Add column, deploy backend (AutoMigrate). All questions are NULL, UI falls back to title. No regression.
- **Phase 2:** Admin UI (or seed data) populates `question` values for existing topics. This is content work, not code work.
- **Phase 3:** Update frontend to render `question` when present, `title` as fallback.

### API Impact

Add `question` to the topic response DTO:

```go
type TopicOut struct {
    ID         uint   `json:"id"`
    Title      string `json:"title"`
    ShortTitle string `json:"short_title,omitempty"`
    Question   string `json:"question,omitempty"`  // NEW
    // ...stances
}
```

`omitempty` ensures backward compatibility — consumers that don't know about `question` are unaffected.

### Frontend Impact

In `CompassContext`, topics already flow through to components. Update issue card and compare page components to use `topic.question || topic.title`. No context changes needed.

### Build Order

1. Add `Question string` field to `compass/models.go` Topic struct
2. Deploy backend (AutoMigrate adds column)
3. Add `question` to TopicOut DTO and serialization
4. Update frontend issue card and compare page: `topic.question || topic.title`
5. Admin: add question field to topic editor
6. Content: populate question values for existing topics

---

## 3. Per-User Stance Randomization

### The Problem

When stance options are always listed in the same order (e.g., "Strongly Agree" first), users show positional bias — they're more likely to pick the first option. Randomizing order removes this, but the order must be **permanent per user** so returning users see the same presentation.

### Two Implementation Approaches

#### Approach A: Client-Side Seed (Recommended)

Generate a random seed at first visit, store it in localStorage (guest) or user profile (authenticated). Use the seed with a deterministic shuffle (e.g., mulberry32 PRNG or seeded Fisher-Yates) to derive stance order per topic.

**Pros:**
- No backend API call for randomization
- Works in guest mode
- Seed syncs to server on account creation (part of guest_state sync)
- Deterministic: same seed = same order on any device after login

**Cons:**
- JS-only: server-side rendering would need seed passed down (not relevant here)

**Implementation:**

```javascript
// On first load (CompassContext)
const seed = localStorage.getItem('ev_stance_seed')
  ?? generateSeed()  // Math.random()-based, stored immediately
localStorage.setItem('ev_stance_seed', seed)

// Shuffle stances for a topic (deterministic)
function shuffleStances(stances, topicId, seed) {
  const combined = hashCombine(seed, topicId)  // topic-specific variation
  return seededShuffle(stances, combined)
}
```

**Server sync:** Include `stance_seed` in `guest_state` payload on registration. Store in a new `users.stance_seed` column (or `app_auth.users`).

#### Approach B: Server-Generated Seed per User

Backend generates and stores a random seed per user. Frontend fetches it from `/auth/me` or `/compass/preferences`.

**Pros:** Seed survives browser clears, works on new devices immediately after login.
**Cons:** Requires backend change, requires auth (breaks guest flow).

### Recommendation

**Use Approach A (client-side seed)** because:
- Works without auth (guest mode)
- Syncs to server as part of the existing guest_state sync pattern
- Simpler backend: just store and return the seed value

### Schema Change

```sql
ALTER TABLE app_auth.users ADD COLUMN stance_seed TEXT;
```

### Build Order

1. Add `StanceSeed` to user model and `/auth/me` response
2. Add seed generation + localStorage persistence to CompassContext
3. Add deterministic shuffle function to `util/`
4. Apply shuffle in quiz question rendering
5. Include seed in guest_state sync on register/login

---

## 4. Candidate Data Alongside Elected Officials in Essentials

### Current State

The Essentials app shows `is_elected = true` officials. BallotReady's candidacy data is already fetched (via `FetchCandidacy`) and stored in `essentials.election_records`. The data is there; it's a display decision.

### Feature Request

Toggle between elected officials and candidates. Candidates should be visually differentiated.

### Data Already Available

From the existing BallotReady integration (`essentials.election_records`, `essentials.endorsements`, `essentials.politician_stances`):
- Candidate name, party, office sought
- Election date, is_incumbent
- Endorsements, stances

### What's Missing

A query path to return candidates by ZIP code. The current `GET /essentials/politicians/{zip}` only returns current officeholders. Need a parallel endpoint or query parameter.

### Recommended Approach

**Add `?include_candidates=true` query param** to the existing ZIP endpoint, or a new endpoint `GET /essentials/candidates/{zip}`.

The candidacy data is linked to politicians via the existing `essentials.politicians` table (each candidate is a politician with election records). The query needs to:
1. Find all elections with a district overlapping the ZIP
2. Return associated politicians with candidacy context (is_incumbent, election_date, party_on_ticket)

### Component Boundaries

```
Backend:
  GET /essentials/candidates/{zip}
    → query essentials.election_records JOIN essentials.politicians
    → filter by upcoming elections (election_date > now())
    → return CandidateOut DTO (extends OfficialOut with election context)

Frontend (essentials/Dashboard.jsx):
  → Toggle: "Officials" | "Candidates"
  → fetchCandidates(zip) separate from fetchPoliticians(zip)
  → Visual differentiation: candidate badge, "Running for [Office]" label
  → Sorted by office, then by election date
```

### Build Order

1. Add `GET /essentials/candidates/{zip}` backend handler
2. Query election_records for upcoming elections with district-to-ZIP mapping
3. Return CandidateOut DTO (reuse OfficialOut structure + add election fields)
4. Add `fetchCandidates(zip)` to `essentials/src/lib/api.jsx`
5. Add toggle UI to Dashboard
6. Add visual differentiation to PoliticianCard (badge/label for candidates)

---

## 5. Image Storage

### Current State

Politician profile images are URLs sourced directly from BallotReady (stored as strings in `essentials.politician_images`). No local image storage exists.

### The Question

Should images be stored locally (Supabase Storage, S3) or served directly from BallotReady CDN URLs?

### Option Comparison

| Option | Cost | Complexity | Control | Risk |
|--------|------|------------|---------|------|
| BallotReady CDN (current) | Free | None | Low | URL expiry, BallotReady outage |
| Supabase Storage | Free tier 1GB | Low | High | Supabase dependency |
| AWS S3 | ~$0.02/GB | Medium | High | Cost, setup |
| Cloudflare R2 | Free 10GB | Medium | High | Another service |
| Netlify Large Media | Free tier | Low | Medium | Git LFS complexity |

### Recommendation: Keep BallotReady CDN for Now

**Rationale:**
- BallotReady images are served from a CDN already. No egress cost.
- Platform has nonprofit cost constraints — adding storage infrastructure is waste unless URLs expire or break.
- If BallotReady image URLs prove unstable (404s, expiry), migrate to Supabase Storage.
- Supabase Storage is the easiest migration path given the existing Supabase PostgreSQL dependency.

**If migration becomes necessary:**

Supabase Storage approach:
1. Create bucket `politician-images` (private or public)
2. Background job: for each politician image URL, download and upload to Supabase Storage
3. Store Supabase Storage URL in `essentials.politician_images` alongside original URL
4. Backend serves Supabase URL, with fallback to BallotReady URL if Storage URL is null

**For building images (Capitol, state capitols, courthouses):**
These are static assets. Store directly in the frontend project's `public/` directory or `src/assets/`. No cloud storage needed for a handful of building photos.

### Component Boundaries (If Storage Added)

```
[background job / admin endpoint]
  → download image from BallotReady URL
  → upload to Supabase Storage bucket
  → update essentials.politician_images.supabase_url

[Backend GET /essentials/politicians/{zip}]
  → prefer supabase_url over ballotready_url in response
  → omit if both null

[Frontend PoliticianCard]
  → no change: renders whatever URL the API returns
```

---

## 6. Multi-App Consolidation

### Current Structure

Four separate React apps, each deployed independently to Netlify:
- `CompassV2/` — political compass quiz
- `essentials/` — politician discovery
- `EV-prototypes/` — treasury tracker, read-rank, badges, data-entry
- `ev-ui/` — shared component library (npm package)

### Three Patterns to Consider

#### Pattern A: Keep Current (Separate Repos / Apps)

**What it is:** Each app is an independent Vite React project. `ev-ui` is published to GitHub npm registry and consumed by other apps as a versioned package.

**Pros:**
- Existing structure — zero migration cost
- Independent deployment: changes to one app don't risk others
- Clear separation: `ev-ui` version bumps are explicit

**Cons:**
- `ev-ui` publish cycle is manual and slow (bump version, publish, update all consumers)
- No code sharing beyond what's in `ev-ui` (no shared hooks, utils, API clients)
- Four separate `node_modules` trees, four separate Netlify deploys

**Best for:** Teams where app-level independence matters more than development speed. Works fine at 2-3 person scale.

#### Pattern B: Monorepo (Recommended for This Team)

**What it is:** All apps live in one repo (or one workspace). Uses npm workspaces or pnpm workspaces to share packages without publishing.

```
/
├── packages/
│   ├── ev-ui/          # shared component library
│   ├── api-client/     # shared fetch functions + hooks
│   └── utils/          # shared helper functions
├── apps/
│   ├── compass/        # CompassV2 → compass
│   ├── essentials/     # essentials
│   └── prototypes/     # EV-prototypes
└── package.json        # workspace root
```

**Pros:**
- `ev-ui` changes are immediately available to all apps (no publish cycle)
- Shared `api-client` package for fetch wrappers — eliminates duplication of API logic
- Single `node_modules` (hoisted by workspace manager)
- One CI pipeline covers everything
- Atomic commits across apps (fix `ev-ui` and update consumers in one PR)

**Cons:**
- Migration cost (restructure directories, update imports, configure workspaces)
- Netlify needs per-app build config (base directory + build command per site)
- Slightly more complex Vite config (workspace-relative paths)

**Implementation using npm workspaces:**

```json
// root package.json
{
  "workspaces": ["packages/*", "apps/*"],
  "scripts": {
    "dev:compass": "npm run dev -w apps/compass",
    "dev:essentials": "npm run dev -w apps/essentials"
  }
}
```

Internal package consumption replaces npm registry:
```json
// apps/compass/package.json
{
  "dependencies": {
    "@ev/ev-ui": "*",      // resolved from packages/ev-ui
    "@ev/api-client": "*"  // resolved from packages/api-client
  }
}
```

**Netlify per-app config:** Each app gets its own Netlify site with `Base directory: apps/compass` and `Build command: npm run build`.

#### Pattern C: Unified SPA

**What it is:** Merge all apps into one React app with React Router. One Netlify deploy, one bundle.

**Pros:**
- Single deployment, single dev server
- Shared state without cross-app coordination

**Cons:**
- Large bundle: users downloading treasury tracker JS when using compass
- Merge complexity: CSS, routing conflicts between existing apps
- All-or-nothing deployment: compass bug → all apps down
- Loses natural boundary between civic apps (compass is a tool; essentials is a directory)

**Not recommended** for this team size and app diversity. The apps serve different user journeys and have different update cadences.

### Recommendation: Monorepo (Pattern B)

**Why for this team:**
- The `ev-ui` publish cycle is the biggest day-to-day friction. A monorepo eliminates it.
- Shared API client would prevent drift between how `essentials` and `CompassV2` call the same backend.
- 2-3 person team benefits from atomic cross-app changes without coordination overhead.
- Netlify supports monorepo deployments natively with `Base directory` config.

**Migration path (low-risk, incremental):**

1. Create `package.json` at repo root with `"workspaces": ["packages/*", "apps/*"]`
2. Move `ev-ui/` → `packages/ev-ui/` — update internal name to `@ev/ev-ui`
3. Move `CompassV2/` → `apps/compass/` — update import paths
4. Move `essentials/` → `apps/essentials/` — update import paths
5. Update Netlify sites: set `Base directory` per app
6. Stop publishing `ev-ui` to GitHub npm registry (or keep as fallback)
7. Optionally extract `packages/api-client/` from shared fetch patterns

This is a 1-2 day migration with no functional changes. Each step is independently safe to revert.

---

## Component Boundaries Summary

### Current Boundaries

```
EV-Backend (Go)
  ├── /auth        → session CRUD
  ├── /compass     → topics, answers, stances
  ├── /essentials  → politicians, offices, ZIP cache
  ├── /treasury    → budgets, cities, line items
  └── /staging     → volunteer data entry

CompassV2 (React)   → /compass endpoints
essentials (React)  → /essentials endpoints
EV-prototypes       → /treasury, /staging endpoints
ev-ui (npm)         → RadarChartCore, PoliticianCard, PoliticianProfile
```

### Target Boundaries (After Milestone)

```
EV-Backend (Go) — same module structure, new fields/endpoints
  ├── /auth          → + guest_state sync on register/login
  │                  → + stance_seed field on users
  ├── /compass       → + question field on topics
  └── /essentials    → + /candidates/{zip} endpoint

apps/compass (React)  → guest-first, no ProtectedRoute on quiz
                       → localStorage-backed state always on
                       → guest_state sync on register/login

apps/essentials (React) → officials/candidates toggle
                         → visual differentiation for candidates

packages/ev-ui          → shared components, updated PoliticianCard

packages/api-client     → shared fetch wrappers (optional extraction)
```

---

## Data Flow (New Features)

### Guest Auth Flow

```
User opens CompassV2 (no login)
  → CompassContext generates stance_seed, stores in localStorage
  → User answers quiz → answers stored ONLY in localStorage
  → User views results → computed locally from localStorage answers
  → User optionally registers
      → RegisterForm reads localStorage: answers, selectedTopics, inverted, stance_seed
      → POST /auth/register { username, password, guest_state: { answers, ... } }
      → Backend: create user, write answers to compass.answers, write seed to users.stance_seed
      → Frontend: clear ev_guest_* localStorage keys
  → On subsequent logins: /auth/me returns stance_seed
  → CompassContext uses server seed instead of localStorage seed
```

### Stance Randomization Flow

```
Topic loads into CompassContext
  → seed = localStorage.getItem('ev_stance_seed') || user.stance_seed
  → For each topic: shuffledStances = seededShuffle(topic.stances, seed, topic.id)
  → Rendered order is stable across page refreshes (same seed = same shuffle)
  → Answers stored by stance ID, not position — order doesn't affect data integrity
```

### Candidate Discovery Flow

```
User views essentials Dashboard
  → Toggle to "Candidates" tab
  → fetchCandidates(zip) → GET /essentials/candidates/{zip}
  → Backend: query election_records JOIN politicians WHERE election_date > now()
               AND district covers zip
  → Return CandidateOut[] with office_sought, election_date, is_incumbent
  → Frontend: render CandidateCard with "Running for [Office]" badge
  → Click → profile page (same /politician/:id route, additional election context)
```

---

## Build Order (Cross-Feature Dependencies)

The features have these dependencies:

```
[Monorepo migration]  → independent, do first to unblock parallel work
        ↓
[Guest-first auth]    → depends on: nothing (pure frontend + small backend change)
        ↓
[Stance seed]         → depends on: guest-first auth (seed is part of guest_state)
        ↓
[Question/prompt]     → independent of auth, depends on: schema migration only
        ↓
[Candidates]          → independent, depends on: existing candidacy data (already fetched)
        ↓
[Image storage]       → deferred unless BallotReady URLs break
```

### Recommended Phase Sequence

| Phase | Work | Parallelizable? |
|-------|------|-----------------|
| 1 | Monorepo migration | Solo — everyone benefits immediately |
| 2a | Guest-first auth (frontend) | Dev A |
| 2b | Question/prompt field (backend + frontend) | Dev B |
| 3a | Stance seed (depends on guest auth) | Dev A, after 2a |
| 3b | Candidates endpoint + toggle (backend + frontend) | Dev B, after 2b |
| 4 | Image storage | Deferred — only if needed |

---

## Decisions This Research Supports

| Decision | Recommendation | Rationale |
|----------|---------------|-----------|
| Guest-first auth sync pattern | localStorage → guest_state in register/login body | No new tables, syncs atomically, works in guest mode |
| Question/prompt field | Add `question TEXT` column, omitempty in API | Backward-compatible, content-fillable independently |
| Stance randomization | Client-side seed, synced to server on registration | Works guest-first, deterministic across devices after login |
| Candidate display | New `/candidates/{zip}` endpoint, toggle in Dashboard | Data already exists, clean separation from officials view |
| Image storage | Keep BallotReady CDN; Supabase Storage if URLs break | Zero cost, zero complexity until proven necessary |
| Project structure | Monorepo with npm workspaces | Eliminates ev-ui publish friction, enables shared api-client |

---

*Research complete: 2026-02-17*
