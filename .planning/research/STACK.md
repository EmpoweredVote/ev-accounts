# Technology Stack

**Project:** v2026.3.6 Read & Rank Redesign
**Researched:** 2026-03-14
**Confidence:** HIGH (all findings from direct source code inspection of EV-readrank, CompassV2, essentials, and EV-Backend repos)

---

## Context: What Is and Is Not New

The prior STACK.md (v2026.3.4) covers the standalone extraction, verdict storage backend, and fragment bridge. All of that is already shipped. This document covers **only what is new for v2026.3.6**: unified evaluate+rank flow, practice round, coach marks, location-based quote filtering, results polish, visual redesign, and chrome cleanup.

**Existing stack that remains unchanged:**
- React 19 + TypeScript + Vite 7 + Tailwind CSS 4
- framer-motion ^12.23.26
- @use-gesture/react ^10.3.1
- @dnd-kit/core ^6.3.1 + @dnd-kit/sortable ^10.0.0 + @dnd-kit/utilities ^3.2.2
- zustand ^5.0.9 with persist middleware
- react-icons ^5.5.0
- @chrisandrewsedu/ev-ui ^0.1.49 (SiteHeader, StanceAccordion, verdictsByQuote)
- Zustand persist key `ev_readrank` (migrated from `readrank-storage` in v2026.3.4)
- Go backend + PostGIS + `/essentials/quotes` + `/essentials/politicians/search` endpoints

---

## Section 1: Unified Evaluate+Rank Flow

### No New Libraries Required

The current flow has three separate phase components: `EvaluationPhase`, `RankingPhase`, and `ResultsPhase`. The unified flow collapses evaluation and ranking into a single interaction — swipe to agree/disagree, then immediately drag-to-rank the agreed quotes in the same view rather than proceeding to a separate `RankingPhase`.

The existing `@dnd-kit/sortable` already handles drag-to-rank on the agreed quotes sidebar (`AgreedQuotesSidebar.tsx`). The `EvaluationPhase` already renders `AgreedQuotesSidebar` on desktop. The unified flow means:

1. `RankingPhase` is removed as a standalone phase.
2. The `'ranking'` value is removed from the `Phase` union type in `useReadRankStore.ts`.
3. When all quotes are evaluated, `setPhase('results')` is called directly — no intermediate ranking screen.
4. The sidebar remains visible during evaluation to show live agreed-quote ranking in real time.

The `@dnd-kit` packages already do this. The `reorderAgreedQuotes` action already exists in the store. No new dependencies.

**State machine change:** `Phase` type shrinks from `'hub' | 'evaluation' | 'ranking' | 'results'` to `'hub' | 'practice' | 'evaluation' | 'results'`. The `'practice'` phase is new (see Section 2).

**Confidence:** HIGH — `AgreedQuotesSidebar.tsx`, `useReadRankStore.ts`, `EvaluationPhase.tsx`, and `RankingPhase.tsx` all inspected directly.

---

## Section 2: Practice Round (Pizza Toppings)

### Static Local Data — No New Libraries

The practice round shows 3-5 fun non-political quotes (e.g., pineapple on pizza) so users learn swipe mechanics before encountering real political content. This is pure UI state with static hardcoded data.

**Implementation:** A new `practiceData.ts` file in `src/data/` with hardcoded practice quotes. A new `PracticePhase` component (or `EvaluationPhase` reused with a `isPractice: boolean` prop). The store gains a `'practice'` phase value. On completing the practice round, `setPhase('evaluation')` transitions to real content.

**No new npm packages.** Practice data is static — not fetched from the API. The same swipe mechanics, `QuoteCard`, and `AgreedQuotesSidebar` components render practice quotes with no changes to those components.

**localStorage consideration:** Practice progress should NOT persist across page loads. The Zustand `partialize` function already controls what persists; exclude `practicePhase` from the serialized state.

**Confidence:** HIGH — all referenced components inspected directly. Static data pattern is trivially correct.

---

## Section 3: Coach Marks

### Use CoachMark from CompassV2 — NOT From ev-ui

