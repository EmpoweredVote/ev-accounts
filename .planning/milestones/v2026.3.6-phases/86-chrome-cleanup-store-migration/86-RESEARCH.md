# Phase 86: Chrome Cleanup + Store Migration - Research

**Researched:** 2026-03-14
**Domain:** Zustand persist migration, React component deletion, TypeScript cleanup
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Profile menu reset:**
- Single "Clear Read & Rank" menu item — matches Compass's single "Clear Compass" pattern
- Confirmation dialog before wiping: "Clear all your Read & Rank progress? This can't be undone." with Cancel/Clear buttons
- Clears localStorage only — server-side quote_verdicts remain (no DELETE endpoint needed)
- Menu order: "Clear Read & Rank" above "Sign out" (matches Compass layout)

**Store v2 migration:**
- Keep persist key 'ev_readrank', bump version to 2
- v2 migrate function resets to clean initial state — all old progress wiped (ranking phase won't exist in new flow)
- Delete RankingPhase component and all its imports
- partialize returns only `{ phase, currentIssueId, issueProgress }` — no redundant legacy data

**Badge system cleanup:**
- Remove BadgeType, BadgeAssignment interfaces from store
- Remove assignBadge, clearBadge store actions and badgeAssignments from IssueProgress
- Delete BadgeIcons component
- Strip diamond/gold point bonuses from matchingAlgorithm.ts — rank-only scoring per FLOW-05
- Strip badge data from verdictFragment.ts encoder (Essentials only reads agree/disagree + rank order)

**Legacy flat state removal:**
- Remove all deprecated flat fields: issueTitle, questionText, topicId, flat agreedQuotes, disagreedQuotes, rankedQuotes, candidateMatches, badgeAssignments
- Remove legacy methods: setQuotes, setIssueInfo
- Update all component reads from `store.agreedQuotes` etc. to `getCurrentIssueProgress()` pattern
- Audit and remove orphaned components (CollectionPhase if unused, any others found)

### Claude's Discretion
- Whether to remove 'ranking' from Phase union now or leave for Phase 87 — Claude picks based on what's cleanest given RankingPhase deletion
- Any other dead code discovered during audit

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| FLOW-06 | Zustand store migrated to version 2 with clean-reset for returning users | Zustand v5 persist middleware supports `version` + `migrate` — bump to 2, reset to initial state in migrate fn |
| CHRM-01 | ProgressHeader removed entirely | Component is self-contained in ProgressHeader.tsx; App.tsx imports and renders it directly — both lines removable |
| CHRM-02 | AnimationOptionsPage and /animation-options route removed | AnimationOptionsPage.tsx is standalone; App.tsx imports it and registers `<Route path="/animation-options">` — both lines removable |
| CHRM-03 | Reset functionality moved to account/profile menu (matching Compass pattern) | CompassV2 Layout.jsx uses `window.confirm` + localStorage.removeItem pattern; ReadRank uses Zustand `reset()` instead |
</phase_requirements>

---

## Summary

Phase 86 is a surgical cleanup phase: delete three chrome components, remove the badge system end-to-end, strip legacy flat state from the Zustand store, and migrate the persist store to version 2 so returning users with stale `phase: 'ranking'` in localStorage land cleanly on the hub.

All source files have been read directly. Every import reference, every consumer of badge state, and every legacy flat-field read has been identified. There are no surprises — the deletions are bounded and the migration path is clear.

The Compass pattern for "reset in profile menu" is confirmed from reading `CompassV2/src/components/Layout.jsx`: `window.confirm` dialog, then `localStorage.removeItem` calls, then context/store reset. ReadRank's equivalent uses Zustand `reset()` which already calls `set(initialState)` — the new v2 initialState simply omits all badge and legacy fields.

**Primary recommendation:** Tackle store migration first (task 1), then delete components (task 2), then update remaining consumers (task 3), then wire the profile menu reset (task 4). This order ensures TypeScript errors guide the cleanup — each deletion makes the compiler point to remaining consumers.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| zustand | ^5.0.9 | State management with persist | Already in use; persist middleware handles localStorage automatically |
| react-router-dom | ^7.11.0 | Routing | Already in use; removing a `<Route>` is trivial |
| TypeScript | ~5.9.3 | Type checking | Build command is `tsc -b && vite build` — TS errors block deploy |

### No new dependencies required
This phase is entirely deletion + migration work. Zero new packages.

---

## Architecture Patterns

### Zustand v5 Persist Migration Pattern
The store is already at version 1 with a pass-through migrate function. Bumping to version 2 with a reset-to-initial migrate is the standard Zustand pattern for breaking schema changes.

**How Zustand persist versioning works (confirmed from codebase):**
- `version: N` is stored alongside the state in localStorage under the persist key
- When the app loads, if stored version < current version, `migrate(persistedState, storedVersion)` is called
- The return value replaces the persisted state
- Returning `initialState` (or a partial) causes Zustand to rehydrate from that clean base

```typescript
// Source: /EV-readrank/src/store/useReadRankStore.ts (current v1 pattern to migrate FROM)
{
  name: 'ev_readrank',
  version: 1,
  migrate: (persistedState, _version) => {
    return persistedState as ReadRankState  // pass-through — needs to become reset
  },
  partialize: (state) => ({
    phase: state.phase,
    currentIssueId: state.currentIssueId,
    issueProgress: state.issueProgress,
    // Legacy fields — these get removed in v2
    agreedQuotes: state.agreedQuotes,
    ...
  }),
}
```

```typescript
// Target v2 pattern
{
  name: 'ev_readrank',
  version: 2,
  migrate: (_persistedState, _version) => {
    // Any old state (v1 with phase:'ranking', badge fields, legacy flat) gets wiped
    return {
      phase: 'hub',
      currentIssueId: null,
      issueProgress: {},
    };
  },
  partialize: (state) => ({
    phase: state.phase,
    currentIssueId: state.currentIssueId,
    issueProgress: state.issueProgress,
    // No legacy fields
  }),
}
```

### Profile Menu Reset Pattern (Compass)
Confirmed from `CompassV2/src/components/Layout.jsx`:

```javascript
// Source: /CompassV2/src/components/Layout.jsx
const profileItems = [
  ...(isAdmin ? [{ label: "Admin", href: "/admin" }] : []),
  { label: "Reset compass", onClick: handleClearCompass },  // Clear above Sign out
  { label: "Logout", onClick: logout },
];

const handleClearCompass = () => {
  if (!window.confirm("Reset your compass? This will remove all your topics, answers, and stances.")) return;
  // localStorage clears...
  // context state resets...
};
```

ReadRank equivalent:

```typescript
// Target pattern for App.tsx
const handleClearReadRank = () => {
  if (!window.confirm("Clear all your Read & Rank progress? This can't be undone.")) return;
  reset();  // Zustand reset() — calls set(initialState), which persist writes to localStorage
};

const profileMenu = loading
  ? undefined
  : isLoggedIn
    ? {
        label: userName || 'Account',
        items: [
          { label: 'Clear Read & Rank', onClick: handleClearReadRank },
          { label: 'Sign out', onClick: logout },
        ]
      }
    : { label: 'Account', items: [{ label: 'Sign in', href: `...` }] };
```

Note: `window.confirm` is sufficient — the CONTEXT.md specifies "Cancel/Clear buttons" which `window.confirm` provides natively. No custom dialog component needed.

### Component Deletion Pattern
Delete file → remove import → remove usage → fix TypeScript errors. Order matters:
1. Delete component file
2. Remove import in consumers
3. Remove `<Route>` or `{renderPhase()}` case
4. Fix any residual TS errors

### Anti-Patterns to Avoid
- **Commenting out instead of deleting:** Dead code should be gone, not commented out
- **Keeping BadgeAssignment in IssueProgress "just in case":** The migration wipes all old data anyway — the type must match the new shape
- **Using `window.location.reload()` after reset:** The Zustand persist middleware writes to localStorage synchronously; `reset()` is sufficient without reload

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| localStorage migration | Custom migration logic | Zustand persist `version` + `migrate` | Already in place; just bump version |
| Confirmation dialog | Custom modal component | `window.confirm()` | Compass uses it; consistent; no new component |
| Store wipe on reset | Manual localStorage.removeItem | Zustand `reset()` + `set(initialState)` | Persist middleware handles storage sync automatically |

---

## Complete File Audit

### Files to DELETE entirely
| File | Reason |
|------|--------|
| `src/components/ProgressHeader.tsx` | CHRM-01 — entire component removed |
| `src/components/AnimationOptionsPage.tsx` | CHRM-02 — entire component and route removed |
| `src/components/BadgeIcons.tsx` | Badge system removal — exports DiamondBadge, GoldBadge, BadgeLabel |
| `src/components/RankingPhase.tsx` | Store migration — ranking phase eliminated, imports BadgeIcons |
| `src/components/CollectionPhase.tsx` | Dead code — not referenced in PhaseContainer.tsx or App.tsx; calls setPhase('ranking') which is being removed |

### Files to MODIFY

**`src/App.tsx`**
- Remove: `import { ProgressHeader }` (line 4)
- Remove: `import { AnimationOptionsPage }` (line 7)
- Remove: `<ProgressHeader />` (line 27)
- Remove: `<Route path="/animation-options" element={<AnimationOptionsPage />} />` (line 41)
- Add: `import { useReadRankStore }` to get `reset`
- Add: `handleClearReadRank` function using `reset()` and `window.confirm`
- Modify: `profileMenu` to include "Clear Read & Rank" item above "Sign out"

**`src/store/useReadRankStore.ts`**
- Remove types: `BadgeType`, `BadgeAssignment`
- Remove from `IssueProgress`: `badgeAssignments: BadgeAssignment`
- Remove from `ReadRankState` interface: all legacy flat fields (`issueTitle`, `questionText`, `topicId`, flat `quotesToEvaluate`, `currentQuoteIndex`, `agreedQuotes`, `disagreedQuotes`, `rankedQuotes`, `badgeAssignments`, `candidateMatches`)
- Remove from `ReadRankState` interface: `setQuotes`, `setIssueInfo`, `assignBadge`, `clearBadge`
- Update `Phase` type: Remove `'ranking'` — becomes `'hub' | 'evaluation' | 'results'` (clean since RankingPhase is deleted)
- Update `IssueProgress.phase`: Remove `'ranking'` — becomes `'evaluation' | 'results'`
- Remove from `initialState`: all legacy flat fields and badgeAssignments
- Remove `createEmptyIssueProgress`: Remove `badgeAssignments` field
- Remove implementations: `assignBadge`, `clearBadge`, `setQuotes`, `setIssueInfo`
- Update `selectIssue`: Remove all legacy flat state writes
- Update `nextQuote`: Remove `phase: 'ranking'` transition — should go to `'results'` or stay in `'evaluation'`
- Update `partialize`: Strip to `{ phase, currentIssueId, issueProgress }` only
- Bump `version: 1` to `version: 2`
- Replace `migrate` with clean reset function

**`src/components/PhaseContainer.tsx`**
- Remove: `import { RankingPhase }` (line 7)
- Remove: `case 'ranking': return <RankingPhase />;` (line 29)

**`src/components/EvaluationPhase.tsx`**
- Remove: `import { questionText }` from store (line 21) — or update if `questionText` is being renamed
- Remove: `setPhase('ranking')` call in `handleComplete` (line 92) — replace with direct to results
- Remove: questionBanner using `questionText` (line 182) — or source from `getCurrentIssueProgress()` if issue question is needed
- Remove: "Assign your badges in the sidebar" hint text (line 153)
- Remove: `'Rank Your Priorities'` mobile button text — replace with 'See Your Results'

**`src/components/AgreedQuotesSidebar.tsx`**
- Remove: `import { DiamondBadge, GoldBadge }` (line 22)
- Remove: badge-related props, state, and rendering from `SortableCompactQuoteCard`
- Remove: badge status section from sidebar header
- Simplify to rank-only display (no badge icons, no "Award badge" section)

**`src/components/ResultsPhase.tsx`**
- Remove: `DiamondBadgeDisplay`, `GoldBadgeDisplay` inline components (lines 10-42)
- Remove: `badgeAssignments` from store destructure (line 222)
- Remove: `topicId` from store destructure (legacy flat field being removed)
- Remove: Badge-based `organizedQuotes` sorting (diamond/gold to top) — use rank order only
- Remove: Diamond/Gold stat boxes from Summary Stats (lines 317-318)
- Update: `buildEssentialsProfileUrl` call — `topicId` must come from `getCurrentIssueProgress()` instead

**`src/utils/matchingAlgorithm.ts`**
- Remove: `import { BadgeAssignment }` from store
- Remove: `BADGE_POINTS` constant
- Remove: `badgeAssignments` parameter from `calculateAlignment`
- Remove: `getPointsForQuote` helper (badge-based scoring)
- Remove: `badge` field from `candidateQuoteMatches` entries
- Rewrite scoring: rank position → points (e.g., `points = rankedQuotes.length - index + 1` or simple `1/rank` weighting)
- Remove: badge bonus from `maxPossiblePoints` calculation
- Remove: `badgeAssignments` parameter from `fetchMatchingResults`

**`src/utils/verdictFragment.ts`**
- Already clean — no badge data references. The fragment only encodes `agreed`/`disagreed` verdicts from `agreedQuotes`, `rankedQuotes`, `disagreedQuotes`. No changes needed.

**`src/utils/verdictSync.ts`**
- Already clean — only sends `{ quote_id, verdict }` pairs. No badge data. No changes needed.

**`src/components/IssueHub.tsx`**
- Line 28: `if (progress.phase === 'ranking')` — remove this case, update badge-references in `getProgressInfo`
- Remove: "Assigning badges" progress text for ranking phase

---

## Common Pitfalls

### Pitfall 1: nextQuote goes to 'ranking' — must reroute
**What goes wrong:** `nextQuote()` in the store currently sets `phase: 'ranking'` when all quotes are evaluated. After deleting RankingPhase, calling this crashes the app.
**Why it happens:** The old three-phase flow was: evaluation → ranking → results.
**How to avoid:** In the v2 store, `nextQuote` should NOT auto-transition to any new phase when all quotes are evaluated — it should stay at `evaluation` phase with `currentQuoteIndex >= quotesToEvaluate.length`. `EvaluationPhase.tsx`'s `handleComplete` already handles the explicit transition, so `nextQuote` should just increment the index.
**Warning signs:** `phase` becomes 'ranking' in localStorage after completing evaluation.

### Pitfall 2: EvaluationPhase reads legacy flat fields
**What goes wrong:** `EvaluationPhase.tsx` destructures `quotesToEvaluate`, `currentQuoteIndex`, `agreedQuotes`, `disagreedQuotes`, `questionText` directly from the store — these are legacy flat fields being deleted.
**Why it happens:** Components haven't been updated to use `getCurrentIssueProgress()`.
**How to avoid:** Replace all direct flat-field reads with `const progress = getCurrentIssueProgress()` and `progress?.quotesToEvaluate` etc. `questionText` maps to the issue's `question` field in `IssueData`, which must be retrieved via `getIssueProgress(currentIssueId)`.
**Warning signs:** TypeScript build errors after removing legacy fields from the interface.

### Pitfall 3: ResultsPhase reads legacy flat fields
**What goes wrong:** `ResultsPhase.tsx` line 222 destructures `rankedQuotes`, `agreedQuotes`, `disagreedQuotes`, `badgeAssignments`, `topicId` directly from the store.
**Why it happens:** Legacy flat-field pattern.
**How to avoid:** Switch to `getCurrentIssueProgress()` for all issue-specific data.

### Pitfall 4: AgreedQuotesSidebar reads legacy flat fields
**What goes wrong:** `AgreedQuotesSidebar.tsx` line 165-173 reads `agreedQuotes`, `badgeAssignments`, `assignBadge`, `quotesToEvaluate`, `currentQuoteIndex` from store.
**Why it happens:** Legacy flat-field pattern.
**How to avoid:** Switch to `getCurrentIssueProgress()`.

### Pitfall 5: IssueHub uses 'ranking' phase check
**What goes wrong:** `getProgressInfo` in IssueHub checks `progress.phase === 'ranking'` to show "Assigning badges" status text (line 28). This must be removed.
**How to avoid:** Remove the `'ranking'` case from the progress info helper.

### Pitfall 6: Stale TypeScript compile cache
**What goes wrong:** `tsc -b` with project references can cache old output. After deleting files, the build may still pass if .tsbuildinfo is stale.
**How to avoid:** Run `tsc --noEmit` (or `tsc -b --force`) to verify the clean build.

### Pitfall 7: partialize returning undefined fields
**What goes wrong:** If `partialize` references fields that no longer exist on the type (e.g. `state.badgeAssignments`), TypeScript will error at build time.
**How to avoid:** Update `partialize` as part of the same store edit that removes the fields.

---

## Code Examples

### v2 Store Type Shape (target)

```typescript
// Source: derived from /EV-readrank/src/store/useReadRankStore.ts + CONTEXT.md decisions

export type Phase = 'hub' | 'evaluation' | 'results';  // 'ranking' removed

export interface IssueProgress {
  issueId: string;
  phase: 'evaluation' | 'results';  // 'ranking' removed
  quotesToEvaluate: Quote[];
  currentQuoteIndex: number;
  agreedQuotes: Quote[];
  disagreedQuotes: Quote[];
  rankedQuotes: RankedQuote[];
  // badgeAssignments removed
  candidateMatches: MatchingResult[];
  completed: boolean;
}

interface ReadRankState {
  // Navigation
  phase: Phase;
  currentIssueId: string | null;
  issueProgress: Record<string, IssueProgress>;

  // Actions (badge actions removed, legacy methods removed)
  setPhase: (phase: Phase) => void;
  selectIssue: (issueId: string, quotes: Quote[], issueData: IssueData) => void;
  nextQuote: () => void;
  agreeWithQuote: (quote: Quote) => void;
  disagreeWithQuote: (quote: Quote) => void;
  rankQuote: (quoteId: string, newRank: number) => void;
  setRankedQuotes: (quotes: Quote[]) => void;
  reorderAgreedQuotes: (quotes: Quote[]) => void;
  // assignBadge removed
  // clearBadge removed
  setCandidateMatches: (matches: MatchingResult[]) => void;
  goToHub: () => void;
  reset: () => void;
  resetIssue: (issueId: string) => void;

  // Helpers
  getCurrentIssueProgress: () => IssueProgress | null;
  getIssueProgress: (issueId: string) => IssueProgress | null;
  getAllIssueProgress: () => Record<string, IssueProgress>;

  // Legacy flat fields REMOVED
}
```

### Profile Menu Reset in App.tsx (target)

```typescript
// Source: pattern from /CompassV2/src/components/Layout.jsx, adapted for ReadRank

function MainApp() {
  const { isLoggedIn, userName, loading, logout } = useAuthState();
  const { reset } = useReadRankStore();

  const handleClearReadRank = () => {
    if (!window.confirm("Clear all your Read & Rank progress? This can't be undone.")) return;
    reset();
  };

  const profileMenu = loading
    ? undefined
    : isLoggedIn
      ? {
          label: userName || 'Account',
          items: [
            { label: 'Clear Read & Rank', onClick: handleClearReadRank },
            { label: 'Sign out', onClick: logout },
          ],
        }
      : {
          label: 'Account',
          items: [{ label: 'Sign in', href: `...` }],
        };
  // ...
}
```

### Rank-only Scoring (matchingAlgorithm.ts target)

```typescript
// Badge-based scoring REMOVED. Rank position-based scoring.
// Points = (totalQuotes - rank + 1) gives highest-ranked quote most points.

export function calculateAlignment(
  rankedQuotes: RankedQuote[],
  quoteCandidateMap: QuoteCandidateMap,
  candidates: Candidate[]
  // badgeAssignments parameter removed
): MatchingResult[] {
  const totalQuotes = rankedQuotes.length;

  // ...
  rankedQuotes.forEach((rankedQuote, index) => {
    const candidateId = quoteCandidateMap[rankedQuote.id];
    if (candidateId) {
      const points = totalQuotes - index; // rank 1 = highest points
      candidatePoints[candidateId] += points;
      candidateQuoteMatches[candidateId].push({
        userRank: index + 1,
        quoteId: rankedQuote.id,
        points,
        // badge field removed
      });
    }
  });

  const maxPossiblePoints = totalQuotes * (totalQuotes + 1) / 2; // triangular sum
  // ...
}
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Legacy flat fields mirroring issue progress | `getCurrentIssueProgress()` accessor | Removes ~10 duplicate fields from store |
| Badge system (diamond/gold bonuses) | Rank-order-only scoring | Simplifies matchingAlgorithm.ts significantly |
| Pass-through persist migrate | Reset migrate (v2) | Any user with old state lands clean on hub |
| ProgressHeader as persistent chrome | Reset in profile menu only | Cleaner layout, matches Compass pattern |

---

## Open Questions

1. **`nextQuote` auto-transition behavior after evaluation complete**
   - What we know: Currently `nextQuote` sets `phase: 'ranking'` when `nextIndex >= quotesToEvaluate.length`
   - What's unclear: In v2, `nextQuote` should not auto-transition — `EvaluationPhase.handleComplete` triggers the explicit phase change. Should `nextQuote` just cap at the end index, or should it auto-go to 'results'?
   - Recommendation: Remove the auto-transition from `nextQuote`; let `EvaluationPhase` call `setPhase('results')` explicitly via `handleComplete`. This matches the existing mouse-device path (line 89: `setPhase('results')`).

2. **`questionText` in EvaluationPhase and RankingPhase**
   - What we know: `questionText` is a legacy flat field that will be deleted. Both `EvaluationPhase.tsx` (line 21) and `RankingPhase.tsx` (being deleted) use it.
   - What's unclear: After removing `questionText` flat field, `EvaluationPhase` still needs the question text to show the question banner.
   - Recommendation: Get from `getCurrentIssueProgress()` is not enough — `IssueProgress` doesn't store the issue question text. The question text must be fetched from the loaded issues data, or EvaluationPhase reads it from a local state populated when `selectIssue` is called. Simplest: remove the question banner from EvaluationPhase entirely (it's an optional UI element), or pass question text down as a prop from a parent that has the issues data.

3. **`topicId` in ResultsPhase for `buildEssentialsProfileUrl`**
   - What we know: `topicId` is a legacy flat field being deleted. `ResultsPhase` line 222 uses it for `buildEssentialsProfileUrl`.
   - Recommendation: Use `currentIssueId` from the store instead — it's the same value (the issue UUID). `currentIssueId` stays in v2.

---

## Validation Architecture

> `workflow.nyquist_validation` key is absent from config.json — treating as enabled.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None detected — no test config files found |
| Config file | None |
| Quick run command | `cd EV-readrank && npm run build` (TypeScript + Vite) |
| Full suite command | `cd EV-readrank && npm run build` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FLOW-06 | Returning user with old localStorage (phase:'ranking') lands on hub without errors | manual-only | N/A — requires browser localStorage manipulation | N/A |
| FLOW-06 | TypeScript builds cleanly with no Phase union references to 'ranking' | build | `cd EV-readrank && npm run build` | ✅ |
| CHRM-01 | ProgressHeader not in DOM — no progress bar visible | manual-only | N/A — visual check | N/A |
| CHRM-02 | /animation-options returns 404 | manual-only | Navigate to route in browser | N/A |
| CHRM-03 | "Clear Read & Rank" in profile menu, confirmation dialog shown | manual-only | Click profile menu in browser | N/A |

### Sampling Rate
- **Per task commit:** `cd EV-readrank && npm run build`
- **Per wave merge:** `cd EV-readrank && npm run build`
- **Phase gate:** TypeScript build clean + manual browser verification of all 5 success criteria

### Wave 0 Gaps
None — no test framework is needed for this phase. Verification is a TypeScript build check plus manual browser testing of the 5 success criteria listed in the phase description.

---

## Sources

### Primary (HIGH confidence)
- `/EV-readrank/src/store/useReadRankStore.ts` — full store shape, v1 persist config, all legacy fields identified
- `/EV-readrank/src/App.tsx` — import list, route definitions, profileMenu wiring
- `/EV-readrank/src/components/PhaseContainer.tsx` — RankingPhase import and switch case
- `/EV-readrank/src/components/ProgressHeader.tsx` — confirmed as self-contained, safe to delete
- `/EV-readrank/src/components/AnimationOptionsPage.tsx` — confirmed as self-contained prototype page
- `/EV-readrank/src/components/BadgeIcons.tsx` — exports DiamondBadge, GoldBadge, BadgeLabel
- `/EV-readrank/src/components/RankingPhase.tsx` — imports BadgeIcons, reads flat legacy fields
- `/EV-readrank/src/components/CollectionPhase.tsx` — confirmed orphaned (not in PhaseContainer or App.tsx)
- `/EV-readrank/src/components/EvaluationPhase.tsx` — reads legacy flat fields, calls setPhase('ranking')
- `/EV-readrank/src/components/ResultsPhase.tsx` — reads badgeAssignments and topicId (both legacy)
- `/EV-readrank/src/components/AgreedQuotesSidebar.tsx` — imports BadgeIcons, reads badgeAssignments
- `/EV-readrank/src/components/IssueHub.tsx` — checks progress.phase === 'ranking'
- `/EV-readrank/src/utils/matchingAlgorithm.ts` — confirmed badge scoring logic present
- `/EV-readrank/src/utils/verdictFragment.ts` — confirmed clean, no badge references
- `/EV-readrank/src/utils/verdictSync.ts` — confirmed clean, no badge references
- `/CompassV2/src/components/Layout.jsx` — confirmed Compass reset pattern: window.confirm + profileItems order

### Secondary (MEDIUM confidence)
- Zustand v5 persist docs — version + migrate behavior consistent with what is already implemented in the codebase

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all versions read from package.json directly
- Architecture: HIGH — all files read directly; no guessing about what imports what
- Pitfalls: HIGH — each pitfall identified from actual code line references

**Research date:** 2026-03-14
**Valid until:** Until Phase 87 begins (store shape changes again for unified evaluation phase)
