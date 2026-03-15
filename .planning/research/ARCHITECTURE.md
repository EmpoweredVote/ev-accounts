# Architecture Patterns

**Domain:** Read & Rank — Unified evaluate+rank flow, practice round, location-based quote filtering, coach marks, results polish, visual redesign (v2026.3.6)
**Researched:** 2026-03-14
**Confidence:** HIGH (all findings from direct source inspection of EV-readrank, EV-Backend, and PROJECT.md)

---

## Current Architecture (Baseline — as of v2026.3.5)

### Component Tree

```
App.tsx
  BrowserRouter
    Route "/"          → MainApp
      SiteHeader (ev-ui)
      ProgressHeader              ← target: DELETE
      main > PhaseContainer
        hub        → IssueHub
        evaluation → EvaluationPhase
          QuoteCard (framer-motion drag)
          SwipeBackground
          ActionButtons
          AgreedQuotesSidebar     (desktop split layout; inline @dnd-kit reorder + badge assign)
        ranking    → RankingPhase ← target: MERGE into EvaluationPhase
          SortableQuoteCard (@dnd-kit)
          BadgeIcons
        results    → ResultsPhase
    Route "/candidate/:id/alignment" → CandidateAlignmentPage
    Route "/animation-options"       → AnimationOptionsPage ← target: DELETE
```

### Current Phase State Machine

```typescript
type Phase = 'hub' | 'evaluation' | 'ranking' | 'results'
// IssueProgress.phase = 'evaluation' | 'ranking' | 'results'
```

### Current Data Flow

```
IssueHub
  fetchQuotesData()  →  GET /essentials/quotes  (module-level cache; mock fallback)
    → { quotes[], candidates[], issues[] }
  handleSelectIssue(id)
    → getQuotesForIssue(quotes, id) → shuffleArray → selectIssue(id, quotes, issueData)

EvaluationPhase
  agreeWithQuote / disagreeWithQuote
  nextQuote() — when index >= quotes.length: setPhase('ranking')

RankingPhase
  @dnd-kit reorder agreedQuotes
  assignBadge (diamond / gold per quoteId)
  setRankedQuotes / setPhase('results')

ResultsPhase
  fetchQuotesData() (for candidates)
  organizedQuotes: diamond → gold → agreed → disagreed
  buildEssentialsProfileUrl() → encodes verdict fragment

PhaseContainer (useEffect: phase==='results' && isLoggedIn)
  postVerdicts() → POST /compass/verdicts
```

### Zustand Store Key Points

- Persist key: `ev_readrank` (version 1)
- Persists: `phase`, `currentIssueId`, `issueProgress` map, plus legacy flat fields
- `IssueProgress` holds `quotesToEvaluate`, `currentQuoteIndex`, `agreedQuotes`, `disagreedQuotes`, `rankedQuotes`, `badgeAssignments`, `candidateMatches`, `completed`
- Legacy flat-state fields (`agreedQuotes`, `rankedQuotes`, etc.) duplicated from current issue for backwards compat

### Backend Surface (Relevant)

- `GET /essentials/quotes` — all quotes + candidates + issues; public; module-level cached
- `GET /essentials/quotes?politician_id=X` — filter by single politician UUID
- `POST /compass/verdicts` — bulk upsert verdicts; auth required (session cookie)
- `POST /essentials/politicians/search` — geocodes address via Google Maps, PostGIS ST_Covers/ST_Intersects, returns politicians by district hierarchy; **public, no auth**

---

## Target Architecture (v2026.3.6)

### Phase Model Change — The Core Structural Decision

The biggest change is dropping `'ranking'` as a top-level phase and merging it inline into the evaluate interaction. `'practice'` is added for the onboarding round.

```typescript
// v2 phase type
type Phase = 'practice' | 'hub' | 'evaluate' | 'results'

// v2 IssueProgress.phase (ranking no longer a separate sub-phase)
phase: 'evaluate' | 'results'
```

### New Component Tree

