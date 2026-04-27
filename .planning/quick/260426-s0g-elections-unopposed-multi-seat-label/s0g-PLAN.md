---
phase: quick-s0g
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - ev-ui/src/CompassCardVertical.jsx
  - ev-ui/src/CompassCardHorizontal.jsx
  - ev-ui/package.json
  - essentials/src/components/ElectionsView.jsx
autonomous: true
requirements: [s0g]
must_haves:
  truths:
    - "Single-seat unopposed races still show 'Running Unopposed' (no change to callers)"
    - "Multi-seat races where activeCandidates.length <= seats show 'Running Unopposed (N seats)'"
    - "Zero-candidate races (isEmpty) do not show the banner"
    - "Withdrawn candidates do not show the banner regardless of seat count"
  artifacts:
    - path: ev-ui/src/CompassCardVertical.jsx
      provides: "string-safe running_unopposed banner render (line ~371)"
    - path: ev-ui/src/CompassCardHorizontal.jsx
      provides: "string-safe running_unopposed banner render (line ~339)"
    - path: essentials/src/components/ElectionsView.jsx
      provides: "seats-aware isUnopposed logic + string label passed to polForCard"
  key_links:
    - from: "essentials/src/components/ElectionsView.jsx"
      to: "CompassCardVertical / CompassCardHorizontal"
      via: "polForCard.running_unopposed — string for multi-seat, true for single-seat"
      pattern: "running_unopposed.*seats"
---

<objective>
Correctly label multi-seat unopposed races with seat count on the Elections page.

Purpose: Races where all seats are filled (or more seats than candidates) currently display "Running Unopposed" only for single-candidate races. This fix makes the label accurate for any race where activeCandidates.length <= seats, and adds "(N seats)" context for multi-seat cases.

Output: ev-ui 0.6.4 patch (string-safe banner in both card components) + updated ElectionsView logic. Separate commits per project.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/quick/260426-s0g-elections-unopposed-multi-seat-label/s0g-CONTEXT.md

<interfaces>
<!-- Key contracts extracted from source files. -->

From ev-ui/src/CompassCardVertical.jsx (lines 362–373) — existing banner:
```jsx
{surface === 'elections' && !politician.withdrawn && politician.running_unopposed && (
  <div style={{ /* ... */ }}>
    Running Unopposed          {/* ← hardcoded string to replace */}
  </div>
)}
```

From ev-ui/src/CompassCardHorizontal.jsx (lines 323–341) — existing banner:
```jsx
{surface === 'elections' && politician.running_unopposed && (
  <div style={{ /* ... */ }}>
    Running Unopposed          {/* ← hardcoded string to replace */}
  </div>
)}
```

From essentials/src/components/ElectionsView.jsx — processedElections race object (lines 331–339):
```js
tierMap[tier][body].races.push({
  key: subgroupKey,
  label: subgroupLabel,
  party,
  districtType: race.district_type,
  raceId: race.race_id,
  shuffledCandidates: seededShuffle(race.candidates, sessionSeed),
  cleanedPosition: cleaned,
  // seats NOT forwarded — add: seats: race.seats ?? 1
});
```

From essentials/src/components/ElectionsView.jsx — isUnopposed (line 563):
```js
const isUnopposed = activeCandidates.length === 1;   // ← replace with seats-aware logic
```

From essentials/src/components/ElectionsView.jsx — polForCard (lines 623–636):
```js
const polForCard = {
  // ...
  running_unopposed: isUnopposed && candidate.candidate_status !== 'withdrawn',
  // ↑ replace with string label for multi-seat, boolean true for single-seat
};
```

ev-ui/package.json current version: "0.6.3" → bump to "0.6.4"
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: ev-ui — make running_unopposed prop accept string | boolean in both card components</name>
  <files>ev-ui/src/CompassCardVertical.jsx, ev-ui/src/CompassCardHorizontal.jsx, ev-ui/package.json</files>
  <action>
In both card components, replace the hardcoded "Running Unopposed" text with a conditional that renders the prop value when it is a string, or falls back to "Running Unopposed" when it is boolean true. Backwards-compatible — all existing callers passing `true` continue to work unchanged.

CompassCardVertical.jsx (~line 371):
```jsx
{typeof politician.running_unopposed === 'string' ? politician.running_unopposed : 'Running Unopposed'}
```

CompassCardHorizontal.jsx (~line 339):
Same substitution — render `politician.running_unopposed` as the banner text when it is a string, otherwise render 'Running Unopposed'.

