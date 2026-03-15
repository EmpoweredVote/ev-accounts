# Phase 89: Coach Marks - Research

**Researched:** 2026-03-15
**Domain:** React coach mark / spotlight overlay, Zustand persist migration, ref-based DOM targeting
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Tour sequence & content**
- 2-step tour: Step 1 spotlights the swipe card area, Step 2 spotlights the rank panel (sidebar on desktop, inline bottom sheet on mobile)
- Step 1 uses interactive spotlight (allowSpotlightInteraction) — user can swipe the card while it's spotlighted
- Step 1 auto-advances to step 2 when the user performs their first swipe (agree or disagree) — no explicit "Next" button needed
- Step 2 is deferred until the user first agrees with a quote and the rank panel becomes visible — if they disagree first, step 2 waits
- Step 2 requires explicit "Got it" button click to dismiss (standard tour pattern)
- Tooltip text is concise and action-oriented: e.g., "Swipe right to agree, left to disagree" / "Pick the stronger quote when matchups appear"
- Same tooltip text on both mobile and desktop — the spotlight target adapts, not the messaging

**Trigger timing**
- Tour starts ~500ms after EvaluationPhase mounts and the first QuoteCard is visible on the first real issue
- Only fires on the first real issue after practice round completion (not during practice)

**Mobile vs desktop targets**
- Step 1: Same target on both viewports — the QuoteCard / swipe area
- Step 2 desktop: Spotlight the AgreedQuotesSidebar
- Step 2 mobile: Spotlight the InlineRankPanel bottom sheet when it appears after 2nd agree

**Dismissal mechanism**
- `coachMarksCompleted: boolean` flag in Zustand store, persisted via Zustand persist
- Store version bump to v6 with migration: existing users (version > 0) get `coachMarksCompleted: true`, new users get `false`
- Any dismissal action (complete tour, Skip All, Escape, tap outside) sets `coachMarksCompleted: true` permanently — no partial resume, no retry
- Matches the `practiceCompleted` pattern established in Phase 88

### Claude's Discretion
- Exact tooltip wording for each step
- CoachMark TypeScript port details (adapting JSX → TSX from CompassV2)
- Animation timing and delay values
- Whether step 2 spotlight targets the full sidebar/panel or just the header area
- How to detect "first swipe" to auto-advance step 1

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| ONBD-05 | Coach marks spotlight key UI elements on first real issue (swipe area, rank panel) | CoachMark component ported to TSX provides SVG mask spotlight; refs added to QuoteCard and rank panel components; EvaluationPhase manages 2-step tour state |
| ONBD-06 | Coach marks permanently dismissed after first completion via store flag | `coachMarksCompleted` boolean added to Zustand store at v6; migration sets true for existing users; any dismiss action sets true; survives page reload via persist |
</phase_requirements>

---

## Summary

Phase 89 adds a 2-step, one-time coach mark tour to EV-readrank. The tour fires on the first real issue (after practice) and spotlights (1) the QuoteCard swipe area, then (2) the rank panel once the user has agreed with at least one quote. Permanent dismissal is persisted in the Zustand store via a `coachMarksCompleted` flag, mirroring the `practiceCompleted` pattern from Phase 88.

The implementation is self-contained: the `CoachMark` JSX component in `CompassV2/src/components/CoachMark.jsx` is the source of truth and needs a TypeScript port directly into `EV-readrank/src/components/CoachMark.tsx`. The component is fully-featured (SVG mask spotlight, 4-rect interactive mode, ResizeObserver tracking, auto-positioning, Framer Motion AnimatePresence, Escape key handling, createPortal). No external library is needed beyond what the project already uses.

State management is straightforward: bump store to v6 with a migration that sets `coachMarksCompleted: true` for any user with a prior version (version > 0 check, matching Phase 88 pattern). Tour step state (which step is showing) lives in local `useState` inside `EvaluationPhase` — it is ephemeral UI state, not persisted.

