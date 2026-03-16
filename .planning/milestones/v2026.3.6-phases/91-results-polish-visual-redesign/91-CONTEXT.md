# Phase 91: Results Polish + Visual Redesign - Context

**Gathered:** 2026-03-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Results page delivers a memorable candidate reveal moment and all Read & Rank components share a cohesive, polished visual design. This includes the dramatic reveal animation, result card simplification, full-app visual cohesion pass, page transitions, end-of-evaluation layout improvement, and matchup layout breathing room.

</domain>

<decisions>
## Implementation Decisions

### Reveal mechanic
- Single "Reveal Who Said It" button triggers staggered reveal across all cards at once — one big moment, not per-card
- Pre-reveal cards show quote text and verdict badge only — no identity section at all (no silhouette, no "???")
- Identity section (photo, name, office) appears for the first time on reveal, expanding into each card
- Centerpiece coral button with subtle pulse animation while waiting — this is THE moment
- High drama reveal: button morphs/disappears on press, 300ms anticipation pause, then cards reveal with staggered 200ms gaps
- Each card's identity reveal uses adapted megaBurst particle effect + slamDown expansion
- CTAs fade in after all reveals complete
- prefers-reduced-motion: disable particle bursts and stagger delays, keep opacity fades

### Result card redesign
- "View on Essentials" is the sole CTA per card — "View Alignment" button removed entirely
- Card content post-reveal: quote text, candidate photo/name/office, source link, verdict badge (AGREED/DISAGREED), rank number for agreed quotes
- Agreed cards: teal left-accent border, full color treatment
- Disagreed cards: gray left-accent border, slightly muted styling
- "Explore More Issues" secondary button (teal outline) fades in below all cards after reveal completes

### CandidateAlignmentPage
- Visual polish only this phase — updated typography/colors to match new results design (per RSLT-04)
- No CTA pointing to it from results cards — accessible via direct URL only
- Future: ReadRank card on Essentials politician profile replaces this page entirely (deferred)

### Visual cohesion pass (full app)
- Scope: ALL pages — Hub, Evaluation, Practice, Matchup, Results, CandidateAlignmentPage
- Color palette stays: cream surfaces (#faf7f2, #fffefb), ev-coral/ev-teal accents, paper texture background retained at 0.025 opacity
- Typography: Manrope everywhere — drop Fraunces entirely from the app
- Mixed component styles is the primary inconsistency to fix: buttons, badges, cards should share consistent border-radius, shadow, and border treatment
- Visual reference: Linear-style clean — minimal, precise spacing, subtle shadows, mono-weight borders, functional elegance
- Claude eyeballs token consistency per component (no formal design token enforcement)

### End-of-evaluation layout
- When all quotes are evaluated, the last QuoteCard fades out and the ranked list animates from sidebar to full-width center layout
- "See Results" button appears below the expanded ranked list
- Smooth transition from split evaluation layout to centered pre-results state

### Matchup layout
- During head-to-head matchups, hide ranked sidebar entirely — both matchup cards get full width/breathing room
- Sidebar returns when matchups complete and evaluation resumes

### Page transitions
- Framer Motion AnimatePresence wrapping route transitions
- Hub to Evaluation: current page fades out (200ms), new page slides up + fades in (300ms)
- Evaluation to Results: cards stay, chrome fades, results header slides down (continuation feel)
- Results to Hub: page slides down + fades out
- prefers-reduced-motion: instant transitions (no slide/fade)

### Claude's Discretion
- Exact stagger timing and easing curves for reveal sequence
- Button morph animation implementation (coral pulse to dissolve)
- Particle burst size/count/color on identity reveal
- Spacing and padding adjustments per component during cohesion pass
- Border-radius and shadow values chosen for Linear-style consistency
- Mobile layout adjustments for end-of-evaluation and matchup improvements

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` — RSLT-01 through RSLT-04 and CHRM-04 define results polish and visual redesign acceptance criteria

### Prior phase context
- `.planning/phases/86-chrome-cleanup-store-migration/86-CONTEXT.md` — Store migration pattern, profile menu reset, badge system removal
- `.planning/phases/87-unified-evaluatephase-inlinerankpanel/87-CONTEXT.md` — Inline ranking mechanic, sidebar/mobile behavior, end-of-evaluation flow
- `.planning/phases/87.1-head-to-head-matchup-ranking/` — Matchup cards, 3D tilt animations, MatchCard component
- `.planning/phases/89-coach-marks/89-CONTEXT.md` — CoachMark component, tour state management

### State decisions
- `.planning/STATE.md` — Accumulated decisions across all phases including animation patterns and store version history

### Key source files
- `EV-readrank/src/components/ResultsPhase.tsx` — Main results page to redesign
- `EV-readrank/src/components/CandidateAlignmentPage.tsx` — Alignment page for visual polish
- `EV-readrank/src/components/MatchCard.tsx` — 3D matchup card with megaBurst/slamDown animations to reuse
- `EV-readrank/src/components/MatchupPhase.tsx` — Head-to-head layout to modify (hide sidebar)
- `EV-readrank/src/components/EvaluationPhase.tsx` — End-of-evaluation layout change
- `EV-readrank/src/index.css` — Design tokens, keyframe animations, component classes

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `megaBurst` keyframe animation: Particle burst effect from matchup phase — adapt for reveal identity burst
- `slamDown` keyframe: Bounce entrance from matchup — adapt for identity section expanding into cards
- `screenShake` keyframe: Subtle oscillation — available for reveal button press effect
- `.ev-button-primary` / `.ev-button-secondary` CSS classes: Existing button styles with hover/tap states
- Framer Motion `AnimatePresence` already used in evaluation flow — extend to page-level transitions
- `useDeviceType` hook: Differentiates mouse vs touch for layout branching

### Established Patterns
- Staggered card animations with `delay: index * 0.08` and custom cubic-bezier `[0.22, 1, 0.36, 1]`
- `@media (prefers-reduced-motion: reduce)` block already in index.css — extend for new animations
- Split layout CSS classes: `evaluation-split-layout`, `evaluation-main-panel`, `evaluation-sidebar-panel`
- Paper texture via pseudo-element with SVG fractal noise at 0.025 opacity

### Integration Points
- `PhaseContainer.tsx` renders phase switch — page transitions wrap here
- `AgreedQuotesSidebar` (exports `RankedListSidebar`) — visibility toggle needed for matchup phase
- `EvaluationPhase.tsx` `handleComplete` — triggers transition to full-width ranked list then results
- `ResultsPhase.tsx` — complete redesign with masked state, reveal button, staggered animation

</code_context>

<specifics>
## Specific Ideas

- Reveal should feel like the payoff for evaluating all those quotes — the "big moment" the whole flow builds toward
- Linear-style visual reference: minimal, precise spacing, subtle shadows, mono-weight borders
- End-of-evaluation: ranked list should "take over" when there are no more cards to swipe — the last card lingering is anticlimactic
- Matchup cards feel cramped with sidebar competing for space — full width during matchups lets users focus on comparing quotes
- Future: ReadRank summary card on Essentials politician profiles (replacing CandidateAlignmentPage as the primary cross-app surface)

</specifics>

<deferred>
## Deferred Ideas

- ReadRank card on Essentials politician profiles — replaces CandidateAlignmentPage as cross-app integration surface (new capability, own phase)
- Mobile-specific matchup layout investigation — user unsure of current mobile matchup experience, may need separate attention

</deferred>

---

*Phase: 91-results-polish-visual-redesign*
*Context gathered: 2026-03-15*
