# Stack Research — Empowered Vote Feature Improvements

**Research Date:** 2026-02-17
**Milestone:** Quality & Consolidation — brownfield improvements to existing platform

---

## Scope

This document covers only *new or changed* stack decisions for the upcoming milestone. Existing stack (Go 1.24.3 + Chi + GORM, React 19 + Vite + Tailwind CSS 4, ev-ui) is retained as-is. Research focuses on six improvement areas:

1. Guest-first auth flow with localStorage persistence
2. Data model changes (question/prompt field on compass topics)
3. Random stance ordering with per-user permanence
4. Candidate data support in Essentials
5. Image storage and delivery (building photos)
6. Project structure consolidation

---

## 1. Guest-First Auth Flow

### Problem

Every Compass route is wrapped in `ProtectedRoute`, which calls `/auth/me` and redirects to `/401` if no session exists. This blocks new users from experiencing the quiz. The goal is to allow full quiz access without login while optionally persisting answers to an account.

### Current State

- `CompassContext.jsx` already stores `selectedTopics` and `invertedSpokes` in `localStorage`
- `compass.answers` table requires a `user_id` string (not nullable, no guest concept)
- Backend `/compass/answers` route is in the session-protected group
- `ProtectedRoute` checks `/auth/me` synchronously on every protected page mount

### Recommendation: localStorage-first with Optional Server Sync

**Confidence: High**

No new libraries are needed. The pattern is:

1. Remove `ProtectedRoute` from quiz, library, build, and results routes
2. Treat all compass state (answers, selected topics, inverted spokes) as localStorage-first
3. On login/register, offer to import localStorage answers to the server
4. Server endpoints remain gated — they're used only if a session exists

**Why not a new auth library (Auth0, Clerk, etc.):** The existing session-based auth is working and appropriate for a small-team nonprofit. Introducing a third-party auth service adds cost, complexity, and a dependency that would require migrating all existing sessions. Not justified for this use case.

**Why not anonymous/guest sessions on the backend:** Creating server-side guest sessions (with UUID tokens in localStorage) adds backend complexity — session cleanup, TTL management, and migration logic. Pure localStorage avoids all of that. The quiz data is low-stakes and doesn't need server persistence for guests.

### Implementation Pattern

```javascript
// CompassContext.jsx — no API calls if no session
const [isAuthenticated, setIsAuthenticated] = useState(false);

useEffect(() => {
  fetch(`${API_URL}/auth/me`, { credentials: "include" })
    .then(res => { if (res.ok) setIsAuthenticated(true); })
    .catch(() => {}); // silent — not required
}, []);

// Sync to server only when authenticated
useEffect(() => {
  if (!isAuthenticated || !serverLoaded.current) return;
  // existing server sync logic
}, [selectedTopics, isAuthenticated]);
```

### Backend Changes Required

The `/compass/answers` GET/POST routes need a conditional path:
- Authenticated: read/write to `compass.answers` table (existing behavior)
- Unauthenticated: 401 is fine — frontend reads from localStorage only

No new Go packages needed. The existing `SessionMiddleware` already handles 401 gracefully.

### What NOT to Do

- Do NOT add `user_id` nullable column to `compass.answers` for guest tracking — unnecessary complexity
- Do NOT use `sessionStorage` — doesn't survive tab close, breaking the UX goal
- Do NOT add Zustand to CompassV2 — the existing Context pattern is sufficient and switching state libraries mid-feature is wasteful

---

## 2. Data Model Evolution — Question/Prompt on Topics

### Problem

The `compass.topics` table has `title`, `short_title`, and `start_phrase`. There is no dedicated `question` or `prompt` field. Issue cards need to display a contextual question (e.g., "How should the US handle border security?") rather than a category title.

### Current Model

```go
type Topic struct {
    ID          uuid.UUID
    TopicKey    string    // unique identifier
    Title       string    // e.g., "Immigration"
    ShortTitle  string    // e.g., "Immigration" (used on radar chart)
    StartPhrase string    // legacy field, partial sentence
    IsActive    bool
    Stances     []Stance
    Categories  []Category
}
```

### Recommendation: Add `question` Column to `compass.topics`

**Confidence: High**

Add a single `question` text column. GORM AutoMigrate handles the column addition safely (additive only).

```go
type Topic struct {
    // ... existing fields ...
    Question string `json:"question"` // e.g., "How should the US approach immigration reform?"
}
```

