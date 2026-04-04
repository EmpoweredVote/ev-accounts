# Phase 103: Essentials Wiring + Landing Page - Context

**Gathered:** 2026-04-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire ev-ui v0.1.55 features (tier hues, icon metadata, headshot crop) into essentials app, reduce election page visual noise, add coverage messaging + location shortcuts to the landing page, and create a headshot audit script.

</domain>

<decisions>
## Implementation Decisions

### Landing Page Design
- **D-01:** Coverage area cards appear ABOVE the address search input, with a divider ("or search by address") separating them. Coverage cards are the first interactive element on the page.
- **D-02:** Two teal-outlined cards with hover shadow — one for "Monroe County, Indiana" and one for "Los Angeles County, California". County name on first line, state on second line.
- **D-03:** Simple factual coverage statement: "We currently cover:" — no "more areas coming soon" or expansion promises.
- **D-04:** Each card navigates to `/results?q={county government building address}` using existing address search flow. Researcher should identify the correct county government building addresses (courthouse, county admin building) that return full representative coverage.
- **D-05:** A "Browse by location →" text link below the cards navigates to the Results page with the LocationBrowser visible. Does NOT duplicate the full LocationBrowser on the landing page.

### Icon Metadata on Cards
- **D-06:** All three icons appear on politician cards: BallotIcon (on ballot), CompassIcon (has stances), BranchIcon (branch type). Icons appear on BOTH the representatives page and election page candidate cards.
- **D-07:** Icons positioned as bottom-right corner overlay on the photo area of PoliticianCard.
- **D-08:** Tooltips via @floating-ui/react — hover on desktop, tap on mobile. Tooltip text: "On your ballot — {date}", "Compare your views", "{branch} branch". Mobile dismisses on tap-away.
- **D-09:** Icon visibility computed frontend-side from existing data: ballot status from `getSeatBallotStatus()` (already exists), compass from stances data, branch from district_type.
- **D-10:** Branch type mapping — best-effort heuristic:
  - `NATIONAL_EXEC`, `STATE_EXEC`, `LOCAL_EXEC` → executive
  - `NATIONAL_UPPER`, `NATIONAL_LOWER`, `STATE_UPPER`, `STATE_LOWER`, `LOCAL`, `SCHOOL` → legislative
  - `JUDICIAL` → judicial
  - `COUNTY` → title-based: "council"/"commissioner" → legislative, "sheriff"/"clerk"/"auditor"/"assessor"/"recorder"/"coroner"/"treasurer" → executive, unknown → no branch icon

### Election Page Clarity
- **D-11:** Restructure election page to group candidates by position (not by position+party). Party primary labels become lightweight sub-labels within a position group, NOT separate CategorySection headers.
- **D-12:** General elections also group candidates by position — all candidates for the same seat appear together.
- **D-13:** Tier hue differentiation (tierColors from ev-ui) applies to election page tier sections, same as the representatives page.
- **D-14:** Exact election page layout needs browser iteration — researcher/planner should propose 2-3 layout variants that reduce visual noise. The direction is "fewer heavy section headers, lighter party labels."

### Tier Hue Differentiation (Representatives Page)
- **D-15:** Pass `tier` prop to CategorySection on the representatives page. Federal=teal-700, State=teal-500, Local=teal-200 (from ev-ui tierColors token, decided in Phase 102).

### Headshot Audit Script
- **D-16:** TypeScript CLI script at `ev-accounts/backend/scripts/auditHeadshots.ts`. Run with `npx tsx backend/scripts/auditHeadshots.ts`.
- **D-17:** Four checks: (1) broken CDN URLs (404/timeout), (2) image dimensions/aspect ratio (flag landscape, too small, or non-portrait), (3) file size outliers (unusually large or tiny), (4) missing headshots (politicians with no image record).
- **D-18:** Output is CSV format: `politician_id,name,issue,url,details` — suitable for manual review.

