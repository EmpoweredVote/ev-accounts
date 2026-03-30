# Phase 100: Elected/Appointed Filter - Research

**Researched:** 2026-03-30
**Domain:** React client-side filtering + backend API field surfacing (essentials frontend + ev-accounts backend)
**Confidence:** HIGH

## Summary

Phase 100 adds a segmented control (All / Elected / Appointed) to the representatives page that filters politicians client-side using `is_appointed` and `faces_retention_vote` fields. The UI-SPEC is already approved; the visual contract is fully specified. The phase appears to be "frontend only" per the CONTEXT decision D-04, but there is a critical backend gap: the `PoliticianFlatRecord` type and all three address-search SQL queries do NOT currently select `p.is_appointed` or `o.faces_retention_vote`. Both fields are needed by the client-side resolution logic. The plan must include a backend step to surface these two fields before the frontend filter can be implemented.

The frontend integration is straightforward: a new `useState` for the elected/appointed filter, a `useMemo` step applied after the existing tier filter chain, a new `SegmentedControl` component rendered in both the desktop sidebar and the mobile filter section, and sessionStorage cache updated to persist the new filter state. The UI-SPEC provides exact pixel values, colors, ARIA roles, and copy — the implementer has zero ambiguity.

Retention judge behavior (appearing in both Elected and Appointed views) is handled entirely by the `faces_retention_vote` field and the filter logic in D-06. No special UI treatment is required.

**Primary recommendation:** Implement in two tasks — (1) backend: add `is_appointed` and `faces_retention_vote` to `PoliticianFlatRecord` and all SQL queries; (2) frontend: add segmented control, filter state, and useMemo filter step.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Stacked filters — the Elected/Appointed filter is a separate control from the existing tier filter (All/Local/State/Federal). Both are active simultaneously (e.g., "State" + "Elected" = only elected state officials).
- **D-02:** Elected/Appointed filter sits below the tier filter in the sidebar (desktop) and below the tier pills (mobile).
- **D-03:** Segmented control (iOS-style pill toggle) with three options: All / Elected / Appointed. Visually distinct from the tier radio buttons, making it clear this is a separate filter dimension.
- **D-04:** Client-side filtering only — no backend changes. The API already returns `is_appointed` (politician-level), `is_elected` (office-level derived from `!is_appointed`), and `faces_retention_vote` on every politician response.
- **D-05:** Client-side resolution of the priority chain: check `politician.is_appointed` first (individual override), then fall back to `offices.is_appointed_position` (per Phase 97 decision). Frontend combines these with `faces_retention_vote` to determine filter visibility.
- **D-06:** Filter logic:
  - **All**: Show everyone (current behavior, default)
  - **Elected**: Show officials where resolved is_appointed=false OR faces_retention_vote=true
  - **Appointed**: Show officials where resolved is_appointed=true (includes retention judges since they are appointed)
- **D-07:** No special visual indicator for retention judges. They silently appear in both Elected and Appointed views. No badge, no tooltip — the filter just works.

### Claude's Discretion

- Segmented control visual styling (colors, active state, sizing)
- Mobile responsive behavior for the segmented control
- State management approach for the new filter (useState, URL param, or cache)
- Animation/transition when filter changes
- Label text variations if "Elected/Appointed" feels too long on mobile

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FILT-01 | User can filter the main representatives page by Elected, Appointed, or All | Segmented control component + useMemo filter step in Results.jsx; requires `is_appointed` and `faces_retention_vote` in API response |
| FILT-02 | Retention judges (appointed with retention vote) appear under both Elected and Appointed filters | `faces_retention_vote` field on `essentials.offices` exists (migration 043); filter logic in D-06 handles dual appearance; field must be added to API response |
| FILT-03 | Filter defaults to "All" preserving current behavior | `useState('All')` initialization; sessionStorage cache already persists `filter` key |
</phase_requirements>

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React | 19 | UI rendering | Project standard |
| Tailwind CSS | 4 | Utility classes | Project standard |
| Inline styles | n/a | Component-specific styling | Established pattern in LocalFilterSidebar, Results.jsx |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| useState | built-in | Filter state management | Single component, no cross-component sharing needed |
| useMemo | built-in | Derived filter computation | Already used for all filtering chains in Results.jsx |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| useState | URL search param | URL param enables shareable filtered URLs but adds complexity; CONTEXT leaves this to Claude's discretion — useState is simpler and consistent with existing `selectedFilter` pattern |
| useState | sessionStorage direct | Already handled: sessionStorage saves `filter` key from existing `selectedFilter` state |

