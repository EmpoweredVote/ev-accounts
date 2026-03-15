# Domain Pitfalls

**Domain:** Swipe-card quote evaluation app — adding unified evaluate+rank flow, practice round onboarding, location-based filtering, and visual redesign to existing app
**Researched:** 2026-03-14
**Scope:** v2026.3.6 Read & Rank Redesign milestone
**Overall confidence:** HIGH — all critical pitfalls derived from direct codebase inspection of `useReadRankStore.ts`, `PhaseContainer.tsx`, `EvaluationPhase.tsx`, `RankingPhase.tsx`, `ResultsPhase.tsx`, and `api.ts`, supplemented by Zustand/Framer Motion/dnd-kit official documentation and community issue trackers.

---

## Critical Pitfalls

Mistakes that cause rewrites or major issues.

---

### Pitfall 1: Zustand Persist Version Not Bumped When Data Shape Changes

**What goes wrong:** The store's `version` is currently `1` in `useReadRankStore.ts`, and the `migrate` function is a no-op passthrough (`return persistedState as ReadRankState`). The redesign removes `badgeAssignments`, `BadgeType`, and the `'ranking'` phase, adds `practiceComplete` and location filter fields, and restructures `IssueProgress`. When existing users load the redesigned app, Zustand's `persist` middleware reads the stale localStorage shape and shallow-merges it with the new initialState. Old nested keys for `badgeAssignments.diamond` survive inside `issueProgress` entries. The app may silently operate on structurally invalid state rather than crashing.

**Why it happens:** Zustand's default merge is a shallow `Object.assign` at the top level. Nested objects like `issueProgress[id]` are not deep-merged — the old shape of each `IssueProgress` entry (which includes `badgeAssignments` and `phase: 'ranking'`) replaces the new shape entirely. The current no-op migrate function (`return persistedState as ReadRankState`) means Zustand never transforms old data regardless of version.

**Consequences:** Practice round skipped for returning users (`phase` from old state is `'evaluation'` or `'ranking'`, not `'hub'`). App tries to render deleted `RankingPhase` component if old `issueProgress[id].phase === 'ranking'`. TypeScript type errors at runtime if `badgeAssignments` is accessed on the new shape.

**Prevention:**
- Bump `version` from `1` to `2` before any state shape changes ship.
- Write an explicit migrate function: `(persistedState, version) => { if (version < 2) { return initialState; } return persistedState; }` — a clean reset is safer than attempting to map badge state to rank order.
- Update `partialize` to exclude all legacy fields (`issueTitle`, `questionText`, `topicId`, `badgeAssignments`) from being written to storage going forward.
- Test by manually setting `localStorage['ev_readrank']` to the old v1 shape in DevTools and loading the redesigned build. Verify it resets cleanly to `hub` phase and shows the practice round.

**Detection:** App loads into `evaluation` or `ranking` phase instead of `hub`. Practice round does not appear for a user who has old v1 state. TypeScript build errors about missing `badgeAssignments` property once the type is removed.

**Phase:** Store refactor — version bump is the very first task, gating all other changes.

---

### Pitfall 2: Practice Round State Leaking Into Real Verdict POST

**What goes wrong:** Practice quotes (pizza toppings) are stored in `issueProgress` under a synthetic key like `'practice'`. When the user completes the real flow and `phase` reaches `'results'`, `PhaseContainer` fires `postVerdicts(issueProgress)`. The current `postVerdicts` utility iterates all entries in `issueProgress` without filtering. The practice entry — with fake quote IDs — is included in the POST payload to `POST /compass/verdicts`. The backend either rejects the entire batch (400 on invalid quote ID) or silently stores fake verdicts that later appear in the Essentials politician profile StanceAccordion.

**Why it happens:** `PhaseContainer.tsx` passes the entire `issueProgress` map to `postVerdicts`. There is no field on `IssueProgress` that marks an entry as practice/non-canonical. The verdict sync fires once (guarded by `hasSynced` ref) but does not discriminate by issue type.

