# Stack Research

**Domain:** Read & Rank extraction + cross-app state sharing + verdict integration
**Researched:** 2026-03-11
**Confidence:** HIGH (all critical findings verified against source code and official specs)

---

## Context: What Is and Is Not New

The existing stack (React 19, Vite 7, Tailwind CSS 4, Zustand 5, Framer Motion 12,
@use-gesture/react 10, @dnd-kit) is already running in EV-prototypes/read-rank.
This document covers only what changes for the standalone extraction and the new
cross-app / verdict integration features.

---

## Section 1: Standalone Repo Extraction (Read & Rank)

### No New Stack Required

The read-rank sub-project inside EV-prototypes already has a complete, self-contained
package.json with its own Vite config, TypeScript, and all runtime deps. Extraction to a
standalone repo is a file-copy operation with two adjustments:

1. **ev-ui package reference** — currently `@chrisandrewsedu/ev-ui`, needs `.npmrc`
   pointing at `npm.pkg.github.com` with `NPM_TOKEN` (same pattern as the other apps;
   a root `.npmrc` with `//npm.pkg.github.com/:_authToken=${NPM_TOKEN}` is required for
   Cloudflare Pages CI).

2. **Cloudflare Pages config** — a `wrangler.toml` at repo root with
   `not_found_handling = "single-page-application"` under `[assets]`. No Workers runtime
   needed; this is a static SPA deployment identical to how CompassV2 and Essentials are
   already deployed.

### Cloudflare Pages wrangler.toml

```toml
name = "readrank"
compatibility_date = "2024-09-23"

[assets]
directory = "./dist"
not_found_handling = "single-page-application"
```

Build command: `npm run build`
Build output: `dist/`
Environment variable: `VITE_API_URL` set in Cloudflare dashboard
(value: `https://api.empowered.vote`)

**Confidence:** HIGH — official Cloudflare Pages docs confirm this pattern for Vite SPAs.

---

## Section 2: Cross-App State Sharing — The Core Problem

### localStorage Is Origin-Isolated (Browser Spec, Not a Bug)

localStorage is strictly scoped to `scheme + host + port`. Two different subdomains —
`readrank.empowered.vote` and `essentials.empowered.vote` — are different origins.
They cannot access each other's localStorage directly. This is the same-origin policy
as defined in the HTML Living Standard and enforced by every major browser.

Setting `document.domain` does NOT help for localStorage. MDN explicitly documents that
document.domain changes do not affect storage APIs (localStorage, indexedDB,
BroadcastChannel, SharedWorker).

**Verified:** MDN Web APIs `Window.localStorage` and same-origin policy explainer.
**Confidence:** HIGH.

### The Right Solution: URL Fragment Handoff + Server-Side Storage

This codebase already has a working cross-origin state bridge: the `#compass=BASE64(...)`
URL fragment pattern in `essentials/src/lib/compass.js`. Read & Rank verdicts should
use the same mechanism.

**For guests:** When a Read & Rank user navigates to a politician profile in Essentials,
encode the verdict payload into the URL as `#verdicts=BASE64(JSON)`. Essentials parses
it on load, caches to localStorage under key `guestVerdicts`, and strips the hash.
Essentials reads this key on profile pages. This requires zero new libraries.

**For logged-in users:** POST verdicts to the backend on submission. Essentials fetches
them via GET on profile load. The existing session cookie (already scoped to
`.empowered.vote`) handles auth transparently across subdomains.

**Option evaluated and rejected — Hidden Shared Iframe + postMessage:**
A trusted `storage.empowered.vote` iframe communicating via postMessage. Rejected
because: adds iframe load latency, Safari ITP blocks third-party storage access for
same-site iframes, and the URL fragment bridge already proven in this codebase is
simpler and has no browser-compatibility issues.

**Option evaluated and rejected — BroadcastChannel:**
Same-origin only. Different subdomains are isolated. Does not solve the problem.

**Recommendation:** URL fragment handoff for guests (matches existing proven pattern).
Server-side storage for logged-in users (matches existing compass answer pattern).

---

## Section 3: Verdict Storage

### Guest Verdicts — localStorage key `guestVerdicts`

Read & Rank stores its session state in Zustand under key `readrank-storage`. For
the cross-app handoff, a separate, lighter localStorage key is used so Essentials
can read it without importing the Zustand store:

```
localStorage key: "guestVerdicts"
Shape: {
  [politician_id: string]: {
    topicId: string,
    quoteId: string,
    verdict: "agree" | "disagree",
    rank: number | null,
    timestamp: number
  }[]
}
```

Read & Rank writes to `guestVerdicts` after each verdict is finalized. Essentials reads
it via a utility function `loadGuestVerdicts()` parallel to the existing
`loadGuestCompass()` in `essentials/src/lib/compass.js`.

