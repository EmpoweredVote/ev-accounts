# Phase 76: Frontend Results Integration - Research

**Researched:** 2026-03-11
**Domain:** React frontend (essentials Results.jsx), classify.js grouping logic, government_body_name API field consumption
**Confidence:** HIGH

## Summary

Phase 76 is a pure frontend change in `essentials/src/pages/Results.jsx`. All backend and ev-ui groundwork is already complete from Phases 73-75:

- `government_body_name` and `government_body_url` are returned per politician from the API (Phase 73)
- `government_bodies` table is seeded with Monroe County Commission, Monroe County Council, Monroe County Government, and Bloomington Common Council display names (Phase 74)
- `CategorySection` accepts `websiteUrl` prop and renders an external-link icon (Phase 75, ev-ui 0.1.41)
- `Results.jsx` already passes `websiteUrl={polList[0]?.government_body_url || undefined}` to all three tier blocks (Phase 75)

The remaining work for Phase 76 is to use `government_body_name` as the section title instead of the generic `getDisplayName(category)` output — and to handle BODY-02's requirement for **distinct sections** when multiple government bodies share the same classify group.

The key challenge: `byTier` currently groups politicians by `cat.group` (e.g., "County Legislators"), so Monroe County Commission members and Monroe County Council members are bundled into a single `polList`. Phase 76 must sub-split that `polList` by `government_body_name` before rendering separate `CategorySection` components for each named body.

**Primary recommendation:** Within each tier's `orderedEntries(...).map(...)` block, sub-group the `polList` by `government_body_name` and render one `CategorySection` per distinct body name. When a polList contains members from multiple named bodies, render multiple sections. When all members share one named body (or none have a name), render a single section as today.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| BODY-01 | Section headings display specific body names (e.g., "Monroe County Council" instead of "County Board") | Use `polList[0]?.government_body_name` as section title; fall back to `getDisplayName(category)` when absent |
| BODY-02 | County Commissioners and County Council display as distinct sections for Indiana counties | Both groups currently map to "County Legislators" in classify.js; sub-group `polList` by `government_body_name` before rendering `CategorySection`; each distinct body name becomes its own section |
| BODY-03 | Township sections display specific township names (e.g., "Perry Township Trustee") | `government_body_name` populated from `government_bodies` table when seeded; if absent for a township, falls back to generic "Township" display name — no logic change needed |
| BODY-04 | City-level sections display specific city names (e.g., "Bloomington Common Council") | Bloomington Common Council seeded in `government_bodies`; sub-group logic delivers this automatically |
| BODY-05 | School Board sections display specific district names (e.g., "Monroe County Community School Corporation Board") | Same pattern as other groups — `government_body_name` used when present |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React | 19 | Component rendering | Already installed in essentials |
| ev-ui | 0.1.41 | CategorySection with websiteUrl prop | Already installed and wired (Phase 75) |

### No New Dependencies Required
This phase modifies `essentials/src/pages/Results.jsx` only. No new packages, no ev-ui changes, no backend changes.

**Installation:** None required.

## Architecture Patterns

### Recommended Project Structure
No structural changes. One file modified in-place:
```
essentials/
└── src/
    └── pages/
        └── Results.jsx   ← modify the tier render blocks
```

### Pattern 1: Sub-Group polList by government_body_name Before Rendering Sections

**What:** Within each `orderedEntries(...).map(...)` block, split the `polList` into sub-groups keyed by `government_body_name`. Render one `CategorySection` per sub-group. Politicians without a `government_body_name` are placed in a fallback sub-group using `getDisplayName(category)` as the key.

**When to use:** Any time a single classify group may contain politicians from multiple distinct named government bodies.

