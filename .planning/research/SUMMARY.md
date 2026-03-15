# Project Research Summary

**Project:** v2026.3.6 Read & Rank Redesign
**Domain:** Swipe-card civic quote evaluation — unified evaluate+rank flow, practice onboarding, location-based filtering, coach marks, results polish, visual redesign
**Researched:** 2026-03-14
**Confidence:** HIGH

## Executive Summary

This milestone redesigns the Read & Rank experience by collapsing the current 4-phase linear flow (Hub → Evaluation → Ranking → Results) into a more fluid 3-phase model (Practice → Hub → Evaluate → Results) where badge assignment happens inline during evaluation rather than in a separate dedicated phase. All research was conducted against the live EV-readrank codebase and confirmed against running production systems, so confidence is uniformly HIGH with no guesswork involved. The app already has nearly every building block needed — the changes are primarily structural and compositional, not greenfield.

The recommended approach is to proceed strictly in dependency order: clean up dead code and reset the phase model first (store version bump, type changes, deletion of `RankingPhase` / `ProgressHeader` / `AnimationOptionsPage`), then build the unified `EvaluatePhase` with the new `InlineRankPanel` component, then layer in practice round and coach marks, then location filtering, and finally results polish and visual redesign. This order is not arbitrary — the practice round reuses `InlineRankPanel`, coach marks rely on the unified phase, and location filtering touches only `IssueHub` so it can be deferred until the core flow is stable. Only one new npm package is required (`@googlemaps/js-api-loader`); all other features reuse existing libraries.

The primary risks are all in state management: the Zustand persist store must be migrated from version 1 to version 2 with an explicit clean-reset migration before any other changes ship, practice round state must be structurally isolated from real verdict POST payloads, and the `postVerdicts` sync trigger must be made idempotent using a persisted store flag rather than a component ref. These are preventable with upfront design decisions and will cause rewrites if deferred.

## Key Findings

### Recommended Stack

The existing React 19 + TypeScript + Vite 7 + Tailwind CSS 4 + Framer Motion + dnd-kit + Zustand stack is unchanged and sufficient. No new animation libraries are needed; Framer Motion's `useAnimate`, `AnimatePresence`, and `useMotionValue` cover all planned animation requirements. The `CoachMark` component (230 lines, already battle-tested in CompassV2) should be copied directly into EV-readrank as a TypeScript port rather than published to ev-ui — the cross-repo coordination overhead is not justified for a single-consumer component in this milestone.

**Core technologies:**
- React 19 + TypeScript + Vite 7: existing foundation, unchanged
- Framer Motion ^12.x: all animation (stagger reveals, phase transitions, card drag) — already installed; no new animation libraries needed
- @dnd-kit/sortable ^10.x: drag-to-reorder in `InlineRankPanel` — already installed; dnd-kit reorder removed from `RankingPhase` context but unified into the new panel component
- Zustand ^5 with persist middleware: app state — requires version 2 migration with explicit clean-reset migrate function
- `@googlemaps/js-api-loader` ^2.0.2: the only new package; needed for location-based quote filtering in `AddressFilter`

**What NOT to add:** New animation libraries, separate geocoding client, parallel geofence endpoints, third badge tiers, or a published CoachMark in ev-ui for this milestone. Each adds complexity without proportional value given existing infrastructure.

### Expected Features

The v2026.3.4 baseline is fully working. This milestone overlays improvements that make the interaction more fluid and the onboarding more effective.

**Must have (table stakes):**
- Swipe to agree/disagree with visual feedback — must survive unification intact
- Badge assignment without leaving the evaluation context — this is the core "unified flow" requirement
- Progress indicator ("3 of 8") — already exists; preserve
- Resume interrupted session via localStorage persist — already exists; preserve (migration must not break it)
- Results page revealing candidate identity with source links — already exists; preserve

