# Architecture Research

**Domain:** Civic tech — Read & Rank integration, shared cross-app localStorage, and quote verdict display
**Researched:** 2026-03-11
**Confidence:** HIGH (all based on direct codebase inspection)

## Context: Subsequent Milestone (v2026.3.4)

This is an integration-focused architecture document for v2026.3.4. It describes how three related features plug into the existing Go + React system:

1. **Read & Rank standalone extraction** — move `EV-prototypes/read-rank/` to its own repo on `readrank.empowered.vote`
2. **Shared `.empowered.vote` localStorage** — cross-app state (verdicts, compass data) accessible by all subdomains, replacing the URL fragment bridge
3. **Quote verdict display in CompassCard** — show each user's agree/disagree verdict next to politician stances in Essentials profile pages

No new frameworks, DB schemas, or backend endpoints are being added for items 1 and 2. Item 3 requires one new backend endpoint.

---

## System Overview: Current State

Before this milestone the system looks like this:

```
compass.empowered.vote       readrank.empowered.vote      essentials.empowered.vote
(CompassV2 React app)        (not yet standalone)         (Essentials React app)
        |                                                          |
        | guest compass data:                                      |
        | URL fragment bridge:                                     |
        | ?return=<essentials_url>                                 |
        | + #compass=BASE64(answers)  <--------------------------  |
        |                                                          |
        +------------------------------------------+               |
                                                   |               |
                                                   v               v
                                          api.empowered.vote
                                          (Go/Chi backend, Render)
                                                   |
                                                   v
                                         Supabase PostgreSQL
```