**Example:**
```jsx
// Source: essentials/src/pages/Results.jsx (new pattern for Phase 76)

// Helper function to sub-group polList by government_body_name
function splitByBodyName(category, polList) {
  const named = {};
  const unnamed = [];

  for (const pol of polList) {
    const bodyName = pol.government_body_name;
    if (bodyName) {
      if (!named[bodyName]) named[bodyName] = [];
      named[bodyName].push(pol);
    } else {
      unnamed.push(pol);
    }
  }

  const result = [];
  // Named bodies first (sorted for consistent ordering)
  for (const [bodyName, pols] of Object.entries(named).sort()) {
    result.push({
      title: bodyName,
      websiteUrl: pols[0]?.government_body_url || undefined,
      pols,
    });
  }
  // Unnamed politicians fall back to generic category display name
  if (unnamed.length > 0) {
    result.push({
      title: getDisplayName(category),
      websiteUrl: undefined,
      pols: unnamed,
    });
  }
  return result;
}

// In the render block (replaces current single CategorySection per group):
{orderedEntries(groups, LOCAL_ORDER).map(([category, polList]) =>
  splitByBodyName(category, polList).map(({ title, websiteUrl, pols }, idx) => (
    <CategorySection
      key={`${category}-${title}-${idx}`}
      title={title}
      websiteUrl={websiteUrl}
    >
      {defaultSort(category, pols).map((pol) => renderPoliticianCard(pol))}
    </CategorySection>
  ))
)}
```

**This pattern must be applied to all three tier blocks: Local, State, and Federal.**

### Pattern 2: Fallback Chain for Section Title

**What:** The priority order for section title is:
1. `government_body_name` from API — specific, seeded for Monroe County and Bloomington bodies
2. `getDisplayName(category)` — generic fallback for all other areas (LA County, Federal, etc.)

**Why:** LA County officials have no seeded `government_body_name`, so they receive the same generic labels as today ("County Board", "City Council"). No regression.

### Pattern 3: Stable React Keys for Sub-Split Sections

**What:** When a single classify group produces multiple `CategorySection` elements, the React key must be unique per section. Use a composite key: `\`${category}-${title}-${idx}\`` where `idx` is the index within the sub-group array.

**Why:** Two sections from the same classify group (e.g., "County Legislators") would share the key if only `category` were used — React reconciliation error.

### Anti-Patterns to Avoid

- **Passing government_body_name through qualifyLocalTitle():** This has been explicitly flagged in STATE.md as causing a double-prefix (e.g., "Monroe County Monroe County Council"). The body name is already fully qualified — use it directly.
- **Mutating byTier/displayedPoliticians/searchFilteredPoliticians:** These are derived from useMemo chains. Do not add sub-grouping logic to those memos — apply it at render time only, within the map() call.
- **Using government_body_name as the React list key alone:** If two different classify groups happened to produce the same body name (unlikely but possible), the key would collide. Always composite with `category`.
- **Sorting named bodies alphabetically when only one body exists per category:** Single-body groups should be fine with any order, but the alphabetical sort for the multi-body case (Commission before Council) is predictable and correct.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Sub-grouping polList by a field | Custom recursive groupBy utility | Inline for-loop per the Pattern 1 example | 3 lines, no dependency; a full groupBy util is overkill for one use case |
| Section ordering when multiple bodies share a classify group | Complex priority ordering system | Alphabetical sort of body names | Predictable, reproducible; Commission < Council alphabetically matches success criteria BODY-02 |

**Key insight:** The entire Phase 76 change is a helper function (~15 lines) and a modification to the three tier render blocks (~5 lines each). No new infrastructure, no ev-ui changes, no backend changes.

## Common Pitfalls

### Pitfall 1: searchFilteredPoliticians Is the Final Filtered Source

**What goes wrong:** Applying sub-grouping to `byTier` instead of `searchFilteredPoliticians` — search filtering breaks because the split happens before the name filter runs.

**Why it happens:** There are five derived state values between `list` and render: `filteredPols` → `federalFiltered` → `classified` → `byTier` → `displayedPoliticians` → `searchFilteredPoliticians`. The render loops iterate over `searchFilteredPoliticians`.

