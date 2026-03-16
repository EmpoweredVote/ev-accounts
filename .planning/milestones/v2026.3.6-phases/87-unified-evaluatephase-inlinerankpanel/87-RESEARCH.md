# Phase 87: Unified EvaluatePhase + InlineRankPanel - Research

**Researched:** 2026-03-14
**Domain:** React drag-and-drop inline ranking UI, Zustand state consolidation, Framer Motion animation
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Inline rank trigger:**
- Rank prompt first appears after the 2nd agree — first agree sits unranked, second triggers the first insert prompt
- Every subsequent agree triggers an inline insert card showing the ranked list with the new quote highlighted for placement
- If user ignores the rank prompt and swipes next quote: gentle nudge ("drag to rank") on first skip, then auto-append to bottom on subsequent skips
- Inline insert card appears below the swipe area (not a modal, not a bottom sheet)

**Mobile rank panel:**
- Compact rank panel slides in between quotes (below swipe area, pushing content down) when triggered by agree
- Panel stays open after placement until user taps a "Continue" button or taps away — no auto-collapse
- Tappable counter pill always visible at bottom ("3 ranked") — user can tap to expand the full rank list for review/reorder anytime, even between disagrees
- Drag-into-position for placement — @dnd-kit TouchSensor, consistent with desktop