**Consequences:** Real user verdicts may be lost if the backend rejects a batch containing invalid IDs. Pizza topping quote text appears in the Essentials politician profile view. The cross-app verdict fragment bridge encodes practice verdicts into the URL, corrupting the Essentials cache.

**Prevention:**
- Add `isPractice: boolean` to `IssueProgress` interface; set it `true` for the practice entry when created.
- Filter practice entries in `postVerdicts`: `const realProgress = Object.fromEntries(Object.entries(issueProgress).filter(([_, v]) => !v.isPractice));`
- Alternatively, store practice state in a completely separate, non-persisted store slice (or sessionStorage key) that is never passed to `postVerdicts`.
- Clear the practice entry from `issueProgress` immediately when transitioning to the real IssueHub, before results are possible.
- Add the same `isPractice` guard to the verdict fragment encoder in `verdictFragment.ts`.

**Detection:** `POST /compass/verdicts` returns 400 with unrecognized quote ID. Network tab shows pizza topping quote IDs in the POST body. Essentials politician profiles show "pizza topping" text in the StanceAccordion under a politician's quotes.

**Phase:** Practice round architecture design — must be built in before implementation, not patched after.

---

### Pitfall 3: Unified Flow Breaks the `nextQuote` Phase Transition and `Phase` Type

**What goes wrong:** The current `nextQuote()` store action explicitly sets `phase: 'ranking'` when the card stack is exhausted. Removing the ranking phase without rewriting `nextQuote` leaves the store transitioning to a phase that no longer exists. If `'ranking'` is removed from the `Phase` union type, TypeScript flags every callsite — but there are also runtime switch statements in `PhaseContainer` (`case 'ranking': return <RankingPhase />`) that would silently hit the `default: return <IssueHub />` branch, teleporting the user back to the hub mid-flow.

**Why it happens:** `Phase = 'hub' | 'evaluation' | 'ranking' | 'results'` is used in the store, PhaseContainer, `setPhase`, and `IssueProgress.phase`. The current `EvaluationPhase.handleComplete` already forks by device type (`isMouseDevice` skips ranking entirely and goes to results). Removing the fork while the type still includes `'ranking'` leaves dead code paths. Removing the type without updating every callsite causes compile-time and runtime errors simultaneously.

**Consequences:** App silently returns to IssueHub when last card is swiped instead of advancing to results. Or TypeScript build fails entirely and nothing ships. Or the `RankingPhase` component is deleted but still referenced in `PhaseContainer`, crashing the build.

**Prevention:**
- Remove `'ranking'` from the `Phase` union type first; use TypeScript errors to find every callsite (`PhaseContainer`, `setPhase`, `IssueProgress`, `nextQuote`, `handleComplete`).
- Rewrite `nextQuote` to transition `evaluation → results` directly (or to an inline review state that does not require a separate phase key).
- Delete `RankingPhase.tsx` and `BadgeIcons.tsx` in the same commit that removes the type entry — do not leave orphaned files.
- The device-type branch in `EvaluationPhase.handleComplete` can be removed entirely once ranking is unified.

**Detection:** TypeScript errors on `phase === 'ranking'` after type removal. App returns to hub after last evaluation card. Blank screen where RankingPhase used to render.

**Phase:** Store + type refactor — must precede all UI component work.

---

### Pitfall 4: Location Filter Creates a Zero-Quotes Dead End

**What goes wrong:** A user enters their address, the app filters quotes to only show politicians representing that address, but the PostGIS geofence query returns politicians who have no quotes in the `compass.quotes` table (or returns no politicians at all for addresses outside current geofence coverage). The evaluation phase starts with `quotesToEvaluate.length === 0`. The current `EvaluationPhase` renders the "Done" empty state immediately, showing `0 agreed · 0 disagreed` with a "See Your Results" button. The user sees a confusing blank results page with no explanation.

