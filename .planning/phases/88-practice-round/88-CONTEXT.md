# Phase 88: Practice Round - Context

**Gathered:** 2026-03-15
**Status:** Ready for planning

<domain>
## Phase Boundary

First-time users complete a practice round with fun pizza-topping quotes before encountering real political content. The practice round teaches both swipe agree/disagree and the head-to-head matchup ranking mechanic. Practice verdicts never reach the backend or fragment encoder. Users can skip practice at any time.

</domain>

<decisions>
## Implementation Decisions

### Practice content
- 5 pizza-topping quotes with playful, opinionated tone ("Pineapple belongs on pizza and I will die on this hill")
- Framed as a single issue: "The Great Pizza Debate" with question text "Where do you stand on pizza toppings?"
- Quotes attributed to silly fake characters (e.g., "Chef Mario", "Pizza Pete")
- Mirrors the real issue/question structure exactly so users learn the pattern

### Entry & exit flow
- Auto-redirect: first visit goes straight to practice (no hub). Store flag `practiceCompleted` tracks completion
- Returning users with `practiceCompleted: true` bypass practice and land on the hub
- Persistent "Skip practice" text link visible throughout the practice round (not pushy, always accessible)
- Skip clears all partial practice state atomically and takes user to hub, sets `practiceCompleted: true`
- After completing practice: mini results screen showing pizza topping rankings with silly character reveals
- Results screen has "Start exploring real issues" CTA button that transitions to hub

### Phase model
- Add `'practice'` to the Phase union type: `'hub' | 'practice' | 'evaluation' | 'results'`
- PhaseContainer renders a new PracticeRound component for the `'practice'` phase
- Practice state lives entirely outside `issueProgress` — no contamination of real verdict data
- Store version bump to v5 with clean-reset migration (established pattern from v2/v3/v4)

### Visual treatment
- Same evaluation layout and card styling as real issues — maximum transfer learning
- Persistent "Practice Round" banner/badge at top to signal it's not real content
- Pizza emoji accent on each quote card (small, lightweight fun without breaking the card pattern)
- Practice results screen mirrors real results reveal mechanic with fake character reveals

### Ranking mechanic
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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` — ONBD-01 through ONBD-04 define practice round acceptance criteria

### Prior phase context
- `.planning/phases/86-chrome-cleanup-store-migration/86-CONTEXT.md` — Store migration pattern, profile menu reset, Phase union decisions
- `.planning/phases/87-unified-evaluatephase-inlinerankpanel/87-CONTEXT.md` — Inline ranking mechanic, sidebar evolution, store model decisions

### State decisions
- `.planning/STATE.md` — Accumulated decisions section: practice state isolation, store version history, matchup ranking decisions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `EvaluationPhase.tsx`: Core swipe evaluation component — practice could wrap or reuse this with practice data
- `MatchCard.tsx` + `MatchupPhase.tsx`: Head-to-head matchup UI — practice should trigger the same flow
- `AgreedQuotesSidebar.tsx`: Desktop ranked list sidebar — reuse as-is during practice
- `InlineRankPanel.tsx`: Mobile ranking panel — reuse as-is during practice
- `ResultsPhase.tsx`: Results display — practice results could be a simplified version or wrapper
- `QuoteCard.tsx`: Swipe card component — reuse with pizza emoji accent added

### Established Patterns
- Zustand persist with version + migrate: Store at v4, bump to v5 with clean-reset migration
- Phase union type in `useReadRankStore.ts` line 53: Currently `'hub' | 'evaluation' | 'results'`
- `PhaseContainer.tsx`: Switch statement renders component per phase — add `'practice'` case
- `createEmptyIssueProgress()`: Factory for per-issue state — practice needs its own isolated equivalent
- `matchupAlgorithm.ts`: `getPendingMatchups`, `computeRankings`, `makePairKey` — reuse during practice

### Integration Points
- `PhaseContainer.tsx` line 22-31: Phase switch — add `case 'practice'`
- `useReadRankStore.ts` line 53: Phase type — extend with `'practice'`
- `useReadRankStore.ts` line 118-122: Initial state — add `practiceCompleted: false`
- `useReadRankStore.ts` line 430-432: migrate function — bump to v5
- `useReadRankStore.ts` line 434: partialize — include `practiceCompleted`
- `verdictSync.ts` + `verdictFragment.ts`: Must NOT read practice data — isolation enforced by keeping practice state outside `issueProgress`

</code_context>

<specifics>
## Specific Ideas

- Practice results should mirror the real results reveal — silly character reveals teach users what to expect when they see real politician reveals
- "Skip practice" should feel low-pressure — a text link, not a prominent button competing with the swipe area
- The practice round is about muscle memory: swipe, see matchup, pick winner. Keep it moving fast.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 88-practice-round*
*Context gathered: 2026-03-15*
