---
phase: 260418-tqy
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - essentials/src/pages/Results.jsx
autonomous: false
requirements:
  - TQY-01
  - TQY-02
  - TQY-03
  - TQY-04

must_haves:
  truths:
    - "When user searches an address, the elections data fetches eagerly alongside politicians (not lazily on tab click)"
    - "The yellow dot appears next to the Elections tab as soon as elections data returns, before the user clicks the tab"
    - "The yellow dot visibly pulses (animate-pulse)"
    - "On desktop (sm:+), the Elections tab label shows 'Elections - {StateName} {Type} · {Date}' for the next upcoming election"
    - "On mobile (<sm), the Elections tab label shows plain 'Elections'"
    - "When no upcoming elections exist, the tab falls back to plain 'Elections'"
  artifacts:
    - path: "essentials/src/pages/Results.jsx"
      provides: "Elections tab with eager-load, pulsing dot, and enhanced responsive label"
  key_links:
    - from: "activeQuery change (address search complete)"
      to: "fetchElectionsByAddress"
      via: "useEffect firing on activeQuery, not activeView"
      pattern: "useEffect.*activeQuery.*fetchElectionsByAddress"
    - from: "electionsData array"
      to: "tab label derivation"
      via: "useMemo selecting next upcoming election + formatting label"
      pattern: "electionsData.*filter.*election_date"
---

<objective>
Two fixes to the Elections tab in essentials/src/pages/Results.jsx:
1. **Eager-load fix:** Fetch elections data when address search completes (not on tab click) so the yellow "new content" dot appears immediately. Add `animate-pulse` so the dot actually glows.
2. **Label enhancement:** On desktop, show the next upcoming election in the tab label: "Elections - Indiana Primary · May 6, 2026". On mobile, keep plain "Elections".

Purpose: Signal to users that election content is available without requiring them to click the tab to discover it. Make the indicator visually active (pulsing).
Output: Updated Results.jsx with eager-fetch useEffect, pulsing dot span, and responsive tab label derived from the next upcoming election.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
</execution_context>

<context>
@essentials/src/pages/Results.jsx
@essentials/src/lib/api.jsx
@essentials/src/components/ElectionsView.jsx
@.planning/quick/260418-tqy-elections-tab-label-and-glowing-dot-fix-/260418-tqy-CONTEXT.md

<interfaces>
Key data/functions already present in Results.jsx:

- `activeQuery` — the decoded query string from URL (address). Triggers data fetches when changed.
- `electionsData` / `setElectionsData` — state holding `election[]` array or null before fetch
- `electionsLoading` / `setElectionsLoading` — loading flag
- `fetchElectionsByAddress(address)` — returns `{ elections: [...], error }`. Each election has `election_date` (ISO string like "2026-05-06"), `election_type` ('primary'|'general'|'special'), `races`.
- `userState` — two-letter state abbreviation (e.g. "IN") already derived via `parseStateFromAddress(addressInput)`
- `formattedAddress` — backend-validated address, available after search
- `activeView` — current tab ('representatives' or 'elections')

Current lazy-load useEffect (lines 386-402) — gates on `activeView === 'elections'`. Needs to be changed to gate on `activeQuery` only.

Current tab render (lines 840-852) — shows static "Elections" text plus a static dot. Needs responsive label + animate-pulse.

State name mapping: `userState` gives abbreviation ("IN"). Need full name ("Indiana") for the label. Use the existing STATE_ABBREVS set conceptually, but we need a reverse map abbrev→full. Add a small local const map (all 50 + DC).
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Eager-load elections data and add pulsing dot</name>
  <files>essentials/src/pages/Results.jsx</files>
  <action>
Change the elections-fetch useEffect (currently lines 386-402) so it fires on address search completion instead of lazily on tab click:

1. Remove the `activeView !== 'elections'` guard. The new guard: fire when `activeQuery` is present AND `electionsData === null` (not yet loaded for this query).
2. The reset effect (lines 404-407) that clears electionsData on `activeQuery` change stays as-is — it ensures re-fetch on new address.
3. Net effect: as soon as an address search begins (activeQuery set), the elections effect also fires alongside the politicians fetch.