**Why it happens:** The `selectIssue` store action takes a `quotes` array directly. If the caller passes an empty array (because the location filter returned nothing), `createEmptyIssueProgress` initializes with no quotes. The evaluation phase has no guard preventing entry with zero quotes. The current `GET /essentials/quotes` endpoint has a `politician_id` filter but no location-scoped bulk filter that would indicate coverage status.

**Consequences:** Users who enter an address in an unsupported area see an unexplained empty experience. They cannot recover without a page refresh, and the empty `issueProgress` entry is now persisted to localStorage.

**Prevention:**
- Guard in IssueHub (or wherever the location filter decision is made): if `filteredQuotes.length < 2`, do not allow entry into evaluation. Show an inline message: "No quotes available for your area. [Show all quotes instead]."
- The location-scoped backend endpoint should include a `total_quotes` count in its response so the frontend can gate entry before even calling `selectIssue`.
- Gracefully degrade: if location filter yields fewer than the minimum threshold for an issue, offer the unfiltered quote set with a note ("Showing all quotes — no local candidates found").
- Test with a known address that has politicians in the geofences table but none of those politicians have quotes in `compass.quotes` (this is the typical edge case for newly imported officials).

**Detection:** `quotesToEvaluate.length === 0` in evaluation phase. Results page shows all-zero stats with empty card list. QA test: enter a ZIP code for a county that has geofences but no associated politician quotes.

**Phase:** Location filter feature — guard must be designed in from the start, not added as a post-ship patch.

---

### Pitfall 5: `postVerdicts` Fires Multiple Times Due to Dependency Array Including `issueProgress`

**What goes wrong:** The current `PhaseContainer` effect fires `postVerdicts` when `phase === 'results'` and guards with a `hasSynced` ref. But the effect's dependency array includes `issueProgress`. If `issueProgress` changes after the `results` phase is reached — for example, because the location filter or practice round adds/modifies an entry while viewing results — the effect re-fires. The `hasSynced` ref resets if `PhaseContainer` unmounts and remounts (e.g., the user navigates to `/candidate/:id/alignment` and back). The result is duplicate POST requests.

**Why it happens:** `useEffect` re-runs whenever any value in its dependency array changes. Including `issueProgress` (a frequently-mutating object) in the deps of a side-effect that should fire exactly once is structurally fragile. Component refs reset on unmount.

**Consequences:** Duplicate verdict POSTs. If the backend upserts on `(user_id, quote_id)`, duplicates are harmless but wasteful. If it inserts, duplicate rows are created.

**Prevention:**
- Move the sync trigger to fire on the `results` phase transition only — not on re-renders of the same phase. Pattern: capture a `prevPhase` ref and fire only when `prevPhase !== 'results' && phase === 'results'`.
- Use a persisted store flag (`verdictsSynced: boolean`) rather than a component ref. Check it before POSTing; set it immediately before the POST call (not after the Promise resolves, to prevent race conditions on re-render).
- Filter practice entries before passing to `postVerdicts` (same guard as Pitfall 2).

**Detection:** Network tab shows multiple POSTs to `/compass/verdicts` within the same results session. Backend logs show duplicate verdict inserts within seconds of each other.

**Phase:** Verdict sync refactor — address in the same phase as practice round isolation.

---

## Moderate Pitfalls

---

### Pitfall 6: Coach Marks Fire Before First Card Is in the DOM

**What goes wrong:** The practice round completes and the user enters the first real issue. A coach mark is triggered by a flag like `hasSeenCoachMarks: false` in the store, firing on component mount. The coach mark needs to position a spotlight overlay on the first swipe card using `getBoundingClientRect()`. But `fetchQuotesData()` has not yet resolved — `quotesToEvaluate` is empty, the card is not rendered, and `getBoundingClientRect()` returns a zeroed rect. The spotlight appears in the wrong position or does not appear at all.