**Installation:** No new packages required.

---

## Architecture Patterns

### Recommended Project Structure

No new files needed. Changes are isolated to:

```
essentials/src/
├── pages/Results.jsx                    # Add state, useMemo step, pass props
├── components/LocalFilterSidebar.jsx    # Add SegmentedControl rendering
└── components/SegmentedControl.jsx      # NEW: reusable segmented control component

ev-accounts/backend/src/lib/
└── essentialsService.ts                 # Add is_appointed + faces_retention_vote fields
```

### Pattern 1: Resolution Logic

**What:** Client-side resolution of appointed status using the priority chain from CONTEXT D-05.

**When to use:** Wherever a politician object needs to be tested against the Elected/Appointed filter.

**Example:**
```javascript
// Source: 100-UI-SPEC.md, CONTEXT.md D-05
function resolveIsAppointed(pol) {
  // politician.is_appointed is the individual override (from politicians table)
  // pol.is_elected is !is_appointed_position (office-level fallback)
  if (pol.is_appointed !== undefined && pol.is_appointed !== null) {
    return pol.is_appointed;
  }
  return !pol.is_elected;
}
```

**Usage in filter:**
```javascript
// Source: CONTEXT.md D-06, 100-UI-SPEC.md interaction contract
function matchesAppointedFilter(pol, filter) {
  if (filter === 'All') return true;
  const resolvedIsAppointed = resolveIsAppointed(pol);
  if (filter === 'Elected') {
    return !resolvedIsAppointed || pol.faces_retention_vote === true;
  }
  if (filter === 'Appointed') {
    return resolvedIsAppointed === true;
  }
  return true;
}
```

### Pattern 2: useMemo Filter Chain Slot

**What:** The new Elected/Appointed filter slots into the existing `useMemo` chain after tier filtering and before search filtering.

**When to use:** Results.jsx already has this chain: `filteredPols` → `federalFiltered` → `classified` → `byTier` → `displayedPoliticians` → `searchFilteredPoliticians`. The new filter applies AFTER `byTier` and BEFORE the tier filter reduces to one tier — meaning it should be applied at the individual politician level within each tier/group bucket, not as a top-level tier cut.

**Correct insertion point:** After `byTier` is built (line ~548), apply the appointed filter to the politician arrays within each tier/group. This ensures both filters are simultaneously active (D-01).

```javascript
// Source: Results.jsx pattern, CONTEXT.md D-01
const appointedFilteredByTier = useMemo(() => {
  if (appointedFilter === 'All') return byTier;
  const result = {};
  for (const [tier, groups] of Object.entries(byTier)) {
    result[tier] = {};
    for (const [group, pols] of Object.entries(groups)) {
      const filtered = pols.filter(pol => matchesAppointedFilter(pol, appointedFilter));
      if (filtered.length > 0) result[tier][group] = filtered;
    }
  }
  return result;
}, [byTier, appointedFilter]);

// Replace byTier reference in displayedPoliticians with appointedFilteredByTier
const displayedPoliticians = useMemo(() => {
  if (selectedFilter === 'All') return appointedFilteredByTier;
  return { [selectedFilter]: appointedFilteredByTier[selectedFilter] || {} };
}, [appointedFilteredByTier, selectedFilter]);
```

### Pattern 3: SegmentedControl Component

**What:** Reusable inline-styled segmented control matching the UI-SPEC exactly.

