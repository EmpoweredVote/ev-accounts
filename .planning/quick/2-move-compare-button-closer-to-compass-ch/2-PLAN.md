---
phase: quick-2
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - CompassV2/src/pages/Compass.jsx
autonomous: false
requirements: [QUICK-2]
must_haves:
  truths:
    - "Compare button is visible directly below the radar chart without scrolling"
    - "Save prompt banner does not overlap the Compare button"
    - "Compare button placement works on both mobile and desktop layouts"
  artifacts:
    - path: "CompassV2/src/pages/Compass.jsx"
      provides: "Repositioned Compare button and save-banner-aware padding"
  key_links:
    - from: "ActionButtons"
      to: "RadarChart container"
      via: "Flex column layout positioning"
      pattern: "ActionButtons.*mt"
---

<objective>
Move the "Compare" button closer to the radar chart on the Compass page so it is visible without scrolling, and prevent the "Save your compass results" banner from overlapping it.

Purpose: The Compare button is currently too far below the chart, and the fixed-position save banner covers it entirely, making it inaccessible to guest users.
Output: Updated Compass.jsx with repositioned Compare button and bottom padding for the save banner.
</objective>

<execution_context>
@/Users/chrisandrews/.claude/get-shit-done/workflows/execute-plan.md
@/Users/chrisandrews/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@CompassV2/src/pages/Compass.jsx
@CompassV2/src/components/SavePromptModal.jsx
</context>

<tasks>

<task type="auto">
  <name>Task 1: Reposition Compare button and add save-banner padding</name>
  <files>CompassV2/src/pages/Compass.jsx</files>
  <action>
Three changes needed in Compass.jsx:

**1. Move ActionButtons closer to the chart (reduce top margin):**

In the `ActionButtons` function (line ~196-209), change:
```jsx
<div className="flex gap-4 mt-4">
```
to:
```jsx
<div className="flex gap-4 mt-1">
```
This reduces the gap between the chart and the Compare button from 16px to 4px.

**2. Add bottom padding to the main page container so the fixed save banner does not overlap content:**

On the main `<div>` at line ~593:
```jsx
<div className="px-4 py-6 flex flex-col items-center overflow-hidden">
```
Change to:
```jsx
<div className="px-4 py-6 pb-16 flex flex-col items-center overflow-hidden">
```
The `pb-16` (64px) ensures that when the save prompt banner slides up from the bottom (~52px tall), the Compare button and other bottom content remain visible and tappable above it.

**3. On mobile Graph tab (line ~694), tighten the chart max-height so the button is visible in the viewport:**

Change the chart container on mobile from:
```jsx
<div className="w-full min-h-[280px] max-h-[calc(100dvh-240px)] aspect-square mx-auto relative">
```
to:
```jsx
<div className="w-full min-h-[280px] max-h-[calc(100dvh-280px)] aspect-square mx-auto relative">
```
This reclaims 40px of vertical space on mobile, ensuring the Compare button fits within the viewport. The chart will be slightly smaller but still large enough to be fully usable.

Do NOT change the desktop chart container dimensions (the one inside the `lg:flex` layout at line ~617) -- desktop has plenty of room.
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub/CompassV2 && npm run build 2>&1 | tail -5</automated>
  </verify>
  <done>ActionButtons has mt-1 instead of mt-4, main container has pb-16, mobile chart max-height uses 280px offset instead of 240px. Build succeeds with no errors.</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 2: Verify Compare button positioning</name>
  <files>CompassV2/src/pages/Compass.jsx</files>
  <action>
Human verifies the Compare button is now positioned correctly relative to the radar chart and is not obscured by the save banner.
  </action>
  <verify>
    1. Run `cd CompassV2 && npm run dev` to start the dev server
    2. Open the Compass page in browser (ensure you have at least 3 topics answered so the chart and Compare button show)
    3. On desktop: Verify the Compare button sits close below the chart with minimal gap
    4. On mobile (use browser dev tools responsive mode, ~390px width): Switch to the "Graph" tab and verify the Compare button is visible below the chart without scrolling
    5. If not logged in, wait ~1.5 seconds for the "Save your compass results" banner to appear at the bottom -- verify it does NOT cover the Compare button
    6. Tap/click the Compare button to confirm it is still functional
  </verify>
  <done>Compare button is visible near the chart on both mobile and desktop, save banner does not overlap it, and button remains functional.</done>
</task>

</tasks>

<verification>
- `npm run build` succeeds with no errors
- Compare button visible directly below chart on both mobile and desktop
- Save prompt banner does not overlap the Compare button
</verification>

<success_criteria>
The Compare button is clearly visible and accessible near the radar chart on both mobile and desktop viewports, and the fixed-position save banner does not cover it.
</success_criteria>

<output>
After completion, create `.planning/quick/2-move-compare-button-closer-to-compass-ch/2-SUMMARY.md`
</output>
