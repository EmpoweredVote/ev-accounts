---
phase: quick-260422-upn
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - essentials/src/lib/groupHierarchy.js
  - essentials/src/lib/groupHierarchy.test.js
  - essentials/src/pages/Results.jsx
autonomous: false
requirements:
  - UPN-01  # Nicole Brown (Clerk of Court) displays in its own "Circuit Court Officials" sub-group
  - UPN-02  # Judges display under "Circuit Court Judges" sub-group (existing behavior, preserved)
  - UPN-03  # Treasury "revenue and expenses" link does NOT render on judicial accordion bodies

must_haves:
  truths:
    - "Monroe Circuit Court accordion renders TWO sub-groups: 'Circuit Court Judges' (the judges) and 'Circuit Court Officials' (Nicole Brown)"
    - "Nicole Brown is NOT grouped inline with the judges"
    - "No 'Explore Monroe County revenue and expenses' link appears inside the Monroe Circuit Court accordion"
    - "Non-judicial Local accordions (City of Bloomington, Monroe County Government) still show the treasury link when a match exists"
  artifacts:
    - path: "essentials/src/lib/groupHierarchy.js"
      provides: "JUDICIAL sub-group split (judges vs. clerk/officials) and Circuit Court Officials label"
      contains: "Circuit Court Officials"
    - path: "essentials/src/lib/groupHierarchy.test.js"
      provides: "Test covering Nicole Brown appearing in its own Circuit Court Officials sub-group"
      contains: "Circuit Court Officials"
    - path: "essentials/src/pages/Results.jsx"
      provides: "Treasury link guard skipping judicial bodies"
      contains: "isJudicialBody"
  key_links:
    - from: "groupHierarchy.js getSubGroupKey"
      to: "judicial clerk/admin vs judge split"
      via: "role segment (JUDGE vs OFFICIAL) in sub-group key"
      pattern: "JUDGE|OFFICIAL"
    - from: "Results.jsx body render"
      to: "treasury link"
      via: "guard that skips when body contains JUDICIAL pols"
      pattern: "district_type.*JUDICIAL"
---

<objective>
Fix the Monroe Circuit Court accordion in the essentials app so Nicole Brown (Clerk of Court) is displayed in her own "Circuit Court Officials" sub-group, separate from the "Circuit Court Judges" sub-group. Also suppress the municipality treasury link on judicial bodies because courts are not funded by the Monroe County general-fund budget currently in the treasury tracker.

Purpose: Users currently see Nicole Brown grouped alongside judges and see an inapplicable "Explore Monroe County revenue and expenses" link under the court body — both are misleading.

Output: Corrected grouping logic in `groupHierarchy.js`, a regression test, and a conditional render guard in `Results.jsx`.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
</execution_context>

<context>
@CLAUDE.md
@essentials/src/lib/classify.js
@essentials/src/lib/groupHierarchy.js
@essentials/src/lib/groupHierarchy.test.js
@essentials/src/pages/Results.jsx

<interfaces>
Key existing behavior to preserve / extend:

From essentials/src/lib/groupHierarchy.js:
- `getAccordionKey(pol)` — JUDICIAL pols: returns `pol.government_body_name` (e.g. "Monroe Circuit Court"). KEEP AS-IS.
- `getSubGroupKey(pol)` — currently: `${body}||${dt}||${roleSegment}`, where roleSegment is `ADMIN` only for `LOCAL` + admin officer title. For JUDICIAL pols, all share the same sub-group key. EXTEND so a JUDICIAL pol whose title contains "clerk" goes into an `OFFICIAL` segment and judges go into a `JUDGE` segment.
- `getSubGroupLabel(pols, accordionTitle)` — Rule 4 handles judiciary via circuit prefix ("... Circuit Judges"). EXTEND to return `"Circuit Court Officials"` (or `"<court> Officials"`) when the sub-group contains clerk/admin pols.
- `subGroupOrderScore(label, pols)` — admin-officer groups score 25. A Judicial "officials" sub-group should sort AFTER the judges sub-group. Use score 30 (or >score for judges) for judicial officials so judges render first.
- `isAdminOfficer(pol)` — currently requires `dt.startsWith('LOCAL')`. Do NOT broaden this function; instead introduce a new `isJudicialOfficial(pol)` helper that matches `dt === 'JUDICIAL'` and title clerk/admin keywords.

From essentials/src/pages/Results.jsx (lines ~1040–1066):
- Current treasury render gate: `tier === 'Local' ? findMatchingMunicipality(body.title, treasuryCities) : null`.
- `body` here is `{ key, title, url, subgroups }` from groupHierarchy. It does not carry district_type directly, so the guard must either (a) inspect the body's subgroup pols, or (b) receive an enriched flag. Simplest: check `body.subgroups.some(sg => sg.pols.some(p => p.district_type === 'JUDICIAL'))` before computing treasuryMatch.