The `CoachMark` component and `useCoachMark` hook are in `CompassV2/src/components/CoachMark.jsx`. They are NOT published to ev-ui (confirmed by inspecting `ev-ui/package.json` and the installed `@chrisandrewsedu/ev-ui` dist — no `CoachMark` export). PROJECT.md v2026.4 says "Reusable CoachMark component with SVG mask spotlight overlay" was built, but it lives in CompassV2 only.

**Option A (recommended): Copy CoachMark into EV-readrank.** Copy `CompassV2/src/components/CoachMark.jsx` to `EV-readrank/src/components/CoachMark.tsx` (convert to TypeScript). The component has zero external dependencies beyond `react`, `react-dom` (createPortal), and `framer-motion` — all already in the EV-readrank package. This is a 230-line file.

**Option B: Publish CoachMark to ev-ui as v0.1.51.** Adds a cross-repo coordination step — ev-ui must be built and published before EV-readrank can use it. Only worth the overhead if other apps (Essentials) also need coach marks in this milestone. They don't.

**Recommendation:** Option A. Copy directly into EV-readrank. Single-repo, no publishing lag, TypeScript conversion is straightforward.

**Dependencies the copied component needs:**
- `framer-motion` — already in package.json
- `react-dom` (createPortal) — already a peer dep via `react-dom ^19.2.0`

**useCoachMark hook behavior:** Persists dismiss state to `localStorage` under a per-coachmark key (e.g., `ev_rr_coach_first_issue`). Dismissed state is intentionally permanent — the coach mark never re-shows after first dismiss. This is the same behavior as in CompassV2.

**No new npm packages required.**

**Confidence:** HIGH — `CoachMark.jsx` read directly, dependencies verified against `EV-readrank/package.json`.

---

## Section 4: Location-Based Quote Filtering

### New Env Var + One New npm Dependency + New Backend Endpoint

This is the only section that requires a new npm package. Location-based filtering means: user enters their address in Read & Rank, the app finds which politicians represent them (via PostGIS geofence matching), and then filters the displayed quotes to show only those politicians' quotes.

**Frontend:**

The `@googlemaps/js-api-loader` package is already used in `essentials` (version `^2.0.2`), which loads the Google Places Autocomplete library. Read & Rank needs the same package.

```
npm install @googlemaps/js-api-loader@^2.0.2
```

The `useGooglePlacesAutocomplete` hook from `essentials/src/hooks/useGooglePlacesAutocomplete.js` should be copied to `EV-readrank/src/hooks/useGooglePlacesAutocomplete.ts` (TypeScript port). It is a 70-line hook with no external runtime deps beyond the dynamically-loaded Google Maps script.

**New env var:** `VITE_GOOGLE_MAPS_API_KEY` — same key already used by Essentials. Add to Cloudflare Pages environment variables for EV-readrank. The Google Maps free tier (28K requests/month, shared across apps) is the existing budget constraint.

**Backend — new filtered endpoint:**

`GET /essentials/quotes` already accepts `?politician_id=UUID` for per-politician filtering. Location-based filtering requires a different query shape: given a lat/lng (from the geocoding step after address selection), find all politician IDs whose geofence boundaries contain that point, then return quotes for those politicians only.

There are two options:

**Option A (recommended): New query parameter on existing `/essentials/quotes`.**
Add `?address=ENCODED_ADDRESS` or `?lat=X&lng=Y` to `GetQuotes`. The handler geocodes the address (or uses the lat/lng directly), calls `FindGeoIDsByPoint` (already exists in `geofence_lookup.go`), fetches the politician IDs from those geofences, and filters the quotes SQL accordingly. This reuses all existing infrastructure with a minimal handler change.

**Option B: Frontend calls `/essentials/politicians/search` first, then filters quotes client-side.**
The `POST /essentials/politicians/search` endpoint already returns politicians for an address. Read & Rank could call this first to get a list of politician IDs, then filter the already-fetched `quotes` array client-side by `quote.candidateId`. No backend changes required. This approach works when the full quote set has already been fetched.

