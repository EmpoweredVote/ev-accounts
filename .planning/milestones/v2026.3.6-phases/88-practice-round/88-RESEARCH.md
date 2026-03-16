# Phase 88: Practice Round - Research

**Researched:** 2026-03-15
**Domain:** React / Zustand — onboarding flow with practice-mode state isolation
**Confidence:** HIGH

## Summary

Phase 88 adds a first-time-user practice round that teaches the two core mechanics — swipe agree/disagree and head-to-head matchup ranking — using pizza-topping quotes before real political content appears. The entire practice flow reuses existing evaluation components unchanged; the only new work is (1) a thin store extension for practice state, (2) a `PracticeRound` container component, (3) a `PracticeResultsScreen` component, and (4) the auto-redirect routing logic.

Practice state must be completely isolated from `issueProgress` so that `verdictSync.ts` and `verdictFragment.ts` never touch it. The isolation boundary is simple: practice data lives in two new top-level store fields (`practiceCompleted` and `practiceProgress`) rather than inside `issueProgress`. The store bumps from v4 to v5 with the same hardcoded-reset migrate pattern established in previous phases.

**Primary recommendation:** Build `PracticeRound` as a wrapper that drives the same `EvaluationPhase` + `MatchupPhase` rendering path, feeding it practice-only state through a local `usePracticeProgress` hook or direct store selectors, never touching `currentIssueId` / `issueProgress`. Practice results use a bespoke `PracticeResultsScreen` that mirrors the reveal pattern from `ResultsPhase` but strips all candidate/essentials links.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Practice content**
- 5 pizza-topping quotes with playful, opinionated tone ("Pineapple belongs on pizza and I will die on this hill")
- Framed as a single issue: "The Great Pizza Debate" with question text "Where do you stand on pizza toppings?"
- Quotes attributed to silly fake characters (e.g., "Chef Mario", "Pizza Pete")
- Mirrors the real issue/question structure exactly so users learn the pattern

**Entry & exit flow**
- Auto-redirect: first visit goes straight to practice (no hub). Store flag `practiceCompleted` tracks completion
- Returning users with `practiceCompleted: true` bypass practice and land on the hub
- Persistent "Skip practice" text link visible throughout the practice round (not pushy, always accessible)
- Skip clears all partial practice state atomically and takes user to hub, sets `practiceCompleted: true`
- After completing practice: mini results screen showing pizza topping rankings with silly character reveals
- Results screen has "Start exploring real issues" CTA button that transitions to hub

**Phase model**
- Add `'practice'` to the Phase union type: `'hub' | 'practice' | 'evaluation' | 'results'`
- PhaseContainer renders a new PracticeRound component for the `'practice'` phase
- Practice state lives entirely outside `issueProgress` — no contamination of real verdict data
- Store version bump to v5 with clean-reset migration (established pattern from v2/v3/v4)

**Visual treatment**
- Same evaluation layout and card styling as real issues — maximum transfer learning
- Persistent "Practice Round" banner/badge at top to signal it's not real content
- Pizza emoji accent on each quote card (small, lightweight fun without breaking the card pattern)
- Practice results screen mirrors real results reveal mechanic with fake character reveals

**Ranking mechanic**
- Full head-to-head matchup flow from Phase 87.1 — users learn the exact ranking mechanic they'll encounter
- With 5 quotes and ~2-3 agrees, users see 1-3 matchup prompts naturally
- Desktop sidebar visible during practice, same as real evaluation
- Sidebar design may change in a future phase — practice should reuse whatever the current evaluation components render

