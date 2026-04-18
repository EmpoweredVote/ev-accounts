# Phase 125: Tier 2 UX Polish Bundle - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix 10 confirmed Tier 2 UX gaps across Essentials, Compass, Read & Rank, and Treasury,
improving platform polish without blocking any voter-critical flows.

**In scope:** G-114-001, G-114-002, G-114-004, G-114-011, G-114-014, G-114-020, G-114-021, G-114-023, G-114-024, G-114-025

**Explicitly out of scope (cut during discussion):**
- G-114-005 — Default tab policy (no longer needed)
- G-114-008 — Verdict badge section on Pierce profile (resolved by Phase 118)
- G-114-013 — Onboarding tooltip blocking radar (no longer needed)
- G-114-015 — Religious Freedom duplicate question (no longer needed)
- G-114-017 — Candidate-level nav in Read & Rank (cut entirely)
- G-114-019 — "Verdicts appear on Essentials" has no link (no longer needed)
- G-114-022 — Budget-vs-actual UI toggle (cut entirely)

</domain>

<decisions>
## Implementation Decisions

### Research / Status Verification

- **D-01:** Researcher must **verify current production state** of each gap before writing
  fix tasks. Some gaps may have been incidentally resolved by prior phases (Phase 118,
  122, 123). Only gaps confirmed still broken get fix tasks. If a gap is already resolved,
  document evidence and close it — do not write a fix plan for it.

### Gap Inventory (confirmed in scope)

| Gap | App | What | Severity |
|-----|-----|------|----------|
| G-114-001 | essentials | Address field has no autocomplete dropdown during typing | confusing |
| G-114-002 | essentials | Address displayed in ALL CAPS in results header | minor |
| G-114-004 | essentials | Candidate appears under different offices on Representatives vs Elections tabs with no cross-reference | confusing |
| G-114-011 | compass | Compare picker has no geo-aware state pre-selection | confusing |
| G-114-014 | compass | Matt Pierce headshot missing in Compass compare panel (exists in Essentials) | confusing |
| G-114-020 | read-rank | Page title shows "readrank-prototype" in browser tab | minor |
| G-114-021 | treasury | Landing page has no geo-prioritization — Indiana municipalities buried below CA cities | confusing |
| G-114-023 | treasury | Monroe County shows FY2025 while Bloomington shows FY2026 — inconsistent coverage | minor |
| G-114-024 | treasury | Bloomington year selector skips 2025 — data import needed | minor |
| G-114-025 | treasury | Sunburst chart labels unreadable without hover | minor |

### G-114-011: Compass Compare Picker Geo-Default

- **D-02:** Use a **three-tier fallback chain** for state pre-selection:
  1. **Essentials address context** — read stored search address from Essentials-domain
     localStorage (cross-app fragment bridge already in place from Phase 122). Extract
     state from the stored address and pre-select it in the picker dropdown.
  2. **Browser geolocation** — if no Essentials address context is available, request
     `navigator.geolocation`. Reverse-geocode to state. Only used when geolocation
     permission is granted without a prompt (i.e., already granted) or user accepts.
  3. **Unfiltered fallback** — if neither source is available, show all politicians
     unsorted (current behavior). Do NOT hardcode Indiana as a fallback.

- **D-03:** The geo-default applies to the **initial state filter value** in the picker
  dropdown, not to the search results themselves. The user can still manually change
  the filter to any state.

### G-114-014: Headshot Source Investigation

- **D-04:** Researcher must determine whether the Compass compare panel sources headshots
  from the same `essentials.politician_images` table as Essentials, or a separate data
  source. Align to a single source so headshots are consistent across apps.

### G-114-021: Treasury Landing Geo-Prioritization

- **D-05:** Add a **"Featured municipalities" section** at the top of the Treasury landing
  page that surfaces Indiana municipalities (Bloomington IN, Monroe County IN) above
  the fold. This can be a static list (not dynamic geo-detection) given the platform's
  known primary audience.

### G-114-023: Fiscal Year Inconsistency

- **D-06:** If FY2026 Monroe County budget data is not yet available, add a
  **"Latest available: FY2025"** notice on the Monroe County budget page rather than
  leaving the inconsistency unexplained.

### G-114-024: Bloomington 2025 Data

- **D-07:** Import FY2025 Bloomington budget data using the existing
  `importBudgetHierarchy.ts` script. Researcher should confirm whether the source
  data (flat tables in Supabase) already has FY2025 or if it needs to be sourced first.

### G-114-025: Sunburst Labels

- **D-08:** Add **permanent labels for top-level budget categories** on the sunburst chart,
  or remove the sunburst toggle in favor of the already-labeled bar chart. Researcher
  determines which is less risky given the current D3 sunburst implementation.