Both files already guard the banner on `politician.running_unopposed` being truthy, so no condition change is needed — only the inner text expression changes.

After both edits, bump ev-ui/package.json version from "0.6.3" to "0.6.4".

Commit (from the ev-ui directory or using its path):
```
feat(ev-ui): support string running_unopposed prop in CompassCard components (0.6.4)
```

Then push the version tag to trigger the npm publish + auto-bump pipeline:
```bash
cd /Users/chrisandrews/Documents/GitHub/ev-ui
npm version patch  # should already be set to 0.6.4; skip if package.json already updated manually
git push origin main --follow-tags
```
Note: If you manually edited package.json to 0.6.4, run `git tag v0.6.4 && git push origin main --follow-tags` instead of `npm version patch` (which would double-bump to 0.6.5).
  </action>
  <verify>
    <automated>grep -n "running_unopposed" /Users/chrisandrews/Documents/GitHub/ev-ui/src/CompassCardVertical.jsx | grep -v "^#" && grep -n "running_unopposed" /Users/chrisandrews/Documents/GitHub/ev-ui/src/CompassCardHorizontal.jsx | grep -v "^#"</automated>
  </verify>
  <done>Both card files render `typeof politician.running_unopposed === 'string' ? politician.running_unopposed : 'Running Unopposed'` (or equivalent). ev-ui package.json version is 0.6.4. Tag v0.6.4 pushed to origin.</done>
</task>

<task type="auto">
  <name>Task 2: essentials ElectionsView — forward seats, fix isUnopposed, pass string label</name>
  <files>essentials/src/components/ElectionsView.jsx</files>
  <action>
Three targeted edits to ElectionsView.jsx:

**Edit A — forward seats in processedElections useMemo (~line 331–339):**
Add `seats: race.seats ?? 1` to the object pushed into `tierMap[tier][body].races`. The `race` here is from `election.races` (API response), which already carries `seats: number`.

**Edit B — update isUnopposed (~line 563):**
Replace:
```js
const isUnopposed = activeCandidates.length === 1;
```
With:
```js
const seats = race.seats ?? 1;
const isUnopposed = activeCandidates.length > 0 && activeCandidates.length <= seats;
```
Note: `race` at this scope is the item from the inner `.map` over the races array (the processed race object from Edit A, which now carries `seats`).

**Edit C — set running_unopposed to string for multi-seat (~line 634):**
Replace:
```js
running_unopposed: isUnopposed && candidate.candidate_status !== 'withdrawn',
```
With:
```js
running_unopposed: isUnopposed && candidate.candidate_status !== 'withdrawn'
  ? (seats > 1 ? `Running Unopposed (${seats} seats)` : true)
  : false,
```

Commit from the essentials directory:
```
feat(essentials): label multi-seat unopposed races with seat count in ElectionsView
```
  </action>
  <verify>
    <automated>grep -n "seats\|isUnopposed\|running_unopposed" /Users/chrisandrews/Documents/GitHub/essentials/src/components/ElectionsView.jsx</automated>
  </verify>
  <done>ElectionsView.jsx has `seats: race.seats ?? 1` in processedElections, `const seats = race.seats ?? 1` + `activeCandidates.length > 0 && activeCandidates.length <= seats` for isUnopposed, and `Running Unopposed (${seats} seats)` string for multi-seat in polForCard. Commit pushed.</done>
</task>

</tasks>

<verification>
After both tasks:
- Single-seat races with 1 active candidate show "Running Unopposed" (no change)
- Multi-seat races where active candidates <= seats show "Running Unopposed (N seats)"
- Races with 0 candidates (isEmpty path) show the "No candidates have filed" message, not the banner
- Withdrawn candidates do not show the banner
- ev-ui 0.6.4 tag is visible at github.com/EmpoweredVote/ev-ui/releases
</verification>

<success_criteria>
- CompassCardVertical and CompassCardHorizontal render `running_unopposed` prop as string when provided (backwards-compatible with boolean true)
- ElectionsView correctly derives `isUnopposed` using seat count from API
- Multi-seat label includes "(N seats)" suffix; single-seat label is unchanged
- ev-ui package version is 0.6.4 with tag pushed to origin
- essentials commit is separate from ev-ui commit
</success_criteria>

<output>
After completion, create `.planning/quick/260426-s0g-elections-unopposed-multi-seat-label/s0g-SUMMARY.md`
</output>