### Claude's Discretion
- Exact pizza-topping quote text and fake character names
- Practice banner styling and positioning
- Pizza emoji placement on quote cards
- Practice results screen layout and animation timing
- Whether PracticeRound is a wrapper around EvaluationPhase with practice data injection or a standalone component

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| ONBD-01 | First-time users see a practice round with pizza topping quotes before real issues | Auto-redirect via `practiceCompleted` flag in store initialState; `PhaseContainer` sets phase to `'practice'` when flag is false |
| ONBD-02 | Practice round teaches swipe agree/disagree and insert-into-list ranking mechanics | Reuse `EvaluationPhase` + `MatchupPhase` wholesale; practice state feeds same store selectors via isolated practice fields |
| ONBD-03 | Practice round verdicts never reach backend or fragment encoder | `verdictSync.ts` reads only `issueProgress`; practice data in separate store fields never passes through `buildVerdictPayload` or `buildEssentialsProfileUrl` |
| ONBD-04 | User can skip practice round; skip cleans up all partial practice state | `skipPractice()` store action sets `practiceCompleted: true`, zeroes `practiceProgress`, sets `phase: 'hub'` atomically |
</phase_requirements>

---

## Standard Stack

### Core (already in project — no new installs required)
| Library | Version | Purpose | Note |
|---------|---------|---------|------|
| zustand + persist | current | Store with localStorage | Pattern already established at v4; bump to v5 |
| framer-motion | current | Card animations, results stagger | Already used in EvaluationPhase / ResultsPhase |
| React | 19 | Component tree | No change |

### No New Dependencies
All components needed for Phase 88 are already in the codebase. The practice round is purely additive: new files + store extension + wiring.

**Installation:** None required.

---

## Architecture Patterns

### Recommended File Structure (additions only)
```
EV-readrank/src/
├── components/
│   ├── PracticeRound.tsx          # NEW — outer wrapper, banner, skip link
│   └── PracticeResultsScreen.tsx  # NEW — pizza reveal results
├── data/
│   └── practiceData.ts            # NEW — 5 pizza quotes + fake characters (static)
└── store/
    └── useReadRankStore.ts        # MODIFIED — v5, practiceCompleted, practiceProgress, actions
```

### Pattern 1: Isolated Practice State in Store

Practice state lives at the top level of `ReadRankState`, never inside `issueProgress`.

```typescript
// Source: existing store pattern (useReadRankStore.ts line 102-116)

// NEW top-level fields added to ReadRankState interface:
practiceCompleted: boolean;
practiceProgress: PracticeProgress | null;  // null = not started

// NEW interface (mirrors IssueProgress structure, stripped of candidateMatches):
export interface PracticeProgress {
  phase: 'evaluation' | 'results';
  currentQuoteIndex: number;
  rankedQuotes: RankedQuote[];
  disagreedQuotes: Quote[];
  matchupWins: Record<string, number>;
  completedMatchupPairs: string[];
  activeMatchupPair: [string, string] | null;
}
```

**Why:** `verdictSync.ts` reads only `issueProgress`. Practice fields are never passed to `buildVerdictPayload()`. Zero risk of backend contamination.

### Pattern 2: Store v5 Migration (hardcoded reset)

```typescript
// Source: existing pattern (useReadRankStore.ts line 430-432)
migrate: (_persistedState, _version) => {
  // v5 migration: wipe all old state
  return {
    phase: 'hub' as Phase,
    currentIssueId: null as string | null,
    issueProgress: {} as Record<string, IssueProgress>,
    practiceCompleted: false,
    practiceProgress: null,
  };
},
```

**Why:** Returning v4 users have no `practiceCompleted` field. Hardcoded reset puts them on hub (they see `practiceCompleted: false` after migration — deliberate: returning users who already know the app should go to hub, so `practiceCompleted` starts true in migration or the redirect logic checks version separately).

**Critical decision point:** Migration resets to hub with `practiceCompleted: false` means returning v4 users would be forced through practice. The correct approach: set `practiceCompleted: true` in the migration return value for any version > 0. New installs (version 0 → 5) should start with `practiceCompleted: false`.

```typescript
migrate: (_persistedState, version) => {
  const isUpgrade = version > 0;  // version 0 = brand new user
  return {
    phase: 'hub' as Phase,
    currentIssueId: null as string | null,
    issueProgress: {},
    practiceCompleted: isUpgrade,  // existing users skip practice
    practiceProgress: null,
  };
},
```

