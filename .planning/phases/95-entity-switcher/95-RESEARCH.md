# Phase 95: Entity Switcher - Research

**Researched:** 2026-03-22
**Domain:** React state management, URL query params, dropdown UI, backend API extension (Go/GORM)
**Confidence:** HIGH

## Summary

Phase 95 replaces the non-functional City/State/Federal NavigationTabs with an EntitySwitcher dropdown that drives a full-page data reload. All data-loading logic is already entity-agnostic — `dataLoader.ts` accepts `municipalityName` and caches by `name-year-dataset`. The primary work is: (1) a new EntitySwitcher component, (2) wiring selected entity state into all three `loadBudgetData` calls in App.tsx, (3) making the hero card dynamic, (4) adding disabled-state support to DatasetTabs, (5) URL query param sync using native `URLSearchParams`, and (6) two backend additions — `hero_image_url` on the `Municipality` model and available-years metadata in the municipalities API response.

No router library is installed (no react-router, no wouter) and no external state library is used. The correct approach for URL params is native `window.location.search` + `URLSearchParams`, updated via `window.history.pushState`. This matches the app's zero-dependency state management style.

The key risk is the entity-year fallback logic (D-08): when the selected year has no data for the new entity, the app must fall back to the entity's most recent year rather than showing an error. This requires knowing available years per entity before loading budget data.

**Primary recommendation:** Load the full municipality list (including available years per entity) at app startup, then drive all subsequent data loads from selected entity state. Use `URLSearchParams` with `pushState` for URL sync — no router needed.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** Replace existing City/State/Federal NavigationTabs with an entity dropdown in the same header position.
**D-02:** Entities grouped by `entity_type` (Cities, Counties) in the dropdown menu.
**D-03:** Display format is "Name, ST" — e.g., "Bloomington, IN", "Monroe County, IN", "Los Angeles, CA".
**D-04:** Hero title updates dynamically to "{Entity Name} Finances" per selected entity. Background photo changes per entity.
**D-05:** Entity photos stored as a `hero_image_url` column on the `treasury.municipalities` DB table. Returned by the municipalities list API endpoint.
**D-06:** Info cards: hide the "per resident" calculation when population data is unavailable for an entity. Show total budget amount regardless.
**D-07:** Show a spinner overlay on the content area while loading new entity data. Keep the header/switcher interactive during load.
**D-08:** Persist year and dataset selection when switching entities. If the new entity lacks data for the selected year, fall back to its most recent available year.
**D-09:** Dataset tabs that have no data for the current entity are shown but disabled (grayed out, non-clickable) with a tooltip like "No salary data available".
**D-10:** Selected entity reflected in URL via query parameter: `?entity=bloomington-in`. Shareable and bookmarkable. Falls back to default if param missing.
**D-11:** Year and dataset also in URL query params: `?entity=la-county-ca&year=2024&dataset=revenue`. All three params optional with sensible defaults.
**D-12:** Default entity when no query parameter is present: Bloomington, IN (the original and most complete dataset).

### Claude's Discretion

- Entity slug format for URL params (e.g., `bloomington-in` vs `bloomington-indiana`)
- API endpoint design for listing municipalities with their available datasets/years
- Spinner implementation details (CSS animation vs library)
- How to derive available years per entity (API response metadata vs separate endpoint)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UI-01 | User can switch between entities (cities/counties) via dropdown on treasury tracker | EntitySwitcher component replaces NavigationTabs; municipality list from existing `/treasury/municipalities` endpoint |
| UI-02 | Hero card, breadcrumbs, and dataset tabs update dynamically per selected entity | App.tsx hero section parameterized; Breadcrumb label from entity name; DatasetTabs gets available-dataset list per entity |
| UI-03 | Entity switcher groups entities by type (city vs county) | `entity_type` field already on Municipality model; group by this field in dropdown render |
| UI-04 | dataLoader.ts cache key includes entity type to prevent cross-entity collisions | Current key is `name-year-dataset`; update to `name-entityType-year-dataset` |
</phase_requirements>

---

## Standard Stack