**Desktop sidebar evolution:**
- Rename AgreedQuotesSidebar to ranked list with header "Your Ranking" (count shown: "Your Ranking (3)")
- Add numbered rank indicators (#1, #2, #3...) to each quote card
- When a new agreed quote arrives: highlight at bottom with pulse animation, sidebar auto-scrolls to show it
- Rank numbers update live as user reorders via drag
- Sidebar is the sole rank surface on desktop — no inline prompt in the main panel
- Only ranked/agreed quotes shown in sidebar — no disagreed quotes section

**Store model:**
- Merge agreedQuotes and rankedQuotes into a single ranked list — one source of truth
- Every agreed quote gets a rank on placement (or auto-appended to bottom if skipped)
- First agreed quote sits unranked until 2nd agree triggers ordering of both
- matchingAlgorithm.ts already reads rankedQuotes — single list feeds directly into scoring

**End-of-evaluation flow:**
- After all quotes evaluated: brief confirmation view showing final rank order with "Looks good" / "Reorder" choice
- Quick confirmation — not a full ranking screen, just a review moment before results
- 0 agrees = skip ranking entirely, show results with "no alignment" messaging
- 1 agree = that quote is rank 1 by default, skip ranking, go to results

### Claude's Discretion
- Exact animation timing for inline insert card appearance/dismissal
- Sidebar pulse animation style and duration
- Counter pill positioning and styling on mobile
- "Drag to rank" nudge visual treatment
- Quick confirmation layout and auto-advance timing

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| FLOW-01 | User evaluates quotes and ranks inline in a single unified phase (no separate ranking screen) | Store merge (agreedQuotes + rankedQuotes → single list) + EvaluationPhase stays in 'evaluation' phase until completion confirmation |
| FLOW-02 | After agreeing with 2+ quotes, user is prompted to insert new agreed quote into ranked list via drag | InlineRankPanel component gated on `agreedCount >= 2`, @dnd-kit with new quote highlighted for placement |
| FLOW-03 | Desktop shows live ranked list in sidebar during evaluation | AgreedQuotesSidebar → RankedListSidebar evolution: rank numbers, pulse animation, auto-scroll to new arrival |
| FLOW-04 | Mobile shows inline insert-into-list ranking between quotes after 2nd agree | InlineRankPanel below swipe area with Framer Motion slide-in, counter pill always visible, @dnd-kit TouchSensor |
| FLOW-05 | Rank order determines alignment weight (no diamond/gold badge system) | matchingAlgorithm already uses rank-position scoring; store unified list feeds directly into calculateAlignment |
</phase_requirements>

---

## Summary

Phase 87 transforms the EvaluationPhase from a pure swipe-and-agree experience into a unified evaluate-and-rank flow. The key architectural work is threefold: (1) merging `agreedQuotes` and `rankedQuotes` in the Zustand store into a single `rankedQuotes` list, (2) building a new `InlineRankPanel` component for mobile that appears below the swipe area after the 2nd agree, and (3) evolving the existing `AgreedQuotesSidebar` into a live `RankedListSidebar` with numbered ranks and arrival animation.

The codebase is well-prepared for this phase. Phase 86 already removed the separate 'ranking' phase, cleaned the store, and established rank-position scoring. All @dnd-kit infrastructure is in place (`DndContext`, `PointerSensor`, `TouchSensor`, `SortableContext`, `verticalListSortingStrategy`, `arrayMove`). The `SortableCompactQuoteCard` component needs only a rank-number prop added. The split layout CSS classes are already wired. No new npm dependencies are needed.

The primary complexity is state management: the transition from the dual-array model (`agreedQuotes: Quote[]` + `rankedQuotes: RankedQuote[]`) to a single `rankedQuotes: RankedQuote[]` list. The first agreed quote is appended as rank 1 but the ranking prompt is not shown until the 2nd agree. This "pending" state — where the list has one item but was never explicitly ordered — needs a clean representation. A timestamp on `RankedQuote` already exists to support this. The `verdictFragment.ts` currently reads both `agreedQuotes` and `rankedQuotes`; after the merge, it reads only `rankedQuotes`.

**Primary recommendation:** Merge the store first (IssueProgress shape change + all consumers updated in one wave), then build the UI components on top of the clean unified list.

---

## Standard Stack

### Core (already installed — no new dependencies)
| Library | Version | Purpose | Notes |
|---------|---------|---------|-------|
| @dnd-kit/core | ^6.3.1 | DnD context, sensors, collision detection | Already used in AgreedQuotesSidebar |
| @dnd-kit/sortable | ^10.0.0 | SortableContext, useSortable, arrayMove | Already used; verticalListSortingStrategy in use |
| @dnd-kit/utilities | ^3.2.2 | CSS.Transform.toString | Already used |
| framer-motion | ^12.23.26 | AnimatePresence, motion, useMotionValue | Already used throughout |
| zustand | ^5.0.9 | Store with persist middleware | v2 store clean from Phase 86 |
| react | ^19.2.0 | UI layer | No changes needed |

### No New Dependencies
This phase requires zero new npm packages. All tooling is already in place.

---

## Architecture Patterns

### Recommended File Changes
```
EV-readrank/src/
├── store/
│   └── useReadRankStore.ts          # MODIFY: merge agreedQuotes into rankedQuotes
├── components/
│   ├── EvaluationPhase.tsx          # MODIFY: add inline panel logic, confirmation view
│   ├── AgreedQuotesSidebar.tsx      # MODIFY: rename → RankedListSidebar, add rank #s, pulse, auto-scroll
│   ├── InlineRankPanel.tsx          # CREATE: mobile inline insert panel
│   └── QuickConfirmation.tsx        # CREATE: post-evaluation "Looks good / Reorder" view
└── index.css                        # MODIFY: add inline-rank-panel, counter-pill, confirmation CSS
```

### Pattern 1: Unified Store — Single Ranked List

**What:** Replace the dual `agreedQuotes: Quote[]` + `rankedQuotes: RankedQuote[]` in `IssueProgress` with a single `rankedQuotes: RankedQuote[]`.

**When to use:** The first agreed quote is appended as rank 1 immediately (auto-rank). The inline prompt only displays when `rankedQuotes.length >= 2` — the second agree triggers reordering of both.

**Current IssueProgress shape:**
```typescript
// CURRENT (Phase 86 output)
interface IssueProgress {
  agreedQuotes: Quote[];       // unranked agreed
  rankedQuotes: RankedQuote[]; // explicitly ranked subset
  // ... other fields
}
```

**Target IssueProgress shape:**
```typescript
// PHASE 87 TARGET
interface IssueProgress {
  rankedQuotes: RankedQuote[];  // single source of truth — all agreed quotes with position
  disagreedQuotes: Quote[];
  pendingRankQuoteId: string | null; // the newly agreed quote awaiting user placement
  rankSkipCount: number;            // tracks how many times user skipped rank prompt
  // agreedQuotes removed
  // ... other fields unchanged
}
```

**Key invariant:** `rankedQuotes` is always ordered (rank 1 at index 0). Rank numbers are derived from array index: `rank = index + 1`. No explicit `.rank` field needed on the object at rest — rank is positional.

**New/changed store actions:**
```typescript
// agreeWithQuote: append to rankedQuotes, set pendingRankQuoteId, call nextQuote
agreeWithQuote: (quote: Quote) => void;

// insertAtRank: move pendingRankQuoteId to specified position in rankedQuotes
insertAtRank: (quoteId: string, targetIndex: number) => void;

// skipRankPrompt: increments rankSkipCount; if > 1, auto-appends to bottom
skipRankPrompt: () => void;

// reorderRankedQuotes: replaces reorderAgreedQuotes — same arrayMove logic
reorderRankedQuotes: (newOrder: RankedQuote[]) => void;

// dismissPending: clears pendingRankQuoteId (called after placement or skip)
dismissPending: () => void;
```

**Removed store actions:** `rankQuote`, `setRankedQuotes`, `reorderAgreedQuotes`

### Pattern 2: InlineRankPanel — Mobile Insert Card

**What:** A Framer Motion animated panel that slides in below the swipe area when `pendingRankQuoteId` is set AND `rankedQuotes.length >= 2` AND device is touch.

**When to use:** Mobile only. Desktop uses the sidebar exclusively.

**Render location:** Inside `EvaluationPhase.tsx`, below the swipe card container, within the mobile path (non-`isMouseDevice` branch).

**Structure:**
```tsx
// InlineRankPanel.tsx — simplified structure
const InlineRankPanel: React.FC<{ onDismiss: () => void }> = ({ onDismiss }) => {
  // Uses same DndContext + SortableContext + TouchSensor pattern as AgreedQuotesSidebar
  // pendingRankQuoteId item highlighted (pulsing border, "Place me" label)
  // draggable items can be repositioned between existing ranked items
  // "Continue" button calls onDismiss (dismissPending)
  // tapping outside (onBlur equivalent) also dismisses after placement
};
```

**AnimatePresence wrapper in EvaluationPhase:**
```tsx
<AnimatePresence>
  {showInlinePanel && !isMouseDevice && (
    <motion.div
      key="inline-rank-panel"
      initial={{ opacity: 0, height: 0 }}
      animate={{ opacity: 1, height: 'auto' }}
      exit={{ opacity: 0, height: 0 }}
      transition={{ duration: 0.28, ease: [0.22, 1, 0.36, 1] }}
      style={{ overflow: 'hidden' }}
    >
      <InlineRankPanel onDismiss={handleDismissPanelOrSkip} />
    </motion.div>
  )}
</AnimatePresence>
```

**Skip logic in EvaluationPhase:**
```typescript
const handleDismissPanelOrSkip = () => {
  // If user taps "Continue" without placing = skip
  // If rankSkipCount === 0: show nudge text, increment, allow next swipe
  // If rankSkipCount >= 1: auto-append to bottom, dismiss
  skipRankPrompt();
};
```

### Pattern 3: RankedListSidebar (Desktop Evolution)

**What:** Rename `AgreedQuotesSidebar` → `RankedListSidebar`. Change header to "Your Ranking (N)". Add rank numbers to `SortableCompactQuoteCard`. Add pulse animation + auto-scroll on new arrival.

**Auto-scroll pattern using a ref:**
```typescript
// In RankedListSidebar
const listRef = useRef<HTMLDivElement>(null);
const prevCountRef = useRef(rankedQuotes.length);

useEffect(() => {
  if (rankedQuotes.length > prevCountRef.current && listRef.current) {
    // New quote arrived — scroll to bottom
    listRef.current.scrollTo({ top: listRef.current.scrollHeight, behavior: 'smooth' });
  }
  prevCountRef.current = rankedQuotes.length;
}, [rankedQuotes.length]);
```

**Pulse animation on the new arrival:**
```tsx
// SortableCompactQuoteCard gets isNew prop
// Framer Motion keyframes for pulse:
animate={isNew ? { boxShadow: ['0 0 0 0 rgba(0,101,124,0)', '0 0 0 6px rgba(0,101,124,0.3)', '0 0 0 0 rgba(0,101,124,0)'] } : {}}
transition={{ duration: 0.8, ease: 'easeOut' }}
```

**Rank number display:**
```tsx
// In SortableCompactQuoteCard, above the quote text
<span style={{
  fontFamily: "'Manrope', sans-serif",
  fontSize: '0.625rem',
  fontWeight: 700,
  color: '#00657c',
  letterSpacing: '0.06em',
}}>
  #{index + 1}
</span>
```

### Pattern 4: Counter Pill — Mobile Persistent Indicator

**What:** Always-visible pill at the bottom of the evaluation content showing ranked count. Tapping expands the full ranked list for review/reorder.

**Render location:** Below evaluation content in the mobile (non-`isMouseDevice`) branch, always shown when `rankedQuotes.length > 0`.

```tsx
// CounterPill — inline in EvaluationPhase mobile branch
{!isMouseDevice && rankedQuotes.length > 0 && (
  <button
    onClick={() => setShowFullRankList(prev => !prev)}
    className="rank-counter-pill"
  >
    {rankedQuotes.length} ranked
    <svg /* chevron icon, rotates when open */ />
  </button>
)}
```

**CSS class to add to index.css:**
```css
.rank-counter-pill {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  padding: 0.375rem 0.875rem;
  background-color: #ecfeff;
  border: 1px solid #a5f3fc;
  border-radius: 9999px;
  font-family: 'Manrope', sans-serif;
  font-size: 0.75rem;
  font-weight: 600;
  color: #0e7490;
  cursor: pointer;
  transition: background-color 0.15s ease;
}
.rank-counter-pill:hover { background-color: #cffafe; }
```

### Pattern 5: Quick Confirmation View

**What:** After all quotes evaluated (isComplete), instead of showing "See Your Results" immediately, show a brief confirmation: final rank order + "Looks good" / "Reorder" buttons. "Looks good" → `setPhase('results')`. "Reorder" → keep evaluation phase, show full rank panel for reordering.

**Gating conditions (no confirmation shown):**
- 0 agrees: `setPhase('results')` immediately with "no alignment" data
- 1 agree: rank is trivially determined, skip to results

**Render location:** In `EvaluationPhase.tsx`, replaces the current "See Your Results" button when `isComplete && rankedQuotes.length >= 2`.

```tsx
// QuickConfirmation.tsx
const QuickConfirmation: React.FC<{ onConfirm: () => void; onReorder: () => void }> = ...
// Shows ordered list of rankedQuotes with their #1, #2 numbers
// "Looks good" → onConfirm → setPhase('results')
// "Reorder" → onReorder → sets local reorderMode state in EvaluationPhase
```

### Anti-Patterns to Avoid

- **Separate DndContext instances fighting each other:** The InlineRankPanel and the counter-pill full list expansion should share one DndContext per render context, not nest them. Nested `DndContext` components are unsupported in @dnd-kit.
- **Storing rank as a field on RankedQuote:** Rank is always derivable from array index. Storing `rank: number` on the object and keeping it in sync with array position creates bugs. Use index-derived rank for display; the field on `RankedQuote` can remain for `matchingAlgorithm.ts` compatibility but should be set at read time via `.map((q, i) => ({ ...q, rank: i + 1 }))`.
- **Auto-collapsing the mobile panel:** The CONTEXT.md decision is explicit: panel stays open until "Continue" tap or tap-away. No auto-collapse after placement.
- **Showing rank prompt on desktop:** Desktop sidebar is the sole rank surface. No inline insert card in the main evaluation panel on mouse devices.
- **Using modal or bottom sheet for inline panel:** CONTEXT.md explicitly says not a modal, not a bottom sheet. It pushes content down inline.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Drag reorder with touch support | Custom touch drag | @dnd-kit TouchSensor (already in AgreedQuotesSidebar) | Touch event normalization, drag overlay, collision detection, keyboard accessibility all handled |
| Smooth list reorder animation | Manual CSS transitions | @dnd-kit SortableContext with `animateLayoutChanges` prop (default) | Built-in layout animation during drag |
| Entry/exit animation for panel | CSS keyframes | Framer Motion AnimatePresence + `height: 0 → 'auto'` | Already used, handles unmount animation correctly |
| Array reorder | Splice logic | `arrayMove` from @dnd-kit/sortable | Already in use; handles edge cases |
| Scroll to bottom on new item | scrollTop math | `element.scrollTo({ behavior: 'smooth' })` | Native smooth scroll sufficient |

---

## Common Pitfalls

### Pitfall 1: agreedQuotes References in consumers
**What goes wrong:** After removing `agreedQuotes` from the store, TypeScript will surface every consumer. Known consumers: `EvaluationPhase.tsx` (reads `agreedQuotes` for count display and mobile summary), `AgreedQuotesSidebar.tsx` (reads `agreedQuotes` directly), `verdictFragment.ts` (iterates `agreedQuotes`), `ResultsPhase.tsx` (reads `agreedQuotes`).
**Why it happens:** Four separate files reference the old shape.
**How to avoid:** Change the IssueProgress interface first. Let TypeScript errors serve as the exhaustive work queue. Fix all errors before writing any UI component.
**Warning signs:** Build succeeds but runtime shows empty ranked list on results page — means `verdictFragment.ts` was not updated.

### Pitfall 2: Nested DndContext
**What goes wrong:** If InlineRankPanel and the counter-pill's expanded full-list view are rendered simultaneously (e.g., during transition), and both render their own DndContext, @dnd-kit throws runtime errors and drag stops working.
**Why it happens:** @dnd-kit does not support nested DndContext.
**How to avoid:** Use `showInlinePanel` and `showFullRankList` as mutually exclusive state — only one can be true at a time. Or hoist a single DndContext to EvaluationPhase level and pass event handlers down.
**Warning signs:** Drag starts but items snap back; console error mentioning "DndContext".

### Pitfall 3: RankedQuote.rank field diverging from array position
**What goes wrong:** matchingAlgorithm.ts reads `rankedQuote.rank` but the unified list stores items in order without updating the `.rank` field. Algorithm scores all items equally (rank = 0 or stale value).
**Why it happens:** arrayMove reorders the array but doesn't update `.rank` fields on items.
**How to avoid:** In `reorderRankedQuotes`, always re-map ranks after reorder:
```typescript
reorderRankedQuotes: (newOrder) => {
  const renumbered = newOrder.map((q, i) => ({ ...q, rank: i + 1 }));
  // ... set store
}
```
Also re-map in `agreeWithQuote` and `insertAtRank`.
**Warning signs:** Results show 0% alignment for candidates even when user agreed with their quotes.

### Pitfall 4: pendingRankQuoteId already in rankedQuotes before placement
**What goes wrong:** agreeWithQuote appends to rankedQuotes immediately (to preserve rank ordering invariant), but the InlineRankPanel treats it as "pending" — it's already in the list at the bottom. The panel highlights it and user places it, causing a duplicate in the array.
**Why it happens:** Two conceptual states ("just agreed, awaiting placement" vs "placed") collapsed into one array.
**How to avoid:** Two valid approaches:
  - **Approach A (simpler):** Don't append to rankedQuotes until placement or skip. Keep a separate `pendingQuote: Quote | null` field. Only merge into rankedQuotes on placement/skip. Panel shows existing rankedQuotes + pending item together.
  - **Approach B (CONTEXT.md intent):** Append immediately to bottom. Panel shows the list with the bottom item highlighted. User drags it to position. This means "placement" is just a reorder of the last item. On skip, item stays at bottom with no further action.

  Approach B aligns better with CONTEXT.md's description ("inline insert card showing the ranked list with the new quote highlighted for placement"). `pendingRankQuoteId` is a UI hint, not a store-level separation. Use Approach B.
**Warning signs:** Duplicate quote IDs in rankedQuotes array.

### Pitfall 5: Animation height transition with dynamic content
**What goes wrong:** Framer Motion `height: 0 → 'auto'` works for entry, but nested DnD items resizing during drag cause layout jumps.
**Why it happens:** `height: 'auto'` reflows on every render; drag transforms cause intermediate reflows.
**How to avoid:** Wrap the InlineRankPanel in a fixed-min-height container, or use `overflow: hidden` only during the enter/exit animation. During normal open state, let height be natural.

### Pitfall 6: Stale progress reference in EvaluationPhase
**What goes wrong:** `EvaluationPhase` reads `progress` once at render, but store updates mid-render (e.g., during agreeWithQuote) cause stale closure reads.
**Why it happens:** `getCurrentIssueProgress()` returns a snapshot; Zustand subscriptions handle reactivity, but the destructured fields need to re-trigger renders.
**How to avoid:** Destructure fields directly from `getCurrentIssueProgress()` at the top of the component (already done in Phase 86). Ensure new fields like `pendingRankQuoteId` and `rankSkipCount` are destructured at that same point.

---

## Code Examples

Verified from existing codebase (Phase 86 output):

### Current agreeWithQuote (to be modified)
```typescript
// src/store/useReadRankStore.ts (current Phase 86 state)
agreeWithQuote: (quote) => {
  const state = get();
  const issueId = state.currentIssueId;
  if (!issueId || !state.issueProgress[issueId]) return;
  const progress = state.issueProgress[issueId];
  const updatedAgreedQuotes = [...progress.agreedQuotes, quote];
  set({
    issueProgress: {
      ...state.issueProgress,
      [issueId]: { ...progress, agreedQuotes: updatedAgreedQuotes },
    },
  });
  get().nextQuote();
},
```

**Phase 87 target behavior:** Append to `rankedQuotes` (with rank = length + 1), set `pendingRankQuoteId` to quote.id, call `nextQuote()`.

### Existing DnD pattern in AgreedQuotesSidebar (reuse as-is)
```typescript
// Pattern established in AgreedQuotesSidebar.tsx — no changes to this wiring needed
const sensors = useSensors(
  useSensor(PointerSensor, { activationConstraint: { distance: 5 } }),
  useSensor(TouchSensor, { activationConstraint: { delay: 150, tolerance: 5 } }),
  useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates })
);

const handleDragEnd = (event: DragEndEvent) => {
  const { active, over } = event;
  if (over && active.id !== over.id) {
    const oldIndex = agreedQuotes.findIndex((q) => q.id === active.id);
    const newIndex = agreedQuotes.findIndex((q) => q.id === over.id);
    reorderAgreedQuotes(arrayMove(agreedQuotes, oldIndex, newIndex));
  }
};
```

### Framer Motion AnimatePresence pattern (already used in codebase)
```tsx
// From AgreedQuotesSidebar.tsx — empty state uses AnimatePresence
<AnimatePresence>
  <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
    ...
  </motion.div>
</AnimatePresence>
```

**InlineRankPanel extension:** Add `height` to the initial/animate/exit for the panel slide-in.

### EvaluationPhase handleComplete (to be modified)
```typescript
// Current Phase 86 state — lines 88-90
const handleComplete = () => {
  setPhase('results');
};
```

**Phase 87 target:** Check `rankedQuotes.length`. If 0 → setPhase('results'). If 1 → setPhase('results'). If >= 2 → show QuickConfirmation view instead.

### verdictFragment.ts reading pattern (to be updated)
```typescript
// Current: reads both agreedQuotes AND rankedQuotes (rankedQuotes is a subset)
for (const progress of Object.values(issueProgress)) {
  for (const quote of progress.agreedQuotes) { v[quote.id] = 'agreed'; }
  for (const quote of progress.rankedQuotes) { v[quote.id] = 'agreed'; } // idempotent
  for (const quote of progress.disagreedQuotes) { v[quote.id] = 'disagreed'; }
}
```

**Phase 87 target:** Remove the `agreedQuotes` loop entirely. `rankedQuotes` is now the single list and covers all agreed quotes.

---

## State of the Art

| Old Approach | Current Approach | Changed | Impact |
|--------------|------------------|---------|--------|
| Separate ranking phase ('ranking' in Phase union) | No ranking phase — inline only | Phase 86 | handleComplete no longer routes to a ranking screen |
| agreedQuotes + rankedQuotes dual arrays | Single rankedQuotes list | Phase 87 (this phase) | matchingAlgorithm reads one list; verdictFragment simplified |
| AgreedQuotesSidebar: unordered agree list | RankedListSidebar: ordered with #1, #2... numbers | Phase 87 | Visual feedback on rank during evaluation |
| No mobile rank UI during evaluation | InlineRankPanel slides in between quotes | Phase 87 | FLOW-04 satisfied |
| badge-weighted scoring | Rank-position scoring only | Phase 86 | FLOW-05 satisfied |

**Deprecated/outdated after this phase:**
- `agreedQuotes: Quote[]` field on IssueProgress — removed
- `rankQuote` store action — removed (replaced by insertAtRank)
- `setRankedQuotes` store action — removed (replaced by reorderRankedQuotes)
- `reorderAgreedQuotes` store action — renamed/replaced by reorderRankedQuotes
- `AgreedQuotesSidebar.tsx` filename — file renamed or replaced by `RankedListSidebar.tsx`

---

## Open Questions

1. **RankedQuote.rank field: keep or derive?**
   - What we know: `matchingAlgorithm.ts` uses `rankedQuote.rank` directly in `calculateAlignment`. It also uses array index (`index` parameter in `rankedQuotes.forEach`). Currently both are present.
   - What's unclear: If we derive rank from index at read-time only (not stored), we need to update `calculateAlignment` to use index instead of `.rank`.
   - Recommendation: Keep `.rank` as a stored field but always renumber after every mutation (agreeWithQuote, insertAtRank, reorderRankedQuotes). This costs one `.map()` per mutation but keeps `matchingAlgorithm.ts` unchanged.

2. **InlineRankPanel DndContext scope: local or hoisted?**
   - What we know: DndContext cannot be nested. InlineRankPanel and the counter-pill full-list expand both need drag. They're mutually exclusive by state.
   - What's unclear: Should each component own its DndContext (safe since they're mutually exclusive), or should EvaluationPhase hoist a single DndContext?
   - Recommendation: Each component owns its DndContext since they never render simultaneously. Simpler component boundaries.

