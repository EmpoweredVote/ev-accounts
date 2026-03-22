# Domain Pitfalls

**Domain:** Multi-jurisdiction budget data import, category normalization, design token refresh, and entity switcher added to existing Treasury Tracker app
**Researched:** 2026-03-22
**Scope:** v2026.3.7 Treasury Tracker Expansion milestone
**Overall confidence:** HIGH — derived from direct codebase inspection of `treasury-tracker/src/`, `EV-Backend/internal/treasury/`, existing Bloomington CSV data files (27K operating rows, 282K checkbook rows, 304K payroll rows), the Indiana Gateway download portal, LA County/City open data portals, and Supabase import documentation.

---

## Critical Pitfalls

Mistakes that cause rewrites or major issues.

---

### Pitfall 1: The Budget Schema Has No `dataset_type` on the Unique Index

**What goes wrong:** The `treasury.budgets` table has a composite unique constraint `idx_budget_city_year` on `(city_id, fiscal_year)` only. `dataset_type` is NOT part of that unique index. This means inserting Bloomington's 2025 operating budget succeeds, but inserting the 2025 revenue budget for the same city/year returns a unique-constraint violation and aborts the import. The `ImportBudget` handler check (`WHERE city_id = ? AND fiscal_year = ? AND dataset_type = ?`) is correct, but the DB-level constraint does not enforce the three-column uniqueness — so concurrent imports or a partial rollback can leave duplicate rows that silently corrupt category trees.

**Why it happens:** The existing data had only one dataset type (operating) when the schema was first created. The `dataset_type` column was added later as an application-level concern without updating the unique constraint.

**How to avoid:** Before running any imports, add `dataset_type` to the unique index:
```sql
DROP INDEX IF EXISTS treasury.idx_budget_city_year;
CREATE UNIQUE INDEX idx_budget_city_year_dataset
  ON treasury.budgets (city_id, fiscal_year, dataset_type);
```
Run this migration first, before importing Bloomington data or any additional jurisdictions.

**Warning signs:** `ImportBudget` returns 409 Conflict for the second dataset type for the same city/year. Or — worse — it succeeds but duplicate rows exist in the table.

**Phase to address:** Phase 1 (Bloomington data migration and backend schema fix) — before any other import work.

---

### Pitfall 2: Indiana Gateway Data Is Pipe-Delimited, Not Comma-Delimited

**What goes wrong:** Indiana Gateway bulk download files use `|` (pipe) as the delimiter, not comma. The existing Bloomington CSV pipeline was built against City of Bloomington's own exports (comma-delimited). Any import script that calls `csv.NewReader()` or Python's `csv.reader()` without setting the delimiter to `|` will silently misparse every row — all column values land in a single field, amounts are always zero, and categories are blank strings that produce a flat tree of empty nodes. This will not throw an error; the import will appear to succeed with wrong data.

**Why it happens:** Indiana Gateway's download page notes the pipe delimiter in small print. Developers building on top of the Bloomington CSV pipeline assume the same format applies to Monroe County and Ellettsville data from Gateway.

**How to avoid:** Download a small sample from Gateway first. Inspect raw bytes before writing the parser. Set `delimiter='|'` explicitly in Python, or use Go's `csv.Reader{Comma: '|'}`. Also confirm encoding: Gateway files are often Windows-1252, not UTF-8 — characters in vendor names and fund descriptions will corrupt silently if not re-encoded.

**Warning signs:** After import, all category amounts are `$0` or all rows collapse into a single root category. Spot-check one row: if the `name` field contains pipe characters it was parsed as CSV.

**Phase to address:** Phase 2 (Monroe County and Ellettsville import) — write a format-detection step at the start of every new import pipeline.

---

### Pitfall 3: LA County Budget Is PDF-First, Not Data-First