```
App.tsx
  BrowserRouter
    Route "/"  → MainApp
      SiteHeader (ev-ui)
      ← ProgressHeader removed
      main > PhaseContainer
        practice → PracticeRound              (NEW)
          PracticeQuoteCard                   (NEW — simplified QuoteCard, no candidateId)
          InlineRankPanel (practice mode)     (NEW — sortable, no badge assign)
          PracticeCompleteScreen              (NEW — "Ready for the real thing?")
        hub      → IssueHub                   (MODIFIED — AddressFilter + first-visit redirect)
          AddressFilter                       (NEW — Google Maps Places autocomplete)
        evaluate → EvaluatePhase              (REPLACES EvaluationPhase + RankingPhase)
          QuoteCard                           (unchanged interface)
          SwipeBackground                     (unchanged)
          ActionButtons                       (unchanged)
          InlineRankPanel (real mode)         (NEW — slides in at agreedQuotes.length >= 2)
          FirstIssueCoachMarks                (NEW — wraps EvaluatePhase on first real issue)
        results  → ResultsPhase               (MODIFIED — stagger reveal, simplified CTAs)
    Route "/candidate/:id/alignment" → CandidateAlignmentPage (unchanged)
    ← Route "/animation-options" removed
```

---

## Unified EvaluatePhase — Interaction Model

The defining behavior of the unified flow:

```
agreedQuotes.length = 0 or 1:
  → full-width QuoteCard stack (same as current EvaluationPhase)

agreedQuotes.length >= 2:
  desktop: left column = QuoteCard | right column = InlineRankPanel slides in
  mobile:  QuoteCard above | InlineRankPanel appears below (collapsed by default,
           expands on tap, or is always visible if screen height allows)

all quotes evaluated (index >= quotes.length):
  → InlineRankPanel expands to full width
  → "See Your Results" CTA appears
  → no separate "ranking" phase navigation
```

The slide-in of InlineRankPanel uses `framer-motion` `AnimatePresence` + `motion.div` with `initial={{ opacity: 0, x: 40 }}` and `layout` on the parent container. The parent switches from a single-column to a two-column layout via a CSS class change; `layout` animation smooths the QuoteCard column narrowing.

### InlineRankPanel

InlineRankPanel is a new component that absorbs the functionality currently split between `AgreedQuotesSidebar` (desktop inline badge+reorder) and `RankingPhase` (full-screen post-evaluation badge+reorder). It is the single canonical ranking UI.

```typescript
interface InlineRankPanelProps {
  mode: 'practice' | 'real';  // practice mode: no badge assign controls
  agreedQuotes: Quote[];
  badgeAssignments: BadgeAssignment;  // ignored in practice mode
  onReorder: (quotes: Quote[]) => void;
  onAssignBadge: (quoteId: string, badge: BadgeType) => void;  // noop in practice mode
  isEvaluationComplete: boolean;  // when true: show full-width + "See Results" CTA
  onComplete: () => void;
}
```

Internally: @dnd-kit `DndContext` + `SortableContext` + `useSortable` per card — same code as current `RankingPhase` SortableQuoteCard and `AgreedQuotesSidebar` SortableCompactQuoteCard, unified into one component.

---

## Practice Round Architecture

### Data

Practice quotes are fully static — no API call, no `candidateId`. Define in `src/data/practiceData.ts`:

```typescript
export interface PracticeQuote {
  id: string;
  text: string;  // pizza topping opinions
}
export const PRACTICE_QUOTES: PracticeQuote[] = [
  { id: 'pq-1', text: '...' },
  // 4-5 quotes total
];
```

### State

PracticeRound does NOT write to `issueProgress`. It only touches two store fields:

```typescript
practiceCompleted: boolean   // persisted; skip practice on return
```

On practice completion: `store.setPracticeCompleted()` then `store.setPhase('hub')`.

### Navigation Logic

```typescript
// In IssueHub, before render:
useEffect(() => {
  if (!practiceCompleted) {
    setPhase('practice');
  }
}, []);
```

