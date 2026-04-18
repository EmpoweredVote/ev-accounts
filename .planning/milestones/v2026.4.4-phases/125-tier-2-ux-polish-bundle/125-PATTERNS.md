# Phase 125: Tier 2 UX Polish Bundle - Pattern Map

**Mapped:** 2026-04-17
**Files analyzed:** 8 modified files (1 backend, 6 frontend, 1 HTML)
**Analogs found:** 8 / 8 (all are existing files being edited; analog = the file itself + surrounding code conventions)

> Note: This phase is a polish bundle — all files are **modified**, not newly created. The "analog" for each file is the existing surrounding code in that file. Pattern excerpts below show the exact conventions to match for each fix.

---

## File Classification

| Modified File | Role | Data Flow | Wave | Closest Analog | Match Quality |
|---------------|------|-----------|------|----------------|---------------|
| `ev-accounts/backend/src/lib/compassService.ts` | service | request-response (SQL query) | 2 | self (lines 267-306) | self |
| `essentials/src/pages/Results.jsx` (G-114-002 display) | page component | render | 1 | self (line 813 surrounding render) | self |
| `essentials/src/pages/Results.jsx` (G-114-004 cross-ref) | page component | render + lazy fetch | 1 | self (lines 337-353 elections fetch + 555-677 card) | self |
| `essentials/src/pages/Results.jsx` (G-114-011 write addr) | page component | localStorage write | 2 | `essentials/src/lib/compass.js:183-211` (localStorage bridge) | role-match |
| `essentials/src/lib/compass.js` (extend bridge) | utility | localStorage read/write | 2 | self (`saveGuestCompass`/`loadGuestCompass` lines 183-211) | self |
| `CompassV2/src/components/InlinePoliticianPicker.jsx` (geo-default) | component | state init from localStorage | 2 | self (lines 22-55 — hooks + filter wiring) | self |
| `read-rank/index.html` | static HTML | n/a | 3 | self (line 7) | self |
| `treasury-tracker/src/components/AlphaLanding.tsx` (CityGrid) | component | render (sort/partition) | 3 | self (lines 105-155 CityGrid) | self |
| `treasury-tracker/src/App.tsx` (FY notice) | page component | conditional render | 3 | self (lines 514-553 controls bar) | self |
| `treasury-tracker/src/components/BudgetSunburst.tsx` (labels OR removal) | component (D3) | render | 3 | self (BudgetSunburst.tsx) + `BudgetVisualization.tsx` (toggle host) | self |

---

## Pattern Assignments

### `ev-accounts/backend/src/lib/compassService.ts` (G-114-014 SQL fix)

**Analog:** itself — `getCompassPoliticians` at lines 267-306.

**Existing SQL pattern** (line 273) — the bug:
```typescript
COALESCE(p.photo_custom_url, p.photo_origin_url, pi.url, '') AS photo_origin_url,
```

**Surrounding query convention** (lines 270-289) — preserve `pool.query` direct SQL, JOIN ordering, and `LATERAL` subselect on `essentials.politician_images`:
```typescript
const { rows } = await pool.query(
  `SELECT DISTINCT ON (p.id)
          p.id, p.first_name, p.last_name, p.preferred_name, p.full_name,
          COALESCE(p.photo_custom_url, p.photo_origin_url, pi.url, '') AS photo_origin_url,
          ...
   LEFT JOIN LATERAL (
     SELECT url FROM essentials.politician_images
     WHERE politician_id = p.id AND type = 'default' LIMIT 1
   ) pi ON true
   WHERE p.is_active = true
   ORDER BY p.id, o.id DESC`
);
```

**Fix to apply** — wrap empty-string-prone columns with `NULLIF`:
```typescript
COALESCE(NULLIF(p.photo_custom_url, ''), NULLIF(p.photo_origin_url, ''), pi.url, '') AS photo_origin_url,
```

**Row mapping convention** (lines 292-305) — preserve fallback `?? ''` on output:
```typescript
photo_origin_url: r.photo_origin_url ?? '',
```

---

### `essentials/src/pages/Results.jsx` — G-114-002 (title-case address)

**Analog:** itself — render block at lines 810-815.

**Existing render** (line 813):
```jsx
{formattedAddress && phase === 'fresh' && list.length > 0 && (
  <div className="px-4 sm:px-8 pb-2">
    <p className="text-sm text-gray-500" style={{ fontFamily: "'Manrope', sans-serif" }}>
      Showing representatives for <span className="font-semibold text-gray-700">{formattedAddress}</span>
    </p>
  </div>
)}
```