For the URL fragment handoff, encode only the politician-specific verdicts (filtered by
`politician_id`) into `#verdicts=BASE64(...)` so the URL payload stays small.

### Logged-In Verdicts — New Backend Endpoint

New table in `compass.` schema and three endpoints following the exact same pattern as
`compass.answers` and `/compass/answers`:

```
POST   /compass/verdicts        — upsert a verdict (authenticated)
GET    /compass/verdicts        — fetch all verdicts for session user (authenticated)
DELETE /compass/verdicts/{id}   — remove a verdict (authenticated)
```

New GORM model (add to `internal/compass/models.go`):

```go
type QuoteVerdict struct {
    ID        uuid.UUID  `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    UserID    uuid.UUID  `gorm:"type:uuid;uniqueIndex:idx_verdict_user_quote"`
    QuoteID   uuid.UUID  `gorm:"type:uuid;uniqueIndex:idx_verdict_user_quote"`
    Verdict   string     // "agree" | "disagree"
    Rank      *int       // null = no explicit rank assigned
    CreatedAt time.Time
    UpdatedAt time.Time
}
func (QuoteVerdict) TableName() string { return "compass.quote_verdicts" }
```

No new Go libraries. Same Chi router + GORM + SessionMiddleware pattern as all
existing handlers.

### Retiring the URL Fragment Bridge for Compass Data

The existing `#compass=BASE64(...)` bridge between CompassV2 and Essentials is replaced
by shared `.empowered.vote` domain localStorage. Since both `compass.empowered.vote`
and `essentials.empowered.vote` are separate origins, the replacement mechanism is:
CompassV2 writes guest compass data to its own localStorage (already does this under
`compassAnswers` / `selectedTopics` keys), and when Essentials needs this data, it either
reads from the URL fragment (existing path) or the user logs in (server merges data).

The fragment bridge does not need to be retired as an emergency change — it can be kept
and the `guestCompass` localStorage key approach used for the new verdict flow. Retiring
the fragment bridge is a separate concern flagged in PROJECT.md and can happen
independently.

---

## Section 4: Visual Polish for Read & Rank

The existing dependency set is correct and complete. No new animation or UI libraries
are needed.

### Core Technologies (Already in Package)

| Technology | Version in repo | Latest | Purpose | Action |
|------------|----------------|--------|---------|--------|
| framer-motion | ^12.23.26 | 12.35.2 | Card swipe animations, spring physics | Update to ^12.35.0 |
| @use-gesture/react | ^10.3.1 | 10.3.1 | Touch/mouse drag detection | Keep as-is |
| @dnd-kit/core | ^6.3.1 | 6.x | Ranking drag-and-drop base | Keep as-is |
| @dnd-kit/sortable | ^10.0.0 | 10.x | Sortable ranking list | Keep as-is |
| zustand | ^5.0.9 | 5.x | State + localStorage persist | Keep as-is |
| react-icons | ^5.5.0 | 5.x | Icon set | Keep as-is |
| tailwindcss | ^4.1.18 | 4.x | Utility styling | Keep as-is |
| @tailwindcss/forms | ^0.5.10 | — | Form base styles (devDep) | Already present |
| @tailwindcss/typography | ^0.5.19 | — | Quote card prose styles (devDep) | Already present |

### Note on framer-motion Package Name

The library was renamed from `framer-motion` to `motion` starting with v11 but both
npm packages are still published and maintained at the same version (12.35.x as of
March 2026). The codebase uses `framer-motion` — no migration needed.
Import paths stay as `import { motion } from 'framer-motion'`.

---

## Section 5: Essentials Integration

### What Essentials Needs (No New npm Dependencies)

Essentials does not need Zustand. It reads `guestVerdicts` from localStorage directly,
exactly as it reads `guestCompass` today via `loadGuestCompass()`.

New utility functions to add to `essentials/src/lib/` (either extend `compass.js` or
create a new `verdicts.js`):

```js
export const GUEST_VERDICTS_KEY = "guestVerdicts";

export function loadGuestVerdicts() { /* read + parse GUEST_VERDICTS_KEY */ }
export function saveGuestVerdicts(verdicts) { /* write GUEST_VERDICTS_KEY */ }
export function parseVerdictFragment() { /* parse #verdicts=BASE64 from URL hash */ }
export async function fetchUserVerdicts() { /* GET /compass/verdicts, 401 returns [] */ }
```

Priority chain in a `VerdictContext` (or added to `CompassContext`) mirrors the existing
compass loading logic:

1. Fragment in URL (`#verdicts=...`) — parse + cache to localStorage, strip hash
2. Logged-in session — fetch from `/compass/verdicts` API
3. Guest — read from `guestVerdicts` localStorage key

### ev-ui Changes

The `StanceAccordion` component (ev-ui, consumed by Essentials) is where verdict badges
will render — showing agree/disagree/rank for quotes under each topic's stance list.
Add a `verdicts` prop (array of verdict objects) to `StanceAccordion`, or a new
`VerdictBadge` sibling component. Bump ev-ui to the next minor version
(currently v0.1.41, so v0.1.42+).