**Why a new column vs. repurposing existing fields:**
- `title` is used on the radar chart axis labels — cannot be replaced with a long question
- `start_phrase` is legacy and inconsistently populated — don't overload it
- A separate `question` column makes intent explicit and allows independent editing in the admin UI

**Migration approach:** AutoMigrate adds the column with empty string default. Populate via admin UI or direct SQL. No data loss risk.

**Admin UI:** The existing `TopicEditor.jsx` / `CreateTopic.jsx` components need a new `question` textarea input. The existing `PATCH /compass/topics/update` handler needs to include `question` in the update payload. No new infrastructure needed.

**What NOT to Do:**
- Do NOT rename `title` to `question` — breaks radar chart labels and requires a coordinated frontend+backend change
- Do NOT use a separate `compass.topic_questions` join table — one topic, one question, no need for normalization

---

## 3. Random Stance Order with Per-User Permanence

### Problem

Stances displayed in a fixed order create positional bias (users tend to pick the first option). The fix is to randomize stance order per user, permanently — so a returning user sees the same randomized order they always saw (preventing confusion from changed positions).

### Current State

- `compass.stances` has a `value` integer field (used for scoring, e.g., -2 to 2 or 1 to 5)
- Stance order is currently determined by `value` sort in the frontend
- No per-user ordering is stored anywhere

### Recommendation: Client-Side Shuffle with localStorage Persistence

**Confidence: High**

No backend changes required for the stance randomization itself.

**Approach:**
1. Generate a random but deterministic shuffle order per topic per user, seeded by topic ID + a stable user salt
2. Store the shuffle map in `localStorage` as `stanceOrder: { [topicId]: [stanceId, stanceId, ...] }`
3. On first visit to a topic, generate and store the order. On return visits, read from storage.

```javascript
// In CompassContext or a hook
function getStanceOrder(topicId, stances) {
  const stored = safeParse(localStorage.getItem("stanceOrder"), {});
  if (stored[topicId]) {
    // Return stances sorted by stored order
    return stances.slice().sort((a, b) =>
      stored[topicId].indexOf(a.id) - stored[topicId].indexOf(b.id)
    );
  }
  // First time: shuffle and persist
  const shuffled = [...stances].sort(() => Math.random() - 0.5);
  stored[topicId] = shuffled.map(s => s.id);
  localStorage.setItem("stanceOrder", JSON.stringify(stored));
  return shuffled;
}
```

**Spectrum preservation note:** The requirement says "spectrum preserved" — this likely means the visual left-to-right ordering on the spectrum (negative to positive stance values) should be maintained, but the specific mapping of stance values to positions should be shuffled. Clarify with the team whether "spectrum preserved" means:
- (a) Just shuffle the display order randomly (any order), or
- (b) Invert the spectrum for some users (some users see negative-to-positive, others see positive-to-negative)

Option (b) is simpler and more meaningful — randomly flip the spectrum direction per topic per user. Store a boolean `flipped: { [topicId]: true|false }` in localStorage.

**If server sync is desired (for returning users on new devices):** Add a nullable `stance_order_salt` or `flipped_topics` column to `compass.user_compasses`. But for the current milestone, localStorage-only is the right call — same pattern as `invertedSpokes`.

**What NOT to Do:**
- Do NOT store stance order in the database for the initial implementation — adds complexity for minimal benefit
- Do NOT use crypto.getRandomValues for seeding — unnecessary; Math.random() is fine for UI ordering

---

## 4. Candidate Data Support in Essentials

### Problem

Essentials currently shows only elected officials (incumbent officeholders). BallotReady also provides candidacy data (people running for office who are not yet elected). The requirement is to show candidates in the UI with visual differentiation from elected officials.

### Current State

- BallotReady candidacy data is already fetched and stored (Phase B is complete)
- `essentials.election_records`, `essentials.endorsements`, `essentials.politician_stances` tables exist
- The `politicians` table has `is_appointed`, `is_vacant` fields but no `is_candidate` flag
- The frontend `classify.js` only handles elected/appointed officials

### Recommendation: Add `is_candidate` Flag and Candidacy API Endpoint

**Confidence: High**

**Backend changes (no new libraries):**

Add a boolean field to indicate this politician record represents a candidate in an active race, not a current officeholder:

```go
// In models.go — extend Politician struct
IsCandidate bool `json:"is_candidate" gorm:"default:false"`
```

Add or extend the existing ZIP-based query to optionally include candidates:

```
GET /essentials/politicians/{zip}?include_candidates=true
```