### Claude's Discretion
- Exact county government building addresses for location card navigation (researcher verifies)
- How to surface the LocationBrowser link on Results when arriving from "Browse by location" on landing
- Whether to batch-fetch compass stance availability or check per-politician
- Election page layout variant selection (propose options, user picks in browser)
- CSS specifics for icon overlay positioning (z-index, padding, background treatment for visibility over photos)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### ev-ui Components (v0.1.55)
- `ev-ui/src/icons.js` — BallotIcon, CompassIcon, BranchIcon SVG components
- `ev-ui/src/tokens.js` — tierColors token with federal/state/local semantic map
- `ev-ui/src/CategorySection.jsx` — Accepts optional `tier` prop for hue differentiation
- `ev-ui/src/PoliticianCard.jsx` — Accepts optional `icons` and `imageFocalPoint` props
- `ev-ui/src/PoliticianProfile.jsx` — Same headshot crop fix

### Essentials Frontend
- `essentials/src/pages/Landing.jsx` — Current landing page (needs coverage cards + location buttons)
- `essentials/src/pages/Results.jsx` — Representatives page (needs tier prop, icon wiring)
- `essentials/src/components/ElectionsView.jsx` — Election page (needs restructure for clarity)
- `essentials/src/components/LocationBrowser.jsx` — Existing browse-by-location with cascading dropdowns
- `essentials/src/components/PoliticianCard.jsx` — Local card wrapper (needs icon overlay integration)
- `essentials/src/utils/ballotStatus.js` — `getSeatBallotStatus()` for ballot icon logic

### Backend Scripts
- `ev-accounts/backend/scripts/` — Home for auditHeadshots.ts (same pattern as importBudgetHierarchy.ts)

### Phase 102 Context
- `.planning/phases/102-ev-ui-foundation-quick-wins/102-CONTEXT.md` — Icon system, tierColors, headshot crop decisions

### Requirements
- `.planning/REQUIREMENTS.md` — VIS-01, VIS-02, VIS-04, VIS-05, DATA-04, NAV-01, NAV-02

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `LocationBrowser.jsx`: Full browse-by-location with State → Area Type → Area cascading dropdowns + browse API integration — landing page links to this, does not duplicate it
- `getSeatBallotStatus()` in `ballotStatus.js`: Already determines if a politician's seat is on an upcoming ballot — directly usable for BallotIcon visibility
- `ev-ui v0.1.55`: tierColors, icons.js, CategorySection tier prop, PoliticianCard icons/imageFocalPoint props — all ready to consume

### Established Patterns
- essentials uses Tailwind CSS 4 for styling + ev-ui components with inline styles/tokens
- Landing page navigates to Results via query params (`/results?q=...`)
- CategorySection wraps groups of PoliticianCards by body name in Results.jsx
- ElectionsView uses `seededShuffle` for antipartisan candidate ordering — must be preserved

### Integration Points
- `essentials` must `npm update @chrisandrewsedu/ev-ui` to pick up v0.1.55
- Landing.jsx: add coverage cards + "Browse by location" link above address input
- Results.jsx: pass `tier` prop to CategorySection, pass `icons` prop to PoliticianCard
- ElectionsView.jsx: restructure race grouping, add tier hues, add icons to candidate cards
- New dependency: `@floating-ui/react` in essentials for icon tooltips

</code_context>

<specifics>
## Specific Ideas

- User wants coverage messaging to be honest/factual — no "coming soon" or expansion promises
- Location cards should point to county government building addresses (courthouse / county admin), not random addresses
- Election page layout needs iteration in-browser — ASCII mockups aren't sufficient for this visual decision. Propose variants that can be compared rendered.
- Branch icon mapping for COUNTY district_type uses office_title keywords; unknown titles get no branch icon rather than guessing wrong

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 103-essentials-wiring-landing-page*
*Context gathered: 2026-04-04*