**Pattern to apply:** add a small helper (inline or in `essentials/src/utils/`). Project convention: small util files live in `essentials/src/utils/` (e.g., `sorters.js`). Helper must preserve state codes (`IN`), zip, directional letters (`W`, `N`).

```jsx
import { toTitleCaseAddress } from '../utils/address';
// ...
<span className="font-semibold text-gray-700">{toTitleCaseAddress(formattedAddress)}</span>
```

---

### `essentials/src/pages/Results.jsx` — G-114-004 (Reps↔Elections cross-reference)

**Analog:** itself — lazy-fetch pattern at lines 337-353 + `renderPoliticianCard` at 555-677.

**Existing lazy-fetch pattern** (lines 337-353) — copy this for eager-load variant:
```jsx
useEffect(() => {
  if (activeView !== 'elections' || !activeQuery) return;
  if (electionsData !== null) return;
  let cancelled = false;
  setElectionsLoading(true);
  fetchElectionsByAddress(decodeURIComponent(activeQuery)).then((data) => {
    if (!cancelled) {
      setElectionsData(data.elections || []);
      setElectionsLoading(false);
    }
  });
  return () => { cancelled = true; };
}, [activeView, activeQuery]);
```

**Fix pattern:** drop the `activeView !== 'elections'` guard so elections data loads in the background as soon as `activeQuery` is set. Build a `Set<politician_id>` from `electionsData` in a `useMemo`. In `renderPoliticianCard`, append a small annotation when set membership matches.

**Annotation styling reference** (existing ev-yellow accent at line ~648 in card):
- Use `text-xs` + `text-[#fed12e]` (ev-yellow) — matches existing candidate accent in card.

**Tab-dot indicator pattern** (lines 800-803) shows the convention for cross-tab signaling:
```jsx
{electionsData && electionsData.length > 0 && (
  <span className="w-2 h-2 rounded-full bg-[#FED12E] ml-1" />
)}
```

---

### `essentials/src/pages/Results.jsx` + `essentials/src/lib/compass.js` — G-114-011 (write address bridge)

**Analog for new key:** existing `GUEST_COMPASS_KEY` pattern in `essentials/src/lib/compass.js:103, 183-217`.

**Existing localStorage bridge convention** (compass.js lines 183-211):
```js
export const GUEST_COMPASS_KEY = "guestCompass";

export function saveGuestCompass(answers, selectedTopics, invertedSpokes = {}) {
  localStorage.setItem(
    GUEST_COMPASS_KEY,
    JSON.stringify({ a: answers, s: selectedTopics, i: invertedSpokes })
  );
}

export function loadGuestCompass() {
  try {
    const raw = localStorage.getItem(GUEST_COMPASS_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed.a !== "object" || parsed.a === null || !Array.isArray(parsed.s)) {
      return null;
    }
    return { answers: parsed.a, selectedTopics: parsed.s, invertedSpokes: parsed.i || {} };
  } catch {
    return null;
  }
}

export function clearGuestCompass() {
  localStorage.removeItem(GUEST_COMPASS_KEY);
}
```

**Pattern to apply:** add a parallel triplet for address. Per RESEARCH §G-114-011 recommendation (b) — separate key:
```js
export const USER_ADDRESS_KEY = "evUserAddress";

export function saveUserAddress(addr, state) {
  localStorage.setItem(
    USER_ADDRESS_KEY,
    JSON.stringify({ addr, state, ts: Date.now() })
  );
}

export function loadUserAddress({ ttlMs = 30 * 24 * 60 * 60 * 1000 } = {}) {
  try {
    const raw = localStorage.getItem(USER_ADDRESS_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed.state !== 'string') return null;
    if (parsed.ts && Date.now() - parsed.ts > ttlMs) return null;
    return { addr: parsed.addr, state: parsed.state };
  } catch {
    return null;
  }
}
```

**Where to write in Results.jsx:** in the success path after `formattedAddress` is set with a parsed state — call `saveUserAddress(formattedAddress, parsedState)`.

---

### `CompassV2/src/components/InlinePoliticianPicker.jsx` — G-114-011 (consume bridge)

**Analog:** itself — hooks block at lines 22-55.

**Existing hook wiring pattern** (lines 28-55):
```jsx
const { politicians, loading } = usePoliticianList();
const {
  level, setLevel,
  stateFilter, setStateFilter,
  clearAll, hasActiveFilters,
  levelCounts, availableStates,
  filtered,
} = useFilteredPoliticians(politicians);

useEffect(() => {
  if (!currentPolitician || !politicians.length) return;
  const fresh = politicians.find((p) => p.id === currentPolitician.id);
  if (fresh && fresh.district_type && !currentPolitician.district_type) {
    onSelect?.(fresh);
  }
}, [politicians, currentPolitician, onSelect]);
```