**How to avoid:** Apply `splitByBodyName` only inside the `orderedEntries(...).map(...)` blocks in the JSX render — after `searchFilteredPoliticians` has been fully computed. Never introduce sub-grouping into the useMemo chain.

**Warning signs:** Name search stops filtering politicians within sub-split sections.

### Pitfall 2: Empty polList Sub-Groups From Search Filtering

**What goes wrong:** After a search filter, a sub-group may contain only politicians whose names don't match — but `searchFilteredPoliticians` already eliminates non-matching politicians from each group. So this is not a real concern at the `polList` level. However, if `splitByBodyName` produces a sub-group with 0 members, a `CategorySection` with no children renders an empty grid.

**Why it happens:** Can't happen in practice — `searchFilteredPoliticians` only includes groups with `filtered.length > 0`, and every member of `polList` passed from there is a match.

**How to avoid:** No action needed — the existing search filtering guarantees non-empty `polList` entries.

### Pitfall 3: government_body_name Is Empty String Not Undefined

**What goes wrong:** The backend uses `omitempty` but the Go struct initializes `GovernmentBodyName` to `""` before COALESCE assigns it. If the COALESCE returns `''` (empty string), the JSON field is suppressed by omitempty. However, in the row struct before serialization, an empty string could slip through.

**Why it happens:** COALESCE with `''` fallback means no-match rows produce empty string, which omitempty then drops. In JavaScript the field will be `undefined`.

**How to avoid:** In `splitByBodyName`, check `if (bodyName)` — empty string is falsy in JavaScript, so an empty `government_body_name` routes to the unnamed bucket correctly. This is the same pattern already used for `websiteUrl` in Phase 75.

**Warning signs:** Sections appear with empty string titles.

### Pitfall 4: Duplicate Section Rendering If Helper Is Called Twice

**What goes wrong:** If `splitByBodyName` is inadvertently called twice per group (e.g., nested map), duplicate sections appear.

**Why it happens:** Accidental double-wrap in the JSX.

**How to avoid:** Keep the helper as a standalone function outside the component, called exactly once per `[category, polList]` entry.

### Pitfall 5: LA County Regression — Multiple Bodies With Same Classify Group

**What goes wrong:** LA County has many city councils and special districts that all classify to "City Council" or "Local Departments & Special Districts" without a `government_body_name` (none seeded). After Phase 76, all those politicians route to the `unnamed` bucket — which correctly renders as a single `CategorySection` with the generic title. No regression.

**Why it happens:** N/A — the fallback bucket handles this correctly.

**How to avoid:** Verify with an LA County address in dev after implementing.

## Code Examples

Verified patterns from existing essentials source:

### Current CategorySection render (Phase 75 output)
```jsx
// Source: essentials/src/pages/Results.jsx lines 742-748
{orderedEntries(groups, LOCAL_ORDER).map(([category, polList]) => (
  <CategorySection key={category} title={getDisplayName(category)} websiteUrl={polList[0]?.government_body_url || undefined}>
    {defaultSort(category, polList).map((pol) =>
      renderPoliticianCard(pol)
    )}
  </CategorySection>
))}
```

### Phase 76 target (sub-split by government_body_name)
```jsx
// essentials/src/pages/Results.jsx — Phase 76 change
{orderedEntries(groups, LOCAL_ORDER).map(([category, polList]) =>
  splitByBodyName(category, polList).map(({ title, websiteUrl, pols }, idx) => (
    <CategorySection
      key={`${category}-${title}-${idx}`}
      title={title}
      websiteUrl={websiteUrl}
    >
      {defaultSort(category, pols).map((pol) => renderPoliticianCard(pol))}
    </CategorySection>
  ))
)}
```