**Primary recommendation:** Port `CoachMark.jsx` to `CoachMark.tsx` preserving all existing logic, add `coachMarksCompleted` to the store at v6, add `forwardRef` to `QuoteCard`/`RankedListSidebar`/`InlineRankPanel`, and wire 2-step tour logic in `EvaluationPhase`.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| framer-motion | Already installed | AnimatePresence for coach mark enter/exit, backdrop fade | Already used throughout app; CoachMark source already uses it |
| zustand + persist | Already installed (v5 store) | Persist `coachMarksCompleted` flag across sessions | Established pattern for practiceCompleted in Phase 88 |
| React createPortal | Built-in (React 19) | Render coach mark overlay above all content at z-index 60+ | Used in source CoachMark.jsx |
| ResizeObserver | Browser API | Track spotlight target element size changes | Used in source CoachMark.jsx |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| React.forwardRef | Built-in | Expose DOM ref from QuoteCard, RankedListSidebar, InlineRankPanel | Required for spotlight targeting from parent (EvaluationPhase) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual port of CoachMark.jsx | shepherd.js / driver.js / react-joyride | External libraries add bundle weight and conflict with custom spotlight interaction pattern; manual port is ~435 lines and already battle-tested |
| Zustand persist flag | localStorage direct (useCoachMark hook pattern from source) | The `useCoachMark` hook in source uses localStorage directly, but CONTEXT.md locks Zustand persist to match `practiceCompleted` — do not use the hook approach |

**Installation:**
No new packages required. All dependencies (framer-motion, zustand) are already installed.

---

## Architecture Patterns

### Recommended Project Structure
```
EV-readrank/src/
├── components/
│   ├── CoachMark.tsx          # NEW — TypeScript port of CompassV2/src/components/CoachMark.jsx
│   ├── EvaluationPhase.tsx    # MODIFIED — tour step state, ref passing, trigger logic
│   ├── QuoteCard.tsx          # MODIFIED — forwardRef to expose DOM ref for step 1 target
│   ├── AgreedQuotesSidebar.tsx # MODIFIED — forwardRef on RankedListSidebar for step 2 desktop
│   └── InlineRankPanel.tsx    # MODIFIED — forwardRef on InlineRankPanel for step 2 mobile
├── store/
│   └── useReadRankStore.ts    # MODIFIED — v6 migration, coachMarksCompleted field + action
```

### Pattern 1: Store v6 Migration (mirrors Phase 88 v5 pattern)

**What:** Bump persist version to 6, add `coachMarksCompleted: boolean` to state. Migration uses `version > 0` to detect existing users and set flag true so they skip the tour.

**When to use:** Any time a new permanent-dismissal flag is added to the store.

```typescript
// Source: EV-readrank/src/store/useReadRankStore.ts (current v5 pattern)
{
  name: 'ev_readrank',
  version: 6,  // bumped from 5
  migrate: (_persistedState, version) => {
    const isUpgrade = version > 0;
    return {
      phase: 'hub' as Phase,
      currentIssueId: null as string | null,
      issueProgress: {} as Record<string, IssueProgress>,
      practiceCompleted: isUpgrade,
      practiceProgress: null as PracticeProgress | null,
      coachMarksCompleted: isUpgrade,  // existing users skip coach marks
    };
  },
  partialize: (state) => ({
    // ... existing fields ...
    coachMarksCompleted: state.coachMarksCompleted,
  }),
}
```

### Pattern 2: forwardRef to expose DOM ref for spotlight targeting

**What:** `QuoteCard`, `RankedListSidebar`, and `InlineRankPanel` need to expose their root DOM element so `EvaluationPhase` can pass refs to `CoachMark`.

**When to use:** When a parent needs to spotlight a child component's DOM node.

```typescript
// Source: React docs — forwardRef pattern
export const QuoteCard = React.forwardRef<HTMLDivElement, QuoteCardProps>(
  (props, ref) => {
    return (
      <motion.div ref={ref} /* ... existing props ... */>
        {/* existing content */}
      </motion.div>
    );
  }
);
QuoteCard.displayName = 'QuoteCard';
```

Note: Framer Motion's `motion.div` accepts `ref` — no special handling needed.

### Pattern 3: 2-step tour state in EvaluationPhase (local useState)

**What:** Tour step is ephemeral UI state — it lives in `EvaluationPhase` local state, not in the store. The store only holds the permanent `coachMarksCompleted` flag.