**What goes wrong:** LA County's primary budget publication is a multi-volume PDF (the 2024-25 Final Budget Book and 2025-26 Recommended Budget are both large PDFs from `ceo.lacounty.gov`). There is no downloadable CSV or JSON for the county-level budget breakdown by department. Attempting to scrape the PDF will yield unreliable data: multi-column table layouts, footnotes mid-table, and merged cells that parsing libraries routinely misread. Spending hours on a PDF scraper produces data that looks correct but has category amounts off by 10-40% due to table-parsing errors.

**Why it happens:** LA County posts machine-readable data for expenditure transactions (via `data.lacounty.gov`) but not for the adopted budget document itself. Developers assume the county-level budget is available in the same format as the city-level data.

**How to avoid:** For LA County, use the `data.lacounty.gov` open data portal for actual expenditure data (what was spent), not the PDF for budgeted amounts. For LA City, use the LA City Controller's open expenditures portal (`lacity.spending.socrata.com`) and `data.lacity.org` — both have CSV/API access. Accept that LA County's official adopted budget figures will need to be manually transcribed from the PDF at the top level only (5-10 departments), with transaction-level detail coming from the expenditure dataset.

**Warning signs:** Any import pipeline for LA County that relies on PDF parsing. Any script that calls `pdfminer`, `tabula`, or `camelot` against the LA County budget PDF.

**Phase to address:** Phase 3 (LA County and LA City data research/import) — budget the data sourcing step as 2-3 days of investigation before writing any import code.

---

### Pitfall 4: Fiscal Year Mismatch Breaks Year-Over-Year Comparisons

**What goes wrong:** Bloomington's fiscal year is January 1 – December 31 (calendar year). Monroe County and Ellettsville also use the Indiana standard calendar year. But LA County and LA City use July 1 – June 30 (the California standard). If the frontend stores only `fiscal_year: 2025` for all entities and the year selector shows "2025" for all of them, LA County's "2025" data actually covers July 2025–June 2026 while Bloomington's "2025" covers January–December 2025. The UI implies comparability that does not exist.

**Why it happens:** The `Budget` model stores only `fiscal_year: int`. There is no `fiscal_year_start` or `fiscal_year_type` field. The assumption that fiscal_year means calendar year was baked into the original Bloomington-only design.

**How to avoid:** Add a `fiscal_year_type` or `fiscal_year_start_month` field to the `Budget` model (e.g., `fiscal_year_start_month: 1` for Indiana, `7` for California). Display the full fiscal period in the UI — "FY 2024-25 (Jul–Jun)" for LA vs. "2025 (Jan–Dec)" for Indiana. Do not show a single year selector that implies apples-to-apples comparison across jurisdictions without this context.

**Warning signs:** The year selector shows "2025" for every entity. A user can select Bloomington 2025 and LA County 2025 and the UI presents both as the same fiscal period.

**Phase to address:** Phase 1 (schema migration) — add `fiscal_year_start_month` (smallint, default 1) to `treasury.budgets` before any California data is imported.

---

### Pitfall 5: Category Color Collision Between EV Brand Tokens and Data Visualization Palette