Key state-per-app:
- **CompassV2:** `compass_answers`, `compass_selected_topics`, `compass_inverted` in localStorage (key: `guestCompass`) + server-side for logged-in users
- **Read & Rank (prototype):** `readrank-storage` Zustand persist key in localStorage; contains per-issue progress with agree/disagree/badge data
- **Essentials:** No verdicts stored; reads compass data via URL fragment on arrival, then falls back to its own `guestCompass` localStorage key (same schema as CompassV2 uses)
- **Cross-app compass data today:** CompassV2 → Essentials via URL fragment (#compass=BASE64); fragment is parsed once on arrival, then cached in Essentials localStorage

---

## System Overview: After This Milestone

```
compass.empowered.vote       readrank.empowered.vote      essentials.empowered.vote
(CompassV2 React app)        (NEW standalone app)         (Essentials React app)
        |                           |                              |
        |                           |                              |
        +---------------------------+------------------------------+
                                    |
                   Shared localStorage (domain: .empowered.vote)
                   Key: ev_guest_compass  (replaces guestCompass)
                   Key: ev_readrank       (verdicts per issue)
                                    |
                                    v
                          api.empowered.vote
                          (Go/Chi backend, Render)
                          NEW: POST /essentials/verdicts  (logged-in)
                          NEW: GET  /essentials/verdicts?politician_id=X
                                    |
                                    v
                          Supabase PostgreSQL
                          NEW: essentials.quote_verdicts table
```

The URL fragment bridge is retired. Cross-app state flows through shared localStorage only.

---

## Feature 1: Read & Rank Standalone Extraction

### What Changes

The `EV-prototypes/read-rank/` directory becomes a standalone repo: `github.com/chrisandrewsedu/ev-readrank` (or similar), deployed to `readrank.empowered.vote` on Cloudflare Pages.

### What Stays the Same

The entire application surface: components, store, data fetching, phases (hub, evaluation, ranking, results), Zustand persist, routing. Zero behavior changes at extraction time — extraction is a file copy + config update.

### Config Changes Required

The BrowserRouter `basename` is currently hardcoded to `/read-rank/dist` (a Netlify monorepo path). In the standalone app this becomes `/` or is removed entirely:

```tsx
// Before (EV-prototypes monorepo):
<BrowserRouter basename="/read-rank/dist">

// After (standalone):
<BrowserRouter>
```

Vite `base` in `vite.config.ts` must also be set to `/` (default) rather than any subdirectory.

The `VITE_API_URL` env var stays as-is pointing to `https://api.empowered.vote`.

The ev-ui package reference (`@chrisandrewsedu/ev-ui`) stays as-is; the standalone repo needs its own `.npmrc` pointing to the GitHub npm registry.

### Cloudflare Pages Config

New Pages project: `readrank-ev` (or similar). Build command: `npm run build`. Output: `dist/`. Domain: `readrank.empowered.vote`.

SPA routing: add `_redirects` file at root of `dist/`:
```
/*    /index.html    200
```

This is needed because `CandidateAlignmentPage` uses `/candidate/:id/alignment` routes that Cloudflare must pass through to the React router.

---

## Feature 2: Shared `.empowered.vote` localStorage

### The Problem with the Current Approach

Two problems with the URL fragment bridge:

1. **One-way, one-time:** The fragment carries data from CompassV2 to Essentials on one page load. If the user answers more compass questions later, Essentials does not see the update.
2. **Not accessible to Read & Rank:** There is no existing mechanism for Read & Rank verdicts to appear in Essentials.

### How Shared localStorage Works

localStorage is scoped to `(scheme, host)` — not just the registered domain. `compass.empowered.vote` and `essentials.empowered.vote` each have their own isolated localStorage. Browsers do not allow cross-origin localStorage reads directly.

**The only reliable mechanism on Cloudflare Pages subdomains is a shared cookie domain.** But cookies are not what we need here — we need a key-value store readable by React.

**Correct approach: shared localStorage via a common subdomain-scoped cookie bridge does NOT work for arbitrary JSON.**

**What does work: write to a key in localStorage on each subdomain with a known key name. Then when Essentials loads, it reads from that known key.** This already works today — both CompassV2 and Essentials use `guestCompass` as the localStorage key, and if they happen to run on the same subdomain or a user navigates directly, this works. But `compass.empowered.vote` and `essentials.empowered.vote` have separate localStorage namespaces.

**The actual solution: use a postMessage relay or a shared iframe.** A tiny hidden `<iframe>` hosted at `shared.empowered.vote` can act as a localStorage relay — both parent pages post messages to it, and it reads/writes to its own localStorage, echoing values back. This pattern is called the "localStorage proxy iframe."

However, this adds significant complexity. The simpler solution for this scale:

**Recommended: sessionStorage + URL parameter handoff + deeper local caching on Essentials side.**

For guest compass data: the existing URL fragment bridge already handles the CompassV2 → Essentials handoff. The fragment is cached in Essentials localStorage on first arrival. This cache survives refreshes. The only gap is when a guest updates their compass after visiting Essentials; they must click "Return to profile" again (the ReturnBanner already supports this).

For Read & Rank verdicts → Essentials: Read & Rank can pass completed verdicts to Essentials via URL parameters when the user navigates from Read & Rank to an Essentials politician profile. This is the same pattern as the existing fragment bridge.

**Alternative recommended approach (simpler than iframe relay, better than pure URL params): use a subdomain-scoped cookie for a small summary token, plus URL params for richer data on explicit cross-app navigation.**

**Verdict after analysis:** Given the team size (2-3 devs) and the low cross-app navigation frequency, the most practical approach is:

1. Keep the URL fragment bridge for compass data (already works)
2. Add verdict data to the URL fragment when Read & Rank links to Essentials
3. Cache verdicts in Essentials localStorage under a stable key (`ev_readrank_verdicts`)
4. For logged-in users: sync verdicts to the server so they persist cross-device

This avoids iframe complexity entirely, adds no new infrastructure, and matches the existing pattern the team already understands.

### Verdict Data Schema

Zustand's `readrank-storage` key already contains per-issue agree/disagree/badge data. The fragment bridge extension adds a verdicts summary to the `#compass=` fragment payload:

```typescript
// Extended fragment payload (add 'v' key alongside existing 'a', 's', 'i'):
{
  a: { [short_title]: value },     // existing compass answers
  s: [uuid, ...],                   // existing selected topics
  i: { [short_title]: bool },       // existing inverted spokes
  v: {                              // NEW: quote verdicts
    [quoteId]: 'agree' | 'disagree' | 'diamond' | 'gold'
  }
}
```

The fragment is still BASE64-encoded. Size concern: 61 quotes in DB × ~40 chars per entry = ~2.4KB uncompressed. After BASE64 that is ~3.2KB. URL length limits are ~8KB in most browsers — this is fine.

Essentials `parseCompassFragment()` in `src/lib/compass.js` already handles optional keys (it returns `decoded.i || {}`). Adding `decoded.v || {}` follows the same pattern.

### What Gets Retired

The `ReturnBanner` mechanism (CompassV2 → Essentials with `?return=` param + `#compass=` fragment) stays. Nothing is retired in v2026.3.4. The fragment bridge works and is not worth replacing.

The PROJECT.md requirement "Retire URL fragment bridge" is future scope, contingent on proving the shared localStorage alternative is simpler in practice. For now, augment the fragment with verdicts data.

---

## Feature 3: Quote Verdict Display in CompassCard

### Where Verdicts Appear

Verdicts show inside the existing `StanceAccordion` component (in `essentials/src/components/StanceAccordion.jsx`). Each accordion row already shows:
- Topic short_title
- question_text
- Politician's stance label (e.g., "Strongly Support")

The new addition: if the user has a verdict for any of the politician's quotes on this topic, show it inline. A small badge — "You Agreed" (green) or "You Disagreed" (red) — alongside or below the stance label.

This requires knowing:
1. Which quotes belong to this topic (quote_id → topic_key mapping)
2. What verdict the user gave each quote

### Data Flow: Verdict Display

```
User evaluates quotes on readrank.empowered.vote
        |
        | (URL fragment bridge when linking to essentials profile)
        v
Essentials receives #compass=BASE64({..., v: {quoteId: 'agree', ...}})
        |
        v
parseCompassFragment() extracts verdicts
        |
        v
CompassContext (essentials) stores verdicts in state + caches in localStorage
        |
        v
CompassCard renders --> passes verdicts to StanceAccordion
        |
        v
StanceAccordion row: for each topic, look up quotes that belong to this topic
        |
        v
Show verdict badge if user evaluated any of those quotes
```

### Backend Support: Linking Quotes to Topics in StanceAccordion

StanceAccordion currently receives `topics` (CompassV2 topic objects with `id`, `short_title`, `stances`). It does not know about quotes.

To show verdict badges, StanceAccordion needs to know which quote IDs belong to each topic.

**Option A: Fetch quotes data in StanceAccordion.** Call `GET /essentials/quotes` (already exists) and filter by `issue` field (which is `topic_key`). This adds one fetch per CompassCard render.

**Option B: Pass quoteIds via CompassCard.** CompassCard already fetches politician answers. Extend `CompassCard` to also call `GET /essentials/quotes?politician_id=X` (new endpoint, narrow scope), getting only the quotes for the displayed politician. Then pass a `{ [topic_key]: quoteId[] }` map down to StanceAccordion.

**Option C: Include quote IDs in the politician stances response.** Extend `GET /compass/politicians/:id/answers` to also return associated quote IDs per topic.

Option B is recommended. It keeps the data fetching in `CompassCard` (which already fetches politician answers), avoids loading all 61 quotes every time, and makes StanceAccordion a pure display component. It requires one new backend endpoint.

### New Backend Endpoint: `GET /essentials/quotes?politician_id=X`

Filters the existing `GetQuotes` handler by politician. Returns the same shape as the existing endpoint but scoped to one politician:

```json
{
  "quotes": [
    { "id": "...", "issue": "cannabis-legalization", "text": "...", ... }
  ]
}
```

The `issue` field is the topic_key. StanceAccordion receives a `verdictsByTopic` map keyed by topic_key, derived by:

```javascript
// In CompassCard, after fetching politician quotes:
const verdictsByTopic = {};
for (const quote of polQuotes) {
  const verdict = verdicts[quote.id]; // from CompassContext
  if (verdict) {
    verdictsByTopic[quote.issue] = verdict; // first verdict per topic wins
  }
}
```

### CompassContext Extension (Essentials)

`CompassContext` in `essentials/src/contexts/CompassContext.jsx` currently manages:
- `isLoggedIn`, `userName`
- `userAnswers`, `selectedTopics`, `allTopics`, `invertedSpokes`
- `politicianIdsWithStances`

Add: `verdicts` — `Record<quoteId, 'agree' | 'disagree' | 'diamond' | 'gold'>`.

Load priority mirrors the existing pattern:
1. Logged-in path: fetch from `GET /essentials/verdicts` (new endpoint)
2. Fragment: extract `v` key from compass fragment
3. localStorage cache: `ev_readrank_verdicts` key
4. Empty: `{}`

### Server-Side Verdict Storage (Logged-in Users)

Two new backend endpoints:

**`POST /essentials/verdicts`** — upsert a user's complete verdict set
```json
{
  "verdicts": { "quoteId": "agree", "quoteId2": "disagree" }
}
```

**`GET /essentials/verdicts`** — return the current user's verdicts
```json
{
  "verdicts": { "quoteId": "agree", "quoteId2": "disagree" }
}
```

New table: `essentials.quote_verdicts`

```sql
CREATE TABLE essentials.quote_verdicts (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES app_auth.users(id) ON DELETE CASCADE,
  quote_id   UUID NOT NULL REFERENCES essentials.quotes(id) ON DELETE CASCADE,
  verdict    TEXT NOT NULL CHECK (verdict IN ('agree', 'disagree', 'diamond', 'gold')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, quote_id)
);
```

Both endpoints require `middleware.SessionMiddleware`. The POST is a bulk upsert (ON CONFLICT DO UPDATE) — same pattern as compass answers.

---

## Component Boundaries: New vs. Modified

| Component | Status | What Changes |
|-----------|--------|--------------|
| `readrank.empowered.vote` repo | NEW | Extracted from EV-prototypes; BrowserRouter basename fixed; standalone Cloudflare Pages |
| `_redirects` (Read & Rank) | NEW | SPA routing for Cloudflare Pages |
| `essentials.quote_verdicts` table | NEW | Server-side verdict storage |
| `GoVerdicts` / `PostVerdicts` handlers (Go) | NEW | CRUD for logged-in user verdicts |
| `GET /essentials/quotes?politician_id=X` | NEW | Filtered quotes fetch per politician |
| `CompassContext` (Essentials) | MODIFIED | Add `verdicts` state, load from fragment/localStorage/API |
| `parseCompassFragment()` (Essentials) | MODIFIED | Extract `v` key from fragment payload |
| `serializeCompassFragment()` (CompassV2) | MODIFIED | Include `v` key in fragment payload |
| `CompassCard` (Essentials) | MODIFIED | Fetch politician quotes, derive `verdictsByTopic`, pass to StanceAccordion |
| `StanceAccordion` (Essentials) | MODIFIED | Accept `verdictsByTopic` prop, render verdict badge per topic row |
| `useReadRankStore` (Read & Rank) | NOT MODIFIED | Existing Zustand store unchanged |
| `ResultsPhase` / `IssueHub` (Read & Rank) | MODIFIED | Add "View on Essentials" CTA that builds fragment URL with verdicts |
| `EV-Backend routes.go` (essentials) | MODIFIED | Register 3 new routes |
| `EV-Backend internal/essentials/models.go` | MODIFIED | Add QuoteVerdict model |

---

## Data Flow: Full Cross-App Verdict Journey

```
1. User evaluates quotes on readrank.empowered.vote
   - Zustand store records: { "quoteId": "agree/disagree/diamond/gold", ... }
   - Persisted in readrank.empowered.vote localStorage under "readrank-storage"

2. User clicks "See this politician on Empowered Vote" (new CTA in ResultsPhase)
   - Read & Rank reads all verdicts from Zustand store
   - Reads existing compass data from localStorage ("guestCompass") if present
   - Builds fragment: #compass=BASE64({a: answers, s: selected, i: inverted, v: verdicts})
   - Navigates to: essentials.empowered.vote/politician/:id#compass=BASE64(...)

3. Essentials profile page loads
   - parseCompassFragment() runs synchronously before any async calls
   - Extracts answers, selected topics, inverted spokes, AND verdicts
   - Saves all to localStorage: "guestCompass" (compass data) + "ev_readrank_verdicts" (verdicts)
   - Strips fragment from URL (history.replaceState)

4. CompassContext.loadAll() runs
   - Compass data: from fragment (highest priority) -> localStorage -> empty
   - Verdicts: from fragment -> localStorage "ev_readrank_verdicts" -> API (if logged in) -> {}
   - Sets verdicts in context state

5. Profile page renders CompassCard
   - CompassCard fetches: politician stances (existing) + politician quotes (new GET /essentials/quotes?politician_id=X)
   - Derives verdictsByTopic: { "cannabis-legalization": "agree", "education-funding": "disagree", ... }
   - Passes verdictsByTopic to StanceAccordion

6. StanceAccordion renders
   - Each topic row: show existing stance label + NEW verdict badge if verdictsByTopic[topic.topic_key] exists
   - "You Agreed" (green) / "You Disagreed" (red) / "Your Top Pick" (diamond) / "Your Runner Up" (gold)

7. If logged in (either app):
   - Read & Rank: on session check, POST /essentials/verdicts with current Zustand state
   - Essentials: CompassContext loads verdicts from GET /essentials/verdicts instead of localStorage
```

---

## Recommended Project Structure: Read & Rank Standalone

The extracted repo mirrors the existing CompassV2/Essentials structure:

```
ev-readrank/               (new repo: github.com/chrisandrewsedu/ev-readrank)
├── src/
│   ├── components/        -- all existing EV-prototypes/read-rank/src/components/
│   ├── hooks/             -- useDeviceType.ts
│   ├── store/             -- useReadRankStore.ts (rename key: "readrank-storage" -> "ev_readrank")
│   ├── data/              -- api.ts, mockData.ts
│   ├── utils/             -- matchingAlgorithm.ts
│   ├── types/             -- ev-ui.d.ts
│   ├── App.tsx            -- BrowserRouter without basename
│   └── main.tsx
├── public/
│   ├── EVLogo.svg
│   └── _redirects         -- NEW: /* /index.html 200
├── .npmrc                 -- GitHub npm registry token for ev-ui
├── package.json
└── vite.config.ts         -- base: "/"
```

Key rename: localStorage key `readrank-storage` → `ev_readrank` for consistency with the shared namespace pattern. This is a breaking change in persisted state — add a migration step in the Zustand store's `onRehydrateStorage` to read from old key if new key is absent.

---

## Architectural Patterns

### Pattern 1: Fragment Bridge Augmentation

**What:** Extend the existing `#compass=BASE64` fragment payload with a new `v` key for verdicts.
**When to use:** Any time cross-origin state must be handed off on explicit user navigation.
**Trade-offs:** Simple, no new infra, one-time transfer only (not live sync). Acceptable for this use case because the user is explicitly navigating between apps.

**Example (serialization side in Read & Rank):**
```typescript
function buildEssentialsUrl(essentialsBaseUrl: string, politicianId: string): string {
  const store = useReadRankStore.getState();
  const allVerdicts: Record<string, string> = {};

  Object.values(store.issueProgress).forEach(issue => {
    issue.agreedQuotes.forEach(q => { allVerdicts[q.id] = 'agree'; });
    issue.disagreedQuotes.forEach(q => { allVerdicts[q.id] = 'disagree'; });
    if (issue.badgeAssignments.diamond) allVerdicts[issue.badgeAssignments.diamond] = 'diamond';
    if (issue.badgeAssignments.gold) allVerdicts[issue.badgeAssignments.gold] = 'gold';
  });

  // Merge with existing compass data from localStorage
  const guestCompass = JSON.parse(localStorage.getItem('guestCompass') || '{}');
  const payload = { ...guestCompass, v: allVerdicts };
  const fragment = '#compass=' + btoa(JSON.stringify(payload));
  return `${essentialsBaseUrl}/politician/${politicianId}${fragment}`;
}
```

### Pattern 2: Context-Level Verdict Cache

**What:** Store verdicts at CompassContext level (not component level) so all components on a profile page see the same data without redundant fetches.
**When to use:** Any cross-component shared state that is loaded once on page entry and referenced by multiple nested components.
**Trade-offs:** Adds one more field to CompassContext, but CompassContext already manages 8 fields — incremental cost is low.

### Pattern 3: Per-Politician Quote Fetch at CompassCard Level

**What:** Fetch `GET /essentials/quotes?politician_id=X` inside `CompassCard` rather than at page level or inside StanceAccordion.
**When to use:** When data is only needed by one section of a page and has a clear natural owner (CompassCard already owns the "compare with this politician" concern).
**Trade-offs:** Adds one more concurrent fetch to CompassCard's load sequence. Acceptable because the quotes fetch is small (one politician's quotes = at most ~5-10 rows in current data).