Updated effect shape:
```jsx
useEffect(() => {
  if (!activeQuery) return;
  if (electionsData !== null) return; // already loaded for this query

  let cancelled = false;
  setElectionsLoading(true);

  fetchElectionsByAddress(decodeURIComponent(activeQuery)).then((data) => {
    if (!cancelled) {
      setElectionsData(data.elections || []);
      setElectionsLoading(false);
    }
  });

  return () => { cancelled = true; };
}, [activeQuery]); // eslint-disable-line react-hooks/exhaustive-deps
```

Then update the dot span (line 850) to add `animate-pulse`:
```jsx
<span className="w-2 h-2 rounded-full bg-[#FED12E] ml-1 animate-pulse" />
```

Keep the existing conditional `{electionsData && electionsData.length > 0 && (...)}` — dot only shows when there is real elections data.
  </action>
  <verify>
    <automated>cd essentials && npm run build 2>&1 | tail -20</automated>
  </verify>
  <done>
- Elections data fetches immediately after address search (verifiable: the dot appears on the Elections tab before the user clicks it)
- Dot visually pulses via animate-pulse class
- Build passes without errors
- No lint/compile warnings introduced
  </done>
</task>

<task type="auto">
  <name>Task 2: Derive and render responsive tab label for next upcoming election</name>
  <files>essentials/src/pages/Results.jsx</files>
  <action>
Add a state-abbreviation-to-full-name map and a useMemo that derives the tab label suffix from the next upcoming election.

**Step 1** — Add a STATE_NAMES const near the existing `STATE_ABBREVS` set (around line 55). Full map for all 50 states + DC, e.g.:
```js
const STATE_NAMES = {
  AL: 'Alabama', AK: 'Alaska', AZ: 'Arizona', AR: 'Arkansas',
  CA: 'California', CO: 'Colorado', CT: 'Connecticut', DE: 'Delaware',
  FL: 'Florida', GA: 'Georgia', HI: 'Hawaii', ID: 'Idaho',
  IL: 'Illinois', IN: 'Indiana', IA: 'Iowa', KS: 'Kansas',
  KY: 'Kentucky', LA: 'Louisiana', ME: 'Maine', MD: 'Maryland',
  MA: 'Massachusetts', MI: 'Michigan', MN: 'Minnesota', MS: 'Mississippi',
  MO: 'Missouri', MT: 'Montana', NE: 'Nebraska', NV: 'Nevada',
  NH: 'New Hampshire', NJ: 'New Jersey', NM: 'New Mexico', NY: 'New York',
  NC: 'North Carolina', ND: 'North Dakota', OH: 'Ohio', OK: 'Oklahoma',
  OR: 'Oregon', PA: 'Pennsylvania', RI: 'Rhode Island', SC: 'South Carolina',
  SD: 'South Dakota', TN: 'Tennessee', TX: 'Texas', UT: 'Utah',
  VT: 'Vermont', VA: 'Virginia', WA: 'Washington', WV: 'West Virginia',
  WI: 'Wisconsin', WY: 'Wyoming', DC: 'District of Columbia',
};
```

**Step 2** — Add a useMemo inside Results() (near the other useMemos, e.g. after `userState`) that picks the next upcoming election and builds the label suffix:
```jsx
const electionsLabelSuffix = useMemo(() => {
  if (!electionsData || electionsData.length === 0) return null;
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const upcoming = electionsData
    .filter((e) => {
      if (!e.election_date) return false;
      const d = new Date(e.election_date + 'T12:00:00');
      return d >= today;
    })
    .sort((a, b) => new Date(a.election_date) - new Date(b.election_date));

  if (upcoming.length === 0) return null;
  const next = upcoming[0];

  const stateName = userState ? (STATE_NAMES[userState] || '') : '';
  const typeRaw = next.election_type || '';
  const typeCap = typeRaw ? typeRaw.charAt(0).toUpperCase() + typeRaw.slice(1).toLowerCase() : '';
  const dateStr = new Date(next.election_date + 'T12:00:00').toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });

  const parts = [stateName, typeCap].filter(Boolean).join(' ');
  if (!parts && !dateStr) return null;
  return `${parts} · ${dateStr}`;
}, [electionsData, userState]);
```