The existing `fetchOfficialsFromDB` function needs a conditional JOIN or filter to include/exclude candidates. The existing `ElectionRecord` table can determine candidacy status (active election date in the future).

**Frontend changes (no new libraries):**

1. Add a toggle control to `Dashboard.jsx` — "Show Candidates" (default off)
2. Extend `classify.js` to handle candidate records — they belong in the same tiers but with a visual badge
3. In `PoliticianCard.jsx`, add a "Candidate" badge when `is_candidate === true`

**Visual differentiation approach:** Use a subtle border or badge variant — `ring-2 ring-ev-yellow` or a "Candidate" label badge. The existing Tailwind classes cover this without new dependencies.

**What NOT to Do:**
- Do NOT create a separate candidates API endpoint if candidates can be returned from the existing ZIP endpoint via query param — keeps the frontend polling logic simple
- Do NOT add a new frontend page for candidates — integrate into the existing results view with the toggle

---

## 5. Image Storage and Delivery (Building Photos)

### Problem

The platform needs building images for Federal/State/Local sections (US Capitol, state capitols, courthouses for LA and Bloomington). These are static editorial images — not user uploads, not politician photos (those already come from BallotReady CDN URLs).

### Current State

- No cloud file storage integration exists
- Politician profile images are served directly from BallotReady CDN URLs stored in the database
- No `File Storage` infrastructure exists for editorial content

### Options Evaluated

#### Option A: Supabase Storage (Recommended)

**Confidence: High**

Supabase Storage is already the project's database provider. The free tier includes 1 GB storage and 2 GB egress/month. The Pro plan includes image transformations at $5/1,000 origin images.

**Rationale:**
- Already paying for Supabase — no new vendor
- Built-in CDN with 285+ edge nodes worldwide
- Public bucket URLs work without SDK: `https://[project_id].supabase.co/storage/v1/object/public/[bucket]/[asset-name]`
- Image transformation for responsive sizing (width/height params)
- For a small number of static editorial images (~10-20 photos), the free tier is more than sufficient
- No new Go or React dependencies needed — just store URLs in config/DB

**Implementation:**
1. Create a public bucket `editorial-images` in Supabase dashboard
2. Upload building photos manually (one-time; not automated)
3. Store public URLs in a config file or a small `editorial_images` table
4. Frontend fetches URLs from config or a new lightweight endpoint

**URL pattern:**
```
https://[project_id].supabase.co/storage/v1/object/public/editorial-images/federal/us-capitol.jpg
https://[project_id].supabase.co/storage/v1/object/public/editorial-images/state/indiana-statehouse.jpg
```

**No SDK needed for reading:** Public bucket URLs are accessible directly from `<img>` tags. No `@supabase/supabase-js` client needed on the frontend for read-only image access.

#### Option B: Netlify Large Media / Git LFS

**Not recommended.** Netlify Large Media is deprecated. Git LFS adds complexity for a small number of static images.

#### Option C: Store in GitHub repo as static assets

**Acceptable for 10-20 small images** but not scalable and adds repository bloat. Supabase Storage is cleaner and already available.

#### Option D: Cloudflare R2 / AWS S3

**Overkill for this use case.** Would require new vendor credentials, IAM setup, and additional complexity. Not justified when Supabase Storage already covers the need at $0 marginal cost.

### What NOT to Do

- Do NOT install `@supabase/supabase-js` on the frontend just for reading public image URLs — direct `<img src="...">` is sufficient
- Do NOT use image transformation for these static editorial images unless needed for performance — the images are hand-curated and can be pre-optimized before upload
- Do NOT add the images to the Git repository — keep the repo lean

---

## 6. Project Structure Consolidation

### Problem