---

## Build Order (Dependency-Ordered)

**Step 1 — Read & Rank standalone extraction.** Copy `EV-prototypes/read-rank/` to new repo. Fix BrowserRouter basename, Vite base, add `_redirects`. Deploy to `readrank.empowered.vote`. Verify all three routes work (`/`, `/candidate/:id/alignment`, `/animation-options`). No logic changes.

**Step 2 — localStorage key rename (Read & Rank).** Rename Zustand persist key from `readrank-storage` to `ev_readrank`. Add migration in `onRehydrateStorage`. Deploy Read & Rank.

**Step 3 — Backend: new DB table and verdict endpoints.** Add `QuoteVerdict` model to `EV-Backend/internal/essentials/models.go`. Register in `setup.go` AutoMigrate. Add `GetVerdicts` and `PostVerdicts` handlers. Add `GET /essentials/quotes?politician_id=X` filter to existing `GetQuotes`. Register routes. Deploy backend.

**Step 4 — CompassContext extension (Essentials).** Add `verdicts` state field to CompassContext. Extend `parseCompassFragment()` to extract `v` key. Add `verdicts` load path (fragment → localStorage → API → {}). Add `verdicts` to context value.

**Step 5 — Fragment serialization in Read & Rank.** Add "View on Essentials" CTA to `ResultsPhase` and `CandidateAlignmentPage`. Implement `buildEssentialsUrl()` that serializes verdicts into the fragment. Link opens Essentials politician profile with the full fragment.