`PhaseContainer` renders `<PracticeRound />` when `phase === 'practice'`. PracticeRound does not need `currentIssueId` — it is entirely self-contained.

### PracticeRound UX Flow

```
PracticeRound renders 4-5 static pizza quotes
  → user swipes/taps agree or disagree on each
  → after 2nd agree: InlineRankPanel appears (practice mode — no badge assign)
  → user drags to rank agreed quotes
  → taps "I'm ready — show me real issues"
    → setPracticeCompleted()
    → setPhase('hub')
```

---

## Location-Based Quote Filtering

### User Flow

```
IssueHub renders
  └─ AddressFilter (Google Maps Places autocomplete widget)
       user types address → Places autocomplete suggestion → onPlaceSelected(placeId, displayText)
         → fetch POST /essentials/politicians/search { query: displayText }
         → receive { politicians: [{ id, ... }] }
         → extract politicianIds = politicians.map(p => p.id)
         → store.setLocationContext({ address: displayText, placeId, politicianIds })
         → IssueHub re-renders: show "Filtered to your area" indicator

handleSelectIssue(issueId):
  const rawQuotes = getQuotesForIssue(allQuotes, issueId)
  const locationCtx = store.locationContext
  const filtered = locationCtx
    ? rawQuotes.filter(q => locationCtx.politicianIds.includes(q.candidateId ?? ''))
    : rawQuotes
  const quotesToUse = filtered.length >= 2 ? filtered : rawQuotes  // graceful fallback
  selectIssue(issueId, shuffleArray(quotesToUse), issueData)
```

The filter logic lives in `IssueHub.handleSelectIssue`. No new store action needed — `locationContext` is read synchronously at click time.

### Backend Reuse

`POST /essentials/politicians/search` already geocodes via Google Maps and runs PostGIS. The response returns politician objects with UUID `id` fields. These match `quote.candidateId` exactly (same UUID). **No new backend endpoint required for location filtering.**

### AddressFilter Component

```typescript
interface AddressFilterProps {
  onLocationSelected: (politicianIds: string[], displayText: string) => void;
  onClear: () => void;
  currentAddress: string | null;  // from store.locationContext?.address
}
```

Internally uses the Google Maps Places JavaScript API — same initialization pattern as `essentials/src/pages/Dashboard.jsx`. Read that file before implementing to replicate the exact `google.maps.places.Autocomplete` setup, `place_changed` event handler, and `getPlace()` call. Do not invent a new pattern.

After `onPlaceSelected`: call `POST /essentials/politicians/search` directly (raw `fetch`, not through `api.ts`, as it is a different domain concern).

### Essentials Context Auto-Detect (One-Way URL Param)

When Essentials links to Read & Rank filtered to a specific politician, it can append `?politician_id=UUID`. On mount, `IssueHub` reads `window.location.search` for `politician_id`, calls `GET /essentials/quotes?politician_id=X`, and pre-populates with only that politician's quotes. No address input needed for this path.

```typescript
// In IssueHub useEffect on mount:
const params = new URLSearchParams(window.location.search);
const politicianId = params.get('politician_id');
if (politicianId) {
  // fetch quotes filtered to this politician
  fetchFilteredQuotes(politicianId).then(data => {
    setFilteredQuotes(data.quotes);
    // clear param from URL to avoid stale state on reload
    window.history.replaceState(null, '', window.location.pathname);
  });
}
```

This is frontend-only. No backend change required.

---

## Coach Marks on First Real Issue

### Trigger Condition

```typescript
// In PhaseContainer or EvaluatePhase:
const isFirstRealIssue = Object.keys(issueProgress).length === 0;
// or more precisely: no completed real issues yet
```

### Component Design

`FirstIssueCoachMarks` wraps the `EvaluatePhase` UI with a step-by-step coach mark overlay. It uses the ev-ui `CoachMark` component.

Before building, read the CompassV2 coach mark implementation to understand:
- The step data structure
- How `CoachMark` accepts a target ref/selector for the SVG mask spotlight
- How step advancement works (user clicks "Next" or taps)

