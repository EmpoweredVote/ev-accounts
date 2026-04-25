---
phase: quick-260419-szc
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - essentials/src/lib/groupHierarchy.js
autonomous: false
requirements:
  - "Nicole Bolden (Bloomington City Clerk) must appear under City Officials sub-group, NOT under Common Council"
  - "Existing Common Council members must remain under City Council sub-group"
  - "Fix must be data-driven (reusable for other clerks/admin officials, not Bolden-specific)"
must_haves:
  truths:
    - "Searching a Bloomington, IN address shows Nicole Bolden under a City Officials / Clerk sub-group"
    - "Common Council members still appear together under their council sub-group"
    - "No regression in other Bloomington/local results (mayor, council, county, etc.)"
  artifacts:
    - path: "essentials/src/lib/groupHierarchy.js"
      provides: "Sub-group key/label logic that separates clerks from council members in same chamber"
  key_links:
    - from: "essentials/src/pages/Results.jsx"
      to: "essentials/src/lib/groupHierarchy.js"
      via: "groupIntoHierarchy(deduped) call"
      pattern: "groupIntoHierarchy"
---

<objective>
Fix Nicole Bolden (Bloomington City Clerk) appearing inside the Common Council sub-group on the essentials Results page. She must appear under a separate "City Clerk" / "City Officials" sub-group of the City of Bloomington accordion.

Purpose: A previous quick task (260418-tlq) modified `essentials/src/lib/classify.js` — but that file is NOT what drives the current grouping. The actual rendering uses `essentials/src/lib/groupHierarchy.js` (data-driven by `government_name` + `government_body_name` + `district_type`). Bolden shares `government_body_name` with the Common Council members, so the existing `getSubGroupKey()` (which keys by `government_body_name + district_type`) puts them in the same sub-group. Both Bolden and the council members have `district_type = LOCAL`, so the district_type tiebreaker doesn't separate them either.

Output: Updated `getSubGroupKey()` and `getSubGroupLabel()` in groupHierarchy.js so administrative officers (clerk, treasurer, auditor, recorder, assessor) are split into their own sub-group inside the same government_body accordion, with a clean label like "Clerk" / "City Clerk".
</objective>

<context>
@essentials/src/lib/groupHierarchy.js
@essentials/src/pages/Results.jsx
@.planning/quick/260418-tlq-fix-nicole-bolden-display-show-as-city-o/260418-tlq-SUMMARY.md
</context>

<interfaces>
<!-- Key shape of the politician object as it flows from backend to grouping -->
<!-- Source: ev-accounts/backend/src/lib/essentialsService.ts (PoliticianFlatRecord) -->

Politician fields used by groupHierarchy.js:
- district_type: string  (e.g. "LOCAL", "LOCAL_EXEC", "STATE_UPPER", ...)
- government_name: string  (e.g. "City of Bloomington, Indiana, US")
- government_body_name: string  (e.g. "Common Council" or "City of Bloomington")
- chamber_name_formal: string  (e.g. "Common City Council")
- chamber_name: string
- office_title: string  (e.g. "City Clerk", "Council Member - At Large")
- district_id: string
- last_name: string

Nicole Bolden's expected record (Bloomington City Clerk):
- district_type: "LOCAL"
- office_title: "City Clerk" (or similar — contains "Clerk")
- government_body_name: same value as Common Council members (root cause)
- chamber_name_formal: "Common City Council"