3. **Counter pill: fixed position or in-flow?**
   - What we know: CONTEXT.md says "always visible at bottom" — could mean sticky/fixed or simply the last element in the flow column.
   - What's unclear: "Always visible" on mobile could require sticky positioning if content overflows.
   - Recommendation: Start with in-flow as the last element inside the evaluation column. If scrolling issues arise, switch to `position: sticky; bottom: 1rem`. The CONTEXT.md description of "sliding in between quotes" implies in-flow, not fixed.

---

## Validation Architecture

> nyquist_validation key is absent from .planning/config.json — treat as enabled.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None detected — EV-readrank has no test files or test config |
| Config file | None (Wave 0 gap) |
| Quick run command | `cd EV-readrank && npx tsc --project tsconfig.app.json --noEmit` (TypeScript check as proxy) |
| Full suite command | `cd EV-readrank && npm run build` (build smoke test) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FLOW-01 | Evaluation phase never transitions to a separate ranking screen | manual-only | N/A | N/A |
| FLOW-02 | InlineRankPanel appears only after 2nd agree | manual-only | N/A | N/A |
| FLOW-03 | Desktop sidebar shows ranked list with numbers during evaluation | manual-only | N/A | N/A |
| FLOW-04 | Mobile inline panel slides in between quotes after 2nd agree | manual-only | N/A | N/A |
| FLOW-05 | matchingAlgorithm uses rankedQuotes (single list) for scoring | TypeScript build | `cd EV-readrank && npx tsc --project tsconfig.app.json --noEmit` | ❌ Wave 0 |

