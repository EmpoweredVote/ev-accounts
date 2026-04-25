---
phase: quick-260418-tlq
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - essentials/src/lib/classify.js
autonomous: false
requirements:
  - QUICK-TLQ-01
must_haves:
  truths:
    - "Nicole Bolden (City Clerk of Bloomington) displays under a City Officials category, not City Council"
    - "City Council category still includes actual council members (chamber = 'Common City Council')"
    - "Municipal Officials group renders under the City of Bloomington section"
  artifacts:
    - path: "essentials/src/lib/classify.js"
      provides: "Classification logic with clerk detection taking precedence over council chamber match"
      contains: "classifyCategory"
  key_links:
    - from: "essentials/src/lib/classify.js"
      to: "essentials/src/pages/Results.jsx"
      via: "classifyCategory() return { tier: 'Local', group: 'Municipal Officials' }"
      pattern: "Municipal Officials"
---

<objective>
Fix Nicole Bolden (Bloomington City Clerk) showing under "Common City Council" category.
Her chamber is "Common City Council" (because the clerk attends council meetings administratively), but her title is "City Clerk" — she should categorize as a Municipal Official / City Official, not a council member.

Purpose: Accurate role display under City of Bloomington. The clerk is not a council member.
Output: Updated classify.js with clerk-title check BEFORE chamber-council check in the LOCAL branch.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
</execution_context>

<context>
@.planning/STATE.md
@essentials/src/lib/classify.js
@essentials/src/pages/Results.jsx

<interfaces>
From essentials/src/lib/classify.js — the LOCAL branch (dt === "LOCAL") currently orders checks as:
1. Township check
2. County legislative chambers
3. Chamber contains "council" OR title in ROLE_LOCAL_LEGIS → "City Council"  ← Nicole hits this because chamber="Common City Council"
4. Title contains "clerk" or "city" → "Municipal Officials"  ← Nicole should hit this

Category display mapping (already correct):
  "Municipal Officials": "City Officials"
</interfaces>
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Reorder LOCAL classification so clerk/administrative titles take precedence over council chamber match</name>
  <files>essentials/src/lib/classify.js</files>
  <behavior>
    - Input: { district_type: "LOCAL", chamber_name_formal: "Common City Council", office_title: "City Clerk" } → { tier: "Local", group: "Municipal Officials" }
    - Input: { district_type: "LOCAL", chamber_name_formal: "Common City Council", office_title: "Council Member" } → { tier: "Local", group: "City Council" } (unchanged)
    - Input: { district_type: "LOCAL", chamber_name_formal: "City Council", office_title: "Alderman" } → { tier: "Local", group: "City Council" } (unchanged via ROLE_LOCAL_LEGIS)
  </behavior>
  <action>
    In essentials/src/lib/classify.js, inside the `if (dt === "LOCAL")` branch (around lines 165-200):

    1. Move the clerk-detection block ABOVE the city-council chamber detection. Specifically, relocate this block (currently lines 182-185):
       ```js
       if (hasAny(title, ["clerk", "city"])) {
         return { tier: "Local", group: "Municipal Officials" };
       }
       ```
       to run BEFORE the council-chamber check.

    2. Tighten the clerk check to be more precise — `hasAny(title, ["city"])` is too broad (would match "City Council Member"). Replace with explicit administrative/municipal-officer titles:
       ```js
       // Municipal administrative officials (clerk, treasurer, auditor, etc.) —
       // check BEFORE chamber-council match because clerks are sometimes
       // attached to the council chamber administratively (e.g., Nicole Bolden,
       // Bloomington City Clerk, chamber="Common City Council").
       if (hasAny(title, ["clerk", "treasurer", "auditor", "recorder", "assessor"])) {
         return { tier: "Local", group: "Municipal Officials" };
       }
       ```

    3. Keep the existing City Council detection block unchanged (it stays after the clerk block).

    4. Remove the now-duplicate/dead clerk check that used to live below the council check.

    Do NOT touch FEDERAL, STATE, COUNTY, SCHOOL, or JUDICIAL branches. Do NOT change CATEGORY_DISPLAY_NAMES (already maps "Municipal Officials" → "City Officials").
  </action>
  <verify>
    <automated>cd essentials &amp;&amp; node -e "import('./src/lib/classify.js').then(m =&gt; { const r1 = m.classifyCategory({ district_type: 'LOCAL', chamber_name_formal: 'Common City Council', office_title: 'City Clerk' }); const r2 = m.classifyCategory({ district_type: 'LOCAL', chamber_name_formal: 'Common City Council', office_title: 'Council Member' }); console.log('clerk:', JSON.stringify(r1)); console.log('council:', JSON.stringify(r2)); if (r1.group !== 'Municipal Officials') process.exit(1); if (r2.group !== 'City Council') process.exit(1); console.log('PASS'); })"</automated>
  </verify>
  <done>City Clerk with council chamber returns group "Municipal Officials"; actual council members still return "City Council". No regressions in township/county classification.</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 2: Verify Nicole Bolden displays correctly in essentials app</name>
  <what-built>Reclassified City Clerk role so clerks attached to council chambers render under "City Officials" (Municipal Officials) instead of "City Council".</what-built>
  <how-to-verify>
    1. `cd essentials &amp;&amp; npm run dev`
    2. Visit the dev URL and search for a Bloomington address (e.g., an address in Bloomington, IN)
    3. Expand the "City of Bloomington" / Local tier section
    4. Confirm Nicole Bolden appears under "City Officials" (NOT under "City Council")
    5. Confirm actual Bloomington Common Council members still appear under "City Council"
    6. Confirm no other local officials shifted categories unexpectedly
  </how-to-verify>
  <resume-signal>Type "approved" or describe any display issues</resume-signal>
</task>

</tasks>

<verification>
- classify.js unit check passes (see Task 1 automated verify)
- Manual UI verification (Task 2) confirms Nicole Bolden under City Officials
- No regressions to City Council, County, Township, or School Board categories
</verification>

<success_criteria>
- Nicole Bolden displays under "City Officials" in Bloomington results
- Actual council members remain under "City Council"
- classify.js change is minimal (LOCAL branch only) and commented to explain why clerk check precedes council check
</success_criteria>

<output>
After completion, create `.planning/quick/260418-tlq-fix-nicole-bolden-display-show-as-city-o/260418-tlq-SUMMARY.md`
</output>
