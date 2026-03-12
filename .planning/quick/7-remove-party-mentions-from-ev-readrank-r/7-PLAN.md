---
phase: quick-7
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - EV-readrank/src/components/ResultsPhase.tsx
  - EV-readrank/src/components/CandidateAlignmentPage.tsx
autonomous: true
requirements: [QUICK-7]

must_haves:
  truths:
    - "No party label (e.g. 'Republican Party', 'Democratic Party', 'Libertarian Party') appears anywhere in the results UI"
    - "Candidate cards still show name and office"
    - "CandidateAlignmentPage header still shows name and office"
  artifacts:
    - path: "EV-readrank/src/components/ResultsPhase.tsx"
      provides: "Quote result cards without party label"
    - path: "EV-readrank/src/components/CandidateAlignmentPage.tsx"
      provides: "Candidate alignment header without party label"
  key_links:
    - from: "ResultsPhase.tsx QuoteResultCard"
      to: "candidate.party"
      via: "getPartyColor + JSX render"
      pattern: "candidate\\.party"
    - from: "CandidateAlignmentPage.tsx profile header"
      to: "candidate.party"
      via: "JSX render"
      pattern: "candidate\\.party"
---

<objective>
Remove all party label rendering from the EV-ReadRank results UI to make the app antipartisan.

Purpose: Party labels reinforce identity politics. The app's purpose is to match users to candidate positions on issues — not tribal affiliation. Removing party display keeps the focus on what candidates say, not what team they're on.
Output: Two modified components with zero party text in rendered output.
</objective>

<execution_context>
@/Users/chrisandrews/.claude/get-shit-done/workflows/execute-plan.md
@/Users/chrisandrews/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@/Users/chrisandrews/Documents/GitHub/EV-readrank/src/components/ResultsPhase.tsx
@/Users/chrisandrews/Documents/GitHub/EV-readrank/src/components/CandidateAlignmentPage.tsx
</context>

<tasks>

<task type="auto">
  <name>Task 1: Remove party label from ResultsPhase quote cards</name>
  <files>EV-readrank/src/components/ResultsPhase.tsx</files>
  <action>
    In the `QuoteResultCard` component (around lines 117–145):

    1. Delete the `getPartyColor` function entirely (lines 117–122). It exists only to color party text.

    2. In the JSX header block (around line 142–146), remove the entire party display line:
       ```tsx
       <span className="text-gray-300">•</span>
       <span className={`font-medium ${getPartyColor(candidate.party)}`}>{candidate.party}</span>
       ```
       The separator bullet (`•`) should also be removed since it only exists to separate office from party. The remaining line should show only `candidate.office` without the bullet and party span.

    Result: The candidate info block shows name + office only. No party text, no color function.
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub/EV-readrank && grep -n "party\|getPartyColor\|Democrat\|Republican\|Libertarian" src/components/ResultsPhase.tsx</automated>
  </verify>
  <done>grep returns zero matches for party-related content in ResultsPhase.tsx</done>
</task>

<task type="auto">
  <name>Task 2: Remove party label from CandidateAlignmentPage profile header</name>
  <files>EV-readrank/src/components/CandidateAlignmentPage.tsx</files>
  <action>
    In the candidate profile header section (around line 289):

    Remove this line:
    ```tsx
    <p className={`font-medium text-white/80`}>{candidate.party}</p>
    ```

    The header already shows `candidate.name` (line 285) and `candidate.office` (line 288). Removing the party `<p>` tag leaves name + office only. No other changes needed in this file.
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub/EV-readrank && grep -n "candidate\.party\|Democrat\|Republican\|Libertarian" src/components/CandidateAlignmentPage.tsx</automated>
  </verify>
  <done>grep returns zero matches for party-related content in CandidateAlignmentPage.tsx</done>
</task>

</tasks>

<verification>
Both verifications should produce no output (zero matches). The `party` field still exists in the store type and data layer — those are untouched. Only the two JSX render sites are removed.

Run a final combined check:
```bash
cd /Users/chrisandrews/Documents/GitHub/EV-readrank && grep -rn "getPartyColor\|candidate\.party" src/components/
```
Expected: no output.
</verification>

<success_criteria>
- `ResultsPhase.tsx` has no `getPartyColor` function and no `{candidate.party}` render
- `CandidateAlignmentPage.tsx` has no `{candidate.party}` render
- Both components still compile (no TypeScript errors from removing the render — the `party` field still exists on the type, it just isn't displayed)
- `npm run build` in EV-readrank completes without errors
</success_criteria>

<output>
After completion, create `.planning/quick/7-remove-party-mentions-from-ev-readrank-r/7-SUMMARY.md`
</output>