**Recommendation:** Option B for MVP. The full quote set is already cached in `cachedData` in `src/data/api.ts`. Calling `POST /essentials/politicians/search` returns politician IDs; filtering `quotes` client-side by matching `quote.candidateId` against those IDs is O(n) and fast for the current quote count (~61 quotes). If the quote database grows substantially (>500), revisit with Option A.

**Option B requires no backend changes and no new Go packages.** It does require the `POST /essentials/politicians/search` endpoint to be accessible from `readrank.empowered.vote` — verify CORS allows this subdomain (it was added in v2026.3.4; confirm it covers all `/essentials/*` routes, not just `/essentials/quotes`).

**CSS for autocomplete dropdown:** Copy the `.pac-container` style override from `essentials/src/index.css` to `EV-readrank/src/index.css` so the Google Places dropdown matches the EV visual language (Manrope font).

**Confidence:** HIGH for Option B — client-side filter against existing data confirmed feasible from direct inspection of `api.ts` (cached response shape) and `useReadRankStore.ts` (Quote interface includes `candidateId`). Option A confidence is MEDIUM — requires Go handler change not yet implemented; pattern is straightforward but untested.

---

## Section 5: Results Reveal Polish

### Framer Motion Stagger — No New Libraries

The dramatic reveal (quotes appearing one-by-one with animation, candidate identities hidden until reveal completes) is handled entirely with Framer Motion stagger sequences. The existing `ResultsPhase.tsx` already uses `initial={{ opacity: 0, y: 24 }}` with `transition={{ delay: index * 0.08 }}` stagger. The redesign enhances this with:

- A `useAnimate` hook from Framer Motion (already imported via `framer-motion` package) for orchestrated multi-step reveals.
- `AnimatePresence` from Framer Motion for mount/unmount transitions (already used in CompassV2).
- Possibly `useMotionValue` + `animate` for a progress-bar reveal effect (already used in `EvaluationPhase.tsx`).

All of these are within the existing `framer-motion` import. No new animation library needed.

**Confidence:** HIGH — Framer Motion API confirmed from direct code inspection.

---

## Section 6: Visual Redesign

### No New Libraries