**Fix pattern:** add a one-shot effect after hook init that reads cross-app localStorage and sets `stateFilter` only if currently empty (don't override user choice):
```jsx
useEffect(() => {
  if (stateFilter) return; // respect user choice
  // Read cross-app key — same string as essentials writes
  try {
    const raw = localStorage.getItem('evUserAddress');
    if (!raw) return;
    const parsed = JSON.parse(raw);
    if (parsed?.state && availableStates?.includes(parsed.state)) {
      setStateFilter(parsed.state);
    }
  } catch { /* noop */ }
  // run once on mount when availableStates first populates
}, [availableStates]); // eslint-disable-line react-hooks/exhaustive-deps
```

**Note:** CompassV2 cannot import from `essentials/src/lib/compass.js` directly (separate apps). Inline the localStorage read with the same key string `'evUserAddress'`. Document the cross-app contract in a code comment.

---

### `read-rank/index.html` — G-114-020 (page title)

**Analog:** itself — line 7.

**Current:**
```html
<title>readrank-prototype</title>
```

**Fix:**
```html
<title>Read & Rank — Empowered Vote</title>
```

**Naming convention reference:** other apps use the pattern `"<App> — Empowered Vote"` (em-dash separator). Confirm by checking `essentials/index.html` and `CompassV2/index.html` if uncertain.

---

### `treasury-tracker/src/components/AlphaLanding.tsx` — G-114-021 (featured municipalities)

**Analog:** itself — `CityGrid` at lines 105-155.

**Existing single-list render** (lines 122-153):
```tsx
return (
  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
    {available.map(city => {
      const years = [...new Set(city.available_datasets.map(d => d.fiscal_year))].sort((a, b) => b - a);
      const isPilot = city.name === 'Bloomington' && city.state === 'IN';
      return (
        <button key={city.id} onClick={() => onNavigateToCity(city)}
          className="flex items-center gap-3 bg-white border border-[#E2EBEF] rounded-xl p-4 text-left hover:border-[#005366] hover:shadow-sm transition-all duration-200 group"
        >
          {/* ...icon, name, year info, arrow... */}
        </button>
      );
    })}
  </div>
);
```

**Fix pattern:** partition `available` into `featured` (state === 'IN') and `others`, render two sections with headers. Reuse the existing button JSX verbatim — extract to a sub-renderer to avoid duplication.

```tsx
const featured = available.filter(m => m.state === 'IN');
const others = available.filter(m => m.state !== 'IN');

return (
  <div className="space-y-6">
    {featured.length > 0 && (
      <div>
        <h3 className="text-xs font-semibold uppercase tracking-wider text-[#6B7280] mb-2">Featured communities</h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          {featured.map(renderCityButton)}
        </div>
      </div>
    )}
    {others.length > 0 && (
      <div>
        <h3 className="text-xs font-semibold uppercase tracking-wider text-[#6B7280] mb-2">Other communities</h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          {others.map(renderCityButton)}
        </div>
      </div>
    )}
  </div>
);
```

**Color/typography convention:** preserve existing palette (`#005366`, `#EAF4F7`, `#E2EBEF`, `#1C1C1C`, `#6B7280`) and `font-manrope`.

---

### `treasury-tracker/src/App.tsx` — G-114-023 (FY notice banner)

**Analog:** itself — controls bar at lines 514-553.

**Existing `availableYears` derivation** (lines 109-113):
```tsx
const availableYears = useMemo(() => {
  if (!selectedEntity) return [];
  const years = [...new Set(selectedEntity.available_datasets.map(d => d.fiscal_year))];
  return years.sort((a, b) => b - a).map(String);
}, [selectedEntity]);
```

**Existing controls-bar wrapper convention** (lines 514-516) — match the `bg-white shadow-sm` + `max-w-[1400px] mx-auto px-6` shell:
```tsx
<div className="bg-white shadow-sm">
  <div className="max-w-[1400px] mx-auto px-6 py-3">
    {/* ...controls... */}
  </div>
</div>
```

**Fix pattern:** insert a conditional banner above or below the controls bar. Use existing palette (avoid new amber/yellow if possible — but RESEARCH suggests `#FFF8ED` / `#F5D98B` / `#92400E` for notice tone):
```tsx
{!availableYears.includes('2026') && availableYears.length > 0 && (
  <div className="bg-[#FFF8ED] border-l-4 border-[#F5D98B]">
    <div className="max-w-[1400px] mx-auto px-6 py-2">
      <p className="text-sm text-[#92400E]">
        Latest available: FY{availableYears[0]}. FY2026 data not yet published by {selectedEntity.name}.
      </p>
    </div>
  </div>
)}
```

Make the condition data-driven (no `selectedEntity.name === 'Monroe County'` hardcoding).

---

### `treasury-tracker/src/components/BudgetSunburst.tsx` — G-114-025 (labels or removal)

**Analog:** itself — `BudgetSunburst.tsx` lines 1-100 (D3 partition setup).

**Existing D3 setup convention** (lines 88-100):
```tsx
useEffect(() => {
  if (!svgRef.current || !containerRef.current) return;
  d3.select(svgRef.current).selectAll('*').remove();
  const containerWidth = containerRef.current.clientWidth;
  const size = Math.min(containerWidth, 900);
  const radius = size / 2;
  // ...
}, [/* deps */]);
```

**Path A — add top-level labels** (preferred per RESEARCH; estimate complexity M):
- After partition layout, select top-level (`depth === 1`) nodes.
- Compute arc length: `(node.x1 - node.x0) * radius`.
- Hide labels for arcs below ~60px arc length (threshold guard).
- Append `<text>` rotated to follow arc midpoint, or use `<textPath>` along the arc path.
- Use existing currency/percentage formatters (`formatCurrency`, `formatPercentage` lines 71-86) for label content if showing amounts.

**Path B — remove sunburst toggle** (fallback per CONTEXT D-08):
- Locate toggle in `treasury-tracker/src/components/BudgetVisualization.tsx` (analog file). Remove the sunburst option from the toggle list and remove the `BudgetSunburst` import + render branch.
- This is a TRIVIAL change; commits with file deletion of `BudgetSunburst.tsx` and `BudgetSunburst.css`.

**Decision rule (per RESEARCH Q5):** plan task with explicit ≤2-hour checkpoint on Path A; if exceeded, switch to Path B.

---

## Shared Patterns

### Cross-app localStorage bridge contract
**Source:** `essentials/src/lib/compass.js` (Phase 122 pattern — `GUEST_COMPASS_KEY`)
**Apply to:** Any new cross-app data needing to flow Essentials → Compass (or other apps)
- Use a dedicated, namespaced string key (e.g., `evUserAddress`, not nested inside another key)
- JSON-serialize a small object with timestamps for TTL guards
- Defensive parse with try/catch returning `null` on any failure
- Provide `save*`/`load*`/`clear*` triplet of pure functions
- Document the contract in a comment when consumed by another app

### Tailwind palette (project-wide)
- `ev-coral` `#ff5740`, `ev-muted-blue` `#00657c`, `ev-light-blue` `#59b0c4`, `ev-yellow` `#fed12e`
- Treasury uses additional grays: `#F7F7F8`, `#E2EBEF`, `#005366`, `#1C1C1C`, `#6B7280`, `#EAF4F7`
- Font: Manrope across all React projects

### Antipartisan principle (CLAUDE.md)
**Apply to:** All UI changes
- No party labels or red/blue color associations
- Use only the EV palette above

### React effect convention (CompassV2 + essentials)
- Use `let cancelled = false` + `return () => { cancelled = true; }` for fetch effects (see Results.jsx:342-352)
- Use `useMemo` for derived state from props (see App.tsx:109-122)
- One-shot effects: depend on the variable that arrives async; guard with early return when state already set

### Backend SQL pattern (ev-accounts)
- `pool.query` with template-literal SQL for `essentials` schema (not exposed via PostgREST)
- `LEFT JOIN LATERAL` for "first row of related set" lookups
- Always wrap potentially-empty-string columns with `NULLIF(col, '')` inside `COALESCE` chains

---

## No Analog Found

None — every file in this phase is a modification of an existing file with established conventions in-place.

---

## Metadata

**Analog search scope:**
- `ev-accounts/backend/src/lib/compassService.ts`
- `essentials/src/pages/Results.jsx`, `essentials/src/lib/compass.js`
- `CompassV2/src/components/InlinePoliticianPicker.jsx`, `ComparePanel.jsx`
- `read-rank/index.html`
- `treasury-tracker/src/components/AlphaLanding.tsx`, `BudgetSunburst.tsx`
- `treasury-tracker/src/App.tsx`

**Files scanned:** ~10
**Pattern extraction date:** 2026-04-17