**Why it happens:** The existing CompassV2 `CoachMark` component (used in v2026.4) relies on a DOM element being present when it mounts. The evaluation phase shows a loading state while data fetches. Coach mark logic tied to component mount (`useEffect([], [])`) fires before the async data resolves.

**Prevention:**
- Gate coach mark activation behind `quotesToEvaluate.length > 0` and a post-render timing pass. Use `useLayoutEffect` (not `useEffect`) with a `requestAnimationFrame` wrapper after the first card renders to ensure the DOM is ready.
- Do not trigger coach marks in the effect that fires on initial mount; trigger them in the effect that fires when `currentQuote` transitions from `undefined` to a real quote object.
- Test on a throttled (Slow 3G) connection in DevTools to simulate the async gap.

**Phase:** Coach mark implementation phase.

---

### Pitfall 7: Practice Round Teaches the Wrong Mechanic If Unified Flow Interaction Is Not Locked First

**What goes wrong:** The practice round is designed and implemented to teach swipe-left/swipe-right. But the unified evaluate+rank flow may introduce a new inline reordering mechanic (drag-to-reorder within the card stack, or numbered priority tapping). If the practice round teaches the old mechanic and the real flow has a different one, users arrive at the real issue confused. The practice round becomes misinformation rather than onboarding.

**Why it happens:** The practice round is built while the unified flow interaction model is still being designed. The two features are developed in parallel without a design dependency being enforced.

**Prevention:**
- Define the exact unified flow interaction model (what happens after agreeing — does a mini-rank sidebar appear? does position in the stack become the rank?) before writing a single line of practice round code.
- Keep practice round content (pizza topping quotes and tutorial script) in a static config object separate from API data so it can be updated cheaply without a full rebuild.
- Do not mark the practice round as "done" until it has been tested back-to-back with the final unified flow to confirm the mechanics match.

**Phase:** Unified flow design must be locked before practice round implementation begins. Treat as a hard dependency.

---

### Pitfall 8: Address Input in Read & Rank Diverges from Essentials Geocoding Path

**What goes wrong:** Essentials uses Google Maps Places autocomplete + a backend PostGIS `ST_Covers` query to match politicians to an address. If Read & Rank implements a parallel geocoding path (client-side `navigator.geolocation`, a different Google Maps API surface, or raw lat/lng passed to a new endpoint), the two apps may return different politician sets for the same address. A politician appears for a user in Essentials but their quotes do not appear in the Read & Rank location filter — confusing and undermining the integration story.

**Why it happens:** Read & Rank is a standalone app. Without explicit coordination, new address input features tend to get built independently rather than reusing the existing backend search logic.

**Prevention:**
- Reuse the existing backend search path: Google Maps Places autocomplete (same legacy `Autocomplete` class as Essentials) → send `place_id` or validated lat/lng to a backend endpoint → backend runs the same ST_Covers geofence query and returns politician IDs.
- Do not build a parallel geofence query in a new endpoint with different PostGIS parameters. Divergence will surface as coverage inconsistencies that are extremely hard to debug.
- Confirm the Google Maps API key is configured in the Read & Rank Cloudflare Pages environment variables (`VITE_GOOGLE_MAPS_KEY`) before implementation begins.
- The existing `GET /essentials/search` (or the POST equivalent) already returns politician IDs from the geofence. Calling this with the address and extracting the politician IDs is less work than building a new location endpoint.

**Phase:** Location filter backend design — must be decided before frontend implementation begins.

---

### Pitfall 9: Visual Redesign Breaks Tailwind Class Purging in Production

**What goes wrong:** The redesign introduces new color tokens or conditionally-constructed class names (e.g., `\`bg-${variantColor}\``). Tailwind's JIT compiler scans source files at build time for literal class strings. Dynamically constructed classes are purged from the production CSS bundle. The redesign looks correct in dev (JIT hot-reloads include all classes seen at runtime) but key colors or spacing values disappear in the Cloudflare Pages production build.

