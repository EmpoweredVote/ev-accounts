---
phase: quick
plan: 260426-eob
type: execute
wave: 1
depends_on: []
files_modified:
  - essentials/src/components/CompassFirstCard.jsx
autonomous: true
requirements: []
must_haves:
  truths:
    - "CompassFirstCard does not render a compass icon in its IconOverlay row"
    - "BallotIcon and BranchIcon still render as before when applicable"
  artifacts:
    - path: "essentials/src/components/CompassFirstCard.jsx"
      provides: "Updated card with hasStances always false"
  key_links:
    - from: "CompassFirstCard.jsx"
      to: "IconOverlay.jsx"
      via: "hasStances prop"
      pattern: "hasStances={false}"
---

<objective>
Remove the compass icon from CompassFirstCard's IconOverlay row.

Purpose: The compass-first card already uses the radar chart as the primary visual anchor — showing a compass icon badge in the icon row is redundant noise now that we've moved to compass-first layout.
Output: CompassFirstCard passes `hasStances={false}` to IconOverlay so the CompassIcon is never rendered on these cards.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Remove compass icon from CompassFirstCard IconOverlay</name>
  <files>essentials/src/components/CompassFirstCard.jsx</files>
  <action>
    In the `contentNode` section of CompassFirstCard.jsx (around line 235-243), the IconOverlay is rendered with:

    ```jsx
    <IconOverlay
      ballot={politician.ballot || null}
      hasStances={Boolean(mockAnswers)}
      branch={politician.branch || null}
    />
    ```

    Change `hasStances={Boolean(mockAnswers)}` to `hasStances={false}`.

    This removes the CompassIcon badge from the icon row on all CompassFirstCard variants (A, B, C). The radar chart itself already communicates compass stance data — the icon is redundant.

    Do NOT modify IconOverlay.jsx itself; the change is isolated to how CompassFirstCard calls it. Leave ballot and branch props unchanged.
  </action>
  <verify>
    Grep confirms the change:
    `grep -n "hasStances" essentials/src/components/CompassFirstCard.jsx`
    Expected output: `hasStances={false}` (not `Boolean(mockAnswers)`)
  </verify>
  <done>CompassFirstCard passes hasStances={false} to IconOverlay. No compass icon appears on compass-first cards. Ballot and branch icons remain unaffected.</done>
</task>

</tasks>

<verification>
```bash
grep -n "hasStances" essentials/src/components/CompassFirstCard.jsx
# Must show: hasStances={false}
```
</verification>

<success_criteria>
- `hasStances={false}` is set in CompassFirstCard.jsx's IconOverlay call
- No compass icon badge renders on CompassFirstCard variants A, B, or C
- Ballot and branch icons are unaffected
</success_criteria>

<output>
After completion, create `.planning/quick/260426-eob-remove-compass-icon-from-compass-first-c/260426-eob-SUMMARY.md`
</output>
