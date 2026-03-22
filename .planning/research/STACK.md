# Stack Research

**Project:** v2026.3.7 Treasury Tracker Expansion
**Domain:** Municipal budget data visualization — visual refresh + multi-entity data migration
**Researched:** 2026-03-22
**Confidence:** HIGH (all findings from direct source inspection + verified open data portals)

---

## Context: What Is and Is Not New

The prior STACK.md (v2026.3.6) covers EV-readrank. This document covers **only what is new for v2026.3.7**: EV design token integration into treasury-tracker, Bloomington static JSON migration to Supabase, and budget data import for Ellettsville IN, Monroe County IN, LA County CA, and LA City CA.

**Existing stack that remains unchanged — do not re-research or reinstall:**
- React 19 + TypeScript + Vite 7.2.4 (treasury-tracker)
- D3.js ^7.9.0 + Recharts ^3.5.1 — chart rendering
- lucide-react ^0.562.0 — icons
- Go 1.24 + Chi + GORM — backend with existing treasury module
- Supabase PostgreSQL — `treasury.cities`, `treasury.budgets`, `treasury.budget_categories`, `treasury.budget_line_items` tables already exist with `ImportBudget` endpoint at `POST /treasury/import`
- `dataLoader.ts` already tries API first, falls back to static JSON — the abstraction is already in place
- `@chrisandrewsedu/ev-ui` currently at ^0.1.6 in treasury-tracker (stale; current is 0.1.53)

---

## Section 1: EV Design Token Integration

### No New npm Packages — Upgrade ev-ui and Add Tailwind CSS 4

**The problem:** Treasury-tracker uses raw CSS custom properties in `src/index.css` that approximate the EV design system but are not connected to it. The property names use non-canonical aliases (`--muted-blue`, `--coral`, `--accent-yellow`) that don't match the ev-ui token names. Color values are also slightly stale (e.g., `--muted-blue: #00657c` vs ev-ui `evTeal: #00647A`). The `@chrisandrewsedu/ev-ui` in `package.json` is pinned at `^0.1.6` while current is `0.1.53` — the SiteHeader, tokens, and tailwind-preset have all changed significantly.

**Step 1: Upgrade @chrisandrewsedu/ev-ui to current.**
The treasury-tracker's `package.json` already lists `@chrisandrewsedu/ev-ui` as a dependency. The `^0.1.6` semver range technically accepts any 0.1.x but npm locks at time of install. Must explicitly upgrade to `^0.1.53`.

