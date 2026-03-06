---
phase: quick-3
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - ev-ui/src/RadarChartCore.jsx
autonomous: false
requirements:
  - QUICK-3
must_haves:
  truths:
    - "When a spoke is inverted on the compare page, the politician's blue compass polygon animates smoothly to its new shape, mirroring the user's coral polygon animation"
    - "When a new politician is selected for comparison, their compass polygon appears without an awkward fly-in animation from center"
    - "The user's coral polygon animation continues to work exactly as before"
  artifacts:
    - path: "ev-ui/src/RadarChartCore.jsx"
      provides: "Animated compare polygon using react-spring"
      contains: "animated.polygon"
  key_links:
    - from: "ev-ui/src/RadarChartCore.jsx"
      to: "@react-spring/web"
      via: "useSpring for compareSpring"
      pattern: "compareSpring.*immediate.*countChanged"
---

<objective>
Animate the politician/compare compass polygon when spokes are inverted, so it mirrors the smooth animation the user's polygon already has.

Purpose: On the compass compare page, clicking a spoke to invert it causes the user's coral polygon to animate smoothly via react-spring, but the politician's blue polygon snaps immediately to its new shape. This feels janky and inconsistent. Both polygons should animate in sync.

Output: Updated RadarChartCore.jsx in ev-ui with animated compare polygon.
</objective>

<execution_context>
@/Users/chrisandrews/.claude/get-shit-done/workflows/execute-plan.md
@/Users/chrisandrews/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@ev-ui/src/RadarChartCore.jsx
</context>

<interfaces>
<!-- Current RadarChartCore animation architecture -->

From ev-ui/src/RadarChartCore.jsx:

The user polygon uses `useSpring` to animate between point strings:
```jsx
const spring = useSpring({
  to: { points: targetPoints },
  immediate: countChanged,  // skip animation when spoke count changes
  reset: countChanged,
  config: { tension: 300, friction: 30 },
});
// Renders as <animated.polygon points={spring.points} />
```

The compare polygon has a spring defined but forced to `immediate: true` always:
```jsx
const compareSpring = useSpring({
  to: { points: comparePoints || centerPoints || `${centerX},${centerY}` },
  immediate: true,  // <-- THIS is the problem: always skips animation
  config: { tension: 300, friction: 30 },
});
// But renders as plain <polygon points={comparePoints} /> -- doesn't even use the spring
```

Key constraint: When `comparePoints` is null (no politician selected) or when a NEW politician is first loaded, the polygon should NOT animate from center-point to actual shape -- it should appear immediately. Animation should only happen when the SAME polygon's points change due to spoke inversion or answer changes.
</interfaces>

<tasks>

<task type="auto">
  <name>Task 1: Enable react-spring animation on compare polygon</name>
  <files>ev-ui/src/RadarChartCore.jsx</files>
  <action>
In `RadarChartCore.jsx`, make the compare polygon animate when spoke inversions change, matching the user polygon's behavior:

1. Track whether compareData just appeared (new politician selected) vs. existing compareData changed shape (spoke inversion). Add a ref to track whether compare data was present in the previous render:
   ```jsx
   const hadCompareDataRef = useRef(false);
   ```
   After the `hasCompareData` calculation, compute whether this is a "new entry" (compareData just appeared) vs. a "shape change" (compareData was already present and points changed):
   ```jsx
   const compareJustAppeared = hasCompareData && !hadCompareDataRef.current;
   ```
   Update the ref in a useEffect:
   ```jsx
   useEffect(() => { hadCompareDataRef.current = hasCompareData; }, [hasCompareData]);
   ```

2. Update the `compareSpring` to animate on shape changes but be immediate on new entry or spoke count changes:
   ```jsx
   const compareSpring = useSpring({
     to: { points: comparePoints || centerPoints || `${centerX},${centerY}` },
     immediate: countChanged || compareJustAppeared,
     reset: countChanged || compareJustAppeared,
     config: { tension: 300, friction: 30 },
   });
   ```

3. Replace the static compare `<polygon>` (around line 244-254) with `animated.polygon` using the spring, mirroring the user polygon pattern:
   ```jsx
   {hasCompareData && comparePoints ? (
     countChanged || compareJustAppeared ? (
       <polygon
         key="compare-static"
         points={comparePoints}
         style={{
           fill: "rgba(89, 176, 196, 0.3)",
           stroke: "rgb(89, 176, 196)",
           strokeWidth: 2,
         }}
       />
     ) : (
       <animated.polygon
         key="compare-animated"
         points={compareSpring.points}
         style={{
           fill: "rgba(89, 176, 196, 0.3)",
           stroke: "rgb(89, 176, 196)",
           strokeWidth: 2,
         }}
       />
     )
   ) : null}
   ```

This ensures:
- Spoke inversion: compare polygon animates smoothly (same spring config as user polygon)
- New politician loaded: compare polygon appears immediately (no fly-in from center)
- Spoke count change (topic added/removed): both polygons update immediately (no animation)
- Existing user polygon animation is completely unchanged
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub/ev-ui && npm run build</automated>
  </verify>
  <done>The ev-ui build succeeds. RadarChartCore uses animated.polygon for the compare polygon with react-spring, animating on spoke inversion but appearing immediately when a new politician is first selected.</done>
</task>

<task type="auto">
  <name>Task 2: Rebuild CompassV2 with updated ev-ui</name>
  <files>CompassV2/package.json</files>
  <action>
After ev-ui builds successfully, update CompassV2 to use the local ev-ui build:

1. In CompassV2 directory, run `npm install ../ev-ui` to link the local build (this updates the package.json reference to point to the local path).
2. Run `npm run build` in CompassV2 to verify the full app builds cleanly with the updated component.

If CompassV2 already references ev-ui via a local path or file: reference, just run `npm install` to pick up the new build, then `npm run build`.
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub/CompassV2 && npm run build</automated>
  </verify>
  <done>CompassV2 builds successfully with the updated RadarChartCore. No build errors or warnings related to the animation change.</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>Animated the politician's blue compass polygon when spokes are inverted. Previously it snapped immediately; now it smoothly morphs like the user's coral polygon does.</what-built>
  <how-to-verify>
    1. Run `cd CompassV2 && npm run dev` to start the dev server
    2. Navigate to the Compass page
    3. Select a politician to compare (click Compare button, pick a politician)
    4. Both polygons should appear on the radar chart (coral = you, blue = politician)
    5. Click any spoke line to invert it
    6. VERIFY: The blue (politician) polygon now animates smoothly to its new shape, just like the coral (user) polygon does
    7. Click the spoke again to un-invert it
    8. VERIFY: Both polygons animate back smoothly in sync
    9. Switch to a different politician
    10. VERIFY: The new politician's polygon appears immediately (no fly-in animation from center)
  </how-to-verify>
  <resume-signal>Type "approved" or describe issues</resume-signal>
</task>

</tasks>

<verification>
- ev-ui builds without errors: `cd ev-ui && npm run build`
- CompassV2 builds without errors: `cd CompassV2 && npm run build`
- Visual verification that both polygons animate on spoke inversion
- Visual verification that new politician selection does NOT animate from center
</verification>

<success_criteria>
When a spoke is inverted on the compass compare page, both the user's coral polygon and the politician's blue polygon animate smoothly to their new shapes in sync. Selecting a new politician still shows their polygon immediately without a fly-in animation.
</success_criteria>

<output>
After completion, create `.planning/quick/3-animate-politician-compass-spoke-inversi/3-SUMMARY.md`
</output>