### splitByBodyName helper
```jsx
// Source: new helper, place above the Results component export or in classify.js
function splitByBodyName(category, polList) {
  const named = {};
  const unnamed = [];

  for (const pol of polList) {
    const bodyName = pol.government_body_name;
    if (bodyName) {
      if (!named[bodyName]) named[bodyName] = [];
      named[bodyName].push(pol);
    } else {
      unnamed.push(pol);
    }
  }

  const result = [];
  for (const [bodyName, pols] of Object.entries(named).sort()) {
    result.push({
      title: bodyName,
      websiteUrl: pols[0]?.government_body_url || undefined,
      pols,
    });
  }
  if (unnamed.length > 0) {
    result.push({
      title: getDisplayName(category),
      websiteUrl: undefined,
      pols: unnamed,
    });
  }
  return result;
}
```

### API field reference
```js
// government_body_name: string or undefined (omitempty suppresses empty string)
// government_body_url:  string or undefined (omitempty suppresses empty string)
// Both fields present on every politician object in the API response.
// Undefined when no matching government_bodies row exists.
pol.government_body_name  // e.g. "Monroe County Council", "Bloomington Common Council", undefined
pol.government_body_url   // e.g. "https://www.in.gov/counties/monroe/government/council/", undefined
```

### Anti-pattern (NEVER do this)
```jsx
// WRONG: passes government_body_name through qualifyLocalTitle — causes double-prefix
title={qualifyLocalTitle(pol.government_body_name || getDisplayName(category), pol)}
// "Monroe County Monroe County Council" ← exact bug flagged in STATE.md

// CORRECT: use government_body_name directly
title={pol.government_body_name || getDisplayName(category)}
```

## State of the Art

| Old Approach | Current Approach (after Phase 76) | When Changed | Impact |
|--------------|-----------------------------------|--------------|--------|
| `getDisplayName(category)` for all section titles | `government_body_name` when present, `getDisplayName(category)` fallback | Phase 76 | Specific body names visible for seeded jurisdictions |
| Single CategorySection per classify group | Sub-split by `government_body_name` → one section per distinct body | Phase 76 | BODY-02: Commission and Council appear as separate sections |
| `websiteUrl` from `polList[0]?.government_body_url` (Phase 75) | Same, but derived per sub-group | Phase 76 | Each sub-group section gets its own correct URL |

**Already complete from prior phases:**
- `government_body_name` and `government_body_url` in API (Phase 73)
- `government_bodies` seeded for Monroe County Commission/Council, Bloomington Common Council, Monroe County Government (Phase 74)
- `CategorySection.websiteUrl` prop and render (Phase 75, ev-ui 0.1.41)
- `websiteUrl` wired to all three tier blocks in Results.jsx (Phase 75)

## Open Questions

1. **Ordering of sub-split sections within a classify group**
   - What we know: Alphabetical sort of body names is predictable. "Monroe County Commission" < "Monroe County Council" alphabetically.
   - What's unclear: Whether the desired UX order is alphabetical, or Commission-first as the executive body.
   - Recommendation: Alphabetical is fine for now; it happens to produce Commission before Council which is a sensible executive-first ordering.

2. **Township bodies without seeded government_body_name**
   - What we know: No township government bodies are currently seeded in `government_bodies`. Township politicians will route to the `unnamed` bucket and display the generic "Township" label.
   - What's unclear: BODY-03 success criterion says "Perry Township Trustee" — this implies a `government_body_name` of "Perry Township Trustee" or similar would need to be seeded. However, if the township official's `government_body_name` comes from their chamber name via the JOIN, it may be populated. The JOIN key is `COALESCE(NULLIF(c.name_formal, ''), c.name, '')` which for a township chamber may be something like "Perry Township" or the full office name.
   - Recommendation: Verify in dev whether township officials return `government_body_name` from the existing `government_bodies` seed or not. If absent, BODY-03 may require an additional seed row in the database (outside Phase 76 scope) or the success criterion for BODY-03 may be satisfied by the existing chamber name logic when name_formal is populated. This warrants investigation during implementation.