**Why it happens:** The current codebase mixes Tailwind utility classes with inline `style={{ }}` props, using inline styles for all EV brand colors (ev-coral, ev-muted-blue, etc.) and Tailwind only for layout. If the redesign moves more dynamic styling into Tailwind class construction, purge issues will appear. This is a well-documented Tailwind pitfall.

**Prevention:**
- Use complete literal class strings: `bg-ev-coral` not `'bg-' + colorVar`.
- For values that vary at runtime (brand colors, variant colors), continue using inline `style={{ }}` props as the existing codebase does.
- After every non-trivial CSS change, run `npm run build` locally and verify the production output in `dist/` before pushing. Do not rely solely on dev server appearance.
- Add a one-line check to the deployment checklist: "Verify colors and spacing in a production build (`npx serve dist`) before merging."

**Phase:** Visual redesign phase. Post-build local verification before every deploy.

---

### Pitfall 10: AnimatePresence Gets Stuck on Rapid Phase Transitions

**What goes wrong:** The redesign introduces dramatic results-reveal animations and phase transitions (practice → hub → evaluation → results). If state changes fire in rapid succession — for example, practice completes, immediately pre-fetching real quotes triggers another state update, and the user clicks into an issue before the hub animation finishes — Framer Motion's `AnimatePresence` can get stuck and stop properly removing or adding elements. This is a documented open bug in the Framer Motion GitHub repository (issues #2023 and #2554, both still open as of 2025).

**Why it happens:** `AnimatePresence` tracks children by `key`. When a parent component with an `AnimatePresence` boundary re-renders due to rapid state changes, exit animations can be interrupted mid-flight and the cleanup callback never fires, leaving ghost DOM elements or preventing new children from mounting.

**Prevention:**
- Assign stable, unique `key` props to every direct child of `AnimatePresence` — never use array index.
- Do not trigger data fetches synchronously inside `onAnimationComplete` callbacks. Defer with `setTimeout(fn, 0)` or `useEffect` with deps.
- Batch phase-change state updates: instead of calling `setPhase` then `setQuotes` in sequence, update both in a single `set()` call in the store to avoid intermediate render states.
- Test rapid phase transitions deliberately (complete practice round → immediately click first real issue) with React DevTools Profiler enabled.

**Phase:** Animation/results polish phase; also relevant to unified flow phase machine design.

---

## Minor Pitfalls

---

### Pitfall 11: Module-Level `cachedData` in `api.ts` Does Not Respect Location Filter

**What goes wrong:** `src/data/api.ts` uses a module-level variable `let cachedData: QuotesResponse | null = null` that persists for the browser tab's lifetime. Once any quotes fetch resolves, all subsequent calls return the same cached response — including the unfiltered full dataset. If the user enters a location, the cache returns the old unfiltered data. If the user clears their location after filtering, the cache returns the filtered data. The location filter appears broken.

**Prevention:**
- Replace the module-level cache with a keyed cache: `const cache = new Map<string, QuotesResponse>()` where the key is the location parameter (or `'unfiltered'` for the default case).
- Expose a `clearCache()` function that is called when the user changes or clears their location.
- This is a small change that prevents a confusing UX defect.

**Phase:** Location filter implementation phase.

---

### Pitfall 12: Removing `ProgressHeader` and `AnimationOptionsPage` Without Cleaning Up Routes

**What goes wrong:** `App.tsx` defines `<Route path="/animation-options" element={<AnimationOptionsPage />} />`. Deleting the component file without removing the import and route causes the TypeScript build to fail. Removing only the route but not the import also fails. If the route is cleaned up but users have the URL bookmarked, React Router's default behavior returns a blank page (no route matched, no redirect).