**Step 6 — CompassCard: fetch politician quotes and derive verdictsByTopic.** After existing `fetchPoliticianAnswers()` call, add `fetchPoliticianQuotes(politicianId)`. Derive `verdictsByTopic` map. Pass to StanceAccordion.

**Step 7 — StanceAccordion: render verdict badges.** Accept `verdictsByTopic` prop. In each topic row, show verdict badge when `verdictsByTopic[topic.topic_key]` is present.

**Step 8 — Logged-in sync (Read & Rank → backend).** On session check in Read & Rank (if/when auth is added), POST verdicts to `/essentials/verdicts`. Lower priority — guest flow is the primary path.

Steps 1-2 are fully independent of steps 3-7 and can run in parallel. Step 3 must complete before step 4 (logged-in verdict fetch). Steps 4 and 5 can run in parallel. Step 6 depends on step 3 (needs the new endpoint) and step 4 (needs verdicts in context). Step 7 depends on step 6.

---

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| Current (61 quotes, ~23 politicians) | In-memory verdict map in CompassContext; no caching needed |
| 500+ quotes, multi-region data | Consider caching quotes by politician_id in a Map; TTL 5 min |
| Logged-in users with cross-device sync | Existing session cookie on .empowered.vote handles auth; verdict endpoint uses same session middleware as compass answers |