**Should have (differentiators):**
- Practice round with pizza-topping quotes — teaches swipe mechanics before political content; `has_done_practice` flag prevents repeat
- Coach marks on first real issue (2-3 steps) — one-time contextual guidance, permanently dismissed via store flag
- Inline badge assignment in `InlineRankPanel` (desktop sidebar during evaluation + mobile post-evaluation compact screen) — replaces separate `RankingPhase`
- Location-based quote filtering — Google Maps Places autocomplete + client-side filter against cached quotes; graceful fallback to all quotes
- Dramatic staggered results reveal with hero interstitial — Framer Motion stagger tuning only

**Defer to future milestone:**
- Multi-issue summary / cross-issue alignment score — antipartisan risk; significant state complexity
- "My reps" surfacing on Compass compare page — belongs in Essentials, not Read & Rank
- Share results card / social sharing — image generation adds infra complexity
- Backend `?politician_ids=uuid1,uuid2` multi-filter endpoint — client-side filter sufficient at current data scale (~61 quotes)

### Architecture Approach

The central structural change is replacing the `'hub' | 'evaluation' | 'ranking' | 'results'` Phase union with `'practice' | 'hub' | 'evaluate' | 'results'`. This renames `EvaluationPhase` to `EvaluatePhase`, removes `RankingPhase` entirely, and introduces a new `InlineRankPanel` component that absorbs the ranking behavior previously split across `AgreedQuotesSidebar` (desktop) and `RankingPhase` (full-screen post-evaluation). Practice state is kept structurally separate from `issueProgress` to prevent contamination of verdict sync. Location filter state lives in the Zustand store (`locationContext`) and is applied client-side in `IssueHub.handleSelectIssue` at issue-selection time — no backend changes required.

**Major components:**
1. `InlineRankPanel` (new) — unified ranking UI used in both practice and real modes; absorbs `AgreedQuotesSidebar` + `RankingPhase`; slides in when `agreedQuotes.length >= 2` during evaluation
2. `EvaluatePhase` (major rewrite of `EvaluationPhase`) — integrates `InlineRankPanel`; hosts `FirstIssueCoachMarks` wrapper; transitions directly to `'results'` on completion
3. `PracticeRound` (new) — fully self-contained; static pizza-topping data in `practiceData.ts`; writes only `practiceCompleted: boolean` to store; no `issueProgress` entry
4. `AddressFilter` (new) — Google Maps Places autocomplete; calls `POST /essentials/politicians/search`; writes `locationContext` to store
5. `FirstIssueCoachMarks` (new) — wraps `EvaluatePhase` on first real issue; TypeScript port of CompassV2 `CoachMark`; reactive to store state; gated on `quotesToEvaluate.length > 0`
6. `useReadRankStore` v2 — adds `practiceCompleted`, `firstIssueCoachMarksSeen`, `locationContext` fields; store version bump to 2 with clean-reset migration

**No backend changes required** for any planned feature. Existing `POST /essentials/politicians/search` and `GET /essentials/quotes?politician_id=X` cover all backend needs.

### Critical Pitfalls

1. **Zustand store version not bumped** — The existing no-op `migrate` function means old `phase: 'ranking'` state from v1 will silently survive into v2, causing the app to try to render the deleted `RankingPhase`. Bump `version` to `2` with a clean-reset migrate function (`return initialState`) as the absolute first commit. Test by injecting old v1 state into localStorage via DevTools.

2. **Practice verdicts leaked into `postVerdicts` POST** — If practice quotes land in `issueProgress` without isolation, they get included in the `POST /compass/verdicts` payload, either causing 400 errors (invalid quote IDs) or polluting Essentials politician profiles with pizza-topping text. Practice state must live entirely outside `issueProgress`, or every verdict sync path must filter by an `isPractice` flag.

