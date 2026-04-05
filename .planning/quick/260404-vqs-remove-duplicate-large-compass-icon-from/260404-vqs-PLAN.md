---
phase: quick-260404-vqs
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - essentials/src/components/IconOverlay.jsx
  - essentials/src/pages/Results.jsx
autonomous: true
must_haves:
  truths:
    - "Only one compass icon appears per politician card (the small 14px icon in the overlay strip)"
    - "Clicking the small compass icon opens the CompassPreview popover anchored to that icon"
    - "Cards without stances show no compass icon at all"
  artifacts:
    - path: "essentials/src/components/IconOverlay.jsx"
      provides: "Clickable compass icon with onCompassClick prop"
    - path: "essentials/src/pages/Results.jsx"
      provides: "onCompassClick wired to IconOverlay instead of PoliticianCard"
  key_links:
    - from: "essentials/src/pages/Results.jsx"
      to: "essentials/src/components/IconOverlay.jsx"
      via: "onCompassClick prop"
      pattern: "onCompassClick"
---

<objective>
Remove the duplicate large teal compass button from politician cards, keeping only the small 14px compass icon in the IconOverlay strip. Make the small icon clickable to open the CompassPreview popover.

Purpose: Eliminate visual clutter — two compass icons on every card with stances is confusing.
Output: Single compass icon per card that opens the compass preview on click.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@essentials/src/components/IconOverlay.jsx
@essentials/src/pages/Results.jsx
@ev-ui/src/PoliticianCard.jsx (reference only — do NOT modify)

<interfaces>
From essentials/src/components/IconOverlay.jsx:
```jsx
// Current signature — no onClick support
function IconWithTooltip({ IconComponent, color, tooltip, size = 14, extraProps = {} })

// Current signature — no onCompassClick
export default function IconOverlay({ ballot, hasStances, branch })
```

From essentials/src/pages/Results.jsx (lines 715-726):
```jsx
// Current: onCompassClick passed to PoliticianCard (renders large button)
onCompassClick={hasStances ? () => {
  const cardEl = document.querySelector(`[data-pol-id="${pol.id}"] .ev-compass-button`);
  setPreviewPol({
    id: pol.id,
    name: `${pol.first_name} ${pol.last_name}`,
    shortTitle: formatLegendName(pol),
    anchorEl: cardEl,
  });
} : undefined}

// IconOverlay rendered separately — small compass icon not clickable
<IconOverlay ballot={ballot} hasStances={hasStances} branch={branch} />
```

CompassPreview expects `anchorRef={{ current: domElement }}` for popover positioning.
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add onClick support to IconOverlay compass icon</name>
  <files>essentials/src/components/IconOverlay.jsx</files>
  <action>
1. Add `onClick` prop to `IconWithTooltip` component. When provided, add `onClick` handler and `cursor: pointer` style to the wrapping `<span>`. The click handler should call `onClick` with the event, allowing the caller to use `e.currentTarget` as a positioning anchor.

2. Add `onCompassClick` prop to the `IconOverlay` component. Update the JSDoc `@param` block to include it.

3. In the compass `IconWithTooltip` instance (the one rendering `CompassIcon`), pass `onClick={onCompassClick}` so clicking the small compass icon triggers the callback.

Key details:
- The `onClick` on the `<span>` must call `e.stopPropagation()` before invoking the callback, so the card's own onClick (navigation) does not also fire.
- Pass the event object to the callback: `onClick={(e) => { e.stopPropagation(); onClickProp(e); }}`
- Only add `cursor: pointer` to the span style when `onClick` is provided.
- Do NOT change any other IconWithTooltip instances (ballot, branch) — only compass gets click behavior.
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub/essentials && npx eslint src/components/IconOverlay.jsx --no-error-on-unmatched-pattern 2>/dev/null; echo "exit: $?"</automated>
  </verify>
  <done>IconOverlay accepts onCompassClick prop; clicking the small compass icon calls it with the click event; click does not bubble to card.</done>
</task>

<task type="auto">
  <name>Task 2: Wire compass click from IconOverlay and remove large button</name>
  <files>essentials/src/pages/Results.jsx</files>
  <action>
1. In the `renderPoliticianCard` function (around line 715), REMOVE the `onCompassClick` prop from the `PoliticianCard` component entirely. This eliminates the large teal compass button.

2. Update the `IconOverlay` invocation (around line 726) to pass the compass click handler:
```jsx
<IconOverlay
  ballot={ballot}
  hasStances={hasStances}
  branch={branch}
  onCompassClick={hasStances ? (e) => {
    setPreviewPol({
      id: pol.id,
      name: `${pol.first_name} ${pol.last_name}`,
      shortTitle: formatLegendName(pol),
      anchorEl: e.currentTarget,
    });
  } : undefined}
/>
```

Key differences from the old handler:
- Use `e.currentTarget` (the small icon span) as `anchorEl` instead of querying the DOM for `.ev-compass-button`.
- No more `document.querySelector` call — cleaner and more reliable.
- The `hasStances` guard remains so the prop is only passed when stances exist.

3. Do NOT modify any other part of Results.jsx. The `previewPol` state, `CompassPreview` rendering, and all other logic stays the same.
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub/essentials && npm run build 2>&1 | tail -5</automated>
  </verify>
  <done>PoliticianCard no longer receives onCompassClick (no large compass button). IconOverlay receives the handler. Build succeeds with no errors.</done>
</task>

</tasks>

<verification>
1. `cd essentials && npm run build` completes without errors
2. Visual check: politician cards with stances show only ONE small compass icon in the bottom-right overlay strip
3. Clicking the small compass icon opens the CompassPreview popover positioned near the icon
4. Clicking elsewhere on the card still navigates to the profile page (click does not conflict)
5. Cards without stances show no compass icon at all
</verification>

<success_criteria>
- Zero duplicate compass icons on any politician card
- CompassPreview popover still works via the small icon click
- Build passes cleanly
</success_criteria>

<output>
After completion, create `.planning/quick/260404-vqs-remove-duplicate-large-compass-icon-from/260404-vqs-SUMMARY.md`
</output>