**Example (desktop + mobile shared component):**
```jsx
// Source: 100-UI-SPEC.md component specification
function SegmentedControl({ options, value, onChange, ariaLabel, minHeight }) {
  return (
    <div
      role="radiogroup"
      aria-label={ariaLabel}
      style={{
        display: 'inline-flex',
        width: '100%',
        borderRadius: '9999px',
        backgroundColor: '#f0f8fa',
        border: '1px solid #e2e8f0',
        padding: '4px',
      }}
    >
      {options.map((option) => (
        <button
          key={option.value}
          role="radio"
          aria-checked={value === option.value}
          onClick={() => onChange(option.value)}
          style={{
            flex: 1,
            textAlign: 'center',
            borderRadius: '9999px',
            padding: '8px 0',
            minHeight: minHeight || undefined,
            fontSize: '14px',
            fontWeight: value === option.value ? 600 : 400,
            color: value === option.value ? '#ffffff' : '#4a5568',
            backgroundColor: value === option.value ? '#00657c' : 'transparent',
            boxShadow: value === option.value ? '0 1px 3px rgba(0,0,0,0.15)' : 'none',
            border: 'none',
            cursor: 'pointer',
            fontFamily: "'Manrope', sans-serif",
            transition: 'background-color 0.15s ease, color 0.15s ease',
          }}
        >
          {option.label}
        </button>
      ))}
    </div>
  );
}
```

### Pattern 4: Backend Field Addition

**What:** Three SQL queries in `essentialsService.ts` need `p.is_appointed` and `o.faces_retention_vote` added to SELECT and the `PoliticianFlatRecord` interface/mapping updated.

**Affected queries:**
1. `getPoliticiansByState` (line ~380) — `p.is_active = true` filter query
2. `getRepresentativesByAddress` district query (line ~500) — geofence query
3. `getRepresentativesByAddress` statewide query (line ~550) — statewide query
4. `getPoliticiansByGovernment` (line ~1350) — government-based query

**Interface change:**
```typescript
// Add to PoliticianFlatRecord interface (line ~55 in essentialsService.ts):
is_appointed: boolean;
faces_retention_vote: boolean;

// Add to each row mapping:
is_appointed: row.is_appointed ?? false,
faces_retention_vote: row.faces_retention_vote ?? false,

// Add to each SQL SELECT:
p.is_appointed, o.faces_retention_vote,
```

### Anti-Patterns to Avoid

- **Filtering at the top-level tier loop only:** The new filter must be applied within tier/group buckets, not by dropping entire tiers. If "State + Appointed" is selected, state tier shows but only appointed officials within it remain.
- **Mutating `byTier` directly:** The pattern is `useMemo` returning a new object — do not mutate.
- **Using yellow for the segmented control:** `#fed12e` is reserved for the Candidates toggle. The segmented control uses `#00657c` (teal) per UI-SPEC.
- **Abbreviating labels on mobile:** UI-SPEC explicitly says "All / Elected / Appointed — no abbreviation needed, these are short enough."
- **Forgetting to update sessionStorage persistence:** `ev:results` cache saves `filter: selectedFilter`. The new `appointedFilter` state must also be persisted and restored from cache, otherwise back-navigation drops filter state.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Segmented control | Custom CSS-heavy component | Hand-rolled inline styles per UI-SPEC | UI-SPEC already specifies exact values; project convention is inline styles, not a UI library |
| Filter logic | Complex selector state machine | Simple `useMemo` with conditional | The filter is two booleans — direct logic is clearer than abstraction |

**Key insight:** This phase is primarily wiring existing infrastructure (useMemo chains, sessionStorage cache, prop drilling pattern) rather than solving novel problems. Complexity comes from the backend gap, not the frontend logic.

---

## Critical Gap: Backend Field Surfacing

**Finding:** CONTEXT.md D-04 states "no backend changes — the API already returns `is_appointed`, `is_elected`, and `faces_retention_vote` on every politician response." This is **incorrect as of the current codebase**.

**Actual state (verified by code inspection):**