The visual redesign uses the existing design system:
- **Colors:** `ev-coral` (#ff5740), `ev-muted-blue` (#00657c), `ev-light-blue` (#59b0c4), `ev-yellow` (#fed12e)
- **Fonts:** Manrope (body), Fraunces (serif display) — already loaded in `index.css`
- **Utility:** Tailwind CSS 4 (already installed)

The `@tailwindcss/forms` and `@tailwindcss/typography` plugins are already in `devDependencies`.

If the redesign introduces new custom CSS variables or keyframe animations, they go in `src/index.css` — same pattern as the current file.

**No new npm packages.**

---

## Section 7: Chrome Cleanup

### Deletions Only

Remove `ProgressHeader` and `AnimationOptionsPage` components. Update `App.tsx` to remove the `/animation-options` route and the `<ProgressHeader />` render. These are pure deletions — no new dependencies.

---

## Recommended Stack (New Additions Only)

| Item | Location | What | Why |
|------|----------|------|-----|
| `@googlemaps/js-api-loader` ^2.0.2 | EV-readrank `dependencies` | Google Places Autocomplete | Location-based quote filtering — same package already in Essentials |
| `VITE_GOOGLE_MAPS_API_KEY` env var | Cloudflare Pages EV-readrank dashboard | Google Maps API key | Required for Places Autocomplete; same key as Essentials |
| `useGooglePlacesAutocomplete.ts` | `EV-readrank/src/hooks/` | Typed copy of Essentials hook | Address input for location filtering |
| `.pac-container` CSS | `EV-readrank/src/index.css` | Places dropdown styling | Manrope font, EV card style |
| `CoachMark.tsx` + `useCoachMark` | `EV-readrank/src/components/` | TypeScript port from CompassV2 | Practice round onboarding + first-issue coach marks |
| `practiceData.ts` | `EV-readrank/src/data/` | Static pizza-topping quotes | Practice round — no API call needed |
| `'practice'` in `Phase` union | `useReadRankStore.ts` | New phase state value | Practice round routing in `PhaseContainer` |

---

## What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| New animation library (GSAP, anime.js, etc.) | Framer Motion already handles all required animations — stagger, spring, presence transitions | Framer Motion `useAnimate`, `AnimatePresence`, `useMotionValue` |
| `@react-spring/web` for additional animations | Overkill; already using framer-motion throughout; mixing animation libraries creates maintenance debt | Framer Motion |
| Publish CoachMark to ev-ui before this milestone | Cross-repo coordination delay; Essentials doesn't need it this milestone | Copy directly into EV-readrank |
| `?lat=X&lng=Y` backend endpoint for quote filtering | Not needed for MVP; client-side filter against cached quote set is sufficient for current data size | Client-side filter using politician IDs from existing `/essentials/politicians/search` |
| `react-spring` | ev-ui peer dep; not needed in EV-readrank directly | n/a |
| New state management layer for location state | Zustand store already handles all app state | Extend existing `useReadRankStore` or use local component state for transient address input |
| `@types/googlemaps` | The `@googlemaps/js-api-loader` package ships its own TypeScript types; no separate types package needed | Built-in types from `@googlemaps/js-api-loader` |

---

## Installation

```bash
# In EV-readrank — only one new package:
npm install @googlemaps/js-api-loader@^2.0.2
```

```bash
# In Cloudflare Pages EV-readrank project — add environment variable:
VITE_GOOGLE_MAPS_API_KEY=<same value as essentials project>
```

No changes to EV-Backend package dependencies. No changes to ev-ui. No changes to Essentials or CompassV2.

---

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| `@googlemaps/js-api-loader` ^2.0.2 | React 19 + Vite 7 | Framework-agnostic loader; works with any JS app; already proven in Essentials |
| `framer-motion` ^12.x | React 19 | `useAnimate` API added in v10.x; `AnimatePresence` stable; no breaking changes for planned usage |
| `@dnd-kit/sortable` ^10.x | React 19 | `useSortable` and `DndContext` confirmed working in current EV-readrank build |
| CoachMark (copied) | React 19 + framer-motion | Depends only on `react`, `react-dom`, `framer-motion` — all present |

---

## Sources

- `/Users/chrisandrews/Documents/GitHub/EV-readrank/package.json` — current dependencies confirmed
- `/Users/chrisandrews/Documents/GitHub/EV-readrank/src/store/useReadRankStore.ts` — Phase type, IssueProgress shape, AgreedQuotesSidebar integration
- `/Users/chrisandrews/Documents/GitHub/EV-readrank/src/components/EvaluationPhase.tsx` — AgreedQuotesSidebar already rendered on desktop; handleComplete already calls setRankedQuotes then setPhase
- `/Users/chrisandrews/Documents/GitHub/EV-readrank/src/components/PhaseContainer.tsx` — phase routing, verdictSync on results
- `/Users/chrisandrews/Documents/GitHub/EV-readrank/src/data/api.ts` — cachedData shape, fetchQuotesData, Quote.candidateId field
- `/Users/chrisandrews/Documents/GitHub/EV-readrank/src/App.tsx` — ProgressHeader, AnimationOptionsPage usage confirmed (to delete)
- `/Users/chrisandrews/Documents/GitHub/CompassV2/src/components/CoachMark.jsx` — 230 lines, deps: react, react-dom, framer-motion only; useCoachMark localStorage key pattern
- `/Users/chrisandrews/Documents/GitHub/essentials/src/hooks/useGooglePlacesAutocomplete.js` — @googlemaps/js-api-loader usage, Places Autocomplete pattern
- `/Users/chrisandrews/Documents/GitHub/essentials/package.json` — `@googlemaps/js-api-loader` ^2.0.2 confirmed
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/routes.go` — `/politicians/search` POST endpoint confirmed
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/geofence_lookup.go` — `FindGeoIDsByPoint` function exists
- `/Users/chrisandrews/Documents/GitHub/ev-ui/package.json` — v0.1.50; CoachMark NOT exported (confirmed absent from exports)

---
*Stack research for: v2026.3.6 Read & Rank Redesign*
*Researched: 2026-03-14*
