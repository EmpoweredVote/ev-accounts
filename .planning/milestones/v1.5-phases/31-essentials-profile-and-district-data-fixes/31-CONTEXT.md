# Phase 31: Essentials Profile and District Data Fixes - Context

**Gathered:** 2026-02-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix data display issues on politician profiles and result cards in the Essentials app. Improve district context visibility, fix missing/incorrect data fields, resolve district-level city council members not appearing in search results, and remove the Issues and Prioritization card from profiles. No new capabilities — this is fixing and polishing what exists.

</domain>

<decisions>
## Implementation Decisions

### Profile page context
- Office title stays as the main heading (H2)
- Add subtitle below title showing **chamber name + district** (e.g., "Bloomington Common Council, District 3" or "Indiana Senate, District 40")
- Office description (what their position does) stays near the title as italicized text — immediate context, not a separate section
- Show **only office_description** — remove bio_text from profile display entirely (no long biographies)
- Term dates labeled inline: "First elected: Jan 2020 — Term ends: Jan 2026"
- Years in office displayed right below the term dates
- If years-in-office data is missing for federal/state officials, research should investigate whether it's a DB gap or display gap and fix accordingly

### Card display in results
- Cards should be 3 lines: (1) Name, (2) Office/position title, (3) Chamber + district
- Chamber + district subtitle appears on ALL cards (federal, state, local) — consistent design
- If chamber/district data is empty, card falls back to 2 lines (no empty 3rd line)
- **No party affiliation displayed anywhere** — no party badges on cards, no party info on profiles. Empowered Vote is antipartisan; listing party affiliation undermines the tool's purpose.
- Research should verify whether party badges are currently showing and flag for removal

### Empty/missing data handling
- Missing profile image: show **initials avatar** (circle with first/last initials in EV color palette)
- Empty office_description: **hide the section** entirely (don't show placeholder text)
- Both term dates null: **hide entire term section** including years in office
- Empty card 3rd line (no chamber/district): card is just 2 lines, no fallback text

### District-level city council visibility
- District-level city council members are not appearing in search results at all
- Backend uses address-based search via Google Maps geocoding → geofence polygon matching against stored data
- Research must verify: (1) Do we have polygon data for Bloomington, IN city council districts? (2) Do we have polygon data for major LA County city districts (Long Beach, Pasadena, etc.)? (3) Is the geofence matching query including LOCAL district types?
- This phase includes both **code fixes AND data fixes** — if polygon data is missing, import it
- BallotReady is no longer used; all data comes from our own database

### Remove Issues and Prioritization card
- Remove the "Issues and Prioritization" card from the profile page (frontend only)
- Keep backend endpoints (endorsements, stances) intact for future use
- Only this card is removed — all other profile sections remain

### Claude's Discretion
- Exact initials avatar styling (colors, font weight, sizing)
- How to abbreviate long chamber names on cards if needed
- Geofence query optimization approach
- Which specific LA County cities to verify polygon data for

</decisions>

<specifics>
## Specific Ideas

- Cards should be clean 3-line layout: Name / Office Title / Chamber, District
- Term date labels should use plain language: "First elected:" and "Term ends:" — not "valid_from" or other DB column names
- The antipartisan principle is fundamental — no party data should leak into any UI surface
- Bloomington, IN and LA County are the two test markets for district council visibility

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 31-essentials-profile-and-district-data-fixes*
*Context gathered: 2026-02-22*