The verdict data volume is inherently bounded — users can only evaluate as many quotes as exist in the DB (currently 61). At 10,000 logged-in users the `quote_verdicts` table has at most 610,000 rows, which is trivially manageable in Postgres.

---

## Anti-Patterns

### Anti-Pattern 1: iframe localStorage relay

**What people do:** Build a hidden `<iframe src="https://shared.empowered.vote/relay.html">` that proxies localStorage via postMessage.
**Why it's wrong:** Adds a new subdomain and deployment, makes the data flow opaque, requires careful handling of async message passing in React, and is completely unnecessary when the URL fragment bridge already works reliably.
**Do this instead:** Extend the existing fragment bridge with the verdicts payload. One-time handoff on explicit navigation is sufficient for this feature.

### Anti-Pattern 2: Storing verdicts in the compass fragment without a size check

**What people do:** Serialize all Zustand `issueProgress` state into the fragment, which includes full quote text, timestamps, and legacy fields.
**Why it's wrong:** `issueProgress` is ~10KB of JSON for a fully completed session. BASE64-encoded in a URL exceeds some browser/server limits.
**Do this instead:** Serialize only the verdict summary (`{ [quoteId]: 'agree' | 'disagree' | 'diamond' | 'gold' }`), not the full progress tree. The quote text is not needed in Essentials — only the verdict status per quote ID.