Suggested tour steps:
1. Spotlight QuoteCard area — "This is a real statement from a real politician"
2. Spotlight agree/disagree buttons — "Swipe right to agree, left to disagree"
3. Spotlight InlineRankPanel (deferred until it appears) — "Your agreed quotes collect here — drag to rank them"
4. Spotlight badge icons (deferred until rank panel is populated) — "Award Diamond and Gold to your top picks"

Steps 3–4 are deferred: the coach mark state machine waits until `agreedQuotes.length >= 2` before advancing to step 3, and until InlineRankPanel is rendered and stable. This requires the coach mark to be reactive to store state.

### Persistence

After the tour completes (or is dismissed), set `store.firstIssueCoachMarksSeen = true` (add this boolean to the store, persisted). Do not re-show on subsequent issues.

---

## Results Phase Changes

### What Changes

The data model is unchanged. `organizedQuotes`, `fetchQuotesData()` for candidates, `buildEssentialsProfileUrl()`, and `postVerdicts` trigger in `PhaseContainer` all remain the same.

Visual changes only:

1. **Remove the 800ms spinner.** Replace with a staggered card reveal. The `fetchQuotesData()` call is already cached after the first issue — it resolves instantly on subsequent issues. Remove the artificial `setTimeout(() => setLoading(false), 800)` delay. If candidates aren't loaded yet (first visit), show a brief shimmer skeleton instead of a spinner.

2. **Add a "hero reveal" interstitial.** Before cards animate in, show a full-width screen for ~1.2s:
   ```
   "Here's who said what"  (Fraunces, large)
   [animated dots or subtle particle burst]
   ```
   Then transition to the card list. Implement with `AnimatePresence` and a `stage` state: `'reveal' | 'cards'`.

3. **Simplified card CTAs.** Replace the current two-button row ("View Alignment" + "Essentials") with a single "View on Essentials" link per card. The CTA links to the Essentials politician profile with the verdict fragment. `CandidateAlignmentPage` stays in the codebase but is no longer surfaced in the primary results flow.

4. **Stagger animation on card list.** Use `variants` with `staggerChildren` on the list container:
   ```typescript
   const containerVariants = { animate: { transition: { staggerChildren: 0.07 } } };
   const cardVariants = { initial: { opacity: 0, y: 20 }, animate: { opacity: 1, y: 0 } };
   ```

---

## Chrome Cleanup

| Item | Action |
|------|--------|
| `ProgressHeader` component | Delete file; remove from `App.tsx` |
| Route `/animation-options` | Remove from `App.tsx` |
| `AnimationOptionsPage` component | Delete file |
| `CollectionPhase` component | Delete file (already not referenced in PhaseContainer) |
| `AgreedQuotesSidebar` component | Delete file (replaced by InlineRankPanel) |
| `RankingPhase` component | Delete file (merged into EvaluatePhase via InlineRankPanel) |
| `PhaseNavigation` component | Audit — if only used by CollectionPhase/ProgressHeader, delete |

---

## Store Schema: v1 → v2

```typescript
// v1 Phase
type Phase = 'hub' | 'evaluation' | 'ranking' | 'results'

// v2 Phase
type Phase = 'practice' | 'hub' | 'evaluate' | 'results'

// v1 IssueProgress.phase
phase: 'evaluation' | 'ranking' | 'results'

// v2 IssueProgress.phase
phase: 'evaluate' | 'results'

// New v2 top-level store fields
practiceCompleted: boolean         // default: false
firstIssueCoachMarksSeen: boolean  // default: false
locationContext: {
  address: string;
  placeId: string;
  politicianIds: string[];
} | null                           // default: null

// Migration (Zustand version 1 → 2):
phase 'evaluation' → 'evaluate'
phase 'ranking'    → 'evaluate'
phase 'hub', 'results' → unchanged
issueProgress[x].phase 'evaluation' | 'ranking' → 'evaluate'
issueProgress[x].phase 'results' → unchanged
```

