---
phase: quick-5b
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - ev-ui/src/PoliticianProfile.jsx
  - essentials/src/pages/CandidateProfile.jsx
autonomous: false
requirements: [BANNER-SLOT, CANDIDATE-BANNER-INSIDE-CARD]
---

<objective>
Polish candidate profile: move the yellow election callout INSIDE the PoliticianProfile card by adding a `banner` slot prop to PoliticianProfile in ev-ui. CandidateProfile in essentials passes the election banner via this prop instead of rendering it above the card.

Purpose: Visual polish — the election info belongs inside the profile card, not floating above it.
Output: Banner renders inside PoliticianProfile card, between heroRow and contact section.
</objective>

<execution_context>
@/Users/chrisandrews/.claude/get-shit-done/workflows/execute-plan.md
@/Users/chrisandrews/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/quick/5-create-candidate-profile-system-with-com/HANDOFF.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add banner prop to PoliticianProfile in ev-ui and move election callout inside card</name>
  <files>
    ev-ui/src/PoliticianProfile.jsx
    essentials/src/pages/CandidateProfile.jsx
  </files>
  <action>
**1a. Add `banner` prop to PoliticianProfile** (ev-ui/src/PoliticianProfile.jsx):

In the component signature (line 204), add `banner` to the destructured props:
```jsx
export default function PoliticianProfile({
  politician = {},
  onBack,
  backLabel,
  children,
  banner,        // NEW: slot for injecting content inside the card after heroRow
  style = {},
  legislativeSummary,
  politicianId,
  onNavigateToRecord,
}) {
```

In the render section, insert `{banner}` inside the card div, right after the heroRow closing `</div>` (after line 622) and before the Contact Info section:
```jsx
        </div>  {/* end heroRow */}

        {/* Banner slot (e.g. candidate election info) */}
        {banner}

        {/* ── Section 2: Contact Info ── */}
```

Then build ev-ui:
```bash
cd /Users/chrisandrews/Documents/GitHub/ev-ui && npm run build
```

**1b. Update CandidateProfile.jsx** (essentials/src/pages/CandidateProfile.jsx):

Move the yellow election banner from ABOVE the PoliticianProfile component into its `banner` prop.

Current code renders the banner div before PoliticianProfile (lines 88-108).
Remove the banner div from its current location. Instead, pass it as the `banner` prop on PoliticianProfile:

```jsx
<PoliticianProfile
  politician={pol}
  onBack={...}
  backLabel={...}
  banner={
    activeElection ? (
      <div
        style={{
          borderLeft: '4px solid #fed12e',
          backgroundColor: '#fffef5',
          borderRadius: '0 8px 8px 0',
          padding: '12px 16px',
          marginTop: '16px',
          fontFamily: "'Manrope', sans-serif",
        }}
      >
        <p style={{ margin: 0, fontWeight: 700, fontSize: '15px', color: '#2d3748' }}>
          Candidate for {activeElection.position_name || pol.office_title}
        </p>
        {activeElection.election_date && (
          <p style={{ margin: '4px 0 0', fontSize: '13px', color: '#718096' }}>
            Election: {formatElectionDateFull(activeElection.election_date)}
          </p>
        )}
      </div>
    ) : null
  }
  legislativeSummary={legislativeSummary}
  politicianId={id}
  onNavigateToRecord={(href) => navigate(href)}
/>
```

Note: change `marginBottom: '16px'` to `marginTop: '16px'` since the banner is now inside the card after the heroRow.

Build essentials:
```bash
cd /Users/chrisandrews/Documents/GitHub/essentials && npm run build
```
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub/ev-ui && npm run build 2>&1 && cd /Users/chrisandrews/Documents/GitHub/essentials && npm run build 2>&1</automated>
  </verify>
  <done>
    - PoliticianProfile accepts `banner` prop and renders it inside the card after heroRow
    - CandidateProfile passes election callout as banner prop instead of rendering it above the card
    - Both ev-ui and essentials build successfully
  </done>
</task>

</tasks>

<verification>
- `cd ev-ui && npm run build` succeeds
- `cd essentials && npm run build` succeeds
- PoliticianProfile.jsx has `banner` in props and renders `{banner}` inside card
- CandidateProfile.jsx no longer renders banner div above PoliticianProfile
- CandidateProfile.jsx passes banner as prop to PoliticianProfile
</verification>

<output>
After completion, update `.planning/quick/5-create-candidate-profile-system-with-com/5-SUMMARY.md`
</output>