3. **School board bodies without seeded government_body_name**
   - What we know: No school board bodies seeded for Monroe County Community School Corporation. Similar open question as townships.
   - Recommendation: Same as Pitfall/Question 2 — verify in dev. If `government_body_name` is absent, BODY-05 may depend on an additional seed row not yet in Phase 74's setup.go.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None — essentials has no automated test suite |
| Config file | none |
| Quick run command | Manual browser verification with Monroe County address |
| Full suite command | Manual browser verification |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BODY-01 | Section headings show specific body names for seeded bodies | manual | n/a | ❌ no test suite |
| BODY-02 | Monroe County Commission and Council appear as separate sections | manual | n/a | ❌ no test suite |
| BODY-03 | Township section shows specific township name | manual | n/a | ❌ no test suite |
| BODY-04 | Bloomington city council section shows "Bloomington Common Council" | manual | n/a | ❌ no test suite |
| BODY-05 | School board section shows specific district name | manual | n/a | ❌ no test suite |
| Regression | LA County address renders generic category names (no crash, no blank sections) | manual | n/a | ❌ no test suite |
| Build | essentials builds without errors | automated | `cd /Users/chrisandrews/Documents/GitHub/essentials && npm run build` | ✅ exists |

### Sampling Rate
- **Per task commit:** `cd /Users/chrisandrews/Documents/GitHub/essentials && npm run build` (build green) + manual browser check for one Monroe County address
- **Phase gate:** All 5 BODY success criteria verified manually against live dev server; LA County regression verified

### Wave 0 Gaps
None — no test infrastructure exists or is expected. Manual verification is the established pattern for essentials.

## Sources

### Primary (HIGH confidence)
- `essentials/src/pages/Results.jsx` — read directly; current CategorySection render at lines 742-784
- `essentials/src/lib/classify.js` — read directly; COUNTY branch at lines 196-207, CATEGORY_DISPLAY_NAMES at lines 241-270
- `essentials/src/utils/sorters.js` — read directly; GROUP_SORT_OPTIONS confirms "County Legislators" exists
- `EV-Backend/internal/essentials/handlers.go` lines 214-215, 1218-1219, 1429-1430 — confirmed `government_body_name` in API response struct and both SQL queries
- `EV-Backend/internal/essentials/setup.go` lines 78-128 — confirmed seeded bodies: Monroe County Commission, Monroe County Council (5 geo_id fan-out), Monroe County Government, Bloomington Common Council (7 geo_id fan-out)
- `ev-ui/src/CategorySection.jsx` — read directly; current implementation with `websiteUrl` prop (ev-ui 0.1.41)
- `.planning/STATE.md` — "Use government_body_name from API directly for section headers — never pass through qualifyLocalTitle()"

### Secondary (MEDIUM confidence)
- `.planning/phases/73-backend-governmentbody-table/73-02-SUMMARY.md` — confirmed "commission" added to COUNTY branch; both Commissioners and Council route to "County Legislators"
- `.planning/phases/75-ev-ui-categorysection-update/75-01-SUMMARY.md` — confirmed Phase 75 complete; Results.jsx already passes `websiteUrl` to all three tier blocks
- `.planning/REQUIREMENTS.md` — BODY-01 through BODY-05 definitions and success criteria

### Tertiary (LOW confidence)
- Open Question 2 (township seeding) — unverified; needs dev investigation during implementation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — direct codebase inspection; no new dependencies
- Architecture (sub-group pattern): HIGH — directly derived from existing Results.jsx patterns and STATE.md decisions
- Pitfalls: HIGH — derived from code inspection and explicit STATE.md warnings (qualifyLocalTitle double-prefix)
- Open Questions (township/school board): LOW — seeding status not confirmed for these body types

**Research date:** 2026-03-11
**Valid until:** 2026-04-10 (stable; no fast-moving dependencies)
