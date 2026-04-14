# Treasury Tracker — UX Walkthrough (UX-04)

**App:** https://treasurytracker.empowered.vote/
**Run date:** 2026-04-13
**Persona:** Naive first-time Monroe County, IN voter — `200 W Kirkwood Ave, Bloomington, IN 47404`
**Environment:** Production

---

## 1. Relevance Check (per CONTEXT D-08)

**Gate result: Monroe County / Bloomington data is PRESENT.**

The Treasury Tracker landing page surfaces an "ALPHA PROGRAM" banner stating the app is "currently serving a limited number of Alpha communities." After scrolling or searching, **Bloomington, IN** and **Monroe County, IN** both appear as available communities in the city/municipality list. Clicking either loads a full budget overview page with FY 2026 data.

- Bloomington, IN — $224.7M total budget (FY 2026)
- Monroe County, IN — $345.1M total budget (FY 2026)

Per CONTEXT D-08 Step 2b: Monroe/Bloomington data IS present — full walkthrough continues.

**Screenshots:**
- `screenshots/treasury/01-landing.png` — Landing page with "ALPHA PROGRAM" banner and initial community grid
- `screenshots/treasury/02-relevance-check.png` — City picker list showing Bloomington, IN entry visible

---

## 2. Landing Page

**URL:** https://treasurytracker.empowered.vote/

The landing page greets the voter with a full-bleed dark hero: "Your government's finances, made transparent." A sub-headline reads: "Treasury Tracker turns dense public budget documents into visual, plain-language summaries — so every citizen can understand how their tax dollars are spent."

Below the hero, a prominent callout box reads: "Treasury Tracker is currently serving a limited number of Alpha communities. Search below to see if your city is available, or browse our curated communities. If your city isn't here yet, explore Bloomington to see the feature in action!"

The community picker below shows a paginated two-column grid of municipalities. The initial viewport shows California cities (Agoura Hills, Alhambra, Arcadia, Azusa, Baldwin Park…) — clearly alpha-seeded with CA data. Indiana/Bloomington is not visible in the above-fold grid.

**Voter friction:** A Monroe County voter landing cold has no indication that their city is available until they scroll or search. The "explore Bloomington" CTA in the callout points to the California city of Bloomington (if one exists) — it is ambiguous. The city list is not geo-personalized.

**Screenshots:**
- `screenshots/treasury/01-landing.png`
- `screenshots/treasury/01-landing-full.png` — Full page scroll showing paginated city grid

**Gap logged:** G-114-021 (landing page — no geo-personalization or Indiana prioritization)

---

## 3. Municipality Select (City Picker)

**URL:** https://treasurytracker.empowered.vote/ (scrolled to community list)

The voter must scroll the community list to find Bloomington or Monroe County. The list appears sorted alphabetically with no state-level grouping visible. Monroe County, IN appears mid-list alongside Monroe County entries potentially from other states. Bloomington, IN is visible when scrolling to the B section.

**Screenshots:**
- `screenshots/treasury/02-relevance-check.png` — City list at B section, Bloomington IN visible
- `screenshots/treasury/06-monroe-county-visible.png` — City list at M section, Monroe County, IN visible

**Voter friction (G-114-021):** The voter must scroll a long unprioritized list to find their municipality. No state filter, no search-by-name field, no location detection. For a voter unfamiliar with Treasury Tracker, finding their city requires patience.

---

## 4. Budget Overview (Bloomington)

**URL:** https://treasurytracker.empowered.vote/Bloomington/Budget (inferred from city click)

After clicking Bloomington, IN, the app loads a "Bloomington Finances" overview with a full-bleed hero image of City Hall. The page reads:

> "In 2026, Bloomington's budgeted $225 million to serve its 74,700 residents — that's roughly $3,016 per person."
> "The biggest share is **Utilities** … followed by **Public Safety** … followed by **General Government** …"

A large dollar figure card shows: **$224.7M — Money Out**

A bar chart below breaks spending across major categories: Utilities, Public Safety, General Government, Economic Development, Parks & Recreation, Road Maintenance.

The natural-language summary is effective — it immediately tells a voter the headline number and the top spending areas in plain English. This is the product's clearest UX win.

**Voter friction (minor):** Year control defaults to FY 2026 but a "Money In" (revenue) card appears blank in some screenshots — revenue data may be missing or below-fold. Budget-vs-actual comparison is not surfaced at this level.

**Screenshots:**
- `screenshots/treasury/03-bloomington-budget-overview.png`
- `screenshots/treasury/03-after-bloomington-click.png`
- `screenshots/treasury/05-bloomington-revenue.png`

---

## 5. Category Drill-Down (Bloomington)

**URL:** https://treasurytracker.empowered.vote/Bloomington/Budget/Water-and-Electric-Services (example)

Clicking a budget category opens a drill-down page. The "Water and Electric Services" category for Bloomington shows:

- A descriptive paragraph explaining what the category funds
- Horizontal bar charts comparing sub-units: Utility Operations, Utilities Service Board, Utility Lines & Pipes, Monroe Solar Treatment Plant, 101man N2 Wastewater Plant, Stormwater Management, Utility Engineering, Biochar Poole Wastewater Plant, Environmental Compliance
- Each sub-unit shows a dollar amount