### Wave / Delivery Structure

- **D-09:** Deliver in **three app-by-app waves**, each its own plan + deploy:
  - **Wave 1 (Essentials):** G-114-001, G-114-002, G-114-004
  - **Wave 2 (Compass):** G-114-011, G-114-014
  - **Wave 3 (Read & Rank + Treasury):** G-114-020, G-114-021, G-114-023, G-114-024, G-114-025
- Each wave is verified in production before the next wave begins.

### Claude's Discretion

- Exact fix for G-114-004 (cross-reference annotation style and placement on the
  Representatives card)
- Visual treatment of the Treasury "Featured municipalities" section
- Whether browser geolocation is silently skipped or prompts the user (prefer
  silent skip if already-denied)
- Diagnostic approach for G-114-014 headshot source investigation

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Gap Report & Audit
- `.planning/GAP-REPORT.md` §G-114-001, §G-114-002, §G-114-004, §G-114-011, §G-114-014, §G-114-020, §G-114-021, §G-114-023, §G-114-024, §G-114-025 — fix sketches, evidence, and tier rationale for each gap
- `.planning/research/ux-walkthrough/GAPS.md` — original 31-gap source

### Essentials
- `essentials/src/pages/Results.jsx` — address display, Representatives/Elections tabs, candidate card rendering
- `essentials/src/App.jsx` — route definitions

### Compass
- `CompassV2/src/components/ComparePanel.jsx` — compare picker, headshot rendering, "View profile" link
- `essentials/src/lib/compass.js` — `GUEST_COMPASS_KEY`, `loadGuestCompass()` — cross-app localStorage bridge

### Read & Rank
- `read-rank/index.html` (or Vite config) — page title source

### Treasury
- `EV-prototypes/treasury-tracker/` or standalone treasury repo — landing page, sunburst chart, year selector
- `ev-accounts/backend/scripts/importBudgetHierarchy.ts` — FY2025 data import script (D-07)

### Cross-App Architecture
- `.planning/phases/122-cross-app-loop-polish/122-CONTEXT.md` — fragment relay architecture, Essentials localStorage bridge

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`loadGuestCompass()` / `GUEST_COMPASS_KEY`** (`essentials/src/lib/compass.js`) — already reads Essentials-domain localStorage; the same key may encode address context for G-114-011 geo-default.
- **`importBudgetHierarchy.ts`** — existing script for Treasury data import; re-run with FY2025 data for G-114-024.
- **`serializeCompassFragment()` / cross-app fragment bridge** — established cross-origin data relay pattern from Phase 122; G-114-011 builds on this.

### Established Patterns
- **Production verification after each wave** — consistent with Phases 118, 119, 122 (local dev for iteration; production DOM/screenshot evidence before closing each gap).
- **ev-ui auto-bump pipeline** — if any Compass fix touches a shared ev-ui component, ship via `npm version patch` → tag → CI → repository_dispatch.
- **Antipartisan design** — no party colors or labels anywhere in any fix.

### Integration Points
- **Compass compare picker** — researcher must confirm how headshot URLs are sourced in `ComparePanel.jsx` (D-04).
- **Treasury landing page** — researcher must confirm the current municipality list rendering and where to insert the Featured section (D-05).

</code_context>

<specifics>
## Specific Ideas

- G-114-011 fallback chain is explicit: Essentials localStorage → browser geolocation → unfiltered. Do NOT hardcode Indiana as a default state.
- G-114-021: "Featured municipalities" section is acceptable as a static list — no dynamic geo-detection required.
- G-114-025: Removing the sunburst toggle entirely is an acceptable fix if labeling is complex.

</specifics>

<deferred>
## Deferred Ideas

- **G-114-017** — Candidate-level "By Candidate" nav view in Read & Rank — cut, not deferred to roadmap.
- **G-114-022** — Budget-vs-actual UI toggle in Treasury — cut, not deferred to roadmap.
- **G-114-005** — Time-based default tab (Elections vs Representatives) — cut per user decision.
- **G-114-013** — Non-blocking compare onboarding tooltip — cut per user decision.
- **G-114-015** — Religious Freedom duplicate question audit — cut per user decision.
- **G-114-019** — "Your verdicts" hyperlink on Read & Rank topic completion — cut per user decision.
- **D-02 Tier 2** — Browser geolocation + reverse-geocode backend for Compass picker geo-default — accepted as deferred 2026-04-17. Tier 1 (Essentials localStorage) + Tier 3 (unfiltered) ship in Phase 125. Reason: marginal UX win vs new backend surface area; Essentials address context covers the common path.

</deferred>

---

*Phase: 125-tier-2-ux-polish-bundle*
*Context gathered: 2026-04-17*