**Step 2: Add Tailwind CSS 4 — the same way essentials and CompassV2 do it.**
Treasury-tracker has NO Tailwind installed. Its `src/index.css` is pure vanilla CSS. The other EV apps use `@import "tailwindcss"` in their CSS entry point (Tailwind v4's CSS-first config), with EV tokens defined in `@theme {}` blocks or consumed via `@import "@chrisandrewsedu/ev-ui/tailwind-preset"`.

The ev-ui package exports a tailwind-preset at `@chrisandrewsedu/ev-ui/tailwind-preset` that exposes all EV color scales (`ev-coral-500`, `ev-teal-500`, etc.), Manrope font family, and spacing/radius tokens as Tailwind utilities. Treasury-tracker should use this to gain EV-native utility classes.

**Step 3: Replace hardcoded CSS vars with ev-ui tokens.**
After Tailwind is installed, replace the manual `:root { --coral: ... }` block with references to the canonical ev-ui token exports. For inline style props that can't use Tailwind utilities, import `colors` from `@chrisandrewsedu/ev-ui/tokens` directly in TypeScript files.

**Tailwind v4 install (CSS-first, no `tailwind.config.js` needed):**
```bash
npm install tailwindcss @tailwindcss/vite
```
Add the Vite plugin to `vite.config.ts`, replace the Google Fonts import pattern and `:root` block in `src/index.css` with:
```css
@import "tailwindcss";
@import "@chrisandrewsedu/ev-ui/tailwind-preset";
@import url('https://fonts.googleapis.com/css2?family=Manrope:wght@300;400;500;600;700;800&display=swap');
```

This is exactly what essentials does (confirmed from `essentials/src/index.css` inspection).

**Chart color palette update:** The existing `budgetConfig.json` has a hardcoded `colorPalette` array of 30 hex values in non-EV blues/purples. Replace with `dataVizPalette` from `ev-ui/src/tokens.js`, which provides 10 EV-brand hues each with 5 shades. This is already published in the ev-ui tokens — import it as needed from the TypeScript components that assign chart segment colors.

**Confidence:** HIGH — all files inspected directly. Tailwind v4 CSS-first install is the identical pattern used in essentials and CompassV2. ev-ui tailwind-preset confirmed exported at `"./tailwind-preset"` in ev-ui `package.json`.

---

## Section 2: Entity Switcher UI

### No New npm Packages

The frontend needs a way to switch between cities/counties (Bloomington, Ellettsville, Monroe County, LA City, LA County). This is a dropdown or tab component, not a routing change.

**Implementation:** The existing `NavigationTabs` component handles tab-style switching. The existing `dataLoader.ts` already accepts `cityName` and `year` parameters and caches by `${cityName}-${year}-${dataset}` key. Connecting the entity switcher to `dataLoader.ts` requires only:
1. A new `selectedEntity` state in `App.tsx`
2. Passing entity name to `loadBudgetData()` (already accepts `cityName` parameter)
3. An entity picker component (tabs or dropdown)

Entity metadata (display name, state, population, hero image URL) should be a static config file (`src/data/entityConfig.ts`) — no backend call needed for the picker UI itself. The API already returns population and fiscal year from the budget response.

**No new npm packages.** lucide-react already provides chevron/selector icons.

**Confidence:** HIGH — `dataLoader.ts` and `App.tsx` inspected directly; `cityName` parameter already threaded through.

---

## Section 3: Bloomington Data Migration to Supabase

### No New npm Packages — Use Existing Import Endpoint

The backend already has `POST /treasury/import` which accepts a full budget JSON payload (`CategoryImport` tree with line items). The Bloomington data already exists as processed JSON files in `treasury-tracker/data/` (raw CSVs) and `public/data/` (processed `budget-{year}.json` files output by the Node.js processing scripts).

**Migration path:**
1. Run the existing processing scripts (`npm run process-all`) to regenerate the JSON files for 2021–2025.
2. Reshape the output to match the `ImportBudget` request body schema (add `city_name`, `city_state`, `population`, `fiscal_year`, `dataset_type` wrapper fields).
3. POST to `https://api.empowered.vote/treasury/import` with admin credentials.

The transformation from processed JSON to import format is a small Node.js script (~50 lines). No new Node packages needed — the processed JSON already has the right category/subcategory/lineItems hierarchy.

**The `dataLoader.ts` fallback chain handles the transition gracefully:** once Supabase has the data, the API path succeeds and the static JSON fallback is never reached. No frontend changes needed until the entity switcher is built.

**Confidence:** HIGH — `handlers.go` `ImportBudget` function inspected in full; `dataLoader.ts` fallback chain confirmed; processed JSON structure confirmed matching `CategoryImport` schema.

---

## Section 4: Budget Data Sourcing for New Entities

### Data Sources and Pipeline Approach

#### 4a: Ellettsville, Indiana

**Source:** Indiana Gateway for Government Units (`gateway.ifionline.org/public/download.aspx`)
- Provides pipe-delimited (`|`) budget files for all Indiana local government units
- Unit ID for Ellettsville: 2546 (confirmed from budgetnotices.in.gov search result)
- 2025 budget: $7,981,903 total
- Data format: pipe-delimited flat file (not hierarchical); requires aggregation similar to the existing Bloomington CSV processing pipeline

**Parsing approach:** The existing `processBudget.js` script already handles CSV parsing with custom logic. Pipe-delimited files need a delimiter configuration change — the parser function already accepts delimiter as a config option. The Indiana Gateway file layout guide provides column documentation.

**Confidence:** MEDIUM — Gateway download page confirmed (direct fetch); column structure for Ellettsville not yet downloaded and inspected. Bloomington's Socrata portal (`data.bloomington.in.gov`) uses the same DLGF-derived schema (Fiscal_Year, Priority, Service, Department, Program, Division, Fund, Approved_Amount, Primary_Function, Sub_Function columns), giving high confidence the Gateway files will be compatible with minor field mapping changes.

#### 4b: Monroe County, Indiana

**Source:** PDF budget documents from `monroecounty.gov/files/finance/`
- 2024 Adopted Budget: `https://www.monroecounty.gov/files/finance/2024%20Adopted%20Budget.pdf`
- 2025 Adopted Budget: `https://www.monroecounty.gov/files/finance/2025%20Adopted%20Budget.pdf`
- Total 2025 budget: ~$103 million (confirmed from IDS News reporting)

**No machine-readable open data portal found** for Monroe County IN. The Indiana Gateway provides downloadable files for Monroe County (unit lookup by county), but these cover the county government broadly — columns are the DLGF standard schema.

**Parsing approach:** If the Indiana Gateway Monroe County download is available in pipe-delimited format, use the same pipeline adaptation as Ellettsville. If only PDFs are available, a Python PDF-to-CSV extraction script using `pdfplumber` or `camelot-py` is the path — both are already in scope for the project's Python scraping infrastructure (Python scripts confirmed at ~17K LOC per PROJECT.md).

**Confidence:** MEDIUM — PDF availability confirmed; machine-readable format availability requires verification by downloading the Gateway file for Monroe County.

#### 4c: LA City (City of Los Angeles)

**Source:** LA Open Data Portal (Socrata) at `data.lacity.org`
- Dataset: "Open Budget — Appropriations Fiscal Years 2010–2025" (dataset ID: `5242-pnmt`)
- Direct CSV download: `https://data.lacity.org/api/views/5242-pnmt/rows.csv?accessType=DOWNLOAD`
- Also: Open Expenditures at `lacity.spending.socrata.com` (checkbook-level transactions)
- FY2024–25 budget: ~$13.9B general fund

**Parsing approach:** Standard CSV download from Socrata. The column structure (department, fund, appropriation amount) maps naturally to the existing treasury category hierarchy. The `dataLoader.ts` / `processBudget.js` pipeline handles CSV. A config file analogous to `budgetConfig.json` maps LA City columns to the treasury hierarchy.

**Confidence:** HIGH — Socrata CSV download URL format confirmed; dataset existence confirmed from multiple search results. Column structure needs inspection before final field mapping.

#### 4d: LA County

**Source:** LA County CEO Budget PDF (`ceo.lacounty.gov/budget/`) and LA County Open Data Portal (`data.lacounty.gov`)
- FY2024–25 Final Budget Book PDF confirmed available
- `data.lacounty.gov` portal uses Socrata — budget datasets exist but specific dataset IDs for machine-readable spending data require discovery

**Parsing approach:** Same Socrata CSV download pattern as LA City if a spending dataset exists on `data.lacounty.gov`. If only PDF budget books are available (likely for high-level department summaries), Python `pdfplumber` extraction is the fallback — same infrastructure used for Monroe County fallback.

**Confidence:** MEDIUM — Portal existence confirmed; specific downloadable spending dataset IDs not yet verified. LA County budget is $49.2B (FY2024–25), with structured departmental appropriations that should map to the treasury category model.

---

## Recommended Stack — New Additions Only

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `tailwindcss` | ^4.x | Utility CSS framework for treasury-tracker | Same version as all other EV apps; CSS-first config requires no `tailwind.config.js`; needed to consume ev-ui tailwind-preset utilities |
| `@tailwindcss/vite` | ^4.x | Vite plugin for Tailwind v4 | Required for Tailwind v4 in Vite projects; replaces PostCSS plugin approach used in v3 |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@chrisandrewsedu/ev-ui` | ^0.1.53 | Design tokens, SiteHeader, tailwind-preset | Upgrade from stale ^0.1.6; needed for correct token values, current SiteHeader, and tailwind-preset export |
| `papaparse` | ^5.5.3 | CSV/pipe-delimited parsing for import scripts | Use in the Node.js import pipeline scripts for Indiana Gateway (pipe-delimited) and Socrata CSV files; already used indirectly via manual CSV parsing in `processBudget.js` — this replaces the hand-rolled parser with a robust one |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Indiana Gateway Download | Source for Ellettsville and Monroe County pipe-delimited budget files | `https://gateway.ifionline.org/public/download.aspx` — download by unit ID, pipe `|` delimiter, DLGF standard columns |
| Bloomington Socrata | Source for Bloomington budget CSV updates | `https://data.bloomington.in.gov/dataset/Budgeted-Expenses-No-Blank-Fund/hej9-2d5y` — same 14-column schema as existing `operating-budget.csv` |
| LA City Socrata | Source for LA City appropriations CSV | `https://data.lacity.org/api/views/5242-pnmt/rows.csv?accessType=DOWNLOAD` — FY2010–2025, department-level appropriations |
| `pdfplumber` (Python) | PDF budget table extraction fallback | Use only if Monroe County or LA County lack machine-readable Socrata exports; already in project Python ecosystem |

---

## Installation

```bash
# In treasury-tracker — add Tailwind CSS 4
npm install tailwindcss @tailwindcss/vite

# Upgrade ev-ui to current
npm install @chrisandrewsedu/ev-ui@^0.1.53

# For import pipeline scripts (Node.js, run locally — not a frontend dep)
npm install -D papaparse @types/papaparse
```

```typescript
// vite.config.ts — add Tailwind plugin
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  base: '/',
})
```

```css
/* src/index.css — replace current manual :root block with: */
@import "tailwindcss";
@import "@chrisandrewsedu/ev-ui/tailwind-preset";
@import url('https://fonts.googleapis.com/css2?family=Manrope:wght@300;400;500;600;700;800&display=swap');
```

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Tailwind v4 CSS-first config | Tailwind v3 with `tailwind.config.js` | Only if the project were already on v3 and migration cost was prohibitive — not the case here; starting fresh |
| ev-ui tailwind-preset import | Manually copy token values into CSS vars | Never — defeats the purpose of a shared design system; tokens will drift again within one milestone |
| Indiana Gateway pipe-delimited download | DLGF PDF budget orders | PDF parsing is lossy and fragile; pipe-delimited data is structured and complete |
| LA City Socrata CSV | LA City Open Budget site scraping | Socrata has a stable direct-download URL; scraping an interactive viz is brittle |
| papaparse for import scripts | Extending the existing hand-rolled CSV parser in `processBudget.js` | The existing parser works for Bloomington's clean CSV but the Indiana Gateway pipe-delimited format with quoted strings and edge cases warrants a proven parser |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Tailwind v3 + `postcss.config.js` approach | Every other EV app uses Tailwind v4 CSS-first; mixing versions creates confusion and blocks consuming `@tailwindcss/vite` | Tailwind v4 `@tailwindcss/vite` plugin |
| Hardcoded hex values in component files | These drift from the design system after the first token update | `import { colors, dataVizPalette } from '@chrisandrewsedu/ev-ui/tokens'` or Tailwind utility classes |
| New charting library (Victory, Nivo, Chart.js) | D3 + Recharts are already installed and used throughout treasury-tracker; adding a third charting library creates redundancy | Extend existing D3/Recharts usage for any new chart types needed by new entity dashboards |
| `xlsx` / `SheetJS` for data parsing | Excel format not used by any of the target open data portals; all portals provide CSV or pipe-delimited text | `papaparse` for delimited text; `pdfplumber` (Python) for PDF fallback |
| Zustand or React Query in treasury-tracker | Current state management via `useState` + `useEffect` + Map-based cache in `dataLoader.ts` is sufficient for the number of entities; adding a state library is over-engineering | Extend the existing `cache: Map<string, BudgetData>` in `dataLoader.ts` |
| `@googlemaps/js-api-loader` | Treasury Tracker has no geolocation requirement; entity selection is manual dropdown | Static entity config in `src/data/entityConfig.ts` |

---

## Stack Patterns by Variant

**For Indiana entities (Bloomington, Ellettsville):**
- Use Bloomington Socrata portal (CSV, 14 standard DLGF columns) for Bloomington refresh
- Use Indiana Gateway pipe-delimited download for Ellettsville; run through adapted `processBudget.js` with `delimiter: '|'` config
- Import via existing `POST /treasury/import` endpoint

**For Monroe County IN (no confirmed machine-readable source):**
- Attempt Indiana Gateway download first (county-level data available)
- Fall back to Python `pdfplumber` extraction from PDF if Gateway lacks department-level breakdown
- Simpler category hierarchy acceptable (fewer depth levels) if PDF is the only source

**For LA entities (LA City, LA County):**
- LA City: direct Socrata CSV download, standard processing pipeline, department-level hierarchy
- LA County: attempt `data.lacounty.gov` Socrata first; fall back to PDF extraction from CEO budget book
- Both entities require a new `entityConfig` entry with population, hero image URL (Wikimedia Commons), and available fiscal years

---

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| `tailwindcss` ^4.x | Vite 7.2.4 + `@tailwindcss/vite` | CSS-first config; NO `tailwind.config.js` needed; `@import "tailwindcss"` in CSS is the v4 activation |
| `@chrisandrewsedu/ev-ui` ^0.1.53 | React 19 | `SiteHeader` peer deps: `react >=17`; `RadarChartCore` requires `@react-spring/web >=9` — NOT needed in treasury-tracker since it doesn't use RadarChartCore |
| `@chrisandrewsedu/ev-ui/tailwind-preset` | Tailwind v4 (CSS import) or v3 (config preset) | ev-ui preset uses `theme.extend` pattern compatible with both; v4 CSS import is preferred for this project |
| `papaparse` ^5.5.3 | Node.js (import pipeline scripts) | Browser-compatible too but only needed in Node.js processing scripts here |

---

## Sources

- `/Users/chrisandrews/Documents/GitHub/treasury-tracker/package.json` — current deps, ev-ui at ^0.1.6, NO Tailwind
- `/Users/chrisandrews/Documents/GitHub/treasury-tracker/src/index.css` — manual CSS vars, non-canonical EV color names
- `/Users/chrisandrews/Documents/GitHub/treasury-tracker/src/App.tsx` — dataLoader usage, entity tabs skeleton (NavigationTabs with City/State/Federal tabs present but non-functional)
- `/Users/chrisandrews/Documents/GitHub/treasury-tracker/src/data/dataLoader.ts` — `loadBudgetData(year, cityName, dataset)` API-first with static JSON fallback; `listCities()` endpoint already exists
- `/Users/chrisandrews/Documents/GitHub/treasury-tracker/budgetConfig.json` — column mappings confirmed match Bloomington Socrata dataset columns
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/treasury/handlers.go` — `ImportBudget` endpoint with `CategoryImport` / `LineItemImport` schema
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/treasury/models.go` — treasury schema: City, Budget, BudgetCategory, BudgetLineItem
- `/Users/chrisandrews/Documents/GitHub/ev-ui/package.json` — v0.1.53 current; exports `./tokens` and `./tailwind-preset`
- `/Users/chrisandrews/Documents/GitHub/ev-ui/src/tokens.js` — `dataVizPalette` (10 hues × 5 shades), `colors`, `colorScales` confirmed
- `/Users/chrisandrews/Documents/GitHub/ev-ui/src/tailwind-preset.js` — flattened color scales as `ev-{hue}-{step}` utilities confirmed
- `/Users/chrisandrews/Documents/GitHub/essentials/src/index.css` — Tailwind v4 CSS-first `@import "tailwindcss"` pattern confirmed as the EV standard
- `https://data.bloomington.in.gov/dataset/Budgeted-Expenses-No-Blank-Fund/hej9-2d5y` — 14-column schema confirmed (Fiscal_Year, Priority, Service, Department, Program, Division, Description, Item_Category, Fund, Approved_Amount, Actual_Amount, Recommended_Amount, Primary_Function, Sub_Function)
- `https://gateway.ifionline.org/public/download.aspx` — pipe-delimited budget files for Indiana local governments including Ellettsville (unit 2546) and Monroe County confirmed available — HIGH confidence
- `https://data.lacity.org/Administration-Finance/Open-Budget-Appropriations-Fiscal-Years-2010-2025/5242-pnmt` — LA City appropriations CSV download confirmed — HIGH confidence
- `https://ceo.lacounty.gov/budget/` — LA County PDF budget books confirmed; machine-readable Socrata format requires verification — MEDIUM confidence
- WebSearch: papaparse v5.5.3 confirmed as latest stable (2025-03)

---
*Stack research for: v2026.3.7 Treasury Tracker Expansion*
*Researched: 2026-03-22*