Add `practiceCompleted`, `firstIssueCoachMarksSeen`, `locationContext` to `partialize`.

---

## Component Boundaries: New vs Modified vs Deleted

| Component | Status | Key Notes |
|-----------|--------|-----------|
| `PhaseContainer` | Modified | Add `practice` case; `evaluation` → `evaluate`; remove `ranking` |
| `EvaluatePhase` (was `EvaluationPhase`) | Major rewrite | Integrates InlineRankPanel; adds coach mark slot |
| `InlineRankPanel` | New | Core new component; absorbs AgreedQuotesSidebar + RankingPhase rank UI |
| `PracticeRound` | New | Self-contained; static pizza data; no API; only writes `practiceCompleted` |
| `PracticeQuoteCard` | New | Simplified QuoteCard variant; same framer-motion drag interface |
| `AddressFilter` | New | Google Maps Places; calls `POST /politicians/search`; writes to store |
| `FirstIssueCoachMarks` | New | Reads ev-ui CoachMark; wraps EvaluatePhase; reactive to store state |
| `IssueHub` | Modified | First-visit practice redirect; AddressFilter; filter logic in handleSelectIssue |
| `ResultsPhase` | Modified | Remove 800ms delay; hero reveal; stagger animation; single CTA per card |
| `QuoteCard` | Unchanged | Same interface; reused in EvaluatePhase and PracticeRound |
| `SwipeBackground` | Unchanged | |
| `ActionButtons` | Unchanged | |
| `BadgeIcons` | Unchanged | Reused in InlineRankPanel |
| `CandidateAlignmentPage` | Unchanged | Route stays; no longer primary CTA in results |
| `DevHelper` | Unchanged | |
| `useReadRankStore` | Modified | New Phase type; new fields; store version 2 + migration |
| `api.ts` | Unchanged | fetchQuotesData unchanged; location search uses raw fetch |
| `verdictFragment.ts` | Unchanged | |
| `verdictSync.ts` | Unchanged | |
| `useAuthState.ts` | Unchanged | |
| `matchingAlgorithm.ts` | Unchanged | |
| `useDeviceType.ts` | Unchanged | |
| `ProgressHeader` | Deleted | |
| `AnimationOptionsPage` | Deleted | |
| `CollectionPhase` | Deleted | Already unused |
| `AgreedQuotesSidebar` | Deleted | Replaced by InlineRankPanel |
| `RankingPhase` | Deleted | Replaced by InlineRankPanel inside EvaluatePhase |
| `PhaseNavigation` | Likely deleted | Audit before deleting |
| `SwipeInstructions` | Audit | May be superseded by coach marks |

---

## Data Flow Diagrams

### Location Filtering Flow

```
IssueHub mounts
  ├─ reads ?politician_id from URL
  │    → if present: fetch GET /essentials/quotes?politician_id=X
  │    → setFilteredQuotes; clear URL param
  │
  └─ AddressFilter
       user types address
       Google Places autocomplete fires
       fetch POST /essentials/politicians/search { query: address }
       response.politicians → extract IDs
       store.setLocationContext({ address, placeId, politicianIds })
         → IssueHub re-renders with "Filtered to your area" indicator

handleSelectIssue(issueId):
  rawQuotes = getQuotesForIssue(allQuotes, issueId)
  locationCtx = store.locationContext
  filtered = locationCtx ? rawQuotes.filter(q => locationCtx.politicianIds.includes(q.candidateId)) : rawQuotes
  quotesToUse = filtered.length >= 2 ? filtered : rawQuotes  // graceful fallback
  selectIssue(issueId, shuffle(quotesToUse), issueData)
```

### Practice → Hub → Evaluate Flow