**What goes wrong:** The Treasury Tracker uses a 30-color data visualization palette (blues, purples, greens, teals) defined in `index.css` and `budgetConfig.json`. The EV design token refresh will introduce `ev-coral` (#ff5740) and `ev-muted-blue` (#00657c) as dominant UI colors. If the design token migration naively replaces all `--data-navy-500` references with `--muted-blue`, the sunburst chart segments that used `--data-navy-500` will all render in the same muted blue — the color-coding that makes the visualization readable collapses into a single-hue blur.

**Why it happens:** Design token systems are designed for UI chrome (buttons, headers, backgrounds). Data visualization palettes are orthogonal — they need perceptual distinctiveness across many adjacent segments, not brand consistency. Treating them as the same system breaks both.

**How to avoid:** Preserve the 30-color data visualization palette in `index.css` as a completely separate namespace (e.g., `--data-*` variables). Apply EV design tokens only to UI chrome: the `SiteHeader`, background colors, typography, the entity switcher, buttons, and info cards. Never pipe EV brand tokens into `BudgetCategory.color` assignments. The `budgetConfig.json` color palette is correct for visualization; leave it alone.

**Warning signs:** After the visual refresh, the sunburst/icicle chart shows fewer than 5 visible distinct colors for a budget with 15+ top-level categories. Or the chart legend becomes unreadable because adjacent segments share similar hues.

**Phase to address:** Phase 4 (visual refresh) — write explicit component-scope rules: EV tokens apply to layout/chrome components; data palette applies to visualization components.

---

### Pitfall 6: Checkbook Transaction Volume Overwhelms the API Response

**What goes wrong:** The Bloomington checkbook CSV has 282,458 rows. The current `ImportBudget` endpoint imports these as `BudgetLineItem` rows via the recursive `importCategories` function, which creates one `db.Create()` call per line item inside a single transaction. At 282K rows, this will time out on Render's free tier (30-second request timeout) and likely OOM the Go process. Even if it succeeds, the `GetBudgetCategories` endpoint does `Preload("LineItems")` — loading 282K line items as a nested JSON payload will make the frontend hang on every category drill-down.

**Why it happens:** The import pipeline was designed for the operating budget's ~27K budget rows. The checkbook (transaction-level) dataset is 10x larger. The current architecture makes no distinction between these.

**How to avoid:** Do not import checkbook transactions as `BudgetLineItem` rows. Checkbook transactions are a different access pattern — they need pagination, filtering, and aggregation. Two options: (1) store them in a separate `treasury.transactions` table with indexed columns (`city_id`, `fiscal_year`, `department`, `vendor`, `date`) and a paginated API endpoint; or (2) keep only the top-N vendors per category aggregated in `BudgetLineItem` and drop individual transaction rows. The existing `LinkedTransactionSummary` type in the frontend already models the aggregated pattern — follow that.

**Warning signs:** The `ImportBudget` request times out. The `GetBudgetCategories` response for a leaf category is larger than 1MB. The frontend freezes when clicking into a leaf category that has linked transactions.

**Phase to address:** Phase 1 (schema design) — decide the transaction storage strategy before importing Bloomington data.

---

### Pitfall 7: App.tsx Entity Switcher Is Hardcoded to `activeTab` City/State/Federal — Not Wired to Real Data

**What goes wrong:** The current `App.tsx` has `NavigationTabs` with hardcoded `[{ id: 'city', label: 'City' }, { id: 'state', label: 'State' }, { id: 'federal', label: 'Federal' }]`. The `activeTab` state is set but never actually changes what data is loaded — the data fetching ignores `activeTab` entirely. When the entity switcher is added for Bloomington/Monroe County/Ellettsville/LA County/LA City, developers might wire it into this existing `activeTab` state by adding more tab values, but the underlying `loadBudgetData` still needs to map entity selection to a `cityName` parameter. If `activeTab` is used as the `cityName` directly, it will look up "state" or "bloomington-in" as a city name, fail the API lookup, fall back to static JSON, and silently display Bloomington data for every entity.

**Why it happens:** The City/State/Federal tabs were placeholder UI from the original prototype that was never connected to real multi-entity data loading. The `dataLoader.ts` API path already supports `?city=` filtering but App.tsx doesn't pass it.

**How to avoid:** Replace `activeTab` with an `selectedEntity` state of type `{ id: string; name: string; state: string }`. On mount, populate the entity list from `listCities()` (the API endpoint already exists). The year selector and dataset tabs should filter data for the currently selected entity. Do not attempt to reuse the existing City/State/Federal tab semantics — they are structurally incompatible with per-entity switching.

**Warning signs:** After adding the entity switcher, selecting "Monroe County" still shows Bloomington data. Or the year selector shows years that don't exist for the selected entity.

**Phase to address:** Phase 5 (frontend entity switcher) — audit `App.tsx` data flow before building any new UI component for entity selection.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Import all Bloomington CSV years at once in one script | Faster setup | One bad year corrupts the import; no per-year rollback | Never — import year-by-year with explicit verification step |
| Use static JSON fallback for entities that have no API data yet | Unblocks frontend development | The fallback always returns Bloomington data regardless of selected entity; creates phantom "it works" behavior | Only acceptable as a named stub that renders an explicit "Data not yet available" state |
| Assign EV brand color tokens to chart segment colors | Visual consistency | Destroys perceptual distinctiveness of multi-segment visualizations | Never for chart segment fills |
| Skip `fiscal_year_start_month` field and document it in a README instead | Saves one migration | Any cross-jurisdiction comparison feature breaks silently; UX hides the mismatch | Never — schema is the source of truth |
| Normalize LA County categories to match Bloomington's hierarchy | Enables UI reuse | LA County uses department-based budgeting; Bloomington uses function-based — forced mapping loses meaning | Never — preserve source hierarchy, add a `hierarchy_type` field |

---

## Integration Gotchas

Common mistakes when connecting to external services.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Indiana Gateway CSV downloads | Assume comma delimiter; import breaks silently with all-zero amounts | Set `delimiter='|'`; re-encode from Windows-1252 to UTF-8 before parsing |
| Indiana Gateway fiscal year field | `fiscal_year` in Gateway files encodes the year the budget was adopted, not the calendar year covered | Verify: Indiana local governments use calendar year; fiscal_year=2025 in Gateway = Jan–Dec 2025 |
| LA County open data portal (`data.lacounty.gov`) | Assume the portal has adopted budget amounts by department | Portal has actual expenditure transactions; adopted budget figures are PDF-only at county level |
| LA City Controller expenditures (`lacity.spending.socrata.com`) | Use the Socrata API without authentication — free tier has rate limits and 1000-row default page size | Use `$limit=50000&$offset=N` pagination; or download the full dataset CSV from the portal rather than using the API |
| Supabase CSV import via dashboard | Upload 300K-row CSV through the dashboard UI (100MB limit) | Use `psql COPY` or `pgloader` for large files; the dashboard import will timeout or fail silently on large CSVs |
| Go `ImportBudget` HTTP endpoint | POST 300K line items in a single request body | Use a file-based CLI import script (as done for essentials and staging modules) — HTTP timeouts at 30s on Render free tier |

---

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| `Preload("LineItems")` on all categories | Category tree API response becomes very large | Only preload line items at the leaf node level; use a separate endpoint for line item detail | Breaks at ~5,000 line items across a budget |
| `GORM Preload("Subcategories")` recursively | N+1 queries building the category tree; 50+ DB calls per request | Use the existing flat-fetch + `buildCategoryTree` pattern in `handlers.go` | Breaks at depth >3 or >200 categories |
| Loading all entities in `listCities()` on the entity switcher dropdown | Fine at 5 cities, slow as cities grow | Already paginated in API; ensure frontend doesn't re-fetch on every render | Breaks at >100 entities |
| Storing raw checkbook transactions as `BudgetLineItem` rows | Imports succeed; leaf-node drill-down response is 5MB+ JSON | Use a separate `transactions` table with pagination | Breaks at >50K transactions per budget |
| Rebuilding `processedBudget.json` in the browser from raw API data on every mount | Imperceptible at Bloomington scale | Cache the transformed tree in component state with `useMemo`; do not re-transform on every render | Breaks when category tree has >500 nodes |

---

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Exposing individual payroll records by name in the API | PII leak — Indiana's payroll CSV includes employee names (`name_last`, `name_first`) | Do not import `name_last`/`name_first` fields into `BudgetLineItem.description`; aggregate payroll by position title only, as the existing Bloomington salary pipeline does |
| Committing Indiana Gateway or LA data CSVs to the repo | Raw data files can be large (>100MB) and may include PII in payroll | Add `data/*.csv`, `data/2024/`, `data/2025/` to `.gitignore` before starting import work; source data lives locally only |
| Admin `ImportBudget` endpoint has no authentication middleware | Any actor who discovers the endpoint can inject arbitrary budget data | Confirm the endpoint is under `SessionMiddleware` in `routes.go` before opening it to production traffic |

---

## UX Pitfalls

Common user experience mistakes in this domain.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Showing "City / State / Federal" tabs when only city-level data exists | User clicks "State" or "Federal", sees nothing or an error | Replace with a named entity dropdown/switcher that only shows entities with actual data; hide tabs for unavailable tiers |
| Displaying a single year selector across all jurisdictions | User selects 2025 for all entities; LA County's 2025 covers a different period than Bloomington's | Show the full fiscal period label ("FY 2024-25" vs "Calendar 2025") next to the year value |
| Comparing per-capita amounts across entities without surfacing population source | Monroe County population (148K) vs Bloomington (79K) — "per resident" figures are confusing if compared directly at county vs. city level | Display the population figure and source year prominently; note that county budgets cover the full county population including city residents |
| Entity switcher that resets all filters on switch | User drills into "Parks & Recreation" in Bloomington, switches to Monroe County, sees the top level — loses context | Preserve dataset type (operating/revenue/salaries) across entity switches; reset only the navigation path |
| Rendering the hero image and city context card with hardcoded Bloomington content when a different entity is selected | Misleads users looking at Monroe County or LA data | Each entity record needs its own `hero_image_url`, `description`, and context card copy — add these to the `treasury.cities` model |

---

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Bloomington data migrated to Supabase:** Verify all 5 fiscal years (2021-2025) exist in `treasury.budgets`, each with all 3 dataset types (operating, revenue, salaries). Check row counts match the source CSVs — do not accept "the import ran" as verification.
- [ ] **Entity switcher:** Verify selecting each entity makes a new API call with `?city=<entity>` and returns data for that entity specifically — not the static JSON fallback.
- [ ] **Fiscal year type labeled in UI:** Verify that LA County/City entries display "FY 2024-25" and Indiana entries display "2024" — not just the raw integer from the DB.
- [ ] **Visual refresh:** Verify the sunburst/icicle chart still renders 15+ distinct colors after the design token migration — not a monochromatic single-hue chart.
- [ ] **Payroll data anonymized:** Verify that no employee names appear in the API response for salary data — only position titles.
- [ ] **Category tree depth correct:** After importing a new jurisdiction, drill down to a leaf node and confirm the hierarchy matches the source data structure (e.g., LA County's `Department > Division > Object` is preserved, not flattened to Bloomington's `primary_function > priority > service > fund`).
- [ ] **`dataset_type` in unique index:** Run `\d treasury.budgets` and confirm the unique constraint includes `(city_id, fiscal_year, dataset_type)` before marking Phase 1 complete.

---

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Bad import: wrong amounts from pipe-delimiter parsing | MEDIUM | Run `DELETE FROM treasury.budget_line_items WHERE category_id IN (SELECT id FROM treasury.budget_categories WHERE budget_id = '<id>')`, then `DELETE FROM treasury.budget_categories WHERE budget_id = '<id>'`, then `DELETE FROM treasury.budgets WHERE id = '<id>'`. Re-run import with corrected parser. |
| Checkbook transactions stored in BudgetLineItem (wrong table) | HIGH | Requires schema migration to add `treasury.transactions` table, data migration from line_items, API endpoint changes, and frontend changes. Avoid by deciding architecture in Phase 1. |
| EV brand tokens applied to chart colors (visual collapse) | LOW | Revert the CSS-only changes to `BudgetVisualization.css` and restore `--data-*` variable references. No data changes needed. |
| Missing `fiscal_year_start_month` after CA data imported | MEDIUM | Add column with `ALTER TABLE treasury.budgets ADD COLUMN fiscal_year_start_month smallint NOT NULL DEFAULT 1`. Update CA records: `UPDATE treasury.budgets SET fiscal_year_start_month = 7 WHERE city_id IN (SELECT id FROM treasury.cities WHERE state = 'CA')`. |
| Payroll PII imported (employee names in DB) | HIGH | Delete affected line item rows, re-import with anonymization applied. If data was ever served through the API, notify as a data exposure event. |

---

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Schema unique index missing `dataset_type` | Phase 1: Schema + Bloomington migration | `\d treasury.budgets` shows 3-column unique constraint |
| Checkbook transaction volume architecture | Phase 1: Schema + Bloomington migration | Decision documented; checkbook imported via correct storage pattern |
| Indiana Gateway pipe delimiter + encoding | Phase 2: Monroe County + Ellettsville import | Parser explicitly sets `delimiter='|'` and UTF-8 re-encoding; verified against manual row count |
| Indiana fiscal year encoding ambiguity | Phase 2: Monroe County + Ellettsville import | `fiscal_year_start_month = 1` set for all IN entities; UI displays "2025 (Jan–Dec)" |
| LA County PDF-first budget source | Phase 3: LA data research sprint | Decision logged: adopted budget figures from PDF (top-level only); transaction detail from `data.lacounty.gov` |
| Fiscal year mismatch CA vs IN | Phase 1 (schema), Phase 3 (verification) | `fiscal_year_start_month = 7` for CA entities; UI shows "FY 2024-25" not "2025" |
| Design token vs. visualization palette collision | Phase 4: Visual refresh | Post-refresh, sunburst chart renders 15+ distinct segment colors |
| `activeTab` not wired to entity data loading | Phase 5: Frontend entity switcher | Selecting Monroe County via switcher shows Monroe County API response, confirmed in Network tab |
| Hardcoded Bloomington hero content | Phase 5: Frontend entity switcher | Each entity shows its own name, description, and context card data |
| Payroll PII exposure | Phase 1 (Bloomington migration) | API response for salary dataset contains no `name_last`/`name_first` values |

---

## Sources

- Direct inspection: `treasury-tracker/src/App.tsx`, `src/data/dataLoader.ts`, `src/types/budget.ts`, `src/index.css`, `budgetConfig.json`
- Direct inspection: `EV-Backend/internal/treasury/models.go`, `handlers.go`, `routes.go`
- Direct inspection: `treasury-tracker/data/operating_budget-all.csv` (27,804 rows), `checkbook-all.csv` (282,458 rows), `payroll-all.csv` (304,911 rows)
- [Indiana Gateway Download Page](https://gateway.ifionline.org/public/download.aspx) — pipe delimiter documented; LOW confidence on exact column schema without direct download test
- [Indiana Gateway — pipe-delimited format confirmation](https://www.bakertilly.com/insights/2025-indiana-gateway-budget-forms) — MEDIUM confidence
- [LA County CEO Budget Page](https://ceo.lacounty.gov/budget/) — PDF-only for adopted budget document confirmed
- [County of Los Angeles Open Data](https://data.lacounty.gov/) — transaction-level expenditure data available
- [LA City Controller Open Expenditures](https://lacity.spending.socrata.com/) — CSV/API available for LA City
- [LA City Open Budget](https://openbudget.lacity.org/) — visualization layer over the same data
- [Supabase Import Data docs](https://supabase.com/docs/guides/database/import-data) — 100MB dashboard CSV limit confirmed; `pgloader` recommendation for large files
- [Supabase row limit discussion](https://github.com/orgs/supabase/discussions/3765) — default 1000-row API limit; configurable to 1M
- [How to Manage Breaking Changes in Design Tokens](https://designtokens.substack.com/p/how-to-manage-breaking-changes-in) — deprecation/migration pattern
- [GFOA: Designing a Local Government Budget](https://www.gfoa.org/long-form/a-guide-to-designing-a-local-government-budget) — hierarchy standards (line items → divisions → departments)

---
*Pitfalls research for: multi-jurisdiction government budget data import and Treasury Tracker expansion*
*Researched: 2026-03-22*