**When to use:** UI state that resets on unmount and doesn't need to survive reload.

```typescript
// Source: EV-readrank/src/components/EvaluationPhase.tsx (to be added)
const [tourStep, setTourStep] = useState<1 | 2 | null>(null);
const quoteCardRef = useRef<HTMLDivElement>(null);
const sidebarRef = useRef<HTMLDivElement>(null);  // desktop
const inlinePanelRef = useRef<HTMLDivElement>(null);  // mobile

const { coachMarksCompleted, completeCoachMarks } = useReadRankStore();

// Trigger tour ~500ms after mount on first real issue
useEffect(() => {
  if (coachMarksCompleted) return;
  const timer = setTimeout(() => setTourStep(1), 500);
  return () => clearTimeout(timer);
}, []); // run once on mount
```

### Pattern 4: Step 1 auto-advance on first swipe

**What:** Step 1 has `allowSpotlightInteraction=true` so the user can actually swipe. The agree/disagree actions need to notify the tour to advance. The cleanest approach: wrap `agreeWithQuote`/`disagreeWithQuote` calls in EvaluationPhase to also advance the tour step.

**When to use:** When the tutorial teaches by doing rather than by reading.

```typescript
// Source: EV-readrank/src/components/EvaluationPhase.tsx (pattern to add)
const handleAgreeWithTour = useCallback((quote: Quote) => {
  agreeWithQuote(quote);
  if (tourStep === 1) {
    // Step 2 deferred: only show when rank panel becomes visible (1+ agreed)
    setTourStep(2);
  }
}, [agreeWithQuote, tourStep]);

const handleDisagreeWithTour = useCallback((quote: Quote) => {
  disagreeWithQuote(quote);
  if (tourStep === 1) {
    // User disagreed — advance step tracker but step 2 waits for first agree
    setTourStep(2);
  }
}, [disagreeWithQuote, tourStep]);
```

Step 2 only renders when `tourStep === 2 && rankedQuotes.length >= 1` — naturally defers until first agree.

### Pattern 5: CoachMark TSX port

**What:** Direct TypeScript port of `CompassV2/src/components/CoachMark.jsx`. The component API and all internal logic are preserved — only JSX→TSX type annotations are added.

**Key TypeScript additions needed:**
- `targetRef: React.RefObject<HTMLDivElement>` prop type
- `allowSpotlightInteraction?: boolean` prop type (already in source JSX)
- Interface for `CoachMarkProps`
- Type annotations on `calcTooltipPosition` return type and `buildClipPath` rect
- Remove `useCoachMark` export (not used in this integration — Zustand replaces it)

**Note on `useCoachMark` hook:** The source exports a `useCoachMark` hook that uses `localStorage` directly. Per CONTEXT.md locked decision, dismissal is via Zustand persist — do NOT use `useCoachMark`. Export it as a dead export or omit it.

### Anti-Patterns to Avoid
- **Using `useCoachMark` hook from source:** The hook uses raw localStorage — locked decision requires Zustand persist instead
- **Storing tourStep in Zustand:** Tour step is ephemeral UI state; only the final `coachMarksCompleted` flag belongs in the store
- **Rendering CoachMark inside QuoteCard or sidebar:** CoachMark uses `createPortal` to body — it must be rendered from EvaluationPhase (or higher), not from within the spotlighted component
- **Targeting the container div instead of the motion.div root:** `getBoundingClientRect()` needs the actual visible card root, not a wrapper — forwardRef must land on the `motion.div` in QuoteCard
- **Step 2 rendering before first agree:** Guard `tourStep === 2` rendering with `rankedQuotes.length >= 1` to avoid spotlighting an empty sidebar

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Spotlight overlay with cutout | Custom CSS clip-path or canvas overlay | CoachMark.tsx (port of existing component) | SVG mask + 4-rect interactive mode already handles all edge cases; border-radius, padding, ResizeObserver tracking included |
| Tooltip auto-positioning | Manual position calculation | `calcTooltipPosition` in CoachMark.tsx | Already handles all 4 fallback directions (below → above → right → left) with viewport margin clamping |
| Backdrop that allows interaction in cutout | Single semi-transparent div | 4-rect `allowSpotlightInteraction` mode in CoachMark.tsx | Single div with pointer-events blocks all input; 4-rect mode leaves spotlight area completely uncovered |
| Persist dismissal flag | Custom useEffect + localStorage | Zustand persist (already in store) | Keeps persistence layer unified; survives hydration race conditions that raw localStorage reads can have |

