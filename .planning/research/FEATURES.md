# Feature Research

**Domain:** Municipal/county budget transparency app — multi-jurisdiction expansion with EV visual refresh
**Researched:** 2026-03-22
**Confidence:** MEDIUM-HIGH

---

## Context: What Already Exists

This is a subsequent milestone on an existing product. The following features are **already shipped** and are NOT in scope:

- Budget visualization with D3 sunburst/icicle/tree charts and Recharts
- Three dataset tabs: Operating (Budget), Revenue, Salaries
- Hierarchical drill-down navigation with breadcrumb
- Linked transaction panel (checkbook-to-budget category linkage for Bloomington)
- Year selector (2021-2025)
- Search bar filtering categories
- Per-resident stat card on hero
- Static JSON data for Bloomington, IN (31 JSON files across 5 fiscal years × 3 datasets)
- Backend treasury schema: `treasury.cities`, `treasury.budgets`, `treasury.budget_categories`, `treasury.budget_line_items`
- API routes: GET /treasury/cities, /treasury/budgets, /treasury/budgets/{id}/categories (live)
- Admin-protected import endpoint: POST /treasury/budgets/import
- SiteHeader from ev-ui (already integrated in App.tsx)
- Manrope font (already used throughout)

**NEW in this milestone (v2026.3.7)** is everything below.

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist given the milestone goal. Missing these makes the milestone incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Entity switcher (jurisdiction selector) | Loading the app for multiple jurisdictions with no way to select one is broken UX; the existing "Bloomington" hero headline is hardcoded and will be incorrect for any other city or county | MEDIUM | Dropdown or tab strip; triggers hero image, entity name, population stat, and year selector to update; powered by `GET /treasury/cities` |
| Bloomington data migrated to Supabase | Milestone goal states this explicitly; static JSON fallback is acknowledged tech debt in CLAUDE.md; API-first loading is the target architecture | HIGH | Import script maps existing JSON hierarchy → treasury schema; uses existing `POST /treasury/budgets/import` admin endpoint; validates pipeline before new jurisdictions |
| Ellettsville, IN budget data | Explicitly listed in milestone target features | MEDIUM | Indiana Gateway pipe-delimited files, unit_id=2546, years 2015–2026; same data schema as Bloomington Indiana Gateway files; operating budget minimum |
| Monroe County, IN budget data | Explicitly listed in milestone target features | MEDIUM | Indiana Gateway covers county units; same pipe-delimited format; needs `entity_type` distinction from city |
| LA County budget data | Explicitly listed in milestone target features | HIGH | `data.lacounty.gov` Open Expenditures (Auditor-Controller) + `budget.lacounty.gov` ArcGIS explorer; different schema than Indiana Gateway; much larger scale ($45B+ budget) |
| Major LA cities budget data | Explicitly listed in milestone target features | HIGH | LA City: `data.lacity.org` Socrata CSV (fiscal years 2010–2025); each additional city requires individual sourcing; scope needs bounding |
| EV visual refresh using ev-ui design tokens | Explicitly listed in milestone target features; current App.css uses custom hex values that partially conflict with ev-ui token names | MEDIUM | Apply ev-coral (#ff5740), ev-muted-blue (#00657c), ev-light-blue (#59b0c4), ev-yellow (#fed12e) to chart segment colors, dataset tab active states, category card accents, info card headers; replace hardcoded blue/purple/pink chart palette |
| `entity_type` field on backend model | Without it, the entity switcher will display "Monroe County" under a "cities" mental model, which is factually wrong and confusing to users | LOW | Add `entity_type` enum (`city`, `county`, `town`) to `treasury.cities`; surface in switcher label ("City of Bloomington" vs "Monroe County") and hero copy |

### Differentiators (Competitive Advantage)

Features that would set this above OpenGov / ClearGov / openbudget.lacity.org for a civic-engagement audience.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| City vs. county framing with contextual hero | LA has both a City and County government; Bloomington sits inside Monroe County; making the "which government is spending this?" question explicit is differentiated civic education that generic budget apps skip | LOW-MEDIUM | Entity switcher hero updates entity name, background photo, and population stat per jurisdiction; existing hero already swaps photo by CSS background-image |
| Per-capita normalization toggle | "Monroe County spends $X per resident vs. Bloomington $Y" — FiSC database research shows this is the most-used comparison lens for cross-jurisdiction analysis | MEDIUM | Population field already exists on City model; `formatPerResident()` already implemented in App.tsx; extend to all entities; add toggle on info stat card |
| EV design system aesthetic | Civic transparency apps (OpenGov, ClearGov, ClearPoint) have generic enterprise SaaS aesthetic; EV's coral/blue/yellow and Manrope feel distinctly human and non-governmental, making budget data approachable | LOW | This is the visual refresh feature; low implementation cost once design tokens are consistently applied |
| Antipartisan framing throughout | Never attribute spending to political parties or elected officials by party affiliation; present budget data as civic fact | LOW | Implement via copy choices and by omitting party-color coding, partisan labels, or "Mayor X approved" framing; aligns with EV mission documented in PROJECT.md |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Real-time or near-real-time spending data | "Show me what the city spent today" sounds exciting | Government accounting systems don't publish real-time; actual transactions appear 30–90 days post-occurrence; building sync infrastructure for marginal freshness gains is ops debt | Import quarterly; clearly label data vintage ("Data: FY 2024-25 adopted budget") |
| Full transaction checkbook for all jurisdictions | Bloomington has linked transactions already; users expect parity | LA City checkbook (Socrata) has millions of rows requiring pagination and filtering UI; Ellettsville and Monroe County don't publish transaction-level data at all; engineering cost is asymmetric | Support transactions only where source data already exists (Bloomington yes, others TBD); use budget appropriations as the baseline for all new jurisdictions |
| Side-by-side jurisdiction comparison layout | "Compare Bloomington vs Monroe County" seems natural | Requires entirely new layout; chart widths halve; drill-down hierarchy becomes much harder to maintain; doubles data loading complexity | Per-capita normalization stat card is a lightweight proxy for comparison; side-by-side deferred to v2+ |
| Salary data at same depth as Bloomington for all entities | Bloomington salary export has individual position-level line items; users expect parity | Indiana Gateway employee compensation data is at fund/department totals, not individual positions; LA County salary data requires entirely separate sourcing pipeline | Surface salary data only where source matches Bloomington's line-item depth; label partial coverage explicitly |
| Geographic choropleth / map view | LA Controller's budget app has choropleth maps; looks compelling | Requires GIS data per budget category; budget categories don't map cleanly to geographic boundaries; is a distraction from the core drill-down UX that users already use | Stick to hierarchical sunburst + category list; geography is Essentials' domain |
| Budget forecasting / scenario modeling | Power-user feature that appears in OpenGov and ClearGov | Wrong audience; this product is citizen-facing transparency, not internal government planning | Out of scope for EV's mission per PROJECT.md |
| CSV or data export | Common request in open data contexts | EV is a civic education tool, not a data platform; raw export directs power users to source portals instead (which is the right answer) | Link to source data portals (Indiana Gateway, data.lacity.org) rather than re-exporting |

---

## Feature Dependencies

```
Entity Switcher (frontend)
    └──requires──> Cities API populated (treasury.cities rows in Supabase)
                       └──requires──> Bloomington migration (first entity in DB)
                       └──requires──> Ellettsville, Monroe County, LA entities imported

entity_type field (backend)
    └──required by──> Entity Switcher label logic ("City of X" vs "X County")
    └──LOW cost, do first──> Avoids confusing labeling from day one of switcher

Per-Capita Normalization toggle (frontend)
    └──requires──> Population field populated for all entities
    └──already exists on──> City model and App.tsx formatPerResident()
    └──independent of──> Entity Switcher (can add after data is in)

EV Visual Refresh (frontend)
    └──enhances──> Entity Switcher (hero, cards, tabs all get refreshed together)
    └──independent of──> Data Migration (can land separately from data work)
    └──no backend dependencies

Bloomington Migration (backend + import script)
    └──requires──> Import script mapping JSON hierarchy → treasury schema
    └──uses──> Existing POST /treasury/budgets/import (admin-auth'd)
    └──unblocks──> Frontend removing static JSON fallback logic
    └──validates──> Import pipeline before using on new jurisdictions

Indiana entities (Ellettsville, Monroe County)
    └──requires──> Indiana Gateway pipe-delimited download + transform script
    └──same schema as──> Bloomington migration (reuse importer with unit_id param)
    └──requires──> entity_type field to distinguish county from city

LA entities
    └──requires──> Separate sourcing pipeline (data.lacounty.gov Socrata or CEO PDF)
    └──higher complexity than──> Indiana entities (different format, much larger scale)
    └──independent workstream from──> Indiana data migration

Salary/Revenue for new jurisdictions
    └──requires──> Operating budget for same entity already imported (baseline first)
    └──lower priority than──> Operating budget across all target jurisdictions
```

### Dependency Notes

- **Entity switcher is gated on data, not vice versa.** The UI is simple, but do not ship it until at least two entities are available in the database. Ship Bloomington migration first, then the switcher becomes immediately demonstrable with a second entity.
- **Bloomington migration validates the pipeline.** The import script for Bloomington (JSON → treasury schema) will have the same shape needed for Indiana Gateway pipe-delimited files. Build Bloomington migration first; Ellettsville and Monroe County reuse the same script with different source inputs.
- **LA County is an independent complexity track.** Indiana data (Bloomington, Ellettsville, Monroe County) all uses Indiana Gateway — same format, same filing schema. LA County and LA City use entirely different portals. Plan LA as a separate workstream that can proceed in parallel but is not a dependency for the entity switcher or Indiana data.
- **`entity_type` is low cost, high impact.** This is a single migration and field addition. Do it early to avoid the frontend ever displaying "Monroe County, City" or a city-named label for a county entity.

---

## MVP Definition

### Launch With (this milestone = v2026.3.7)

- [ ] `entity_type` field added to backend City model and `treasury.cities` table — prevents label confusion from day one
- [ ] Bloomington data migrated to Supabase — validates pipeline, removes static JSON tech debt, enables API-first loading
- [ ] Entity switcher UI — dropdown or tab to select jurisdiction; hero image, entity name, population stat update accordingly; powered by `GET /treasury/cities`
- [ ] EV visual refresh — ev-coral/ev-muted-blue/ev-yellow applied to chart segments, active tabs, card accents; remove conflicting custom hex values
- [ ] Ellettsville, IN operating budget imported — Indiana Gateway, same importer as Bloomington
- [ ] Monroe County, IN operating budget imported — Indiana Gateway, county entity type
- [ ] LA County operating budget imported — `data.lacounty.gov` or CEO budget PDF; even if fewer years or coarser hierarchy than Indiana data

### Add After Validation (v2026.3.7.x)

- [ ] Major LA cities (LA City minimum via data.lacity.org CSV) — operating appropriations for most recent available fiscal years
- [ ] Per-capita normalization toggle on info stat card — low frontend complexity once entity population data is populated for all jurisdictions
- [ ] Indiana entity revenue data — Indiana Gateway detailed receipts; same importer pipeline
- [ ] Indiana salary data — Indiana Gateway employee compensation; will be at fund/department level, not individual positions

### Future Consideration (v2+)

- [ ] Transaction-level checkbook for LA — data.lacity.org Socrata has millions of rows; requires pagination, search, and filtering UI; high complexity for uncertain additional value
- [ ] Side-by-side jurisdiction comparison UI — new layout, doubled data load; wait for user validation
- [ ] Year-over-year trend chart — line chart showing total budget growth across fiscal years per entity
- [ ] Capital budget tracking — LA City has CAPEX dataset; Bloomington does not currently expose capital spending separately
- [ ] Revenue data for LA entities — lower user value than operating budget given audience

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| `entity_type` backend field | MEDIUM | LOW | P1 |
| Bloomington migration to Supabase | HIGH (unblocks all entity switcher work) | MEDIUM | P1 |
| Entity switcher UI | HIGH (core milestone feature) | LOW-MEDIUM | P1 |
| EV visual refresh | MEDIUM (design coherence and brand) | LOW-MEDIUM | P1 |
| Ellettsville, IN data | HIGH (milestone target) | LOW (Indiana Gateway, same format) | P1 |
| Monroe County, IN data | HIGH (milestone target) | LOW-MEDIUM | P1 |
| LA County data | HIGH (milestone target) | HIGH (different format, scale) | P1 |
| LA major cities data | MEDIUM (milestone bonus) | HIGH (per-city sourcing) | P2 |
| Per-capita normalization toggle | MEDIUM | LOW frontend / MEDIUM data | P2 |
| Indiana revenue data | LOW | LOW (same importer) | P3 |
| Indiana salary data | LOW | MEDIUM (coarser data, different transform) | P3 |
| Transaction checkbook for LA | LOW for MVP | HIGH | P3 |
| Side-by-side comparison UI | LOW for MVP | HIGH | P3 |

**Priority key:**
- P1: Must have for this milestone
- P2: Should have, add after operating budget pipeline validates
- P3: Future milestone consideration

---

## Competitor Feature Analysis

| Feature | OpenGov / ClearGov | openbudget.lacity.org | Our Approach |
|---------|--------------------|-----------------------|--------------|
| Multi-entity selector | Yes — city/district/state picker | Single city only | Dropdown entity switcher backed by `GET /treasury/cities` |
| Dataset tabs (budget/revenue/salary) | OpenGov: all three | Budget + Revenue + Capital | Keep existing three-tab pattern |
| Drill-down hierarchy | OpenGov: function → department → program → account | Breadcrumb sidebar with percentages | Keep existing sunburst + category list |
| Transaction-level detail | OpenGov links to checkbook | LA Controller separate checkbook app | Support where source exists (Bloomington); others TBD |
| Per-capita normalization | OpenGov: yes, toggle | No | Add as stat card enhancement (P2) |
| Cross-jurisdiction comparison | OpenGov: head-to-head benchmarking (paid) | No | Per-capita stat card only; side-by-side v2+ |
| Year-over-year trend | ClearGov: multi-year forecasting | No | YearSelector exists; trend chart v2+ |
| CSV export | Both platforms offer | Yes via data.lacity.org | Not planned — link to source portals instead |
| Geographic budget map | ClearGov/OpenGov optional | LA Controller choropleth | Out of scope |
| Design aesthetic | Enterprise SaaS, generic blue | Generic government | EV coral/muted-blue/yellow, Manrope — human and approachable |

---

## Data Sourcing Reference

This directly constrains what features are buildable per jurisdiction:

| Jurisdiction | Source Portal | Format | Operating | Revenue | Salaries | Transactions |
|---|---|---|---|---|---|---|
| Bloomington, IN | Static JSON (migrate) + Indiana Gateway | JSON → Supabase, then Gateway pipe-delimited | Yes (5 years, 3 datasets) | Yes | Yes (position-level) | Yes (linked checkbook) |
| Ellettsville, IN | Indiana Gateway (`gateway.ifionline.org`) | Pipe-delimited `\|` | Yes (2015–2026) | Yes | Fund/dept totals only | No |
| Monroe County, IN | Indiana Gateway | Pipe-delimited `\|` | Yes (2012–2025) | Yes | Fund/dept totals only | No |
| LA County | `data.lacounty.gov` + `budget.lacounty.gov` | Socrata API / ArcGIS | Yes (department-level) | Limited | No | Open Expenditures dataset (separate) |
| LA City | `data.lacity.org` (Socrata) | CSV API | Yes (FY 2010–2025) | Yes | No | LA Controller checkbook (millions of rows) |

**Indiana Gateway details:** Files are pipe-delimited (`|`), documented at `gateway.ifionline.org/public/download.aspx`. Budget Form 4-A (fund/department/expenditure category) is the most useful for hierarchical display. Budgets, Annual Financial Reports, and Disbursements by Fund and Department are all available for Monroe County and Ellettsville. Data available 2012–2025.

**LA County details:** `budget.lacounty.gov` is an ArcGIS-powered budget explorer with structured department-level appropriations. `data.lacounty.gov` has the Auditor-Controller "Open Expenditures" dataset for actual spending. CEO publishes annual budget PDF as a fallback but the Socrata API is the right starting point. FY 2024-25 budget is $45.4B — categories will be coarser than Bloomington's line-item depth.

**LA City details:** `openbudget.lacity.org` and `data.lacity.org/Administration-Finance/Open-Budget-Appropriations-Fiscal-Years-2010-2025/5242-pnmt` provide CSV exports for fiscal years 2010–2025 (appropriations). The LA Controller's open expenditures site (`lacity.spending.socrata.com`) has transaction-level data but millions of rows — flag as v2+ complexity.

---

## Sources

- Indiana Gateway download page: https://gateway.ifionline.org/public/download.aspx — data format confirmed as pipe-delimited; fields confirmed from DLGF documentation (HIGH confidence)
- Ellettsville budget notices: https://budgetnotices.in.gov/Unit_View.aspx?unit_id=2546 — years 2015–2026 confirmed available (HIGH confidence)
- LA City Open Budget: https://openbudget.lacity.org/ — CSV export, Socrata backing, dataset types confirmed (HIGH confidence)
- LA City appropriations data catalog: https://data.lacity.org/Administration-Finance/Open-Budget-Appropriations-Fiscal-Years-2010-2025/5242-pnmt/data (HIGH confidence)
- LA County budget explorer: https://budget.lacounty.gov/ — ArcGIS-backed, department-level structure confirmed (MEDIUM confidence)
- LA County Open Expenditures: https://data.lacounty.gov/datasets/la-county-open-expenditures-auditor-controller/about — existence confirmed, full field schema not verified (MEDIUM confidence)
- ICMA: How 3 Innovative Cities Make Budgets Easy: https://icma.org/blog-posts/how-3-innovative-cities-make-budgets-easy — drill-down, dual-view, transaction linking as expected patterns (MEDIUM confidence)
- Lincoln Institute FiSC database: https://www.lincolninst.edu/data/fiscally-standardized-cities/ — per-capita normalization validated as standard civic comparison lens (HIGH confidence)
- OpenGov head-to-head comparison: https://govtech.com/dc/articles/OpenGov-Offers-Head-to-Head-Budget-Comparisons-for-Government.html — cross-jurisdiction comparison is a known civic tech pattern (MEDIUM confidence)
- Codebase: `treasury-tracker/src/App.tsx` — existing feature inventory, hardcoded Bloomington, formatPerResident(), static JSON loading pattern (HIGH confidence)
- Codebase: `EV-Backend/internal/treasury/models.go`, `routes.go` — existing schema, API surface (HIGH confidence)

---

*Feature research for: v2026.3.7 Treasury Tracker Expansion milestone*
*Researched: 2026-03-22*