**Note:** Zustand persist calls `migrate` with the persisted version number. Version 0 is passed when no persisted state exists (brand new user). This is the correct gate.

### Pattern 3: Auto-Redirect in PhaseContainer

```typescript
// Source: PhaseContainer.tsx lines 9-18 (current pattern)
// PhaseContainer reads phase from store and renders accordingly
// New logic: on mount, check practiceCompleted; if false, setPhase('practice')

useEffect(() => {
  if (!practiceCompleted && phase === 'hub') {
    setPhase('practice');
  }
}, []);  // run once on mount
```

**Why this location:** PhaseContainer is the single orchestrator for all phase transitions. Adding the redirect here keeps the entry-gate logic co-located with phase rendering.

### Pattern 4: PracticeRound Component Structure

PracticeRound should NOT reuse `EvaluationPhase` directly because `EvaluationPhase` reads from `getCurrentIssueProgress()` which requires `currentIssueId` to be set. Setting `currentIssueId` to a practice ID would bleed into `issueProgress`.

Instead, `PracticeRound` renders its own evaluation UI by:
1. Reading `practiceProgress` directly from the store
2. Rendering the same child components (`QuoteCard`, `MatchupPhase`, `RankedListSidebar`, `InlineRankPanel`) with practice data
3. Calling practice-specific store actions (`agreePracticeQuote`, `disagreePracticeQuote`, `recordPracticeMatchupWin`, etc.)

**Alternative considered:** Inject practice context via React Context so `getCurrentIssueProgress()` could be overridden. Rejected — more complexity, same outcome.