The sub-unit drill-down is detailed and readable. The natural-language category introduction is helpful. Budget-vs-actual comparison is not visible at this level either — only approved budget amounts are shown.

**Screenshots:**
- `screenshots/treasury/04-budget-categories.png` — Bloomington category list
- `screenshots/treasury/04-category-drilldown.png` — Water and Electric Services drill-down with sub-units

**Gap logged:** G-114-022 (budget-vs-actual data missing from visible budget pages)

---

## 6. Salary / Workforce Data (Bloomington)

**URL:** https://treasurytracker.empowered.vote/Bloomington/Budget (workforce tab)

A "How Bloomington compensates its workforce" section appears below the budget breakdown. It shows department-level payroll data. The headline copy reads: "Each segment shows the share of the total budget. Tap any category to explore its breakdown."

The salary view exists but appears to show only summary segmentation, not individual salary rows (no individual employee names or amounts were visible in the screenshot).

**Screenshots:**
- `screenshots/treasury/06-bloomington-salaries.png`

---

## 7. Monroe County View

**URL:** https://treasurytracker.empowered.vote/Monroe-County/Budget (inferred)

Monroe County, IN has its own full budget overview:

> "In 2025, Monroe County's budgeted $345 million across all departments and services."
> "The biggest share is **Education** … followed by **General Services** … followed by **Operations** …"

A large dollar figure card shows: **$345.1M — Money Out**

The Monroe County budget uses FY 2025 data (not 2026 — one year behind Bloomington's FY 2026 data). This date discrepancy is notable.

**Screenshots:**
- `screenshots/treasury/07-monroe-county-budget.png`
- `screenshots/treasury/08-monroe-controls.png`

**Gap logged:** G-114-023 (Monroe County budget year is FY 2025 while Bloomington shows FY 2026 — inconsistent fiscal year coverage)

---

## 8. Year Selector

**URL:** https://treasurytracker.empowered.vote/Bloomington/Budget (year dropdown open)

The year selector for Bloomington shows: 2026, 2024, 2023, 2022, 2021, 2020. Year 2025 appears absent from the Bloomington year selector dropdown, creating a gap year. The year control is accessible via a dropdown in the breadcrumb/filter area.

**Screenshots:**
- `screenshots/treasury/09-year-selector-open.png` — Year dropdown open showing available years

**Gap logged:** G-114-024 (Bloomington year selector skips 2025 — gap-year in historical data continuity)

---

## 9. Sunburst / Chart View (Bloomington)

**URL:** https://treasurytracker.empowered.vote/Bloomington/Budget (sunburst toggle)

A toggle between "Bars" and "Sunburst" chart types exists. The sunburst view renders a radial partition chart of budget spending. In the screenshot the sunburst is visible but labeled spending categories are hard to read at small font sizes — the colored segments are not individually labeled in the full-page view; only the hover state would reveal category names.

**Screenshots:**
- `screenshots/treasury/10-sunburst-view.png`

**Gap logged:** G-114-025 (sunburst chart labels are not readable without hover/interaction — static screenshot shows unlabeled color segments)

---

## 10. Budget Breakdown Scrolled (Bloomington)

**URL:** https://treasurytracker.empowered.vote/Bloomington/Budget (scrolled)

The full Bloomington budget breakdown view shows all major spending categories as horizontal bars: Water and Electric Services $97.7M, Police and Fire Services, City Administration, Economic Development Fund $21.8M, Parks & Recreation $16.1M, Road Maintenance $12.8M.

The category amounts are clear and readable. Navigation back to the city list is available via the breadcrumb path at the top.

**Screenshots:**
- `screenshots/treasury/11-budget-breakdown-scrolled.png`

---

## 11. Monroe County — Education Drill-Down

**URL:** https://treasurytracker.empowered.vote/Monroe-County/Budget/Education

Monroe County's Education category shows a single sub-item: "General $47.3M." The drill-down is shallow — one level deep with a single line item, no further subdivision. The page uses the same bar chart pattern as Bloomington but with sparser data.

**Screenshots:**
- `screenshots/treasury/12-monroe-education-drilldown.png`

---

## 12. Gap Summary

| Gap ID | Description | Severity | Type |
|--------|-------------|----------|------|
| G-114-021 | Landing page has no geo-personalization — Indiana municipalities are buried in a long unsorted California-heavy list | confusing | ux-friction |
| G-114-022 | Budget-vs-actual comparison data not surfaced on budget overview or category drill-down pages | confusing | feature |
| G-114-023 | Monroe County budget shows FY 2025 while Bloomington shows FY 2026 — inconsistent fiscal year coverage between the two Monroe entities | minor | data |
| G-114-024 | Bloomington year selector skips 2025 — creates a gap year in the historical budget continuity | minor | data |
| G-114-025 | Sunburst chart labels are not readable without hover interaction — static view shows unlabeled color segments | minor | ux-friction |

All entries appended to `GAPS.md` with monotonic IDs G-114-021 through G-114-025.