**Step 3** — Update the Elections tab button render (currently lines 840-852) to show plain "Elections" on mobile and the full label on desktop:
```jsx
<button
  className={`px-4 py-3 text-sm min-h-[44px] transition-colors flex items-center gap-1 ${
    activeView === 'elections'
      ? 'text-[#00657C] font-semibold border-b-2 border-[#00657C]'
      : 'text-[#718096] font-normal hover:text-[#4A5568]'
  }`}
  onClick={() => switchView('elections')}
>
  <span className="sm:hidden">Elections</span>
  <span className="hidden sm:inline">
    {electionsLabelSuffix ? `Elections - ${electionsLabelSuffix}` : 'Elections'}
  </span>
  {electionsData && electionsData.length > 0 && (
    <span className="w-2 h-2 rounded-full bg-[#FED12E] ml-1 animate-pulse" />
  )}
</button>
```

Label format examples:
- Full: "Elections - Indiana Primary · May 6, 2026"
- No state (address parse failed): "Elections - Primary · May 6, 2026"
- No upcoming elections: "Elections"
- Mobile: always "Elections"
  </action>
  <verify>
    <automated>cd essentials && npm run build 2>&1 | tail -20</automated>
  </verify>
  <done>
- STATE_NAMES map present with all 50 states + DC
- electionsLabelSuffix useMemo picks the soonest-future election and formats the suffix
- Tab button renders plain "Elections" on mobile (<640px) and full label on desktop (>=640px)
- Falls back to plain "Elections" when no upcoming elections exist
- Build passes without errors
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 3: Verify tab label + pulsing dot in browser</name>
  <what-built>
Elections tab now fetches data eagerly on address search (not on tab click), shows a pulsing yellow dot when elections exist, and displays a responsive label with the next upcoming election's state + type + date on desktop.
  </what-built>
  <how-to-verify>
1. `cd essentials && npm run dev`
2. Open http://localhost:5173 (or whatever port Vite picks) in a desktop-width browser
3. Search an address with known upcoming elections (e.g. "200 W Kirkwood Ave, Bloomington, IN, 47404")
4. BEFORE clicking the Elections tab, confirm:
   - Yellow dot appears next to the Elections tab label within ~1-2s of the politicians loading
   - Dot is visibly pulsing (animate-pulse: opacity fades in/out)
   - Tab label reads "Elections - Indiana Primary · May 6, 2026" (or similar — next upcoming election for that address)
5. Resize browser below 640px (or use device toolbar to mobile width):
   - Tab label should truncate to just "Elections"
   - Dot should still be visible and pulsing
6. Search an address with no upcoming elections (if available) or confirm fallback:
   - Tab should show plain "Elections" with no dot
  </how-to-verify>
  <resume-signal>Type "approved" or describe any issues (e.g. label wrong, dot not pulsing, mobile truncation broken)</resume-signal>
</task>

</tasks>

<verification>
- Build: `cd essentials && npm run build` passes
- Visual/functional: human verification per Task 3
- No regression in Representatives tab (tab switching still works, data still loads)
</verification>

<success_criteria>
1. Elections data fetches on address search completion (verified by dot appearing before tab click)
2. Dot pulses via Tailwind animate-pulse
3. Desktop tab label includes state name + capitalized election type + formatted date
4. Mobile tab label is plain "Elections"
5. Fallback to plain "Elections" when no upcoming elections
6. No build errors, no runtime console errors
</success_criteria>

<output>
After completion, append to .planning/STATE.md Quick Tasks Completed table.
</output>
