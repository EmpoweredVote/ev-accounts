# Phase 78: Visual Refresh - Context

**Gathered:** 2026-03-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Apply EV brand design language to Read & Rank's three surfaces: the IssueHub (landing/hub page), QuoteCard swipe UI, and ResultsPhase layout. Goal is visual parity with CompassV2 and Essentials. Zero behavior or animation changes — purely visual polish using EV design tokens already configured in the codebase.

</domain>

<decisions>
## Implementation Decisions

### Overall tone
- Match CompassV2 exactly: serious, civic, professional
- Visual-only changes — all existing Framer Motion animations, swipe gestures, and card mechanics stay identical
- No specific reference page to match; use EV tokens and CompassV2 visual language as the guide

### Hub page (IssueHub)
- Minimal header style — title + subtitle in Manrope bold, no hero block or background accent strip
- ev-muted-blue (#00657c) as the primary accent color (replaces current ev-light-blue usage)
- Issue card styling updated to match CompassV2 card patterns
- Completion state treatment and subtitle copy: Claude's discretion

### QuoteCard
- White card with ev-muted-blue top border accent (3-4px) at rest
- Card stack enhanced with subtle shadow-offset behind the top card to reinforce the "stack of quotes" metaphor
- Candidate identity stays hidden on card face — revealed after verdict (existing behavior preserved)
- Swipe feedback colors: Claude's discretion — must be a colorblind-safe, non-partisan pair that does NOT use ev-coral or ev-muted-blue (avoid associations with political parties); not red/green

### Results layout
- Badge ranking hierarchy retains trophy metaphor colors: Diamond = cyan, Gold = amber (existing colors preserved)
- EV brand polish applied to card backgrounds, typography, layout structure, and spacing
- "View on Essentials" CTA button uses ev-coral (matches CompassV2 primary action button treatment)
- Candidate photo prominence and stats header treatment: Claude's discretion

### Claude's Discretion
- Colorblind-safe swipe feedback color pair selection (must not be red/green, coral, or muted-blue)
- Whether completed issue cards get a left-border accent or status badge is sufficient
- Hub subtitle copy adjustments
- Candidate photo sizing in results cards
- Results stats header layout (keep current 4-column or simplify)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- EV design tokens already configured in tailwind.config.ts and index.css: ev-coral (#ff5740), ev-muted-blue (#00657c), ev-light-blue (#59b0c4), ev-yellow (#fed12e), Manrope font
- `@chrisandrewsedu/ev-ui` SiteHeader component already in use (App.tsx) — do not modify
- Framer Motion already wired in all three surfaces — preserve all animation props exactly

### Established Patterns
- CompassV2 uses: white cards, black text, rounded-xl/2xl, coral for primary CTAs, Manrope bold for headings
- Essentials uses: white cards with shadow-lg, rounded-lg, light-blue accents, politician cards with `bg-white p-4 rounded-lg shadow-lg`
- IssueHub currently uses `ev-light-blue` as primary accent — this should be upgraded to `ev-muted-blue` per decision above
- Custom CSS classes in index.css: `.ev-quote-card`, `.ev-quote-card-dragging`, `.ev-heading`, `.ev-text-primary` — existing classes should be updated not replaced

### Integration Points
- Phase 77 extracts Read & Rank to standalone repo (EV-ReadRank/ directory) — changes should target that repo, not EV-prototypes/read-rank/
- App.tsx uses `bg-ev-white` as page background — consistent with CompassV2 white base
- ResultsPhase has a `onViewAlignment` callback wired to candidate navigation — CTA button visual only, don't touch the callback

</code_context>

<specifics>
## Specific Ideas

- "Match CompassV2 exactly" — serious and civic, not playful
- Swipe colors must not create partisan color association (no coral = one party, blue = another party interpretation)
- All animations stay exactly as they are — this is purely a visual CSS/color/typography update

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 78-visual-refresh*
*Context gathered: 2026-03-11*
