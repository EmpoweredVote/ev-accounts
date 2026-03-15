# Phase 87: Unified EvaluatePhase + InlineRankPanel - Context

**Gathered:** 2026-03-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Users evaluate quotes and assign rank inline without ever leaving the evaluation context. No separate ranking screen — ranking happens as quotes are agreed with during evaluation. Completing an issue transitions directly to results after a quick confirmation.

</domain>

<decisions>
## Implementation Decisions

### Inline rank trigger
- Rank prompt first appears after the 2nd agree — first agree sits unranked, second triggers the first insert prompt
- Every subsequent agree triggers an inline insert card showing the ranked list with the new quote highlighted for placement
- If user ignores the rank prompt and swipes next quote: gentle nudge ("drag to rank") on first skip, then auto-append to bottom on subsequent skips
- Inline insert card appears below the swipe area (not a modal, not a bottom sheet)

### Mobile rank panel
- Compact rank panel slides in between quotes (below swipe area, pushing content down) when triggered by agree
- Panel stays open after placement until user taps a "Continue" button or taps away — no auto-collapse
- Tappable counter pill always visible at bottom ("3 ranked") — user can tap to expand the full rank list for review/reorder anytime, even between disagrees
- Drag-into-position for placement — @dnd-kit TouchSensor, consistent with desktop

### Desktop sidebar evolution
- Rename AgreedQuotesSidebar to ranked list with header "Your Ranking" (count shown: "Your Ranking (3)")
- Add numbered rank indicators (#1, #2, #3...) to each quote card
- When a new agreed quote arrives: highlight at bottom with pulse animation, sidebar auto-scrolls to show it
- Rank numbers update live as user reorders via drag
- Sidebar is the sole rank surface on desktop — no inline prompt in the main panel
- Only ranked/agreed quotes shown in sidebar — no disagreed quotes section

### Store model
- Merge agreedQuotes and rankedQuotes into a single ranked list — one source of truth
- Every agreed quote gets a rank on placement (or auto-appended to bottom if skipped)
- First agreed quote sits unranked until 2nd agree triggers ordering of both
- matchingAlgorithm.ts already reads rankedQuotes — single list feeds directly into scoring

### End-of-evaluation flow
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

</decisions>

<specifics>
## Specific Ideas

- Mobile rank panel should feel like inserting a card into a hand of cards — tactile drag between existing ranked quotes
- Desktop sidebar should feel alive — numbers updating, smooth scroll, pulse on new arrivals
- The gentle nudge on first skip teaches without blocking — respect user's pace

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AgreedQuotesSidebar`: Already has @dnd-kit DndContext with PointerSensor, TouchSensor, KeyboardSensor and SortableContext — rename and evolve, don't rebuild
- `SortableCompactQuoteCard`: Existing sortable card component — add rank number display
- `reorderAgreedQuotes` store action: Already reorders via arrayMove — can become the primary rank reorder method
- `rankQuote` and `setRankedQuotes` store actions: Exist but may be replaced by unified single-list approach
- `useDeviceType` hook: Already differentiates mouse vs touch for layout branching

### Established Patterns
- @dnd-kit with closestCenter collision detection and verticalListSortingStrategy — reuse for rank insertion
- Framer Motion AnimatePresence for entry/exit animations — use for inline rank panel
- Split layout on desktop (evaluation-split-layout, evaluation-main-panel, evaluation-sidebar-panel CSS classes) — already wired

### Integration Points
- `EvaluationPhase.tsx` line 56-60: `agreeWithQuote` action — needs to trigger rank prompt after 2nd agree
- `useReadRankStore.ts` IssueProgress: `agreedQuotes` and `rankedQuotes` arrays — merge into single ranked list
- `matchingAlgorithm.ts` `calculateAlignment`: Reads `rankedQuotes` — single list feeds directly in
- `verdictFragment.ts`: Encodes agree/disagree + rank order — needs to read from unified list
- `PhaseContainer.tsx`: May need new phase state or inline rank rendering hook
- `EvaluationPhase.tsx` line 88-90: `handleComplete` → `setPhase('results')` — insert quick confirmation step before this

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 87-unified-evaluatephase-inlinerankpanel*
*Context gathered: 2026-03-14*