3. **Unified flow breaks the `nextQuote` phase transition** — Currently `nextQuote()` auto-sets `phase: 'ranking'`. Removing `'ranking'` from the Phase union produces TypeScript build errors everywhere — use those errors as a guided cleanup checklist. Rewrite `nextQuote` to transition directly to `'results'`. Delete `RankingPhase.tsx` in the same commit as the type removal.

4. **Location filter creates a zero-quotes dead end** — When a user's address resolves to politicians who have no quotes in `compass.quotes`, `quotesToEvaluate.length === 0`, and the evaluation phase shows an unexplained blank. Gate evaluation entry on `filteredQuotes.length >= 2`; fall back to unfiltered quotes with an inline soft message if the threshold is not met.

5. **`postVerdicts` fires multiple times due to component refs resetting** — The current `hasSynced` ref resets when `PhaseContainer` unmounts (e.g., navigation to `/candidate/:id/alignment`). Replace with a persisted store flag `verdictsSynced: boolean` so the guard survives remounts. Also prevents double-firing when `issueProgress` updates after entering results phase.

## Implications for Roadmap

Research firmly establishes that this milestone has hard sequential dependencies and a clear optimal build order. Deviation from this order creates rework. Six phases are recommended.

### Phase 1: Chrome Cleanup + Store Migration

**Rationale:** Every other phase builds on a clean phase model and a valid store migration. Doing this first means all subsequent phases work against correct types, and the TypeScript compiler becomes a guided checklist for every callsite that needs updating. This is the only phase with zero new user-facing behavior — treat it as foundation work.
**Delivers:** Deleted `ProgressHeader`, `AnimationOptionsPage`, `CollectionPhase`, `AgreedQuotesSidebar`, `RankingPhase`. Updated `Phase` union type. Store bumped to v2 with clean-reset migrate. `PhaseContainer` updated. Legacy flat-state fields removed from `partialize`.
**Addresses:** Chrome cleanup (anti-features), store foundation for all subsequent phases
**Avoids:** Pitfall 1 (store version), Pitfall 3 (phase type orphan causing silent hub regression), Pitfall 12 (deleted component still imported in `App.tsx`)

### Phase 2: Unified EvaluatePhase + InlineRankPanel

**Rationale:** `InlineRankPanel` is the core deliverable of this milestone and is a dependency for the practice round (which reuses it in practice mode). Building the canonical unified interaction before practice ensures practice teaches the correct mechanic. This is the highest-value visible change — the primary "unified flow" milestone requirement.
**Delivers:** New `EvaluatePhase` with `InlineRankPanel` sliding in at `agreedQuotes.length >= 2`. Badge assignment inline. `setPhase('results')` called directly from evaluate — no intermediate ranking screen. Desktop split-layout and mobile compact mode both handled.
**Uses:** Framer Motion `AnimatePresence` + `layout` for slide-in; @dnd-kit/sortable for reorder in panel; existing `assignBadge` store action
**Avoids:** Pitfall 7 (practice teaches wrong mechanic if unified flow not locked first), Pitfall 14 (dnd-kit / framer-motion gesture conflict — `InlineRankPanel` must be in a structurally separate DOM area from the swipe card stack)

### Phase 3: Practice Round

**Rationale:** Depends on Phase 2 because `PracticeRound` reuses `InlineRankPanel` in practice mode. Must follow Phase 2 so the practice experience matches the real flow. Practice state isolation must be designed in from the start, not patched later.
**Delivers:** `PracticeRound` component with static `practiceData.ts` pizza quotes. `practiceCompleted` store field. First-visit auto-redirect from `IssueHub`. `skipPractice()` atomic action that cleans up all partial practice state. Practice verdicts never reach backend or fragment encoder.
**Avoids:** Pitfall 2 (practice verdicts leaked to POST), Pitfall 13 (skip path leaving partial state), Pitfall 7 (practice mechanic mismatch with real flow)

### Phase 4: Coach Marks