**Key insight:** The CoachMark source is production-quality. Do not rebuild any part of it — port it as-is and add types.

---

## Common Pitfalls

### Pitfall 1: forwardRef on a motion.div inside a wrapper
**What goes wrong:** Developer adds `ref` to the outer container `<div>` in QuoteCard, but the outer div has padding/margin that makes the spotlight rect larger than the visible card.
**Why it happens:** Misidentifying which DOM element represents the "visible spotlight target."
**How to avoid:** Forward the ref directly to the `motion.div` that has the `ev-quote-card` className — that is the visually bounded element.
**Warning signs:** Spotlight appears larger than the card or offset from it.

### Pitfall 2: Step 2 fires before rank panel is mounted
**What goes wrong:** `setTourStep(2)` fires immediately on first swipe, but if the user disagreed, `rankedQuotes.length === 0`, the sidebar is in empty-state, and the spotlight targets an empty placeholder.
**Why it happens:** Tour step advancement is decoupled from the rank panel's visible state.
**How to avoid:** Guard the step 2 CoachMark render: `tourStep === 2 && rankedQuotes.length >= 1`. This means step 2 is set early but only renders when there's something to spotlight.
**Warning signs:** CoachMark tooltip appears pointing at "Agree with quotes to begin forging your ranking" placeholder text.

### Pitfall 3: ResizeObserver fires before ref is attached
**What goes wrong:** CoachMark mounts with `show={true}` but `targetRef.current` is null because the forwardRef hasn't rendered yet.
**Why it happens:** React renders children before effects run; if CoachMark is rendered conditionally, the ref target may not exist yet.
**How to avoid:** The 500ms delay before `setTourStep(1)` handles this. The existing `measureTarget` guard (`if (!targetRef?.current) return`) is the safety net.
**Warning signs:** Spotlight doesn't appear despite `show={true}`.

### Pitfall 4: Escape key conflict with CoachMark and QuoteCard
**What goes wrong:** Escape key listener in CoachMark calls `onSkipAll`, but EvaluationPhase or QuoteCard might also listen for Escape.
**Why it happens:** Multiple `document.addEventListener('keydown')` handlers.
**How to avoid:** CoachMark's Escape handler only fires when `show === true`. EvaluationPhase doesn't currently have an Escape listener. No conflict expected, but verify during implementation.
**Warning signs:** Single Escape press skips both coach mark AND something else.

### Pitfall 5: Store migrate wipes issueProgress for brand-new v6 users
**What goes wrong:** The v6 `migrate` function returns a hardcoded initial state that resets `issueProgress` to `{}`, wiping any progress the user had.
**Why it happens:** This is intentional — the established pattern from Phase 86 and 88 is that migrations reset to clean state. The `version > 0` check preserves `coachMarksCompleted: true` for existing users but still resets their session.
**How to avoid:** This is correct behavior — confirm with the established pattern: "migrate() returns hardcoded initial state regardless of version." Do not try to preserve issueProgress across migration.
**Warning signs:** Confusion if you expect migration to preserve session data — it does not.

### Pitfall 6: InlineRankPanel bottom sheet is conditionally rendered (mobile)
**What goes wrong:** `inlinePanelRef` is null when step 2 tries to spotlight it on mobile because the panel only renders when `showFullRankList === true`.
**Why it happens:** `InlineRankPanel` is rendered only when the user taps the rank counter pill.
**How to avoid:** On mobile, step 2 must wait until `showFullRankList === true` AND `rankedQuotes.length >= 1`. Consider auto-opening the panel when step 2 activates on mobile, or use `sidebarRef` for both viewports if the counter pill itself is a viable spotlight target.
**Warning signs:** `inlinePanelRef.current === null` when step 2 renders on mobile.

---

## Code Examples

Verified patterns from the actual source code:

### CoachMark component API (from CompassV2/src/components/CoachMark.jsx)
```typescript
// Tour mode (Next + Skip All buttons):
<CoachMark
  targetRef={quoteCardRef}
  show={tourStep === 1}
  allowSpotlightInteraction={true}
  stepLabel="1 of 2"
  onNext={() => {}}  // no Next button needed — auto-advances on swipe
  onSkipAll={handleSkipTour}
>
  Swipe right to agree, left to disagree
</CoachMark>

// Single hint mode (Got it button):
<CoachMark
  targetRef={sidebarRef}
  show={tourStep === 2 && rankedQuotes.length >= 1}
  allowSpotlightInteraction={false}
  stepLabel="2 of 2"
  onDismiss={handleCompleteTour}
>
  Your agreed quotes rank here. Pick the stronger quote when matchups appear.
</CoachMark>
```

### Store v6 interface additions (from useReadRankStore.ts patterns)
```typescript
// In ReadRankState interface:
coachMarksCompleted: boolean;
completeCoachMarks: () => void;

// In initialState:
coachMarksCompleted: false,

// In store actions:
completeCoachMarks: () => set({ coachMarksCompleted: true }),

// In partialize:
coachMarksCompleted: state.coachMarksCompleted,

// In migrate (version 6):
const isUpgrade = version > 0;
return {
  phase: 'hub' as Phase,
  currentIssueId: null as string | null,
  issueProgress: {} as Record<string, IssueProgress>,
  practiceCompleted: isUpgrade,
  practiceProgress: null as PracticeProgress | null,
  coachMarksCompleted: isUpgrade,
};
```

### forwardRef pattern for QuoteCard (from React docs + current QuoteCard.tsx)
```typescript
// QuoteCard.tsx — add forwardRef
export const QuoteCard = React.forwardRef<HTMLDivElement, QuoteCardProps>(
  ({ quote, isStacked = false, ... }, ref) => {
    return (
      <motion.div
        ref={ref}  // forward to motion.div root
        drag={isDraggable && !isCurrentlyAnimating}
        // ... rest of existing props unchanged
        className="ev-quote-card w-full max-w-lg ..."
      >
        {/* existing content unchanged */}
      </motion.div>
    );
  }
);
QuoteCard.displayName = 'QuoteCard';
```