**Prevention:**
- Delete the component file, remove the import, and remove the route in a single atomic commit — the TypeScript build will enforce completeness.
- Add a `<Navigate from="/animation-options" to="/" />` route for a clean user-facing redirect, even if the URL is unlikely to be bookmarked.
- Remove `ProgressHeader` from `App.tsx` in the same commit.

**Phase:** Chrome cleanup phase — do this first to unblock the redesign with a clean component tree.

---

### Pitfall 13: Practice Round "Skip" Path Leaves Partial State in `issueProgress`

**What goes wrong:** If the practice round has a Skip option (for returning users), pressing Skip while mid-practice (e.g., after swiping card 2 of 5) leaves `issueProgress['practice']` with `currentQuoteIndex: 2`, `agreedQuotes: [quote1]`. The `practiceComplete` flag is never set. On next visit, the practice round condition checks `!practiceComplete` — it is still false — and the practice round starts again from the beginning (not from where it was left), but now `issueProgress['practice']` has stale data that may cause confusing behavior.

**Prevention:**
- Skip must call a dedicated `skipPractice()` action that atomically: sets `practiceComplete: true`, deletes `issueProgress['practice']`, and transitions to `'hub'` phase — all in a single `set()` call.
- Do not let Skip call `setPhase('hub')` alone. The partial practice entry must be cleaned up in the same action.
- Add a `isPracticeComplete` selector used by the entry point guard to decide whether to show practice round or go directly to hub.

**Phase:** Practice round implementation phase.

---

### Pitfall 14: dnd-kit Touch Events Conflict with Framer Motion Swipe Gestures

**What goes wrong:** If the unified flow places any drag-to-reorder interaction (dnd-kit) in the same viewport area as the swipe-card mechanic (Framer Motion drag), both libraries register `touchstart`/`pointermove` event listeners. dnd-kit's `TouchSensor` uses a 150ms activation delay to distinguish taps from drags. Framer Motion's `drag` prop starts on `pointerdown`. When both are active in the same DOM subtree, a deliberate swipe on a card can accidentally activate a drag-to-reorder, and vice versa.

**Why it happens:** `touch-action: none` must be set on draggable elements for both libraries to function reliably on iOS Safari. When two draggable systems share a DOM ancestor, `pointerdown` events are consumed ambiguously.

**Prevention:**
- Keep swipe gesture (Framer Motion card stack) and drag-to-reorder (dnd-kit agreed-quote list) in visually and DOM-structurally separate areas — never on the same element or in the same scroll container.
- If the unified flow shows ranked quotes in a sidebar or a panel below the swipe stack, gesture areas are naturally separated and this conflict does not arise.
- For any drag handle element in the ranked list, apply `touch-action: none` only to the handle, not to the whole card.
- Verify on actual touch devices (iOS Safari, Android Chrome) — this conflict does not manifest with a mouse.

**Phase:** Unified flow interaction design — must be resolved before implementation. If design cannot separate the two gesture areas, choose one interaction model (not both) to avoid the conflict.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Store refactor (remove badges, unify phases) | `version` not bumped → stale localStorage corrupts new state | Bump to `version: 2` with clean-reset migrate function as first commit |
| Store refactor | Legacy flat fields (`issueTitle`, `questionText`, `topicId`) still persisted but unused | Remove from `partialize` in same commit |
| Practice round architecture | Practice verdicts POSTed to backend as real data | `isPractice: true` flag on `IssueProgress`; filter in `postVerdicts` |
| Practice round implementation | Skip path leaves partial state | Dedicated `skipPractice()` action; atomic cleanup |
| Unified flow phase machine | `'ranking'` still in `Phase` union after `RankingPhase` deleted | Remove type first; let TypeScript errors guide cleanup |
| Location filter feature | Zero-quotes dead end for unsupported addresses | Gate evaluation entry on `quotes.length >= 2`; unfiltered fallback |
| Location filter backend | Parallel geocoding diverges from Essentials results | Reuse existing backend ST_Covers search; same Google Maps Places path |
| Coach marks | Fires before first card renders | Gate on `quotesToEvaluate.length > 0`; use `useLayoutEffect` + rAF |
| Results reveal animation | AnimatePresence stuck on rapid state transitions | Stable `key` props; batch state updates in single `set()` call |
| Visual redesign | Dynamic Tailwind classes purged in production build | Use literal class strings; run `npm run build` locally before deploy |
| Chrome cleanup | Deleted component still imported in `App.tsx` | Delete file, import, and route in single commit |
| Quote data caching | Module-level cache ignores location filter changes | Keyed cache by filter params; `clearCache()` on location change |
| Verdict sync | `postVerdicts` fires multiple times due to `issueProgress` in deps | Persist `verdictsSynced` flag in store; fire on phase transition, not re-render |