### Core (already installed)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React | 19.2.0 | Component model, useState hooks | Project standard |
| TypeScript | ~5.9.3 | Type safety | Project standard |
| Vite | ^7.2.4 | Build tool | Project standard |
| lucide-react | ^0.562.0 | ChevronDown and other icons already used in DatasetTabs | Already in use |

### No Additional Libraries Needed

URL query param management: native `URLSearchParams` + `window.history.pushState` — no react-router, no wouter. The app has zero routing dependencies; adding a router for one feature would be excessive.

Tooltip for disabled dataset tabs: CSS `title` attribute is sufficient for MVP. The `title` HTML attribute renders a native tooltip on hover with no JS or library required.

Spinner: CSS animation (keyframes) — already used in the project's App.css pattern for `loading` state. No additional library.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Native URLSearchParams | react-router useSearchParams | react-router adds ~50KB and a BrowserRouter wrapper for a feature that is trivially implementable natively |
| CSS title tooltip | Radix UI Tooltip | Radix is more accessible but a heavy addition for a simple "No data available" message |
| CSS keyframe spinner | React Spring / Framer Motion | Both are already in other EV apps but not in treasury-tracker; CSS is simpler here |

---

## Architecture Patterns

### Recommended Project Structure

No new directories needed. New files added to existing structure:

```
treasury-tracker/src/
├── components/
│   └── EntitySwitcher.tsx      # NEW — replaces NavigationTabs import in App.tsx
├── data/
│   └── dataLoader.ts           # MODIFY — update cache key, add available-years fetch
├── types/
│   └── budget.ts               # MODIFY — add Municipality interface
└── App.tsx                     # MODIFY — entity state, URL sync, hero dynamic
```

### Pattern 1: Entity State as Single Source of Truth in App.tsx

**What:** A single `selectedEntity` state of type `Municipality` drives hero content, `loadBudgetData` calls, DatasetTabs availability, and URL params.

**When to use:** App.tsx is already the sole state owner for year, dataset, and navigation path. Entity selection follows the same pattern.

**Example — entity state initialization:**
```typescript
// Source: existing App.tsx state pattern
const [municipalities, setMunicipalities] = useState<Municipality[]>([]);
const [selectedEntity, setSelectedEntity] = useState<Municipality | null>(null);

// On mount: load municipalities, resolve entity from URL param
useEffect(() => {
  listMunicipalities().then(list => {
    setMunicipalities(list);
    const param = new URLSearchParams(window.location.search).get('entity');
    const match = param ? list.find(m => toSlug(m) === param) : null;
    setSelectedEntity(match ?? list.find(m => m.name === 'Bloomington') ?? list[0]);
  });
}, []);
```

### Pattern 2: URL Sync via pushState (no router)

**What:** After any entity/year/dataset change, update the URL query string without navigation.

**When to use:** Single-page app with no router. `pushState` updates the browser URL bar and enables bookmarking without triggering a page reload.

**Example:**
```typescript
// Source: MDN History API
function syncURL(entity: Municipality, year: string, dataset: string) {
  const params = new URLSearchParams({
    entity: toSlug(entity),
    year,
    dataset
  });
  window.history.pushState({}, '', `?${params.toString()}`);
}
```

### Pattern 3: Entity Slug Format

**What:** Derive URL slug from municipality name + state at runtime — no stored slug field needed.