Key function signatures in groupHierarchy.js:
- getSubGroupKey(pol) -> string  (currently `${government_body_name}||${district_type}`)
- getSubGroupLabel(pols, accordionTitle) -> string
</interfaces>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Split admin officers into their own sub-group in groupHierarchy.js</name>
  <files>essentials/src/lib/groupHierarchy.js</files>
  <behavior>
    Add a helper `isAdminOfficer(pol)` that returns true when `office_title` matches /\b(clerk|treasurer|auditor|recorder|assessor)\b/i AND `district_type` starts with "LOCAL" (so we don't reclassify county roles or state-level treasurers).

    Modify `getSubGroupKey(pol)` to append a third segment "ADMIN" when isAdminOfficer is true:
      - Council Member, district_type=LOCAL, government_body_name="Bloomington Common Council"
        -> "Bloomington Common Council||LOCAL||MEMBER"
      - Nicole Bolden, district_type=LOCAL, government_body_name="Bloomington Common Council", office_title="City Clerk"
        -> "Bloomington Common Council||LOCAL||ADMIN"
      Result: distinct sub-groups inside the same accordion.

    Modify `getSubGroupLabel(pols, accordionTitle)` so that when ALL pols in a sub-group are admin officers, the label becomes a clean role-based label:
      - All clerks -> "City Clerk"  (or "Clerk" if office_title contains "Clerk")
      - All treasurers -> "Treasurer", etc.
      - Mixed/single role: derive from office_title with "City "/"Town "/"Village "/"County " prefix stripped, and any " - <district>" suffix stripped.

    Update `subGroupOrderScore(label, pols)` so admin-officer sub-groups sort after legislative bodies and after executives (they currently fall into the default "Other" bucket at 30 — keep that, but ensure they don't accidentally hit the LEGISLATIVE_KW match because their accordion key contains "council").

    Tests (write first, in new file `essentials/src/lib/groupHierarchy.test.js` using Vitest if not present, otherwise plain Node assert):
      - Test A: Bolden + 9 council members in one government_body -> result has TWO sub-groups (one for Bolden, one for council); Bolden's sub-group label contains "Clerk".
      - Test B: Council members alone -> single sub-group, label unchanged from current behavior.
      - Test C: A LOCAL treasurer + LOCAL council members in same body -> two sub-groups, treasurer separated.
      - Test D: COUNTY clerk (district_type="COUNTY") -> NOT split into ADMIN sub-group (rule guards by LOCAL prefix; county hierarchy already handled elsewhere).
      - Test E: LOCAL_EXEC mayor + LOCAL council in same government_name accordion -> still two sub-groups (existing behavior preserved via district_type segment).

    Implementation notes:
      - Keep changes confined to groupHierarchy.js. Do NOT touch classify.js — it's no longer the source of truth for grouping.
      - When checking office_title for "council" to avoid the legislative bucket misfire in subGroupOrderScore, also pass `pols` so you can check `isAdminOfficer(pols[0])` and force a non-legislative score.
  </behavior>
  <action>
    1. Open essentials/src/lib/groupHierarchy.js
    2. Add `isAdminOfficer(pol)` helper near top (after `getTier`).
    3. Update `getSubGroupKey` to append `||ADMIN` vs `||MEMBER` segment based on isAdminOfficer (LOCAL only).
    4. Update `getSubGroupLabel` with admin-officer label branch (runs BEFORE the existing "Rule 1" body===accordionGovName branch, so it works whether body equals accordion name or not). Label derivation: take first pol's office_title, strip leading "City "/"Town "/"Village "/"County ", strip " - ..." suffix; if result is bare "Clerk" prefix the jurisdiction noun ("City Clerk"); otherwise return cleaned title.
    5. Update `subGroupOrderScore` to short-circuit admin-officer sub-groups to score 25 (between executives at 20 and other at 30) so they sit just below executives but above generic "other" entries.
    6. Write tests in essentials/src/lib/groupHierarchy.test.js (or extend if file exists). If essentials project doesn't have Vitest configured, use a self-contained Node script `essentials/scripts/test-groupHierarchy.mjs` that imports the module, runs the 5 cases, prints PASS/FAIL, and exits non-zero on failure.
    7. Run the tests; iterate until all 5 pass.
  </action>
  <verify>
    <automated>cd essentials && (npx vitest run src/lib/groupHierarchy.test.js 2>/dev/null || node scripts/test-groupHierarchy.mjs)</automated>
  </verify>
  <done>
    All 5 test cases pass. groupHierarchy.js exports unchanged signature for `groupIntoHierarchy`. No edits made to classify.js.
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>
    Sub-group splitting in groupHierarchy.js so that LOCAL administrative officers (clerk/treasurer/auditor/recorder/assessor) appear in their own sub-group within the same government body accordion, instead of being lumped in with council members.
  </what-built>
  <how-to-verify>
    1. `cd essentials && npm run dev`
    2. Open the dev URL (typically http://localhost:5173)
    3. Search a Bloomington, IN address (e.g., "200 W Kirkwood Ave, Bloomington, IN, 47404")
    4. Scroll to the Local tier -> "City of Bloomington" (or "Bloomington Common Council") accordion
    5. CONFIRM: Nicole Bolden appears in a separate sub-group labelled "City Clerk" (or "Clerk") — NOT mixed in with the Common Council members.
    6. CONFIRM: Common Council members are still grouped together under their council sub-group.
    7. CONFIRM: Mayor still appears as its own sub-group (no regression).
    8. CONFIRM: Other previously-correct results (county officials, state legislators, federal reps) look unchanged.
    9. (Optional) Search a different city's address (e.g., a Los Angeles County address) and confirm no visual regressions.
  </how-to-verify>
  <resume-signal>Type "approved" or describe issues observed</resume-signal>
</task>

</tasks>

<verification>
- Automated tests in Task 1 pass (5/5 cases).
- Human verification confirms Bolden displays under City Clerk sub-group on a real Bloomington address search.
- No regressions in council, mayor, or other-tier displays.
</verification>

<success_criteria>
- Nicole Bolden displayed under a "City Clerk" / "City Officials" sub-group, separate from Common Council.
- Common Council members remain grouped together.
- Fix is data-driven (works for any clerk/treasurer/auditor/recorder/assessor at LOCAL level), not Bolden-specific.
- groupHierarchy.js automated tests pass.
- classify.js untouched (it's no longer the source of truth for grouping).
</success_criteria>

<output>
After completion, create `.planning/quick/260419-szc-fix-nicole-bolden-classification-show-as/260419-szc-SUMMARY.md` documenting:
- Root cause clarification (classify.js was modified previously but isn't in the rendering path; groupHierarchy.js is)
- The sub-group key + label changes
- Test results
- Human verification outcome
</output>