### Tour trigger in EvaluationPhase (pattern from PhaseContainer practiceCompleted)
```typescript
// EvaluationPhase.tsx additions:
const { coachMarksCompleted, completeCoachMarks } = useReadRankStore();
const [tourStep, setTourStep] = useState<1 | 2 | null>(null);
const quoteCardRef = useRef<HTMLDivElement>(null);
const sidebarRef = useRef<HTMLDivElement>(null);

useEffect(() => {
  if (coachMarksCompleted) return;
  const timer = setTimeout(() => setTourStep(1), 500);
  return () => clearTimeout(timer);
}, []); // run once on mount

const handleSkipTour = useCallback(() => {
  setTourStep(null);
  completeCoachMarks();
}, [completeCoachMarks]);

const handleCompleteTour = useCallback(() => {
  setTourStep(null);
  completeCoachMarks();
}, [completeCoachMarks]);
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| useCoachMark localStorage hook (CompassV2) | Zustand persist flag (EV-readrank) | Phase 89 design decision | Single persistence layer; no dual-source-of-truth between localStorage key and Zustand store |
| Step 2 on explicit "Next" button | Step 2 deferred until first agree + auto-advance from step 1 on swipe | Phase 89 design decision | Learn-by-doing; no "Next" button cluttering step 1 |

**Deprecated/outdated:**
- `useCoachMark` hook export: The localStorage-based hook from CompassV2 is not used in this integration. The TSX port can omit it or include it as an unused export.

---

## Open Questions

1. **Step 2 mobile target: InlineRankPanel vs counter pill**
   - What we know: `InlineRankPanel` only renders when `showFullRankList === true` (user taps counter pill). The counter pill itself is always visible when `rankedQuotes.length > 0`.
   - What's unclear: Should step 2 auto-open the InlineRankPanel on mobile, or spotlight the counter pill instead, or spotlight the AgreedQuotesSidebar-equivalent on mobile?
   - Recommendation: Auto-open `showFullRankList` when `tourStep === 2` activates on mobile (call `setShowFullRankList(true)` alongside `setTourStep(2)`). This guarantees the `inlinePanelRef` is mounted before CoachMark tries to measure it. Alternatively, use the counter pill as the step 2 mobile target — simpler and always present.

2. **Step 1 "Next" button: omit entirely or keep as fallback**
   - What we know: CONTEXT.md says step 1 auto-advances on swipe — no explicit "Next" button needed.
   - What's unclear: What if the user doesn't swipe (e.g., uses keyboard agree/disagree buttons on desktop)? The `handleButtonSwipe` path in EvaluationPhase also calls agree/disagree — it should also advance the tour.
   - Recommendation: Wire tour advancement into both `QuoteCard` swipe callbacks AND the `handleButtonSwipe` path in EvaluationPhase. Include a "Skip" (not "Next") button in step 1 tooltip as the only explicit escape — handled by `onSkipAll`.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None detected in EV-readrank |
| Config file | None — Wave 0 gap |
| Quick run command | N/A until framework installed |
| Full suite command | N/A until framework installed |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ONBD-05 | Coach marks appear on first real issue (swipe area spotlighted at step 1, rank panel at step 2) | manual-only | N/A — requires visual DOM + interaction | ❌ Wave 0 |
| ONBD-05 | Coach marks do NOT appear during practice round | unit | N/A — no test framework | ❌ Wave 0 |
| ONBD-06 | `coachMarksCompleted` flag set to true after any dismiss action | unit | N/A — no test framework | ❌ Wave 0 |
| ONBD-06 | Existing users (store version > 0) get `coachMarksCompleted: true` via migration | unit | N/A — no test framework | ❌ Wave 0 |
| ONBD-06 | Coach marks do not appear on page reload after completion | manual-only | N/A — requires localStorage inspection | ❌ Wave 0 |

**Note:** EV-readrank has no test framework installed. Coach mark behavior is primarily visual and interaction-based. Manual verification via browser DevTools is the practical validation path for this phase. The planner should include a manual smoke-test checklist in the verification plan rather than automated test tasks.

### Wave 0 Gaps
- No test framework installed in EV-readrank — automated testing deferred to a future milestone
- Manual verification checklist is the substitute for this phase

*(If automated tests are desired in future: Vitest + @testing-library/react would match the React 19 + Vite stack)*

---

## Sources

### Primary (HIGH confidence)
- `CompassV2/src/components/CoachMark.jsx` — Full source component inspected directly; all API details, props, rendering strategy, and edge cases confirmed by reading the file
- `EV-readrank/src/store/useReadRankStore.ts` — Current store structure, v5 migration pattern, `practiceCompleted` flag implementation confirmed by reading the file
- `EV-readrank/src/components/EvaluationPhase.tsx` — Integration points, existing ref usage, agree/disagree call sites confirmed by reading the file
- `EV-readrank/src/components/QuoteCard.tsx` — Current component structure confirms no forwardRef yet; `motion.div` root is correct ref target
- `EV-readrank/src/components/AgreedQuotesSidebar.tsx` — `RankedListSidebar` export confirmed; no forwardRef yet
- `EV-readrank/src/components/InlineRankPanel.tsx` — Conditional rendering confirmed; `showFullRankList` gate identified as mobile pitfall
- `.planning/phases/89-coach-marks/89-CONTEXT.md` — All locked decisions and discretion areas

### Secondary (MEDIUM confidence)
- React 19 `forwardRef` + Framer Motion `motion.div` ref compatibility — standard React pattern; Framer Motion docs confirm `motion.div` accepts `ref` prop natively

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already in project; no new installs required
- Architecture: HIGH — source component read directly; all patterns derived from actual code
- Pitfalls: HIGH — pitfalls identified from actual conditional rendering logic in InlineRankPanel and existing store migration patterns
- Open questions: MEDIUM — mobile step 2 target is the one genuinely ambiguous area

**Research date:** 2026-03-15
**Valid until:** 2026-04-15 (stable codebase; no rapidly changing dependencies)