**Note on manual-only:** All UI interaction tests (swipe, drag, panel appearance) require a browser. The TypeScript build is the automated gate that will catch type errors in the store merge.

### Sampling Rate
- **Per task commit:** `cd EV-readrank && npx tsc --project tsconfig.app.json --noEmit`
- **Per wave merge:** `cd EV-readrank && npm run build`
- **Phase gate:** Zero TypeScript errors + full build green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] No test framework installed — acceptable for this phase (manual testing is the validation path)
- [ ] TypeScript build serves as the automated proxy: `npx tsc --project tsconfig.app.json --noEmit`

*(Existing infrastructure: TypeScript + Vite build covers structural correctness. No unit test framework exists and none is required for this phase.)*

---

## Sources

### Primary (HIGH confidence)
- Codebase direct read: `EV-readrank/src/store/useReadRankStore.ts` — verified Phase 86 state, dual-array store shape, existing actions
- Codebase direct read: `EV-readrank/src/components/AgreedQuotesSidebar.tsx` — verified @dnd-kit wiring, sensor config, SortableContext pattern
- Codebase direct read: `EV-readrank/src/components/EvaluationPhase.tsx` — verified split layout, handleComplete, isMouseDevice branching
- Codebase direct read: `EV-readrank/src/utils/matchingAlgorithm.ts` — verified rank-position scoring uses `rankedQuote.rank` and array index
- Codebase direct read: `EV-readrank/src/utils/verdictFragment.ts` — verified dual-array reads (agreedQuotes + rankedQuotes)
- Codebase direct read: `EV-readrank/src/index.css` — verified CSS classes for split layout, sidebar, and animation utilities
- Codebase direct read: `EV-readrank/package.json` — verified @dnd-kit/core 6.3.1, @dnd-kit/sortable 10.0.0, framer-motion 12.23.26, zustand 5.0.9
- Phase context: `.planning/phases/87-unified-evaluatephase-inlinerankpanel/87-CONTEXT.md` — locked decisions
- Phase 86 summary: `.planning/phases/86-chrome-cleanup-store-migration/86-01-SUMMARY.md` — confirmed Phase 86 completion state

### Secondary (MEDIUM confidence)
- @dnd-kit docs (general knowledge): Nested DndContext not supported — verified by project usage pattern showing single DndContext per component
- Framer Motion AnimatePresence pattern — verified by existing usage in AgreedQuotesSidebar.tsx

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries verified from package.json; no new dependencies needed
- Architecture: HIGH — existing code read directly; store shape, component structure, and CSS classes all confirmed
- Pitfalls: HIGH — dual-array merge and DnD context scoping pitfalls derived directly from code analysis; rank field divergence from direct algorithm read
- Animation patterns: MEDIUM — Framer Motion patterns verified from existing usage; exact timing values are Claude's Discretion

**Research date:** 2026-03-14
**Valid until:** 2026-04-14 (stable stack, no external API dependencies)
