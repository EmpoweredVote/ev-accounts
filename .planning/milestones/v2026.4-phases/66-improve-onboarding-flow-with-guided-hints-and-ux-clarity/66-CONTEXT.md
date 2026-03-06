# Phase 66: Improve Onboarding Flow with Guided Hints and UX Clarity - Context

**Gathered:** 2026-03-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Improve the Compass onboarding and post-onboarding experience through a coach mark hint system, a post-calibration guided tour, a compare deep-dive tour, welcome screen simplification, and contextual Library page guidance. This phase does NOT add new features — it makes existing features discoverable and understandable for first-time users.

</domain>

<decisions>
## Implementation Decisions

### Hint system design
- Coach marks with full-page dim overlay and spotlight cutout around the target element
- Blocks interaction with non-highlighted elements during the hint
- Hybrid sequencing: short post-calibration tour (automatic sequence), plus independent contextual hints triggered at first encounter
- Each hint tracked via individual localStorage flags (matching existing pattern: `onboarding_spokeFlip`, `onboarding_compare`, etc.)
- Hints are one-time only — dismissed permanently on click/advance

### Post-calibration guided tour (4 steps on Compass page)
- Triggers once after calibration celebration screen dismisses
- Step 1: Highlight a compass spoke — "Click any spoke to flip its direction"
- Step 2: Highlight Compare button — "See how your views line up with a politician"
- Step 3: Highlight "Back to Library" link — "Add or change topics anytime from the Library"
- Step 4: Highlight the ? help button — "Need a refresher? The walkthrough is always here"
- Replaces the existing SpokeHint component entirely — one unified system
- Next/Skip All controls on each step

### Compare deep-dive tour (triggered on first compare open)
- Triggers when user first opens the Compare modal or first selects a politician
- Steps walk through: filters, search, selecting a politician, compass overlay comparison, selecting a topic to compare, comparison in the drawer, summary section, sources section
- Final step: spoke inversion on compare page — clarify that flipping a spoke changes the visual perspective but does not change the user's actual stance
- Independent of the post-calibration tour — fires on first compare regardless of whether post-cal tour was completed or skipped

### Welcome screen simplification
- Replace the GIF with a static hero image (polished screenshot or illustration of a completed compass)
- Trim text from 4 bullet points down to 1-2 concise lines
- Keep "Get Started" and "Skip for now" buttons
- Goal: get users into the flow faster

### Write-in hint (calibration answer step)
- First question only: subtle note pointing to the "Write your own..." button to ensure users know it exists
- The existing drag hint (SortableWriteInCard pulse animation + "Drag your own view to where it fits") already handles the post-write guidance — no changes needed there
- Hint dismissed after first question

### Library page coach marks (2-step mini-tour)
- Triggers on first Library visit (regardless of calibration status)
- Step 1: Spotlight a topic card's + button — explain adding topics to compass
- Step 2: Spotlight the Full Calibration CTA banner — explain the alternative full quiz path

### Claude's Discretion
- Celebration screen timing (whether to keep 3-second auto-dismiss or switch to manual click before tour starts)
- Whether "Back to Library" link styling should be upgraded (text link → ghost button/pill) for ongoing discoverability
- Coach mark tooltip positioning/arrow direction per step
- Exact copy/wording for each hint (keeping it concise and on-brand)
- How to build the reusable CoachMark component (portal-based overlay, ref-based positioning, etc.)
- Compare tour step count and grouping (some steps could potentially be combined)

</decisions>

<specifics>
## Specific Ideas

- The compare tour should explicitly call out that spoke inversion on the compare page changes the visual view but doesn't change the user's actual stance — this is a conceptual clarity point, not just a feature pointer
- Write-in drag hint already exists (SortableWriteInCard pulse) — just need the "Write your own exists" awareness hint on the first question
- Coach marks should feel like Figma/Notion onboarding — immersive spotlight, not subtle

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SpokeHint` component (Compass.jsx:12-28): Current hint pattern — will be replaced by the new coach mark system but provides reference for positioning and dismiss logic
- `onboarding_spokeFlip` localStorage flag: Existing dismiss tracking pattern to follow
- `calibration_completed` / `calibration_skipped` flags: Used to gate when post-calibration tour fires
- `SortableWriteInCard` (CalibrationOverlay.jsx:93-171): Already has `showHint` prop with pulse animation and drag guidance text

### Established Patterns
- All onboarding state tracked via individual localStorage flags
- Dismissible UI elements use useState + localStorage.setItem pattern
- CalibrationOverlay is a full-screen fixed overlay (z-50) — coach marks will need z-60+ to layer above if used during calibration steps
- Framer Motion available in the project for animations

### Integration Points
- `Compass.jsx` onComplete callback (line 626-634): Post-calibration tour should fire after calibration_completed is set
- `CompareModal` / `ComparePanel`: Compare tour triggers on first open of either
- `Library.jsx` mount: Library coach marks trigger on first render
- `CalibrationOverlay.jsx` answer step: Write-in hint triggers on first question (currentIndex === 0)
- `Layout.jsx` help button (line 92-101): Post-cal tour Step 4 targets this element

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 66-improve-onboarding-flow-with-guided-hints-and-ux-clarity*
*Context gathered: 2026-03-05*
