# Quick Task 260418-tqy: Elections Tab Label and Glowing Dot Fix - Context

**Gathered:** 2026-04-19
**Status:** Ready for planning

<domain>
## Task Boundary

Two fixes to the Elections tab in `essentials/src/pages/Results.jsx`:

1. **Tab label enhancement** — instead of just "Elections", show state + election type + date.
2. **Glowing dot fix** — dot currently only appears after clicking the tab (lazy-load bug); also needs actual pulse animation.

</domain>

<decisions>
## Implementation Decisions

### Tab label format
- **Desktop:** Full label — "Elections - Indiana Primary · May 6, 2026"
- **Mobile:** Truncate to just "Elections" (responsive via Tailwind)
- Format: `Elections - {StateName} {ElectionType} · {Date}`
- Capitalize election type (primary → Primary, general → General, special → Special)

### Which election to feature in label
- Show the **next upcoming** election (nearest future date)
- If multiple elections exist, compare dates and pick the soonest
- If no upcoming elections, fall back to showing "Elections" (plain label)

### State name in label
- **Include state name** — e.g., "Indiana" — even though user searched by address
- Source: needs to come from address data available in Results.jsx context (check how address/jurisdiction state is stored after search)

### Glowing dot behavior
- **Eager-load elections data** on address search (same time as politicians fetch), not lazily on tab click
- Add `animate-pulse` to the dot span so it actually glows/pulses
- Dot color stays `#FED12E` (ev-yellow)

### Claude's Discretion
- Exact abbreviated date format (e.g., "May 6, 2026" vs "May 6" vs "May 6 '26") — use "MMM D, YYYY" (e.g., "May 6, 2026") matching the existing `election_date` format from the API
- How to derive state name if not directly available in election object — use address state field from Results.jsx search data
- Mobile breakpoint for truncation — use `sm:` (640px) as the cutoff (hidden on xs, visible on sm+)

</decisions>

<specifics>
## Specific Requirements

- Election data fields available: `election_date` (e.g., "May 6, 2026"), `election_type` ('primary'|'general'|'special'), races array
- Current dot: `<span className="w-2 h-2 rounded-full bg-[#FED12E] ml-1" />` — add `animate-pulse`
- Current lazy-load: elections API called inside `switchView('elections')` handler — move call to address search completion handler
- API endpoints: `/essentials/elections/me` (auth) and `/essentials/elections-by-address` (public)

</specifics>

<canonical_refs>
## Canonical References

- Tab component: `essentials/src/pages/Results.jsx` lines 827-854
- Elections view: `essentials/src/components/ElectionsView.jsx`
- API calls: `essentials/src/lib/api.jsx` lines 286-311
- Color tokens: `essentials/src/index.css` lines 6-8

</canonical_refs>
