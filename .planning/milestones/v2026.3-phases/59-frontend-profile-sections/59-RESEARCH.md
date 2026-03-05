# Phase 59: Frontend Profile Sections - Research

**Researched:** 2026-03-03
**Domain:** React component library (ev-ui) + React SPA (essentials app) — legislative data display
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Section layout & placement**
- Two-tier design: Inline summary embedded in the existing profile card (below bio/contact), plus a full legislative record on a separate page at `/politician/:id/record`
- Inline summary includes: topic tags, key stats (attendance %, bills advanced, leadership roles — whatever is available), most recent notable action in plain language, and a "View Full Legislative Record" link
- Topic tags should align with compass issue categories (citizen-friendly language like "Housing", "Climate", "Transit") — the mapping table is deferred, but the UI slot for tags should exist
- Stats show whatever is available and skip the rest — no N/A placeholders or empty stat slots
- Full record page section order: Committees & Leadership first, Sponsored Legislation second, Voting Record third
- Full record page uses nested route: `/politician/:id/record`
- Build so it works with either UUID or future slug-based URLs — no hardcoded assumptions about ID format

**Data density (full record page)**
- Committees: Name + role badge (Chair/Member/etc), flat list. No subcommittee grouping, chamber labels, or dates for now
- Voting record: Bill title/description + date + position badge (Yea/Nay) + overall outcome (Passed/Failed) + clickable link to source
- Sponsored legislation: Bill number + title + status badge + introduction date + sponsor/cosponsor indicator. No inline summaries
- Default 20-25 items per section, "Show all" link to expand and load the full history

**Empty state design**
- Inline summary on profile card only renders when at least some legislative data exists — politicians with zero legislative data see the profile exactly as it is today
- "View Full Legislative Record" link appears whenever any legislative data exists, even if partial
- Full record page always shows all three section headers
- Empty sections display a brief factual/informative note — e.g., "Voting records are not available for this office"
- Tone: clear, concise, explains the gap without jargon

**Year filter (replaces session toggle)**
- No session toggle — year dropdown filter on Votes and Bills sections only
- Default selection: "All" with items sorted most recent first
- Year options populated from the data (e.g., 2026, 2025, 2024)
- The 20-25 item default cap keeps "All" manageable; "Show all" expands within the selected year filter