**Rationale:** Depends on Phase 2 because coach marks spotlight `InlineRankPanel`, which must exist first. Should follow Phase 3 so coach marks reinforce what practice introduced rather than replace it. Must read CompassV2 `CoachMark.jsx` source before implementing to replicate the exact step data structure and spotlight targeting mechanism.
**Delivers:** `FirstIssueCoachMarks` wrapper around `EvaluatePhase`. TypeScript port of `CoachMark.jsx` from CompassV2. `firstIssueCoachMarksSeen` store flag. 2-4 tour steps targeting swipe card and badge buttons. Permanent dismiss after first completion.
**Avoids:** Pitfall 6 (coach marks firing before first card is in the DOM — gate on `quotesToEvaluate.length > 0` + `useLayoutEffect` + `requestAnimationFrame`)

### Phase 5: Location-Based Filtering

**Rationale:** The most complex feature (three parts: address input UI, politician ID resolution, client-side filter with graceful fallback) touches only `IssueHub`, making it independent of Phases 2-4. Doing it after the core flow is stable means any bugs are clearly attributable to the location layer. Reuse Essentials' Google Maps Places initialization pattern exactly — do not invent a parallel geocoding approach.
**Delivers:** `AddressFilter` component in `IssueHub`. `locationContext` store field. `handleSelectIssue` filter logic with `filteredQuotes.length >= 2` guard and unfiltered fallback. URL `?politician_id` auto-detect on mount for cross-app deep links from Essentials. `@googlemaps/js-api-loader` installed. `VITE_GOOGLE_MAPS_API_KEY` added to Cloudflare Pages env. Module-level `cachedData` replaced with keyed cache.
**Uses:** `@googlemaps/js-api-loader` ^2.0.2 (only new npm package this milestone); `POST /essentials/politicians/search` (existing public backend endpoint, no backend changes)
**Avoids:** Pitfall 4 (zero-quotes dead end), Pitfall 8 (parallel geocoding diverging from Essentials), Pitfall 11 (module-level cache not respecting location filter changes), Pitfall 5 (postVerdicts firing with location-modified issueProgress — address with persisted `verdictsSynced` flag)

### Phase 6: Results Polish + Visual Redesign

**Rationale:** Pure visual layer. Depends on stable phase model from Phase 1 but is independent of Phases 2-5. Can be partially parallelized with Phases 2-5 if capacity allows, or executed as a final pass to ensure it layers onto a stable component structure with no functional risk.
**Delivers:** Hero reveal interstitial (Fraunces headline + `AnimatePresence` stage). Stagger animation with `staggerChildren: 0.07` on card list. 800ms artificial spinner removed (replaced with shimmer skeleton). Single "View on Essentials" CTA per result card. Visual redesign across all components within existing design system.
**Avoids:** Pitfall 9 (dynamic Tailwind classes purged in production — use literal class strings only; run `npm run build` locally before every deploy), Pitfall 10 (AnimatePresence stuck on rapid transitions — stable `key` props, batch state updates in single `set()` call)

### Phase Ordering Rationale

- Phase 1 must be first: store migration gates everything; TypeScript type cleanup is the guided checklist for all subsequent work
- Phase 2 must precede Phase 3: `InlineRankPanel` is a hard dependency of `PracticeRound` in practice mode; building canonical version first prevents rework
- Phase 3 must precede Phase 4: coach marks are designed to reinforce the practice mechanic — both must exist for the onboarding arc to make sense
- Phase 5 is isolated to `IssueHub` and can slot anywhere after Phase 1; doing it after Phases 2-4 means the core flow is stable before adding the filtering complexity layer
- Phase 6 is the safest to defer or parallelize — pure visual changes with no functional dependencies on Phases 2-5

### Research Flags

Phases needing specific pre-implementation source review:

- **Phase 4 (Coach Marks):** Must read `CompassV2/src/components/CoachMark.jsx` in full before implementing `FirstIssueCoachMarks`. The step data structure, spotlight target mechanism, and `useCoachMark` hook localStorage key pattern must be replicated exactly, not re-invented.
- **Phase 5 (Location Filtering):** Must read `essentials/src/pages/Dashboard.jsx` for the exact Google Maps Places `Autocomplete` initialization pattern before implementing `AddressFilter`. The Essentials pattern is canonical — divergence causes geocoding inconsistencies between apps.

Phases with standard well-documented patterns (can proceed without additional research):

- **Phase 1 (Cleanup + Migration):** Zustand persist migration is straightforward; TypeScript errors guide all callsite cleanup. No unknowns.
- **Phase 2 (InlineRankPanel):** Component boundaries and interaction model fully specified in ARCHITECTURE.md. All source components inspected. No unknowns.
- **Phase 3 (Practice Round):** Static data + boolean store flag — zero external dependencies.
- **Phase 6 (Visual Redesign):** Framer Motion stagger is well-documented; all patterns from existing codebase. Run `npm run build` locally before deploying to catch Tailwind purge issues.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All findings from direct source inspection; only one new package needed; version compatibility verified against installed packages |
| Features | HIGH | Existing codebase fully inspected; all feature recommendations grounded in what already exists and what v2026.3.4 shipped |
| Architecture | HIGH | Component boundaries and data flow verified against live source; no assumptions about unread code; build order derived from direct dependency analysis |
| Pitfalls | HIGH | Critical pitfalls 1-5 derived from direct code inspection of the specific files that contain the risk; Zustand and Framer Motion risks confirmed against official docs and open GitHub issues |

**Overall confidence:** HIGH

### Gaps to Address

- **CORS verification for location filtering:** Confirm that `POST /essentials/politicians/search` allows requests from `readrank.empowered.vote` on all `/essentials/*` routes (not just `/essentials/quotes`) in `EV-Backend/internal/middleware/middleware.go` before Phase 5 ships. This was noted as added in v2026.3.4 but the exact scope was flagged as unconfirmed.
- **CoachMark ev-ui export status:** As of v0.1.50, `CoachMark` is NOT in the published ev-ui package. If ev-ui is updated between now and Phase 4, recheck before porting manually to avoid duplicating work.
- **Google Maps API key budget:** The 28K requests/month free tier is shared across Essentials and will now include Read & Rank. Not a concern at current traffic but should be noted when `VITE_GOOGLE_MAPS_API_KEY` is added to Cloudflare Pages environment variables.

## Sources

### Primary (HIGH confidence — direct codebase inspection)

- `/Users/chrisandrews/Documents/GitHub/EV-readrank/` — all source files (store, components, data layer, hooks); every component referenced in this summary was directly read
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/` — routes, handlers, geofence lookup; confirmed existing endpoint surface
- `/Users/chrisandrews/Documents/GitHub/CompassV2/src/components/CoachMark.jsx` — component deps (react, react-dom, framer-motion only) and useCoachMark hook localStorage key pattern
- `/Users/chrisandrews/Documents/GitHub/essentials/src/` — Google Maps Places init pattern, `@googlemaps/js-api-loader` usage confirmed
- `/Users/chrisandrews/Documents/GitHub/ev-ui/package.json` — confirmed CoachMark NOT exported as of v0.1.50

### Secondary (MEDIUM confidence — official docs and open issues)

- Zustand persist middleware docs — migration strategy, `partialize` behavior
- Framer Motion GitHub issues #2554 and #2023 — AnimatePresence stuck on rapid transitions (both open as of 2025)
- dnd-kit official docs — touch-action and gesture conflict guidance
- Tailwind CSS docs — JIT class scanning, dynamic class purging behavior

### Tertiary (LOW confidence — single community sources)

- Duolingo onboarding UX references — practice round design rationale (corroborated by multiple secondary sources)
- Coach marks UX best practices (NN/g, Plotline 2025) — tour step design guidance

---
*Research completed: 2026-03-14*
*Ready for roadmap: yes*