### Anti-Pattern 3: Fetching all quotes in StanceAccordion

**What people do:** Call `GET /essentials/quotes` (all 61 quotes) inside StanceAccordion to find verdicts for displayed topics.
**Why it's wrong:** Over-fetches; StanceAccordion is a pure display component and should not own data fetching; pulling all quotes when you need only 5 for one politician is wasteful.
**Do this instead:** Fetch `GET /essentials/quotes?politician_id=X` in CompassCard (which already owns politician-scoped data fetching), derive the `verdictsByTopic` map, and pass it as a prop.

### Anti-Pattern 4: Breaking the standalone extraction by changing app behavior

**What people do:** "While extracting, also refactor the store, update the design, and add the verdict export all at once."
**Why it's wrong:** Conflates extraction (structural, zero behavior change) with feature work (behavior change). Makes debugging harder. If the deployment breaks, you cannot tell if it is the structural change or the behavior change.
**Do this instead:** Extract first, verify it works identically to the prototype, deploy, then layer in feature changes as separate commits.

---

## Integration Points Summary

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Read & Rank → Essentials | URL fragment (#compass=BASE64 with `v` key) | Triggered by user clicking "View on Essentials" CTA |
| Essentials CompassContext → StanceAccordion | React props via CompassCard (`verdictsByTopic`) | Context holds verdicts; CompassCard derives topic-keyed map |
| CompassCard → backend | `GET /essentials/quotes?politician_id=X` | New endpoint, returns quote IDs and topic keys for one politician |
| Logged-in users (either app) → backend | `POST /essentials/verdicts` | Bulk upsert; same session cookie as compass answers |
| CompassContext (Essentials) → backend | `GET /essentials/verdicts` | Logged-in load path; replaces localStorage as source of truth |
| `readrank.empowered.vote` localStorage | `ev_readrank` Zustand persist key | Renamed from `readrank-storage` during extraction |
| `essentials.empowered.vote` localStorage | `ev_readrank_verdicts` key | Verdicts cache; written by parseCompassFragment on arrival |

---

## Sources

- Direct inspection of `EV-prototypes/read-rank/src/App.tsx` — BrowserRouter basename, route structure
- Direct inspection of `EV-prototypes/read-rank/src/store/useReadRankStore.ts` — Zustand state shape, persist key name, per-issue agree/disagree/badge data
- Direct inspection of `EV-prototypes/read-rank/src/data/api.ts` — `fetchQuotesData()` call to `GET /essentials/quotes`, fallback to mockData
- Direct inspection of `EV-prototypes/read-rank/src/components/ResultsPhase.tsx` — result cards, "Back to Issues" navigation
- Direct inspection of `EV-prototypes/read-rank/src/components/CandidateAlignmentPage.tsx` — per-issue badge breakdown, navigation from results
- Direct inspection of `essentials/src/contexts/CompassContext.jsx` — load priority (fragment > API > localStorage > empty), fragment parse, `guestCompass` key
- Direct inspection of `essentials/src/lib/compass.js` — `parseCompassFragment()`, `saveGuestCompass()`, fragment schema (`{a, s, i}`)
- Direct inspection of `essentials/src/components/CompassCard.jsx` — dual fetch (politician answers + context), verdicts display points
- Direct inspection of `essentials/src/components/StanceAccordion.jsx` — row structure, lazy context fetch, prop surface
- Direct inspection of `essentials/src/pages/Profile.jsx` — CompassCard usage, data flow into profile
- Direct inspection of `CompassV2/src/components/ReturnBanner.jsx` — fragment serialization via `serializeCompassFragment()`
- Direct inspection of `EV-Backend/internal/essentials/handlers.go` — `GetQuotes` function, SQL, response shape (`quotes`, `candidates`, `issues`)
- Direct inspection of `EV-Backend/internal/essentials/routes.go` — existing route surface, `/quotes` GET endpoint
- Direct inspection of `.planning/PROJECT.md` — v2026.3.4 milestone scope, active requirements, out-of-scope boundaries

---

*Architecture research for: v2026.3.4 Read & Rank Integration*
*Researched: 2026-03-11*