| Field | DB column | In API response? | Notes |
|-------|-----------|-----------------|-------|
| `is_elected` | derived `!is_appointed_position` | YES — in `PoliticianFlatRecord` | Already works |
| `is_appointed` | `essentials.politicians.is_appointed` | NO — missing from `PoliticianFlatRecord` | Only in `PoliticianDetail` (profile endpoint) |
| `faces_retention_vote` | `essentials.offices.faces_retention_vote` | NO — missing from all queries | Migration 043 added column, not wired to API |

**Impact:** The resolution logic `resolvedIsAppointed = politician.is_appointed ?? !politician.is_elected` requires `politician.is_appointed`. Without it, the fallback `!politician.is_elected` fires for all politicians, making the individual override from Phase 97 (D-05, Courtney Daily edge case) non-functional. The retention judge filter also breaks silently since `faces_retention_vote` would always be `undefined`.

**Required backend work (minimal — SQL SELECT + interface only, no route changes):**
1. Add `p.is_appointed` to 3 SQL SELECT clauses in `essentialsService.ts`
2. Add `o.faces_retention_vote` to 3 SQL SELECT clauses
3. Add both fields to `PoliticianFlatRecord` interface
4. Map both fields in 3 `rows.map()` calls

**Confidence:** HIGH — verified by direct inspection of `PoliticianFlatRecord` interface (line 55-96), all three SQL queries, and the `row.is_appointed` mapping that only appears in the detail endpoint (line 989).

---

## Common Pitfalls

### Pitfall 1: Assuming D-04 "no backend changes" is accurate

**What goes wrong:** Planner skips backend task assuming `is_appointed` and `faces_retention_vote` are already in the API response. Frontend filter silently fails — all politicians appear as "elected" because `pol.is_appointed` is always `undefined`, causing `!pol.is_elected` fallback to fire everywhere, and `pol.faces_retention_vote` is always falsy.
**Why it happens:** D-04 was written based on the intended post-Phase-97 state, but the actual field surfacing was deferred or forgotten.
**How to avoid:** Backend task must come first in the plan; frontend task gates on it.
**Warning signs:** If `Object.keys(politician).includes('is_appointed')` returns false in browser devtools, the field was not added.

### Pitfall 2: Applying the elected/appointed filter at the wrong level

**What goes wrong:** Developer wraps the outer `byTier` loop and drops whole tiers when all their officials are appointed, but the tier filter is still set to "All". User selects "Appointed + State" and sees nothing because the State tier was dropped instead of filtering within it.
**Why it happens:** The two-filter interaction (D-01) requires the appointed filter to operate on the politician arrays inside each tier/group bucket, not on the tier keys themselves.
**How to avoid:** Apply `matchesAppointedFilter` inside the group-level loop, not the tier-level loop.

### Pitfall 3: Not updating sessionStorage cache with new filter state

**What goes wrong:** User browses with "Appointed" filter active, clicks a politician card, presses back — filter resets to "All" because sessionStorage restore only reads the tier filter.
**Why it happens:** `ev:results` sessionStorage already has `filter: selectedFilter` for the tier filter; the new `appointedFilter` state must be added alongside it.
**How to avoid:** Update both the `sessionStorage.setItem` call and the `cachedResult?.filter` initialization pattern to include `appointedFilter`/`cachedResult?.appointedFilter`.

### Pitfall 4: Segmented control outside the sidebar scroll container on mobile

**What goes wrong:** On mobile, the filter section is inside a fixed-height container and the segmented control overflows or wraps oddly.
**Why it happens:** The three options ("All" / "Elected" / "Appointed") fit in a single row at normal font sizes, but developers sometimes add extra padding that causes wrapping on 320px screens.
**How to avoid:** `flex: 1` on each pill with `text-align: center` is sufficient — do not set `min-width` on individual pills. The track is `width: 100%` which naturally distributes space.

### Pitfall 5: Wrong empty state scope

**What goes wrong:** When "Appointed + Local" yields zero officials, the existing `!hasGroups` empty state is triggered and shows "No officials found for this area" instead of the specific "No appointed officials found for this area" message.
**Why it happens:** The existing empty state check (`!hasGroups && ... && activeQuery`) fires on the same condition.
**How to avoid:** When `appointedFilter !== 'All'`, the empty state message should be `"No ${appointedFilter.toLowerCase()} officials found for this area."` per UI-SPEC copywriting contract.

