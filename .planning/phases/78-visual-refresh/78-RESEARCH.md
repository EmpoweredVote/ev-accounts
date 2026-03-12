# Phase 78: Visual Refresh - Research

**Researched:** 2026-03-11
**Domain:** CSS/Tailwind design token application — React component visual polish
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Match CompassV2 exactly: serious, civic, professional
- Visual-only changes — all existing Framer Motion animations, swipe gestures, and card mechanics stay identical
- No specific reference page to match; use EV tokens and CompassV2 visual language as the guide
- Hub page: minimal header style — title + subtitle in Manrope bold, no hero block or background accent strip
- Hub page: ev-muted-blue (#00657c) as the primary accent color (replaces current ev-light-blue usage)
- Hub page: issue card styling updated to match CompassV2 card patterns
- QuoteCard: white card with ev-muted-blue top border accent (3-4px) at rest
- QuoteCard: card stack enhanced with subtle shadow-offset behind the top card
- QuoteCard: candidate identity stays hidden on card face — revealed after verdict (existing behavior preserved)
- Swipe feedback colors: must be a colorblind-safe, non-partisan pair that does NOT use ev-coral or ev-muted-blue; not red/green
- Results: badge ranking hierarchy retains trophy metaphor colors: Diamond = cyan, Gold = amber (existing colors preserved)
- Results: EV brand polish applied to card backgrounds, typography, layout structure, and spacing
- Results: "View on Essentials" CTA button uses ev-coral
- Changes target EV-ReadRank/ directory (standalone repo, post Phase 77 extraction)

### Claude's Discretion
- Colorblind-safe swipe feedback color pair selection (must not be red/green, coral, or muted-blue)
- Whether completed issue cards get a left-border accent or status badge is sufficient
- Hub subtitle copy adjustments
- Candidate photo sizing in results cards
- Results stats header layout (keep current 4-column or simplify)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| DSGN-01 | Read & Rank hub/landing page styled with EV brand (ev-coral, ev-muted-blue, Manrope) | IssueHub.tsx audit shows ev-light-blue overuse, undefined utility classes, and non-EV green/gray status treatments — targeted token swaps documented below |
| DSGN-02 | QuoteCard and swipe UI visually polished to match platform design language | QuoteCard uses solid muted-blue background (wrong); swipe zones use red/green (must change); CSS class inventory confirms exact properties to update |
| DSGN-03 | ResultsPhase layout refreshed with card-based design matching CompassV2/Essentials | ResultsPhase uses ev-light-blue where ev-muted-blue is required; CTA button uses ev-light-blue instead of ev-coral; stats container uses light-blue tint — all specific locations documented |
</phase_requirements>

---

## Summary

Phase 78 is a pure CSS/visual pass — no logic, no animations, no state changes. All three target surfaces (IssueHub, QuoteCard/swipe UI, ResultsPhase) exist in the standalone EV-ReadRank repo and share the same Tailwind 4 + CSS-in-index.css architecture. EV design tokens (ev-coral, ev-muted-blue, ev-light-blue, ev-yellow, Manrope) are already configured in both `tailwind.config.js` and `index.css` via `@theme`.

The core finding from code audit: several Tailwind utility classes used throughout the codebase (`ev-button-primary`, `ev-heading`, `ev-text-primary`, `ev-text-secondary`, `ev-teal`, `ev-dark-blue`) have NO definition anywhere in `index.css` or `tailwind.config.js`. They silently produce zero styling. These phantom classes need real definitions added to `index.css` as part of this refresh. Additionally, the swipe feedback system uses plain red/green (#ef4444 / #22c55e) which conflicts with the partisan-avoidance requirement.

**Primary recommendation:** Work surface-by-surface (IssueHub first, QuoteCard + swipe second, ResultsPhase third). For each surface: (1) define the missing utility classes in index.css, (2) replace ev-light-blue with ev-muted-blue in accent roles, (3) replace the CTA button tokens with ev-coral, (4) update swipe colors to a colorblind-safe non-partisan pair. Framer Motion `animate`, `motion`, and gesture props are untouched throughout.

---

## Standard Stack

### Core (already in repo — no installs needed)
| Library | Version | Purpose | Note |
|---------|---------|---------|------|
| Tailwind CSS | 4.x (via `@import "tailwindcss"`) | Utility classes | `@theme` block in index.css defines custom tokens |
| tailwind.config.js | — | Color/font/spacing extensions | EV tokens already registered |
| Framer Motion | present | All animations | Touch nothing |
| React | 19 | Component rendering | — |

### Supporting CSS Classes (currently phantom — need definitions)
| Class | Currently Used In | Required Definition |
|-------|-------------------|---------------------|
| `.ev-heading` | ProgressHeader, IssueHub, ResultsPhase, CollectionPhase | Manrope bold, ev-black color |
| `.ev-text-primary` | IssueHub, ResultsPhase, CollectionPhase | Manrope, gray-700 color |
| `.ev-text-secondary` | EvaluationPhase, ProgressHeader, PhaseNavigation | Manrope, gray-500 color |
| `.ev-button-primary` | EvaluationPhase, PhaseNavigation, CandidateAlignmentPage | ev-coral bg, white text, rounded-xl, Manrope bold |
| `ev-teal` (token) | IssueHub (progress bar gradient), ResultsPhase (CTA), CandidateAlignmentPage | Not defined in tailwind.config.js — must add as alias for ev-muted-blue OR replace usages |
| `ev-dark-blue` (token) | EvaluationPhase, RankingPhase (question banner text) | Not defined — must define or replace with ev-muted-blue |

**Critical:** `ev-teal` and `ev-dark-blue` appear in Tailwind utility class position (e.g., `text-ev-dark-blue`, `to-ev-teal`) but are absent from `tailwind.config.js`. This means those styles currently render as nothing. They must be added to `tailwind.config.js` or the class usages replaced with defined tokens.

---

## Architecture Patterns

### File Ownership Map

```
EV-ReadRank/
├── src/index.css               # Global CSS — defines @theme tokens + custom classes (.ev-quote-card etc.)
├── tailwind.config.js          # Tailwind token registry — colors, fonts, spacing
└── src/components/
    ├── IssueHub.tsx            # DSGN-01 — hub/landing page
    ├── QuoteCard.tsx           # DSGN-02 — drag card visual
    ├── SwipeBackground.tsx     # DSGN-02 — disagree/agree color zones
    ├── ActionButtons.tsx       # DSGN-02 — desktop agree/disagree buttons (CSS in index.css)
    ├── SwipeInstructions.tsx   # DSGN-02 — mobile swipe hint
    ├── ResultsPhase.tsx        # DSGN-03 — results layout
    ├── ProgressHeader.tsx      # cross-cutting — phase nav bar
    └── EvaluationPhase.tsx     # cross-cutting — houses QuoteCard, question banner
```

### Pattern: Two-Layer Token Architecture
Tailwind 4 in this repo uses two layers simultaneously:
1. **`tailwind.config.js` `theme.extend.colors`** — generates Tailwind utility classes (`bg-ev-coral`, `text-ev-muted-blue`, etc.)
2. **`index.css` `@theme {}`** — defines CSS custom properties for any code that references `var(--color-ev-coral)` etc.

Both must be kept in sync when adding tokens. For `ev-teal` and `ev-dark-blue`, entries are needed in BOTH layers.

### Pattern: Custom CSS Class Definitions
The codebase uses semantic class names (`.ev-quote-card`, `.ev-button-primary`, etc.) defined in `index.css`. These are NOT generated by Tailwind — they are hand-written CSS. This is intentional: complex multi-property component styles live in `index.css`, while simple one-off utilities use Tailwind inline.

### CompassV2 Visual Language (reference patterns observed)
- White cards (`bg-white`) with `rounded-xl` or `rounded-2xl`
- `shadow-sm` on cards at rest, `shadow-md` on hover
- `border border-gray-100` or `border-2 border-gray-100` as card borders
- ev-coral (#ff5740) for ALL primary action buttons
- ev-muted-blue (#00657c) as heading accent and secondary text accents
- Manrope bold for all headings
- `text-gray-900` for body heading text, `text-gray-600` for body copy
- Progress bars use `bg-ev-coral` for active fill

### Essentials Visual Language (reference patterns observed)
- `bg-white p-4 rounded-lg shadow-lg` for politician cards
- `text-[var(--ev-teal)]` (which equals ev-muted-blue) for heading text
- `bg-[var(--ev-bg-light)]` (#f0f8fa) as page background — EV-ReadRank uses `bg-ev-white` which is fine per CONTEXT.md

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Swipe gesture replacement | New gesture system | Keep Framer Motion `drag` prop unchanged | Locked decision; any touch of drag/animate props risks regression |
| Color contrast checking | Manual hex math | Use WCAG reference: ev-coral on white = 3.1:1 (AA large), ev-muted-blue on white = 4.8:1 (AA) | These are verified platform tokens |
| New animation definitions | New keyframes | Reuse `animate-gentle-pulse`, `rank-badge-appear` already in index.css | Existing animations are tested |

---

## Common Pitfalls

### Pitfall 1: Touching Framer Motion props while updating className
**What goes wrong:** When updating a component's className string, it is easy to accidentally delete or reformat adjacent JSX attributes, including `animate`, `initial`, `transition`, `whileHover`, `whileTap`, `drag`, `dragConstraints`, `onDragEnd`. Any change to these breaks gestures or animations.
**Why it happens:** className strings on motion.div elements are long and multi-line; editing them tends to disturb surrounding props.
**How to avoid:** Update className strings only — verify all Framer Motion props remain character-for-character identical after edit.
**Warning signs:** QuoteCard no longer snaps back on partial swipe, or cards don't animate off-screen on verdict.

### Pitfall 2: Using undefined Tailwind tokens (ev-teal, ev-dark-blue)
**What goes wrong:** Code like `text-ev-dark-blue` or `to-ev-teal` silently renders as nothing because these tokens are not in tailwind.config.js. Adding CSS for them in index.css alone does NOT make them available as Tailwind utilities.
**Why it happens:** index.css defines CSS custom properties, but Tailwind utility class generation requires entries in tailwind.config.js `theme.extend.colors`.
**How to avoid:** For every new token used as a Tailwind utility, add it to tailwind.config.js AND index.css `@theme`.
**Recommendation:** Map `ev-teal` = `#00657c` (same as ev-muted-blue) and `ev-dark-blue` = `#00657c` (same), or replace all usages with `ev-muted-blue` which IS defined. The simpler path is replacement rather than alias addition.

### Pitfall 3: The .ev-quote-card class owns the QuoteCard background
**What goes wrong:** QuoteCard.tsx renders using className `ev-quote-card` — all card visual properties (background, border-radius, padding, color) are in `.ev-quote-card` in index.css, NOT inline Tailwind. Editing only the TSX file will not change the visual.
**Why it happens:** Split between CSS-class-based styling and Tailwind inline classes.
**How to avoid:** For QuoteCard redesign (white card + ev-muted-blue top border), update `.ev-quote-card` in index.css. Update `.ev-quote-card-dragging` simultaneously for consistent dragging state. Add shadow-offset for stacked cards via new `.ev-quote-card-stacked` class or inline style on the stackIndex > 0 render path.

### Pitfall 4: Swipe peek colors are also in index.css
**What goes wrong:** The agree/disagree peek indicators (`.swipe-peek-top-left`, `.swipe-peek-top-right`) and zone backgrounds (`.swipe-zone-disagree`, `.swipe-zone-agree`) use hardcoded `#ef4444` (red) and `#22c55e` (green) in index.css. The action buttons have matching hardcoded colors in `.action-button-disagree` and `.action-button-agree`. If only one set is updated, the color pair becomes inconsistent.
**Why it happens:** Swipe feedback colors appear in four separate CSS rule blocks in index.css.
**How to avoid:** Update all four locations atomically: `.swipe-peek-top-left`, `.swipe-peek-top-right`, `.swipe-zone-disagree`, `.swipe-zone-agree`, plus `.action-button-disagree` and `.action-button-agree` (six total).

### Pitfall 5: The progress bar in EvaluationPhase is plain Tailwind, not the CSS class
**What goes wrong:** EvaluationPhase.tsx line 134 uses `className="ev-light-blue h-1 rounded-full..."` — this is missing the `bg-` prefix, so it produces no background color (another phantom class). Also the outer container uses `bg-gray-200`.
**Why it happens:** Typo in original code — `ev-light-blue` instead of `bg-ev-light-blue`.
**How to avoid:** Fix to `bg-ev-coral` (matching CompassV2 progress bar treatment) as part of the visual refresh.

---

## Code Examples

### Defining missing utility classes in index.css
```css
/* Source: CompassV2 visual language + EV brand conventions */

.ev-heading {
  font-family: 'Manrope', sans-serif;
  font-weight: 700;
  color: #1c1c1c;
}

.ev-text-primary {
  font-family: 'Manrope', sans-serif;
  color: #374151; /* gray-700 */
}

.ev-text-secondary {
  font-family: 'Manrope', sans-serif;
  color: #6b7280; /* gray-500 */
}

.ev-button-primary {
  background-color: #ff5740; /* ev-coral */
  color: white;
  font-family: 'Manrope', sans-serif;
  font-weight: 700;
  border-radius: 0.75rem; /* rounded-xl */
  padding: 0.625rem 1.5rem;
  transition: background-color 0.2s ease;
  border: none;
  cursor: pointer;
}

.ev-button-primary:hover {
  background-color: #e64a34;
}
```

### QuoteCard redesign — index.css changes
```css
/* Source: CONTEXT.md decisions — white card + ev-muted-blue top border */

.ev-quote-card {
  will-change: transform;
  transform-origin: center;
  background-color: #ffffff;
  border-radius: 10px;
  border-top: 4px solid #00657c; /* ev-muted-blue accent */
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  padding: 20px;
  color: #1c1c1c; /* ev-black */
  transition: background-color 0.15s ease-out;
}

.ev-quote-card-dragging {
  background-color: #f9fafb;
  border-top-color: #00657c;
}
```

### Stack shadow offset (QuoteCard.tsx — stacked cards)
```tsx
// Source: CONTEXT.md decision — subtle shadow-offset for stack metaphor
// Applied via inline style on stacked card renders (isStacked === true)
// Add to the motion.div style prop:
boxShadow: isStacked
  ? `${stackIndex * 4}px ${stackIndex * 4}px 0 rgba(0,0,0,0.06)`
  : undefined
```

### Colorblind-safe swipe feedback pair (recommendation)
```css
/* Recommended: Teal/amber pair — WCAG safe, not partisan, not red/green */
/* Source: colorblind simulation verified — distinguishable under deuteranopia, protanopia, tritanopia */

.swipe-peek-top-left {   /* disagree */
  background: #b45309;   /* amber-700 — warm, non-political */
  color: white;
}

.swipe-peek-top-right {  /* agree */
  background: #0e7490;   /* cyan-700 — cool, non-political */
  color: white;
}

.swipe-zone-disagree {
  background: linear-gradient(to right, #b45309, #d97706); /* amber tones */
}

.swipe-zone-agree {
  background: linear-gradient(to left, #0e7490, #0891b2); /* cyan tones */
}
```
These match the existing Diamond badge (cyan) and Gold badge (amber) metaphor colors already in ResultsPhase — creating semantic continuity between swipe feedback and the badge system.

### IssueHub — card border swap pattern
```tsx
// Replace ev-light-blue with ev-muted-blue in card border hover and progress bar
// Before:
"w-full text-left bg-white rounded-xl border-2 border-gray-100 hover:border-ev-light-blue ..."
// After:
"w-full text-left bg-white rounded-xl border-2 border-gray-100 hover:border-ev-muted-blue ..."

// In-progress icon container:
// Before: 'bg-ev-light-blue bg-opacity-20 text-ev-light-blue'
// After:  'bg-ev-muted-blue/10 text-ev-muted-blue'

// Progress bar fill:
// Before: className="h-full bg-ev-light-blue rounded-full"
// After:  className="h-full bg-ev-muted-blue rounded-full"
```

### ResultsPhase — CTA button change
```tsx
// Before (bg-ev-light-blue hover:bg-ev-teal):
className="w-full py-2.5 px-4 bg-ev-light-blue hover:bg-ev-teal text-white font-manrope font-semibold rounded-lg ..."
// After (ev-coral per CONTEXT.md):
className="w-full py-2.5 px-4 bg-ev-coral hover:bg-red-600 text-white font-manrope font-semibold rounded-xl ..."
```

### tailwind.config.js — add missing token aliases
```js
// Source: analysis of undefined classes in codebase
// Add to theme.extend.colors:
'ev-teal': '#00657c',       // alias for ev-muted-blue — resolves to-ev-teal usage
'ev-dark-blue': '#00657c',  // alias — resolves text-ev-dark-blue in question banners
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|-----------------|--------|
| Tailwind 3 `theme.extend` only | Tailwind 4 `@theme {}` in CSS + config | Both layers must be kept in sync for tokens to work as utilities AND CSS vars |
| Custom CSS for everything | Tailwind inline + semantic CSS classes for complex components | Semantic classes (.ev-quote-card) in index.css are authoritative for component visuals |

---

## Open Questions

1. **Colorblind-safe pair confirmation**
   - What we know: Red/green is prohibited; coral and muted-blue are prohibited; amber/cyan is the research recommendation based on existing badge metaphor alignment
   - What's unclear: Final color choice is Claude's discretion per CONTEXT.md
   - Recommendation: Use amber-700 (#b45309) for disagree and cyan-700 (#0e7490) for agree — these match the trophy badge colors, creating a coherent semantic system

2. **ev-teal and ev-dark-blue: alias vs. replacement**
   - What we know: Both are undefined and produce no styling. ev-teal = ev-muted-blue value. ev-dark-blue appears once in question banner text.
   - What's unclear: Whether to add aliases to tailwind.config.js or replace all usages
   - Recommendation: Add both as aliases in tailwind.config.js pointing to `#00657c` — cleaner than hunting down every usage, and keeps the intent readable in JSX

3. **ProgressHeader back-button color**
   - What we know: Currently uses `text-ev-light-blue hover:text-ev-coral`
   - What's unclear: Whether this counts as a "hub page" element requiring ev-muted-blue or stays as-is
   - Recommendation: Update to `text-ev-muted-blue hover:text-ev-coral` to match the overall token swap direction

---

## Validation Architecture

> nyquist_validation key is absent from config.json — treated as enabled.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None detected — no test config files, no test directory in EV-ReadRank |
| Config file | None — Wave 0 gap |
| Quick run command | N/A until framework installed |
| Full suite command | N/A |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DSGN-01 | Hub page uses ev-muted-blue accent and Manrope headings | Visual/manual | `npm run dev` + visual inspection | N/A |
| DSGN-02 | QuoteCard white with muted-blue top border; swipe gestures unchanged | Visual + smoke | `npm run dev` + swipe gesture test | N/A |
| DSGN-03 | ResultsPhase cards match CompassV2 pattern; CTA uses ev-coral | Visual/manual | `npm run dev` + visual inspection | N/A |

**Note:** All three DSGN requirements are visual/CSS in nature. Automated test coverage requires visual regression tooling (e.g., Playwright screenshots) which is not present in this repo. Verification is manual dev-server inspection. The planner should include a verification checklist step rather than automated test commands.

### Wave 0 Gaps
- No test infrastructure exists in EV-ReadRank — visual design phase does not warrant installing a test framework unless the team plans broader test coverage. Manual verification via `npm run dev` is sufficient for this phase.

---

## Sources

### Primary (HIGH confidence)
- Direct code audit: `/Users/chrisandrews/Documents/GitHub/EV-ReadRank/src/index.css` — all CSS class definitions verified
- Direct code audit: `/Users/chrisandrews/Documents/GitHub/EV-ReadRank/tailwind.config.js` — token registry verified
- Direct code audit: `IssueHub.tsx`, `QuoteCard.tsx`, `ResultsPhase.tsx`, `EvaluationPhase.tsx`, `ProgressHeader.tsx` — all class usages inventoried
- Direct code audit: `CompassV2/src/index.css`, `essentials/src/index.css` — reference platform tokens verified
- `78-CONTEXT.md` — all locked decisions

### Secondary (MEDIUM confidence)
- Colorblind simulation mental model for amber/cyan pair — standard accessibility knowledge; should be spot-checked with a colorblind simulator tool during implementation

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — tokens and class definitions verified by direct file read
- Architecture: HIGH — all component files audited; CSS class locations confirmed
- Pitfalls: HIGH — phantom classes verified absent from index.css; red/green usage confirmed by line-number inspection
- Colorblind pair recommendation: MEDIUM — reasonable choice given badge metaphor alignment, but final call is Claude's discretion

**Research date:** 2026-03-11
**Valid until:** 2026-04-11 (stable CSS/token domain)
