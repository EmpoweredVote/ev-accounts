# Phase 103: Essentials Wiring + Landing Page - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-04
**Phase:** 103-essentials-wiring-landing-page
**Areas discussed:** Landing page design, Icon metadata on cards, Election page clarity, Headshot audit script

---

## Landing Page Design

### Layout Position

| Option | Description | Selected |
|--------|-------------|----------|
| Below the search (Recommended) | Address input stays hero. Coverage + buttons below. | |
| Above the search | Coverage areas first, then "or search by address" divider, then input. | ✓ |
| Side by side | Two-column: search left, shortcuts right. | |

**User's choice:** Above the search
**Notes:** User wants to make it clear the site currently only covers these two areas.

### Button Style

| Option | Description | Selected |
|--------|-------------|----------|
| Teal outlined cards (Recommended) | Bordered cards with county name + state, hover shadow. | ✓ |
| Filled teal buttons | Solid teal background, white text. | |
| Minimal text links | Arrow-prefixed text links, lightest touch. | |

**User's choice:** Teal outlined cards

### Navigation Approach

| Option | Description | Selected |
|--------|-------------|----------|
| Hardcoded address search (Recommended) | Navigate to /results?q={county building address}. | ✓ |
| Browse API with geo_id | POST to browse-by-area with hardcoded geo_ids. | |
| Pre-fetched results | Static JSON, instant load, stale data risk. | |

**User's choice:** Hardcoded address search
**Notes:** User clarified: should point to county government offices/courthouse, not random addresses. Also discussed wanting a path for users who don't want to enter an address — decided to use "Browse by location →" link to Results page LocationBrowser rather than duplicating browse functionality on landing page.

### Coverage Messaging

**User's choice:** Factual statement, no "coming soon" or expansion promises. Honest about current coverage being limited to these two counties.

---

## Icon Metadata on Cards

### Which Icons

| Option | Description | Selected |
|--------|-------------|----------|
| Ballot icon (on ballot) | Shows upcoming election status | ✓ |
| Compass icon (has stances) | Shows compass data availability | ✓ |
| Branch icon (branch type) | Shows legislative/executive/judicial | ✓ |

**User's choice:** All three icons (multi-select)

### Placement

| Option | Description | Selected |
|--------|-------------|----------|
| Below the name/title (Recommended) | Row of icons beneath title text | |
| Top-right corner overlay | Icons float over top-right of photo | |
| Bottom-right corner overlay | Icons float over bottom-right of photo | ✓ |
| Inline after title | Icons inline with title, right-aligned | |

**User's choice:** Bottom-right corner overlay (modified from top-right via user notes)

### Tooltips

| Option | Description | Selected |
|--------|-------------|----------|
| Hover tooltip + tap on mobile (Recommended) | @floating-ui/react tooltips, tap on mobile | ✓ |
| Always-visible labels | Tiny labels always shown next to icons | |
| You decide | Claude picks based on WCAG | |

**User's choice:** Hover tooltip + tap on mobile

### Election Page Icons

| Option | Description | Selected |
|--------|-------------|----------|
| Compass icon only | Only compass adds info on election page | |
| All applicable icons | Compass + branch on election cards too | ✓ |
| No icons on election cards | Icons only on representatives page | |

**User's choice:** All applicable icons

### Icon Data Logic

| Option | Description | Selected |
|--------|-------------|----------|
| Frontend-computed (Recommended) | Compute from existing data, no new API fields | ✓ |
| Backend flag fields | Add has_stances, branch_type, on_ballot to API | |

**User's choice:** Frontend-computed
**Notes:** User raised concern about branch mapping for local officials. district_type alone doesn't distinguish county council (legislative) from county auditor (executive). Decided on best-effort heuristic with title-keyword matching for COUNTY type.

### Local Branch Mapping

| Option | Description | Selected |
|--------|-------------|----------|
| Best-effort mapping (Recommended) | district_type + title keywords for COUNTY, no icon if unknown | ✓ |
| Skip branch for locals | Only federal/state get branch icons | |
| You decide | Claude figures out best mapping | |

**User's choice:** Best-effort mapping

---

## Election Page Clarity

### Noise Source

| Option | Description | Selected |
|--------|-------------|----------|
| Party primary labels (Recommended) | Same race split into multiple sections by party | |
| Too many tier sections | Tier dividers create too much hierarchy | |
| Card density | Cards take too much vertical space | |

**User's choice:** Combination (via free text)
**Notes:** User clarified it's a combination of party labels, multiple candidates per position, each position getting its own section — the overall effect is too many boxes/headers for the content.

### Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Group by position, indent ballots (Recommended) | Position is one section, party ballots are sub-labels | ✓ |
| Flat list with inline labels | No sections, all candidates in flat list | |
| You decide | Claude determines best structure | |

**User's choice:** Group by position, indent ballots
**Notes:** User said this is directionally correct but wants to see 2-3 layout variants rendered in the browser before committing to a specific treatment. ASCII mockups aren't sufficient for this visual decision.

### Election Tier Hues

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, same tier hues (Recommended) | tierColors applied to election page too | ✓ |
| No, keep election page neutral | Election page stays without color coding | |
| You decide | Claude determines based on final layout | |

**User's choice:** Yes, same tier hues

### General Election Grouping

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, group by position (Recommended) | All candidates for same seat together | ✓ |
| You decide | Claude determines best grouping | |

**User's choice:** Group by position

---

## Headshot Audit Script

### Audit Checks

| Option | Description | Selected |
|--------|-------------|----------|
| Broken URLs (404/timeout) | Fetch CDN URLs, flag non-200 | ✓ |
| Image dimensions | Flag landscape, too small, bad aspect ratio | ✓ |
| File size outliers | Flag unusually large or tiny files | ✓ |
| Missing headshots | Politicians with no image record | ✓ |

**User's choice:** All four checks (multi-select)

### Script Location

| Option | Description | Selected |
|--------|-------------|----------|
| TypeScript CLI in backend/scripts (Recommended) | Same pattern as importBudgetHierarchy.ts, CSV output | ✓ |
| SQL query only | Database-only checks, can't validate URLs | |
| You decide | Claude picks best approach | |

**User's choice:** TypeScript CLI in backend/scripts

---

## Claude's Discretion

- Exact county government building addresses for location card navigation
- How to surface LocationBrowser link on Results page
- Batch vs per-politician compass stance availability check
- Election page layout variant proposals
- CSS for icon overlay positioning

## Deferred Ideas

None — discussion stayed within phase scope