---

## Code Examples

Verified patterns from existing code:

### Existing tier filter state pattern (to replicate)
```javascript
// Source: essentials/src/pages/Results.jsx line ~300-302
const [selectedFilter, setSelectedFilter] = useState(
  cachedResult?.filter || 'All'
);
```

New filter follows the same pattern:
```javascript
const [appointedFilter, setAppointedFilter] = useState(
  cachedResult?.appointedFilter || 'All'
);
```

### Existing sessionStorage save (to extend)
```javascript
// Source: essentials/src/pages/Results.jsx line ~349-360
sessionStorage.setItem('ev:results', JSON.stringify({
  query: queryFromUrl,
  list,
  filter: selectedFilter,      // tier filter — already saved
  // ADD: appointedFilter: appointedFilter,
  timestamp: Date.now(),
}));
```

### Existing mobile tier pill pattern (to replicate below)
```jsx
// Source: essentials/src/pages/Results.jsx line ~916-931
<div className="flex gap-2 mb-3">
  {['All', 'Local', 'State', 'Federal'].map((filter) => (
    <button
      key={filter}
      onClick={() => setSelectedFilter(filter)}
      className={`px-3 py-1 text-sm rounded-full border transition-colors ${
        selectedFilter === filter
          ? 'bg-[#00657c] text-white border-[#00657c]'
          : 'bg-white text-gray-600 border-gray-300'
      }`}
      style={{ fontFamily: "'Manrope', sans-serif" }}
    >
      {filter}
    </button>
  ))}
</div>
// INSERT SegmentedControl here (margin-top: 8px)
```

### LocalFilterSidebar insertion point (desktop)
```jsx
// Source: essentials/src/components/LocalFilterSidebar.jsx line ~68-70
        </div>   // closes tier radio group
      </div>     // closes "Group" section

      <hr className="border-gray-200 my-4" />

      {/* INSERT: Type segmented control */}
      <div className="mb-1">
        <p className="text-sm font-medium text-gray-500 mb-2">Type</p>
        <SegmentedControl ... />
      </div>

      <hr className="border-gray-200 my-4" />

      {/* Name search input — existing code continues */}
```

### Backend SQL addition (all three queries)
```sql
-- Add to each SELECT clause in essentialsService.ts
p.is_appointed, o.faces_retention_vote,
```