The current workspace has 5+ separate React apps (CompassV2, essentials, EV-prototypes/*, ev-ui), each with independent `node_modules`, `package.json`, and `npm install`. This causes:
- Diverging dependency versions across apps (Vite 6 vs 7, React 19.0 vs 19.1.1)
- ev-ui must be published to GitHub npm registry before changes reflect in consuming apps
- No shared tooling config (ESLint, TypeScript settings)
- EV-prototypes already uses a manual multi-build script (not true workspaces)

### Options Evaluated

#### Option A: npm Workspaces at the Workspace Root (Recommended)

**Confidence: Medium**

**What it is:** A single `package.json` at the repo root with a `workspaces` array pointing to each app. npm v7+ handles hoisted `node_modules` and symlinks local packages.

**Benefits for this team:**
- ev-ui becomes a local workspace package — no publish cycle needed during development
- Single `npm install` at root installs all dependencies
- Shared dev dependencies (ESLint, TypeScript types) can be hoisted to root
- Works with existing Vite setups — no Vite config changes needed
- No new tooling to learn

**Drawbacks:**
- Requires restructuring the root `package.json` (currently not an npm package)
- Netlify build commands need updating to target specific workspace packages
- Some hoisting conflicts possible with peer dependencies (manageable)

**Root package.json:**
```json
{
  "name": "empowered-vote",
  "private": true,
  "workspaces": [
    "CompassV2",
    "essentials",
    "ev-ui",
    "EV-prototypes/read-rank",
    "EV-prototypes/treasury-tracker",
    "EV-prototypes/data-entry",
    "EV-prototypes/empowered-badges"
  ]
}
```

**ev-ui as local package:**
In consuming apps, replace:
```json
"@chrisandrewsedu/ev-ui": "^0.1.14"
```
with:
```json
"@chrisandrewsedu/ev-ui": "*"
```
npm workspaces automatically symlinks the local `ev-ui/` package.

#### Option B: Turborepo

**Not recommended for current milestone.**

Turborepo adds task orchestration (parallel builds, caching) on top of npm/pnpm workspaces. Useful for teams with complex build pipelines and CI caching needs. For a 2-3 person nonprofit team with manual Netlify deploys, the overhead of learning and configuring Turborepo is not justified. Evaluate post-consolidation if build times become painful.

**What NOT to Do:** Do NOT adopt Turborepo for this milestone — the benefit is real but the setup cost is disproportionate to team size.

#### Option C: Keep Current Structure (Status Quo)

**Acceptable if consolidation is deferred.** The current multi-repo-style structure works and has clear boundaries. The main pain is the ev-ui publish cycle during active component development.

**Recommendation:** Proceed with Option A (npm workspaces) for ev-ui linkage only in the first step. Full workspace consolidation of all apps can follow. This is the lowest-risk migration path.

#### Option D: Unified Single React App (Vite with sub-routes)

**Not recommended.** Merging CompassV2 and essentials into one app would require a large routing restructure, shared auth state decisions, and increases deployment surface area. The apps serve different user flows and can stay separate.

---

## Summary Table

| Area | Decision | New Dependencies | Confidence |
|------|----------|-----------------|------------|
| Guest-first auth | localStorage-first, optional server sync | None | High |
| Topic question field | Add `question` column to `compass.topics` | None | High |
| Stance randomization | Client-side shuffle, localStorage-persisted | None | High |
| Candidate support | `is_candidate` flag + query param filter | None | High |
| Building images | Supabase Storage public bucket | None (direct URL) | High |
| Project consolidation | npm workspaces (ev-ui first) | None | Medium |

**Key finding:** None of the six improvement areas require new runtime dependencies. The existing stack handles all requirements. The work is architectural and data-model level, not library selection.

---

## Versions Reference (as of 2026-02-17)

These are the versions already in use. No upgrades are recommended for this milestone — upgrading mid-milestone creates unnecessary risk.

| Package | Current Version | Latest | Action |
|---------|----------------|--------|--------|
| React | 19.1.x | 19.1.x | No change |
| Vite | 6.3.5 (CompassV2), 7.1.2 (essentials) | 7.x | No change |
| Tailwind CSS | 4.1.x | 4.1.x | No change |
| Zustand | 5.0.9 | 5.0.x | No change |
| GORM | 1.30.0 | 1.30.x | No change |
| Chi | v5.2.1 | v5.x | No change |
| Go | 1.24.3 | 1.24.3 | No change |

---

## What NOT to Adopt This Milestone

| Considered | Reason to Skip |
|------------|---------------|
| Auth0 / Clerk | Cost + migration complexity; existing session auth is fine |
| Turborepo | Overhead disproportionate to 2-3 person team |
| Anonymous backend sessions for guests | Pure localStorage avoids backend complexity |
| @supabase/supabase-js (frontend) | Not needed for reading public image URLs |
| TypeScript migration | Would require coordinated effort across all apps; not this milestone |
| New state management (Jotai, Valtio) | Context + localStorage already handles the use cases |
| React Query / SWR | Would require rewriting existing polling hooks; defer until needed |
| Cloudflare R2 / AWS S3 | Supabase Storage already covers image hosting need at $0 marginal cost |

---

*Stack research: 2026-02-17*