**Recommendation (Claude's Discretion):** Use `name-state` abbreviated format: `bloomington-in`, `monroe-county-in`, `la-county-ca`, `la-city-ca`, `ellettsville-in`. Lowercase, spaces replaced with hyphens, "Los Angeles" → `la` abbreviation is the user-friendly convention for CA entities. The derivation function must be deterministic and round-trippable.

```typescript
// Slug derivation — apply at both write (URL update) and read (URL parse)
function toSlug(m: Municipality): string {
  return `${m.name.toLowerCase().replace(/\s+/g, '-')}-${m.state.toLowerCase()}`;
}
// Lookup: list.find(m => toSlug(m) === param)
```

Note: "Los Angeles" entity with city role and "LA County" entity have different names in the DB, so no collision. Verify exact DB name strings when entities are imported in Phase 93/94.

### Pattern 4: Available Years per Entity

**What:** The `DatasetTabs` disabled state (D-09) and year fallback (D-08) both require knowing which years and datasets have data for the current entity before loading.

**Recommendation (Claude's Discretion):** Extend the `ListMunicipalities` Go handler to include a `available_datasets` array in each municipality's JSON response. This is a single additional DB query (GROUP BY municipality_id, fiscal_year, dataset_type) joined into the response. No separate endpoint needed.

**Alternative:** Query `/treasury/budgets?municipality_id={id}` (no year filter) to get all budgets for an entity — this already works with the existing handler but requires N+1 calls (one per entity after selection). The GROUP BY approach in municipalities is cleaner.

**Backend change required in `ListMunicipalities`:**
```go
// Augmented municipality response
type MunicipalityWithDatasets struct {
  Municipality
  AvailableDatasets []DatasetSummary `json:"available_datasets"`
}

type DatasetSummary struct {
  FiscalYear  int    `json:"fiscal_year"`
  DatasetType string `json:"dataset_type"`
}
```

### Pattern 5: Spinner Overlay (D-07)

**What:** Content area shows spinner during entity switch. Header remains interactive.

**When to use:** D-07 specifies overlay on content area only, not full page.

**Implementation:** CSS `position: relative` wrapper on `.main-content`, overlay `position: absolute` child with `z-index` above content but below `.header`. Controlled by existing `loading` boolean — reuse it when entity switches.

**Anti-pattern to avoid:** Do NOT replace the full page with a loading state (current pattern at line 186 of App.tsx). The entity switch spinner must be an overlay — the header/switcher must remain interactive per D-07.

### Pattern 6: DatasetTabs Disabled State (D-09)

**What:** Tabs with no data for the selected entity appear grayed out and non-clickable with a tooltip.

**How to implement:** Pass an `availableDatasets: string[]` prop to DatasetTabs. Inside the component, check `availableDatasets.includes(dataset.id)` to determine if a tab is interactive. Apply `opacity: 0.4; cursor: not-allowed; pointer-events: none` via inline style when disabled. Use `title="No salary data available"` for the native tooltip.

**Change to DatasetTabs props interface:**
```typescript
interface DatasetTabsProps {
  activeDataset: string;
  onDatasetChange: (datasetId: string) => void;
  revenueTotal?: number;
  operatingTotal?: number;
  availableDatasets?: string[];  // NEW — defaults to all three if omitted (backward compat)
}
```

### Anti-Patterns to Avoid

- **Full-page replace on entity switch:** Current loading state (lines 186-229 of App.tsx) replaces the entire app. For entity switching, only the main-content area should overlay — the header and switcher must stay mounted.
- **Hardcoded year list:** `const years = ['2025', '2024', '2023', '2022', '2021']` at line 113 of App.tsx must be replaced with years derived from the selected entity's `available_datasets`.
- **Cache collision:** Current cache key is `${municipalityName}-${year}-${dataset}`. If two entities share a name across states (unlikely but possible), this collides. The updated key must include entity type or state: `${municipalityName}-${entityType}-${year}-${dataset}` (per UI-04).
- **Hardcoded "Bloomington" in loadBudgetData calls:** Lines 75, 95 of App.tsx pass `'Bloomington'` literally. Both useEffect hooks must read from `selectedEntity?.name`.
- **"City" label in breadcrumbs:** Line 157 of App.tsx hardcodes `label: 'City'`. This must become `label: selectedEntity?.name ?? 'City'`.
- **"city" language in getDatasetDisplayText:** Lines 29-31 of App.tsx use "city revenue" language. If entity_type is county, this text reads awkwardly. Replace "city" with a dynamic term based on entity_type (or simply remove it — "How it funds its budget" is entity-neutral).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| URL param read/write | Custom URL class | Native `URLSearchParams` | Built into all browsers, zero bytes |
| Dropdown outside-click dismiss | Custom event listener logic | Reuse pattern from `YearSelector.tsx` (lines 14-28) | Identical pattern already exists in codebase |
| Available years discovery | Separate `/treasury/years` endpoint | Extend `ListMunicipalities` response with `available_datasets` array | Fewer roundtrips, data collocated with entity |
| Group-by in dropdown | Custom sort/reduce | `Array.reduce` grouping by entity_type — 5 lines | No library needed for 5 entities |

**Key insight:** The codebase has zero state management or routing libraries. Introducing one for this phase would be over-engineering. Every problem here is solvable with native browser APIs and React state hooks.

---

## Runtime State Inventory

> Rename/refactor trigger: NOT applicable. This is a new feature phase, not a rename.

Not applicable — no string renames, no data migrations. The `hero_image_url` column is a new column addition (schema migration), not a rename.

---

## Common Pitfalls

### Pitfall 1: Entity Switch Triggers Two Separate Data Fetches Before State Settles

**What goes wrong:** When entity changes, if selectedYear is also invalid for the new entity, the app fires one fetch (which 404s), then adjusts the year, then fires another fetch. The user sees a flash of error state before the fallback resolves.

**Why it happens:** Year fallback logic (D-08) runs as a reaction to the entity change, but the initial data load fires before the year has been corrected.

**How to avoid:** Compute the effective year for the new entity before calling `loadBudgetData`. The `handleEntityChange` function should: (1) get the new entity's available years, (2) determine if the current year is available, (3) set the correct year, (4) then load. Do this in a single coordinated handler, not across multiple useEffect chains.

**Warning signs:** Console shows a 404 or "No budget found" error followed immediately by a successful load.

### Pitfall 2: URL params Set on Mount Before Municipalities Are Loaded

**What goes wrong:** If `selectedEntity` is null on mount (before the municipalities fetch resolves), `syncURL()` writes `?entity=` (empty string) to the URL, overwriting a valid incoming URL parameter.

**Why it happens:** `useEffect` fires after render, but if URL sync also runs on mount, it fires before data is available.

**How to avoid:** Only call `syncURL` after `selectedEntity` is non-null. Guard: `if (!selectedEntity) return;` at the top of the URL sync effect. Alternatively, initialize selectedEntity directly from the URL param in the same effect that loads municipalities.

### Pitfall 3: Cache Key Collision (UI-04)

**What goes wrong:** If "Monroe County, IN" and a hypothetical "Monroe County, AR" both exist, the current cache key `Monroe County-2024-operating` hits the same cache entry.

**Why it happens:** Cache key uses only name + year + dataset, not state.

**How to avoid:** Update `loadBudgetData` cache key to include state or entity_type. Recommended: `${municipalityName}-${state}-${year}-${dataset}`. Also update the `listMunicipalities` return type to match the Municipality interface so state is available at call sites.

**Note:** UI-04 says "includes entity type" — but including state is more precise (two counties in different states with the same name would otherwise collide even with entity_type included). Use state.

### Pitfall 4: hero_image_url Not Available for All Entities at Phase Launch

**What goes wrong:** Phases 93 and 94 (Indiana and LA data import) may not have populated `hero_image_url` in the DB. If it's null, the hero background fails silently or shows a broken `url(null)`.

**Why it happens:** D-05 says hero photos are stored in DB, but photo population may not be part of Phase 93/94 scope.

**How to avoid:** Add a null guard in App.tsx: only set `backgroundImage` when `hero_image_url` is truthy. Fall back to the current hardcoded courthouse photo for Bloomington, or a solid gradient color. The Bloomington courthouse URL can remain as the default fallback for any entity without a photo.

**Warning signs:** Hero section shows a broken background or CSS warning `url("null")`.

### Pitfall 5: Disabled Dataset Tab Still Fires onClick

**What goes wrong:** Setting `opacity: 0.4` does not prevent click events. If `pointer-events: none` is omitted, users can still click disabled tabs and trigger a data load that 404s.

**Why it happens:** CSS opacity is visual only. Disabled state requires both visual styling and event suppression.

**How to avoid:** In the DatasetTabs disabled branch, add `style={{ pointerEvents: 'none', opacity: 0.4, cursor: 'not-allowed' }}` AND check in `onDatasetChange` callback whether the selected dataset is available before calling through. Defense in depth.

---

## Code Examples

### Cache Key Update (UI-04)
```typescript
// Source: treasury-tracker/src/data/dataLoader.ts (current, line 24)
// CURRENT:
const cacheKey = `${municipalityName}-${year}-${dataset}`;

// UPDATED (include state to prevent cross-entity collisions):
export async function loadBudgetData(
  year: number = 2025,
  municipalityName: string = 'Bloomington',
  municipalityState: string = 'IN',
  dataset: string = 'operating'
): Promise<BudgetData> {
  const cacheKey = `${municipalityName}-${municipalityState}-${year}-${dataset}`;
  // ... rest unchanged
}
```

### Municipality Interface (to add to types/budget.ts)
```typescript
// New type — matches ListMunicipalities API response
export interface Municipality {
  id: string;
  name: string;
  state: string;
  entity_type: 'city' | 'county' | 'township';
  population: number;
  hero_image_url?: string | null;
  available_datasets: Array<{
    fiscal_year: number;
    dataset_type: 'operating' | 'revenue' | 'salaries';
  }>;
}
```

### EntitySwitcher Component Structure
```typescript
// treasury-tracker/src/components/EntitySwitcher.tsx (NEW)
interface EntitySwitcherProps {
  municipalities: Municipality[];
  selectedEntity: Municipality | null;
  onEntityChange: (entity: Municipality) => void;
}

// Groups by entity_type for display (D-02)
// Displays "Name, ST" format (D-03)
// Uses same dropdown pattern as YearSelector (click-outside dismiss)
```

### Go: Extended ListMunicipalities Response
```go
// EV-Backend/internal/treasury/handlers.go
// Add available_datasets to ListMunicipalities response

type DatasetSummary struct {
  FiscalYear  int    `json:"fiscal_year"`
  DatasetType string `json:"dataset_type"`
}

type MunicipalityResponse struct {
  Municipality
  AvailableDatasets []DatasetSummary `json:"available_datasets"`
  HeroImageURL      *string          `json:"hero_image_url,omitempty"` // from D-05
}

// In ListMunicipalities handler, after fetching municipalities:
// JOIN or subquery to treasury.budgets to get (municipality_id, fiscal_year, dataset_type) tuples
```

### Go: hero_image_url Migration (new field, models.go)
```go
// Add to Municipality struct in EV-Backend/internal/treasury/models.go
HeroImageURL *string `json:"hero_image_url,omitempty"`
// GORM AutoMigrate will ADD COLUMN treasury.municipalities.hero_image_url TEXT
// nullable — no default needed
```

### URL Sync (no router)
```typescript
// In App.tsx — called after any entity/year/dataset change
function toSlug(m: Municipality): string {
  return `${m.name.toLowerCase().replace(/\s+/g, '-')}-${m.state.toLowerCase()}`;
}

function syncURL(entity: Municipality, year: string, dataset: string) {
  const params = new URLSearchParams({ entity: toSlug(entity), year, dataset });
  window.history.pushState({}, '', `?${params.toString()}`);
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Full-page loading replacement | Spinner overlay on content area only | This phase (D-07) | Header stays interactive during loads |
| Hardcoded Bloomington in `loadBudgetData` calls | Entity-parameterized calls | This phase | All entities load same code path |
| Static `years` array | Dynamic years from entity's `available_datasets` | This phase (D-08) | Year selector adapts to each entity's data availability |
| Non-functional City/State/Federal tabs | Working entity dropdown grouped by type | This phase (D-01, D-02) | Users can switch jurisdictions |

**Deprecated/outdated after this phase:**
- `NavigationTabs.tsx` — replaced by `EntitySwitcher.tsx`. File can be deleted.
- `activeTab` state (`useState('city')`) in App.tsx — no longer needed after NavigationTabs removal.
- `const tabs = [...]` array in App.tsx — same.
- `const years = ['2025', '2024', '2023', '2022', '2021']` in App.tsx — replaced by dynamic year list from entity.

---

## Open Questions

1. **Exact DB names for LA entities**
   - What we know: Phase 94 imports "LA County" and "LA City" but exact `name` strings in the `treasury.municipalities` table depend on Phase 94 import config.
   - What's unclear: The URL slug derivation (`toSlug`) must match actual DB names. "Los Angeles" vs "LA City" vs "LA" produce different slugs.
   - Recommendation: Plan should include a task to verify/document exact entity names after Phase 93/94 complete, or the EntitySwitcher tests against whatever is in the DB dynamically.

2. **Spinner: CSS animation vs. inline SVG**
   - What we know: No spinner utility currently exists in the codebase. `lucide-react` does not include a spinner icon.
   - What's unclear: Whether to use a CSS keyframe spinner or a third-party SVG.
   - Recommendation: Use a CSS-only spinner (border-radius circle with rotating border) — zero bytes, consistent with project's no-library-for-simple-things pattern.

3. **hero_image_url: when will photos be populated?**
   - What we know: D-05 specifies the column but Phase 94's scope is data import, not photo collection.
   - What's unclear: Whether hero photos for Indiana/LA entities will exist at Phase 95 launch.
   - Recommendation: Implement graceful null fallback (Bloomington courthouse photo as default). Document that hero photos can be backfilled via `PUT /treasury/municipalities/{id}` after this phase.

---

## Environment Availability

> This phase is frontend + backend code changes only. No new external services, CLIs, or databases.

Step 2.6: SKIPPED — no external dependencies beyond existing Go backend and Supabase, which are already operational.

---

## Validation Architecture

> `workflow.nyquist_validation` key is absent from `.planning/config.json` — treated as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None detected in treasury-tracker — no test config, no test files |
| Config file | None |
| Quick run command | N/A — no test framework installed |
| Full suite command | N/A |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| UI-01 | Entity dropdown renders municipalities grouped by type | manual-only | N/A — no test framework | N/A |
| UI-02 | Hero, breadcrumbs, dataset tabs update on entity switch | manual-only | N/A | N/A |
| UI-03 | Grouping by city/county visible in dropdown | manual-only | N/A | N/A |
| UI-04 | Cache key includes entity type — no stale cross-entity data | manual-only | N/A | N/A |

**Manual test protocol (Wave 0 substitute):**
1. Load app at `localhost:5173` — verify Bloomington loads by default (D-12)
2. Switch to Monroe County — verify hero title, dataset tabs, year list update
3. Switch to LA County — verify county label in breadcrumbs (not "Monroe County, City")
4. Manually corrupt URL to `?entity=invalid` — verify fallback to Bloomington
5. Verify URL updates on each entity/year/dataset change (D-10, D-11)
6. Verify disabled dataset tab appears grayed out for entity with no salary data

### Wave 0 Gaps

- No test framework is installed. Testing this phase is manual via browser inspection.
- If the project adds Vitest in Phase 96 (Visual Refresh), unit tests for `toSlug()` and cache key composition would be trivial first tests.

---

## Sources

### Primary (HIGH confidence)
- Direct source file inspection: `treasury-tracker/src/App.tsx` — confirmed hardcoded Bloomington references, current state pattern, loading behavior
- Direct source file inspection: `treasury-tracker/src/data/dataLoader.ts` — confirmed current cache key format, `listMunicipalities` function already exists
- Direct source file inspection: `EV-Backend/internal/treasury/models.go` — confirmed `entity_type` field exists, `hero_image_url` does NOT exist yet
- Direct source file inspection: `EV-Backend/internal/treasury/handlers.go` — confirmed `ListMunicipalities` returns no `available_datasets`
- Direct source file inspection: `treasury-tracker/src/components/NavigationTabs.tsx` — confirmed tabs are non-functional (only 'city' enabled)
- Direct source file inspection: `treasury-tracker/src/components/datasets/DatasetTabs.tsx` — confirmed no `disabled` or `availableDatasets` prop exists
- Direct source file inspection: `treasury-tracker/src/components/YearSelector.tsx` — confirmed click-outside dismiss pattern (reusable for EntitySwitcher)

### Secondary (MEDIUM confidence)
- MDN History API: `window.history.pushState` — standard for URL param updates without page reload; no router needed
- MDN URLSearchParams: `new URLSearchParams(window.location.search)` — standard for reading query params

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries inspected directly from package.json and source
- Architecture: HIGH — all integration points identified from direct source reading
- Pitfalls: HIGH — derived from actual code patterns and state management bugs observed in existing App.tsx
- Backend changes: HIGH — models.go and handlers.go read directly; gaps (hero_image_url, available_datasets) confirmed by absence

**Research date:** 2026-03-22
**Valid until:** 2026-04-22 (stable codebase, no fast-moving dependencies)