```
User first visits readrank.empowered.vote
  store.practiceCompleted === false
    → IssueHub useEffect: setPhase('practice')
    → PhaseContainer renders PracticeRound
      user swipes pizza quotes
      user ranks agreed quotes
      taps "I'm ready"
        → store.setPracticeCompleted()
        → setPhase('hub')
    → PhaseContainer renders IssueHub
      user selects real issue
        → setPhase('evaluate') via selectIssue
    → PhaseContainer renders EvaluatePhase
      store.Object.keys(issueProgress).length === 0 → isFirstRealIssue = true
        → FirstIssueCoachMarks wraps the UI
```

### Verdict Sync (Unchanged)

```
PhaseContainer useEffect:
  phase === 'results' && isLoggedIn && !hasSynced.current
    → postVerdicts(issueProgress)  → POST /compass/verdicts
```

This trigger condition still works correctly because the phase string `'results'` is unchanged.

---

## Backend Changes for v2026.3.6

**No new backend endpoints required** for any of the core features:

| Feature | Backend Needs |
|---------|---------------|
| Unified evaluate+rank | None — frontend only |
| Practice round | None — static data |
| Location filter | Reuse `POST /essentials/politicians/search` (existing, public) |
| Coach marks | None — frontend only |
| Results polish | None — frontend only |
| Visual redesign | None — frontend only |

Optional backend enhancement (not required for v1, worth doing if quote dataset grows): Add `?politician_ids=uuid1,uuid2` multi-filter to `GET /essentials/quotes` for server-side location filtering. At 61 current quotes, client-side filter is fine.

---

## Build Order (Dependency-Ordered)

### Phase 1: Chrome Cleanup + Phase Model Reset

**What:** Delete `ProgressHeader`, `AnimationOptionsPage`, `CollectionPhase`. Update `Phase` type. Rename `EvaluationPhase` → `EvaluatePhase`. Add store version 2 migration (phase name remap). Update `PhaseContainer` switch statement.

**Why first:** Everything else builds on the clean phase model. Doing cleanup first prevents migrating the same files twice. The migration must be tested before adding new state on top.

**Risk note:** The store migration must not silently lose in-progress sessions. Write a test or manually verify: load page with `phase: 'evaluation'` in localStorage, confirm it becomes `'evaluate'` after migration and the session resumes correctly.

**Delivers:** Clean codebase with no dead code; same user-facing behavior as before.

### Phase 2: InlineRankPanel + Unified EvaluatePhase

**What:** Build `InlineRankPanel`. Rewrite `EvaluationPhase` → `EvaluatePhase` to include `InlineRankPanel`. Delete `AgreedQuotesSidebar` and `RankingPhase`. Add `AnimatePresence` slide-in at `agreedQuotes.length >= 2`.

**Depends on:** Phase 1 (clean phase model).

**Why before practice:** Practice round reuses the same interaction pattern as EvaluatePhase. Build the canonical version first, then simplify for practice.

**Delivers:** The core "unified flow" milestone requirement.

### Phase 3: Practice Round

**What:** `src/data/practiceData.ts`, `PracticeRound`, `PracticeQuoteCard`. Add `practiceCompleted` to store. Wire into `PhaseContainer` and `IssueHub` first-visit redirect.

**Depends on:** Phase 2 (PracticeRound uses InlineRankPanel in practice mode).

**Delivers:** Onboarding flow; users never land cold on the real issues.

### Phase 4: Location Filtering

**What:** `AddressFilter` component, `locationContext` store fields, filter logic in `IssueHub.handleSelectIssue`, URL `?politician_id` auto-detect on mount.

**Depends on:** Phase 1 (clean store for new fields). Independent of Phases 2–3.

**Why after eval/practice:** Location filter is an IssueHub-only concern. EvaluatePhase and ResultsPhase are unaffected.

**Note on AddressFilter:** Read `essentials/src/pages/Dashboard.jsx` Google Maps initialization pattern before implementing. Do not invent a new init approach.

**Delivers:** Location-aware quote filtering.

### Phase 5: Coach Marks

**What:** `FirstIssueCoachMarks` component wrapping `EvaluatePhase`. Add `firstIssueCoachMarksSeen` to store.