```typescript
// Add to PoliticianFlatRecord interface
is_appointed: boolean;
faces_retention_vote: boolean;

// Add to each rows.map() call
is_appointed: row.is_appointed ?? false,
faces_retention_vote: row.faces_retention_vote ?? false,
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single tier filter (All/Local/State/Federal) | Two simultaneous filters (tier + appointed) | This phase | Requires careful useMemo chain ordering |

**Not applicable (greenfield addition):** No deprecated patterns — this adds on top of existing filter infrastructure.

---

## Open Questions

1. **Is `faces_retention_vote` expected only on `essentials.offices` or also on `essentials.politicians`?**
   - What we know: Migration 043 added `faces_retention_vote` to `essentials.offices` only. The address-search queries join `offices`.
   - What's unclear: The CONTEXT references it as part of the politician response — but the field lives on the office row. No field currently copies it to the politician level.
   - Recommendation: Add `o.faces_retention_vote` to each SQL SELECT (pulling from the offices join that already exists in all three queries). This is the correct normalized approach.

2. **Should `appointedFilter` be persisted in the URL as a search param?**
   - What we know: CONTEXT leaves state management approach to Claude's discretion. The existing `selectedFilter` (tier) is NOT in the URL — it's only in sessionStorage and React state.
   - What's unclear: Whether shareable filtered URLs are desired.
   - Recommendation: Use `useState` + sessionStorage (matching the existing tier filter pattern) for consistency. URL param can be a future enhancement.

---

## Environment Availability

Step 2.6: SKIPPED — no new external dependencies. This phase modifies existing Express + React code with no new external tools, databases, or services.

---

## Validation Architecture

> `nyquist_validation` key absent from config.json — treat as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Vitest |
| Config file | `ev-accounts/vitest.config.ts` (inferred from `npm test` = `vitest run`) |
| Quick run command | `cd ev-accounts && npm test` |
| Full suite command | `cd ev-accounts && npm test` |

**Frontend note:** `essentials` has no test framework configured — only `dev`, `build`, `lint`, `preview` scripts in package.json. No test files exist outside node_modules. Frontend validation is manual/visual.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FILT-01 | Filter control renders; all/elected/appointed options work | manual | n/a (no test framework in essentials) | N/A |
| FILT-02 | Retention judge appears in both Elected and Appointed views | manual | n/a | N/A |
| FILT-03 | Filter defaults to "All" | manual | n/a | N/A |
| FILT-01 | Backend: `is_appointed` and `faces_retention_vote` present in API response | integration | `cd ev-accounts && npm test` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** Manual browser check of filter behavior
- **Per wave merge:** `cd ev-accounts && npm test` (integration tests for API response shape)
- **Phase gate:** All filter combinations verified manually + backend test green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `ev-accounts/tests/integration/essentials-fields.test.ts` — verify `is_appointed` and `faces_retention_vote` present in `/api/essentials/by-address` response shape (CI-safe route wiring test, no live DB required)

---

## Project Constraints (from CLAUDE.md)

| Directive | Constraint |
|-----------|------------|
| GitHub account | Use `chrisandrewsedu` for all git operations |
| Secrets | Never commit `.env` files; verify before any commit |
| Design system | Colors: `ev-coral` (#ff5740), `ev-muted-blue` (#00657c), `ev-light-blue` (#59b0c4), `ev-yellow` (#fed12e); Font: Manrope |
| Styling | Tailwind CSS 4 across all React projects |
| Backend pattern | Service file → Route file → wire into index.ts → migration |
| `ev-ui` publish | Component changes require version bump + `npm publish`; consumers must `npm update` |
| Anti-partisan | Never show party affiliation; do not store party data even if upstream provides it |

**Phase-specific constraint:** The `ev-ui` component library is NOT involved. `LocalFilterSidebar` is the local replacement that avoids an ev-ui publish cycle (per CLAUDE.md "Duplicated Display Logic" note). The new `SegmentedControl` component should be created in `essentials/src/components/`, not in `ev-ui`.

---

## Sources

### Primary (HIGH confidence)
- Direct code inspection: `essentials/src/pages/Results.jsx` — existing filter state, useMemo chain, sessionStorage pattern, mobile pill layout (lines 230-983)
- Direct code inspection: `essentials/src/components/LocalFilterSidebar.jsx` — full file, insertion point identified
- Direct code inspection: `ev-accounts/backend/src/lib/essentialsService.ts` — `PoliticianFlatRecord` interface (lines 55-96), all three SQL queries (lines 380, 500, 550), field mapping
- Direct code inspection: `.planning/phases/100-elected-appointed-filter/100-UI-SPEC.md` — full approved UI contract
- Direct code inspection: `.planning/phases/100-elected-appointed-filter/100-CONTEXT.md` — all decisions

### Secondary (MEDIUM confidence)
- Migration 043 (`ev-accounts/backend/migrations/043_faces_retention_vote.sql`) — confirms `faces_retention_vote` column on `essentials.offices`, Indiana appellate judges flagged
- `essentials/src/utils/sorters.js` line 153 — `electedFirstKey` uses `pol.is_elected` (confirms field name convention)

### Tertiary (LOW confidence)
- None.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — existing project, no new dependencies
- Architecture: HIGH — insertion points verified by direct code inspection
- Pitfalls: HIGH — backend gap confirmed by interface inspection, other pitfalls derived from established codebase patterns
- Backend gap: HIGH — verified by reading `PoliticianFlatRecord` interface and all SQL queries

**Research date:** 2026-03-30
**Valid until:** 2026-04-30 (stable project, no fast-moving dependencies)