Nicole Brown politician record shape (based on test fixtures):
- `district_type`: `'JUDICIAL'`
- `office_title`: contains `"Clerk"` (e.g. "Clerk of the Monroe Circuit Court" or similar)
- `government_body_name`: `"Monroe Circuit Court"` (shared with the judges)
- `chamber_name` / `chamber_name_formal`: Circuit Court chamber
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Split judicial sub-groups — judges vs. court officials — and guard treasury link on judicial bodies</name>
  <files>essentials/src/lib/groupHierarchy.js, essentials/src/lib/groupHierarchy.test.js, essentials/src/pages/Results.jsx</files>
  <behavior>
    Test cases (add to essentials/src/lib/groupHierarchy.test.js, following existing test style):

    1. **Judicial sub-group split — judges and clerk are separated**
       Given a flat list containing:
         - 3 JUDICIAL pols with office_title like "Indiana Circuit Court Judge - 10th Circuit, Division N", government_body_name "Monroe Circuit Court"
         - 1 JUDICIAL pol with office_title "Clerk of the Monroe Circuit Court" (Nicole Brown), government_body_name "Monroe Circuit Court"
       When groupIntoHierarchy runs
       Then the Local tier has a body titled "Monroe Circuit Court" with EXACTLY 2 sub-groups:
         - one labeled matching /Circuit Judges$/ containing all 3 judges
         - one labeled "Circuit Court Officials" containing ONLY the clerk pol
       And the judges sub-group sorts BEFORE the officials sub-group.

    2. **Non-clerk judicial pols do not create an empty officials group**
       Given a flat list with only 2 JUDICIAL judge pols (no clerk)
       When groupIntoHierarchy runs
       Then the body has exactly 1 sub-group (the judges); no "Officials" sub-group appears.

    3. **LOCAL admin officers still behave as before (regression)**
       Given the existing LOCAL admin officer fixture (e.g., Nicole Bolden as City Clerk) — the previously-passing test must still pass: admin officer lands in its own sub-group within the City of Bloomington accordion. (Do not duplicate the existing test; just don't break it.)

    No dedicated unit test for Results.jsx treasury guard (integration surface) — covered by the human-verify checkpoint below. The implementation guard itself is small and inspectable.
  </behavior>
  <action>
    Follow RED → GREEN → REFACTOR. Commit after RED and after GREEN.

    **RED — write failing tests first:**
    1. Open `essentials/src/lib/groupHierarchy.test.js`. Extend it with the two new test cases above (judicial split; no-clerk = one group). Match the existing `makePol` factory / import style already used in the file.
    2. Run `cd essentials && npm test -- groupHierarchy` (or `npx vitest run src/lib/groupHierarchy.test.js`) — confirm the new judicial tests FAIL and existing tests PASS.
    3. Commit: `test(quick-260422-upn): add failing tests for Circuit Court sub-group split`

    **GREEN — implement minimum code to pass:**
    4. Edit `essentials/src/lib/groupHierarchy.js`:
       - Add helper near `isAdminOfficer`:
         ```js
         const JUDICIAL_OFFICIAL_TITLE_RE = /\bclerk\b|\badministrator\b|\bcourt officer\b/i;
         function isJudicialOfficial(pol) {
           return pol.district_type === 'JUDICIAL' && JUDICIAL_OFFICIAL_TITLE_RE.test(pol.office_title || '');
         }
         ```
       - In `getSubGroupKey(pol)`: before returning the generic `${body}||${dt}||${roleSegment}`, handle JUDICIAL explicitly:
         ```js
         if (dt === 'JUDICIAL') {
           const judicialSeg = isJudicialOfficial(pol) ? 'OFFICIAL' : 'JUDGE';
           return `${body}||${dt}||${judicialSeg}`;
         }
         ```
       - In `getSubGroupLabel(pols, accordionTitle)`: before Rule 4 (judicial circuit-prefix logic), add a branch for judicial officials:
         ```js
         if (dt === 'JUDICIAL' && pols.every(p => isJudicialOfficial(p))) {
           // Derive court name from accordion / body (e.g. "Monroe Circuit Court" → "Circuit Court Officials")
           const courtName = (body || accordionTitle || '').replace(/^.*?\b(Circuit Court|Superior Court|District Court|Court)\b.*$/i, '$1');
           return courtName ? `${courtName} Officials` : 'Court Officials';
         }
         ```
         Ensure the existing Rule 4 (judges → "... Circuit Judges") continues to run for the judges sub-group (since `pols.every(isJudicialOfficial)` will be false for them).
       - In `subGroupOrderScore(label, pols)`: add a check BEFORE the admin-officer (25) check:
         ```js
         if (pols.length > 0 && pols.every(p => isJudicialOfficial(p))) return 30; // Judicial officials AFTER judges
         ```
         The judges sub-group will fall through to the default `return 30` path via no keyword match; to guarantee judges sort FIRST, add explicit rule above existing keyword matches:
         ```js
         if (pols.length > 0 && pols[0]?.district_type === 'JUDICIAL' && !pols.every(p => isJudicialOfficial(p))) return 15; // Judges first within a court body
         ```
         (Adjust numbers as needed — the only hard requirement is: judges score < officials score within the same accordion.)

    5. Edit `essentials/src/pages/Results.jsx` around line 1040–1066:
       - Replace the current `const treasuryMatch = tier === 'Local' ? findMatchingMunicipality(...) : null;` with a guard that skips judicial bodies:
         ```js
         const isJudicialBody = body.subgroups.some(sg =>
           sg.pols.some(p => p.district_type === 'JUDICIAL')
         );
         const treasuryMatch = (tier === 'Local' && !isJudicialBody)
           ? findMatchingMunicipality(body.title, treasuryCities)
           : null;
         ```
       - No other changes to the render tree.

    6. Run `cd essentials && npm test -- groupHierarchy` — all tests (new + existing) must PASS.
    7. Run `cd essentials && npm run build` — must succeed with no new errors/warnings introduced by this change.
    8. Commit: `feat(quick-260422-upn): split Circuit Court officials from judges and hide treasury link on courts`

    **REFACTOR (optional):** Only if duplication emerges (e.g., the court-name extraction regex can be lifted to a named helper), clean up and commit separately. Otherwise skip.
  </action>
  <verify>
    <automated>cd essentials && npx vitest run src/lib/groupHierarchy.test.js && npm run build</automated>
  </verify>
  <done>
    - All `groupHierarchy.test.js` tests pass (existing + 2 new judicial cases)
    - `npm run build` succeeds in essentials/
    - Code review: Nicole Brown's fixture (`district_type: JUDICIAL`, title contains "Clerk") produces a sub-group labeled "Circuit Court Officials" separate from the judges
    - Results.jsx treasury link render is gated by `!isJudicialBody`
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>
    Split the Monroe Circuit Court accordion into two sub-groups (judges vs. officials), and removed the "Explore Monroe County revenue and expenses" link from the Circuit Court body.
  </what-built>
  <how-to-verify>
    1. Start essentials dev server: `cd essentials && npm run dev`
    2. Visit http://localhost:5173 (or printed port). Enter a Bloomington/Monroe County address (e.g., `100 W Kirkwood Ave, Bloomington, IN 47404`) and submit.
    3. Wait for results. Scroll to the **Local** tier and locate the **Monroe Circuit Court** accordion. Expand it.
    4. Confirm:
       a. Two sub-group headings are visible inside the accordion:
          - "... Circuit Judges" (or similar — the existing judges heading) listing the Circuit Court judges
          - "Circuit Court Officials" listing Nicole Brown (Clerk of Court) — and only Nicole Brown
       b. Nicole Brown does NOT appear in the judges list.
       c. NO "Explore Monroe County revenue and expenses" link is visible anywhere inside the Monroe Circuit Court accordion.
    5. Scroll to the **City of Bloomington** and **Monroe County Government** accordions. Confirm the "Explore … revenue and expenses" treasury link IS still present on those (regression check).
    6. Open DevTools console; confirm no new errors or React warnings during render.
  </how-to-verify>
  <resume-signal>Reply "approved" if all six checks pass, or describe what's wrong.</resume-signal>
</task>

</tasks>

<verification>
- Unit tests pass for groupHierarchy (new judicial split cases + existing regression cases)
- Build succeeds
- Human verification confirms visual split and treasury-link suppression on court bodies only
</verification>

<success_criteria>
- Nicole Brown appears under "Circuit Court Officials" within the Monroe Circuit Court accordion, not alongside judges
- Circuit Court judges remain under their existing "... Circuit Judges" sub-group
- No treasury link renders inside the Monroe Circuit Court accordion
- Treasury link still renders on non-judicial Local accordions (City of Bloomington, Monroe County Government)
- No new test failures, no new build warnings
</success_criteria>

<output>
After completion, create `.planning/quick/260422-upn-fix-circuit-court-category-nicole-brown-/260422-upn-SUMMARY.md` recording: files changed, test count added, key decisions (why isJudicialOfficial is separate from isAdminOfficer, why the treasury guard lives in Results.jsx rather than groupHierarchy).
</output>
