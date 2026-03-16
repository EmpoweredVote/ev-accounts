# Phase 91: Results Polish + Visual Redesign - Research

**Researched:** 2026-03-15
**Domain:** Framer Motion animation sequencing, React state machines for reveal UX, CSS animation reuse, visual cohesion patterns
**Confidence:** HIGH

## Summary

Phase 91 is a UI-only phase with no backend dependencies and no new library acquisitions. All animation primitives needed are already present in the codebase: `megaBurst`, `slamDown`, `screenShake`, `gentle-pulse` keyframes in `index.css`; Framer Motion `AnimatePresence` already imported in evaluation flow; the `MegaParticles` component in `MatchCard.tsx` ready for extraction and reuse.

The primary technical challenge is the **reveal state machine** in `ResultsPhase.tsx`. The component currently renders candidate identity immediately on load. The redesign requires a `revealed: boolean` state gate — cards render in masked state (quote + verdict only), a single coral button triggers a sequenced animation (button morph → 300ms pause → staggered card reveals with per-card `MegaParticles` burst + `slamDown` identity section → CTA fade-in). This is a Framer Motion `useAnimate` / `variants` + `staggerChildren` problem, well within existing patterns.

The visual cohesion pass (CHRM-04) is a targeted find-and-replace of Fraunces references across all components. The codebase uses Fraunces in exactly three contexts: `.ev-heading` CSS class, `.ev-quote-text` CSS class, and inline `fontFamily: "'Fraunces', serif"` style strings. Replacing all three with Manrope + updated weights gives the desired Linear-style typography without changing layout.

**Primary recommendation:** Implement phase as three sequential plans — (1) reveal state machine + card redesign in `ResultsPhase.tsx`, (2) end-of-evaluation / matchup layout changes in `EvaluationPhase.tsx` + `MatchupPhase.tsx` + page transitions in `PhaseContainer.tsx`, (3) full-app visual cohesion pass across all components.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Reveal mechanic:**
- Single "Reveal Who Said It" button triggers staggered reveal across all cards at once — one big moment, not per-card
- Pre-reveal cards show quote text and verdict badge only — no identity section at all (no silhouette, no "???")
- Identity section (photo, name, office) appears for the first time on reveal, expanding into each card
- Centerpiece coral button with subtle pulse animation while waiting — this is THE moment
- High drama reveal: button morphs/disappears on press, 300ms anticipation pause, then cards reveal with staggered 200ms gaps
- Each card's identity reveal uses adapted megaBurst particle effect + slamDown expansion
- CTAs fade in after all reveals complete
- prefers-reduced-motion: disable particle bursts and stagger delays, keep opacity fades

**Result card redesign:**
- "View on Essentials" is the sole CTA per card — "View Alignment" button removed entirely
- Card content post-reveal: quote text, candidate photo/name/office, source link, verdict badge (AGREED/DISAGREED), rank number for agreed quotes
- Agreed cards: teal left-accent border, full color treatment
- Disagreed cards: gray left-accent border, slightly muted styling
- "Explore More Issues" secondary button (teal outline) fades in below all cards after reveal completes

**CandidateAlignmentPage:**
- Visual polish only this phase — updated typography/colors to match new results design (per RSLT-04)
- No CTA pointing to it from results cards — accessible via direct URL only
- Future: ReadRank card on Essentials politician profile replaces this page entirely (deferred)