**Depends on:** Phase 2 (coach marks highlight InlineRankPanel — must exist first). Must read ev-ui `CoachMark` component docs/source before building.

**Delivers:** Guided first-issue experience.

### Phase 6: Results Polish + Visual Redesign

**What:** Remove 800ms spinner; add hero reveal interstitial; stagger animation on card list; single "View on Essentials" CTA per card. Visual redesign (colors, spacing, typography — within existing design system).

**Depends on:** Phase 1 (clean phase model). Independent of Phases 2–5.

**Why last:** Pure visual layer — safe to build in parallel with Phases 2–5 or after functional plumbing is stable.

**Delivers:** Polished results reveal.

---

## Integration Points With Other Apps

| Concern | Direction | Mechanism | Change in v2026.3.6 |
|---------|-----------|-----------|---------------------|
| Verdicts to Essentials (guest) | Read & Rank → Essentials | URL fragment `#compass=base64` | Unchanged |
| Verdicts to backend (logged-in) | Read & Rank → API | POST /compass/verdicts | Unchanged; `phase === 'results'` trigger still valid |
| Essentials → Read & Rank pre-filter | Essentials → Read & Rank | `?politician_id=UUID` URL param | New; frontend-only |
| Location search | Read & Rank → API | POST /essentials/politicians/search | Reuse existing; no backend change |
| CoachMark component | ev-ui → Read & Rank | npm `@chrisandrewsedu/ev-ui` | New import; check current ev-ui version for CoachMark API |
| SiteHeader | ev-ui → Read & Rank | Already in App.tsx | Unchanged |
| Google Maps Places | Read & Rank → Browser API | Same CDN/loader pattern as Essentials | New usage; replicate Essentials init |

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Making InlineRankPanel Only Appear After All Quotes Are Evaluated

**What:** Waiting until `currentQuoteIndex >= quotesToEvaluate.length` before showing InlineRankPanel.

**Why bad:** This is the old two-phase flow with a delayed trigger — not "unified." The user still experiences a hard context switch.

**Instead:** Show InlineRankPanel as soon as `agreedQuotes.length >= 2`, while the evaluation deck continues. User can rank and badge while evaluating remaining quotes. The list naturally grows as more quotes are agreed.

### Anti-Pattern 2: Giving Practice Round an IssueProgress Entry

**What:** Storing practice session data under an issueId (e.g., `"practice"`) in `issueProgress`.

**Why bad:** Pollutes the hub progress display (shows "1/4 completed" when only practice is done). Practice badge assignments would incorrectly appear in verdict sync.

**Instead:** Practice round is stateless except for `practiceCompleted: boolean`. No `issueProgress` entry. `selectIssue` is never called during practice.

### Anti-Pattern 3: Prop-Drilling Location Filter Through Components

**What:** Fetching politicians in `AddressFilter`, passing results up to `IssueHub` via callback, then passing down to `handleSelectIssue` via closure.

**Why bad:** Creates timing issues (user selects issue before address search resolves). Creates prop-drilling through multiple layers.

**Instead:** `AddressFilter` writes `locationContext` directly to the Zustand store. `IssueHub.handleSelectIssue` reads `store.locationContext` synchronously at click time. If address search hasn't resolved yet when the user taps an issue, `locationContext` is null and all quotes are used — graceful degradation.

### Anti-Pattern 4: Breaking verdictSync on Phase Rename

**What:** Renaming `'evaluation'` to `'evaluate'` but accidentally also renaming `'results'` or the comparison string in `PhaseContainer`'s useEffect.

**Why bad:** `postVerdicts` silently stops triggering. No console error; verdicts just don't sync.

**Prevention:** The `postVerdicts` trigger checks `phase === 'results'` — verify this string is unchanged after the migration. Add a comment in `PhaseContainer` flagging this dependency.

### Anti-Pattern 5: Re-fetching Quote Data in AddressFilter

**What:** AddressFilter calling `fetchQuotesData()` to get a fresh quote list after location is set.