### Claude's Discretion
- Exact inline summary layout and spacing within the profile card
- How topic tag pills are styled (colors, shapes — reference the screenshot for inspiration but don't replicate exactly)
- Loading states for the parallel API fetches
- How the "Show all" expansion works (append to list vs full page load)
- Empty state message wording per jurisdiction (as long as tone matches: factual, concise, informative)
- How year dropdown interacts with "Show all" (filter first, then expand — or expand then filter)

### Deferred Ideas (OUT OF SCOPE)
- Slug-based politician URLs — Replace `/politician/:uuid` with `/politician/:name-state`
- Topic tag mapping table — Mapping from Congress.gov bill subjects and committee names to compass issue categories
- Bill detail view — Expandable or linked view showing CRS plain-language summaries
- Subcommittee grouping — Group subcommittees under parent committees
- Compass category alignment audit
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| UI-01 | Committees & Leadership section on politician profile showing current committee assignments with roles and any leadership positions | API endpoint `/politician/{id}/committees` returns `LegislativeCommitteeAssignmentOut[]` with `committee_name`, `role`, `is_current`, `parent_name`. Leadership endpoint returns `LegislativeLeadershipRoleOut[]`. New `LegislativeActivity` component in ev-ui renders both. |
| UI-02 | Voting Record section showing recent votes with bill title/summary, politician's position (yea/nay/etc), and overall outcome | API endpoint `/politician/{id}/votes` returns `LegislativeVoteOut[]` with `vote_question`, `position`, `vote_date`, `result`, `bill_title`, `bill_url`. Year filter UI in `LegislativeRecord.jsx` page. |
| UI-03 | Sponsored Legislation section showing bills with number, title, status, and introduction date | API endpoint `/politician/{id}/bills` returns `LegislativeBillOut[]` with `number`, `title`, `status_label`, `introduced_at`, `is_sponsor`. Status badge component needed. Year filter UI shared with votes. |
| UI-04 | All legislative sections gracefully show empty states when data unavailable for a given government level | `legislative-summary` endpoint returns empty arrays for politicians with no data. Inline summary hidden when both arrays empty. Full record page always shows section headers with factual empty-state messages. |
| UI-05 | Session filter (year dropdown) lets users toggle between current and previous session data | Year options derived from `introduced_at` (bills) and `vote_date` (votes) in fetched data. Dropdown state controls client-side filter. No backend param needed — filter is client-side from the fetched dataset. |
</phase_requirements>

---

## Summary

Phase 59 is a pure frontend build with all five backend API endpoints already implemented and deployed. The work splits cleanly into two deliverables: (1) new ev-ui components published as a new package version, and (2) integration into the essentials app.

The ev-ui library contains the canonical display components (`PoliticianProfile`, `CommitteeTable`, `IssueTags`, `tokens.js`). All new legislative display components must be added here, built with inline styles using `tokens.js` design tokens — **not** Tailwind classes. The essentials app consumes the published ev-ui package and handles routing, API fetching, and the new `/politician/:id/record` route.

The key architectural decision is placement: a `LegislativeInlineSummary` sub-component gets embedded inside `PoliticianProfile.jsx` (below bio/contact, above the children slot), and a standalone `LegislativeRecord` page component lives in the essentials app at the new nested route. The inline summary uses the `/legislative-summary` endpoint (returns 5 bills + 10 votes), while the full record page uses the individual `/committees`, `/leadership`, `/bills`, and `/votes` endpoints with parallel fetching.

**Primary recommendation:** Build `LegislativeInlineSummary` and `LegislativeRecord` as new ev-ui components in 59-01, then wire up routes, API functions, and the new `LegislativeRecord` page in 59-02.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React | 19.1.1 | Component rendering | Already in both ev-ui and essentials |
| react-router-dom | 7.8.2 | Nested routing for `/politician/:id/record` | Already in essentials app |
| ev-ui tokens.js | — | Design tokens (colors, spacing, fonts) | All ev-ui components use inline styles with these tokens |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| useMediaQuery (ev-ui hook) | — | Responsive layout switching | Mobile vs desktop layout in new components |
| tsup | ^8.0.0 | ev-ui build (ESM + CJS) | Used for `npm run build` in ev-ui |

### No New Libraries Needed
The entire phase can be implemented with existing dependencies. No new npm packages required in either ev-ui or essentials.

**Installation:** None required.

---

## Architecture Patterns

### Recommended File Structure

**ev-ui additions:**
```
ev-ui/src/
├── LegislativeInlineSummary.jsx   # NEW: inline summary block for profile card
├── LegislativeRecord.jsx          # NEW: full legislative record page component
├── PoliticianProfile.jsx          # MODIFIED: embeds LegislativeInlineSummary
├── index.js                       # MODIFIED: export new components
```

**essentials app additions:**
```
essentials/src/
├── pages/
│   └── LegislativeRecord.jsx      # NEW: route page wrapping ev-ui LegislativeRecord component
├── lib/
│   └── api.jsx                    # MODIFIED: add legislative fetch functions
├── App.jsx                        # MODIFIED: add nested route
```

### Pattern 1: Inline Styles with Tokens (ev-ui standard)

All ev-ui components use inline styles with imported tokens — never Tailwind classes. This is mandatory for library components that must work outside Tailwind contexts.

```jsx
// Source: ev-ui/src/PoliticianProfile.jsx (verified in codebase)
import { colors, fonts, fontWeights, fontSizes, spacing, borderRadius, shadows } from './tokens';

const styles = {
  container: {
    fontFamily: fonts.primary,
    background: colors.bgWhite,
    borderRadius: borderRadius.lg,
    padding: spacing[4],
  },
  badge: {
    display: 'inline-flex',
    padding: `${spacing[1]} ${spacing[3]}`,
    borderRadius: borderRadius.full,
    fontSize: fontSizes.xs,
    fontWeight: fontWeights.semibold,
    backgroundColor: colors.evTeal,
    color: colors.textWhite,
  },
};
```

**Anti-pattern:** `className="rounded-full bg-[#00657c] text-white"` — do not use Tailwind inside ev-ui components.

### Pattern 2: Conditional Rendering for Empty States

The inline summary must not render at all when no data exists (so local politicians see the exact same profile card as today). The full record page always renders all three section headers.

```jsx
// Inline summary — render nothing if no legislative data
const hasLegislativeData = summary.recent_bills.length > 0 || summary.recent_votes.length > 0;
if (!hasLegislativeData) return null;

// Full record page — always render section headers, conditionally render content
<section>
  <h2>Committees & Leadership</h2>
  {committees.length === 0
    ? <EmptyStateMessage message="Committee information is not available for this office." />
    : <CommitteeRoleList committees={committees} />
  }
</section>
```

### Pattern 3: Parallel API Fetches

The full record page needs 4 endpoints. Use `Promise.all` for parallel fetching — do not chain them sequentially.

```jsx
// Source: Established pattern from Profile.jsx parallel fetch structure
useEffect(() => {
  if (!id) return;
  setLoading(true);
  Promise.all([
    fetchLegislativeCommittees(id),
    fetchLegislativeLeadership(id),
    fetchLegislativeBills(id),
    fetchLegislativeVotes(id),
  ])
    .then(([committees, leadership, bills, votes]) => {
      setCommittees(committees);
      setLeadership(leadership);
      setBills(bills);
      setVotes(votes);
    })
    .catch(err => console.error(err))
    .finally(() => setLoading(false));
}, [id]);
```

### Pattern 4: Nested Route in React Router v7

The essentials app uses `react-router` v7 (imported as `'react-router-dom'` in page files but `'react-router'` in `main.jsx`). Both import paths resolve to the same package. The nested route `/politician/:id/record` requires a parent `<Route>` wrapper with an `<Outlet>` — but since Profile.jsx currently does not render an Outlet, the cleanest approach is a **sibling flat route** at the same level, not a true nested route that renders inside Profile.

```jsx
// Source: essentials/src/App.jsx pattern + react-router docs
// In App.jsx — add as a sibling route (flat, not nested):
<Route path="/politician/:id" element={<Profile />} />
<Route path="/politician/:id/record" element={<LegislativeRecordPage />} />
```

This is the correct approach because Profile.jsx does not render an `<Outlet>`. The "nested route" in the user's decision means a URL path nesting, not a layout nesting. The legislative record page is a standalone full page (with its own Header), not a sub-panel inside the profile card.

### Pattern 5: Year Filter (Client-Side)

Year options are derived from the data itself — no backend parameter needed. Extract unique years from `introduced_at` (bills) and `vote_date` (votes), sort descending, prepend "All".

```jsx
const years = useMemo(() => {
  const yearSet = new Set();
  bills.forEach(b => { if (b.introduced_at) yearSet.add(b.introduced_at.slice(0, 4)); });
  return ['All', ...Array.from(yearSet).sort((a, b) => b - a)];
}, [bills]);

const filteredBills = useMemo(() => {
  if (selectedYear === 'All') return bills;
  return bills.filter(b => b.introduced_at?.startsWith(selectedYear));
}, [bills, selectedYear]);
```

### Pattern 6: Role Badge Normalization

The `/committees` endpoint returns `role` values: `"member"`, `"chair"`, `"vice_chair"`, `"ranking_member"`, `"ex_officio"`. Normalize to display labels with appropriate color coding.

```jsx
const ROLE_LABELS = {
  chair: 'Chair',
  vice_chair: 'Vice Chair',
  ranking_member: 'Ranking Member',
  ex_officio: 'Ex Officio',
  member: 'Member',
};

const ROLE_COLORS = {
  chair: colors.evCoral,         // prominent
  vice_chair: colors.evTealLight,
  ranking_member: colors.evTeal,
  ex_officio: colors.textMuted,
  member: colors.borderMedium,   // subdued
};
```

### Pattern 7: Derived Stats for Inline Summary

The inline summary stats (attendance %, bills advanced, leadership) are derived from the `/legislative-summary` response — not hardcoded.

```
attendance %   = (votes where position != 'Not Voting' AND position != 'Absent') / total votes
bills advanced = count of recent_bills (already filtered to exclude "Introduced" by backend)
leadership     = derived from leadership endpoint — but inline summary uses /legislative-summary
                 which does NOT include leadership; leadership requires separate fetch or skip
```

Important: `/legislative-summary` returns only `recent_bills` and `recent_votes`. Leadership roles require a separate call to `/politician/{id}/leadership`. For the inline summary, the stat line should show attendance + bills advanced from the summary data, and derive "has leadership role" only if leadership data has already been fetched separately. Given the CONTEXT decision that "stats show whatever is available and skip the rest," the safest approach is: inline summary fetches `/legislative-summary` only, skips leadership stat, and shows a "View Full Legislative Record" link.

### Anti-Patterns to Avoid

- **Tailwind in ev-ui components:** All ev-ui components use inline styles with tokens. Never add Tailwind classNames inside ev-ui.
- **Sequential API fetches:** Chaining 4 await calls adds latency. Use `Promise.all`.
- **Hardcoding UUID format:** The route uses `:id` — treat it as an opaque string, never call `uuid.Parse` or assume format client-side.
- **Empty stat slots with "N/A":** The CONTEXT decision is explicit — show nothing when a stat is unavailable, not a placeholder.
- **Rendering inline summary for politicians with no data:** Local politicians (school board, sheriffs, etc) must see the exact same profile as today. Guard with `hasLegislativeData` check.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Status badge colors for bills | Custom status-to-color map from scratch | Define a small `STATUS_COLORS` object using ev-ui tokens | Status labels come from backend (`Introduced`, `Passed House`, `Became Law`, etc.) — a simple lookup map is sufficient |
| Date formatting | Custom date parser | `new Date(dateStr).toLocaleDateString('en-US', ...)` | Already used in PoliticianProfile.jsx; be aware of year-only timezone bug (use `.slice(0,4)` for year extraction) |
| Responsive media queries | Custom resize listener | `useMediaQuery` hook from ev-ui | Already exported from ev-ui, handles SSR safely |
| "Show all" pagination | Complex pagination state | Simple `showAll` boolean state + slice | 20-25 default cap; `showAll ? data : data.slice(0, 25)` |

**Key insight:** This phase is UI assembly, not infrastructure. The data model, API, and component library patterns are all established. The work is connecting dots, not inventing new patterns.

---

## Common Pitfalls

### Pitfall 1: Year-Only Date Parsing (Timezone Bug)
**What goes wrong:** `new Date("2024")` parses as midnight UTC Jan 1, which displays as "Dec 2023" in US timezones.
**Why it happens:** ISO 8601 treats bare year strings as UTC midnight.
**How to avoid:** For year extraction, use `dateStr.slice(0, 4)` not `new Date(dateStr).getFullYear()`. For display, the existing `formatTermDate` function in PoliticianProfile.jsx handles this with a precision flag — follow the same pattern.
**Warning signs:** Bills from 2024 showing year as 2023 in the year filter dropdown.

### Pitfall 2: ev-ui Version Bump Workflow
**What goes wrong:** New ev-ui components aren't visible in the essentials app because the published package version hasn't been bumped and re-published.
**Why it happens:** essentials/package.json pins `"@chrisandrewsedu/ev-ui": "^0.1.36"`. Even with `^` (minor-compatible), the local node_modules won't update until you `npm install` after a new version is published.
**How to avoid:** Plan 59-01 (ev-ui work) must end with: bump version in package.json, `npm run build`, publish to GitHub npm registry. Plan 59-02 (essentials work) starts with `npm install` to pull the new version.
**Warning signs:** Importing new components from ev-ui throws "Module not found" or exports undefined.

### Pitfall 3: CommitteeTable Conflict
**What goes wrong:** `PoliticianProfile.jsx` already renders `CommitteeTable` (the BallotReady committees from `pol.committees`). The new legislative committees are different data from a different endpoint. If both render, users see duplicate "Committee Memberships" sections.
**Why it happens:** The existing `CommitteeTable` in `PoliticianProfile.jsx` uses `pol.committees` (BallotReady data: `[{name, position, url}]`). The new `LegislativeInlineSummary` will receive legislative committee data from the summary endpoint.
**How to avoid:** The inline summary should NOT duplicate the existing `CommitteeTable`. The existing committee display is BallotReady data (broader committee memberships, often empty for local officials). The legislative committees are richer role-tagged data from the federal/state import. They are complementary, not duplicate — but visually they should not appear as two "Committee" sections on the same card. One option: remove the existing `CommitteeTable` from `PoliticianProfile.jsx` and replace it entirely with the legislative data in the inline summary. Confirm this decision during plan 59-01 — the CONTEXT says `CommitteeTable` "may be replaced or extended."
**Warning signs:** Two "Committee Memberships" sections appearing on a federal politician's profile card.

### Pitfall 4: react-router Import Path Inconsistency
**What goes wrong:** `main.jsx` imports `BrowserRouter` from `'react-router'` while page components import hooks from `'react-router-dom'`. Both resolve correctly in v7 (react-router-dom re-exports from react-router), but mixing them is inconsistent.
**Why it happens:** react-router v7 merged the packages; `react-router-dom` is now a thin re-export shim.
**How to avoid:** New page components should follow the existing convention — import hooks from `'react-router-dom'` to match `Profile.jsx`, `Results.jsx`, and `Landing.jsx`.
**Warning signs:** Not a runtime error — just a consistency issue.

### Pitfall 5: /legislative-summary Returns Empty for Non-Federal Politicians
**What goes wrong:** Calling `/legislative-summary` for a Bloomington city council member returns `{ recent_bills: [], recent_votes: [] }` — and if the component is not guarded, it renders an empty inline summary block with just a "View Full Legislative Record" link and no stats.
**Why it happens:** Local data pipeline (Phase 58) imported committees and legislation for Bloomington and LA County, but **no individual vote attribution** exists for local politicians (confirmed infeasible). Bills may exist for Bloomington but the summary query filters to "advanced" bills only.
**How to avoid:** The inline summary renders only when `recent_bills.length > 0 || recent_votes.length > 0`. A politician with only committee data (no bills/votes) will NOT show an inline summary — this is correct per CONTEXT. The "View Full Legislative Record" link should appear if `committees.length > 0` — but the summary endpoint doesn't return committees. Solution: the inline summary should check only bills/votes from `/legislative-summary`; if both are empty, render nothing including the link.
**Warning signs:** Local politicians showing a "View Full Legislative Record" link that leads to an empty record page.

---

## Code Examples

### API Functions to Add (essentials/src/lib/api.jsx)

```javascript
// Source: established fetchPolitician pattern in api.jsx
export async function fetchLegislativeSummary(id) {
  const res = await fetch(`${API}/essentials/politician/${id}/legislative-summary`, {
    credentials: "include",
  });
  if (!res.ok) return { recent_bills: [], recent_votes: [] };
  return res.json();
}

export async function fetchLegislativeCommittees(id) {
  const res = await fetch(`${API}/essentials/politician/${id}/committees`, {
    credentials: "include",
  });
  if (!res.ok) return [];
  return res.json();
}

export async function fetchLegislativeLeadership(id) {
  const res = await fetch(`${API}/essentials/politician/${id}/leadership`, {
    credentials: "include",
  });
  if (!res.ok) return [];
  return res.json();
}

export async function fetchLegislativeBills(id, { all = false, limit = 50 } = {}) {
  const params = new URLSearchParams();
  if (all) params.set('all', 'true');
  if (limit !== 50) params.set('limit', String(limit));
  const qs = params.toString() ? `?${params}` : '';
  const res = await fetch(`${API}/essentials/politician/${id}/bills${qs}`, {
    credentials: "include",
  });
  if (!res.ok) return [];
  return res.json();
}

export async function fetchLegislativeVotes(id, { limit = 50 } = {}) {
  const qs = limit !== 50 ? `?limit=${limit}` : '';
  const res = await fetch(`${API}/essentials/politician/${id}/votes${qs}`, {
    credentials: "include",
  });
  if (!res.ok) return [];
  return res.json();
}
```

### New Route in App.jsx

```jsx
// Source: essentials/src/App.jsx existing pattern
import LegislativeRecordPage from "./pages/LegislativeRecord";

function App() {
  return (
    <Routes>
      <Route path="/" element={<Landing />} />
      <Route path="/results" element={<Results />} />
      <Route path="/politician/:id" element={<Profile />} />
      <Route path="/politician/:id/record" element={<LegislativeRecordPage />} />
    </Routes>
  );
}
```

### LegislativeInlineSummary Structure (ev-ui component)

```jsx
// ev-ui/src/LegislativeInlineSummary.jsx — structure sketch
// Uses inline styles + tokens (no Tailwind)
export default function LegislativeInlineSummary({ summary, politicianId }) {
  const { recent_bills = [], recent_votes = [] } = summary || {};

  // Guard: render nothing if no legislative data
  if (recent_bills.length === 0 && recent_votes.length === 0) return null;

  // Derived stats
  const billsAdvanced = recent_bills.length; // backend already filters "Introduced"
  const totalVotes = recent_votes.length;
  const activeVotes = recent_votes.filter(
    v => v.position !== 'Not Voting' && v.position !== 'Absent' && v.position !== 'not_voting'
  ).length;
  const attendancePct = totalVotes > 0 ? Math.round((activeVotes / totalVotes) * 100) : null;

  // Most recent action
  const latestAction = recent_bills[0] || recent_votes[0] || null;

  return (
    <div style={styles.container}>
      {/* Topic tag pills slot (empty for now, populated when mapping table ships) */}
      {/* Stat line: only show stats that have real values */}
      <div style={styles.statsRow}>
        {attendancePct !== null && (
          <span style={styles.stat}>{attendancePct}% attendance</span>
        )}
        {billsAdvanced > 0 && (
          <span style={styles.stat}>{billsAdvanced} bills advanced</span>
        )}
      </div>
      {/* Most recent action */}
      {latestAction && <LatestActionLine item={latestAction} />}
      {/* Link to full record */}
      <a href={`/politician/${politicianId}/record`} style={styles.link}>
        View Full Legislative Record
      </a>
    </div>
  );
}
```

### Position Badge for Votes

```jsx
// Vote position badge using tokens
const POSITION_CONFIG = {
  'Yea': { label: 'Yea', bg: colors.success + '20', color: colors.success },
  'Nay': { label: 'Nay', bg: colors.error + '20', color: colors.error },
  'Not Voting': { label: 'Not Voting', bg: colors.borderLight, color: colors.textMuted },
  'Abstain': { label: 'Abstain', bg: colors.evYellowLight, color: colors.evYellowDark },
  'Absent': { label: 'Absent', bg: colors.borderLight, color: colors.textMuted },
};
// Normalize position values (backend may return "not_voting" or "Not Voting")
function normalizePosition(pos) {
  return (pos || '').replace(/_/g, ' ')
    .replace(/\b\w/g, c => c.toUpperCase());
}
```

### Status Badge for Bills

```jsx
// Bill status badges using tokens
const STATUS_CONFIG = {
  'Introduced': { color: colors.textMuted, bg: colors.borderLight },
  'Passed House': { color: colors.evTeal, bg: colors.bgLight },
  'Passed Senate': { color: colors.evTeal, bg: colors.bgLight },
  'Became Law': { color: colors.success, bg: colors.success + '15' },
  'Vetoed': { color: colors.error, bg: colors.error + '15' },
  'Failed': { color: colors.textMuted, bg: colors.borderLight },
};
// Fallback for unknown status labels
function getStatusConfig(label) {
  return STATUS_CONFIG[label] || { color: colors.textSecondary, bg: colors.borderLight };
}
```

---

## API Response Shapes (Verified from Backend Code)

These are the exact JSON shapes returned by the five endpoints. Verified from `handlers.go` type definitions.

### GET /politician/{id}/legislative-summary
```json
{
  "recent_bills": [
    {
      "external_id": "string",
      "number": "HR 1234",
      "title": "string",
      "summary": "string (omitempty)",
      "status_label": "Passed House",
      "introduced_at": "2024-03-15",
      "is_sponsor": true,
      "url": "string (omitempty)",
      "source": "congress.gov"
    }
  ],
  "recent_votes": [
    {
      "vote_question": "On Passage",
      "position": "Yea",
      "vote_date": "2024-03-15",
      "result": "Passed",
      "bill_title": "string (omitempty)",
      "bill_number": "string (omitempty)",
      "bill_url": "string (omitempty)",
      "source": "congress.gov"
    }
  ]
}
```

### GET /politician/{id}/committees
```json
[
  {
    "committee_name": "string",
    "role": "chair|vice_chair|ranking_member|member|ex_officio",
    "chamber": "House|Senate",
    "congress_number": 119,
    "is_current": true,
    "parent_name": "string (omitempty)",
    "committee_type": "committee|subcommittee|joint"
  }
]
```

### GET /politician/{id}/leadership
```json
[
  {
    "title": "Speaker of the House",
    "chamber": "House",
    "is_current": true,
    "start_date": "2023-01-03 (omitempty)",
    "end_date": "string (omitempty)"
  }
]
```

### GET /politician/{id}/bills
Same shape as `recent_bills` above. Supports `?limit=N` and `?all=true`.

### GET /politician/{id}/votes
Same shape as `recent_votes` above. Supports `?limit=N`.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Session toggle ("Current Session" / "Previous Session") | Year dropdown populated from data | Phase 59 design | More citizen-friendly; no jargon |
| CommitteeTable showing BallotReady position | Legislative committee list with role badges | Phase 59 | Richer data for federal/state politicians |
| Single profile page at `/politician/:id` | Two-tier: inline summary + `/politician/:id/record` | Phase 59 | Keeps profile card clean; full data on demand |

---

## Open Questions

1. **CommitteeTable replacement vs coexistence**
   - What we know: `PoliticianProfile.jsx` renders `CommitteeTable` from BallotReady data (`pol.committees`). The new `LegislativeInlineSummary` uses different legislative data. For federal politicians, both could have data.
   - What's unclear: Should the existing BallotReady committee section be removed when legislative committee data is present? Or kept as a separate source?
   - Recommendation: In 59-01, check whether any real federal politicians have both `pol.committees` populated AND legislative committee data. If BallotReady committees are always empty for federal politicians (likely), remove the `CommitteeTable` render from `PoliticianProfile.jsx` and rely on the inline summary + full record for that data. If BallotReady committees populate for state/local where legislative data is absent, keep `CommitteeTable` as the fallback.

2. **"View Full Legislative Record" link when only committee data exists**
   - What we know: `/legislative-summary` returns bills + votes only (no committees). Local politicians may have committee assignments but no bills/votes.
   - What's unclear: Should the link appear for politicians who have committee data but no bills/votes?
   - Recommendation: Since the summary endpoint doesn't return committee counts, omit the link when `recent_bills` and `recent_votes` are both empty. Document this as a known gap — a future improvement could check committee data existence. This is the lowest-risk path.

3. **ev-ui component naming: page-level vs sub-component**
   - What we know: The full record page is a complete page layout (with Header), but it's being built in ev-ui for potential reuse.
   - What's unclear: Should the full record page component be in ev-ui (reusable across apps) or only in essentials (app-specific)?
   - Recommendation: Build `LegislativeRecord.jsx` in ev-ui as a headless content component (sections + data, no Header or routing). The essentials `LegislativeRecord.jsx` page wraps it with Header, fetching, and routing. This keeps ev-ui components portable.

---

## Sources

### Primary (HIGH confidence)
- Codebase: `ev-ui/src/PoliticianProfile.jsx` — verified component structure, inline style pattern, CommitteeTable usage
- Codebase: `ev-ui/src/tokens.js` — verified design token values
- Codebase: `ev-ui/src/CommitteeTable.jsx`, `IssueTags.jsx` — verified existing component patterns
- Codebase: `EV-Backend/internal/essentials/handlers.go` lines 115-160 + 2992-3390 — verified all 5 endpoint response shapes
- Codebase: `EV-Backend/internal/essentials/routes.go` — verified all routes registered
- Codebase: `essentials/src/App.jsx` — verified routing structure
- Codebase: `essentials/src/lib/api.jsx` — verified API fetch patterns
- Codebase: `essentials/src/pages/Profile.jsx` — verified profile page structure
- Codebase: `essentials/package.json` — verified react-router-dom@7.8.2, React 19
- Context7 `/remix-run/react-router` — verified nested route / Outlet pattern for react-router v7

### Secondary (MEDIUM confidence)
- Codebase inference: BallotReady `pol.committees` vs legislative committees are separate data sources — confirmed from handlers.go showing two different committee queries
- Codebase inference: `/legislative-summary` returns bills+votes only, no committees — confirmed from `LegislativeSummaryOut` struct

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all dependencies verified in package.json files
- Architecture: HIGH — all patterns verified from existing codebase code
- API shapes: HIGH — verified directly from handlers.go type definitions and SQL queries
- Pitfalls: HIGH for ev-ui version bump, date bug, CommitteeTable conflict (all verified from code); MEDIUM for local data empty state (logical inference from confirmed data pipeline scope)

**Research date:** 2026-03-03
**Valid until:** 2026-04-03 (stable — no external APIs or fast-moving dependencies)