**Visual cohesion pass (full app):**
- Scope: ALL pages — Hub, Evaluation, Practice, Matchup, Results, CandidateAlignmentPage
- Color palette stays: cream surfaces (#faf7f2, #fffefb), ev-coral/ev-teal accents, paper texture background retained at 0.025 opacity
- Typography: Manrope everywhere — drop Fraunces entirely from the app
- Mixed component styles is the primary inconsistency to fix: buttons, badges, cards should share consistent border-radius, shadow, and border treatment
- Visual reference: Linear-style clean — minimal, precise spacing, subtle shadows, mono-weight borders, functional elegance
- Claude eyeballs token consistency per component (no formal design token enforcement)

**End-of-evaluation layout:**
- When all quotes are evaluated, the last QuoteCard fades out and the ranked list animates from sidebar to full-width center layout
- "See Results" button appears below the expanded ranked list
- Smooth transition from split evaluation layout to centered pre-results state

**Matchup layout:**
- During head-to-head matchups, hide ranked sidebar entirely — both matchup cards get full width/breathing room
- Sidebar returns when matchups complete and evaluation resumes

**Page transitions:**
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

### Deferred Ideas (OUT OF SCOPE)
- ReadRank card on Essentials politician profiles — replaces CandidateAlignmentPage as cross-app integration surface (new capability, own phase)
- Mobile-specific matchup layout investigation — user unsure of current mobile matchup experience, may need separate attention
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| RSLT-01 | Results cards are visually cleaner with less information density per card | Card redesign: remove "View Alignment" button, single CTA, identity hidden pre-reveal reduces cognitive load on first render |
| RSLT-02 | "Who said it" reveal has a dramatic staggered animation moment | Reveal state machine + reuse of `megaBurst`/`slamDown` keyframes from `MatchCard.tsx` `MegaParticles` component |
| RSLT-03 | "View on Essentials" is the primary CTA on result cards | Remove `onViewAlignment` handler and "View Alignment" button from `QuoteResultCard`; promote Essentials `<a>` to `ev-button-primary` |
| RSLT-04 | CandidateAlignmentPage stays in ReadRank with visual polish matching new design | Typography swap (Fraunces → Manrope) + color/spacing pass in `CandidateAlignmentPage.tsx`; no routing or data changes |
| CHRM-04 | Visual redesign applied across all components (revert editorial WIP, design from scratch) | Full Fraunces removal from CSS + all component inline styles; consistent border-radius/shadow tokens eyeballed per component |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| framer-motion | ^12.23.26 | Animation sequencing, AnimatePresence, variants, stagger | Already installed; used throughout app for card animations |
| react | ^19.2.0 | Component state for reveal gate | Already installed |
| zustand | ^5.0.9 | Store reads (rankedQuotes, disagreedQuotes, goToHub) | Already installed; no store changes needed this phase |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| CSS keyframes (index.css) | n/a | `megaBurst`, `slamDown`, `screenShake`, `gentle-pulse` — low-level animation atoms | For animations not requiring Framer Motion orchestration |
| react-router-dom | ^7.11.0 | AnimatePresence wrapping routes in `PhaseContainer.tsx` | Page-level transitions only |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| CSS `@keyframes` for particle burst | Framer Motion `keyframes` array | CSS is already wired with `--dx`/`--dy` custom properties; reuse is simpler |
| `useAnimate` imperative API | Framer Motion `variants` + `staggerChildren` | `variants` declarative stagger is cleaner for the per-card reveal; `useAnimate` better for the button morph sequence |

**No new installations needed for this phase.**

## Architecture Patterns

### Recommended Project Structure
No structural changes. All work is in-place edits to existing files:
```
EV-readrank/src/
├── components/
│   ├── ResultsPhase.tsx     # Complete redesign (reveal state machine)
│   ├── CandidateAlignmentPage.tsx  # Visual polish only
│   ├── MatchupPhase.tsx     # Sidebar hide during matchup
│   ├── EvaluationPhase.tsx  # End-of-evaluation layout + sidebar show/hide
│   └── PhaseContainer.tsx   # AnimatePresence page transitions
└── index.css                # Fraunces removal, shared token cleanup
```

### Pattern 1: Reveal State Machine

**What:** `ResultsPhase` holds a `revealed: boolean` state (starts `false`). Pre-reveal renders masked cards. On button press, an async sequence fires: button exits → 300ms pause → Framer Motion stagger variant plays on cards → `slamDown` + `MegaParticles` on identity section per card → after last card reveals, CTAs fade in.

**When to use:** Any multi-step reveal where UI gates downstream content behind a single user action.

**Example:**
```typescript
// Reveal state gate
const [revealed, setRevealed] = useState(false);
const [revealPhase, setRevealPhase] = useState<'idle' | 'anticipation' | 'revealing' | 'done'>('idle');

const handleReveal = async () => {
  setRevealPhase('anticipation');
  await new Promise(r => setTimeout(r, 300)); // 300ms pause
  setRevealPhase('revealing');
};

// Framer Motion stagger on card list
const containerVariants = {
  hidden: {},
  visible: {
    transition: {
      staggerChildren: 0.2, // 200ms gaps between cards
    }
  }
};

const cardVariants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { duration: 0.4, ease: [0.22, 1, 0.36, 1] } }
};
```

### Pattern 2: MegaParticles Extraction

**What:** `MegaParticles` component is currently private inside `MatchCard.tsx`. For `ResultsPhase`, it needs to be used per identity reveal. Extract `MegaParticles` (lines 20-64 of `MatchCard.tsx`) and its `Particle` interface to a shared location or re-define inline in `ResultsPhase.tsx` (acceptable — it's 45 lines and currently contains no MatchCard-specific logic).

**When to use:** Any component needing the coral particle burst effect.

**Approach:** Re-define inline in `ResultsPhase.tsx`. Modifying `MatchCard.tsx` exports is unnecessary complexity for a single additional consumer.

### Pattern 3: Sidebar Visibility Toggle for Matchup

**What:** `EvaluationPhase.tsx` renders `RankedListSidebar` inside `.evaluation-sidebar-panel`. To hide during matchup, conditionally render based on `showMatchupMode`:

```typescript
// In the desktop split layout return:
<div className="evaluation-sidebar-panel">
  {!showMatchupMode && <RankedListSidebar ref={sidebarRef} />}
</div>
```

The `.evaluation-sidebar-panel` CSS uses `flex: 1` — when sidebar is hidden, the main panel will not expand to fill (flex layout with fixed `width: 380px` on main panel). For full width during matchup, switch the layout class or override inline when `showMatchupMode` is true.

**Better approach:**
```typescript
// Desktop layout
<div className={showMatchupMode ? 'matchup-full-layout' : 'evaluation-split-layout'}>
  <div className={showMatchupMode ? 'matchup-full-main' : 'evaluation-main-panel'}>
    {evaluationContent}
  </div>
  {!showMatchupMode && (
    <div className="evaluation-sidebar-panel">
      <RankedListSidebar ref={sidebarRef} />
    </div>
  )}
</div>
```

Add `.matchup-full-layout` and `.matchup-full-main` CSS classes in `index.css`.

### Pattern 4: End-of-Evaluation Full-Width Ranked List

**What:** When `isComplete` is true and `showMatchupMode` is false, transition to a centered full-width layout showing the ranked list. Currently, `isComplete` shows a small "Done" card inside the main panel; the sidebar is still visible alongside it.

**When to use:** `isComplete && !showMatchupMode` on desktop.

**Approach:** When `isComplete`, replace the split layout entirely with a centered column:
```typescript
if (isComplete && !showMatchupMode && isMouseDevice) {
  return (
    <div className="space-y-5 max-w-2xl mx-auto">
      <RankedListSidebar /> {/* full-width centered */}
      {showResultsButton && <button ...>See Your Results</button>}
    </div>
  );
}
```

This requires `RankedListSidebar` to work in full-width context — it likely already does as its container constrains width.

### Pattern 5: AnimatePresence Page Transitions

**What:** Wrap the `renderPhase()` switch in `PhaseContainer.tsx` with `AnimatePresence mode="wait"`. Each phase component gets an outer `motion.div` with enter/exit variants.

**When to use:** Page-level transitions — Hub ↔ Evaluation ↔ Results.

**Example:**
```typescript
// PhaseContainer.tsx
import { AnimatePresence, motion } from 'framer-motion';

// Inside render:
<AnimatePresence mode="wait">
  <motion.div
    key={phase}
    initial={{ opacity: 0, y: 16 }}
    animate={{ opacity: 1, y: 0 }}
    exit={{ opacity: 0, y: -8 }}
    transition={{ duration: 0.25, ease: [0.22, 1, 0.36, 1] }}
  >
    {renderPhase()}
  </motion.div>
</AnimatePresence>
```

Each phase has distinct enter/exit per the context decisions (Hub→Eval slides up, Eval→Results slides down, Results→Hub slides down).

### Anti-Patterns to Avoid

- **Per-card reveal button:** Locked decision is one global button. Don't add per-card reveal triggers.
- **Modifying store for reveal state:** `revealed` is ephemeral session UI state — local `useState` only, not Zustand.
- **Fraunces on quote text:** `.ev-quote-text` class currently uses Fraunces italic. During cohesion pass, replace with Manrope normal weight. The quote text will lose the editorial italic look — this is intentional per the Linear-style direction.
- **AnimatePresence `mode="sync"`:** Use `mode="wait"` so the exiting phase fully unmounts before the entering phase mounts. `mode="sync"` causes both to render simultaneously with overlapping layout.
- **CSS `@media (prefers-reduced-motion)` already sets `animation-duration: 0.01ms`:** The existing block in `index.css` (lines 303-311) already covers all CSS keyframe animations globally. For Framer Motion animations, use `useReducedMotion()` hook to gate stagger delays and particle rendering.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stagger orchestration | Manual `setTimeout` chain per card | Framer Motion `staggerChildren` in variants | Variants respect `prefers-reduced-motion` via `useReducedMotion`; setTimeout chains are fragile and don't pause on page hide |
| Particle burst | Custom canvas/WebGL particle system | Re-use `MegaParticles` + `megaBurst` CSS keyframe from MatchCard | Already tuned with `--dx`/`--dy` CSS custom properties; proven in production matchup phase |
| Page-level unmount animation | Custom `useEffect` + `useState` exit flag | `AnimatePresence mode="wait"` | AnimatePresence handles deferred unmount correctly; DIY solutions miss edge cases with React 19 concurrent mode |
| `prefers-reduced-motion` detection | `window.matchMedia` in useEffect | `useReducedMotion()` from framer-motion | SSR-safe, reactive to OS setting changes at runtime |

**Key insight:** Every animation primitive needed for this phase already exists in the codebase. The work is wiring and adaptation, not invention.

## Common Pitfalls

### Pitfall 1: Fraunces in `.ev-quote-text` Breaks Quote Rendering
**What goes wrong:** The `.ev-quote-text` CSS class (used in both `ResultsPhase.tsx` and `CandidateAlignmentPage.tsx`) sets `font-family: 'Fraunces', serif`. After removing the Google Fonts import for Fraunces from `index.css`, any remaining usage will fall back to the OS default serif (Times New Roman on Mac/Windows), not Manrope.
**Why it happens:** Two locations define Fraunces usage — the CSS class and the Google Fonts `@import` at line 1 of `index.css`. Removing the import without updating the class (or vice versa) creates a silent fallback.
**How to avoid:** In the cohesion pass, update `.ev-quote-text` to `font-family: 'Manrope', sans-serif; font-style: normal` before removing the Fraunces `@import`. Do both in the same commit.
**Warning signs:** Quote text renders in a serif fallback font during dev preview.

### Pitfall 2: `MegaParticles` Uses CSS Custom Properties that Must Be Set Inline
**What goes wrong:** The `megaBurst` keyframe uses `var(--dx)` and `var(--dy)`. These must be set as inline styles on each particle element. If the component is copy-pasted without the `['--dx' as string]: \`${p.dx}px\`` inline style pattern, the particles will all burst to the same position (0, 0).
**Why it happens:** CSS custom properties on keyframes require the variable to be scoped on the element itself — they cannot be provided by a parent.
**How to avoid:** Keep the `['--dx' as string]: \`${p.dx}px\`` style pattern exactly as it appears in `MatchCard.tsx` lines 55-56.
**Warning signs:** All particles collapse to center on reveal.

### Pitfall 3: `AnimatePresence` Requires Stable `key` on Children
**What goes wrong:** `AnimatePresence` needs the child's `key` to change between phases so it knows when to animate out the old and in the new. Using a non-changing key (e.g., always `"phase"`) means AnimatePresence treats every render as the same element and never fires exit/enter animations.
**Why it happens:** React reuses DOM nodes when keys match — AnimatePresence piggybacks on this.
**How to avoid:** Use `key={phase}` on the `motion.div` wrapping `renderPhase()` in `PhaseContainer.tsx`. The `phase` string changes between `'hub'`, `'evaluation'`, `'results'`.
**Warning signs:** Page transitions don't animate.

### Pitfall 4: End-of-Evaluation Layout Causes Double Sidebar
**What goes wrong:** If the `isComplete` full-width centered layout uses `<RankedListSidebar>` while the normal split layout also renders `<RankedListSidebar>` conditionally, you may briefly render two instances during the layout switch.
**Why it happens:** React re-renders before CSS transitions complete.
**How to avoid:** Mutually exclusive render paths — when `isComplete && !showMatchupMode` on desktop, render the centered layout as a complete replacement, not an additional element alongside the split layout.

### Pitfall 5: `prefers-reduced-motion` Applies to CSS Keyframes but Not Framer Motion
**What goes wrong:** The global CSS block in `index.css` nukes all CSS keyframe durations, so `megaBurst` and `slamDown` won't play on reduced-motion systems. But Framer Motion animations (opacity fades, `animate` prop) are JavaScript-driven and bypass the CSS block entirely.
**Why it happens:** Framer Motion uses WAAPI or JS-based animation, not CSS `animation:` declarations.
**How to avoid:** Import `useReducedMotion` from `framer-motion` in `ResultsPhase.tsx`. When true: skip stagger delays (all cards reveal simultaneously), don't render `MegaParticles`, keep opacity fade-in variants. This is explicitly called out in the context decisions.

### Pitfall 6: Reveal Button Morph Race Condition
**What goes wrong:** If the user double-taps the reveal button before the 300ms anticipation delay completes, `handleReveal` fires twice, triggering the stagger twice.
**Why it happens:** `revealPhase` state update is async; the button may still be visible for one render cycle.
**How to avoid:** Gate the button with `disabled={revealPhase !== 'idle'}` and remove it from the DOM entirely once `revealPhase === 'anticipation'`.

## Code Examples

Verified patterns from existing codebase:

### Existing Stagger Pattern (from EvaluationPhase initial card renders)
```typescript
// Source: EV-readrank/src/components/ResultsPhase.tsx (current, lines 78-81)
// Existing stagger: delay: index * 0.08, cubic-bezier [0.22, 1, 0.36, 1]
initial={{ opacity: 0, y: 24 }}
animate={{ opacity: 1, y: 0 }}
transition={{ delay: index * 0.08, duration: 0.5, ease: [0.22, 1, 0.36, 1] }}

// New reveal stagger: index * 0.2 (200ms gaps per context decision)
transition={{ delay: revealPhase === 'revealing' ? index * 0.2 : 0, duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
```

### MegaParticles Component (from MatchCard.tsx, lines 20-64)
```typescript
// Source: EV-readrank/src/components/MatchCard.tsx
// Re-define inline in ResultsPhase.tsx — no import needed
const MegaParticles: React.FC<{ active: boolean }> = ({ active }) => {
  const particlesRef = useRef<Particle[]>([]);
  if (particlesRef.current.length === 0) {
    particlesRef.current = Array.from({ length: 16 }, (_, i) => {
      const angle = (i / 16) * 360;
      const dist = 40 + Math.random() * 70;
      return {
        dx: Math.cos((angle * Math.PI) / 180) * dist,
        dy: Math.sin((angle * Math.PI) / 180) * dist,
        size: 2 + Math.random() * 5,
        delay: Math.random() * 0.15,
        isLarge: i % 4 === 0,
      };
    });
  }
  if (!active) return null;
  return (
    <div style={{ position: 'absolute', inset: -20, pointerEvents: 'none', zIndex: 20 }}>
      {particlesRef.current.map((p, i) => (
        <div
          key={i}
          style={{
            position: 'absolute', borderRadius: '50%',
            background: p.isLarge ? 'radial-gradient(circle, #ff5740, transparent)' : '#ff5740',
            top: '50%', left: '50%',
            width: p.isLarge ? p.size * 2 : p.size, height: p.isLarge ? p.size * 2 : p.size,
            transform: 'translate(-50%, -50%)',
            animation: `megaBurst 0.8s ${p.delay}s cubic-bezier(0.25, 0.46, 0.45, 0.94) forwards`,
            ['--dx' as string]: `${p.dx}px`,
            ['--dy' as string]: `${p.dy}px`,
          }}
        />
      ))}
    </div>
  );
};
```

### Coral Pulse Button (existing `.animate-gentle-pulse` class)
```css
/* Source: EV-readrank/src/index.css lines 224-231 */
/* Already defined — use this class on the reveal button */
@keyframes gentle-pulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.02); }
}
.animate-gentle-pulse { animation: gentle-pulse 2s ease-in-out infinite; }
```

### SlamDown Identity Section
```typescript
// Source: EV-readrank/src/index.css lines 265-269 + MatchCard.tsx line 126
// Use animation: 'slamDown 0.4s cubic-bezier(0.22, 1, 0.36, 1) forwards' on identity wrapper
// Wrap the revealed identity section in:
<div style={{ animation: 'slamDown 0.4s cubic-bezier(0.22, 1, 0.36, 1) forwards' }}>
  {/* photo + name + office */}
</div>
// Note: slamDown uses translateX(-50%) which assumes a centered absolute element.
// For a block-level identity section, use a modified keyframe or Framer Motion instead:
// initial={{ opacity: 0, scaleY: 0, originY: 0 }} animate={{ opacity: 1, scaleY: 1 }}
```

### useReducedMotion Gate
```typescript
// Source: framer-motion docs (HIGH confidence — in installed package)
import { useReducedMotion } from 'framer-motion';

const prefersReducedMotion = useReducedMotion();

// In MegaParticles render:
if (!active || prefersReducedMotion) return null;

// In stagger delay:
transition={{ delay: prefersReducedMotion ? 0 : index * 0.2 }}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Fraunces serif for headings + quote text | Manrope everywhere (this phase) | Phase 91 | Unified sans-serif system; drops editorial aesthetic in favor of functional Linear-style |
| Two CTAs per result card (View Alignment + Essentials) | Single CTA: View on Essentials | Phase 91 | Cleaner card hierarchy; CandidateAlignmentPage accessible via direct URL only |
| Candidate identity shown immediately on results render | Identity gated behind reveal moment | Phase 91 | Payoff moment for the evaluation flow |
| Sidebar always visible during matchup on desktop | Sidebar hidden during matchup | Phase 91 | Full-width breathing room for matchup cards |

**Deprecated/outdated in this phase:**
- `Fraunces` font: removed from Google Fonts `@import` and all usages in `index.css` + component inline styles
- `onViewAlignment` prop and handler in `ResultsPhase.tsx`: removed with the "View Alignment" button
- `.ev-heading` CSS class with Fraunces: updated to Manrope bold

## Open Questions

1. **`slamDown` keyframe uses `translateX(-50%)` — incompatible with block identity section**
   - What we know: The keyframe was designed for an absolutely-positioned centered element (the "CHOSEN" badge in MatchCard). A block-level identity section expanding into a card doesn't need horizontal centering.
   - What's unclear: Whether to adapt the keyframe or use Framer Motion for the identity section entrance.
   - Recommendation: Use Framer Motion `initial={{ opacity: 0, height: 0, scaleY: 0 }} animate={{ opacity: 1, height: 'auto', scaleY: 1 }}` for the identity section expansion. It's more natural for a content block and avoids keyframe specificity conflicts. Keep `slamDown` for the "CHOSEN"-style badge overlay if one is desired.

2. **End-of-evaluation animated transition — complexity of `RankedListSidebar` in full-width mode**
   - What we know: `RankedListSidebar` (exports `RankedListSidebar` from `AgreedQuotesSidebar.tsx`) is designed for sidebar width. Its internal CSS may use fixed widths.
   - What's unclear: Whether it renders correctly at 100% width without changes.
   - Recommendation: Read `AgreedQuotesSidebar.tsx` during planning to confirm. If it uses `.agreed-quotes-sidebar` class which has no fixed width, it will adapt. Otherwise, add a `fullWidth?: boolean` prop.

3. **Page transitions — `EvaluationPhase` contains split layout with fixed sidebar width**
   - What we know: The "Evaluation to Results: cards stay, chrome fades" transition is complex — it implies the result cards visually continue from evaluation cards. This is an illusion that requires careful coordination.
   - What's unclear: Whether the user actually wants a true shared-element transition (hard) or just a directional fade that creates a continuation feel (easy).
   - Recommendation: Implement the simpler directional fade (results header slides down while evaluation content fades out). A true shared-element FLIP transition would require significant structural changes and is out of scope for this phase's timeline.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None detected — no test config or test files found in EV-readrank |
| Config file | None — Wave 0 gap |
| Quick run command | `npm run build` (TypeScript compile as proxy for correctness) |
| Full suite command | `npm run build && npm run lint` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RSLT-01 | Result cards show only quote + verdict pre-reveal; single CTA post-reveal | manual-only | Visual browser verification | N/A |
| RSLT-02 | Staggered reveal animation fires on button press | manual-only | Visual browser verification | N/A |
| RSLT-03 | "View on Essentials" is the only button per card | manual-only | Visual browser verification; TypeScript build confirms `onViewAlignment` prop removed | ❌ Wave 0 |
| RSLT-04 | CandidateAlignmentPage renders with Manrope only | manual-only | Visual browser verification; grep for Fraunces in components | N/A |
| CHRM-04 | No Fraunces references in rendered components | automated | `grep -r "Fraunces" EV-readrank/src/components/ --include="*.tsx"` exits 0 | N/A |

### Sampling Rate
- **Per task commit:** `npm run build` in `EV-readrank/` — TypeScript compile confirms no type errors
- **Per wave merge:** `npm run build && npm run lint`
- **Phase gate:** All builds green + manual browser verification of reveal animation + Fraunces grep clean before `/gsd:verify-work`

### Wave 0 Gaps
- No formal test framework in EV-readrank — this is a UI-animation phase where visual verification is the primary validation method. TypeScript compilation (`npm run build`) serves as the automated correctness proxy.
- [ ] Fraunces audit script: `grep -r "Fraunces" /Users/chrisandrews/Documents/GitHub/EV-readrank/src/ --include="*.tsx" --include="*.css"` — run at phase gate to confirm complete removal

*(No test framework installation recommended — UI animation testing with existing tooling would require Playwright or similar; not justified for this phase's scope)*

## Sources

### Primary (HIGH confidence)
- Direct code read: `EV-readrank/src/components/ResultsPhase.tsx` — current state of results component, existing animation patterns
- Direct code read: `EV-readrank/src/components/MatchCard.tsx` — `MegaParticles` implementation, `slamDown` usage
- Direct code read: `EV-readrank/src/index.css` — all keyframe definitions, existing CSS classes, design tokens
- Direct code read: `EV-readrank/src/components/EvaluationPhase.tsx` — split layout structure, matchup mode flag, completion logic
- Direct code read: `EV-readrank/src/components/MatchupPhase.tsx` — sidebar interaction context
- Direct code read: `EV-readrank/src/components/PhaseContainer.tsx` — phase switch structure for transitions
- Direct code read: `EV-readrank/src/components/CandidateAlignmentPage.tsx` — typography/color usage to polish
- Direct code read: `EV-readrank/package.json` — framer-motion ^12.23.26, react ^19.2.0

### Secondary (MEDIUM confidence)
- `.planning/phases/91-results-polish-visual-redesign/91-CONTEXT.md` — locked decisions and implementation specifics
- Framer Motion `useReducedMotion` API — well-established hook, stable across v11/v12; verified present in framer-motion package at this version

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already installed, versions confirmed from package.json
- Architecture: HIGH — patterns extrapolated directly from existing code in the same files being modified
- Pitfalls: HIGH — derived from direct reading of keyframe definitions and component structure, not speculation
- Animation timing: MEDIUM — stagger values (200ms gaps, 300ms anticipation) are locked decisions from CONTEXT.md; easing curves are Claude's discretion

**Research date:** 2026-03-15
**Valid until:** 2026-04-15 (stable dependencies; no external API surface)