**Simpler alternative (Claude's discretion):** Duplicate only the rendering portion of `EvaluationPhase` into `PracticeRound`, removing the store-reading logic and replacing with practice store selectors. Since `EvaluationPhase` is ~270 lines and already well-structured, this is straightforward.

### Pattern 5: MatchupPhase Works Unmodified

`MatchupPhase` reads `activeMatchupPair` and `rankedQuotes` from `getCurrentIssueProgress()`. This is the integration risk.

**Two clean options:**

**Option A — Practice-scoped `getCurrentIssueProgress` override:** Add a `getPracticeProgress()` selector to the store that returns `practiceProgress` in the `IssueProgress` shape. Pass it down as a prop or via context to `MatchupPhase`. Requires adding `issueId` and `quotesToEvaluate` fields to `PracticeProgress` to match the `IssueProgress` interface.

**Option B — Duplicate MatchupPhase rendering inline in PracticeRound:** Read `practiceProgress.activeMatchupPair` directly and render `MatchCard` components inline in `PracticeRound`. `MatchCard` has no store dependency — it takes `quote`, `side`, `onPick`, `selected`, `disabled` as props.

**Recommendation:** Option B for `MatchupPhase` is safer and avoids touching store internals. `MatchCard.tsx` is already prop-driven. `PracticeRound` reproduces the matchup layout (banner, two `MatchCard` instances, VS divider) and calls `recordPracticeMatchupWin()`.

### Pattern 6: verdictSync Isolation — Already Enforced by Architecture

```typescript
// Source: verdictSync.ts lines 12-26
export function buildVerdictPayload(
  issueProgress: Record<string, IssueProgress>  // ← only parameter
): VerdictPayload[] { ... }
```

`postVerdicts` is called in `PhaseContainer` only when `phase === 'results'`:
```typescript
// PhaseContainer.tsx lines 14-18
useEffect(() => {
  if (phase === 'results' && isLoggedIn && !hasSynced.current) {
    hasSynced.current = true;
    postVerdicts(issueProgress);  // ← issueProgress only, never practiceProgress
  }
}, [phase, isLoggedIn, issueProgress]);
```

Since practice data never enters `issueProgress`, and `postVerdicts` only runs when `phase === 'results'` (not `'practice'`), ONBD-03 is satisfied with zero extra work.

### Pattern 7: partialize Must Include New Fields

```typescript
// Source: useReadRankStore.ts lines 434-438 (current)
partialize: (state) => ({
  phase: state.phase,
  currentIssueId: state.currentIssueId,
  issueProgress: state.issueProgress,
  // ADD:
  practiceCompleted: state.practiceCompleted,
  practiceProgress: state.practiceProgress,
}),
```

If `practiceCompleted` is omitted from `partialize`, it won't persist across page reloads and every visit will redirect to practice.

### Anti-Patterns to Avoid

- **Setting `currentIssueId` to a practice issue ID:** Would route practice data through `issueProgress`, contaminating `verdictSync`. Never do this.
- **Adding a `'practice'` issue to the real issues API/data:** Practice data must be static, never fetched from backend or mixed with real issues.
- **Calling `selectIssue()` for practice:** That action creates `issueProgress` records. Use dedicated practice actions instead.
- **Checking `practiceCompleted` in `IssueHub`:** The redirect belongs in `PhaseContainer`, not the hub. Hub should render normally; the gate is upstream.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Swipe card UI | Custom swipe implementation | `QuoteCard.tsx` as-is | Already has Framer Motion drag, thresholds, animations |
| Matchup UI | Custom side-by-side comparison | `MatchCard.tsx` as-is | Prop-driven, no store dependency, handles 3D tilt |
| Ranked list display | Custom ranking UI | `RankedListSidebar` / `InlineRankPanel` as-is | Already have rank colors, labels, layout |
| Stagger animation | Custom reveal animation | Framer Motion `initial`/`animate` with `delay: index * 0.08` | Already used in `ResultsPhase` |
| Matchup algorithm | Custom win-counting | `matchupAlgorithm.ts` — `getPendingMatchups`, `computeRankings`, `makePairKey` | Already handles all edge cases including tie-breaking |

**Key insight:** Phase 88 is almost entirely assembly. Every visual and algorithmic primitive exists. The risk is contamination, not implementation complexity.

---

## Common Pitfalls

### Pitfall 1: practiceCompleted Missing from partialize
**What goes wrong:** `practiceCompleted: true` is not saved to localStorage. Every page refresh redirects to practice.
**Why it happens:** Forgetting to add new fields to the `partialize` object.
**How to avoid:** After adding `practiceCompleted` and `practiceProgress` to state, immediately add them to `partialize`.
**Warning signs:** Practice shows on every refresh even after completing.

### Pitfall 2: Migration Sets practiceCompleted: false for Upgrade Users
**What goes wrong:** Returning users with v4 localStorage are wiped to `practiceCompleted: false`, forcing them through pizza practice before accessing the hub.
**Why it happens:** Using the same reset for new and upgrade users.
**How to avoid:** In `migrate`, check `version > 0` to set `practiceCompleted: true` for upgrades. Version 0 = brand new user (no persisted state).
**Warning signs:** Returning users report being stuck on pizza practice.

### Pitfall 3: Skip Leaves Partial Practice State
**What goes wrong:** User partially completes practice (e.g., agreed with 3 quotes, has active matchup), skips — but `practiceProgress` retains stale state. On revisit, practice might appear to resume from mid-session.
**Why it happens:** `skipPractice()` action only sets `practiceCompleted: true` without nulling `practiceProgress`.
**How to avoid:** `skipPractice()` atomically sets `{ phase: 'hub', practiceCompleted: true, practiceProgress: null }`.
**Warning signs:** After skip, returning to practice (via DevHelper or other path) shows partial state.

### Pitfall 4: PracticeRound Triggers postVerdicts
**What goes wrong:** The `useEffect` in `PhaseContainer` watches `phase` — if `'practice'` is added to `Phase` union but the guard is `phase === 'results'`, this is already safe. But if `PracticeResultsScreen` calls `setPhase('results')` instead of a dedicated `completePractice()` action, it would trigger `postVerdicts` with empty `issueProgress`, sending a no-op POST.
**Why it happens:** Reusing `setPhase('results')` from real evaluation flow.
**How to avoid:** `PracticeResultsScreen`'s "Start exploring real issues" CTA calls `completePractice()` which sets `{ phase: 'hub', practiceCompleted: true }` directly — never touches `'results'` phase.
**Warning signs:** Network tab shows `POST /compass/verdicts` after completing practice.

### Pitfall 5: QuoteCard Calls agreeWithQuote/disagreeWithQuote (Store Actions for Real Issues)
**What goes wrong:** `QuoteCard` directly calls `agreeWithQuote(quote)` from `useReadRankStore`, which writes to `issueProgress[currentIssueId]`. If used in practice, it contaminates real issue state.
**Why it happens:** `QuoteCard` has hardcoded store bindings (line 3, 22: `useReadRankStore`).
**How to avoid:** `PracticeRound` cannot use `QuoteCard` directly. Either (a) pass `onAgree`/`onDisagree` as props and refactor `QuoteCard` to accept them, or (b) inline the card markup in `PracticeRound` with practice-specific handlers. Option (b) avoids touching `QuoteCard`.
**Warning signs:** After practice agree, `issueProgress` in DevHelper shows unexpected entries.

**Important:** This is the highest-risk pitfall — `QuoteCard` is NOT prop-injectable for its swipe handlers in the current implementation (lines 56-72 call store actions directly). Either a small QuoteCard refactor (add optional `onAgree`/`onDisagree` props) or duplication of the card markup is required.

### Pitfall 6: MatchupPhase Reads getCurrentIssueProgress()
**What goes wrong:** `MatchupPhase` calls `useReadRankStore()` to get `activeMatchupPair`, `rankedQuotes`, `quotesToEvaluate` from `getCurrentIssueProgress()`. In practice context, this returns null (no `currentIssueId` set).
**Why it happens:** `MatchupPhase` has store coupling on lines 28-34.
**How to avoid:** Do not use `MatchupPhase` directly in `PracticeRound`. Instead, render the matchup UI inline in `PracticeRound` using `MatchCard` (which IS prop-driven). `MatchCard` takes `quote`, `side`, `onPick`, `selected`, `disabled` — zero store dependency.

---

## Code Examples

### Practice Store Shape

```typescript
// New fields in ReadRankState interface
practiceCompleted: boolean;
practiceProgress: PracticeProgress | null;

// Actions
startPractice: () => void;
agreePracticeQuote: (quote: Quote) => void;
disagreePracticeQuote: (quote: Quote) => void;
recordPracticeMatchupWin: (winnerId: string, loserId: string) => void;
completePractice: () => void;   // → phase: 'hub', practiceCompleted: true
skipPractice: () => void;       // → phase: 'hub', practiceCompleted: true, practiceProgress: null
```

### agreePracticeQuote Action Pattern

```typescript
// Source: mirrors agreeWithQuote (useReadRankStore.ts lines 199-233)
agreePracticeQuote: (quote) => {
  const state = get();
  const progress = state.practiceProgress;
  if (!progress) return;

  const newRank = progress.rankedQuotes.length + 1;
  const rankedQuote: RankedQuote = { ...quote, rank: newRank, timestamp: Date.now() };
  const updatedRanked = [...progress.rankedQuotes, rankedQuote];

  let activeMatchupPair = progress.activeMatchupPair;
  if (updatedRanked.length >= 2) {
    const pending = getPendingMatchups(updatedRanked, progress.completedMatchupPairs);
    activeMatchupPair = pending.length > 0 ? pending[0] : null;
  }

  set({
    practiceProgress: {
      ...progress,
      rankedQuotes: updatedRanked,
      currentQuoteIndex: progress.currentQuoteIndex + 1,
      activeMatchupPair,
    },
  });
},
```

### Migration v5

```typescript
// Source: mirrors existing migrate (useReadRankStore.ts line 430-432)
version: 5,
migrate: (_persistedState, version) => {
  const isUpgrade = version > 0;
  return {
    phase: 'hub' as Phase,
    currentIssueId: null as string | null,
    issueProgress: {} as Record<string, IssueProgress>,
    practiceCompleted: isUpgrade,  // existing users bypass practice
    practiceProgress: null,
  };
},
```

### PhaseContainer Auto-Redirect

```typescript
// Add to PhaseContainer (after existing store destructuring)
const { phase, practiceCompleted, setPhase } = useReadRankStore();

useEffect(() => {
  if (!practiceCompleted && phase === 'hub') {
    setPhase('practice');
  }
}, []); // intentionally empty — run once on mount only
```

### Static Practice Data Shape

```typescript
// src/data/practiceData.ts
import type { Quote } from '../store/useReadRankStore';

export const PRACTICE_ISSUE = {
  id: 'practice-pizza',
  title: 'The Great Pizza Debate',
  question: 'Where do you stand on pizza toppings?',
};

// Fake characters (Claude's discretion on names/text)
export const PRACTICE_CHARACTERS = [
  { id: 'chef-mario', name: 'Chef Mario', title: 'Head Chef, Napoli Kitchen' },
  { id: 'pizza-pete', name: 'Pizza Pete', title: 'Professional Pizza Critic' },
  { id: 'tina-toppings', name: 'Tina Toppings', title: 'Pizza Purist' },
  { id: 'derek-deep', name: 'Derek Deep-Dish', title: 'Deep Dish Defender' },
  { id: 'sam-slice', name: 'Sam Slice', title: 'Artisan Slice Enthusiast' },
];

export const PRACTICE_QUOTES: Quote[] = [
  { id: 'pq-1', text: 'Pineapple belongs on pizza and I will die on this hill.', candidateId: 'chef-mario', issue: 'practice-pizza' },
  { id: 'pq-2', text: 'The only acceptable pizza toppings are pepperoni, mozzarella, and silence.', candidateId: 'tina-toppings', issue: 'practice-pizza' },
  { id: 'pq-3', text: 'Ranch dressing is a perfectly valid pizza sauce. The haters are wrong.', candidateId: 'pizza-pete', issue: 'practice-pizza' },
  { id: 'pq-4', text: 'Thin crust is a crime against pizza. Deep dish is the only honest pizza.', candidateId: 'derek-deep', issue: 'practice-pizza' },
  { id: 'pq-5', text: 'Anchovies on pizza is an acquired taste worth acquiring. The ocean deserves representation.', candidateId: 'sam-slice', issue: 'practice-pizza' },
];
```

---

## State of the Art

| Old Approach | Current Approach | Phase | Impact |
|--------------|------------------|-------|--------|
| `'ranking'` phase in Phase union | Removed in Phase 86 | 86 | Phase union is now `'hub' | 'evaluation' | 'results'` — add `'practice'` |
| `agreedQuotes` field | Removed in Phase 87; `rankedQuotes` is sole source | 87 | Practice state uses `rankedQuotes` too |
| Drag-to-rank gate | Removed in Phase 87.1; matchup flow is sole ranking UX | 87.1 | Practice uses matchup flow, no drag gate |
| Store v4 | Current | 87.1 | Bump to v5 in Phase 88 |

**Deprecated/outdated (do not reintroduce):**
- `agreedQuotes`: removed in Phase 87, replaced by `rankedQuotes`
- `pendingRankQuoteId` / `rankSkipCount`: these were for drag-gate UX, removed in 87.1 — practice state does NOT need these fields
- `QuickConfirmation`: removed in Phase 87 — practice does not use it

---

## Open Questions

1. **QuoteCard store coupling (HIGHEST PRIORITY)**
   - What we know: `QuoteCard` calls `agreeWithQuote`/`disagreeWithQuote` directly from the store (lines 56-72). These write to `issueProgress[currentIssueId]`.
   - What's unclear: The planner needs to decide — refactor `QuoteCard` to accept optional `onAgree`/`onDisagree` callback props, or duplicate the card rendering in `PracticeRound`.
   - Recommendation: Add optional `onAgree?: (quote: Quote) => void` and `onDisagree?: (quote: Quote) => void` props to `QuoteCard`. When provided, use them instead of the store actions. This is a ~5-line change and keeps the component reusable. Safer than duplication.

2. **Zustand migrate version=0 behavior**
   - What we know: The docs say `migrate` is called with the persisted version number when it doesn't match the current version.
   - What's unclear: Does Zustand call `migrate` with `version=0` for brand-new users (no localStorage), or does it skip `migrate` entirely and use `initialState`?
   - Recommendation: Test empirically in DevHelper. If Zustand skips `migrate` for new users, `initialState` must set `practiceCompleted: false`. If it calls `migrate` with `version=0`, the `isUpgrade = version > 0` guard works correctly. Either way, `initialState.practiceCompleted = false` ensures new users always see practice.

3. **Sidebar "Wins" display during practice**
   - What we know: `RankedListSidebar` shows a "W" wins badge per quote using `matchupWins` from `getCurrentIssueProgress()`. During practice, `getCurrentIssueProgress()` returns null.
   - What's unclear: Should practice sidebar show wins, or just rankings?
   - Recommendation: Since `RankedListSidebar` cannot be used as-is (store coupling on `getCurrentIssueProgress`), `PracticeRound` renders a simpler sidebar that lists `practiceProgress.rankedQuotes` directly. Wins display is optional — include it if it naturally follows from `practiceProgress.matchupWins`.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None detected in EV-readrank |
| Config file | None — Wave 0 gap |
| Quick run command | N/A |
| Full suite command | N/A |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ONBD-01 | First visit redirects to practice phase | manual-only | N/A — no test framework | N/A |
| ONBD-02 | Swipe and matchup mechanics work during practice | manual-only | N/A — no test framework | N/A |
| ONBD-03 | Practice verdicts never reach backend | manual-only (network tab inspection) | N/A | N/A |
| ONBD-04 | Skip clears all practice state atomically | manual-only | N/A | N/A |

### Sampling Rate
- **Per task commit:** Manual smoke test in browser (DevHelper available for state inspection)
- **Per wave merge:** Full manual walkthrough of new-user flow
- **Phase gate:** All 4 ONBD requirements verified manually before `/gsd:verify-work`

### Wave 0 Gaps
No test infrastructure exists in EV-readrank. Given single-consumer React app with no existing test setup, adding a test framework is out of scope for this phase. All verification is manual.

*(No automated test files to create — manual verification protocol covers all phase requirements.)*

---

## Sources

### Primary (HIGH confidence)
- Direct source code read of `EV-readrank/src/store/useReadRankStore.ts` — full store shape, migrate pattern, partialize
- Direct source code read of `EV-readrank/src/components/PhaseContainer.tsx` — phase switch, postVerdicts guard
- Direct source code read of `EV-readrank/src/components/EvaluationPhase.tsx` — full rendering structure, store coupling
- Direct source code read of `EV-readrank/src/components/QuoteCard.tsx` — confirmed direct store action coupling
- Direct source code read of `EV-readrank/src/components/MatchupPhase.tsx` — confirmed `getCurrentIssueProgress()` coupling
- Direct source code read of `EV-readrank/src/components/MatchCard.tsx` — confirmed prop-driven, no store dependency
- Direct source code read of `EV-readrank/src/utils/verdictSync.ts` — confirmed isolation boundary
- Direct source code read of `EV-readrank/src/utils/matchupAlgorithm.ts` — confirmed pure functions, reusable
- `.planning/phases/88-practice-round/88-CONTEXT.md` — locked decisions

### Secondary (MEDIUM confidence)
- Zustand persist `migrate` version parameter behavior — based on pattern observed in phases 86-87.1 codebase; empirical confirmation recommended for version=0 behavior

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already in project, no new installs
- Architecture: HIGH — all integration points directly verified in source
- Pitfalls: HIGH — QuoteCard and MatchupPhase store coupling confirmed by direct read; isolation boundary confirmed in verdictSync
- Migration strategy: MEDIUM — version=0 behavior not empirically confirmed

**Research date:** 2026-03-15
**Valid until:** 2026-04-15 (stable codebase, low churn risk)