---

## Sources

- Direct codebase inspection: `EV-readrank/src/store/useReadRankStore.ts` — `version: 1`, no-op migrate, `badgeAssignments`, `Phase` union, `nextQuote` auto-transition to `'ranking'` (HIGH confidence)
- Direct codebase inspection: `EV-readrank/src/components/PhaseContainer.tsx` — `postVerdicts(issueProgress)` with `hasSynced` ref (HIGH confidence)
- Direct codebase inspection: `EV-readrank/src/components/EvaluationPhase.tsx` — device-type branch, `handleComplete`, `setPhase('ranking')` path (HIGH confidence)
- Direct codebase inspection: `EV-readrank/src/components/RankingPhase.tsx` — `badgeAssignments`, `assignBadge`, dnd-kit DndContext (HIGH confidence)
- Direct codebase inspection: `EV-readrank/src/data/api.ts` — module-level `cachedData` variable (HIGH confidence)
- [Zustand persist middleware docs](https://zustand.docs.pmnd.rs/reference/middlewares/persist) (HIGH confidence)
- [Persist middleware keeping old function versions — GitHub Discussion #2556](https://github.com/pmndrs/zustand/discussions/2556) (MEDIUM confidence)
- [How to migrate Zustand local storage store to a new version — DEV Community](https://dev.to/diballesteros/how-to-migrate-zustand-local-storage-store-to-a-new-version-njp) (MEDIUM confidence)
- [Solving Zustand persisted store re-hydration merging — DEV Community](https://dev.to/atsyot/solving-zustand-persisted-store-re-hydtration-merging-state-issue-1abk) (MEDIUM confidence)
- [AnimatePresence gets stuck when state changes quickly — Framer Motion Issue #2554](https://github.com/framer/motion/issues/2554) (HIGH confidence — open official issue)
- [AnimatePresence doesn't update with latest state on fast change — Issue #2023](https://github.com/framer/motion/issues/2023) (HIGH confidence — open official issue)
- [dnd-kit touch-action and gesture conflict documentation](https://docs.dndkit.com/api-documentation/draggable) (HIGH confidence — official docs)
- [How not to design swipe actions — Medium/TygoDesign](https://medium.com/tygodesign/how-not-to-design-a-swipe-actions-b93a93018058) (LOW confidence — single community source)
- [UX Onboarding Best Practices 2025 — UX Design Institute](https://www.uxdesigninstitute.com/blog/ux-onboarding-best-practices-guide/) (MEDIUM confidence — corroborated by multiple sources)
- [Tailwind CSS in Large Projects: Best Practices & Pitfalls — Medium](https://medium.com/@vishalthakur2463/tailwind-css-in-large-projects-best-practices-pitfalls-bf745f72862b) (MEDIUM confidence — consistent with official Tailwind docs on content scanning)
- [Laws of UX: Onboarding for Active Users (2024)](https://lawsofux.com/articles/2024/onboarding-for-active-users/) (MEDIUM confidence)

---
*Pitfalls research for: v2026.3.6 Read & Rank Redesign — unified evaluate+rank flow, practice round, location filtering, visual redesign*
*Researched: 2026-03-14*