**Why bad:** The quote list from `fetchQuotesData()` is already cached at the module level in `api.ts`. Location filtering happens client-side against the cached quotes, not by re-fetching. A second fetch would clear the cache and add latency.

**Instead:** Location filter is applied in `IssueHub.handleSelectIssue` against the already-cached `allQuotes` array. `AddressFilter` only fetches politician IDs (via `/politicians/search`), never quotes.

---

## Scalability Considerations

| Concern | Now (~61 quotes, ~23 politicians) | Future (500+ quotes) |
|---------|-----------------------------------|-----------------------|
| Client-side location filter | Fine — in-memory, instantaneous | Add `?politician_ids=uuid1,uuid2` to GET /essentials/quotes for server-side pre-filter |
| Practice data | 4-5 static quotes, no API | Always static; no scale concern |
| `cachedData` in api.ts | Module-level variable, cleared on reload | Acceptable for SPA; add TTL if quote data updates frequently |
| Store localStorage size | Small; per-issue progress fits easily | Add `partialize` trim for completed progress entries older than 30 days |
| AddressFilter Google Maps requests | ~1 per user session (address autocomplete) | Within Google Maps free tier (28K/month) |

---

## Sources

All findings from direct source inspection (HIGH confidence):

- `/Users/chrisandrews/Documents/GitHub/EV-readrank/src/store/useReadRankStore.ts` — full Zustand state shape, phase type, IssueProgress, persist config
- `/Users/chrisandrews/Documents/GitHub/EV-readrank/src/components/PhaseContainer.tsx` — phase switch, postVerdicts trigger
- `/Users/chrisandrews/Documents/GitHub/EV-readrank/src/components/EvaluationPhase.tsx` — split layout, drag, handleComplete, AgreedQuotesSidebar
- `/Users/chrisandrews/Documents/GitHub/EV-readrank/src/components/RankingPhase.tsx` — @dnd-kit sortable, badge assign, SortableQuoteCard
- `/Users/chrisandrews/Documents/GitHub/EV-readrank/src/components/AgreedQuotesSidebar.tsx` — inline reorder + badge in sidebar
- `/Users/chrisandrews/Documents/GitHub/EV-readrank/src/components/IssueHub.tsx` — fetchQuotesData, handleSelectIssue, progress display
- `/Users/chrisandrews/Documents/GitHub/EV-readrank/src/components/ResultsPhase.tsx` — organizedQuotes, 800ms spinner, card structure
- `/Users/chrisandrews/Documents/GitHub/EV-readrank/src/components/QuoteCard.tsx` — framer-motion drag interface
- `/Users/chrisandrews/Documents/GitHub/EV-readrank/src/components/ProgressHeader.tsx` — confirm it is delete-safe
- `/Users/chrisandrews/Documents/GitHub/EV-readrank/src/components/CollectionPhase.tsx` — confirm already unused
- `/Users/chrisandrews/Documents/GitHub/EV-readrank/src/data/api.ts` — fetchQuotesData, module-level cache, mock fallback
- `/Users/chrisandrews/Documents/GitHub/EV-readrank/src/utils/verdictFragment.ts` — buildEssentialsProfileUrl, buildVerdictFragment
- `/Users/chrisandrews/Documents/GitHub/EV-readrank/src/utils/verdictSync.ts` — postVerdicts, buildVerdictPayload
- `/Users/chrisandrews/Documents/GitHub/EV-readrank/src/hooks/useAuthState.ts` — auth check pattern
- `/Users/chrisandrews/Documents/GitHub/EV-readrank/src/App.tsx` — route structure, ProgressHeader import
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/routes.go` — GET /quotes, POST /politicians/search endpoints
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/handlers.go` — GetQuotes implementation (LATERAL JOIN, topic_key, candidate map), SearchPoliticians (PostGIS path)
- `/Users/chrisandrews/Documents/GitHub/.planning/PROJECT.md` — v2026.3.6 milestone goals and constraints

---

*Architecture research for: v2026.3.6 Read & Rank Redesign*
*Researched: 2026-03-14*