Both CompassV2 and Essentials will need their ev-ui references updated to pick up the
new version.

---

## Recommended Stack (New Additions Only)

| Item | Location | What | Why |
|------|----------|------|-----|
| `wrangler.toml` | ReadRank repo root | Cloudflare Pages SPA config | Required for `readrank.empowered.vote` deployment |
| `.npmrc` | ReadRank repo root | `//npm.pkg.github.com/:_authToken=${NPM_TOKEN}` | Required for ev-ui in Cloudflare Pages CI |
| `VITE_API_URL` env var | Cloudflare dashboard | `https://api.empowered.vote` | Connects standalone app to backend |
| `compass.quote_verdicts` table | EV-Backend DB | GORM model + AutoMigrate | Stores logged-in user verdicts server-side |
| `/compass/verdicts` endpoints | `internal/compass/` | POST/GET/DELETE handlers + routes | Server-side verdict CRUD |
| `guestVerdicts` localStorage key | ReadRank + Essentials | Shared key name constant | Cross-app guest verdict handoff |
| Verdict utility functions | Essentials `src/lib/` | load/save/fetch/parse verdicts | Mirror of existing compass utils |
| ev-ui v0.1.42+ | ev-ui repo | `verdicts` prop on `StanceAccordion` | Verdict badge display in politician profiles |

---

## What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| New state management library in Essentials | React Context + local state is sufficient; Zustand not needed for verdict read | Direct localStorage read via utility function |
| New animation library in ReadRank | Framer Motion already covers all needed animations | Framer Motion ^12.35.0 |
| Shared iframe / postMessage infrastructure | Overkill; URL fragment bridge is simpler and proven; Safari ITP is a real concern with iframe-based cross-site storage | URL fragment handoff |
| Third-party sync service (Liveblocks, Pusher) | Nonprofit budget; overkill for a verdict list | Backend API endpoint |
| New PostgreSQL schema (`readrank.`) | Verdicts are user-compass data; `compass.` is the correct semantic home, avoids cross-schema JOINs | Add to `compass.quote_verdicts` |
| document.domain manipulation | MDN explicitly states it does NOT affect localStorage origin checks | URL fragment handoff |
| BroadcastChannel for cross-app sync | Same-origin only; subdomains are different origins | URL fragment handoff |

---

## Installation

```bash
# In the new standalone ReadRank repo (copied from EV-prototypes/read-rank):
npm install @chrisandrewsedu/ev-ui@latest
npm install framer-motion@^12.35.0
# No other new installs
```

```bash
# In essentials:
npm install @chrisandrewsedu/ev-ui@latest
# No other new installs — verdict utils are plain JS, no runtime deps
```

```bash
# In ev-ui (for verdict badge component — no new runtime deps):
# Bump package.json version to 0.1.42
npm run build
# Publish to GitHub npm registry
```

---

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| framer-motion ^12.x | React 19 | No breaking changes in v12; confirmed on npm changelog |
| @use-gesture/react ^10.x | React 19 | No known issues with React 19 |
| zustand ^5.x | React 19 | Officially supports React 19; persist middleware API unchanged |
| @dnd-kit/core ^6.x | React 19 | Current in EV-prototypes; no issues reported |
| tailwindcss ^4.x | Vite 7 | Already proven across all EV apps |
| ev-ui (GitHub registry) | React 19 + Vite 7 | Essentials on ^0.1.41; update to ^0.1.42+ for verdict props |

---

## Sources

- MDN Web API: `Window.localStorage` — origin isolation per scheme+host+port confirmed
- MDN: Same-origin policy — document.domain does NOT affect storage APIs
- npmjs.com: `framer-motion` — latest 12.35.2, published 2026-03-10 (verified)
- Cloudflare Pages docs — `not_found_handling = "single-page-application"` in wrangler.toml
- `/Users/chrisandrews/Documents/GitHub/EV-prototypes/read-rank/package.json` — current deps verified
- `/Users/chrisandrews/Documents/GitHub/essentials/src/lib/compass.js` — URL fragment bridge pattern, `GUEST_COMPASS_KEY` convention
- `/Users/chrisandrews/Documents/GitHub/essentials/src/contexts/CompassContext.jsx` — fragment > API > localStorage priority chain
- `/Users/chrisandrews/Documents/GitHub/EV-prototypes/read-rank/src/store/useReadRankStore.ts` — Zustand persist key `readrank-storage` confirmed
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/routes.go` — existing `/quotes` GET endpoint confirmed
- `/Users/chrisandrews/Documents/GitHub/essentials/package.json` — ev-ui ^0.1.41, no Zustand dep confirmed

---
*Stack research for: v2026.3.4 Read & Rank Integration*
*Researched: 2026-03-11*
